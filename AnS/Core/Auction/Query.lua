local Ans = select(2, ...);

local Utils = Ans.Utils;
local Sources = Ans.Sources;

local Query = {};
Query.__index = Query;
Query.SORT_METHODS = {
    NAME = 1,
    PRICE = 2,
    PERCENT = 3,
    RECENT = 4,
    ILEVEL = 5
};

Ans.Query = Query;

local Recycler = { blocks = {}, auctions = {}};
Recycler.__index = Recycler;

Ans.Recycler = Recycler;

local Auction = {};
Auction.__index = Auction;

function Auction:New()
    local a = {};
    setmetatable(a, Auction);
    a.group = {};
    return a;
end

function Auction:Clone()
    local a = Recycler:GetAuction();
    a.id = self.id;
    a.name = self.name;
    a.texture = self.texture;
    a.count = self.count;
    a.quality = self.quality;
    a.canUse = self.canUse;
    a.level = self.level;
    a.huh = self.huh;
    a.minBid = self.minBid;
    a.minIncrement = self.minIncrement;
    a.buyoutPrice = self.buyoutPrice;
    a.bid = self.bid;
    a.highBidder = self.highBidder;
    a.bidderFullName = self.bidderFullName;
    a.owner = self.owner;
    a.ownerFullName = self.ownerFullName;
    a.saleStatus = self.saleStatus;
    a.hasAll = self.hasAll;
    a.link = self.link;
    a.time = self.time;
    a.sniped = self.sniped;
    a.percent = self.percent;
    a.tsmId = self.tsmId;
    a.iLevel = self.iLevel;
    a.type = self.type;
    a.subtype = self.subtype;
    a.ppu = self.ppu;
    a.vendorsell = self.vendorsell;

    local tg = #self.group;
    if (tg > 0) then
        local i;

        for i = 1, tg do
            tinsert(a.group, self.group[i]:Clone());
        end 
    end

    return a;
end

local AuctionBlock = {};
AuctionBlock.__index = AuctionBlock;

function AuctionBlock:New()
    local b = {};
    setmetatable(b, AuctionBlock);
    
    b.page = -1;
    b.index = -1;
    b.item = nil;
    b.queryId = -1;

    return b;
end

function AuctionBlock:Clone()
    local b = Recycler:GetBlock();
    b.page = self.page;
    b.index = self.index;
    b.queryId = self.queryId;

    if (self.item) then
        b.item = self.item:Clone();
    else
        b.item = nil;
    end

    return b;
end

function Recycler:Reset()
    wipe(self.blocks);
    wipe(self.auctions);
end

function Recycler:RecycleAuction(auction)
    local group = auction.group;
    local gtotal = #group;

    local i;
    for i = 1, gtotal do
        local r = group[i];
        if (r) then
            self:RecycleBlock(r);
        end
    end
    wipe(group);
    tinsert(self.auctions, auction);
end

function Recycler:RecycleBlock(block)
    if (block) then
        local item = block.item;
        tinsert(self.blocks, block);

        if (item) then
            self:RecycleAuction(item);
        end
    end
end

