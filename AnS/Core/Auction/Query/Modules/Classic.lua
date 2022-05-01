local Ans = select(2, ...);

local Utils = Ans.Utils;
local Config = Ans.Config;

local EventState = Ans.EventState;
local EventManager = Ans.EventManager;

local Tasker = Ans.Tasker;
local TASKER_TAG = "QUERY";

local Sources = Ans.Sources;

local Query = Ans.Auctions.Query;

local Recycler = Ans.Auctions.Recycler;
local Auction = Ans.Auctions.Auction;

local Classic = Ans.Object.Register("Classic", Query);

if (Utils.IsClassic()) then
    Query.module = Classic;
end

function Classic:Acquire(ilevel, buyout, quality, maxPercent)
    local q = Classic:New();

    q.ilevel = ilevel;
    q.buyout = buyout;
    q.quality = quality;
    q.percent = maxPercent;
    q.ops = Query.ops;
    q.state = nil;
    q.page = 0;

    q:Defaults();

    return q;
end

function Classic:SetOptions(ilevel, buyout, quality, maxPercent)
    self.ilevel = ilevel;
    self.buyout = buyout;
    self.quality = quality;
    self.percent = maxPercent;

    self.ops = Query.ops;

    self:Defaults();
end

function Classic:Defaults() 
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

function Classic:IsValid(auction, ignorePercent)
    local ilevel = self.ilevel;
    local buyout = self.buyout;
    local percent = self.percent;
    local quality = self.quality;

    local baseValid = Query.IsValid(auction, ignorePercent, ilevel, buyout, percent);
    if (not baseValid) then
        return false;
    end

    local q = quality[1] or 0;
    if (auction.quality <= q and q > 0) then
        return false;
    end

    return true;
end

function Classic:IsValidAuction(auction)
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

function Classic:IsValidGroup(auction)
    return nil;
end

function Classic:IsReady()
    return CanSendAuctionQuery();
end

function Classic:Next(auction, index)
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
    auction.hasAll = GetAuctionItemInfo("list", index);
    auction.link = GetAuctionItemLink("list", index);
    auction.time = GetAuctionItemTimeLeft("list", index);
    auction.sniped = false;
    auction.percent = 1000;
    auction.isPet = false;
    auction.isCommodity = false;
    auction.iLevel = 0;
    auction.vendorsell = 0;
    auction.itemIndex = index;
    auction.isOwnerItem = auction.owner == UnitName("player");

    if (not auction.link or not auction.hasAll) then
        Recycler:Recycle(auction);
        return nil, true;
    end

    if (not auction.buyoutPrice or auction.buyoutPrice <= 0 or auction.saleStatus ~= 0) then
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

function Classic:NextOwned(auction, index)
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
    auction.hasAll = GetAuctionItemInfo("owner", index);
    auction.link = GetAuctionItemLink("owner", index);
    auction.time = GetAuctionItemTimeLeft("owner", index);
    auction.isPet = false;
    auction.isCommodity = false;
    auction.iLevel = 0;
    auction.vendorsell = 0;
    auction.itemIndex = index;
    auction.isOwnerItem = true;

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

function Classic:Owned()
    local count, total = GetNumAuctionItems("owner");
    local i;

    local auction = Recycler:Get();
    for i = 1, count do
        auction = self:NextOwned(auction, i);

        if (auction) then
            EventManager:Emit("QUERY_OWNED_RESULT", auction);
        end
    end

    Tasker.Schedule(function()
        EventManager:Emit("QUERY_OWNED_COMPLETE");
    end, TASKER_TAG);
end

function Classic:ProcessAuctions(state, filter, autoPage)
    local this = self;
    local count, total = GetNumAuctionItems("list");
    local last = math.max(math.ceil(total / NUM_AUCTION_ITEMS_PER_PAGE) - 1, 0);
    local i;

    if (last ~= self.page and autoPage) then
        self.page = last;
        Tasker.Schedule(function()
            EventManager:Emit("QUERY_SEARCH_COMPLETE");
        end, TASKER_TAG);
        return;
    end

    local auction = Recycler:Get();
    for i = 1, count do
        if (state.released) then
            return;
        end

        auction = self:Next(auction, i);

        if (auction) then
            EventManager:Emit("QUERY_SEARCH_RESULT", auction);
        end
    end

    Tasker.Schedule(function()
        EventManager:Emit("QUERY_SEARCH_COMPLETE");
    end, TASKER_TAG);
