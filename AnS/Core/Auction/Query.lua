local Ans = select(2, ...);
local Config = Ans.Config;
local Utils = Ans.Utils;
local Sources = Ans.Sources;

local Query = {};
Query.__index = Query;

Ans.Auctions = {};
Ans.Auctions.Query = Query;

local Recycler = { auctions = {}};
Recycler.__index = Recycler;

Ans.Auctions.Recycler = Recycler;

local Auction = {};
Auction.__index = Auction;

local SnipingOp = Ans.Operations.Sniping;

function Auction:New()
    local a = {};
    setmetatable(a, Auction);
    a.itemKey = nil;
    a.id = nil;
    a.name = nil;
    a.texture = nil;
    a.count = 1;
    a.level = 0;
    a.ppu = 0;
    a.owner = nil;
    a.link = nil;
    a.sniped = false;
    a.tsmId  = nil;
    a.percent = -1;
    a.quality = 0;
    
    a.iLevel = 0;
    a.vendorsell = 0;
    a.isCommodity = false;
    a.auctionId = nil;
    a.avg = 1;
    return a;
end

function Auction:Clone()
    local a = Recycler:Get();
    setmetatable(a, Auction);
    a.id = self.id;
    a.itemKey = self.itemKey;
    a.name = self.name;
    a.texture = self.texture;
    a.quality = self.quality;
    a.count = self.count;
    a.level = self.level;
    a.ppu = self.ppu;
    a.buyoutPrice = self.buyoutPrice;
    a.owner = self.owner;
    a.link = self.link;
    a.sniped = self.sniped;
    a.tsmId = self.tsmId;
    a.percent = self.percent;
    a.iLevel = self.iLevel;
    a.vendorsell = self.vendorsell;
    a.isCommodity = self.isCommodity;
    a.auctionId = self.auctionId;
    a.itemIndex = self.itemIndex;
    a.avg = self.avg;
    a.auctions = self.auctions;
    return a;
end

function Recycler:Reset()
    wipe(self.auctions);
end

function Recycler:Recycle(auction)
    wipe(auction);
    tinsert(self.auctions, auction);
end

