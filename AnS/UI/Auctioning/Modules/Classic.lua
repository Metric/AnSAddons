local Ans = select(2, ...);
local Config = Ans.Config;
local Utils = Ans.Utils;
local Groups = Utils.Groups;
local Query = Ans.Auctions.Query;

local Tasker = Ans.Tasker;
local TASKER_TAG = "POSTING";
local Logger = Ans.Logger;

local EventManager = Ans.EventManager;
local Recycler = Ans.Auctions.Recycler;
local EventState = Ans.EventState;
local PostingView = Ans.UI.AuctionPostingView;
local Classic = Ans.Object.Register("Classic", PostingView);

local postQueue = PostingView.postQueue;
local cancelQueue = PostingView.cancelQueue;
local ops = PostingView.ops;
local bestPrices = PostingView.bestPrices;
local inventory = PostingView.inventory;

local DEFAULT_BROWSE_QUERY = {};
DEFAULT_BROWSE_QUERY.searchString = "";
DEFAULT_BROWSE_QUERY.minLevel = 0; -- zero = any
DEFAULT_BROWSE_QUERY.maxLevel = 0; -- zero = any
DEFAULT_BROWSE_QUERY.filters = {};
DEFAULT_BROWSE_QUERY.itemClassFilters = {};
DEFAULT_BROWSE_QUERY.sorts = {};
DEFAULT_BROWSE_QUERY.quality = 1;

local query = Query:Acquire(0,0,{0},0);

if (Utils.IsClassicEra()) then
    PostingView.module = Classic;
end

function Classic:CanPost(v)
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

    return true;
end

function Classic:Post(v)
    local op = v.op;
    local bid = op.bidPercent;
    local total = v.count;

    local success, wait = query:PostAuction(v, op.duration, bid);
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

function Classic:CanCancel(v)
    local hash = v.hash;
    local num = GetNumAuctionItems("owner");
    local a = Recycler:Get();
    local canceled = false;
    for i = 1, num do
        a = query:NextOwned(a, i);
        if (a and a.hash == hash) then
            if (CanCancelAuction(i)) then
                canceled = true;
            end      
            break;
        end
    end
    if (not canceled) then
        print("AnS - Cannot cancel auction "..v.link.." x "..v.count.." - skipping");
        tremove(cancelQueue, 1);
    end
    if (a) then
        Recycler:Recycle(a);
    end
    return canceled;
end

function Classic:Cancel(v)
    local success, wait = query:CancelAuction(v.hash);
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

function Classic:Interrupt()
    Tasker.Clear(TASKER_TAG);

    query:Interrupt();

    local state = self.state;
    if (not state) then
        return;
    end

    state:Release();
    self.state = nil;
end

function Classic:PostNext()
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

function Classic:CancelNext()
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

function Classic:PriceScan(isCancel)
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
    
    DEFAULT_BROWSE_QUERY.searchString = Query.Truncate(item.name);
    DEFAULT_BROWSE_QUERY.quality = 0;
    query.page = 0;

    query:Search(DEFAULT_BROWSE_QUERY);
    return true;
end

function Classic:CancelScan()
    PostingView.Wipe();
    PostingView.GetOps();

    local this = self;
    local fn = self.cancelScanFn or {};
    wipe(fn);
    fn.event = function(self, state, name, ...)
        if (name == "QUERY_OWNED_RESULT") then
            local v = ...;
            if (not v) then
                return false;
            end

            for k, op in ipairs(ops) do
                if (op:ContainsItem(v)) then
                    local clone = v:Clone();

                    clone.ownedPPU = clone.ppu;
                    bestPrices[op:GetReferenceID(v)] = v.ppu;
                    clone.op = op;

                    tinsert(inventory, clone);
                    return false;
                end
            end

            return false;
        elseif (name == "QUERY_OWNED_COMPLETE") then
            if (#inventory == 0) then
                EventManager:Emit("POSTING_COMPLETE", true);
                return true;
            end

            EventManager:Emit("POSTING_PRICE_SCAN", true, true);
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

function Classic:PostScan()
    PostingView.Wipe();
    PostingView.GetInventory();

    if (#inventory == 0) then
        EventManager:Emit("POSTING_COMPLETE", false);
        return;
    end

    EventManager:Emit("POSTING_PRICE_SCAN", false, true);
end

function Classic:TrackInventory(item)
    tinsert(inventory, item);
end

function Classic:IsActive()
    local activeQuery = query:IsActive();
    if (activeQuery) then
        return true;
    end

    local state = self.state;
    return state ~= nil and (not state.complete or state.processing);
end

function Classic:Process()
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