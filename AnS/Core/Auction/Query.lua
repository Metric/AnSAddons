local Ans = select(2, ...);
local Config = Ans.Config;
local Utils = Ans.Utils;
local Sources = Ans.Sources;
local EventManager = Ans.EventManager;

local Query = {};
Query.__index = Query;

Ans.Auctions = {};
Ans.Auctions.Query = Query;

local Recycler = { auctions = {}};
Recycler.__index = Recycler;

Ans.Auctions.Recycler = Recycler;

local Auction = {};
Auction.__index = Auction;

local throttleMessageReceived = true;
local throttleWaitingForSend = false;
local throttleTime = time();

local EVENTS_TO_REGISTER = {};

local DEFAULT_ITEM_SORT = { sortOrder = 0, reverseSort = false };

local ownedAuctions = {};

if (not Utils:IsClassic()) then
    EVENTS_TO_REGISTER = {
        "AUCTION_HOUSE_BROWSE_RESULTS_ADDED",
        "AUCTION_HOUSE_BROWSE_RESULTS_UPDATED",
        "ITEM_SEARCH_RESULTS_ADDED",
        "ITEM_SEARCH_RESULTS_UPDATED",
        "COMMODITY_SEARCH_RESULTS_ADDED",
        "COMMODITY_SEARCH_RESULTS_UPDATED",
        "AUCTION_HOUSE_THROTTLED_MESSAGE_RESPONSE_RECEIVED",
        "AUCTION_HOUSE_THROTTLED_MESSAGE_DROPPED",
        "AUCTION_HOUSE_THROTTLED_MESSAGE_SENT",
        "AUCTION_HOUSE_THROTTLED_MESSAGE_QUEUED",
        "OWNED_AUCTIONS_UPDATED",
        "AUCTION_CANCELED",
        "AUCTION_HOUSE_AUCTION_CREATED",
        "AUCTION_MULTISELL_FAILURE"
    };
else
    EVENTS_TO_REGISTER = {
        "AUCTION_ITEM_LIST_UPDATE"
    };
end

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
    a.buyoutPrice = 0;
    a.iLevel = 0;
    a.vendorsell = 0;
    a.isCommodity = false;
    a.auctionId = nil;
    a.avg = 1;
    return a;
end

function Auction:Clone(forceNew)
    local a = Recycler:Get(forceNew);
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
    a.isPet = self.isPet;
    a.auctionId = self.auctionId;
    a.itemIndex = self.itemIndex;
    a.avg = self.avg;
    a.auctions = self.auctions;
    a.op = self.op;
    a.isEquipment = self.isEquipment;
    return a;
end

function Recycler:Reset()
    wipe(self.auctions);
end

function Recycler:Recycle(auction)
    wipe(auction);
    tinsert(self.auctions, auction);
end

