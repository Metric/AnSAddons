local Ans = select(2, ...);
local Config = Ans.Config;
local Utils = Ans.Utils;
local Groups = Utils.Groups;
local Query = Ans.Auctions.Query;
local Recycler = Ans.Auctions.Recycler;
local EventState = Ans.EventState;
local EventManager = Ans.EventManager;
local PostingView = Ans.UI.AuctionPostingView;
local Logger = Ans.Logger;
local Tasker = Ans.Tasker;

local TASKER_TAG = "POSTING";

local Retail = Ans.Object.Register("Retail", PostingView);

local postQueue = PostingView.postQueue;
local cancelQueue = PostingView.cancelQueue;
local ops = PostingView.ops;
local bestPrices = PostingView.bestPrices;
local inventory = PostingView.inventory;
local ownedIds = PostingView.ownedIds;

local query = Query:Acquire(0,0,{0},0);

if (not Utils.IsClassic()) then
    PostingView.module = Retail;
end

function Retail:CanPost(v)
    local total = v.toSell;
    local op = v.op;

    if (not v:Exists()) then
        tremove(postQueue, 1);
        print("AnS - "..v.link.." no longer exists in the specified bag slot");
        return false;
    end

    if (v:IsLocked()) then
        tremove(postQueue, 1);
        print("AnS - "..v.link.." is currently locked - skipping");
        return false;
    end

    if (not v:IsFullDurability()) then
        tremove(postQueue, 1);
        print("AnS - "..v.link.." is not full durability - skipping");
        return false;
    end

    local location = ItemLocation:CreateFromBagAndSlot(v.bag, v.slot);
    if (total > 0) then
        local type = C_AuctionHouse.GetItemCommodityStatus(location);
        if (type == 2) then
            return true;
        elseif (type == 1) then
            return true;
        end
    else
        tremove(postQueue, 1);
    end

    return false;
end

function Retail:Post(v)
    local total = v.toSell;
    local op = v.op;

    local success, wait = query:PostAuction(v, op.duration);
    if (wait) then
        return;
    end

    if (success) then
        print("AnS - Posting auction "..v.link.. " x "..total.." for "..Utils.PriceToString(v.ppu).."|cFFFFFFFF per unit");
    else
        print("Ans - Failed to post "..v.link);
    end

    tremove(postQueue, 1);
    return;
end

function Retail:CanCancel(v)
    if (C_AuctionHouse.CanCancelAuction(v.auctionId)) then
        return true;
    end

    print("AnS - Cannot cancel auction "..v.link.." x "..v.count.." - skipping");
    tremove(cancelQueue, 1);
    return false;
end

function Retail:Cancel(v)
    local success, wait = query:CancelAuction(v.auctionId);
    if (wait) then
        return;
    end

    if (success) then
        print("AnS - Trying to cancel "..v.link.." x "..v.count);
    else
        print("AnS - Cannot cancel auction "..v.link.." x "..v.count.." - skipping");
    end

    tremove(cancelQueue, 1);
    return;
end

function Retail:PostNext()
    local item = postQueue[1];

    if (not item) then
        return false;
    end

    if (not self:CanPost(item)) then
        return postQueue[1];
    end

    self:Post(item);
    return postQueue[1];
end

function Retail:CancelNext()
    local item = cancelQueue[1];
        
    if (not item) then
        return false;
    end

    if (not self:CanCancel(item)) then
        return cancelQueue[1];
    end

    self:Cancel(item);
    return cancelQueue[1];
end

