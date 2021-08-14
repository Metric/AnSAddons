local Ans = select(2, ...);
local GTrack = Ans.Analytics.GoldTracker;
local Trans = Ans.Analytics.Transactions;
local ItemTrack = Ans.Analytics.ItemTracker;
local DataQuery = Ans.Object.Register("Query", Ans.Analytics);

local itemHolder = {};
local nameHolder = {};
local goldHolder = {};
local currentGoldHolder = {};

local SECONDS_PER_DAY = 60 * 60 * 24;

--- this only gets the current realm characters
function DataQuery:GetTransactionCharacters()
    Trans:GetNames(nameHolder);
    return nameHolder;
end

--- this only gets the current realm characters
function DataQuery:GetGoldCharacters()
    GTrack:GetNames(nameHolder);
    return nameHolder;
end

--- this only gets the current realm characters
function DataQuery:GetItemCharacters()
    ItemTrack:GetNames(nameHolder);
    return nameHolder;
end

function DataQuery:GetInventory(name, type, tbl)
    local inv = ItemTrack:Get(name);
    if (inv and inv[type]) then
        for k,v in pairs(inv[type]) do
            local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, stackSize, _, _, vendorsell  = GetItemInfo(v.link);
            local _, _, _, itemName = strsplit("|", v.link);
            local t = tbl[k] or {id = k, quality = itemRarity, type = "", name = itemName, item = v.link, link = v.link, count = 0, quantity = 0, copper = 0, iLevel = itemLevel, ppu = 0, vendorsell = vendorsell or 0, from = ""};
            t.count = t.count + v.count;
            t.quantity = t.quantity + v.count;
            tbl[k] = t;
        end
    end
end

function DataQuery:JoinInventory(names, tbl, search)
    wipe(tbl);
    wipe(itemHolder);

    for i,v in ipairs(names) do
        self:GetInventory(v, "Inventory", itemHolder);
        self:GetInventory(v, "Bank", itemHolder);
    end

    for k,v in pairs(itemHolder) do
        if (not search or search:len() == 0) then
            tinsert(tbl, v);
        elseif (strfind(v.item:lower(), search)) then
            tinsert(tbl, v);
        end
    end

    table.sort(tbl, function(a,b) return a.name < b.name; end);
end

function DataQuery:GetAllInventory(tbl, includeBank)
    wipe(tbl);
    local names = self:GetItemCharacters();

    for i,v in ipairs(names) do
        self:GetInventory(v, "Inventory", tbl);
        if (includeBank) then
            self:GetInventory(v, "Bank", tbl);
        end
    end
end

function DataQuery:GetAllSales(name, subtype, tbl, search)
    self:GetAllTransactions(name, "sale", subtype, tbl, true, search);
end

function DataQuery:GetAllPurchases(name, subtype, tbl, search)
    self:GetAllTransactions(name, "buy", subtype, tbl, true, search);
end

function DataQuery:GetAllExpenses(name, types, subtype, tbl, search)
    for i,v in ipairs(types) do
        self:GetAllTransactions(name, v, subtype, tbl, true, search);
    end
end

function DataQuery:GetAllIncome(name, subtype, tbl, search)
    self:GetAllTransactions(name, "sale", subtype, tbl, true, search);
    self:GetAllTransactions(name, "income", nil, tbl, true, search);
end

function DataQuery:GetAllCancelled(name, tbl, search)
    self:GetAllTransactions(name, "cancel", nil, tbl, true, search);
end

function DataQuery:GetAllExpired(name, tbl, search)
    self:GetAllTransactions(name, "expire", nil, tbl, true, search);
end

function DataQuery:Sort(tbl, sortMode)
    if (sortMode and sortMode.reversed) then
        table.sort(tbl, 
            function(x,y)
                if (sortMode.key == "type") then
                    if (x.type == y.type and x.subtype and y.subtype) then
                        return x.subtype > y.subtype;
                    else
                        return x.type > y.type; 
                    end
                end 
                if (not x or not y or not x[sortMode.key] or not y[sortMode.key]) then
                    return false;
                end
                return x[sortMode.key] > y[sortMode.key]; 
            end);
    elseif(sortMode and not sortMode.reversed) then
        table.sort(tbl,
            function(x,y)
                if (sortMode.key == "type") then
                    if (x.type == y.type and x.subtype and y.subtype) then
                        return x.subtype < y.subtype;
                    else
                        return x.type < y.type; 
                    end
                end 
                if (not x or not y or not x[sortMode.key] or not y[sortMode.key]) then
                    return false;
                end
                return x[sortMode.key] < y[sortMode.key]; 
            end);
    end
end

function DataQuery:JoinExpired(names, tbl, search, sortMode)
    wipe(tbl);
    for i,v in ipairs(names) do
        self:GetAllExpired(v, tbl, search);
    end
    self:Sort(tbl, sortMode);