end

function Classic:Search(filter, autoPage)
    local this = self;
    local fn = self.searchFn or {};
    wipe(fn);
    fn.event = function(self, state, name, ...)
        if (not self.requested) then
            return false;
        end
        
        this:ProcessAuctions(state, filter, autoPage);
        return true;
    end
    fn.process = function(self, state)
        local ready = this:IsReady();
        if (not ready) then
            return true;
        end

        self.requested = true;
        local nameFilter = Query.Truncate(filter.searchString or "");
        QueryAuctionItems(nameFilter, 
                            filter.minLevel, filter.maxLevel,
                            this.page, false, filter.quality, 
                            false, false);

        return false;
    end
    fn.result = function(self, state)
        return nil;
    end
    self.searchFn = fn;
    self.state = EventState:Acquire(fn, "AUCTION_ITEM_LIST_UPDATE");
end

function Classic:All()
    local ready, allReady = self:IsReady();
    if (not allReady) then
        return false;
    end

    QueryAuctionItems(nil,nil,nil,0,false,1,true);
    return true;
end

function Classic:AllCount()
    local c, t = GetNumAuctionItems("list");
    return t;
end

function Classic:IsActive()
    local state = self.state;
    return state ~= nil and (not state.complete or state.processing);
end

function Classic:Interrupt()
    Tasker.Clear(TASKER_TAG);

    local state = self.state;
    if (not state) then
        return;
    end

    state:Release();
    self.state = nil;
end

function Classic:Process()
    local state = self.state;
    if (not state) then
        return;
    end

    state:Process();
    if (state.complete and not state.processing) then
        self.state = nil;
    end
end

-- return values: success, wait, bidPlaced
function Classic:PurchaseItem(auction)
    if (not self:IsReady()) then
        return false, true, false;
    end

    if (not auction or auction.sniped) then
        print("Ans - auction is already sniped??");
        return true, false, false;
    end

    local index = auction.itemIndex;
    if (not index 
        or not auction.name 
        or not auction.link
        or not auction.buyoutPrice
        or not auction.count) then
            print("Ans - auction block is invalid for some reason");
            print("Ans - auction debug: "..index.. " | "..auction.name.." | "..auction.buyoutPrice.." | "..auction.count.." | "..auction.link);
            return true, false, false;
    end

    local link = GetAuctionItemLink("list", index);
    local _,_, count,_,_,_,_,_,_,buyoutPrice, _,_, _, _,
    _, _, _, hasAllInfo = GetAuctionItemInfo("list", index);


    if (not link or not hasAllInfo) then
        print("Ans - auction does not have all info yet");
        return false, true, false;
    end

    if (link and auction.link ~= link) then
        print("Ans - auction does not match link");
        return true, false, false;
    end

    if (count ~= auction.count or not buyoutPrice
        or buyoutPrice > auction.buyoutPrice) then
        print("Ans - price or count does not match");
        return true, false, false;
    end

    if (GetMoney() < buyoutPrice) then
        print("Ans - Not enough gold to buy");
        return false, false, false;
    end

    PlaceAuctionBid("list", index, buyoutPrice);
    auction.sniped = true;
    return true, false, true;
end

function Classic:PostAuction(v, duration, bidPercent)
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

    local ppu = v.ppu;
    local ppuBid = v.ppu * bidPercent;
    local total = v.count;

    UseContainerItem(v.bag, v.slot);
    PostAuction(total * ppuBid, total * ppu, duration, total, 1);

    return true, false;
end

function Classic:CancelAuction(hash)
    if (not self:IsReady()) then
        return false, true;
    end

    local num = GetNumAuctionItems("owner");
    local a = Recycler:Get();
    local canceled = false;
    for i = 1, num do
        a = self:NextOwned(a, i);
        if (a and a.hash == hash) then
            if (CanCancelAuction(i)) then
                CancelAuction(i);
                canceled = true;
            end      
            break;
        end
    end
    if (a) then
        Recycler:Recycle(a);
    end
    return canceled, false;
end