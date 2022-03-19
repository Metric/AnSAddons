local Ans = select(2, ...);
local Data = Ans.Data;
local VendorData = Data.Vendor;
local Config = Ans.Config;
local Sources = Ans.Object.Register("Sources");
Sources.items = {};

local Utils = Ans.Utils;
local PriceSource = Ans.PriceSource;
local IsSocketBonus = Ans.Data.SocketBonus;
local IsSocketCrafted = Ans.Data.SocketCrafted;

local NAME_CACHE = "";
local CVAR_CACHE = "";
local BONUS_CACHE = {};

local OpCodes = Ans.Object.Register("OpCodes", Sources);

local timingEnabled = false;
local timing = GetTime();
local function Timestamp(stop, tag)
    if (not timingEnabled) then
        return;
    end

    if (not stop) then
        timing = GetTime();
        return;
    end

    local diff = GetTime() - timing;
    print("Ans - Timestamp: "..diff.." | "..tag);
end

function OpCodes:Acquire() 
    local op = {};
    op.percent = 0;
    op.ppu = 0;
    op.stacksize = 0;
    op.buyout = 0;
    op.ilevel = 0;
    op.vendorsell = 0;
    op.vendorbuy = 0;
    op.quality = 1;
    op.dbmarket = 0;
    op.dbminbuyout = 0; 
    op.dbhistorical = 0; 
    op.dbregionmarketavg = 0;
    op.dbregionminbuyoutavg = 0; 
    op.dbregionhistorical = 0; 
    op.dbregionsaleavg = 0; 
    op.dbregionsalerate = 0; 
    op.dbregionsoldperday = 0;
    op.tujmarket = 0; 
    op.tujrecent = 0; 
    op.tujglobalmedian = 0; 
    op.tujglobalmean = 0;
    op.tujage = 0;
    op.tujdays = 0; 
    op.tujstddev = 0; 
    op.tujglobalstddev = 0;
    op.atrvalue = 0;
    op.ansrecent = 0;
    op.ansmarket = 0;
    op.ansmin = 0;
    op.ans3day = 0;
    op.ansregionmarket = 0;
    op.ansregionmin = 0;
    op.avgsell = 0;
    op.avgbuy = 0;
    op.maxsell = 0;
    op.maxbuy = 0;
    op.destroy = 0;
    op.numinventory = 0;
    op.isgroup = false;
    op.bonuses = BONUS_CACHE;
    op.socket = false;
    return op;
end

local VAR_CACHE = {};

local OP_CACHE = {};
local VALUE_CACHE = {};

local VAR_TEMPLATE = "local %s = %s or 0; ";