function Retail:PriceScan(isCancel) 
    local item = inventory[1];

    if (not item) then
        return false;
    end

    local this = self;
    local fn = self.priceScanFn or {};
    wipe(fn);
    fn.event = function(self, state, name, v)
        if (name == "QUERY_SEARCH_RESULT") then
            if (not v) then
                return false;
            end

            PostingView.TrackItem(v, item, isCancel);
        
            return false;
        elseif (name == "QUERY_SEARCH_COMPLETE") then
            Logger.Log("POSTING", "Search Complete");

            PostingView.ValidateItem(item, isCancel);      
            tremove(inventory, 1);

            Tasker.Schedule(function()
                EventManager:Emit("POSTING_PRICE_SCAN", isCancel);
            end, TASKER_TAG);

            return true;
        end

        return false;
    end
    fn.process = function(self, state)
        return false;
    end
    fn.result = function(self, state)
        return nil;
    end
    self.priceScanFn = fn;

    self.state = EventState:Acquire(fn, "QUERY_SEARCH_COMPLETE", "QUERY_SEARCH_RESULT");
    query:Search(item:Clone(), item.isEquipment, false); 
    return true;
end

function Retail:CancelScan()
    PostingView.Wipe();
    PostingView.GetOps();

    local this = self;
    local fn = self.cancelScanFn or {};
    wipe(fn);
    fn.event = function(self, state, name, v)
        if (name == "QUERY_OWNED_RESULT") then
            if (not v) then
                return false;
            end

            ownedIds[v.auctionId] = 1;
            
            Logger.Log("POSTING", "Received Owned Item Result");

            for k, op in ipairs(ops) do
                if (op:ContainsItem(v)) then
                    local clone = v:Clone();

                    if (clone.isEquipment) then
                        clone.itemKey = AuctionHouseUtil.ConvertItemSellItemKey(v.itemKey);
                    end

                    clone.ownedPPU = v.ppu;
                    bestPrices[op:GetReferenceID(v)] = v.ppu;
                    clone.op = op;
                    tinsert(inventory, clone);
                    return false;
                end
            end

            return false;
        elseif (name == "QUERY_OWNED_COMPLETE") then
            Logger.Log("POSTING", "Owned Results Complete");

            if (#inventory == 0) then
                Tasker.Schedule(function()
                    EventManager:Emit("POSTING_COMPLETE", true);
                end, TASKER_TAG);
                
                return true;
            end

            Tasker.Schedule(function()
                EventManager:Emit("POSTING_PRICE_SCAN", true, true);
            end, TASKER_TAG);
         
            return true;
        end

        return false;
    end
    fn.process = function(self, state)
        return false;
    end
    fn.result = function(self, state)
        return nil;
    end
    self.cancelScanFn = fn;
    self.state = EventState:Acquire(fn, "QUERY_OWNED_COMPLETE", "QUERY_OWNED_RESULT");
    query:Owned();
end

function Retail:PostScan()
    PostingView.Wipe();
    PostingView.GetInventory();

    if (#inventory == 0) then
        EventManager:Emit("POSTING_COMPLETE", false);
        return;
    end

    EventManager:Emit("POSTING_PRICE_SCAN", false, true);
end

function Retail:TrackInventory(item)
    local location = ItemLocation:CreateFromBagAndSlot(item.bag, item.slot);
    item.itemKey = C_AuctionHouse.GetItemKeyFromItem(location);

    if (item.itemKey) then
        local info = C_AuctionHouse.GetItemKeyInfo(item.itemKey);

        item.isEquipment = info.isEquipment;
        item.isCommodity = info.isCommodity;
        if (item.isEquipment) then
            item.itemKey = AuctionHouseUtil.ConvertItemSellItemKey(item.itemKey);
        end

        tinsert(inventory, item);
    end
end

function Retail:Interrupt()
    Tasker.Clear(TASKER_TAG);

    query:Interrupt();

    local state = self.state;
    if (not state) then
        return;
    end

    state:Release();
    self.state = nil;
end

function Retail:IsActive()
    local activeQuery = query:IsActive();
    if (activeQuery) then
        return true;
    end

    local state = self.state;
    return state ~= nil and (not state.complete or state.processing);
end

function Retail:Process()
    query:Process();

    local state = self.state;
    if (not state) then
        return;
    end

    state:Process();
    if (state.complete and not state.processing) then
        self.state = nil;
    end
end