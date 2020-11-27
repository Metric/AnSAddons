local Ans = select(2, ...);
local Config = Ans.Config;
local Utils = Ans.Utils;
local Query = Ans.Auctions.Query;
local Recycler = Ans.Auctions.Recycler;
local EventManager = Ans.EventManager;
local BagScanner = Ans.BagScanner;
local FSM = Ans.FSM;
local FSMState = Ans.FSMState;
local Tasker = Ans.Tasker;
local TASKER_TAG = "POSTING";

local AuctionOp = Ans.Operations.Auctioning;

local TreeView = Ans.UI.TreeView;

local PostingView = {};
PostingView.__index = PostingView;
PostingView.inited = false;

local PostingFSM = nil;

-- used only for classic
local DEFAULT_BROWSE_QUERY = {};
DEFAULT_BROWSE_QUERY.searchString = "";
DEFAULT_BROWSE_QUERY.minLevel = 0; -- zero = any
DEFAULT_BROWSE_QUERY.maxLevel = 0; -- zero = any
DEFAULT_BROWSE_QUERY.filters = {};
DEFAULT_BROWSE_QUERY.itemClassFilters = {};
DEFAULT_BROWSE_QUERY.sorts = {};
DEFAULT_BROWSE_QUERY.quality = 1;

local STATES = {};
STATES.NONE = 0;
STATES.SCANNING = 1;
STATES.READY = 3;
STATES.OWNED = 4;
STATES.POST = 1;
STATES.CANCEL = 2;

PostingView.state = STATES.NONE;
PostingView.type = STATES.POST;

Ans.Auctions.PostingView = PostingView;

local activeOps = {};
local ops = {};
local treeViewItems = {};
local inventory = {};
local bestPrices = {};
local postQueue = {};
local cancelQueue = {};
local searchesComplete = 0;

local ERRORS = {
    ERR_ITEM_NOT_FOUND,
    ERR_AUCTION_DATABASE_ERROR,
    ERR_AUCTION_REPAIR_ITEM,
    ERR_AUCTION_LIMITED_DURATION_ITEM,
    ERR_AUCTION_USED_CHARGES,
    ERR_AUCTION_WRAPPED_ITEM,
    ERR_AUCTION_BAG,
    ERR_NOT_ENOUGH_MONEY
};