function Recycler:Get(forceNew)
    if (#self.auctions > 0 and not forceNew) then
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

local function ItemKeyHash(itemKey)
    if (not itemKey) then
        return nil;
    end

    return ""..itemKey.itemID..itemKey.itemLevel..itemKey.itemSuffix..itemKey.battlePetSpeciesID;
end

local function GetOwners(result)
    if (#result.owners == 0) then
        return "";
    elseif (#result.owners == 1) then
        return result.owners[1];
    else
        return result.owners;
    end
end

local STATES = {};
STATES.NONE = 0;
STATES.BROWSE = 1;
STATES.SEARCH = 2;
STATES.CLASSIC_SEARCH = 3;
STATES.BROWSE_MORE = 4;
STATES.SEARCH_MORE = 5;
STATES.OWNED = 6;

Query.ItemKeyHash = ItemKeyHash;

Query.ops = {};
Query.page = 0;
Query.itemIndex = 1;
Query.blacklist = {};
Query.groupResults = {};
Query.queuedSearches = {};

Query.BrowseFilterFunc = nil;
Query.fullBrowseResults = false;
Query.state = STATES.NONE;
Query.previousState = STATES.NONE;
Query.STATES = STATES;
Query.queuedStates = {};

function Query:RegisterEvents(frame)
    for i,v in ipairs(EVENTS_TO_REGISTER) do
        frame:RegisterEvent(v);
    end
    frame:RegisterEvent("AUCTION_HOUSE_SHOW");
    frame:RegisterEvent("AUCTION_HOUSE_CLOSED");
end

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
        tinsert(self.ops, v);
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

-- classic

function Query:IsReady()
    local query, queryAll = CanSendAuctionQuery();
    return query;
end

function Query:IsAllReady()
    local query, queryAll = CanSendAuctionQuery();
    return queryAll;
end

function Query:Search(filter, autoPage, op)
    local ready = self:IsReady();
    
    self.state = STATES.CLASSIC_SEARCH;
    self.itemIndex = 1;
    self.op = op;
    self.filter = filter;
    self.autoPage = autoPage;

    if (ready) then
        self.delay = nil;
        EventManager:On("AUCTION_ITEM_LIST_UPDATE", Query.OnListUpdate);
        QueryAuctionItems(filter.searchString or "", filter.minLevel, filter.maxLevel, self.page, false, filter.quality, false, false);
    else
        self.delay = time();
    end
    return ready;
end

function Query:All()
    local ready = self:IsAllReady();
    if (ready) then
        self.itemIndex = 1;
        self.filter = nil;
        self.autoPage = false;
        QueryAuctionItems(nil, nil, nil, 0, false, 1, true);
    end
    return ready;
end

function Query:HasNext()
    local count, total = GetNumAuctionItems("list");
    return self.itemIndex <= count;
end

-- helper function for Owned Auctions for Classic
function Query:GetOwnedAuctionClassic(index)
    local auction = Recycler:Get();

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
    auction.hasAll = GetAuctionItemInfo("owner", index);
    auction.link = GetAuctionItemLink("owner", index);
    auction.time = GetAuctionItemTimeLeft("owner", index);
    auction.isPet = false;
    auction.isCommodity = false;
    auction.iLevel = 0;
    auction.vendorsell = 0;
    auction.itemIndex = index;

    if (not auction.link) then
        Recycler:Recycle(auction);
        return nil;
    end

    if (auction.buyoutPrice <= 0 or auction.saleStatus ~= 0 or not auction.hasAll) then
        Recycler:Recycle(auction);
        return nil;
    end

    auction.tsmId = Utils:GetTSMID(auction.link);

    auction.ppu = math.floor(auction.buyoutPrice / auction.count);
    auction.hash = ItemHash(auction);

    return auction;
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

    local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, stackSize, _, _, vendorsell  = GetItemInfo(auction.link);
    if (itemName) then
        auction.iLevel = itemLevel;
        auction.vendorsell = vendorsell;
    end

    if (auction.buyoutPrice <= 0 or auction.saleStatus ~= 0 or not auction.hasAll) then
        Recycler:Recycle(auction);
        return nil;
    end

    auction.tsmId = Utils:GetTSMID(auction.link);

    auction.ppu = math.floor(auction.buyoutPrice / auction.count);
    auction.hash = ItemHash(auction);

    if (self.op) then
        auction.op = self.op;
    end

    return auction;
end

function Query:Count()
    local count, total = GetNumAuctionItems("list");
    return count;
end

function Query:NextPage()
    self.page = self.page + 1;
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

function Query:OwnedCount()
    local count, total = GetNumAuctionItems("owner");
    return total;
end

function Query.OnListUpdate()
    local self = Query;
    -- we remove it as we only want the first update initiated by a search
    EventManager:RemoveListener("AUCTION_ITEM_LIST_UPDATE", Query.OnListUpdate);

    while (Query:HasNext()) do
        local item = Query:Next();
        if (item) then
            EventManager:Emit("QUERY_CLASSIC_RESULT", item);
        end
    end

    if (not Query:IsLast() and Query.autoPage) then
        Query:NextPage();
        Query:Search(Query.filter, Query.autoPage, Query.op);
    else
        self.state = STATES.NONE;
        self.filter = nil;
        self.op = nil;

        EventManager:Emit("QUERY_CLASSIC_COMPLETE");
    end
end

local browseResults = {};
local browseIndex = 1;

-- retail and classic specific updates

function Query.OnUpdate()
    -- this is for when classic search fails we keep trying
    -- until it goes through
    if (Query.state == STATES.CLASSIC_SEARCH) then
        if (Query.delay and time() - Query.delay > 1 and Query.filter) then
            Query:Search(Query.filter, Query.autoPage, Query.op);
        end
    -- these ar for retail for when it is in the specified state
    -- but we received a ThrottleDropped message
    -- thus we try and try again
    elseif (Query.state == STATES.BROWSE) then
        if (Query.delay and time() - Query.delay > 1 and Query.filter) then
            if (not Query.Browse(Query.filter)) then
                Query.delay = time();
            else
                Query.delay = nil;
            end
        end
    elseif (Query.state == STATES.SEARCH) then
        if (Query.delay and time() - Query.delay > 1 and Query.filter and Query.filter.item) then
            if (not Query.SearchForItem(Query.filter.item, Query.filter.byItemID, Query.filter.firstOnly)) then
                Query.delay = time();
            else
                Query.delay = nil;
            end
        end
    elseif (Query.state == STATES.BROWSE_MORE) then
        if (Query.delay and time() - Query.delay > 1) then
            Query.delay = nil;
            Query.BrowseMore();
        end
    elseif (Query.state == STATES.OWNED) then
        if (Query.delay and time() - Query.delay > 1) then
            Query.delay = nil;
            Query.Owned();
        end
    elseif (Query.state == STATES.SEARCH_MORE) then
        if (Query.delay and time() - Query.delay > 1 and Query.moreItem) then
            Query.delay = nil;
            if (Query.moreItem.isCommodity) then
                C_AuctionHouse.RequestMoreCommoditySearchResults(Query.moreItem.key);
            else
                C_AuctionHouse.RequestMoreItemSearchResults(Query.moreItem.key);
            end
        end
    elseif (Query.state == STATES.NONE) then
        if (#Query.queuedStates > 0) then
            local next = tremove(Query.queuedStates);

            if (next.state == STATES.BROWSE) then
                if (not Query.Browse(next.data)) then
                    Query.delay = time();
                end
            elseif (next.state == STATES.SEARCH) then
                if (not Query.SearchForItem(next.data.item, next.data.byItemID, next.data.firstOnly)) then
                    Query.delay = time();
                end
            elseif (next.state == STATES.OWNED) then
                if (not Query.Owned()) then
                    Query.delay = time();
                end
            end
        end
    end

    if (#browseResults > 0 and browseIndex <= #browseResults and Query.BrowseFilterFunc) then
        local count = 0;
        while (browseIndex <= #browseResults and count < Config.Sniper().itemsPerUpdate) do

            local group = browseResults[browseIndex];

            if (group) then
                local filtered = Query.BrowseFilterFunc(group);
                if (filtered) then
                    tinsert(Query.groupResults, filtered);
                end
            end

            browseIndex = browseIndex + 1;
            count = count + 1;
        end
        
        if (browseIndex > #browseResults) then
            if (Query.state == STATES.BROWSE or Query.state == STATES.BROWSE_MORE) then
                Query.state = STATES.NONE;
                Query.filter = nil;
            end

            wipe(browseResults);
            browseIndex = 1;

            EventManager:Emit("QUERY_BROWSE_RESULTS");
        end
    end
end

-- retail

-- helper function for Owned Auctions for Retail
function Query:GetOwnedAuctionRetail(index)
    local auction = Recycler:Get();
    local info = C_AuctionHouse.GetOwnedAuctionInfo(index);

    if (not info) then
        Recycler:Recycle(auction);
        return nil;
    end

    auction.link = info.itemLink;

    local keyInfo = C_AuctionHouse.GetItemKeyInfo(info.itemKey);

    if (not keyInfo) then
        Recycler:Recycle(auction);
        return nil;
    end

    auction.isEquipment = keyInfo.isEquipment;
    auction.id = info.itemKey.itemID;
    auction.auctionId = info.auctionID;
    auction.itemKey = info.itemKey;
    auction.status = info.status;
    auction.count = info.quantity;
    auction.ppu = info.buyoutAmount;
    auction.bidder = info.bidder;

    if (auction.status > 0) then
        Recycler:Recycle(auction);
        return nil;
    end

    if (not auction.ppu) then
        Recycler:Recycle(auction);
        return nil;
    end

    local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, stackSize, _, _, vendorsell  = GetItemInfo(auction.link);
    if (itemName) then
        auction.quality = itemRarity;
    end

    auction.tsmId = Utils:GetTSMID(auction.link);

    return auction;
end

function Query.OnOwnedUpdate()
    for i,v in ipairs(ownedAuctions) do
        Recycler:Recycle(v);
    end

    wipe(ownedAuctions);

    local num = C_AuctionHouse.GetNumOwnedAuctions();

    for i = 1, num do
        local auction = Query:GetOwnedAuctionRetail(i);
        if (auction) then
            tinsert(ownedAuctions, auction);
        end
    end

    if (Query.state == STATES.OWNED) then
        Query.state = STATES.NONE;
    end

    EventManager:Emit("QUERY_OWNED_AUCTIONS", ownedAuctions);
end

-- throttle related for retail
function Query.ThrottleReceived()
    throttleTime = time();
    throttleMessageReceived = true;
end

function Query.ThrottleQueued()
    throttleMessageReceived = false;
    throttleWaitingForSend = true;
end

function Query.ThrottleDropped()
    throttleWaitingForSend = false;
    throttleMessageReceived = true;

    if (Query.state ~= STATES.NONE) then
        Query.delay = time();
    end
end

function Query.ThrottleSent()
    throttleTime = time();
    throttleWaitingForSend = false;
end

function Query.ClearThrottle()
    throttleTime = 0;
    throttleMessageReceived = true;
    throttleWaitingForSend = false;
end

function Query.Clear()
    wipe(Query.queuedStates);
    Query.state = STATES.NONE;
    Query.delay = nil;
end

function Query.IsThrottled()
    return throttleMessageReceived == false or throttleWaitingForSend == true;
end

function Query.Browse(filter)
    if (Query.state ~= STATES.NONE and Query.state ~= STATES.BROWSE) then
        tinsert(Query.queuedStates, {state = STATES.BROWSE, data = filter});
        return false;
    end

    Query.filter = filter;
    Query.previousState = STATES.BROWSE;
    Query.state = STATES.BROWSE;

    if (Query.IsThrottled()) then
        Query.delay = time();
        return false;
    end

    Query.fullBrowseResults = false;
    wipe(Query.groupResults);

    C_AuctionHouse.SendBrowseQuery(filter);
    
    return true;
end

function Query.BrowseMore()
    Query.state = STATES.BROWSE_MORE;
    C_AuctionHouse.RequestMoreBrowseResults();
    return true;
end

function Query.SearchForItem(item, byItemID, firstOnly)
    
    -- set filter here
    local filter = {
        item = item,
        byItemID = byItemID,
        firstOnly = firstOnly
    };

    if (Query.state ~= STATES.NONE and Query.state ~= STATES.SEARCH) then
        tinsert(Query.queuedStates, {state = STATES.SEARCH, data = filter});
        return false;
    end

    Query.state = STATES.SEARCH;
    Query.previousState = STATES.SEARCH;

    Query.filter = filter;

    if (Query.IsThrottled()) then
        Query.delay = time();
        return false;
    end

    if (item and item.id) then
        local _ = GetItemInfo(item.id);
        if (_ and item and item.itemKey) then
            local info = C_AuctionHouse.GetItemKeyInfo(item.itemKey);
            local hash = ItemKeyHash(item.itemKey);
            if (info and hash) then
                Query.queuedSearches[hash] = item;
                Query.queuedSearches[item.id] = item;

                if (byItemID) then
                    C_AuctionHouse.SendSellSearchQuery(item.itemKey, DEFAULT_ITEM_SORT, true);
                else
                    C_AuctionHouse.SendSearchQuery(item.itemKey, DEFAULT_ITEM_SORT, true);
                end

                return true;
            end
        elseif (not item or not item.itemKey) then
            Query.delay = nil;
            return true;
        end
    elseif (not item or not item.id) then
        Query.delay = nil;
        return true;
    end

    -- if neither item info or item key info
    -- then we must wait for the events for item info or item key info
    -- then try again
    -- otherwise, the SendSearchQuery may fail for some unknown reason
    -- and will never trigger an event properly.
    Query.delay = time();
    return false;
end

function Query.Owned()
    if (Query.state ~= STATES.NONE and Query.state ~= STATES.OWNED) then
        tinsert(Query.queuedStates, {state = STATES.OWNED, data = nil});
        return false;
    end

    Query.state = STATES.OWNED;
    Query.previousState = STATES.OWNED;

    if (Query.IsThrottled()) then
        Query.delay = time();
        return false;
    end

    Query.delay = nil;
    C_AuctionHouse.QueryOwnedAuctions(DEFAULT_ITEM_SORT);
    return true;
end

-- override with your own is exiting
function Query.IsExiting()
    return false;
end

function Query.OnBrowseResults(added)
    if (Query.IsExiting() or (Query.state ~= STATES.BROWSE and Query.state ~= STATES.BROWSE_MORE)) then
        return;
    end

    if (added) then
        for i,v in ipairs(added) do
            if (Query.BrowseFilterFunc) then
                tinsert(browseResults, v);
            else
                tinsert(Query.groupResults, v);
            end
        end
    else
        local results = C_AuctionHouse.GetBrowseResults();
        wipe(Query.groupResults);
        wipe(browseResults);
        browseIndex = 1;

        for i,v in ipairs(results) do
            if (Query.BrowseFilterFunc) then
                tinsert(browseResults, v);
            else
                tinsert(Query.groupResults, v);
            end
        end
    end

    Query.fullBrowseResults = C_AuctionHouse.HasFullBrowseResults();

    if (not Query.BrowseFilterFunc or #browseResults == 0) then
        if (Query.state == STATES.BROWSE or Query.state == STATES.BROWSE_MORE) then
            Query.state = STATES.NONE;
            Query.filter = nil;
        end
        EventManager:Emit("QUERY_BROWSE_RESULTS");
    end
end

function Query.OnItemResults(itemKey)
    local hash = ItemKeyHash(itemKey);

    if (not hash) then
        return;
    end

    if (not Query.queuedSearches[hash] or Query.IsExiting()) then
        return;
    end

    if (not C_AuctionHouse.HasFullItemSearchResults(itemKey) and Query.filter and not Query.filter.firstOnly) then
        Query.state = STATES.SEARCH_MORE;
        Query.moreItem = {key = itemKey, isCommodity = false};

        C_AuctionHouse.RequestMoreItemSearchResults(itemKey);
        return;
    end

    local item = Query.queuedSearches[hash];

    if (not item or not item.id or not item.itemKey) then
        if (Query.state == STATES.SEARCH_MORE or Query.state == STATES.SEARCH) then
            Query.state = STATES.NONE;
            Query.moreItem = nil;
            Query.filter = nil;
        end

        return;
    end

    item.isCommodity = false;
    Query.queuedSearches[hash] = nil;
    Query.queuedSearches[item.id] = nil;

    for searchIndex = 1, C_AuctionHouse.GetNumItemSearchResults(itemKey) do
        local result = C_AuctionHouse.GetItemSearchResultInfo(itemKey, searchIndex);
        if (result.buyoutAmount) then
            item.count = result.quantity;
            item.ppu = result.buyoutAmount;
            item.buyoutPrice = result.buyoutAmount;
            item.owner = GetOwners(result);
            item.isOwnerItem = result.containsOwnerItem or result.containsAccountItem;

            if (result.itemLink) then
                item.link = result.itemLink;

                if (item.link) then
                    local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemIcon, itemSellPrice, itemClassID, itemSubClassID, bindType, expacID, itemSetID, isCraftingReagent = GetItemInfo(item.link); 

                    item.quality = itemRarity;
                    item.name = itemName;
                    item.texture = itemIcon;
                    item.vendorsell = itemSellPrice;
                end

                if (Utils:IsBattlePetLink(item.link)) then
                    local info = Utils:ParseBattlePetLink(item.link);
                    item.name = info.name;
                    item.iLevel = info.level;
                    item.quality = info.breedQuality;
                    item.texture = info.icon;
                end

                item.tsmId = Utils:GetTSMID(item.link);
            end

            item.auctionId = result.auctionID;

            EventManager:Emit("QUERY_SEARCH_RESULT", item);

            if (Query.filter and Query.filter.firstOnly) then
                break;
            end
        end
    end

    if (Query.state == STATES.SEARCH_MORE or Query.state == STATES.SEARCH) then
        Query.state = STATES.NONE;
        Query.moreItem = nil;
        Query.filter = nil;
    end
    EventManager:Emit("QUERY_SEARCH_COMPLETE", item);
end

function Query.OnCommodityResults(itemID)
    if (not Query.queuedSearches[itemID] or Query.IsExiting()) then
        return;
    end

    if (not C_AuctionHouse.HasFullCommoditySearchResults(itemID) and Query.filter and not Query.filter.firstOnly) then
        Query.state = STATES.SEARCH_MORE;
        Query.moreItem = {key = itemID, isCommodity = true};

        C_AuctionHouse.RequestMoreCommoditySearchResults(itemID);
        return;
    end

    local item = Query.queuedSearches[itemID];

    if (not item or not item.id or not item.itemKey) then
        if (Query.state == STATES.SEARCH_MORE or Query.state == STATES.SEARCH) then
            Query.state = STATES.NONE;
            Query.moreItem = nil;
            Query.filter = nil;
        end

        return;
    end

    item.isCommodity = true;
    Query.queuedSearches[itemID] = nil;

    local hash = ItemKeyHash(item.itemKey);

    if (hash) then
        Query.queuedSearches[hash] = nil;
    end

    for searchIndex = 1, C_AuctionHouse.GetNumCommoditySearchResults(itemID) do
        local result = C_AuctionHouse.GetCommoditySearchResultInfo(itemID, searchIndex);
        item.count = result.quantity;
        item.ppu = result.unitPrice;
        item.buyoutPrice = result.unitPrice * result.quantity;
        item.owner = GetOwners(result);
        item.isOwnerItem = result.containsOwnerItem or result.containsAccountItem;

        if (item.id) then
            local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemIcon, itemSellPrice, itemClassID, itemSubClassID, bindType, expacID, itemSetID, isCraftingReagent = GetItemInfo(item.id); 

            if (itemName and itemLink) then
                item.link = itemLink;

                item.quality = itemRarity;
                item.name = itemName;
                item.texture = itemIcon;
                item.vendorsell = itemSellPrice;
            end
        end

        EventManager:Emit("QUERY_SEARCH_RESULT", item);

        if (Query.filter and Query.filter.firstOnly) then
            break;
        end
    end

    if (Query.state == STATES.SEARCH_MORE or Query.state == STATES.SEARCH) then
        Query.state = STATES.NONE;
        Query.moreItem = nil;
        Query.filter = nil;
    end
    EventManager:Emit("QUERY_SEARCH_COMPLETE", item);
end

EventManager:On("AUCTION_HOUSE_THROTTLED_MESSAGE_RESPONSE_RECEIVED", Query.ThrottleReceived);
EventManager:On("AUCTION_HOUSE_THROTTLED_MESSAGE_QUEUED", Query.ThrottleQueued);
EventManager:On("AUCTION_HOUSE_THROTTLED_MESSAGE_DROPPED", Query.ThrottleDropped);
EventManager:On("AUCTION_HOUSE_THROTTLED_MESSAGE_SENT", Query.ThrottleSent);

EventManager:On("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED", Query.OnBrowseResults);
EventManager:On("AUCTION_HOUSE_BROWSE_RESULTS_ADDED", Query.OnBrowseResults);

EventManager:On("ITEM_SEARCH_RESULTS_UPDATED", Query.OnItemResults);
EventManager:On("ITEM_SEARCH_RESULTS_ADDED", Query.OnItemResults);

EventManager:On("COMMODITY_SEARCH_RESULTS_UPDATED", Query.OnCommodityResults);
EventManager:On("COMMODITY_SEARCH_RESULTS_ADDED", Query.OnCommodityResults);

EventManager:On("OWNED_AUCTIONS_UPDATED", Query.OnOwnedUpdate);

EventManager:On("UPDATE", Query.OnUpdate);

EventManager:On("AUCTION_HOUSE_CLOSED", Query.Clear);
