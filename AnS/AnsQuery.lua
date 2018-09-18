AnsQuery = {};
AnsQuery.__index = AnsQuery;

AnsQuerySort = {
    NAME = 1,
    PRICE = 2,
    PERCENT = 3,
    RECENT = 4,
    ILEVEL = 5
};

local GroupTempTable = {};

AnsRecycler = { blocks = {}, auctions = {}};
AnsRecycler.__index = AnsRecycler;

local AnsAuction = {};
AnsAuction.__index = AnsAuction;

function AnsAuction:New()
    local a = {};
    setmetatable(a, AnsAuction);
    a.group = {};
    return a;
end

function AnsAuction:Clone()
    local a = AnsRecycler:GetAuction();
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

local AnsAuctionBlock = {};
AnsAuctionBlock.__index = AnsAuctionBlock;

function AnsAuctionBlock:New()
    local b = {};
    setmetatable(b, AnsAuctionBlock);
    
    b.page = -1;
    b.index = -1;
    b.item = nil;
    b.queryId = -1;

    return b;
end

function AnsAuctionBlock:Clone()
    local b = AnsRecycler:GetBlock();
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

function AnsRecycler:RecycleAuction(auction)
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

function AnsRecycler:RecycleBlock(block)
    if (block) then
        local item = block.item;
        tinsert(self.blocks, block);

        if (item) then
            self:RecycleAuction(item);
        end
    end
end