local TEMPLATE = [[
    return function(sources, ops)
        local ifgte, iflte, iflt, ifgt, ifeq, ifneq, check, avg, first, round,
            min, max, mod, 
            abs, ceil, floor, random, log, 
            log10, exp, sqrt = sources.ifgte, sources.iflte, sources.iflt, sources.ifgt, sources.ifeq, sources.ifneq, sources.check, sources.avg, sources.first, sources.round, sources.min, sources.max, math.fmod, math.abs, math.ceil, math.floor, math.random, math.log, math.log10, math.exp, math.sqrt;

        local isgroup, isGroup = ops.isgroup, ops.isgroup;
        local Socket, socket = ops.socket, ops.socket;
        local eq, neq, startswith, contains = sources.eq, sources.neq, sources.startswith, sources.contains;
        local bonuses = ops.bonuses;
        local bonus = function(v1,v2,v3)
            local noArgs = v2 == nil and v3 == nil;
            if (isgroup) then
                if (noArgs) then
                    return true;
                end
                return v2 or 0;
            end
            return sources.bonus(bonuses, v1, v2, v3);
        end

        local percent, Percent = ops.percent, ops.percent;
        local ppu, Ppu, PPU = ops.ppu, ops.ppu, ops.ppu;
        local stacksize, StackSize = ops.stacksize, ops.stacksize;
        local buyout, Buyout = ops.buyout, ops.buyout;
        local avgbuy, avgBuy, AvgBuy, Avgbuy = ops.avgbuy, ops.avgbuy, ops.avgbuy, ops.avgbuy;
        local avgsell, avgSell, AvgSell, Avgsell = ops.avgsell, ops.avgsell, ops.avgsell, ops.avgsell;
        local destroy, Destroy = ops.destroy, ops.destroy;
        local maxsell, maxSell, MaxSell, Maxsell = ops.maxsell, ops.maxsell, ops.maxsell, ops.maxsell;
        local maxbuy, maxBuy, MaxBuy, Maxbuy = ops.maxbuy, ops.maxbuy, ops.maxbuy, ops.maxbuy;
        local ilevel, ilevel, itemLevel, ItemLevel, itemlevel, Itemlevel = ops.ilevel, ops.ilevel, ops.ilevel, ops.ilevel, ops.ilevel, ops.ilevel;
        local quality, itemquality, itemQuality, ItemQuality, Itemquality = ops.quality, ops.quality, ops.quality, ops.quality, ops.quality;
        local vendorsell, vendorSell, Vendorsell, VendorSell = ops.vendorsell, ops.vendorsell, ops.vendorsell, ops.vendorsell;
        local vendorbuy, vendorBuy, VendorBuy, Vendorbuy = ops.vendorbuy, ops.vendorbuy, ops.vendorbuy, ops.vendorbuy;
        local tsmId, tsmid, tsmID = ops.tsmId, ops.tsmId, ops.tsmId;
        local id, Id, ID = ops.id, ops.ids, ops.id;

        local dbmarket, DBMarket, Dbmarket = ops.dbmarket, ops.dbmarket, ops.dbmarket;
        local dbminbuyout, DBMinBuyout, Dbminbuyout = ops.dbminbuyout, ops.dbminbuyout, ops.dbminbuyout;
        local dbhistorical, DBHistorical, Dbhistorical = ops.dbhistorical, ops.dbhistorical, ops.dbhistorical;

        local dbregionminbuyoutavg, DBRegionMinBuyoutAvg, Dbregionminbuyoutavg = ops.dbregionminbuyoutavg, ops.dbregionminbuyoutavg, ops.dbregionminbuyoutavg;
        local dbregionmarketavg, DBRegionMarketAvg, Dbregionmarketavg = ops.dbregionmarketavg, ops.dbregionmarketavg, ops.dbregionmarketavg;
        local dbregionhistorical, DBRegionHistorical, Dbregionhistorical = ops.dbregionhistorical, ops.dbregionhistorical, ops.dbregionhistorical;
        local dbregionsaleavg, DBRegionSaleAvg, Dbregionsaleavg = ops.dbregionsaleavg, ops.dbregionsaleavg, ops.dbregionsaleavg, ops.dbregionsaleavg;
        local dbregionsalerate, DBRegionSaleRate, Dbregionsalerate = ops.dbregionsalerate, ops.dbregionsalerate, ops.dbregionsalerate;
        local dbregionsoldperday, DBRegionSoldPerDay, Dbregionsoldperday = ops.dbregionsoldperday, ops.dbregionsoldperday, ops.dbregionsoldperday; 
        local numinventory, NumInventory, Numinventory, numInventory = ops.numinventory, ops.numinventory, ops.numinventory, ops.numinventory;

        local atrvalue, AtrValue, Atrvalue = ops.atrvalue, ops.atrvalue, ops.atrvalue;
        
        local ansmin, Ansmin, ANSmin, ANSMin, AnsMin = ops.ansmin, ops.ansmin, ops.ansmin, ops.ansmin, ops.ansmin;
        local ansmarket, Ansmarket, ANSmarket, ANSMarket, AnsMarket = ops.ansmarket, ops.ansmarket, ops.ansmarket, ops.ansmarket, ops.ansmarket;
        local ans3day, Ans3day, Ans3Day, ANS3day, ANS3Day = ops.ans3day, ops.ans3day, ops.ans3day, ops.ans3day, ops.ans3day;
        local ansrecent, Ansrecent, ANSrecent, ANSRecent, AnsRecent = ops.ansrecent, ops.ansrecent, ops.ansrecent, ops.ansrecent, ops.ansrecent;
        local ansregionmin, AnsRegionMin, ANSRegionMin, ansRegionMin = ops.ansregionmin, ops.ansregionmin, ops.ansregionmin, ops.ansregionmin;
        local ansregionmarket, AnsRegionMarket, ANSRegionMarket, ansRegionMarket = ops.ansregionmarket, ops.ansregionmarket, ops.ansregionmarket, ops.ansregionmarket;

        local tujmarket, tujMarket, TUJMarket, TUJmarket = ops.tujmarket, ops.tujmarket, ops.tujmarket, ops.tujmarket;
        local tujglobalmean, tujGlobalMean, TUJGlobalMean, TUJglobalmean = ops.tujglobalmean, ops.tujglobalmean, ops.tujglobalmean, ops.tujglobalmean;
        local tujdays, tujDays, TUJDays, TUJdays = ops.tujdays, ops.tujdays, ops.tujdays, ops.tujdays;

        %s

        return %s;
    end
]];


