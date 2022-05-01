local Ans = select(2, ...);

local Utils = Ans.Utils;
local Config = Ans.Config;
local Logger = Ans.Logger;

local EventState = Ans.EventState;
local EventManager = Ans.EventManager;

local Sources = Ans.Sources;

local Query = Ans.Auctions.Query;
local Tasker = Ans.Tasker;
local TASKER_TAG = "QUERY";

local Recycler = Ans.Auctions.Recycler;
local Auction = Ans.Auctions.Auction;

local Retail = Ans.Object.Register("Retail", Query);

local DEFAULT_ITEM_SORT = Query.DEFAULT_ITEM_SORT;

if (not Utils.IsClassic()) then
    Query.module = Retail;
end

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

local infoKeyCache = {};
local infoKeyWaitQueue = {}

local function OnItemKeyInfo(id)
    if (not infoKeyWaitQueue[id]) then
        return;
    end

    Logger.Log("QUERY", "item key info received for: "..id);

    local key = infoKeyWaitQueue[id];
    if (not key) then
        infoKeyWaitQueue[itemID] = nil;
        return;
    end
    
    local hash = Query.ItemKeyHash(key);
    infoKeyCache[hash] = C_AuctionHouse.GetItemKeyInfo(key);
    infoKeyWaitQueue[id] = nil;
end

function Retail:Acquire(ilevel, buyout, quality, maxPercent)
    local q = Retail:New();

    q.ilevel = ilevel;
    q.buyout = buyout;
    q.quality = quality;
    q.percent = maxPercent;
    q.ops = Query.ops;
    q.state = nil;
    q.results = {};
    q.previousState = nil;

    q:Defaults();

    return q;
end

function Retail:SetOptions(ilevel, buyout, quality, maxPercent)
    self.ilevel = ilevel;
    self.buyout = buyout;
    self.quality = quality;
    self.percent = maxPercent;

    self.ops = Query.ops;

    self:Defaults();
end

function Retail:Defaults() 
    local ilevel = self.ilevel;
    local buyout = self.buyout;
    local quality = self.quality;
    local percent = self.percent;

    local sniperConfig = Config.Sniper();

    for i,v in ipairs(self.ops) do
        if (v.inheritGlobal) then
            v.minILevel = ilevel;
            v.price = sniperConfig.pricing;
            v.maxPercent = percent;
            v.maxPPU = buyout;
            v.ignoreGroupMaxPercent = sniperConfig.ignoreGroupMaxPercent;
            v.minQuality = quality[1] or 0;
        end
    end
end