local function BuildStateMachine()
    local fsm = FSM:New("PostingFSM");

    local none = FSMState:New("NONE");
    none:AddEvent("IDLE");
    fsm:Add(none);

    local idle = FSMState:New("IDLE");
    idle:SetOnEnter(function(self)
        PostingView.post:SetText("Post Scan");
        PostingView.post:Enable();
        PostingView.cancel:Enable();
        PostingView.cancel:SetText("Cancel Scan");

        wipe(ops);
        wipe(bestPrices);
        wipe(inventory);
        wipe(cancelQueue);
        wipe(postQueue);

        Query.Clear();

        return nil;
    end);
    --idle:AddEvent("CANCEL_SCAN");
    idle:AddEvent("POST_SCAN");
    idle:AddEvent("CANCEL_SCAN");

    fsm:Add(idle);

    -- POSTING STATES
    local postScan = FSMState:New("POST_SCAN");
    postScan:SetOnEnter(function(self)
        wipe(postQueue);
        wipe(ops);
        wipe(inventory);
        wipe(bestPrices);

        Query.Clear();

        searchesComplete = 0;

        for k,v in pairs(activeOps) do
            local op = AuctionOp:FromConfig(v);
            tinsert(ops, op);
            local items = op:GetAvailableItems();
    
            for i, item in ipairs(items) do
                if (not Utils:IsClassic()) then
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
                else
                    tinsert(inventory, item);
                end
            end
        end

        if(Utils:IsClassic()) then
            return "CLASSIC_POST_SCAN";
        else
            return "RETAIL_POST_SCAN";
        end
    end);

    postScan:AddEvent("CLASSIC_POST_SCAN");
    postScan:AddEvent("RETAIL_POST_SCAN");

    fsm:Add(postScan);

    local classicPostScan = FSMState:New("CLASSIC_POST_SCAN");
    classicPostScan:SetOnEnter(function(self)
        if (#inventory == 0) then
            print("AnS - Nothing to Post");
            return "IDLE";
        end
    
        local next = inventory[1];
        DEFAULT_BROWSE_QUERY.searchString = next.name;
        DEFAULT_BROWSE_QUERY.quality = 0;
        Query.page = 0;
    
        Query:Search(DEFAULT_BROWSE_QUERY, true)
        PostingView.post:SetText("Scanning 1 of "..#inventory);
        PostingView.post:Disable();
        PostingView.cancel:Disable();

        return "POST_ITEM_RESULTS", next;
    end);
    classicPostScan:AddEvent("IDLE");
    classicPostScan:AddEvent("POST_ITEM_RESULTS");

    fsm:Add(classicPostScan);

    local retailPostScan = FSMState:New("RETAIL_POST_SCAN");
    retailPostScan:SetOnEnter(function(self)
        if (#inventory == 0) then
            print("AnS - Nothing to Post");
            return "IDLE";
        end

        local next = inventory[1];
        Query.SearchForItem(next:Clone(), next.isEquipment)
        PostingView.post:SetText("Scanning 1 of "..#inventory);
        PostingView.post:Disable();
        PostingView.cancel:Disable();

        return "POST_ITEM_RESULTS", next;
    end);
    retailPostScan:AddEvent("IDLE");
    retailPostScan:AddEvent("POST_ITEM_RESULTS");

    fsm:Add(retailPostScan);

    local postItemResults = FSMState:New("POST_ITEM_RESULTS");
    postItemResults:SetOnEnter(function(self, item)
        self.item = item;
        return nil;
    end);
    postItemResults:AddEvent("ITEM_RESULT", function(self, event, item)
        if (item) then
            if (self.item and self.item.op) then
                self.item.op:Track(item);
            end
            
            PostingView.CalcLowest(item);
        end
    end);
    postItemResults:AddEvent("SEARCH_COMPLETE", function(self)
        searchesComplete = searchesComplete + 1;

        local v = self.item;

        local txt, undercut = Utils:MoneyStringToCopper(v.op.undercut);

        if (not undercut) then
            undercut = 0;
        end

        local ppu = bestPrices[v.tsmId] or 0;

        if (Utils:IsClassic()) then
            ppu = v.op:IsValid(ppu, v.link, false);
        else
            ppu = v.op:IsValid(ppu, v.link, v.isCommodity and v.op.commodityLow);
        end
        
        if (ppu - undercut > 0) then
            ppu = ppu - undercut;
        end

        if (ppu > 0) then
            if (Utils:IsClassic()) then
                v.ppu = ppu;
            else
                v.ppu = ppu - (ppu % COPPER_PER_SILVER);
            end

            if (v.ppu > 0) then
                v.op:ApplyPost(v, postQueue);
            end
        end

        if (searchesComplete >= #inventory) then
            if (#postQueue > 0) then
                return "POST_READY";
            else
                return "IDLE";
            end
        else
            local nextItem = inventory[searchesComplete + 1];
            self.item = nextItem;
            if (Utils:IsClassic()) then
                DEFAULT_BROWSE_QUERY.searchString = nextItem.name;
                Query.page = 0;
                Query:Search(DEFAULT_BROWSE_QUERY, true);
            else
                Query.SearchForItem(nextItem:Clone(), nextItem.isEquipment);
            end
            PostingView.post:SetText("Scanning "..(searchesComplete + 1).." of "..#inventory);
        end

        return nil;
    end);
    postItemResults:AddEvent("IDLE");
    postItemResults:AddEvent("POST_READY");

    fsm:Add(postItemResults);
    fsm:Add(FSMState:New("SEARCH_COMPLETE"));

    local postReady = FSMState:New("POST_READY");
    postReady:SetOnEnter(function(self)
        PostingView.post:Enable();
        PostingView.post:SetText("Post ("..#postQueue..")");
        return nil;
    end);
    postReady:AddEvent("POST", function(self)
        local item = postQueue[1];

        if (Utils:IsClassic()) then
            if (PostingView.CanPostItemClassic(item)) then
                return "POST_CONFIRM", item;
            end
        else
            if (PostingView.CanPostItemRetail(item)) then
                return "POST_CONFIRM", item;
            end
        end

        PostingView.post:SetText("Post ("..#postQueue..")");

        if (#postQueue == 0) then
            return "IDLE";
        end
    end);

    postReady:AddEvent("IDLE");
    postReady:AddEvent("POST_CONFIRM");

    fsm:Add(postReady);
    fsm:Add(FSMState:New("POST"));

    local postConfirm = FSMState:New("POST_CONFIRM");
    postConfirm:SetOnEnter(function(self, item)
        self.item = item;
        return nil;
    end);
    postConfirm:SetOnExit(function(self)
        self.item = nil;
    end);
    postConfirm:AddEvent("DROPPED", function(self)
        if (#postQueue == 0) then
            return "IDLE";
        else
            return "POST_READY";
        end
    end);
    postConfirm:AddEvent("SUCCESS", function(self)
        tremove(postQueue, 1);
        print("AnS - successfully posted "..self.item.link);
        if (#postQueue == 0) then
            return "IDLE";
        else
            return "POST_READY";
        end
    end);
    postConfirm:AddEvent("FAILURE", function(self)
        print("AnS - failed to post "..self.item.link.." - skipping");
        tremove(postQueue, 1);
        if (#postQueue == 0) then
            return "IDLE";
        else
            return "POST_READY";
        end
    end);
    postConfirm:AddEvent("IDLE");
    postConfirm:AddEvent("POST_READY");
    fsm:Add(postConfirm);

    -- END POSTING STATES

    -- START CANCEL STATES

    local cancelScan = FSMState:New("CANCEL_SCAN");
    cancelScan:SetOnEnter(function(self)
        wipe(cancelQueue);
        wipe(ops)
        wipe(bestPrices);
        wipe(inventory);

        Query.Clear();

        searchesComplete = 0;

        for k,v in pairs(activeOps) do
            local op = AuctionOp:FromConfig(v);
            tinsert(ops, op);
        end

        if (Utils:IsClassic()) then
            return "CLASSIC_CANCEL_SCAN";
        else
            return "RETAIL_CANCEL_SCAN";
        end
    end);
    cancelScan:AddEvent("CLASSIC_CANCEL_SCAN");
    cancelScan:AddEvent("RETAIL_CANCEL_SCAN");

    fsm:Add(cancelScan);

    local classicCancel = FSMState:New("CLASSIC_CANCEL_SCAN");
    classicCancel:SetOnEnter(function(self)
        local num = Query:OwnedCount();
        for i = 1, num do
            local auction = Query:GetOwnedAuctionClassic(i);
            if (auction) then
                for i,op in ipairs(ops) do
                    if (op:ContainsItem(auction)) then
                        -- set original owned ppu
                        auction.ownedPPU = auction.ppu;
                        auction.op = op;
                        -- set best price to our owned ppu
                        bestPrices[auction.tsmId] = auction.ppu;
                        tinsert(inventory, auction);
                        break;
                    end
                end
            end
        end
    
        if (#inventory == 0) then
            print("AnS - Nothing to Cancel");
            return "IDLE";
        end

        local next = inventory[1];
        DEFAULT_BROWSE_QUERY.searchString = next.name;
        DEFAULT_BROWSE_QUERY.quality = 0;
        Query.page = 0;
    
        Query:Search(DEFAULT_BROWSE_QUERY, true)
        PostingView.post:Disable();
        PostingView.cancel:Disable();
        PostingView.cancel:SetText("Scanning 1 of "..#inventory);

        return "CANCEL_ITEM_RESULTS", next;
    end);
    classicCancel:AddEvent("IDLE");
    classicCancel:AddEvent("CANCEL_ITEM_RESULTS");

    fsm:Add(classicCancel);

    local retailCancel = FSMState:New("RETAIL_CANCEL_SCAN");
    retailCancel:SetOnEnter(function(self)
        PostingView.post:Disable();
        PostingView.cancel:Disable();
        PostingView.cancel:SetText("Getting Owned Auctions");

        Query.Owned();
        return nil;
    end);
    retailCancel:AddEvent("OWNED", function(self, event, owned) 
        for i,v in ipairs(owned) do
            for k,op in ipairs(ops) do
                if (op:ContainsItem(v)) then
                    local clone = v:Clone();

                    -- save original owned ppu
                    clone.ownedPPU = v.ppu;
                    
                    if (clone.isEquipment) then
                        clone.itemKey = AuctionHouseUtil.ConvertItemSellItemKey(v.itemKey);
                    end

                    -- set initial best price to our owned auction ppu
                    bestPrices[v.tsmId] = v.ppu;
                    clone.op = op;
                    tinsert(inventory, clone);
                    break;
                end
            end
        end

        if (#inventory == 0) then
            print("AnS - Nothing to Cancel");
            return "IDLE";
        end

        local next = inventory[1];
        PostingView.post:Disable();
        PostingView.cancel:Disable();
        PostingView.cancel:SetText("Scanning 1 of "..#inventory);
        Query.SearchForItem(next:Clone(), next.isEquipment, true);

        return "CANCEL_ITEM_RESULTS", next;
    end);

    retailCancel:AddEvent("IDLE");
    retailCancel:AddEvent("CANCEL_ITEM_RESULTS");

    fsm:Add(retailCancel);
    fsm:Add(FSMState:New("OWNED"));

    local cancelItemResults = FSMState:New("CANCEL_ITEM_RESULTS");
    cancelItemResults:SetOnEnter(function(self, item)
        self.item = item;
        return nil;
    end);
    cancelItemResults:AddEvent("ITEM_RESULT", function(self, event, item)
        if (item) then
            PostingView.CalcLowest(item);
        end
    end);
    cancelItemResults:AddEvent("SEARCH_COMPLETE", function(self)
        searchesComplete = searchesComplete + 1;

        local v = self.item;
        local ppu = bestPrices[v.tsmId] or 0;

        if (Utils:IsClassic()) then
            ppu = v.op:IsValid(ppu, v.link, false, v.ownedPPU);
        else
            ppu = v.op:IsValid(ppu, v.link, v.isCommodity and v.op.commodityLow, v.ownedPPU);
        end

        v.ppu = ppu;

        if (v.ppu > 0) then
            v.op:ApplyCancel(v, cancelQueue);
        end

        if (searchesComplete >= #inventory) then
            if (#cancelQueue > 0) then
                return "CANCEL_READY";
            else
                print("AnS - Nothing to Cancel");
                return "IDLE";
            end
        else
            local nextItem = inventory[searchesComplete + 1];
            self.item = nextItem;
            if (Utils:IsClassic()) then
                DEFAULT_BROWSE_QUERY.searchString = nextItem.name;
                Query.page = 0;
                Query:Search(DEFAULT_BROWSE_QUERY, true);
            else
                Query.SearchForItem(nextItem:Clone(), nextItem.isEquipment, true);
            end
            PostingView.cancel:SetText("Scanning "..(searchesComplete + 1).." of "..#inventory);
        end

        return nil;
    end);
    cancelItemResults:AddEvent("IDLE");
    cancelItemResults:AddEvent("CANCEL_READY");

    fsm:Add(cancelItemResults);

    fsm:Add(FSMState:New("ITEM_RESULT"));

    local cancelReady = FSMState:New("CANCEL_READY");
    cancelReady:SetOnEnter(function(self)
        PostingView.cancel:Enable();
        PostingView.cancel:SetText("Cancel ("..#cancelQueue..")");
        return nil;
    end);
    cancelReady:AddEvent("CANCEL", function(self)
        local item = cancelQueue[1];

        if (Utils:IsClassic()) then
            if (PostingView.CanCancelItemClassic(item)) then
                return "CANCEL_CONFIRM", item;
            end
        else
            if (PostingView.CanCancelItemRetail(item)) then
                return "CANCEL_CONFIRM", item;
            end
        end

        PostingView.cancel:SetText("Cancel ("..#cancelQueue..")");

        if (#cancelQueue == 0) then
            return "IDLE";
        end
    end);

    cancelReady:AddEvent("IDLE");
    cancelReady:AddEvent("CANCEL_CONFIRM");

    fsm:Add(cancelReady);
    fsm:Add(FSMState:New("CANCEL"));

    local cancelConfirm = FSMState:New("CANCEL_CONFIRM");
    cancelConfirm:SetOnEnter(function(self, item)
        self.item = item;
        return nil;
    end);
    cancelConfirm:SetOnExit(function(self)
        self.item = nil;
    end);
    cancelConfirm:AddEvent("DROPPED", function(self)
        if (#cancelQueue == 0) then
            return "IDLE";
        else
            return "CANCEL_READY";
        end
    end);
    cancelConfirm:AddEvent("FAILURE", function(self)
        tremove(cancelQueue, 1);
        print("AnS - Failed to cancel "..self.item.link.. " - skipping");
        if (#cancelQueue == 0) then
            return "IDLE";
        else
            return "CANCEL_READY";
        end
    end);
    cancelConfirm:AddEvent("SUCCESS", function(self)
        tremove(cancelQueue, 1);
        print("AnS - successfully canceled "..self.item.link);
        if (#cancelQueue == 0) then
            return "IDLE";
        else
            return "CANCEL_READY";
        end
    end);
    cancelConfirm:AddEvent("IDLE");
    cancelConfirm:AddEvent("CANCEL_READY");

    fsm:Add(cancelConfirm);

    -- END CANCEL STATES

    fsm:Add(FSMState:New("DROPPED"));
    fsm:Add(FSMState:New("SUCCESS"));
    fsm:Add(FSMState:New("FAILURE"));

    fsm:Start("NONE");
    fsm:Process("IDLE");

    return fsm;
end

function PostingView.OnClassicOwnedUpdate()
    if (PostingFSM) then
        local state = PostingFSM:GetCurrent();
        if (state and state.item and state.name == "POST_CONFIRM") then
            local item = state.item;
            local num = Query:OwnedCount();

            for i = 1, num do 
                local a = Query:GetOwnedAuctionClassic(i);
                if (a) then
                    if (a.link == item.link and a.count == item.count and a.ppu == item.ppu) then
                        PostingFSM:Process("SUCCESS");
                        return;
                    end
                end
            end

            PostingFSM:Process("FAILURE");
        elseif (state and state.item and state.name == "CANCEL_CONFIRM") then
            local item = state.item;
            local num = Query:OwnedCount();

            for i = 1, num do 
                local a = Query:GetOwnedAuctionClassic(i);
                if (a) then
                    if (a.link == item.link and a.count == item.count and a.ppu == item.ppu) then
                        PostingFSM:Process("FAILURE");
                        return;
                    end
                end
            end

            PostingFSM:Process("SUCCESS");
        end
    end
end

function PostingView.OnErrorMessage(type, msg)
    if (PostingFSM) then
        if (PostingFSM.current == "POST_CONFIRM" or PostingFSM.current == "CANCEL_CONFIRM") then
            if (Utils:InTable(ERRORS, msg)) then
                PostingFSM:Process("FAILURE");
            end
        end
    end
end

function PostingView.CanPostItemRetail(v)
    local total = v.toSell;
    local op = v.op;

    if (not BagScanner:Exists(v)) then
        tremove(postQueue, 1);
        print("AnS - "..v.link.." no longer exists in the specified bag slot");
        return false;
    end

    if (BagScanner:IsLocked(v)) then
        tremove(postQueue, 1);
        print("AnS - "..v.link.." is currently locked - skipping");
        return false;
    end

    if (not BagScanner:IsFullDurability(v)) then
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

function PostingView.PostItemRetail(v)
    local total = v.toSell;
    local op = v.op;

    if (not BagScanner:Exists(v)) then
        tremove(postQueue, 1);
        print("AnS - "..v.link.." no longer exists in the specified bag slot");
        return false;
    end

    if (BagScanner:IsLocked(v)) then
        tremove(postQueue, 1);
        print("AnS - "..v.link.." is currently locked - skipping");
        return false;
    end

    if (not BagScanner:IsFullDurability(v)) then
        tremove(postQueue, 1);
        print("AnS - "..v.link.." is not full durability - skipping");
        return false;
    end

    local location = ItemLocation:CreateFromBagAndSlot(v.bag, v.slot);
    if (total > 0) then
        local type = C_AuctionHouse.GetItemCommodityStatus(location);
        if (type == 2) then
            print("AnS - Trying to post "..v.link.. " x "..total.." for "..Utils:PriceToString(v.ppu).."|cFFFFFFFF per unit");
            C_AuctionHouse.PostCommodity(location, op.duration, total, v.ppu);
            return true;
        elseif (type == 1) then
            print("AnS - Trying to post "..v.link.. " x "..total.." for "..Utils:PriceToString(v.ppu).."|cFFFFFFFF per unit");
            C_AuctionHouse.PostItem(location, op.duration, total, nil, v.ppu);
            return true;
        end
    else
        tremove(postQueue, 1);
    end

    return false;
end

function PostingView.CanPostItemClassic(v)
    local op = v.op;

    if (not BagScanner:Exists(v, true)) then
        tremove(postQueue, 1);
        print("AnS - "..v.link.." no longer exists in the specified bag slot");
        return false;
    end

    if (BagScanner:IsLocked(v)) then
        tremove(postQueue, 1);
        print("AnS - "..v.link.." is currently locked - skipping");
        return false;
    end

    if (not BagScanner:IsFullDurability(v)) then
        tremove(postQueue, 1);
        print("AnS - "..v.link.." is not full durability - skipping");
        return false;
    end

    return true;
end

function PostingView.PostItemClassic(v)
    local op = v.op;
    local ppu = v.ppu;
    local bidPPU = v.ppu * op.bidPercent;

    if (not BagScanner:Exists(v, true)) then
        tremove(postQueue, 1);
        print("AnS - "..v.link.." no longer exists in the specified bag slot");
        return false;
    end

    if (BagScanner:IsLocked(v)) then
        tremove(postQueue, 1);
        print("AnS - "..v.link.." is currently locked - skipping");
        return false;
    end

    if (not BagScanner:IsFullDurability(v)) then
        tremove(postQueue, 1);
        print("AnS - "..v.link.." is not full durability - skipping");
        return false;
    end

    local total = v.count;
    print("AnS - Trying to post "..v.link.. " x "..total.." for "..Utils:PriceToString(v.ppu).."|cFFFFFFFF per unit");
   
    UseContainerItem(v.bag, v.slot);
    PostAuction(v.count * bidPPU, v.count * ppu, op.duration, v.count, 1);
    
    return true;
end

function PostingView.CanCancelItemRetail(v)
    if (C_AuctionHouse.CanCancelAuction(v.auctionId)) then
        return true;
    end

    print("AnS - Cannot cancel auction "..v.link.." x "..v.count.." - skipping");
    tremove(cancelQueue, 1);

    return false;
end

function PostingView.CancelItemRetail(v)
    if (C_AuctionHouse.CanCancelAuction(v.auctionId)) then
        print("AnS - Trying to cancel "..v.link.." x "..v.count);
        C_AuctionHouse.CancelAuction(v.auctionId);
        return true;
    end

    print("AnS - Cannot cancel auction "..v.link.." x "..v.count.." - skipping");
    tremove(cancelQueue, 1);

    return false;
end

function PostingView.CanCancelItemClassic(v)
    local num = Query:OwnedCount();
  -- we need to find the classic index to cancel
    -- based on the hash
    for i = 1, num do 
        local a = Query:GetOwnedAuctionClassic(i);
        if (a) then
            if (a.hash == v.hash) then
                if (CanCancelAuction(a.itemIndex)) then
                    Recycler:Recycle(a);
                    return true;
                else
                    print("AnS - Cannot cancel auction "..v.link.." x "..v.count.." - skipping");
                    tremove(cancelQueue, 1);
                    Recycler:Recycle(a);
                    return false;
                end
            end

            Recycler:Recycle(a);
        end
    end

    print("AnS - Could not find auction "..v.link.." x "..v.count.." - skipping");
    tremove(cancelQueue, 1);

    return false;
end

function PostingView.CancelItemClassic(v)
    local num = Query:OwnedCount();

    -- we need to find the classic index to cancel
    -- based on the hash
    for i = 1, num do 
        local a = Query:GetOwnedAuctionClassic(i);
        if (a) then
            if (a.hash == v.hash) then
                if (CanCancelAuction(a.itemIndex)) then
                    print("AnS - Trying to cancel "..v.link.." x "..v.count);
                    CancelAuction(a.itemIndex);
                    Recycler:Recycle(a);
                    return true;
                else
                    print("AnS - Cannot cancel auction "..v.link.." x "..v.count.." - skipping");
                    tremove(cancelQueue, 1);
                    Recycler:Recycle(a);
                    return false;
                end
            end

            Recycler:Recycle(a);
        end
    end

    print("AnS - Could not find auction "..v.link.." x "..v.count.." - skipping");
    tremove(cancelQueue, 1);

    return false;
end

function PostingView:OnLoad(f)
    local this = self;

    if (self.inited) then
        return;
    end

    local filterTemplate = "AnsFilterRowTemplate";
    local frameTemplate = "AnsPostingTemplate"

    if (Utils:IsClassic()) then
        frameTemplate = "AnsPostingClassicTemplate";
        filterTemplate = "AnsFilterRowClassicTemplate";
    end

    self.inited = true;
    self.parent = f;
    self.frame = CreateFrame("Frame", "AnsPostingHook", f, frameTemplate);

    self.frame:SetScript("OnShow", function() this:OnShow() end);
    self.frame:SetScript("OnHide", function() this:OnHide() end);

    self.parent.AnsPosting = self.frame;

    local AHDisplayMode = AuctionHouseFrameDisplayMode or {};
    
    if (AHDisplayMode.ItemSell) then
        tinsert(AHDisplayMode.ItemSell, "AnsPosting");
    end
    if (AHDisplayMode.CommoditiesSell) then
        tinsert(AHDisplayMode.CommoditiesSell, "AnsPosting");
    end
    if (AHDisplayMode.Auctions) then
        tinsert(AHDisplayMode.Auctions, "AnsPosting");
    end

    if (Utils:IsClassic()) then
        -- assign a tab display mode
        -- to the classic AHTabs
        -- required to show this
        AuctionFrameTab3.displayMode = {"AnsPosting"};
    end

    self.cancel = self.frame.Cancel;
    self.post = self.frame.Post;
    self.reset = self.frame.Reset;
    self.all = self.frame.All;

    self.filterTree = TreeView:New(self.frame, {
        rowHeight = 21,
        childIndent = 16,
        template = filterTemplate, multiselect = true
    }, function(item) 
        if (item.op and not item.group) then
            this:Toggle(item.op)
        elseif (item.op and item.group) then
            this:ToggleGroup(item.op, item.group); 
        end
    end);

    self.all:SetScript("OnClick", self.SelectAll);
    self.reset:SetScript("OnClick", self.Reset);
    self.post:SetScript("OnClick", function() this:Post() end);
    self.cancel:SetScript("OnClick", function() this:Cancel() end);
end

function PostingView:Hide()
    if (self.frame) then
        self.frame:Hide();
    end
end

function PostingView:Toggle(op) 
    if (activeOps[op.id]) then
        activeOps[op.id] = nil;
    else
        activeOps[op.id] = op;
    end

    self:RefreshTreeView();
end

function PostingView.Reset()
    wipe(activeOps);
    PostingView:RefreshTreeView();
end

function PostingView.SelectAll()
    local ops = Config.Operations().Auctioning;
    for i,v in ipairs(ops) do
        activeOps[v.id] = v;
    end
    PostingView:RefreshTreeView();
end

function PostingView:ToggleGroup(f, g)
    if (f.nonActiveGroups[g]) then
        f.nonActiveGroups[g] = nil;
    else
        f.nonActiveGroups[g] = true;
    end
end

function PostingView:RefreshTreeView()
    local ops = Config.Operations().Auctioning;

    wipe(treeViewItems);
    for i,v in ipairs(ops) do
        v.nonActiveGroups = v.nonActiveGroups or {};
        local t = {
            name = v.name,
            op = v,
            selected = activeOps[v.id] ~= nil,
            children = {},
            expanded = false
        };

        for i,v2 in ipairs(v.groups) do
            local g = Utils:GetGroupFromId(v2);
            if (g) then
                tinsert(t.children, {
                    name = g.path,
                    selected = (not v.nonActiveGroups[v2]),
                    expanded = false,
                    children = {},
                    group = v2,
                    op = v
                });
            end
        end

        tinsert(treeViewItems, t);
    end

    self.filterTree.items = treeViewItems;
    self.filterTree:Refresh();
end

function PostingView.OnSearchResult(item)
    if (PostingFSM) then
        PostingFSM:Process('ITEM_RESULT', item);
    end
end

function PostingView.CalcLowest(item)
    local valid = item.ppu;

    if (valid > 0) then
        if (bestPrices[item.tsmId]) then
            bestPrices[item.tsmId] = math.min(valid, bestPrices[item.tsmId]);
        else
            bestPrices[item.tsmId] = valid;
        end
    end

    if (Utils:IsClassic()) then
        Recycler:Recycle(item);
    end
end

function PostingView.OnSearchComplete(item)
    --local self = PostingView;
    if (PostingFSM) then
        PostingFSM:Process("SEARCH_COMPLETE");
    end
end

function PostingView.OnDropped()
    if (PostingFSM) then
        PostingFSM:Process("DROPPED");
    end
end

function PostingView.OnFailure()
    if (PostingFSM) then
        PostingFSM:Process("FAILURE");
    end
end

function PostingView.OnAuctionCreated()
    if (PostingFSM) then
        PostingFSM:Process("SUCCESS");
    end
end

function PostingView.OnOwned(owned)
    if (PostingFSM) then
        PostingFSM:Process("OWNED", owned);
    end
end

-- just something to note
-- the id returned when using C_AuctionHouse.CancelAuction
-- will return 0 in most cases unless the item
-- is selected in the blizzard UI and the blizzard UI cancel button is used. 
-- Not sure if this is a bug
-- or not on blizzards part.
-- as according to the docs it should be the auction id that was canceled
-- however that is not always the case with C_AuctionHouse.CancelAuction
-- for third party addons
function PostingView.OnAuctionCanceled(id)
    if (PostingFSM) then
        PostingFSM:Process("SUCCESS");
    end
end

function PostingView:Cancel()
    if (not self.frame:IsShown()) then
        return;
    end

    if (PostingFSM) then
        if (PostingFSM.current == "IDLE") then
            PostingFSM:Process("CANCEL_SCAN");
        elseif (PostingFSM.current == "CANCEL_READY") then
            PostingFSM:Process("CANCEL");

            -- we have to do this here
            -- in order to ensure the PostingFSM state changes
            -- are complete before we proceed to cancel
            -- We cannot do a delay in the states like usual
            -- since C_AuctionHouse.CancelAuction
            -- require physical user input on the same frame of execution
            local state = PostingFSM:GetCurrent();
            if (state.item and state.name == "CANCEL_CONFIRM") then
                if (Utils:IsClassic()) then
                    if (not PostingView.CancelItemClassic(state.item)) then
                        PostingFSM:Process("DROPPED");
                    end
                else
                    if (not PostingView.CancelItemRetail(state.item)) then
                        PostingFSM:Process("DROPPED");
                    end
                end
            end
        end
    end
end

function PostingView:Post()
    if (not self.frame:IsShown()) then
        return;
    end

    if (PostingFSM) then
        if (PostingFSM.current == "IDLE") then
            PostingFSM:Process("POST_SCAN");
        elseif (PostingFSM.current == "POST_READY") then
            PostingFSM:Process("POST");

            -- we have to do this here
            -- in order to ensure the PostingFSM state changes
            -- are complete before we proceed to purchase
            -- We cannot do a delay in the states like usual
            -- since C_AuctionHouse.PostCommodity, C_AuctionHouse.PostItem, or PostAuction
            -- require physical user input on the same frame of execution
            local state = PostingFSM:GetCurrent();
            if (state.item and state.name == "POST_CONFIRM") then
                if (Utils:IsClassic()) then
                    if (not PostingView.PostItemClassic(state.item)) then
                        PostingFSM:Process("DROPPED");
                    end
                else
                    if (not PostingView.PostItemRetail(state.item)) then
                        PostingFSM:Process("DROPPED");
                    end
                end
            end
        end
    end
end

function PostingView:Stop()
    self.post:SetText("Post Scan");
    self.post:Enable();
    self.cancel:Enable();
    self.cancel:SetText("Cancel Scan");
    wipe(ops);
    wipe(bestPrices);
    wipe(inventory);
    wipe(postQueue);
    wipe(cancelQueue);
    Query.Clear();
end

function PostingView:RegisterEvents()
    EventManager:On("QUERY_SEARCH_RESULT", PostingView.OnSearchResult);
    EventManager:On("QUERY_SEARCH_COMPLETE", PostingView.OnSearchComplete);
    EventManager:On("QUERY_OWNED_AUCTIONS", PostingView.OnOwned);
    EventManager:On("AUCTION_HOUSE_AUCTION_CREATED", PostingView.OnAuctionCreated);
    EventManager:On("AUCTION_CANCELED", PostingView.OnAuctionCanceled);
    EventManager:On("AUCTION_MULTISELL_FAILURE", PostingView.OnFailure);
    EventManager:On("AUCTION_HOUSE_THROTTLED_MESSAGE_DROPPED", PostingView.OnDropped);
    EventManager:On("AUCTION_OWNED_LIST_UPDATE", PostingView.OnClassicOwnedUpdate);
    EventManager:On("UI_ERROR_MESSAGE", PostingView.OnErrorMessage);
end

function PostingView:UnregisterEvents()
    EventManager:RemoveListener("QUERY_SEARCH_RESULT", PostingView.OnSearchResult);
    EventManager:RemoveListener("QUERY_SEARCH_COMPLETE", PostingView.OnSearchComplete);
    EventManager:RemoveListener("QUERY_OWNED_AUCTIONS", PostingView.OnOwned);
    EventManager:RemoveListener("AUCTION_HOUSE_AUCTION_CREATED", PostingView.OnAuctionCreated);
    EventManager:RemoveListener("AUCTION_CANCELED", PostingView.OnAuctionCanceled);
    EventManager:RemoveListener("AUCTION_MULTISELL_FAILURE", PostingView.OnFailure);
    EventManager:RemoveListener("AUCTION_HOUSE_THROTTLED_MESSAGE_DROPPED", PostingView.OnDropped);
    EventManager:RemoveListener("AUCTION_OWNED_LIST_UPDATE", PostingView.OnClassicOwnedUpdate);
    EventManager:RemoveListener("UI_ERROR_MESSAGE", PostingView.OnErrorMessage);
end

function PostingView:OnHide()
    if (PostingFSM) then
        PostingFSM:Interrupt();
    end

    Tasker.Clear(TASKER_TAG);

    self:Stop();
    self:UnregisterEvents();
end

function PostingView:OnShow()
    PostingFSM = BuildStateMachine();
    self:RefreshTreeView();
    self:RegisterEvents();
end