function Recycler:GetBlock() 
    if (#self.blocks > 0) then
        return tremove(self.blocks);
    end
    return AuctionBlock:New();
end

function Recycler:GetAuction()
    if (#self.auctions > 0) then
        return tremove(self.auctions);
    end
    return Auction:New();
end

local lastFoundHash = "";

local function Truncate(str)
    if(str:len() <= 63) then
        return str;
    end

    return str:sub(1, 62);
end

function Query:ClearLastHash() 
    lastFoundHash = "";
end

function Query:Reset()
    lastFoundHash = "";
    self.index = 0;
    wipe(self.auctions);
    wipe(self.filters);
    wipe(self.blacklist);
    wipe(self.groupTempTable);
    Recycler:Reset();
    Utils:ClearTSMIDCache();
end

function Query:New(search)
    local query = {};
    setmetatable(query, Query);

    query.search = Truncate(search);
    query.index = 0;
    query.auctions = {};
    query.count = 0;
    query.previous = nil;
    query.total = -1;
    query.filters = {};

    query.minILevel = 0;
    query.maxBuyout = 0;
    query.quality = 1;
    query.minStackSize = 0;
    query.maxPercent = 100;

    query.blacklist = {};

    query.id = 0;
    query.groupTempTable = {};

    return query;
end

function Query:AssignFilters(filters, ilevel, buyout, quality, size, maxPercent)
    wipe(self.filters);

    self.minILevel = ilevel;
    self.maxBuyout = buyout;
    self.quality = quality;
    self.minStackSize = size;
    self.maxPercent = maxPercent;

    local i;
    for i = 1, #filters do
        local f = filters[i]:Clone();
        f:AssignOptions(ilevel, buyout, quality, size, maxPercent, ANS_GLOBAL_SETTINGS.pricingFn);
        tinsert(self.filters, f);
    end
end

function Query:Set(search) 
    self.search = Truncate(search);
    self.index = 0;
    self.count = 0;
    
    self.total = -1;
    self.previous = nil;
end

function Query:IsReady()
    local query, queryAll = CanSendAuctionQuery();
    return query;
end

function Query:Search(quality, exact)
    local query, queryAll = CanSendAuctionQuery();

    quality = quality or 1;
    exact = exact or false;

    if (query) then
        self.id = math.fmod(self.id + 1, 100000);
        if(self.search == "" or self.search:len() == 0)then
            QueryAuctionItems(nil, nil, nil, self.index, false, quality);
        else
            QueryAuctionItems(self.search, nil, nil, self.index, false, quality, false, exact);
        end
    end

    return query;
end

function Query:Next() 
    self.index = self.index + 1;
end

local sortAsc = false;

local function Sort_By_Name(x,y)
    if (x.item and y.item) then
        if (sortAsc) then
            return x.item.name < y.item.name;
        else
            return x.item.name > y.item.name;
        end
    else
        if (sortAsc) then
            return x.name < y.name;
        else
            return x.name > y.name;
        end
    end
end

local function Sort_By_Percent(x,y)
    if (x.item and y.item) then
        if (sortAsc) then
            return x.item.percent < y.item.percent;
        else
            return x.item.percent > y.item.percent;
        end
    else
        if (sortAsc) then
            return x.percent < y.percent;
        else
            return x.percent > y.percent;
        end
    end
end

local function Sort_By_Price(x,y)
    if (x.item and y.item) then
        if (sortAsc) then
            return x.item.ppu < y.item.ppu;
        else
            return x.item.ppu > y.item.ppu;
        end
    else
        if (sortAsc) then
            return x.ppu < y.ppu;
        else
            return x.ppu > y.ppu;
        end
    end
end

local function Sort_By_Time(x,y)
    if (x.item and y.item) then
        if (sortAsc) then
            return x.item.time < y.item.time;
        else
            return x.item.time > y.item.time;
        end
    else
        if (sortAsc) then
            return x.time < y.time;
        else
            return x.time > y.time;
        end
    end
end

local function Sort_By_iLevel(x,y)
    if (x.item and y.item) then
        if (sortAsc) then
            return x.item.iLevel < y.item.iLevel;
        else
            return x.item.iLevel > y.item.iLevel;
        end
    else
        if (sortAsc) then
            return x.iLevel < y.iLevel;
        else
            return x.iLevel > y.iLevel;
        end
    end
end

local function ItemHash(item, pg)
    local owner = "?";

    if (item.owner) then
        owner = item.owner;
    end

    local page = "";

    if (pg) then
        page = pg;
    end

    return item.link..item.count..item.ppu..owner..page;
end

function Query:AddToBlacklist(item)
    self.blacklist[ItemHash(item)] = true;
end

function Query:AddAllToBlacklist(item)
    self.blacklist[item.tsmId] = true;
end

----
-- Only sorts the auctions in this page query
----
function Query:Items(sort,asc,toTbl)
    -- set local variable for sort functions
    sortAsc = asc;
    if (self.count > 1) then
        if (sort == self.SORT_METHODS.NAME) then
            table.sort(self.auctions, Sort_By_Name);
        elseif (sort == self.SORT_METHODS.PRICE) then
            table.sort(self.auctions, Sort_By_Price);
        elseif (sort == self.SORT_METHODS.PERCENT) then
            table.sort(self.auctions, Sort_By_Percent);
        elseif (sort == self.SORT_METHODS.RECENT) then
            table.sort(self.auctions, Sort_By_Time);
        elseif (sort == self.SORT_METHODS.ILEVEL) then
            table.sort(self.auctions, Sort_By_iLevel);
        end
    end

    if (toTbl) then
        for i, v in ipairs(toTbl) do
            Recycler:RecycleBlock(v);
        end
        wipe(toTbl);
        for i, v in ipairs(self.auctions) do
            tinsert(toTbl, v:Clone());
        end
    end

    return self.auctions;
end

function Query:IsValid(item) 
    if (item.iLevel < self.minILevel) then
        return false;
    end
    if (item.ppu > self.maxBuyout and self.maxBuyout > 0) then
        return false;
    end
    if (item.percent > self.maxPercent) then
        return false;
    end
    if (item.count < self.minStackSize) then
        return false;
    end
    if (item.quality < self.quality) then
        return false;
    end

    return true;
end

----------------------
-- Capture page info but in a lighter fashion
-- since we will need to scan again to buy
-- anyway
-- the major difference is, it doesn't keep track
-- of group page index and instead
-- only groups items together on a page by page basis
-- this allows for less tables created
-- but it is less accurate and thus
-- needs a search before trying to purchase
----------------------

function Query:CaptureLight(noGroup)
    self.count, self.total = GetNumAuctionItems("list");

    local x;
    local groupLookup = self.groupTempTable;

    local auction = {};

    for x = 1, self.count do
        auction.name,
        auction.texture,
        auction.count,
        auction.quality,
        auction.canUse,
        auction.level,
        auction.huh,
        auction.minBid,
        auction.minIncrement,
        auction.buyoutPrice,
        auction.bid,
        auction.highBidder,
        auction.bidderFullName,
        auction.owner,
        auction.ownerFullName,
        auction.saleStatus,
        auction.id,
        auction.hasAll = GetAuctionItemInfo("list", x);
        auction.link = GetAuctionItemLink("list", x);
        auction.time = GetAuctionItemTimeLeft("list", x);
        auction.sniped = false;
        auction.percent = 1000;

        if (auction.link ~= nil) then
            auction.tsmId = Utils:GetTSMID(auction.link);

            -- a cageable pet if auction id = 82800
            if (auction.id == 82800) then
                auction.iLevel = 0;
                auction.type = "pet";
                auction.subtype = "normal";
                auction.vendorsell = 0;
            -- otherwise normal item auction
            else
                local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, stackSize, _, _, vendorsell  = GetItemInfo(auction.link);
                if (itemName ~= nil) then
                    auction.iLevel = itemLevel;
                    auction.type = itemType:lower();
                    auction.subtype = itemSubType:lower();
                    auction.vendorsell = vendorsell;
                else
                    auction.iLevel = 0;
                    auction.type = "Unknown";
                    auction.subtype = "Unknown";
                    auction.vendorsell = 0;
                end
            end
        else
            auction.tsmId = "i:"..auction.id;
            auction.iLevel = 0;
            auction.type = "Unknown";
            auction.subtype = "Unknown";
            auction.vendorsell = 0;
        end

        local ownerName;
        if (not auction.ownerFullName) then
            ownerName = auction.owner;
        else
            ownerName = auction.ownerFullName;
        end

        local blacklist = ANS_GLOBAL_SETTINGS.characterBlacklist;
        local isOnBlacklist = false;

        if (ownerName) then
            isOnBlacklist = Utils:InTable(blacklist, ownerName:lower());
        end

        -- according to blizzard's own code for their auction house ui, hasAll fixed bug: 145328
        -- a basic assumption based on the action performed by them, is the auction should be hidden
        -- until it has all the information
        if (auction.buyoutPrice > 0 and auction.saleStatus == 0 and auction.hasAll and ownerName ~= UnitName("player") and not isOnBlacklist) then
            local ppu = math.floor(auction.buyoutPrice / auction.count);
            auction.ppu = ppu;

            local hash = ItemHash(auction);

            local avg = Sources:Query(ANS_GLOBAL_SETTINGS.percentFn, auction);
            if (not avg or avg <= 0) then avg = auction.vendorsell or 1; end;

            auction.page = self.index;
            auction.percent = math.floor(ppu / avg * 100);
            auction.queryId = self.id;
            auction.stack = 1;
            auction.total = 1;

            if (not noGroup) then
                local idx = groupLookup[hash];
                if  (idx and idx > 0) then
                    local block = self.auctions[idx];
                    block.stack = block.stack + 1;
                    block.total = block.total + 1;

                    if (not Utils:InTable(block.page, ""..self.index)) then
                        -- save the amount found for this page block
                        local last = block.page[#block.page];
                        last = last..":"..(block.stack - 1);
                        block.page[#block.page] = last;
                        -- reset block size
                        block.stack = 1;
                        -- insert new page block
                        tinsert(block.page, ""..self.index);
                    end
                else
                    auction.page = {""..self.index};
                    tinsert(self.auctions, auction);
                    groupLookup[hash] = #self.auctions;

                    -- create new auction
                    -- otherwise we reuse the table
                    -- until we add it
                    auction = {};
                end
            else
                tinsert(self.auctions, auction);

                -- create new auction
                -- otherwise we reuse the table
                -- until we add it
                auction = {};
            end
        end
    end
end

----------------------
-- Capture page info
----------------------
function Query:Capture()
    self.count, self.total = GetNumAuctionItems("list");

    wipe(self.groupTempTable);

    local x;
    local groupLookup = self.groupTempTable;
    local doGroup = ANS_GLOBAL_SETTINGS.groupAuctions;
    local foundHash = "";
    local auction = nil;
    local lastTotal = #self.auctions;
    
    for x = 1, lastTotal do
        local r = self.auctions[x];
        if (r) then
            Recycler:RecycleBlock(r);
        end
    end

    wipe(self.auctions);

    for x = 1, self.count do
        auction = Recycler:GetAuction();

        auction.name,
        auction.texture,
        auction.count,
        auction.quality,
        auction.canUse,
        auction.level,
        auction.huh,
        auction.minBid,
        auction.minIncrement,
        auction.buyoutPrice,
        auction.bid,
        auction.highBidder,
        auction.bidderFullName,
        auction.owner,
        auction.ownerFullName,
        auction.saleStatus,
        auction.id,
        auction.hasAll = GetAuctionItemInfo("list", x);
        auction.link = GetAuctionItemLink("list", x);
        auction.time = GetAuctionItemTimeLeft("list", x);
        auction.sniped = false;
        auction.percent = 1000;

        if (auction.link ~= nil) then
            auction.tsmId = Utils:GetTSMID(auction.link);

            -- a cageable pet if auction id = 82800
            if (auction.id == 82800) then
                auction.iLevel = 0;
                auction.type = "pet";
                auction.subtype = "normal";
                auction.vendorsell = 0;
            -- otherwise normal item auction
            else
                local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, stackSize, _, _, vendorsell  = GetItemInfo(auction.link);
                if (itemName ~= nil) then
                    auction.iLevel = itemLevel;
                    auction.type = itemType:lower();
                    auction.subtype = itemSubType:lower();
                    auction.vendorsell = vendorsell;
                else
                    auction.iLevel = 0;
                    auction.type = "Unknown";
                    auction.subtype = "Unknown";
                    auction.vendorsell = 0;
                end
            end
        else
            auction.tsmId = "i:"..auction.id;
            auction.iLevel = 0;
            auction.type = "Unknown";
            auction.subtype = "Unknown";
            auction.vendorsell = 0;
        end

        local ownerName;
        if (not auction.ownerFullName) then
            ownerName = auction.owner;
        else
            ownerName = auction.ownerFullName;
        end

        local blacklist = ANS_GLOBAL_SETTINGS.characterBlacklist;
        local isOnBlacklist = false;

        if (ownerName) then
            isOnBlacklist = Utils:InTable(blacklist, ownerName:lower());
        end

        -- according to blizzard's own code for their auction house ui, hasAll fixed bug: 145328
        -- a basic assumption based on the action performed by them, is the auction should be hidden
        -- until it has all the information
        if (auction.buyoutPrice > 0 and auction.saleStatus == 0 and auction.hasAll and ownerName ~= UnitName("player") and not isOnBlacklist) then
            local ppu = math.floor(auction.buyoutPrice / auction.count);
            auction.ppu = ppu;

            local hash = ItemHash(auction);

            local avg = Sources:Query(ANS_GLOBAL_SETTINGS.percentFn, auction);
            if (not avg or avg <= 0) then avg = auction.vendorsell or 1; end;

            auction.percent = math.floor(ppu / avg * 100);

            local filterAccepted = false;
            local k;

            if (#self.filters == 0) then
                local allowed = Sources:Query(ANS_GLOBAL_SETTINGS.pricingFn, auction);

                if (type(allowed) == "boolean") then
                    if (allowed and self:IsValid(auction)) then
                        filterAccepted = true;
                    end
                else
                    filterAccepted = self:IsValid(auction);
                end
            end

            local tf = #self.filters;
            for k = 1, tf do
                if (self.filters[k]:IsValid(auction)) then
                    filterAccepted = true;
                    break;
                end
            end

            if (self.blacklist[hash] or self.blacklist[auction.tsmId]) then
                filterAccepted = false;
            end

            if (filterAccepted) then
                local block = Recycler:GetBlock();

                block.item = auction;
                block.page = self.index;
                block.index = x;
                block.queryId = self.id;

                if (doGroup) then
                    local idx = groupLookup[hash];
                    if  (idx and idx > 0) then
                        local agroup = self.auctions[idx].item.group;
                        tinsert(agroup, block);
                    else
                        foundHash = foundHash..hash;
                        tinsert(self.auctions, block);
                        groupLookup[hash] = #self.auctions;
                    end
                else 
                    tinsert(self.auctions, block);
                end
            else
                Recycler:RecycleAuction(auction);
            end
        else
            Recycler:RecycleAuction(auction);
        end
    end

    if (#self.auctions > 0 and foundHash ~= lastFoundHash and ANS_GLOBAL_SETTINGS.dingSound) then
        PlaySound(SOUNDKIT.AUCTION_WINDOW_OPEN, "Master");
    end
    lastFoundHash = foundHash;
end

function Query:IsLastPage()
    self.count, self.total = GetNumAuctionItems("list");
    return (((self.index + 1) * NUM_AUCTION_ITEMS_PER_PAGE) >= self.total) or (self.count >= self.total);
end

function Query:LastPage() 
    local last = math.max(math.ceil(self.total / NUM_AUCTION_ITEMS_PER_PAGE) - 1, 0);
    if(self:IsLastPage() and self.index == last) then
        return;
    end                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
    self.index = last;
end