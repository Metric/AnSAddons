AnsQuery = {};
AnsQuery.__index = AnsQuery;

AnsQuerySort = {
    NAME = 1,
    PRICE = 2,
    PERCENT = 3,
    RECENT = 4,
    ILEVEL = 5
};

local AnsRecycler = { blocks = {}, auctions = {}};
AnsRecycler.__index = AnsRecycler;

function AnsRecycler:RecycleAuction(auction)
    local group = auction.group;
    local gtotal = #group;

    local i;
    for i = 1, gtotal do
        local r = tremove(group);
        if (r) then
            self:RecycleBlock(r);
        end
    end
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
    
    return {};
end

function AnsRecycler:GetAuction()
    if (#self.auctions > 0) then
        return tremove(self.auctions);
    end

    return {group = {}};
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
    self.auctions = {};
    self.filters = {};
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

    return query;
end

function AnsQuery:AssignFilters(ilevel, buyout, quality, size, maxPercent)
    self.filters = {};

    self.minILevel = ilevel;
    self.maxBuyout = buyout;
    self.quality = quality;
    self.minStackSize = size;
    self.maxPercent = maxPercent;

    local count = 0;
    local i;
    for i = 1, #AnsFilterSelected do
        if (AnsFilterSelected[i]) then
            local f = AnsFilterList[i]:Clone();

            count = count + 1;
            f.maxPercent = maxPercent or 100;
            if (f.useGlobalMinILevel) then
                f.minILevel = ilevel;
            else
                f.minILevel = 0;
            end
            if (f.useGlobalMaxBuyout) then
                f.maxBuyout = buyout;
            else
                f.maxBuyout = 0;
            end
            if (f.useGlobalMinQuality) then
                f.minQuality = quality;
            else
                f.minQuality = 1;
            end
            if (f.useGlobalMinStack) then
                f.minSize = size;
            else
                f.minSize = 0;
            end
            local fn = f.priceFn;

            if (not fn or fn:len() == 0) then
                f.priceFn = ANS_GLOBAL_SETTINGS.pricingFn;
            end
            self.filters[count] = f;
        end
    end
end

function AnsQuery:Set(search) 
    self.search = Truncate(search);
    self.index = 0;
    
    self.auctions = {};
    self.count = 0;
    
    self.total = -1;
    self.previous = nil;
end

function AnsQuery:Search()
    local query, queryAll = CanSendAuctionQuery();

    if (query) then
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

local function Sort_By_Name(x,y,asc)
    if (asc) then
        return x.item.name:lower() < y.item.name:lower();
    else
        return x.item.name:lower() > y.item.name:lower();
    end
end

local function Sort_By_Percent(x,y,asc)
    if (asc) then
        return x.item.percent < y.item.percent;
    else
        return x.item.percent > y.item.percent;
    end
end

local function Sort_By_Price(x,y,asc)
    if (asc) then
        return x.item.ppu < y.item.ppu;
    else
        return x.item.ppu > y.item.ppu;
    end
end

local function Sort_By_Time(x,y,asc)
    if (asc) then
        return x.item.time < y.item.time;
    else
        return x.item.time > y.item.time;
    end
end

local function Sort_By_iLevel(x,y,asc)
    if (asc) then
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

    return item.name..item.count..item.ppu..owner;
end

----
-- Only sorts the auctions in this page query
----
function AnsQuery:Items(sort,asc)
    if (self.count > 1) then
        if (sort == AnsQuerySort.NAME) then
            table.sort(self.auctions, function(x,y) return Sort_By_Name(x,y,asc); end);
        elseif (sort == AnsQuerySort.PRICE) then
            table.sort(self.auctions, function(x,y) return Sort_By_Price(x,y,asc); end);
        elseif (sort == AnsQuerySort.PERCENT) then
            table.sort(self.auctions, function(x,y) return Sort_By_Percent(x,y,asc); end);
        elseif (sort == AnsQuerySort.RECENT) then
            table.sort(self.auctions, function(x,y) return Sort_By_Time(x,y,asc); end);
        elseif (sort == AnsQuerySort.ILEVEL) then
            table.sort(self.auctions, function(x,y) return Sort_By_iLevel(x,y,asc); end);
        end
    end

    return self.auctions;
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

    local x;
    local groupLookup = {};
    local doGroup = ANS_GLOBAL_SETTINGS.groupAuctions;
    local foundHash = "";
    local auction = nil;
    local lastTotal = #self.auctions;

    for x = 1, lastTotal do
        local r = tremove(self.auctions);
        if (r) then
            AnsRecycler:RecycleBlock(r);
        end
    end

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
        auction.id = GetAuctionItemInfo("list", x);
        auction.link = GetAuctionItemLink("list", x);
        auction.time = GetAuctionItemTimeLeft("list", x);
        auction.sniped = false;
        auction.percent = 1000;

        if (auction.link ~= nil) then
            local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType = GetItemInfo(auction.link);
            if (itemName ~= nil) then
                auction.iLevel = itemLevel;
                auction.type = itemType;
                auction.subtype = itemSubType;
            else
                auction.iLevel = 0;
                auction.type = "Unknown";
                auction.subtype = "Unknown";
            end
        end

        if (auction.buyoutPrice > 0 and auction.saleStatus == 0) then
            local ppu = math.floor(auction.buyoutPrice / auction.count);
            auction.ppu = ppu;

            local hash = ItemHash(auction);

            local avg = AnsPriceSources:Query(ANS_GLOBAL_SETTINGS.percentFn, auction);
            if (not avg or avg <= 0) then avg = 1; end;

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

            if (filterAccepted) then
                local block = AnsRecycler:GetBlock();

                block.item = auction;
                block.page = self.index;
                block.index = x;

                if (doGroup) then
                    local idx = groupLookup[hash];
                    if  (idx and idx > 0) then
                        local agroup = self.auctions[idx].item;
                        tinsert(agroup, block);
                    else
                        foundHash = foundHash..hash;
                        tinsert(self.auctions, block);
                        groupLookup[hash] = #self.auctions;
                    end
                else 
                    tinsert(self.auctions, block);
                end
            end
        end
    end

    if (#self.auctions > 0 and foundHash ~= lastFoundHash) then
        PlaySound(SOUNDKIT.AUCTION_WINDOW_OPEN, "SFX");
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