function Sources:Clear()
    Utils.ClearCache();

    NAME_CACHE = "";
    CVAR_CACHE = "";
    
    wipe(VALUE_CACHE);
    wipe(OP_CACHE);
    wipe(BONUS_CACHE);
end

function Sources:ClearValues()
    wipe(VALUE_CACHE);
end

function Sources:LoadCVars()
    wipe(VAR_CACHE);
    for i,v in ipairs(Config.CustomSources()) do
        local value = v.value;

        if (value and value:len() > 0) then
            value = Utils.ReplaceOpShortHand(value);
            value = Utils.ReplaceShortHandPercent(value);
            value = Utils.ReplaceMoneyShorthand(value); 

            tinsert(VAR_CACHE, {name = v.name, value = value});
        end
    end
end

function Sources:Register(name, fn, key)
    local n = name:lower();
    local source = PriceSource:Acquire(n,fn,key);
    tinsert(self.items, source);
end

function Sources:GetNameString()
    local str = "";
    local sep = "";
    local i;

    if (NAME_CACHE and NAME_CACHE:len() > 0) then
        return NAME_CACHE;
    end

    for i = 1, #self.items do
        local s = self.items[i];
        if (s.fn ~= nil) then
            str = str..sep..s.name;
            sep = ",";
        end
    end

    -- cache for future lookups
    NAME_CACHE = str;

    return str;
end

function Sources:GetCVarString()
    local str = "";
    local i;

    if (CVAR_CACHE and CVAR_CACHE:len() > 0) then
        return CVAR_CACHE;
    else
        self:LoadCVars();
    end

    for i = 1, #VAR_CACHE do
        local cvar = VAR_CACHE[i];
        local nstr = string.format(VAR_TEMPLATE, cvar.name, cvar.value);
        str = str..nstr;
    end

    CVAR_CACHE = str;

    return str;
end

function Sources:IsValidQuery(q)
    -- check for matching ()

    local sindex = 1;
    sindex = string.find(q, "%s?%(%s?", sindex);

    -- since no start (  was found
    -- check for straggling )
    if (not sindex) then
        sindex = string.find(q, "%s?%)%s?", 1);

        if (sindex) then
            return false;
        end
    end

    while (sindex) do
        sindex = sindex + 1;
        sindex = string.find(q, "%s?%)%s?", sindex);
        if (not sindex) then
            return false;
        end
        sindex = sindex + 1;
        sindex = string.find(q, "%s?%(%s?", sindex);
    end

    return true;
end

function Sources:GetValues(itemId, ops)
    local i;
    local total = #self.items;

    for i = 1, total do
        local s = self.items[i];
        if (s.fn ~= nil) then
            local r = s.fn(itemId, s.key, s.name);
            local v = r or 0;
            ops[s.name] = v;
        end
    end
end

Sources.round = function(n)
    if (n < 0) then
        return math.floor(n - 0.5);
    end
    
    return math.floor(n + 0.5);
end