end

function DataQuery:JoinCancelled(names, tbl, search, sortMode)
    wipe(tbl);
    for i,v in ipairs(names) do
        self:GetAllCancelled(v, tbl, search);
    end
    self:Sort(tbl, sortMode);
end

function DataQuery:JoinSales(names, subtype, tbl, search, sortMode)
    wipe(tbl);
    for i,v in ipairs(names) do
        self:GetAllSales(v, subtype, tbl, search);
    end
    self:Sort(tbl, sortMode);
end

function DataQuery:JoinPurchases(names, subtype, tbl, search, sortMode)
    wipe(tbl);
    for i,v in ipairs(names) do
        self:GetAllPurchases(v, subtype, tbl, search);
    end
    self:Sort(tbl, sortMode);
end

function DataQuery:JoinExpenses(names, types, subtype, tbl, search, sortMode)
    wipe(tbl);
    for i,v in ipairs(names) do
        self:GetAllExpenses(v, types, subtype, tbl, search);
    end
    self:Sort(tbl, sortMode);
end

function DataQuery:JoinIncome(names, types, subtype, tbl, search, sortMode)
    wipe(tbl);
    for i,v in ipairs(names) do
        self:GetAllIncome(v, subtype, tbl, search);
        self:GetAllExpenses(v, types, subtype, tbl, search);
    end
    self:Sort(tbl, sortMode);
end

function DataQuery:GetTotalProfit(name, stime)
    local log = Trans:GetLog(name);
    local total = 0;
    local count = 1;

    if (log) then
        for i, rec in ipairs(log) do
            if (rec.time >= stime) then
                if (rec.type == "sale") then
                    total = total + (rec.quantity * rec.copper);
                elseif (rec.type == "buy") then
                    total = total - (rec.quantity * rec.copper);
                elseif (rec.type == "expense") then
                    total = total - rec.copper;
                elseif (rec.type == "income") then
                    total = total + rec.copper;
                elseif (rec.type == "cod") then
                    total = total - (rec.quantity * rec.copper);
                elseif (rec.type == "repair") then
                    total = total - rec.copper;
                elseif (rec.type == "postage") then
                    total = total - rec.copper;
                end
            end
        end
    end

    count = math.max(math.ceil((time() - stime) / SECONDS_PER_DAY), 1);
    return total, math.floor(total / count);
end

function DataQuery:GetTotalSales(name, stime)
    local log = Trans:GetLog(name);
    local total = 0;
    local count = 1;

    if (log) then
        for i, rec in ipairs(log) do
            if (rec.time >= stime) then
                if (rec.type == "sale") then
                    total = total + (rec.quantity * rec.copper);
                end
            end
        end
    end

    count = math.max(math.ceil((time() - stime) / SECONDS_PER_DAY), 1);
    return total, math.floor(total / count);
end

function DataQuery:GetTotalExpenses(name, stime)
    local log = Trans:GetLog(name);
    local total = 0;
    local count = 1;

    if (log) then
        for i, rec in ipairs(log) do
            if (rec.time >= stime) then
                if (rec.type == "expense") then
                    total = total + rec.copper;
                elseif (rec.type == "buy") then
                    total = total + (rec.quantity * rec.copper);
                elseif (rec.type == "repair") then
                    total = total + rec.copper;
                elseif (rec.type == "postage") then
                    total = total + rec.copper;
                end
            end
        end
    end

    count = math.max(math.ceil((time() - stime) / SECONDS_PER_DAY), 1);
    return total, math.floor(total / count);
end

function DataQuery:JoinTotalSales(names, stime)
    local total = 0;
    local tavg = 0;

    for i, v in ipairs(names) do
        local t, avg = self:GetTotalSales(v, stime);
        total = total + t;
        tavg = tavg + avg;
    end

    local ncount = #names;
    ncount = ncount == 0 and 1 or ncount;

    return total, math.floor(tavg / ncount);
end

function DataQuery:JoinTotalExpenses(names, stime)
    local total = 0;
    local tavg = 0;

    for i, v in ipairs(names) do
        local t, avg = self:GetTotalExpenses(v, stime);
        total = total + t;
        tavg = tavg + avg;
    end

    local ncount = #names;
    ncount = ncount == 0 and 1 or ncount;

    return total, math.floor(tavg / ncount); 
end

function DataQuery:JoinTotalProfit(names, stime)
    local total = 0;
    local tavg = 0;

    for i, v in ipairs(names) do
        local t, avg = self:GetTotalProfit(v, stime);
        total = total + t;
        tavg = tavg + avg;
    end

    local ncount = #names;
    ncount = ncount == 0 and 1 or ncount;

    return total, math.floor(tavg / ncount);
end

