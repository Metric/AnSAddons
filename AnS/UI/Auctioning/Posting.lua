local Ans = select(2, ...);
local Config = Ans.Config;
local Utils = Ans.Utils;
local Query = Ans.Auctions.Query;
local Recycler = Ans.Auctions.Recycler;
local EventManager = Ans.EventManager;

local AuctionOp = Ans.Operations.Auctioning;

local TreeView = Ans.UI.TreeView;

local PostingView = {};
PostingView.__index = PostingView;
PostingView.inited = false;

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
local searchesComplete = 0;

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
    }, function(item) this:Toggle(item.op) end);

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

function PostingView:RefreshTreeView()
    local ops = Config.Operations().Auctioning;

    wipe(treeViewItems);
    for i,v in ipairs(ops) do
        local t = {
            name = v.name,
            op = v,
            selected = activeOps[v.id] ~= nil
        };
        tinsert(treeViewItems, t);
    end

    self.filterTree.items= treeViewItems;
    self.filterTree:Refresh();
end

function PostingView.IsExiting()
    return PostingView.state == STATES.NONE;
end

-- classic posting scan

function PostingView.OnClassicResult(item)
    local self = PostingView;

    if (self.state == STATES.SCANNING) then
        if (item.op) then
            local op = item.op;
            local valid = op:IsValid(item, false, self.type == STATES.CANCEL and bestPrices[item.link] or nil);
            if (valid > 0) then
                if (bestPrices[item.link]) then
                    bestPrices[item.link] = math.min(valid, bestPrices[item.link]);
                else
                    bestPrices[item.link] = valid;
                end
            end
        end

        Recycler:Recycle(item);
    end
end

