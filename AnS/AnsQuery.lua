AnsQuery = {};
AnsQuery.__index = AnsQuery;

AnsQuerySort = {
    NAME = 1,
    PRICE = 2,
    PERCENT = 3,
    RECENT = 4
};

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
            filter.minILevel = ilevel;
            filter.maxBuyout = buyout;
            filter.minQuality = quality;
            filter.minSize = size;
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

local function Sort_By_Time(x,y,abs)
    if (asc) then
        return x.item.time < y.item.time;
    else
        return x.item.time > y.item.time;
    end
end

local function ItemHash(item)
    local isHigh = "false";

    if(item.highBidder) then
        isHigh = "true"
    end

    return item.name..item.count..item.buyoutPrice..item.minBid..item.bid..isHigh;
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
        end
    end

    return self.auctions;
end

----------------------
-- Capture page info
----------------------
function AnsQuery:Capture()
    self.auctions = {};
    self.count, self.total = GetNumAuctionItems("list");

    local x;
    local analyzed = self.analyzed;
    local count = 0;

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

        --- it is actually more efficient to analyze while capturing
        if (not analyzed[auction.name]) then
            analyzed[auction.name] = {};
        end

        if (auction.buyoutPrice > 0 and auction.saleStatus == 0) then
            local ppu = math.floor(auction.buyoutPrice / auction.count);
            auction.ppu = ppu;

            if (type(TUJMarketInfo) == "function") then
                TUJMarketInfo(auction.link, analyzed[auction.name]);
            end

            if (analyzed[auction.name]["recent"]) then
                auction.percent = math.floor(ppu / analyzed[auction.name]["recent"] * 100);
            else
                auction.percent = 1000;
            end

            if (analyzed[auction.name]["days"] ~= 252) then
                local filterAccepted = false;
                local k;

                if (#self.filters == 0) then
                    filterAccepted = true;
                end

                for k = 1, #self.filters do
                    if (self.filters[k]:IsValid(auction)) then
                        filterAccepted = true;
                        break;
                    end
                end

                if (filterAccepted) then
                    count = count + 1;
                    local block = {};

                    block.item = auction;
                    block.page = self.index;
                    block.index = x;

                    self.auctions[count] = block;
                end
            end
        end
    end

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