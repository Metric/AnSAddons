local Ans = select(2, ...);
local Config = Ans.Config;
local Utils = Ans.Utils;
local Groups = Utils.Groups;
local Query = Ans.Auctions.Query;
local Recycler = Ans.Auctions.Recycler;

local EventManager = Ans.EventManager;
local Logger = Ans.Logger;

local Tasker = Ans.Tasker;
local TASKER_TAG = "POSTING";
local TASKER_TAG_POST = "POSTING_POST";

local AuctionOp = Ans.Operations.Auctioning;

local TreeView = Ans.UI.TreeView;

local PostingView = Ans.Object.Register("AuctionPostingView", Ans.UI);

local STATES = {};
STATES.NONE = 0;
STATES.POSTING = 1;
STATES.POSTING_READY = 2;
STATES.CANCELING = 3;
STATES.CANCELING_READY = 4;

PostingView.module = nil;

PostingView.ops = {};
PostingView.inventory = {};
PostingView.bestPrices = {};
PostingView.postQueue = {};
PostingView.cancelQueue = {};
PostingView.ownedIds = {};
PostingView.firstMatch = nil;
PostingView.state = STATES.NONE;

-- local access helpers
local ops = PostingView.ops;
local inventory = PostingView.inventory;
local bestPrices = PostingView.bestPrices;
local postQueue = PostingView.postQueue;
local cancelQueue = PostingView.cancelQueue;
local ownedIds = PostingView.ownedIds;

local activeOps = {};
local treeViewItems = {};
local searchesComplete = 0;
local totalSearches = 0;

local function Wipe()
    PostingView.firstMatch = nil;

    searchesComplete = 0;
    totalSearches = 0;

    wipe(ownedIds);
    wipe(ops);
    wipe(postQueue);
    wipe(cancelQueue);
    wipe(bestPrices);
    wipe(inventory);
end

PostingView.Wipe = Wipe;

function PostingView.GetInventory()
    local module = PostingView.module;

    for k,v in pairs(activeOps) do
        local op = AuctionOp.From(v);
        tinsert(ops, op);

        local items = op:GetAvailableItems();

        for i, item in ipairs(items) do
            module:TrackInventory(item);
            -- if (not Utils.IsClassic()) then
                
            -- else
            --    tinsert(inventory, item);
            -- end
        end

    end
end

function PostingView.GetOps()
    for k,v in pairs(activeOps) do
        local op = AuctionOp.From(v);
        tinsert(ops, op);
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

end

function PostingView.Update(delta)
    local module = PostingView.module;
    module:Process();
end

function PostingView.OnPriceScan(isCancel, first)
    Logger.Log("POSTING", "Price Scan Request");

    if (first) then
        totalSearches = #inventory;
    end

    local module = PostingView.module;
    if (not module:PriceScan(isCancel)) then
        PostingView:ValidateQueues(isCancel);
    else
        searchesComplete = searchesComplete + 1;
        PostingView:UpdateSearchState(isCancel);    
    end
end

function PostingView.OnComplete(isCancel)
    if (isCancel) then
        print("Ans - Cancel Complete");
    else
        print("Ans - Post Complete");
    end

    PostingView:Stop();
end

function PostingView.CalcLowest(item, ref)
    local valid = item.ppu;

    if (valid > 0) then
        if (bestPrices[ref]) then
            bestPrices[ref] = math.min(valid, bestPrices[ref]);
        else
            bestPrices[ref] = valid;
        end
    end
end

function PostingView.TrackItem(v, item, isCancel)
    if (isCancel and not Utils.IsClassic()) then
        local first = PostingView.firstMatch;
        if (not first) then
            PostingView.firstMatch = v:Clone();
        end
    else
        item.op:Track(v);
    end

    PostingView.CalcLowest(v, item.op:GetReferenceID(v)); 
end

