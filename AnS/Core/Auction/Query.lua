local Ans = select(2, ...);
local Config = Ans.Config;
local Utils = Ans.Utils;
local Logger = Ans.Logger;
local Sources = Ans.Sources;
local Tasker = Ans.Tasker;
local FSM = Ans.FSM;
local FSMState = Ans.FSMState;
local EventManager = Ans.EventManager;
local Recycler = Ans.Auctions.Recycler;
local Auction = Ans.Auctions.Auction;
local TempTable = Ans.TempTable;

local QueryFSM = nil;

local Query = Ans.Object.Register("Query", Ans.Auctions);

local throttleMessageReceived = true;
local throttleWaitingForSend = false;
local throttleTime = GetTime();

local EVENTS_TO_REGISTER = {};

local DEFAULT_ITEM_SORT = {
    { sortOrder = 0, reverseSort = false },
    { sortOrder = 4, reverseSort = false },
};

local ownedAuctions = {};

local MAX_THROTTLE_WAIT = 0.25;
local TASKER_TAG = "QUERY";

if (not Utils.IsClassic()) then
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
        "AUCTION_MULTISELL_FAILURE",
        "UI_ERROR_MESSAGE",
        "CHAT_MSG_SYSTEM"
    };
else
    EVENTS_TO_REGISTER = {
        "AUCTION_ITEM_LIST_UPDATE",
        "AUCTION_OWNED_LIST_UPDATE",
        "UI_ERROR_MESSAGE"
    };
end

local function Truncate(str)
    if(str:len() <= 63) then
        return str;
    end

    return str:sub(1, 62);
end

local function ItemHash(item)
    if (item.auctionId) then
        return tostring(item.auctionId);
    end

    return item.link..item.count..item.ppu;
end

local function ItemKeyHash(itemKey)
    if (not itemKey) then
        return nil;
    end

    return ""..itemKey.itemID..itemKey.itemLevel..itemKey.battlePetSpeciesID;
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

Query.ItemKeyHash = ItemKeyHash;
Query.DEFAULT_ITEM_SORT = DEFAULT_ITEM_SORT;

Query.ops = {};
Query.page = 0;
Query.itemIndex = 1;
Query.blacklist = {};
Query.results = {};

Query.browseFilter = nil;
Query.fullBrowseResults = false;
Query.lastQueryType = nil;

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

    local sniperConfig = Config.Sniper();

    for i,v in ipairs(self.ops) do
        if (v.inheritGlobal) then
            v.minILevel = ilevel;
            v.price = sniperConfig.pricing;
            v.maxPercent = maxPercent;
            v.maxPPU = buyout;
            v.ignoreGroupMaxPercent = sniperConfig.ignoreGroupMaxPercent;
            v.minQuality = quality;
        end
    end
end

function Query:AssignSnipingOps(ops) 
    wipe(self.ops);

    for i,v in ipairs(ops) do
        tinsert(self.ops, v);
    end
end