function Recycler:Get()
    if (#self.auctions > 0) then
        return tremove(self.auctions);
    end
    return Auction:New();
end

local function Truncate(str)
    if(str:len() <= 63) then
        return str;
    end

    return str:sub(1, 62);
end

local function ItemHash(item, owner)
    owner = owner or "";
    return item.link..item.count..item.ppu..owner;
end

Query.ops = {};
Query.page = 0;
Query.itemIndex = 1;
Query.blacklist = {};

function Query:Blacklist(auction)
    self.blacklist[ItemHash(auction)] = true;
end

function Query:IsBlacklisted(auction)
    return self.blacklist[ItemHash(auction)] == true;
end

function Query:ClearBlacklist()
    wipe(self.blacklist);
end

function Query:AssignDefaults(ilevel, buyout, quality, maxPercent)
    self.minILevel = ilevel;
    self.maxBuyout = buyout;
    self.quality = quality;
    self.maxPercent = maxPercent;
end

function Query:AssignSnipingOps(ops) 
    wipe(self.ops);

    for i,v in ipairs(ops) do
        local op = SnipingOp:FromConfig(v);
        op:ParseGroups();
        tinsert(self.ops, op);
    end
end

function Query:IsValid(item) 
    if (item.iLevel < self.minILevel and self.minILevel > 0) then
        return false;
    end
    if (item.ppu > self.maxBuyout and self.maxBuyout > 0) then
        return false;
    end
    if (item.percent > self.maxPercent and self.maxPercent > 0) then
        return false;
    end
    if (item.quality < self.quality and self.quality > 0) then
        return false;
    end

    return true;
end

function Query:IsFiltered(auction)
    local blacklist = Config.Sniper().characterBlacklist;

    -- ensure the blacklist is in table
    -- format, if not make it table and cache it
    -- this won't hurt anything since
    -- the config already handles if it is in a table
    -- and will fill in the edit box appropriately
    if (type(blacklist) == "string") then
        if (blacklist == "" or blacklist:len() == 0) then
            blacklist = {};
        else
            blacklist = { strsplit("\r\n", blacklist:lower()) };
            Config.Sniper().characterBlacklist = blacklist;
        end
    end

    local isOnBlacklist = false;

    if (auction.owner and #blacklist > 0) then
        if (type(auction.owner) ~= "table") then
            if (auction.owner ~= "" and auction.owner:len() > 0) then
                isOnBlacklist = Utils:InTable(blacklist, auction.owner:lower());
            end
        else
            for i,v in ipairs(auction.owner) do
                if (v ~= "" and v:len() > 0) then
                    local contains = Utils:InTable(blacklist, v:lower());
                    if (contains) then
                        isOnBlacklist = true;
                        break;
                    end
                end
            end
        end
    end

    if (isOnBlacklist) then
        return false;
    end

    if (Config.Sniper().itemBlacklist[auction.tsmId]) then
        return false;
    end

    if (auction.buyoutPrice > 0) then
        local avg = Sources:Query(Config.Sniper().source, auction);
        if (not avg or avg <= 0) then avg = auction.vendorsell or 1; end;

        if (avg <= 1) then
            auction.avg = 1;
            auction.percent = 9999;
        else
            auction.avg = avg;
            auction.percent = math.floor(auction.ppu / avg * 100);
        end

        local filterAccepted = false;
        local k;

        if (#self.ops == 0) then
            local allowed = Sources:Query(Config.Sniper().pricing, auction);

            if (type(allowed) == "boolean" or type(allowed) == "number") then
                if (type(allowed) == "number") then
                    if (auction.ppu <= allowed and self:IsValid(auction)) then
                        filterAccepted = true;
                    end
                else
                    if (allowed and self:IsValid(auction)) then
                        filterAccepted = true;
                    end
                end
            else
                filterAccepted = self:IsValid(auction);
            end
        end

        local tf = #self.ops;
        for k = 1, tf do
            if (self.ops[k]:IsValid(auction, true)) then
                filterAccepted = true;
                break;
            end
        end

        return filterAccepted;
    end

    return false;
end

function Query:IsFilteredGroup(group)
    local auction = Recycler:Get();

    auction.name = nil;
    auction.itemKey = group.itemKey;
    auction.isCommodity = false;
    auction.isPet = false;
    auction.texture = nil;
    auction.quality = 99;
    auction.iLevel = group.itemKey.itemLevel or 0;
    auction.id = group.itemKey.itemID;
    auction.count = group.totalQuantity;

    auction.ppu = group.minPrice;
    auction.buyoutPrice = auction.ppu;

    auction.link = nil;

    local groupInfo = C_AuctionHouse.GetItemKeyInfo(group.itemKey);

    if (group.itemKey.battlePetSpeciesID > 0) then
        if (not groupInfo) then
            Recycler:Recycle(auction);
            return nil, false;
        end

        auction.link = groupInfo.battlePetLink;
        auction.isPet = true;
    end
    
    if (groupInfo) then
        auction.quality = groupInfo.quality;
        auction.texture = groupInfo.iconFileID;
        auction.name = groupInfo.itemName;
        auction.isCommodity = groupInfo.isCommodity;
    end

    auction.type = 0;
    auction.subtype = 0;
    auction.vendorsell = 0;

    if (auction.link and Utils:IsBattlePetLink(auction.link)) then
        local info = Utils:ParseBattlePetLink(auction.link);
        auction.texture = info.icon;
        auction.iLevel = info.level;
        auction.name = info.name;
        auction.quality = info.breedQuality;
        auction.tsmId = Utils:GetTSMID(auction.link);
    else
        auction.tsmId = "i:"..auction.id;
    end

    if (auction.buyoutPrice > 0) then
        local avg = Sources:Query(Config.Sniper().source, auction);
        if (not avg or avg <= 0) then 
            avg = auction.vendorsell or 1; 
        end

        if (avg <= 1) then
            auction.avg = 1;
            auction.percent = 9999;
        else
            auction.avg = avg;
            auction.percent = math.floor(auction.ppu / avg * 100);
        end

        local filterAccepted = false;
        local k;

        if (#self.ops == 0) then
            local allowed = Sources:Query(Config.Sniper().pricing, auction);

            if (type(allowed) == "boolean" or type(allowed) == "number") then
                if (type(allowed) == "number") then
                    if (auction.ppu <= allowed and self:IsValid(auction)) then
                        filterAccepted = true;
                    end
                else
                    if (allowed and self:IsValid(auction)) then
                        filterAccepted = true;
                    end
                end
            else
                filterAccepted = self:IsValid(auction);
            end
        end

        local tf = #self.ops;
        for k = 1, tf do
            if (self.ops[k]:IsValid(auction, auction.isPet)) then
                filterAccepted = true;
                break;
            end
        end

        if (filterAccepted) then
            return auction;
        end
    end

    Recycler:Recycle(auction);
    return nil, false;
end

function Query:IsReady()
    local query, queryAll = CanSendAuctionQuery();
    return query;
end

function Query:IsAllReady()
    local query, queryAll = CanSendAuctionQuery();
    return queryAll;
end

function Query:Search(filter)
    local ready = self:IsReady();
    if (ready) then
        self.itemIndex = 1;
        QueryAuctionItems(filter.searchString or "", filter.minLevel, filter.maxLevel, self.page, false, filter.quality, false, false);
    end
    return ready;
end

function Query:All()
    local ready = self:IsAllReady();
    if (ready) then
        self.itemIndex = 1;
        QueryAuctionItems(nil, nil, nil, 0, false, 1, true);
    end
    return ready;
end

function Query:HasNext()
    local count, total = GetNumAuctionItems("list");
    return self.itemIndex <= count;
end

function Query:Next(auction)
    auction = auction or Recycler:Get();

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
    auction.hasAll = GetAuctionItemInfo("list", self.itemIndex);
    auction.link = GetAuctionItemLink("list", self.itemIndex);
    auction.time = GetAuctionItemTimeLeft("list", self.itemIndex);
    auction.sniped = false;
    auction.percent = 1000;
    auction.isPet = false;
    auction.isCommodity = false;
    auction.iLevel = 0;
    auction.vendorsell = 0;
    auction.itemIndex = self.itemIndex;

    self.itemIndex = self.itemIndex + 1;

    if (not auction.link) then
        Recycler:Recycle(auction);
        return nil;
    end

    auction.tsmId = Utils:GetTSMID(auction.link);

    local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, stackSize, _, _, vendorsell  = GetItemInfo(auction.link);
    if (itemName) then
        auction.iLevel = itemLevel;
        auction.vendorsell = vendorsell;
    end

    if (auction.buyoutPrice <= 0 or auction.saleStatus ~= 0 or not auction.hasAll) then
        Recycler:Recycle(auction);
        return nil;
    end

    auction.ppu = math.floor(auction.buyoutPrice / auction.count);
    auction.hash = ItemHash(auction);

    return auction;
end

function Query:Count()
    local count, total = GetNumAuctionItems("list");
    return count;
end

function Query:IsFirst()
    return self.page == 0;
end

function Query:IsLast()
    local count, total = GetNumAuctionItems("list");
    return (self.page + 1) * NUM_AUCTION_ITEMS_PER_PAGE >= total or count >= total;
end

function Query:Last()
    local count, total = GetNumAuctionItems("list");
    local last = math.max(math.ceil(total / NUM_AUCTION_ITEMS_PER_PAGE) - 1, 0);
    if (self:IsLast() and self.page == last) then
        return;
    end
    self.page = last;
end