Sources.avg = function(...)
    local totalItems = select("#", ...);

    local i;
    local t = 0;
    local amt = 0;

    for i = 1, totalItems do
        local v = select(i, ...);
        if (v and type(v) == "number" 
            and math.floor(v) > 0) then
                amt = amt + v;
                t = t + 1;
        end
    end

    if t == 0 then
        return amt;
    end

    return Sources.round(amt / t);
end

Sources.first = function(...)
    local totalItems = select("#", ...);

    local i;

    for i = 1, totalItems do
        local v = select(i, ...);
        if (v and type(v) == "number") 
            and math.floor(v) > 0 then
                return v or 0;
        end
    end

    return 0;
end

Sources.check = function(v1,v2,v3)
    if (v1 and type(v1) == "number" 
        and math.floor(v1) > 0) then
            return v2 or 0;
    end
    
    return v3 or 0;
end

Sources.iflte = function(v1, v2, v3, v4)
    if (not v1 or type(v1) ~= "number") then
        return v4 or 0;
    end

    if (not v2 or type(v2) ~= "number") then
        return v3 or 0;
    end

    if (v1 <= v2) then
        return v3 or 0;
    end
    
    return v4 or 0;
end

Sources.ifgte = function(v1, v2, v3, v4)
    if (not v1 or type(v1) ~= "number") then
        return v4 or 0;
    end

    if (not v2 or type(v2) ~= "number") then
        return v3 or 0;
    end

    if (v1 >= v2) then
        return v3 or 0;
    end
    
    return v4 or 0;
end

Sources.iflt = function(v1, v2, v3, v4)
    if (not v1 or type(v1) ~= "number") then
        return v4 or 0;
    end

    if (not v2 or type(v2) ~= "number") then
        return v3 or 0;
    end

    if (v1 < v2) then
        return v3 or 0;
    end

    return v4 or 0;
end

Sources.ifgt = function(v1, v2, v3, v4)
    if (not v1 or type(v1) ~= "number") then
        return v4 or 0;
    end

    if (not v2 or type(v2) ~= "number") then
        return v3 or 0;
    end

    if (v1 > v2) then
        return v3 or 0;
    end
    
    return v4 or 0;
end

Sources.ifeq = function(v1, v2, v3, v4)
    if (v1 == v2) then
        return v3 or 0;
    end
    
    return v4 or 0;
end

Sources.ifneq = function(v1, v2, v3, v4)
    if (v1 ~= v2) then
        return v3 or 0;
    end
    
    return v4 or 0;
end

Sources.neq = function(v1,v2,v3,v4)
    if (v1 ~= v2) then     
        return v3 or 0;
    end

    return v4 or 0;
end

Sources.eq = function(v1,v2,v3,v4)
    if (v1 == v2) then
        return v3 or 0;
    end

    return v4 or 0;
end