function PostingView.ValidateItem(item, isCancel)
    local v = item;
    local vid = v.op:GetReferenceID(v);
    local ppu = bestPrices[vid] or 0;

    ppu = v.op:IsValid(ppu, vid, v.isCommodity and v.op.commodityLow, v.ownedPPU);

    if (not isCancel) then     
        local txt, undercut = Utils.MoneyStringToCopper(v.op.undercut);

        if (not undercut) then
            undercut = 0;
        end

        ppu = ppu - undercut;
    end
       
    v.ppu = ppu;

    if (isCancel) then
        local first = PostingView.firstMatch;
        local cancelByTime = not Utils.IsClassic() 
                                and first and not first.isOwnerItem;

        if (v.ppu > 0 or cancelByTime) then
            v.op:ApplyCancel(v, cancelQueue, cancelByTime);
        end
    else
        v.ppu = v.ppu - (v.ppu % COPPER_PER_SILVER);
        if (v.ppu > 0) then
            v.op:ApplyPost(v, postQueue);
        end
    end

    PostingView.firstMatch = nil;
end

function PostingView:UnhookTabs()
    local AHDisplayMode = AuctionHouseFrameDisplayMode or {};
    
    if (AHDisplayMode.ItemSell) then
        for i,v in ipairs(AHDisplayMode.ItemSell) do
            if (v == "AnsPosting") then
                tremove(AHDisplayMode.ItemSell, i);
                break;
            end
        end
    end
    if (AHDisplayMode.CommoditiesSell) then
        for i,v in ipairs(AHDisplayMode.CommoditiesSell) do
            if (v == "AnsPosting") then
                tremove(AHDisplayMode.CommoditiesSell, i);
                break;
            end
        end
    end
    if (AHDisplayMode.Auctions) then
        for i,v in ipairs(AHDisplayMode.Auctions) do
            if (v == "AnsPosting") then
                tremove(AHDisplayMode.Auctions, i);
                break;
            end
        end
    end

    if (Utils.IsClassic()) then
        AuctionFrameTab3.displayMode = {};
    end
end

function PostingView:HookTabs()
    local AHDisplayMode = AuctionHouseFrameDisplayMode or {};
    
    if (AHDisplayMode.ItemSell and not Utils.InTable(AHDisplayMode.ItemSell, "AnsPosting")) then
        tinsert(AHDisplayMode.ItemSell, "AnsPosting");
    end
    if (AHDisplayMode.CommoditiesSell and not Utils.InTable(AHDisplayMode.CommoditiesSell, "AnsPosting")) then
        tinsert(AHDisplayMode.CommoditiesSell, "AnsPosting");
    end
    if (AHDisplayMode.Auctions and not Utils.InTable(AHDisplayMode.Auctions, "AnsPosting")) then
        tinsert(AHDisplayMode.Auctions, "AnsPosting");
    end

    if (Utils.IsClassic()) then
        -- assign a tab display mode
        -- to the classic AHTabs
        -- required to show this
        AuctionFrameTab3.displayMode = {"AnsPosting"};
    end
end