function Query:IsValid(item, ignoreMaxPercent) 
    if (item.iLevel < self.minILevel and self.minILevel > 0) then
        return false;
    end
    if (item.ppu > self.maxBuyout and self.maxBuyout > 0) then
        return false;
    end
    if (item.percent > self.maxPercent and self.maxPercent > 0 and not ignoreMaxPercent) then
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
        blacklist = {};
        Config.Sniper().characterBlacklist = blacklist;
    end

    local isOnBlacklist = false;

    if (auction.owner and #blacklist > 0) then
        if (type(auction.owner) ~= "table") then
            if (auction.owner ~= "" and auction.owner:len() > 0) then
                isOnBlacklist = Utils.InTable(blacklist, auction.owner:lower());
            end
        else
            for i,v in ipairs(auction.owner) do
                if (v ~= "" and v:len() > 0) then
                    local contains = Utils.InTable(blacklist, v:lower());
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

    if (Config.Sniper().itemBlacklist[auction.tsmId] or Query:IsBlacklisted(auction)) then
        return false;
    end

    if (auction.buyoutPrice > 0) then
        local avg = Sources:Query(Config.Sniper().source, auction, false);
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
                    if (auction.ppu <= allowed and self:IsValid(auction, false)) then
                        filterAccepted = true;
                    end
                else
                    if (allowed and self:IsValid(auction, false)) then
                        filterAccepted = true;
                    end
                end
            else
                filterAccepted = self:IsValid(auction, false);
            end
        end

        local tf = #self.ops;
        for k = 1, tf do
            if (self.ops[k]:IsValid(auction, true, false)) then
                filterAccepted = true;
                break;
            end
        end

        return filterAccepted;
    end

    return false;
end

function Query:GetGroupHash(group)
    if (not group) then
        return nil;
    end

    return group.itemKey.itemID.."."..group.itemKey.itemLevel.."."..group.itemKey.itemSuffix.."."..group.itemKey.battlePetSpeciesID;
end

function Query:GetGroupInfo(group)
    return C_AuctionHouse.GetItemKeyInfo(group.itemKey);
end

-- used for retail auction group data
function Query:GetAuctionData(group, info)
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
    auction.suffix = group.itemKey.itemSuffix or 0;

    auction.ppu = group.minPrice;
    auction.buyoutPrice = auction.ppu;

    auction.link = nil;

    local groupInfo = info or C_AuctionHouse.GetItemKeyInfo(group.itemKey);

    if (not groupInfo) then
        Recycler:Recycle(auction);
        return nil, false;
    end

    if (group.itemKey.battlePetSpeciesID > 0) then
        auction.link = groupInfo.battlePetLink;
        auction.isPet = true;
    end
    
    auction.quality = groupInfo.quality;
    auction.texture = groupInfo.iconFileID;
    auction.name = groupInfo.itemName;
    auction.isCommodity = groupInfo.isCommodity;

    auction.type = 0;
    auction.subtype = 0;
    auction.vendorsell = 0;

    if (auction.link and Utils.IsBattlePetLink(auction.link)) then
        local info = Utils.ParseBattlePetLink(auction.link);
        auction.texture = info.icon;
        auction.iLevel = info.level;
        auction.name = info.name;
        auction.quality = info.breedQuality;
        auction.tsmId = Utils.GetID(auction.link);
    else
        auction.tsmId = "i:"..auction.id;
    end

    return auction;
end

function Query:IsFilteredGroup(auction)
    if (not auction) then
        return nil, false;
    end

    local ignoreMaxPercent = Config.Sniper().ignoreGroupMaxPercent;

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
            local allowed = 0;
            
            allowed = Sources:Query(Config.Sniper().pricing, auction, true);
        
            if (type(allowed) == "boolean" or type(allowed) == "number") then
                if (type(allowed) == "number") then
                    if (auction.ppu <= allowed and self:IsValid(auction, ignoreMaxPercent)) then
                        filterAccepted = true;
                    end
                else
                    if (allowed and self:IsValid(auction, ignoreMaxPercent)) then
                        filterAccepted = true;
                    end
                end
            else
                filterAccepted = self:IsValid(auction, ignoreMaxPercent);
            end
        end

        local tf = #self.ops;
        for k = 1, tf do
            if (self.ops[k]:IsValid(auction, auction.isPet, true)) then
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

function Query:Search(filter, autoPage)
    local ready = self:IsReady();
    
    self.itemIndex = 1;
    self.filter = filter;
    self.autoPage = autoPage;

    if (ready) then
        -- ensure we remove the previous listener if there was one still
        EventManager:Off("AUCTION_ITEM_LIST_UPDATE", Query.OnListUpdate);
        EventManager:On("AUCTION_ITEM_LIST_UPDATE", Query.OnListUpdate);
        self.delay = nil;
        QueryAuctionItems(filter.searchString or "", filter.minLevel, filter.maxLevel, self.page, false, filter.quality, false, false);
    else
        Tasker.Delay(GetTime() + 1, function() 
            Query:Search(filter, autoPage);
        end, TASKER_TAG);
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

    local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, stackSize, _, _, vendorsell  = GetItemInfo(auction.link);
    if (itemName) then
        auction.iLevel = itemLevel;
        auction.vendorsell = vendorsell or 0;
    end

    auction.tsmId = Utils.GetID(auction.link);

    auction.ppu = math.floor(auction.buyoutPrice / auction.count);

    -- fix for when ppu is less than 1 aka a decimal
    -- mainly happens on items that are a buyoutPrice of 1c and have
    -- multiples in stack
    if (auction.ppu < 1) then
        auction.ppu = 1;
    end

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
        auction.vendorsell = vendorsell or 0;
    end

    if (auction.buyoutPrice <= 0 or auction.saleStatus ~= 0 or not auction.hasAll) then
        Recycler:Recycle(auction);
        return nil;
    end

    auction.tsmId = Utils.GetID(auction.link);

    auction.ppu = math.floor(auction.buyoutPrice / auction.count);

    -- fix for when ppu is less than 1 aka a decimal
    -- mainly happens on items that are a buyoutPrice of 1c and have
    -- multiples in stack
    if (auction.ppu < 1) then
        auction.ppu = 1;
    end

    auction.hash = ItemHash(auction);

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

    -- remove listener as we only want the first update
    EventManager:Off("AUCTION_ITEM_LIST_UPDATE", Query.OnListUpdate);

    while (Query:HasNext()) do
        local item = Query:Next();
        if (item) then
            EventManager:Emit("QUERY_SEARCH_RESULT", item);
        end
    end

    if (not Query:IsLast() and Query.autoPage) then
        Query:NextPage();
        Query:Search(Query.filter, Query.autoPage, Query.op);
    else
        self.filter = nil;

        EventManager:Emit("QUERY_SEARCH_COMPLETE");
    end
end

local browseResults = {};
local browseIndex = 1;

-- retail and classic specific updates

function Query.OnUpdate()
    if (#browseResults > 0 and browseIndex <= #browseResults and Query.browseFilter) then
        local count = 0;
        while (browseIndex <= #browseResults and count < Config.Sniper().itemsPerUpdate) do

            local group = browseResults[browseIndex];

            if (group) then
                local filtered = Query.browseFilter(group);
                if (filtered) then
                    tinsert(Query.results, filtered);
                end
            end

            browseIndex = browseIndex + 1;
            count = count + 1;
        end
        
        if (browseIndex > #browseResults) then
            wipe(browseResults);
            browseIndex = 1;

            if (not QueryFSM) then
                return;
            end

            QueryFSM:Process("IDLE");
        end
    end
end

-- retail

-- helper function for Owned Auctions for Retail
function Query:GetOwnedAuctionRetail(index)
    local info = C_AuctionHouse.GetOwnedAuctionInfo(index);

    if (not info) then
        return nil;
    end

    local keyInfo = C_AuctionHouse.GetItemKeyInfo(info.itemKey);

    if (not keyInfo) then
        return nil;
    end

    local auction = Recycler:Get();

    auction.link = info.itemLink;
    auction.tsmId = Utils.GetID(auction.link);

    auction.isCommodity = keyInfo.isCommodity;
    auction.isEquipment = keyInfo.isEquipment;
    auction.id = info.itemKey.itemID;
    auction.auctionId = info.auctionID;
    auction.itemKey = info.itemKey;
    auction.status = info.status;
    auction.count = info.quantity;
    auction.ppu = info.buyoutAmount;
    auction.bidder = info.bidder;
    auction.iLevel = info.itemKey.itemLevel;
    auction.suffix = info.itemKey.itemSuffix;

    if (info.itemKey.battlePetSpeciesID > 0 
        and keyInfo.battlePetLink 
        and Utils.IsBattlePetLink(keyInfo.battlePetLink)) then
        
        local info = Utils.ParseBattlePetLink(keyInfo.battlePetLink);
        auction.iLevel = info.level;
        auction.link = keyInfo.battlePetLink;
    end

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
        auction.vendorsell = vendorsell or 0;
        auction.quality = itemRarity;
    end

    auction.tsmId = Utils.GetID(auction.link);

    auction.hash = ItemHash(auction);

    return auction;
end

function Query.OnOwnedUpdate()
    QueryFSM:Process("OWNED_RESULTS");
end

-- throttle related for retail
function Query.ThrottleReceived()
    throttleTime = GetTime();
    throttleMessageReceived = true;
    Logger.Log("Throttled message received");
end

function Query.ThrottleQueued()
    throttleMessageReceived = false;
    throttleWaitingForSend = true;
    Logger.Log("Throttle message queued");
end

function Query.ThrottleDropped()
    throttleWaitingForSend = false;
    throttleMessageReceived = true;

    throttleTime = GetTime();

    Logger.Log("Message dropped due to throttle - increasing retry time");

    if (not QueryFSM) then
        return;
    end

    QueryFSM:Process("DROPPED");
end

function Query.ThrottleSent()
    throttleTime = GetTime();
    throttleWaitingForSend = false;
    Logger.Log("Throttled message sent");
end

function Query.ClearThrottle()
    throttleTime = 0;
    MAX_THROTTLE_WAIT = 0.25;
    throttleMessageReceived = true;
    throttleWaitingForSend = false;
end

function Query.Clear()
    Tasker.Clear(TASKER_TAG);

    if (not QueryFSM) then
        return;
    end

    QueryFSM:Interrupt();
end

function Query.IsThrottled()
    return throttleMessageReceived == false or throttleWaitingForSend == true;
end

function Query.Error(type, msg)
    if (QueryFSM) then
        if (msg == ERR_AUCTION_DATABASE_ERROR) then
            MAX_THROTTLE_WAIT = MAX_THROTTLE_WAIT + 0.25;

            if (MAX_THROTTLE_WAIT > 10) then
                MAX_THROTTLE_WAIT = 0.25;
                print("AnS - Auction House possibly phased. Please close and reopen");
            end

            Query.ThrottleDropped();
        end
    end
end

function Query.Browse(filter)
    if (not QueryFSM) then
        return;
    end

    if (not QueryFSM.current) then
        QueryFSM.current = "IDLE";
    end
    QueryFSM:Process("BROWSE", filter);
end

function Query.BrowseMore()
    if (not QueryFSM) then
        return;
    end

    if (not QueryFSM.current) then
        QueryFSM.current = "IDLE";
    end
    Logger.Log("QUERY", "Browse More Event");
    QueryFSM:Process("BROWSE_MORE");
end

function Query.OnBrowseResults(added)
    Logger.Log("QUERY", "Browse Results Event");
    local transitionSuccess = QueryFSM:Process("BROWSE_RESULTS", added);
end

function Query.SearchForItem(item, byItemID, firstOnly)
    if (not QueryFSM) then
        return;
    end

    if (not QueryFSM.current) then
        QueryFSM.current = "IDLE";
    end
    QueryFSM:Process("SEARCH", item, byItemID, firstOnly);
end

function Query.SearchForItems(items, byItemID, firstOnly)
    if (not QueryFSM) then
        return;
    end

    if (not QueryFSM.current) then
        QueryFSM.current = "IDLE";
    end

    QueryFSM:Process("SEARCH", items, byItemID, firstOnly);
end

function Query.Owned()
    if (not QueryFSM) then
        return;
    end

    if (not QueryFSM.current) then
        QueryFSM.current = "IDLE";
    end
    QueryFSM:Process("OWNED");
end

function Query.ProcessCommodity(item, itemID)
    for searchIndex = 1, C_AuctionHouse.GetNumCommoditySearchResults(itemID) do
        local result = C_AuctionHouse.GetCommoditySearchResultInfo(itemID, searchIndex);
        item.count = result.quantity;
        item.ppu = result.unitPrice;
        item.buyoutPrice = result.unitPrice * result.quantity;
        item.owner = GetOwners(result);
        item.isCommodity = true;
        item.isOwnerItem = result.containsOwnerItem or result.containsAccountItem;

        if (item.id) then
            local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemIcon, itemSellPrice, itemClassID, itemSubClassID, bindType, expacID, itemSetID, isCraftingReagent = GetItemInfo(item.id); 

            if (itemName and itemLink) then
                item.link = itemLink;

                item.quality = itemRarity;
                item.name = itemName;
                item.texture = itemIcon;
                item.vendorsell = itemSellPrice or 0;
            end
        end

        -- set to nil to make sure
        -- it is cleared if it some
        -- how got filled in
        item.auctionId = nil;

        item.hash = ItemHash(item);

        EventManager:Emit("QUERY_SEARCH_RESULT", item);

        if (Query.filter and Query.filter.first) then
            break;
        end
    end
end

function Query.ProcessItem(item, itemKey)
    for searchIndex = 1, C_AuctionHouse.GetNumItemSearchResults(itemKey) do
        local result = C_AuctionHouse.GetItemSearchResultInfo(itemKey, searchIndex);
        if (result.buyoutAmount) then
            item.isCommodity = false;
            item.count = result.quantity;
            item.ppu = result.buyoutAmount;
            item.buyoutPrice = result.buyoutAmount;
            item.owner = GetOwners(result);
            item.isOwnerItem = result.containsOwnerItem or result.containsAccountItem;

            if (result.itemLink) then
                item.link = result.itemLink;

                if (Utils.IsBattlePetLink(item.link)) then
                    local info = Utils.ParseBattlePetLink(item.link);
                    item.name = info.name;
                    item.iLevel = info.level;
                    item.quality = info.breedQuality;
                    item.texture = info.icon;
                    item.vendorsell = 0;
                else
                    local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemIcon, itemSellPrice, itemClassID, itemSubClassID, bindType, expacID, itemSetID, isCraftingReagent = GetItemInfo(item.link); 

                    if (_G["GetDetailedItemLevelInfo"]) then
                        local eff, preview, base = GetDetailedItemLevelInfo(item.link);
                        if (preview) then
                            item.iLevel = itemLevel;
                        elseif (eff) then
                            item.iLevel = eff;
                        else
                            item.iLevel = itemLevel;
                        end
                    else
                        item.iLevel = itemLevel;
                    end

                    item.quality = itemRarity;
                    item.name = itemName;
                    item.texture = itemIcon;
                    item.vendorsell = itemSellPrice or 0;
                end

                item.tsmId = Utils.GetID(item.link);
            end

            item.auctionId = result.auctionID;

            item.hash = ItemHash(item);

            EventManager:Emit("QUERY_SEARCH_RESULT", item);

            if (Query.filter and Query.filter.first) then
                break;
            end
        end
    end
end

-- override with your own is exiting
function Query.IsExiting()
    return false;
end

function Query.OnItemResults(itemKey)
    if (not QueryFSM) then
        return;
    end

    Logger.Log("QUERY", "item results");
    QueryFSM:Process("ITEM_RESULT", itemKey);
end

function Query.OnItemResultsAdded(itemKey)
    if (not QueryFSM) then
        return;
    end

    Logger.Log("QUERY", "item results added");
    QueryFSM:Process("ITEM_RESULT", itemKey);
end

function Query.OnCommodityResults(itemID)
    if (not QueryFSM) then
        return;
    end

    Logger.Log("QUERY", "commodity results");
    QueryFSM:Process("COMMODITY_RESULT", itemID);
end

function Query.OnCommodityResultsAdded(itemID)
    if (not QueryFSM) then
        return;
    end

    Logger.Log("QUERY", "commodity results added");
    QueryFSM:Process("COMMODITY_RESULT", itemID);
end

-- the state machine is only really used
-- for retail
-- since the classic version is simpler
-- it is not needed
local function BuildStateMachine()
    local fsm = FSM:Acquire("QueryFSM");

    local idle = FSMState:Acquire("IDLE");
    idle:AddEvent("BROWSE");
    idle:AddEvent("BROWSE_MORE");
    idle:AddEvent("SEARCH");
    idle:AddEvent("OWNED");

    fsm:Add(idle);

    local tryBrowseFunc = function()
        QueryFSM:Process("TRY_BROWSE");
    end
    local browse = FSMState:Acquire("BROWSE");
    browse:SetOnEnter(function(self, filter)
        Query.filter = filter;
        Query.fullBrowseResults = false;
        Query.lastQueryType = "BROWSE";
        wipe(Query.results);

        Logger.Log("QUERY", "browse on enter");

        Tasker.Delay(throttleTime + MAX_THROTTLE_WAIT, tryBrowseFunc, TASKER_TAG);
        return nil;
    end);
    browse:AddEvent("TRY_BROWSE");
    browse:AddEvent("IDLE");
    browse:AddEvent("SEARCH");

    fsm:Add(browse);

    local tryBrowse = FSMState:Acquire("TRY_BROWSE");
    tryBrowse:SetOnEnter(function(self)
        if (not Query.filter) then
            return "IDLE";
        end

        local filter = Query.filter;
        Logger.Log("QUERY", "trying to send browse");
        C_AuctionHouse.SendBrowseQuery(filter);
        return nil;
    end);
    local browseResultsFunc = function()
        EventManager:Emit("QUERY_BROWSE_RESULTS");
    end
    tryBrowse:SetOnExit(function(self, next) 
        if (next == "IDLE") then
            Tasker.Schedule(browseResultsFunc, TASKER_TAG);
        end
    end);
    tryBrowse:AddEvent("IDLE");
    tryBrowse:AddEvent("BROWSE_RESULTS");
    tryBrowse:AddEvent("BROWSE");
    tryBrowse:AddEvent("DROPPED", function(self)
        Logger.Log("QUERY", "browse dropped");
        return "BROWSE", Query.filter;
    end);
    tryBrowse:AddEvent("SEARCH");

    fsm:Add(tryBrowse);

    local fsmbrowseResults = FSMState:Acquire("BROWSE_RESULTS");
    fsmbrowseResults:SetOnEnter(function(self, added)
        Logger.Log("QUERY", "processing browse results");
        if (added) then
            for i,v in ipairs(added) do
                if (Query.browseFilter) then
                    tinsert(browseResults, v);
                else
                    tinsert(Query.results, v);
                end
            end
        else
            local results = C_AuctionHouse.GetBrowseResults();

            wipe(Query.results);
            wipe(browseResults);

            browseIndex = 1;

            for i,v in ipairs(results) do
                if (Query.browseFilter) then
                    tinsert(browseResults, v);
                else
                    tinsert(Query.results, v);
                end
            end
        end

        Query.fullBrowseResults = C_AuctionHouse.HasFullBrowseResults();

        if (not Query.browseFilter or #browseResults == 0) then
            return "IDLE";
        end

        return nil;
    end);
    fsmbrowseResults:SetOnExit(function(self, next)
        Logger.Log("QUERY", "browse result complete");
        if (next == "IDLE") then
            Tasker.Schedule(browseResultsFunc, TASKER_TAG);
        end
    end);
    fsmbrowseResults:AddEvent("IDLE");
    fsmbrowseResults:AddEvent("SEARCH");

    fsm:Add(fsmbrowseResults);

    local tryBrowseMoreFunc = function()
        QueryFSM:Process("TRY_BROWSE_MORE");
    end
    local browseMore = FSMState:Acquire("BROWSE_MORE");
    browseMore:SetOnEnter(function(self)
        Query.lastQueryType = "BROWSE";
        Tasker.Delay(throttleTime + MAX_THROTTLE_WAIT, tryBrowseMoreFunc, TASKER_TAG);
        return nil;
    end);
    browseMore:AddEvent("TRY_BROWSE_MORE");
    browseMore:AddEvent("IDLE");
    browseMore:AddEvent("SEARCH");

    fsm:Add(browseMore);

    local tryBrowseMore = FSMState:Acquire("TRY_BROWSE_MORE");
    tryBrowseMore:SetOnEnter(function(self)
        Query.lastQueryType = "BROWSE";
        C_AuctionHouse.RequestMoreBrowseResults();
        return nil;
    end);
    tryBrowseMore:AddEvent("BROWSE_RESULTS");
    tryBrowseMore:AddEvent("DROPPED", function(self)
        return "BROWSE_MORE";
    end);
    tryBrowseMore:AddEvent("IDLE");
    tryBrowseMore:AddEvent("SEARCH");
    tryBrowseMore:AddEvent("BROWSE_MORE");

    fsm:Add(tryBrowseMore);

    local trySearchFunc = function()
        QueryFSM:Process("TRY_SEARCH");
    end
    local search = FSMState:Acquire("SEARCH");
    search:SetOnEnter(function(self, item, sell, first)
        if (Query.filter) then
            Query.filter.item = item;
            Query.filter.sell = sell;
            Query.filter.first = first;
        else
            Query.filter = {
                item = item,
                sell = sell,
                first = first
            };
        end

        Tasker.Delay(throttleTime + MAX_THROTTLE_WAIT, trySearchFunc, TASKER_TAG);    
    end);
    search:AddEvent("TRY_SEARCH");
    search:AddEvent("IDLE");
    fsm:Add(search);

    local trySearch = FSMState:Acquire("TRY_SEARCH");
    trySearch:SetOnEnter(function(self)
        if (not Query.filter or not Query.filter.item) then
            return "IDLE";
        end

        local item = Query.filter.item;
        local sell = Query.filter.sell;

        Logger.Log("QUERY", "trying to start search");

        if (item and item.id) then
            local _ = GetItemInfo(item.id);
            if (_ and item and item.itemKey) then
                local info = C_AuctionHouse.GetItemKeyInfo(item.itemKey);
                if (info) then
                    Logger.Log("QUERY", "sending search query");
                    item.isCommodity = info.isCommodity;

                    Query.lastQueryType = "SEARCH";

                    if (sell) then
                        C_AuctionHouse.SendSellSearchQuery(item.itemKey, DEFAULT_ITEM_SORT, true);
                    else
                        C_AuctionHouse.SendSearchQuery(item.itemKey, DEFAULT_ITEM_SORT, true);
                    end
    
                    return "ITEM_RESULTS", item;
                end
            elseif (not item or not item.itemKey) then
                return "IDLE";
            end
        elseif (not item or not item.id) then
            return "IDLE";
        end

        return "SEARCH", Query.filter.item, Query.filter.sell, Query.filter.first;
    end);
    local searchCompleteFunc = function()
        EventManager:Emit("QUERY_SEARCH_COMPLETE");
    end
    trySearch:SetOnExit(function(self, next)
        if (next == "IDLE") then
            Tasker.Schedule(searchCompleteFunc, TASKER_TAG);
        end
    end);
    trySearch:AddEvent("IDLE");
    trySearch:AddEvent("ITEM_RESULTS");
    trySearch:AddEvent("SEARCH");
    trySearch:AddEvent("DROPPED", function(self)
        return "SEARCH", Query.filter.item, Query.filter.sell, Query.filter.first;
    end);

    fsm:Add(trySearch);

    local itemResults = FSMState:Acquire("ITEM_RESULTS");
    itemResults:SetOnEnter(function(self, item)
        Logger.Log("QUERY", "on item results");
        self.item = item;
        return nil;
    end);
    itemResults:SetOnExit(function(self, next)
        self.item = nil;
        Logger.Log("QUERY", "item results complete");
        Tasker.Schedule(searchCompleteFunc, TASKER_TAG);
    end);
    itemResults:AddEvent("IDLE");
    itemResults:AddEvent("MORE_ITEMS", function(self)
        if (not self.item) then
            return nil;
        end

        Tasker.Delay(throttleTime + MAX_THROTTLE_WAIT, function()
            if (not self.item) then
                return;
            end
            C_AuctionHouse.RequestMoreItemSearchResults(self.item.itemKey);
        end, TASKER_TAG);
    end);
    itemResults:AddEvent("MORE_COMMODITIES", function(self)
        if (not self.item) then
            return nil;
        end

        Tasker.Delay(throttleTime + MAX_THROTTLE_WAIT, function()
            if (not self.item) then
                return;
            end
            C_AuctionHouse.RequestMoreCommoditySearchResults(self.item.itemKey);
        end, TASKER_TAG);
    end);
    itemResults:AddEvent("DROPPED", function(self)
        if (not self.item) then
            return nil;
        end

        Tasker.Schedule(function()
            if (not self.item) then
                return;
            end
            if (self.item.isCommodity) then
                QueryFSM:Process("MORE_COMMODITIES");
            else
                QueryFSM:Process("MORE_ITEMS");
            end
        end, TASKER_TAG);
    end);
    local moreItemsFunc = function()
        QueryFSM:Process("MORE_ITEMS");
    end
    itemResults:AddEvent("ITEM_RESULT", function(self, event, itemKey)
        if (not self.item) then
            return nil;
        end

        local iLevel = itemKey.itemLevel;

        if (itemKey.battlePetSpeciesID > 0) then
            local info = C_AuctionHouse.GetItemKeyInfo(itemKey);
            if (info and info.battlePetLink and Utils.IsBattlePetLink(info.battlePetLink)) then
                local info = Utils.ParseBattlePetLink(info.battlePetLink);
                iLevel = info.level;
            end
        end

        if (itemKey.itemID == self.item.id 
            and itemKey.battlePetSpeciesID == self.item.itemKey.battlePetSpeciesID 
            and not C_AuctionHouse.HasFullItemSearchResults(self.item.itemKey) 
            and Query.filter 
            and not Query.filter.first) then
                Logger.Log("QUERY", "Querying more items");
                Tasker.Schedule(moreItemsFunc, TASKER_TAG);
                return nil;
        end

        local needsProcessing = true;

        if (itemKey.itemID ~= self.item.id 
            or itemKey.battlePetSpeciesID ~= self.item.itemKey.battlePetSpeciesID 
            or (iLevel ~= self.item.iLevel and iLevel > 0 and self.item.iLevel > 0)
            or self.item.isCommodity) then

            Logger.Log("QUERY", "item id match: "..tostring(itemKey.itemID == self.item.id));
            Logger.Log("QUERY", "item level incoming: "..tostring(itemKey.itemLevel).." item level expected:"..tostring(self.item.iLevel));
            Logger.Log("QUERY", "item level match: "..tostring(itemKey.itemLevel == self.item.iLevel));
            Logger.Log("QUERY", "incoming id: "..itemKey.itemID);
            Logger.Log("QUERY", "expected id:"..self.item.id);
            Logger.Log("QUERY", "battle pet species match: "..tostring(itemKey.battlePetSpeciesID == self.item.itemKey.battlePetSpeciesID));
            Logger.Log("QUERY", "is commodity: "..tostring(self.item.isCommodity));

            needsProcessing = false;
        end

        if (needsProcessing) then
            Query.ProcessItem(self.item, self.item.itemKey);
            return "IDLE";
        end

        return nil;
    end);
    local moreCommoditiesFunc = function()
        QueryFSM:Process("MORE_COMMODITIES");
    end
    itemResults:AddEvent("COMMODITY_RESULT", function(self, event, itemID)
        if (not self.item) then
            return nil;
        end

        if (itemID == self.item.id and not C_AuctionHouse.HasFullCommoditySearchResults(itemID) and Query.filter and not Query.filter.first) then
            Logger.Log("QUERY", "Querying more commodities");
            Tasker.Schedule(moreCommoditiesFunc, TASKER_TAG);
            return nil;
        end

        local needsProcessing = true;

        if (itemID ~= self.item.id or not self.item.isCommodity) then
            needsProcessing = false;
        end

        if (needsProcessing) then
            Query.ProcessCommodity(self.item, itemID);
        end

        if (itemID == self.item.id) then
            return "IDLE";
        end

        return nil;
    end);

    fsm:Add(itemResults);
    fsm:Add(FSMState:Acquire("MORE_ITEMS"));
    fsm:Add(FSMState:Acquire("ITEM_RESULT"));
    fsm:Add(FSMState:Acquire("MORE_COMMODITIES"));
    fsm:Add(FSMState:Acquire("COMMODITY_RESULT"));

    local tryOwnedFunc = function()
        QueryFSM:Process("TRY_OWNED");
    end
    local owned = FSMState:Acquire("OWNED");
    owned:SetOnEnter(function(self)
        Tasker.Delay(throttleTime + MAX_THROTTLE_WAIT, tryOwnedFunc, TASKER_TAG);
        return nil;
    end);
    owned:AddEvent("TRY_OWNED");

    fsm:Add(owned);

    local tryOwned = FSMState:Acquire("TRY_OWNED");
    tryOwned:SetOnEnter(function(self)
        C_AuctionHouse.QueryOwnedAuctions(DEFAULT_ITEM_SORT);
        return nil;
    end);
    tryOwned:AddEvent("DROPPED", function(self)
        return "OWNED";
    end);
    tryOwned:AddEvent("OWNED_RESULTS");
    tryOwned:AddEvent("OWNED");

    fsm:Add(tryOwned);

    local ownedResults = FSMState:Acquire("OWNED_RESULTS");
    ownedResults:SetOnEnter(function(self)
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

        Tasker.Schedule(function()
            EventManager:Emit("QUERY_OWNED_AUCTIONS", ownedAuctions);
        end, TASKER_TAG);
        return "IDLE";
    end);
    ownedResults:AddEvent("IDLE");

    fsm:Add(ownedResults);

    fsm:Add(FSMState:Acquire("DROPPED"));
    fsm:Add(FSMState:Acquire("DELAY_COMPLETE"));

    fsm:Start("IDLE");

    return fsm;
end

EventManager:On("AUCTION_HOUSE_THROTTLED_MESSAGE_RESPONSE_RECEIVED", Query.ThrottleReceived);
EventManager:On("AUCTION_HOUSE_THROTTLED_MESSAGE_QUEUED", Query.ThrottleQueued);
EventManager:On("AUCTION_HOUSE_THROTTLED_MESSAGE_DROPPED", Query.ThrottleDropped);
EventManager:On("AUCTION_HOUSE_THROTTLED_MESSAGE_SENT", Query.ThrottleSent);

EventManager:On("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED", Query.OnBrowseResults);
EventManager:On("AUCTION_HOUSE_BROWSE_RESULTS_ADDED", Query.OnBrowseResults);

EventManager:On("ITEM_SEARCH_RESULTS_UPDATED", Query.OnItemResults);
EventManager:On("ITEM_SEARCH_RESULTS_ADDED", Query.OnItemResultsAdded);

EventManager:On("COMMODITY_SEARCH_RESULTS_UPDATED", Query.OnCommodityResults);
EventManager:On("COMMODITY_SEARCH_RESULTS_ADDED", Query.OnCommodityResultsAdded);

EventManager:On("OWNED_AUCTIONS_UPDATED", Query.OnOwnedUpdate);

EventManager:On("UPDATE", Query.OnUpdate);

EventManager:On("AUCTION_HOUSE_CLOSED", Query.Clear);
EventManager:On("AUCTION_HOUSE_SHOW", function()
    QueryFSM = BuildStateMachine();
end);

EventManager:On("UI_ERROR_MESSAGE", Query.Error);