function PostingView.OnClassicComplete()
    local self = PostingView;
    if (self.state == STATES.SCANNING) then
        searchesComplete = searchesComplete + 1;

        if (searchesComplete >= #inventory) then
            if (self.type == STATES.POST) then
                for i,v in ipairs(inventory) do
                    local txt, ppu = Utils:MoneyStringToCopper(v.op.undercut);

                    if (not ppu) then
                        ppu = 0;
                    end

                    if (bestPrices[v.link]) then
                        v.ppu = bestPrices[v.link] - ppu;
                    else
                        v.ppu = v.op:GetNormalValue(v) - ppu;
                    end

                    if (v.ppu > 0) then
                        v.op:ApplyPost(v);
                    end
                end

                if (AuctionOp.QueueCount() > 0) then
                    self:Ready();
                else
                    self:Stop();
                end
            else
                for i,v in ipairs(inventory) do
                    if (bestPrices[v.link]) then
                        v.ppu = bestPrices[v.link];

                        if (v.ppu > 0) then
                            v.op:ApplyCancel(v);
                        end
                    end
                end

                if (AuctionOp.QueueCount() > 0) then
                    self:Ready();
                else
                    print("AnS - Nothing to Cancel");
                    self:Stop();
                end
            end
        else
            local nextItem = inventory[searchesComplete + 1];
            DEFAULT_BROWSE_QUERY.searchString = nextItem.name;
            Query.page = 0;
            Query:Search(DEFAULT_BROWSE_QUERY, true, nextItem.op);

            if (self.type == STATES.POST) then
                self.post:SetText("Scanning "..(searchesComplete + 1).." of "..#inventory);
            elseif (self.type == STATES.CANCEL) then
                self.cancel:SetText("Scanning "..(searchesComplete + 1).." of "..#inventory);
            end
        end
    end
end

-- retail posting scan

function PostingView.OnSearchResult(item)
    local self = PostingView;
    if (self.state == STATES.SCANNING) then
        if (item.op) then
            local op = item.op;
            local valid = op:IsValid(item, item.isCommodity and op.commodityLow, self.type == STATES.CANCEL and bestPrices[item.link] or nil);

            if (valid > 0) then
                if (bestPrices[item.link]) then
                    bestPrices[item.link] = math.min(valid, bestPrices[item.link]);
                else
                    bestPrices[item.link] = valid;
                end
            end
        end
    end
end

function PostingView.OnSearchComplete(item)
    local self = PostingView;
    if (self.state == STATES.SCANNING) then
        searchesComplete = searchesComplete + 1;

        if (searchesComplete >= #inventory) then
            if (self.type == STATES.POST) then
                for i,v in ipairs(inventory) do
                    local txt, ppu = Utils:MoneyStringToCopper(v.op.undercut);

                    if (not ppu) then
                        ppu = 0;
                    end

                    if (bestPrices[v.link]) then
                        v.ppu = bestPrices[v.link] - ppu;
                    else
                        v.ppu = v.op:GetNormalValue(v) - ppu;
                    end

                    v.ppu = v.ppu - (v.ppu % COPPER_PER_SILVER);

                    if (v.ppu > 0) then
                        v.op:ApplyPost(v);
                    end
                end 

                if (AuctionOp.QueueCount() > 0) then
                    self:Ready();
                else
                    self:Stop();
                end
            elseif (self.type == STATES.CANCEL) then
                for i,v in ipairs(inventory) do
                    if (bestPrices[v.link]) then
                        v.ppu = bestPrices[v.link];

                        if (v.ppu > 0) then
                            v.op:ApplyCancel(v);
                        end
                    end
                end

                if (AuctionOp.QueueCount() > 0) then
                    self:Ready();
                else
                    print("AnS - Nothing to Cancel");
                    self:Stop();
                end
            end
        else
            Query.SearchForItem(inventory[searchesComplete + 1], inventory[searchesComplete + 1].isEquipment, true);

            if (self.type == STATES.POST) then
                self.post:SetText("Scanning "..(searchesComplete + 1).." of "..#inventory);
            elseif (self.type == STATES.CANCEL) then
                self.cancel:SetText("Scanning "..(searchesComplete + 1).." of "..#inventory);
            end
        end
    end
end

function PostingView.OnOwned(owned)
    local self = PostingView;
    if (self.state == STATES.OWNED) then
        wipe(inventory);

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
                    bestPrices[v.link] = v.ppu;
                    clone.op = op;
                    tinsert(inventory, clone);
                    break;
                end
            end
        end

        if (#inventory > 0) then
            searchesComplete = 0;
            self.cancel:SetText("Scanning "..(searchesComplete + 1).." of "..#inventory);
            Query.SearchForItem(inventory[searchesComplete + 1], inventory[searchesComplete + 1].isEquipment, true);
            self.state = STATES.SCANNING;
        else
            print("AnS - Nothing to Cancel");
            self:Stop();
        end
    end
end

function PostingView.OnFailure()
    local self = PostingView;

    if (AuctionOp.IsWaitingForConfirm()) then
        
    end
end

function PostingView.OnAuctionCreated()
    local self = PostingView;
    
    if (self.state == STATES.READY) then
        if (AuctionOp.IsWaitingForConfirm()) then

        end
    end
end

function PostingView.OnAuctionCanceled()
    local self = PostingView;

    if (self.state == STATES.READY) then
        if (AuctionOp.IsWaitingForConfirm()) then

        end
    end
end

function PostingView:Ready()
    if (self.state == STATES.SCANNING) then
        self.state = STATES.READY;

        if (self.type == STATES.POST) then
            self.post:Enable();
            self.post:SetText("Post ("..AuctionOp.QueueCount()..")");
        elseif(self.type == STATES.CANCEL) then
            self.cancel:Enable();
            self.cancel:SetText("Cancel ("..AuctionOp.QueueCount()..")");
        end
    end
end

function PostingView:Cancel()
    if (self.state == STATES.NONE) then
        self.type = STATES.CANCEL;
        searchesComplete = 0;

        if (Utils:IsClassic()) then
            wipe(ops);
            
            for k,v in pairs(activeOps) do
                local op = AuctionOp:FromConfig(v);
                tinsert(ops, op);
            end

            self:CancelScanClassic();
        else
            self:CancelScanRetail();
        end
    elseif (self.state == STATES.READY and self.type == STATES.CANCEL) then
        if (Query.IsThrottled()) then
            return;
        end

        AuctionOp:CancelNext();

        self.cancel:SetText("Cancel ("..AuctionOp.QueueCount()..")");
    
        if (AuctionOp.QueueCount() <= 0) then
            self:Stop();
        end
    end
end

function PostingView:CancelScanClassic()
    local num = Query:OwnedCount();
    wipe(inventory);
    wipe(bestPrices);

    for i = 1, num do
        local auction = Query:GetOwnedAuctionClassic(i);
        if (auction) then
            for i,op in ipairs(ops) do
                if (op:ContainsItem(auction)) then
                    -- set original owned ppu
                    auction.ownedPPU = auction.ppu;
                    auction.op = op;
                    -- set best price to our owned ppu
                    bestPrices[auction.link] = auction.ppu;
                    tinsert(inventory, auction);
                    break;
                end
            end
        end
    end

    if (#inventory == 0) then
        print("AnS - Nothing to Cancel");
        return;
    end

    DEFAULT_BROWSE_QUERY.searchString = inventory[1].name;
    DEFAULT_BROWSE_QUERY.quality = 0;
    Query.page = 0;

    Query:Search(DEFAULT_BROWSE_QUERY, true, inventory[1].op)
    self.post:Disable();
    self.cancel:Disable();
    self.cancel:SetText("Scanning 1 of "..#inventory);

    self.state = STATES.SCANNING;
end

function PostingView:CancelScanRetail()
    wipe(ops);
    wipe(inventory);
    wipe(bestPrices);

    Query.IsExiting = PostingView.IsExiting;

    for k,v in pairs(activeOps) do
        local op = AuctionOp:FromConfig(v);
        tinsert(ops, op);
    end

    Query.Owned()
    self.state = STATES.OWNED;
    self.post:Disable();
    self.cancel:Disable();
    self.cancel:SetText("Getting Owned Auctions");
end

function PostingView:Post()
    if (self.state == STATES.NONE) then
        self.type = STATES.POST;
        searchesComplete = 0;

        if (Utils:IsClassic()) then
            self:PostScanClassic();
        else
            self:PostScanRetail();
        end
    elseif (self.state == STATES.READY and self.type == STATES.POST) then
        if (Query.IsThrottled()) then
            return;
        end

        AuctionOp:PostNext();
        self.post:SetText("Post ("..AuctionOp.QueueCount()..")");

        if (AuctionOp.QueueCount() == 0) then
            self:Stop();
        end
    end
end

function PostingView:PostScanClassic()
    wipe(ops);
    wipe(inventory);
    wipe(bestPrices);

    for k,v in pairs(activeOps) do
        local op = AuctionOp:FromConfig(v);
        tinsert(ops, op);
        local items = op:GetAvailableItems();

        for i, item in ipairs(items) do
            tinsert(inventory, item);
        end
    end

    if (#inventory == 0) then
        print("AnS - Nothing to Post");
        return;
    end

    DEFAULT_BROWSE_QUERY.searchString = inventory[1].name;
    DEFAULT_BROWSE_QUERY.quality = 0;
    Query.page = 0;

    Query:Search(DEFAULT_BROWSE_QUERY, true, inventory[1].op)
    self.post:SetText("Scanning 1 of "..#inventory);
    self.post:Disable();
    self.cancel:Disable();

    self.state = STATES.SCANNING;
end

function PostingView:PostScanRetail()
    wipe(ops);
    wipe(inventory);
    wipe(bestPrices);

    Query.IsExiting = PostingView.IsExiting;

    for k,v in pairs(activeOps) do
        local op = AuctionOp:FromConfig(v);
        tinsert(ops, op);
        local items = op:GetAvailableItems();
        for i,item in ipairs(items) do
            local location = ItemLocation:CreateFromBagAndSlot(item.bag, item.slot);
            item.itemKey = C_AuctionHouse.GetItemKeyFromItem(location);
            if (item.itemKey) then
                item.isEquipment = C_AuctionHouse.GetItemKeyInfo(item.itemKey).isEquipment;
                if (item.isEquipment) then
                    item.itemKey = AuctionHouseUtil.ConvertItemSellItemKey(item.itemKey);
                end
                tinsert(inventory, item);
            end
        end
    end

    if (#inventory == 0) then
        print("AnS - Nothing to Post");
        return;
    end

    Query.SearchForItem(inventory[1], inventory[1].isEquipment, true)
    self.post:SetText("Scanning 1 of "..#inventory);
    self.post:Disable();
    self.cancel:Disable();

    self.state = STATES.SCANNING;
end

function PostingView:Stop()
    self.state = STATES.NONE;
    self.post:SetText("Post Scan");
    self.post:Enable();
    self.cancel:Enable();
    self.cancel:SetText("Cancel Scan");
    AuctionOp.ClearQueue();
    wipe(ops);
    wipe(bestPrices);
    wipe(inventory);
    Query.Clear();
end

function PostingView:RegisterQueueEvents()
    if (Utils:IsClassic()) then
        EventManager:On("QUERY_CLASSIC_RESULT", PostingView.OnClassicResult);
        EventManager:On("QUERY_CLASSIC_COMPLETE", PostingView.OnClassicComplete);
    else
        EventManager:On("QUERY_SEARCH_RESULT", PostingView.OnSearchResult);
        EventManager:On("QUERY_SEARCH_COMPLETE", PostingView.OnSearchComplete);
        EventManager:On("QUERY_OWNED_AUCTIONS", PostingView.OnOwned);
    end
end

function PostingView:UnregisterQueueEvents()
    if (Utils:IsClassic()) then
        EventManager:RemoveListener("QUERY_CLASSIC_RESULT", PostingView.OnClassicResult);
        EventManager:RemoveListener("QUERY_CLASSIC_COMPLETE", PostingView.OnClassicComplete);
    else
        EventManager:RemoveListener("QUERY_SEARCH_RESULT", PostingView.OnSearchResult);
        EventManager:RemoveListener("QUERY_SEARCH_COMPLETE", PostingView.OnSearchComplete);
        EventManager:RemoveListener("QUERY_OWNED_AUCTIONS", PostingView.OnOwned);
    end
end

function PostingView:OnHide()
    self:Stop();
    self:UnregisterQueueEvents();

    -- unregister classic stuff here
end

function PostingView:OnShow()
    self:RefreshTreeView();
    self:RegisterQueueEvents();

    -- register classic stuff here
end