function PostingView:OnLoad(f)
    local this = self;

    if (self.inited) then
        return;
    end

    local filterTemplate = "AnsFilterRowTemplate";
    local frameTemplate = "AnsPostingTemplate"

    if (Utils.IsClassic()) then
        frameTemplate = "AnsPostingClassicTemplate";
        filterTemplate = "AnsFilterRowClassicTemplate";
    end

    self.inited = true;
    self.parent = f;
    self.frame = CreateFrame("Frame", "AnsPostingHook", f, frameTemplate);

    self.frame:SetScript("OnShow", function() this:OnShow() end);
    self.frame:SetScript("OnHide", function() this:OnHide() end);

    self.parent.AnsPosting = self.frame;

    self.cancel = self.frame.Cancel;
    self.post = self.frame.Post;
    self.reset = self.frame.Reset;
    self.all = self.frame.All;

    self.filterTree = TreeView:Acquire(self.frame, {
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

function PostingView:ValidateQueues(isCancel)
    if (#cancelQueue == 0 and #postQueue == 0) then
        EventManager:Emit("POSTING_COMPLETE", isCancel);
        return;
    end

    if (isCancel) then
        self.cancel:Enable();
        self.cancel:SetText("Cancel ("..#cancelQueue..")");
        self.state = STATES.CANCELING_READY;
    else
        self.post:Enable();
        self.post:SetText("Post ("..#postQueue..")");
        self.state = STATES.POSTING_READY;
    end
end

function PostingView:UpdateSearchState(isCancel)
    if (isCancel) then
        self.cancel:SetText("Scanning "..searchesComplete.." of "..totalSearches);
    else
        self.post:SetText("Scanning "..searchesComplete.." of "..totalSearches);
    end
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
            local g = Groups.GetGroupFromId(v2);
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

function PostingView:DisableButtons()
    self.cancel:Disable();
    self.post:Disable();
end

function PostingView:Cancel()
    if (not self.frame:IsShown()) then
        return;
    end

    if (self.state == STATES.NONE) then
        self.state = STATES.CANCELING;

        self:DisableButtons();
        self.cancel:SetText("Scanning");

        local module = self.module;
        module:CancelScan();
    elseif (self.state == STATES.CANCELING_READY) then
        local module = self.module;
        local hasNext = module:CancelNext();

        self.cancel:SetText("Cancel ("..#cancelQueue..")");

        if (not hasNext) then
            EventManager:Emit("POSTING_COMPLETE", true);
        end
    end
end

function PostingView:Post()
    if (not self.frame:IsShown()) then
        return;
    end

    if (self.state == STATES.NONE) then
        self.state = STATES.POSTING;

        self:DisableButtons();
        self.post:SetText("Scanning");

        local module = self.module;
        module:PostScan();
    elseif (self.state == STATES.POSTING_READY) then
        local module = self.module;
        local hasNext = module:PostNext();

        self.post:SetText("Post ("..#postQueue..")");
        
        if (not hasNext) then
            EventManager:Emit("POSTING_COMPLETE", false);
        end
    end
end

function PostingView:Stop()
    self.state = STATES.NONE;

    self.post:Enable();
    self.cancel:Enable();

    self.post:SetText("Post Scan");
    self.cancel:SetText("Cancel Scan");

    Wipe();
    
    self.module:Interrupt();
end

function PostingView:RegisterEvents()
    EventManager:On("POSTING_COMPLETE", PostingView.OnComplete);
    EventManager:On("POSTING_PRICE_SCAN", PostingView.OnPriceScan);
    EventManager:On("UPDATE", PostingView.Update);

    --EventManager:On("AUCTION_HOUSE_AUCTION_CREATED", PostingView.OnAuctionCreated);
    --EventManager:On("AUCTION_CANCELED", PostingView.OnAuctionCanceled);
    --EventManager:On("AUCTION_MULTISELL_FAILURE", PostingView.OnAuctionFailure);
end

function PostingView:UnregisterEvents()
    EventManager:Off("POSTING_COMPLETE", PostingView.OnComplete);
    EventManager:Off("POSTING_PRICE_SCAN", PostingView.OnPriceScan);
    EventManager:Off("UPDATE", PostingView.Update);

    --EventManager:Off("AUCTION_HOUSE_AUCTION_CREATED", PostingView.OnAuctionCreated);
    --EventManager:Off("AUCTION_CANCELED", PostingView.OnAuctionCanceled);
    --EventManager:Off("AUCTION_MULTISELL_FAILURE", PostingView.OnFailure);
end

function PostingView:OnHide()
    Tasker.Clear(TASKER_TAG);

    self:Stop();
    self:UnregisterEvents();
end

function PostingView:OnShow()
    self:RefreshTreeView();
    self:RegisterEvents();
end