function Retail:IsValid(auction, ignorePercent)
    local ilevel = self.ilevel;
    local buyout = self.buyout;
    local percent = self.percent;
    local quality = self.quality;

    local baseValid = Query.IsValid(auction, ignorePercent, ilevel, buyout, percent);
    if (not baseValid) then
        return false;
    end

    if (#quality > 0) then
        if (not tContains(quality, auction.quality)) then
            return false;
        end
    end

    return true;
end

function Retail:IsValidAuction(auction)
    local this = self;
    local ops = self.ops;
    local valid = false;

    if (Query.IsBlacklisted(auction)) then
        return false;
    end

    if (not self.defaultFilterCallback) then
        self.defaultFilterCallback = function(a,i)
            return this:IsValid(a, i);
        end
    end

    if (auction.buyoutPrice <= 0) then
        return false;
    end

    Query.FillAverage(auction, false);

    if (#ops == 0) then
        return Query.FilterDefault(auction, false, false, self.defaultFilterCallback);
    end

    return Query.FilterOps(auction, ops, true, false);
end

function Retail:IsValidGroup(auction)
    if (not auction) then
        return false;
    end

    local this = self;
    local ops = self.ops;
    local ignoreMaxPercent = Config.Sniper().ignoreMaxPercent;

    if (auction.buyoutPrice <= 0) then
        return false;
    end

    if (not self.defaultFilterCallback) then
        self.defaultFilterCallback = function(a,i)
            return this:IsValid(a, i);
        end
    end

    Query.FillAverage(auction);

    if (#ops == 0) then
        return Query.FilterDefault(auction, ignoreMaxPercent, true, self.defaultFilterCallback);
    end

    return Query.FilterOps(auction, ops, auction.isPet, true);
end

function Retail:IsReady()
    local throttle = C_AuctionHouse.IsThrottledMessageSystemReady();
    if (not throttle) then
        return false;
    end
    return not Query:IsActive(self);
end

function Retail:GetItemKeyInfo(key)
    local hash = Query.ItemKeyHash(key);
    
    if (infoKeyCache[hash]) then
        return infoKeyCache[hash];
    end

    local info = C_AuctionHouse.GetItemKeyInfo(key);
    if not info then
        infoKeyWaitQueue[key.itemID] = key;
        return nil;
    end

    infoKeyCache[hash] = info;
    return info;
end

function Retail:NextGroup(group, info)
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

    local groupInfo = info or self:GetItemKeyInfo(group.itemKey)

    if (not groupInfo) then
        Logger.Log("QUERY", "No group info for: "..group.itemKey.itemID);
        Recycler:Recycle(auction);
        return nil;
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

function Retail:Next(auction, index)
    -- note: we expect index to be 1+
    -- but for retail GetReplicateItemInfo
    -- the indexing starts at 0 instead of 1
    index = index - 1;

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
    auction.hasAll = C_AuctionHouse.GetReplicateItemInfo(index);
    auction.link = C_AuctionHouse.GetReplicateItemLink(index);
    auction.itemIndex = index;
    auction.iLevel = 0;
    auction.vendorsell = 0;
    auction.isOwnerItem = auction.owner == UnitName("player");

    if (not auction.link or not auction.hasAll) then
        Recycler:Recycle(auction);
        return nil, true;
    end

    if (auction.buyoutPrice <= 0 or auction.saleStatus ~= 0) then
        Recycler:Recycle(auction);
        return nil, false;
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

    auction.hash = Query.ItemHash(auction);

    return auction, false;
end

function Retail:NextOwned(auction, index)
    auction = auction or Recycler:Get();

    local info = C_AuctionHouse.GetOwnedAuctionInfo(index);
    if (not info) then
        Recycler:Recycle(auction);
        return nil;
    end

    local keyInfo = self:GetItemKeyInfo(info.itemKey);
    if (not keyInfo) then
        Recycler:Recycle(auction);
        return nil;
    end

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

    auction.hash = Query.ItemHash(auction);

    return auction;
end

function Retail:ProcessCommodity(item, itemID, first)
    for searchIndex = 1, C_AuctionHouse.GetNumCommoditySearchResults(itemID) do
        local result = C_AuctionHouse.GetCommoditySearchResultInfo(itemID, searchIndex);
        item.count = result.quantity;
        item.ppu = result.unitPrice;
        item.buyoutPrice = result.unitPrice * result.quantity;
        item.owner = Query.GetOwners(result);
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

        item.hash = Query.ItemHash(item);

        EventManager:Emit("QUERY_SEARCH_RESULT", item);

        if (first) then
            break;
        end
    end
end

function Retail:ProcessItem(item, itemKey, first)
    for searchIndex = 1, C_AuctionHouse.GetNumItemSearchResults(itemKey) do
        local result = C_AuctionHouse.GetItemSearchResultInfo(itemKey, searchIndex);
        if (result.buyoutAmount) then
            item.isCommodity = false;
            item.count = result.quantity;
            item.ppu = result.buyoutAmount;
            item.buyoutPrice = result.buyoutAmount;
            item.owner = Query.GetOwners(result);
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

            item.hash = Query.ItemHash(item);

            EventManager:Emit("QUERY_SEARCH_RESULT", item);

            if (first) then
                break;
            end
        end
    end
end

function Retail:Browse(filter, groupFilter)
    local this = self;
    local fn = self.browseFn or {};
    wipe(fn);
    fn.event = function(self, state, name)
        if (not self.requested) then
            return false;
        end

        self.eventReceived = true;

        if (not C_AuctionHouse.HasFullBrowseResults()) then
            return false;
        end

        return true;
    end
    fn.process = function(self, state)
        if (not this:IsReady()) then
            return true;
        end

        if (self.requested and self.eventReceived and not self.full) then
            self.eventReceived = false;

            if (not C_AuctionHouse.HasFullBrowseResults()) then
                C_AuctionHouse.RequestMoreBrowseResults();
                return true;
            end

            self.full = C_AuctionHouse.GetBrowseResults();
            Logger.Log("QUERY", "Total Browse Groups: "..#self.full);
        end

        if (self.requested and self.full) then  
            local results = self.full;
            local offset = self.iIndex;
            local count = #results;
            local i = 0;
            local perFrame = Config.Sniper().itemsPerUpdate;

            while (offset <= count and i < perFrame) do
                local group = results[offset];

                EventManager:Emit("QUERY_BROWSE_UPDATE", offset, count)

                if (group and groupFilter) then
                    local auction = groupFilter(group);
                    if (auction) then
                        tinsert(this.results, auction);
                    end
                end

                i = i + 1;
                offset = offset + 1;
            end

            self.iIndex = offset;

            if (offset <= count) then
                return true;
            end

            Logger.Log("QUERY", "Total Valid Browse Groups: "..#this.results);
            Tasker.Schedule(function()
                EventManager:Emit("QUERY_BROWSE_COMPLETE");
            end, TASKER_TAG);

            wipe(self.full);
            return false;
        elseif (self.requested and not self.full) then
            return true;
        end

        self.eventReceived = false;
        self.full = false;
        self.requested = true;
        self.iIndex = 1;
        C_AuctionHouse.SendBrowseQuery(filter);
        return true;
    end
    fn.result = function(self, state)
        return nil;
    end
    self.browseFn = fn;

    wipe(self.results);

    self.state = EventState:Acquire(fn, "AUCTION_HOUSE_BROWSE_RESULTS_UPDATED", "AUCTION_HOUSE_BROWSE_RESULTS_ADDED");
end

function Retail:All()
    if (not self:IsReady()) then
        return false;
    end

    C_AuctionHouse.ReplicateItems();
    return true;
end

function Retail:AllCount()
    -- note: GetNumReplicateItems we need to -1
    -- so we can do proper loop for 0, num do
    -- since ReplicatItems index is zero based
    return C_AuctionHouse.GetNumReplicateItems() - 1;
end

function Retail:Search(item, sell, first)
    local this = self;
    local fn = self.searchFn or {};
    wipe(fn);
    fn.event = function(self, state, name, itemKey)
        if (not self.requested) then
            return false;
        end

        self.eventReceived = true;
        if (item.isCommodity) then
            if (not C_AuctionHouse.HasFullCommoditySearchResults(item.id)) then
                return false;
            end
        else
            if (not C_AuctionHouse.HasFullItemSearchResults(item.itemKey)) then
                return false;
            end
        end

        Logger.Log("QUERY", "Search Event Done");
        return true;
    end
    fn.process = function(self, state)
        if (not item or not item.itemKey) then
            return false;
        end

        if (not this:IsReady()) then
            return true;
        end

        if (self.requested and self.eventReceived and not self.full) then
            self.eventReceived = false;

            if (item.isCommodity) then
                if (not C_AuctionHouse.HasFullCommoditySearchResults(item.id)) then
                    C_AuctionHouse.RequestMoreCommoditySearchResults(item.id);
                    return true;
                end
            else
                if (not C_AuctionHouse.HasFullItemSearchResults(item.itemKey)) then
                    C_AuctionHouse.RequestMoreItemSearchResults(item.itemKey);
                    return true;
                end
            end

            Timestamp(true, "Search Query");
            self.full = true;
        end

        if (self.requested and self.full) then
            Logger.Log("QUERY", "Processing Item");
            Timestamp();
            if (item.isCommodity) then
                Logger.Log("QUERY", "Total Search Commodities: "..C_AuctionHouse.GetNumCommoditySearchResults(item.id));
                this:ProcessCommodity(item, item.id, first);
            else
                Logger.Log("QUERY", "Total Search Items: "..C_AuctionHouse.GetNumItemSearchResults(item.itemKey));
                this:ProcessItem(item, item.itemKey, first);
            end
            Timestamp(true, "Search Process");
            Tasker.Schedule(function()
                EventManager:Emit("QUERY_SEARCH_COMPLETE");
            end, TASKER_TAG);

            return false;
        elseif (self.requested and not self.full) then
            return true;
        end

        local info = this:GetItemKeyInfo(item.itemKey);
        if (not info) then
            Logger.Log("QUERY", "Search: Waiting for ItemKeyInfo");
            return true;
        end

        Logger.Log("QUERY", "Sending search query");
        item.isCommodity = info.isCommodity;

        Timestamp();
        if (sell) then
            C_AuctionHouse.SendSellSearchQuery(item.itemKey, DEFAULT_ITEM_SORT, true);
        else
            C_AuctionHouse.SendSearchQuery(item.itemKey, DEFAULT_ITEM_SORT, true);
        end

        self.full = false;
        self.eventReceived = false;
        self.requested = true;
        return true;
    end
    fn.result = function(self, state)
        return nil;
    end
    self.searchFn = fn;
    self.state = EventState:Acquire(fn, "ITEM_SEARCH_RESULTS_UPDATED", "ITEM_SEARCH_RESULTS_ADDED", "COMMODITY_SEARCH_RESULTS_UPDATED", "COMMODITY_SEARCH_RESULTS_ADDED")
end

function Retail:Owned()
    local this = self;
    local fn = self.ownedFn or {};
    wipe(fn);
    fn.event = function(self, state, name, ...)
        if (not self.requested) then
            return false;
        end

        local count = C_AuctionHouse.GetNumOwnedAuctions();
        local i;
    
        local auction = Recycler:Get();
        for i = 1, count do
            if (state.released) then
                return;
            end
    
            auction = this:NextOwned(auction, i);
    
            if (auction) then
                EventManager:Emit("QUERY_OWNED_RESULT", auction);
            end
        end
    
        Tasker.Schedule(function()
            EventManager:Emit("QUERY_OWNED_COMPLETE");
        end, TASKER_TAG);

        return true;
    end
    fn.process = function(self, state)
        if (not this:IsReady()) then
            return true;
        end

        self.requested = true;
        C_AuctionHouse.QueryOwnedAuctions(DEFAULT_ITEM_SORT);
        return false;
    end
    fn.result = function(self, state)
        return nil;
    end
    self.ownedFn = fn;

    self.state = EventState:Acquire(fn, "OWNED_AUCTIONS_UPDATED");
end

function Retail:IsActive()
    local state = self.state;
    return state ~= nil and (not state.complete or state.processing);
end

function Retail:Interrupt()
    Tasker.Clear(TASKER_TAG);

    local state = self.state;
    if (not state) then
        return;
    end

    state:Release();
    self.state = nil;
end

function Retail:Process()
    local state = self.state;
    if (not state) then
        return;
    end

    state:Process();
    if (state.complete and not state.processing) then
        self.state = nil;
    end
end

function Retail:PurchaseCommodity(auction, total)
    if (not auction.isCommodity) then
        return;
    end

    local STATE_NAME = "ST_P_COMMODITY";
    local this = self;
    local ppu = auction.ppu;
    local id = auction.id;

    if (self.state 
        and self.state:Result() ~= nil
        and self.state:GetVar("name") == STATE_NAME) then

        return;
    else
        self:Interrupt();
    end

    local fn = self.purchaseCommodityFn or {};
    wipe(fn);
    fn.name = STATE_NAME;
    fn.event = function(self, state, name, unit, t)
        if (name == "COMMODITY_PURCHASE_FAILED"
            or name == "COMMODITY_PURCHASED"
            or name == "COMMODITY_PURCHASE_SUCCEEDED") then

            EventManager:Emit("PURCHASE_COMPLETE", true, self.auction, self.total);
            EventManager:Emit("QUERY_PREVIOUS_COMPLETED");
            return true;
        elseif (name == "COMMODITY_PRICE_UPDATED") then 
            if (unit > self.ppu or t <= 0) then
                C_AuctionHouse.CancelCommoditiesPurchase();
                EventManager:Emit("PURCHASE_COMPLETE", true, self.auction, self.total);
                EventManager:Emit("QUERY_PREVIOUS_COMPLETED");
                return true;
            end

            C_AuctionHouse.ConfirmCommoditiesPurchase(self.auction.id, self.total);
            return false;
        elseif (name == "COMMODITY_PRICE_UNAVAILABLE") then
   
            C_AuctionHouse.CancelCommoditiesPurchase();
            EventManager:Emit("PURCHASE_COMPLETE", false, self.auction, self.total);
            EventManager:Emit("QUERY_PREVIOUS_COMPLETED");
            return true;
        end

        return false;
    end
    fn.process = function(self, state)
        return false;
    end
    fn.ppu = ppu;
    fn.auction = auction;
    fn.total = total;
    fn.result = function(self, state)
        return self.auction;
    end
    self.purchaseCommodityFn = fn;

    self.state = EventState:Acquire(fn, "COMMODITY_PURCHASE_FAILED", 
                                        "COMMODITY_PURCHASED", "COMMODITY_PURCHASE_SUCCEEDED",
                                        "COMMODITY_PRICE_UPDATED", "COMMODITY_PRICE_UNAVAILABLE");

    print("Ans - trying to buy: "..auction.link.." x "..total.." for "..Utils.PriceToString(ppu));
    EventManager:Emit("PURCHASE_START", auction);
    C_AuctionHouse.StartCommoditiesPurchase(id, total, ppu);
end

function Retail:PurchaseItem(auction)
    if (auction.isCommodity) then
        return;
    end

    local this = self;
    local id = auction.auctionId;
    local price = auction.buyoutPrice;

    if (self.state and self.state:Result() ~= nil) then
        local auc, result, sent = self.state:Result();

        if (sent) then
            return;
        end

        if (not result) then
            return;
        end

        if (not self:IsReady()) then
            return;
        end

        if (auc.auctionId == id) then
            self.state:SetVar("sent", true);
            EventManager:Emit("PURCHASE_START", auction);

            if (not C_AuctionHouse.GetAuctionInfoByID(auction.auctionId)) then
                -- auction not available
                -- do not even bother trying
                EventManager:Emit("PURCHASE_MODAL_MSG", "Auction no longer exists - skipping purchase");
                print("Ans - auction no longer exists - skipping purchase");
                EventManager:Emit("PURCHASE_COMPLETE", true, auction);
                EventManager:Emit("QUERY_PREVIOUS_COMPLETED");
                self:Interrupt();
                return;
            end

            print("Ans - trying to buy: "..auction.link.." for "..Utils.PriceToString(price));
            C_AuctionHouse.PlaceBid(id, price);
            return;
        else
            self:Interrupt();
        end
    else
        self:Interrupt();
    end

    local hasResults = C_AuctionHouse.HasFullItemSearchResults(auction.itemKey);

    -- note: cache these objects for the temporary
    -- fn states
    local fn = self.purchaseItemFn or {};
    wipe(fn);
    fn.event = function(self, state, name, notif, format)
        if (not self.sent) then
            return false;
        end

        Logger.Log("SNIPER", "Purchase Event: "..name);
        Logger.Log("SNIPER", "Purchase Enum: "..notif);

        if (name == "AUCTION_HOUSE_SHOW_NOTIFICATION"
            or name == "AUCTION_HOUSE_SHOW_FORMATTED_NOTIFICATION") then

            local removal = false;
            if (notif == Enum.AuctionHouseNotification.AuctionWon) then
                Logger.Log("SNIPER", "Item Purchased Event");
                EventManager:Emit("PURCHASE_COMPLETE", true, self.auction);
            elseif (notif == Enum.AuctionHouseNotification.AuctionRemoved) then
                Logger.Log("SNIPER", "Item Removed Event");
                EventManager:Emit("PURCHASE_COMPLETE", true, self.auction);
            end

            EventManager:Emit("QUERY_PREVIOUS_COMPLETED");
            return true;
        elseif (name == "AUCTION_HOUSE_SHOW_ERROR") then
            if (notif == Enum.AuctionHouseError.ItemNotFound
                or notif == Enum.AuctionHouseError.Unavailable
                or notif == Enum.AuctionHouseError.NotEnoughItems
                or notif == Enum.AuctionHouseError.DatabaseError
                or notif == Enum.AuctionHouseError.ItemHasQuote
                or notif == Enum.AuctionHouseError.HasRestriction
                or notif == Enum.AuctionHouseError.IsBusy) then
                Logger.Log("SNIPER", "Item Not Found Event");
                EventManager:Emit("PURCHASE_COMPLETE", true, self.auction);
            else
                Logger.Log("SNIPER", "Auction Error Event: "..notif);
                EventManager:Emit("PURCHASE_COMPLETE", false, self.auction);
            end   

            EventManager:Emit("QUERY_PREVIOUS_COMPLETED");
            return true;
        end

        return false;
    end
    fn.process = function(self, state)
        local auc = self.auction;
        if (not this:IsReady()) then
            return true;
        end

        self.hasResults = C_AuctionHouse.HasFullItemSearchResults(auc.itemKey);

        if (self.hasResults) then
            return false;
        end

        if (not self.requested) then
            self.requested = true;
            C_AuctionHouse.SendSearchQuery(auc.itemKey, DEFAULT_ITEM_SORT, true);
            return true;
        else
            C_AuctionHouse.RequestMoreItemSearchResults(auc.itemKey);
            return true;
        end

        return true;
    end
    
    fn.hasResults = hasResults;
    fn.auction = auction;
    fn.sent = false;

    fn.result = function(self, state)
        return self.auction, self.hasResults, self.sent;
    end
    
    self.purchaseItemFn = fn;
    self.state = EventState:Acquire(fn, "AUCTION_HOUSE_SHOW_NOTIFICATION", 
                                        "AUCTION_HOUSE_SHOW_FORMATTED_NOTIFICATION",
                                        "AUCTION_HOUSE_SHOW_ERROR");
    
    if (hasResults and self:IsReady()) then
        self.state:SetVar("sent", true);
        EventManager:Emit("PURCHASE_START", auction);
        
        if (not C_AuctionHouse.GetAuctionInfoByID(auction.auctionId)) then
            -- auction not available
            -- do not even bother trying
            print("Ans - auction no longer exists - skipping purchase");
            EventManager:Emit("PURCHASE_COMPLETE", true, auction);
            EventManager:Emit("QUERY_PREVIOUS_COMPLETED");
            self:Interrupt();
            return;
        end

        print("Ans - trying to buy: "..auction.link.." for "..Utils.PriceToString(price));

        C_AuctionHouse.PlaceBid(id, price);  
        return;
    else
        EventManager:Emit("PURCHASE_MODAL_MSG", "Pausing and Looking up item. Please try again in a second.");    
        print("Ans - Pausing and Looking up item. Please try again in a second.");
    end
end

function Retail:PostAuction(v, duration)
    if (not self:IsReady()) then
        return false, true;
    end

    if (not v) then
        return false, false;
    end

    if (not v:Exists()) then
        return false, false;
    elseif (v:IsLocked()) then
        return false, false;
    elseif (not v:IsFullDurability()) then
        return false, false;
    end

    local quantity = v.toSell;
    local location = ItemLocation:CreateFromBagAndSlot(v.bag, v.slot);
    local t =  C_AuctionHouse.GetItemCommodityStatus(location);
    if (t ~= 1 and t ~= 2) then
        return false, false;
    end

    if (t == 2) then
        C_AuctionHouse.PostCommodity(location, duration, quantity, v.ppu);
    else
        C_AuctionHouse.PostItem(location, duration, quantity, nil, v.ppu);
    end

    return true, false;
end

function Retail:CancelAuction(id)
    if (not self:IsReady()) then
        return false, true;
    end

    if (not C_AuctionHouse.CanCancelAuction(id)) then
        return false, false;
    end

    C_AuctionHouse.CancelAuction(id);
    return true, false;
end

-- schedule ItemKeyInfoReceived Handler
EventManager:On("ITEM_KEY_ITEM_INFO_RECEIVED", OnItemKeyInfo);