function DataQuery:GetAllTransactions(name, type, subtype, tbl, nowipe, search)
    if (not nowipe) then
        wipe(tbl);
    end

    if (search) then
        search = search:lower();
    end

    local log = Trans:GetLog(name);
    if (log) then
        for i = #log, 1, -1 do
            local rec = log[i];
            if (rec.type == type) then
                if (subtype and rec.subtype) then
                    if (rec.subtype == subtype) then
                        if (search and search ~= "") then
                            if ((rec.item and strfind(rec.item:lower(), search)) or (rec.from and strfind(rec.from:lower(), search))) then
                                tinsert(tbl, rec);
                            end
                        else
                            tinsert(tbl, rec);
                        end
                    end
                elseif (not subtype) then
                    if (search and search ~= "") then
                        if ((rec.item and strfind(rec.item:lower(), search)) or (rec.from and strfind(rec.from:lower(), search))) then
                            tinsert(tbl, rec);
                        end
                    else
                        tinsert(tbl, rec);
                    end
                end
            end
        end
    end

    table.sort(tbl, function(x,y) return x.time > y.time; end);
end

function DataQuery:GetTransactions(name, type, subtype, stime, etime, tbl, nowipe, limit, search)
    if (not nowipe) then
        wipe(tbl);
    end

    if (search) then
        search = search:lower();
    end

    local log = Trans:GetLog(name);
    if (log) then
        -- we iterate backwards to get latest first
        for i = #log, 1, -1 do
            local rec = log[i];
            if (rec.type == type) then
                if(subtype and rec.subtype) then
                    if(rec.subtype == subtype) then
                        if (rec.time >= stime and rec.time <= etime) then
                            if (search and search ~= "") then
                                if ((rec.item and strfind(rec.item:lower(), search)) or (rec.from and strfind(rec.from:lower(), search))) then
                                    tinsert(tbl, rec);
                                end
                            else
                                tinsert(tbl, rec);
                            end
                        end
                    end
                elseif (not subtype) then
                    if (rec.time >= stime and rec.time <= etime) then
                        if (search and search ~= "") then
                            if ((rec.item and strfind(rec.item:lower(), search)) or (rec.from and strfind(rec.from:lower(), search))) then
                                tinsert(tbl, rec);
                            end
                        else
                            tinsert(tbl, rec);
                        end
                    end
                end
            end

            if (limit and limit > 0 and #tbl >= limit) then
                break;
            end
        end
    end

    table.sort(tbl, function(x,y) return x.time > y.time; end);
end

function DataQuery:JoinTransactions(names, type, subtype, stime, etime, tbl, limit, search)
    wipe(tbl);

    local lt = limit or 100;
    for i,v in ipairs(names) do
        self:GetTransactions(v, type, subtype, stime, etime, tbl, true, lt * i, search);
    end
end

function DataQuery:JoinGoldAt(names, type, stime, tbl)
    wipe(tbl);
    local max = 0;

    for i, v in ipairs(names) do
        self:GetGoldAt(v, type, stime, goldHolder);
        local m = goldHolder[1];

        if (m) then
            max = max + m;
        end
    end

    tinsert(tbl, max);
end

function DataQuery:JoinGold(names, type, stime, etime, tbl, limit)
    wipe(tbl);

    local max = 0;

    for i, v in ipairs(names) do
        self:GetGold(v, type, stime, etime, goldHolder, limit);

        local r = goldHolder[1];

        if (r) then
            max = max + r.total;
        end
    end

    tinsert(tbl, max);
end

function DataQuery:CurrentGold(names, tbl)
    wipe(tbl);

    for i, v in ipairs(names) do
        local log = GTrack:GetPlayerLog(v);

        if (log) then
            tinsert(tbl, log.current);
        end
    end
end

function DataQuery:GetGoldAt(name, type, stime, tbl)
    wipe(tbl);

    local log = GTrack:GetPlayerLog(name);

    if (not log or #log.ledger == 0) then
        tinsert(tbl, 0);
        return;
    end

    if (log) then
        local ledger = log.ledger;
        local i;
        for i = #ledger, 1, -1 do
            local record = ledger[i];
            if (record.time <= stime) then
                tinsert(tbl, record.total);
                return;
            end
        end
        tinsert(tbl, 0);
    end
end

function DataQuery:GetGold(name, type, stime, etime, tbl, limit)
    wipe(tbl);

    local log = GTrack:GetPlayerLog(name);
    if (log) then
        local ledger = log.ledger;
        local i;
        for i = 1, #ledger do
            local record = ledger[i];

            if (record.time >= stime and record.time <= etime) then
                tinsert(tbl, record);
            end

            if (limit and limit > 0 and #tbl >= limit) then
                break;
            end
        end
    end

    table.sort(tbl, function(x, y) return x.time > y.time; end);
end