Sources.startswith = function(v1, v2, v3, v4)
    local noArgs = v3 == nil and v4 == nil;

    if (not v1 or type(v1) ~= "string") then
        if (noArgs) then
            return false;
        end
        return v4 or 0;
    end

    if (not v2 or type(v2) ~= "string") then
        if (noArgs) then
            return false;
        end
        return v4 or 0;
    end

    if (strsub(v1, 1, #v2) == v2) then
        if (noArgs) then
            return true;
        end
        return v3 or 0;
    end

    if (noArgs) then
        return false;
    end
    return v4 or 0;
end

Sources.contains = function(v1, v2, v3, v4)
    local noArgs = v3 == nil and v4 == nil;

    if (not v1 or type(v1) ~= "string") then
        if (noArgs) then
            return false;
        end
        return v4 or 0;
    end

    if (not v2 or type(v2) ~= "string") then
        if (noArgs) then
            return true;
        end
        return v3 or 0;
    end

    if (strfind(v1, v2)) then
        if (noArgs) then
            return true;
        end
        return v3 or 0;
    end

    if (noArgs) then
        return false;
    end
    return v4 or 0;
end

Sources.bonus = function(v1,v2,v3,v4)
    local noArgs = v3 == nil and v4 == nil;

    if (not v1 or not v2) then
        if (noArgs) then
            return false;
        end
        return v4 or 0;
    end

    local b = v1[v2];

    if (b) then
        if (noArgs) then
            return true;
        end
        return v3 or 0; 
    end

    if (noArgs) then
        return false;
    end
    return v4 or 0;
end

Sources.max = function(...)
    local c = select("#", ...);
    local lastMax = -math.huge;
    for i = 1, c do
        local v = select(i, ...);
        if (v and type(v) == "number") then
            if (v ~= 0) then
                lastMax = math.max(lastMax, v);
            end
        end
    end
    return lastMax == -math.huge and 0 or lastMax;
end

Sources.min = function(...)
    local c = select("#", ...);
    local lastMin = math.huge;
    for i = 1, c do
        local v = select(i, ...);
        if (v and type(v) == "number") then
            if (v ~= 0) then
                lastMin = math.min(lastMin, v);
            end
        end
    end
    return lastMin == math.huge and 0 or lastMin;
end

-- This accepts an item id in tsm format, numeric, or an item link
function Sources:QueryID(q, itemId)
    if (not itemId) then
        return nil;
    end
    
    local codes = nil;

    local names = self:GetNameString();
    if (not names or names:len() == 0 ) then
        return nil;
    end

    if (not q or q:len() == 0) then
        return nil;
    end

    if (VALUE_CACHE[itemId]) then
        codes = VALUE_CACHE[itemId];
    else 
        codes = OpCodes:Acquire();
        VALUE_CACHE[itemId] = codes;
        self:GetValues(itemId, codes);
    end

    codes.buyout = 0;
    codes.stacksize = 0;
    codes.quality = 99;
    codes.percent = 0;
    codes.ppu = 0;
    codes.ilevel = 0;
    codes.vendorsell = 0;
    codes.tsmId = Utils.GetID(itemId);
    codes.isgroup = false;

    local idBonusOnly, socket = Utils.BonusID(codes.tsmId, false, codes.bonuses, IsSocketBonus);

    local t, id = strsplit(":", codes.tsmId); 

    if (t == "p") then
        idBonusOnly = t..":"..id;
    end

    codes.vendorbuy = Config.Vendor()[idBonusOnly] or VendorData[idBonusOnly] or 0;

    codes.id = tonumber(id);
    codes.socket = socket or IsSocketCrafted(codes.id);

    local _, fn, err = false, nil, nil;
    local oq = q;

    if (not OP_CACHE[q]) then
        q = Utils.ReplaceOpShortHand(q);
        q = Utils.ReplaceShortHandPercent(q);
        q = Utils.ReplaceMoneyShorthand(q);    
        q = Utils.ReplaceTabReturns(q);

        --print(q);

        if (not self:IsValidQuery(q)) then
            print("AnS Invalid Filter / Pricing String: "..q);
            return 0;
        end

        local pstr = string.format(TEMPLATE, self:GetCVarString(), q);

        fn, err = loadstring(pstr);

        if(not fn or err) then
            print("AnS Filter / Pricing String Error: "..err);
            return 0;
        end

        _, fn = pcall(fn);

        if (not _ or not fn) then
            print("AnS Invalid Filter / Pricing String: "..q);
            return 0;
        end

        OP_CACHE[oq] = fn;
    else
        fn = OP_CACHE[oq];
    end

    if (not fn) then
        return 0;
    end

    local _, r = pcall(fn, self, codes);

    if (not _) then
        print("AnS Invalid Filter / Pricing String: "..q);
        return 0;
    end 

    return r;
end

function Sources:Validate(q)
    local itemId = "i:2589";

    local codes = nil;

    local names = self:GetNameString();
    if (not names or names:len() == 0 ) then
        return nil;
    end

    if (not q or q:len() == 0) then
        return nil;
    end

    if (VALUE_CACHE[itemId]) then
        codes = VALUE_CACHE[itemId];
    else 
        codes = OpCodes:Acquire();
        VALUE_CACHE[itemId] = codes;
        self:GetValues(itemId, codes);
    end

    codes.buyout = 0;
    codes.stacksize = 0;
    codes.quality = 99;
    codes.percent = 0;
    codes.ppu = 0;
    codes.ilevel = 0;
    codes.vendorsell = 0;
    codes.tsmId = itemId;
    codes.vendorbuy = 0;
    codes.id = 2589;
    codes.isgroup = false;

    local _, fn, err = false, nil, nil;
    local oq = q;

    if (not OP_CACHE[q]) then
        q = Utils.ReplaceOpShortHand(q);
        q = Utils.ReplaceShortHandPercent(q);
        q = Utils.ReplaceMoneyShorthand(q);    
        q = Utils.ReplaceTabReturns(q);

        --print(q);

        if (not self:IsValidQuery(q)) then
            return false;
        end

        local pstr = string.format(TEMPLATE, self:GetCVarString(), q);

        fn, err = loadstring(pstr);

        if(not fn or err) then
            return false;
        end

        _, fn = pcall(fn);

        if (not _ or not fn) then
            return false;
        end

        OP_CACHE[oq] = fn;
    else
        fn = OP_CACHE[oq];
    end

    if (not fn) then
        return false;
    end

    local _, r = pcall(fn, self, codes);

    if (not _) then
        return false;
    end 

    return true;
end

function Sources:Query(q, item, isGroup)
    local itemId = item.link or item.id;
    local buyout = item.buyoutPrice;
    local stackSize = item.count;
    local quality = item.quality;
    local ilvl = item.iLevel;
    local percent = item.percent;
    local ppu = item.ppu;

    if (not itemId) then
        return nil;
    end
    
    local codes = nil;

    local names = self:GetNameString();
    if (not names or names:len() == 0 ) then
        return nil;
    end

    if (not q or q:len() == 0) then
        return nil;
    end

    if (VALUE_CACHE[itemId]) then
        codes = VALUE_CACHE[itemId];
    else 
        codes = OpCodes:Acquire();
        VALUE_CACHE[itemId] = codes;
        self:GetValues(itemId, codes);
    end

    if (not item.tsmId and item.link) then
        item.tsmId = Utils.GetID(item.link);
    end

    local idBonusOnly, socket = Utils.BonusID(item.tsmId or item.link or item.id, false, codes.bonuses, IsSocketBonus);

    if (item.tsmId and item.isPet) then
        local t, id = strsplit(":", item.tsmId); 

        if (t == "p") then
            idBonusOnly = t..":"..id;
        end
    end

    codes.buyout = buyout;
    codes.stacksize = stackSize;
    codes.quality = quality;
    codes.percent = percent;
    codes.ppu = ppu;
    codes.ilevel = ilvl;
    codes.vendorsell = item.vendorsell;
    codes.tsmId = item.tsmId;
    codes.id = item.id;
    codes.vendorbuy = Config.Vendor()[idBonusOnly] or VendorData[idBonusOnly] or 0;
    codes.isgroup = isGroup;
    codes.socket = socket or IsSocketCrafted(codes.id);

    local _, fn, err = false, nil, nil;
    local oq = q;

    if (not OP_CACHE[q]) then
        q = Utils.ReplaceOpShortHand(q);
        q = Utils.ReplaceShortHandPercent(q);
        q = Utils.ReplaceMoneyShorthand(q);    
        q = Utils.ReplaceTabReturns(q);

        --print(q);

        if (not self:IsValidQuery(q)) then
            print("AnS Invalid Filter / Pricing String: "..q);
            return 0;
        end

        local pstr = string.format(TEMPLATE, self:GetCVarString(), q);

        fn, err = loadstring(pstr);

        if(not fn or err) then
            print("AnS Filter / Pricing String Error: "..err);
            return 0;
        end

        _, fn = pcall(fn);

        if (not _ or not fn) then
            print("AnS Invalid Filter / Pricing String: "..q);
            return 0;
        end

        OP_CACHE[oq] = fn;
    else
        fn = OP_CACHE[oq];
    end

    if (not fn) then
        return 0;
    end

    local _, r = pcall(fn, self, codes);

    if (not _) then
        print("AnS Invalid Filter / Pricing String: "..q);
        return 0;
    end 

    return r;
end