function AnsRecycler:GetBlock() 
    if (#self.blocks > 0) then
        return tremove(self.blocks);
    end
    return AnsAuctionBlock:New();
end

function AnsRecycler:GetAuction()
    if (#self.auctions > 0) then
        return tremove(self.auctions);
    end
    return AnsAuction:New();
end

local lastFoundHash = "";

local function Truncate(str)
    if(str:len() <= 63) then
        return str;
    end

    return str:sub(1, 62);
end

function AnsQuery:ClearLastHash() 
    lastFoundHash = "";
end

function AnsQuery:Reset()
    lastFoundHash = "";
    self.index = 0;
    wipe(self.auctions);
    wipe(self.filters);
    wipe(self.blacklist);
    AnsUtils:ClearTSMIDCache();
end

function AnsQuery:New(search)
    local query = {};
    setmetatable(query, AnsQuery);

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

    return query;
end

function AnsQuery:AssignFilters(ilevel, buyout, quality, size, maxPercent)
    wipe(self.filters);

    self.minILevel = ilevel;
    self.maxBuyout = buyout;
    self.quality = quality;
    self.minStackSize = size;
    self.maxPercent = maxPercent;

    local i;
    for i = 1, #AnsFilterSelected do
        if (AnsFilterSelected[i]) then
            local f = AnsFilterList[i]:Clone();
            f.maxPercent = maxPercent or 100;
            f.minILevel = ilevel;
            f.maxBuyout = buyout;
            f.minQuality = quality;
            f.minSize = size;
            local fn = f.priceFn;

            if ((fn == nil or fn:len() == 0) and not f.isCustom) then
                f.priceFn = ANS_GLOBAL_SETTINGS.pricingFn;
            end
            tinsert(self.filters, f);
        end
    end
end

function AnsQuery:Set(search) 
    self.search = Truncate(search);
    self.index = 0;
    self.count = 0;
    
    self.total = -1;
    self.previous = nil;
end

function AnsQuery:IsReady()
    local query, queryAll = CanSendAuctionQuery();
    return query;
end

function AnsQuery:Search()
    local query, queryAll = CanSendAuctionQuery();

    if (query) then
        self.id = math.fmod(self.id + 1, 100000);
        if(self.search == "" or self.search:len() == 0)then
            QueryAuctionItems(nil, nil, nil, self.index, false, 1);
        else
            QueryAuctionItems(self.search, nil, nil, self.index, false, 1);
        end
    end

    return query;
end

function AnsQuery:Next() 
    self.index = self.index + 1;
end

local sortAsc = false;

local function Sort_By_Name(x,y)
    if (sortAsc) then
        return x.item.name < y.item.name;
    else
        return x.item.name > y.item.name;
    end
end

local function Sort_By_Percent(x,y)
    if (sortAsc) then
        return x.item.percent < y.item.percent;
    else
        return x.item.percent > y.item.percent;
    end
end

local function Sort_By_Price(x,y)
    if (sortAsc) then
        return x.item.ppu < y.item.ppu;
    else
        return x.item.ppu > y.item.ppu;
    end
end

local function Sort_By_Time(x,y)
    if (sortAsc) then
        return x.item.time < y.item.time;
    else
        return x.item.time > y.item.time;
    end
end

local function Sort_By_iLevel(x,y)
    if (sortAsc) then
        return x.item.iLevel < y.item.iLevel;
    else
        return x.item.iLevel > y.item.iLevel;
    end
end

local function ItemHash(item)
    local owner = "?";

    if (item.owner) then
        owner = item.owner;
    end

    return item.link..item.count..item.ppu..owner;
end

function AnsQuery:AddToBlacklist(item)
    self.blacklist[ItemHash(item)] = true;
end

function AnsQuery:AddAllToBlacklist(item)
    self.blacklist[item.tsmId] = true;
end

----
-- Only sorts the auctions in this page query
----
function AnsQuery:Items(sort,asc,toTbl)
    -- set local variable for sort functions
    sortAsc = asc;
    if (self.count > 1) then
        if (sort == AnsQuerySort.NAME) then
            table.sort(self.auctions, Sort_By_Name);
        elseif (sort == AnsQuerySort.PRICE) then
            table.sort(self.auctions, Sort_By_Price);
        elseif (sort == AnsQuerySort.PERCENT) then
            table.sort(self.auctions, Sort_By_Percent);
        elseif (sort == AnsQuerySort.RECENT) then
            table.sort(self.auctions, Sort_By_Time);
        elseif (sort == AnsQuerySort.ILEVEL) then
            table.sort(self.auctions, Sort_By_iLevel);
        end
    end

    local tt = #toTbl;   
    local t = #self.auctions;
    local i;
    
    for i = 1, tt do
        AnsRecycler:RecycleBlock(toTbl[i]);
    end

    wipe(toTbl);

    for i = 1, t do
        tinsert(toTbl, self.auctions[i]:Clone());
    end

    return toTbl;
end

function AnsQuery:IsValid(item) 
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
-- Capture page info
----------------------
function AnsQuery:Capture()
    self.count, self.total = GetNumAuctionItems("list");

    wipe(GroupTempTable);

    local x;
    local groupLookup = GroupTempTable;
    local doGroup = ANS_GLOBAL_SETTINGS.groupAuctions;
    local foundHash = "";
    local auction = nil;
    local lastTotal = #self.auctions;

    for x = 1, lastTotal do
        local r = self.auctions[x];
        if (r) then
            AnsRecycler:RecycleBlock(r);
        end
    end

    wipe(self.auctions);

    for x = 1, self.count do
        auction = AnsRecycler:GetAuction();

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
            auction.tsmId = AnsUtils:GetTSMID(auction.link);
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
            
        else
            auction.tsmId = auction.id;
            auction.iLevel = 0;
            auction.type = "Unknown";
            auction.subtype = "Unknown";
            auction.vendorsell = 0;
        end

        local ownerName;
        if (not auction.ownerFullName) then
            ownerName = owner;
        else
            ownerName = auction.ownerFullName;
        end

        -- according to blizzard's own code for their auction house ui, hasAll fixed bug: 145328
        -- a basic assumption based on the action performed by them, is the auction should be hidden
        -- until it has all the information
        if (auction.buyoutPrice > 0 and auction.saleStatus == 0 and auction.hasAll and ownerName ~= UnitName("player")) then
            local ppu = math.floor(auction.buyoutPrice / auction.count);
            auction.ppu = ppu;

            local hash = ItemHash(auction);

            local avg = AnsPriceSources:Query(ANS_GLOBAL_SETTINGS.percentFn, auction);
            if (not avg or avg <= 0) then avg = auction.vendorsell or 1; end;

            auction.percent = math.floor(ppu / avg * 100);

            local filterAccepted = false;
            local k;

            if (#self.filters == 0) then
                local allowed = AnsPriceSources:Query(ANS_GLOBAL_SETTINGS.pricingFn, auction);

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
                local block = AnsRecycler:GetBlock();

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
                AnsRecycler:RecycleAuction(auction);
            end
        else
            AnsRecycler:RecycleAuction(auction);
        end
    end

    if (#self.auctions > 0 and foundHash ~= lastFoundHash and ANS_GLOBAL_SETTINGS.dingSound) then
        PlaySound(SOUNDKIT.AUCTION_WINDOW_OPEN, "Master");
    end
    lastFoundHash = foundHash;
end

function AnsQuery:IsLastPage()
    self.count, self.total = GetNumAuctionItems("list");
    return (((self.index + 1) * NUM_AUCTION_ITEMS_PER_PAGE) >= self.total) or (self.count >= self.total);
end

function AnsQuery:LastPage() 
    local last = math.max(math.ceil(self.total / NUM_AUCTION_ITEMS_PER_PAGE) - 1, 0);
    if(self:IsLastPage() and self.index == last) then
        return;
    end                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
    self.index = last;
end