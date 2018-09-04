AnsQuery = {};
AnsQuery.__index = AnsQuery;

AnsQuerySort = {
    NAME = 1,
    PRICE = 2,
    PERCENT = 3,
    RECENT = 4,
    ILEVEL = 5
};

local lastFoundHash = "";

local function Truncate(str)
    if(str:len() <= 63) then
        return str;
    end

    return str:sub(1, 62);
end

function AnsQuery:New(search)
    local query = {};
    setmetatable(query, AnsQuery);

    query.search = Truncate(search);
    query.index = 0;
    query.auctions = {};
    query.count = 0;
    query.analyzed = {};
    query.previous = nil;
    query.total = -1;

    query.filters = {};

    query.groups = {};

    return query;
end

function AnsQuery:AssignFilters(ilevel, buyout, quality, size)
    self.filters = {};
    local count = 0;
    local i;
    for i = 1, #AnsFilterSelected do
        if (AnsFilterSelected[i]) then
            count = count + 1;
            local filter = AnsFilterList[i];
            if (filter.useGlobalMinILevel) then
                filter.minILevel = ilevel;
            else
                filter.minILevel = 0;
            end
            if (filter.useGlobalMaxBuyout) then
                filter.maxBuyout = buyout;
            else
                filter.maxBuyout = 0;
            end
            if (filter.useGlobalMinQuality) then
                filter.minQuality = quality;
            else
                filter.minQuality = 1;
            end
            if (filter.useGlobalMinStack) then
                filter.minSize = size;
            else
                filter.minSize = 0;
            end
            local fn = filter.priceFn;

            if (not fn or fn:len() == 0) then
                filter.priceFn = ANS_GLOBAL_SETTINGS.pricingFn;
            end
            self.filters[count] = filter;
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
            QueryAuctionItems(nil, nil, nil, self.index, 0, 1);
        else
            QueryAuctionItems(self.search, nil, nil, self.index, 0, 1);
        end
    end

    return query;
end

function AnsQuery:Next() 
    local query = AnsQuery:New(self.search);
    query.index = self.index + 1;
    query.previous = self;
    query.total = self.total;
    query.filters = self.filters;
    return query;
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

----------------------
-- Capture page info
----------------------
function AnsQuery:Capture()
    self.auctions = {};
    self.groups = {};
    self.count, self.total = GetNumAuctionItems("list");

    local x;
    local analyzed = self.analyzed;
    local count = 0;
    local groupLookup = {};
    local doGroup = ANS_GLOBAL_SETTINGS.groupAuctions;

    local foundHash = "";

    for x = 1, self.count do
        local auction = {};

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
        auction.group = {};
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

            --- it is actually more efficient to analyze while capturing
            if (not analyzed[hash]) then
                local avg = AnsPriceSources:Query(ANS_GLOBAL_SETTINGS.percentFn, auction);
                if (not avg or avg <= 0) then avg = 1000; end;
                analyzed[hash] = avg;
            end

            auction.percent = math.floor(ppu / analyzed[hash] * 100);

            local filterAccepted = false;
            local k;

            if (#self.filters == 0) then
                local allowed = AnsPriceSources:Query(ANS_GLOBAL_SETTINGS.pricingFn, auction);

                if (type(allowed) == "boolean") then
                    if (allowed) then
                        filterAccepted = true;
                    end
                else
                    filterAccepted = true;
                end
            end

            for k = 1, #self.filters do
                if (self.filters[k]:IsValid(auction)) then
                    filterAccepted = true;
                    break;
                end
            end

            if (filterAccepted) then
                local block = {};

                block.item = auction;
                block.page = self.index;
                block.index = x;

                if (doGroup) then
                    local idx = groupLookup[hash];
                    if  (idx and idx > 0) then
                        local agroup = self.auctions[idx].item;
                        local t = #agroup.group + 1;
                        agroup.group[t] = block;
                    else
                        foundHash = foundHash..hash;
                        count = count + 1;
                        self.auctions[count] = block;
                        groupLookup[hash] = count;
                    end
                else 
                    count = count + 1;
                    self.auctions[count] = block;
                end
            end
        end
    end

    if (#self.auctions > 0 and foundHash ~= lastFoundHash) then
        PlaySound(SOUNDKIT.AUCTION_WINDOW_OPEN, "SFX");
    end
    lastFoundHash = foundHash;

    self.analyzed = analyzed;
end

function AnsQuery:IsLastPage()
    return (((self.index + 1) * NUM_AUCTION_ITEMS_PER_PAGE) >= self.total) or (self.count >= self.total);
end

function AnsQuery:LastPage() 
    local last = math.max(math.ceil(self.total / NUM_AUCTION_ITEMS_PER_PAGE) - 1, 0);
    if(self:IsLastPage() and self.index == last) then
        return self;
    end
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
    local query = AnsQuery:New(self.search);
    query.total = self.total;
    query.index = last;
    query.filters = self.filters;
    return query;
end