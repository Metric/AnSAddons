local Core = select(2, ...);
local Config = Ans.API.Config;
local Data = Ans.API.Data;
local BaseData = Ans.API.BaseData;
local Query = Ans.API.Auctions.Query;
local Recycler = Ans.API.Auctions.Recycler;
local AuctionList = Core.AuctionList;
local Sources = Ans.API.Sources;
local TreeView = Ans.API.UI.TreeView;
local Utils = Ans.API.Utils;
local Groups = Utils.Groups;
local EventManager = Ans.API.EventManager;

local SnipingOp = Ans.API.Operations.Sniping;

local Tasker = Ans.API.Tasker;
local Logger = Ans.API.Logger;

local TASKER_TAG = "SNIPER_WINDOW";
local PURCHASE_WAIT_TIME = 10;

local AHFrame = nil;
local AHFrameDisplayMode = nil;

local ERRORS = {
    ERR_ITEM_NOT_FOUND,
    ERR_AUCTION_DATABASE_ERROR
};

local rootFrame = nil;

local STATES = {};
STATES.NONE = 0;
STATES.RUNNING = 1;

local DEFAULT_BROWSE_QUERY = {};
DEFAULT_BROWSE_QUERY.searchString = "";
DEFAULT_BROWSE_QUERY.minLevel = 0; -- zero = any
DEFAULT_BROWSE_QUERY.maxLevel = 0; -- zero = any
DEFAULT_BROWSE_QUERY.filters = {};
DEFAULT_BROWSE_QUERY.itemClassFilters = {};
DEFAULT_BROWSE_QUERY.sorts = {};
DEFAULT_BROWSE_QUERY.quality = 1;

AuctionSnipe = {};
AuctionSnipe.__index = AuctionSnipe;
AuctionSnipe.isInited = false;
AuctionSnipe.activeOps = {};
AuctionSnipe.baseFilters = {};
AuctionSnipe.state = STATES.NONE;

local opTreeViewItems = {};
local baseTreeViewItems = {};

local AnsQualityToText = {};
AnsQualityToText[1] = "Common";
AnsQualityToText[2] = "Uncommon";
AnsQualityToText[3] = "Rare";
AnsQualityToText[4] = "Epic";
AnsQualityToText[5] = "Legendary";

local AnsQualityToAuctionEnum = {};
AnsQualityToAuctionEnum[1] = 5;
AnsQualityToAuctionEnum[2] = 6;
AnsQualityToAuctionEnum[3] = 7;
AnsQualityToAuctionEnum[4] = 8;
AnsQualityToAuctionEnum[5] = 9;

AuctionSnipe.AnsQualityToText = AnsQualityToText;
AuctionSnipe.AnsQualityToAuctionEnum = AnsQualityToAuctionEnum;

-- holders for quality filters etc
local qualityFilters = {};
local qualityQueryFilters = {};
local classFilters = {};

-- last known item for stuff
local currentItem = nil;

-- counters and flags for 
-- search results
local totalResultsFound = 0;
local totalGroups = 0;
local last = 0;
local clearNew = true;

-- local ERR_AUCTION_WON = gsub(ERR_AUCTION_WON_S or "", "%%s", "");

-- this dialog is used when in browse query
-- and you try to buy an auction
-- when this is displayed we are out of 
-- then browse state and have entered
-- a viable search state to purchase
StaticPopupDialogs["ANSCONFIRMAUCTION"] = {
    text = "Purchase %s for %s?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function(self)
        local auction = self.data.auction;
        AuctionList:Purchase(auction);
    end,
    OnCancel = function()
        
    end,
    timeout = 0,
    whileDead = false,
    hideOnEscape = true,
    preferredIndex = 3
};

-- local function QualitySelected(self, arg1, arg2, checked)
--    local qualities = Config.Sniper().qualities;
--    if (not Utils.IsClassic()) then
--        if (checked) then
--            Config.Sniper().minQuality = arg1;
--            if (AuctionSnipe.qualityInput ~= nil) then
--                UIDropDownMenu_SetText(AuctionSnipe.qualityInput, ITEM_QUALITY_COLORS[arg1].hex..AnsQualityToText[arg1]);
--            end
--        end
--        qualities[arg1] = checked;
--    else
--        Config.Sniper().minQuality = arg1;
--        if (AuctionSnipe.qualityInput ~= nil) then
--            UIDropDownMenu_SetText(AuctionSnipe.qualityInput, ITEM_QUALITY_COLORS[arg1].hex..AnsQualityToText[arg1]);
--        end
--    end

--    if (Utils.IsClassic()) then
--        CloseDropDownMenus();
--    end
-- end

local function BuildQualityDropDown(frame, level, menuList)
    local i;

    local module = AuctionSnipe.module;
    local qualities = Config.Sniper().qualities;
    for i = 1, 5 do
        local info = UIDropDownMenu_CreateInfo();
        info.func = module.QualitySelected;

        local c = ITEM_QUALITY_COLORS[i];
        local text = c.hex..AnsQualityToText[i];
        info.text, info.arg1 = text, i;
        if (not Utils.IsClassic()) then
            info.keepShownOnClick = true;
            info.checked = qualities[i];
            info.isNotRadio = true;
            info.value = i;
        end
        UIDropDownMenu_AddButton(info);
    end
end

function AuctionSnipe:BuySelected()
    if (not self.isInited or not AuctionList) then
        return;
    end

    AuctionList:BuySelected();

    -- if (AuctionList and SniperFSM and AuctionList.selectedItem
    --    and SniperFSM and SniperFSM.current ~= "NONE" and SniperFSM.current ~= "START_BUYING"
    --    and SniperFSM.current ~= "BUYING" and not AuctionList.auction) then
        -- interrupt current query fsm
    --    Query.Clear();
    --    if ((SniperFSM.current == "ITEMS" and lastItemId and AuctionList:IsSelectedSameAsLastId(lastItemId)) or Utils.IsClassic() 
    --    or (SniperFSM.current == "IDLE" and Query.lastQueryType == "SEARCH"  and lastItemId and AuctionList:IsSelectedSameAsLastId(lastItemId))) then
    --        AuctionList:BuySelected(true);
    --    else
    --        AuctionList:BuySelected();
    --    end
    --    self:StartBuyState();
    -- end
end

function AuctionSnipe:BuyFirst()
    if (not self.isInited or not AuctionList) then
        return;
    end

    AuctionList:BuyFirst();

    -- if (AuctionList and SniperFSM and #AuctionList.items > 0 
    --    and SniperFSM and SniperFSM.current ~= "NONE" and SniperFSM.current ~= "START_BUYING"
    --    and SniperFSM.current ~= "BUYING" and not AuctionList.auction) then
        -- interrupt current query fsm
    --    Query.Clear();
    --    if ((SniperFSM.current == "ITEMS" and lastItemId and AuctionList:IsFirstSameAsLastId(lastItemId)) or Utils.IsClassic() 
    --    or (SniperFSM.current == "IDLE" and Query.lastQueryType == "SEARCH" and lastItemId and AuctionList:IsFirstSameAsLastId(lastItemId))) then
    --        AuctionList:BuyFirst(true);
    --    else
    --        AuctionList:BuyFirst();
    --    end
    --    self:StartBuyState();
    -- end
end

function AuctionSnipe:Init()
    local d = self;
    if (self.isInited) then
        return;
    end;

    -- bug fix for qualities if you switch between classic and retail
    -- sadly your last qualities will be lost on this for the moment
    -- will change this eventually to separate quality configs
    -- for classic / retail
    if (Config.Sniper().classicMode ~= Utils.IsClassic()) then
        Config.Sniper().qualities = {};
        Config.Sniper().minQuality = 1;
    end

    Config.Sniper().classicMode = Utils.IsClassic();

    local snipeTemplate = "AnsSnipeBuyTemplate";
    local snipeFilterTemplate = "AnsFilterRowTemplate";

    if (Utils.IsClassic()) then
        snipeTemplate = "AnsSnipeBuyClassicTemplate";
        snipeFilterTemplate = "AnsFilterRowClassicTemplate";
    end

    self.isInited = true;

    --- create main panel
    local frame = CreateFrame("FRAME", "AnsSnipeMainPanel", AHFrame, snipeTemplate);

    local this = self;
    self.frame = frame;

    frame:HookScript("OnShow", function() AuctionSnipe:Show() end);
    frame:HookScript("OnHide", function() AuctionSnipe:Close() end);

    -- new in 8.3 let the AH itself handle the tabs
    -- thanks to blizzard new tab implementation
    -- we only have to set the Key Value to the Frame
    -- Add a DisplayMode for the Frame and Tab

    AHFrame["AnsSnipeMainPanel"] = frame;
    AHFrameDisplayMode.Snipe = {"AnsSnipeMainPanel"};

    AuctionList:OnLoad(frame);
    AuctionList.module = self.module;

    Ans:AddAHTab("Snipe", AHFrameDisplayMode.Snipe);

    self.filterTreeView = TreeView:Acquire(_G[frame:GetName().."FilterList"], {
        rowHeight = 21,
        childIndent = 16,
        template = snipeFilterTemplate, multiselect = true
    }, function(item)
        if (item.filter and not item.group) then 
            d:ToggleFilter(item.filter)
        elseif (item.filter and item.group) then
            d:ToggleGroup(item.filter, item.group);
        end 
    end);

    self.baseTreeView = TreeView:Acquire(_G[frame:GetName().."BaseList"], {
        rowHeight = 21,
        childIndent = 16,
        template = snipeFilterTemplate, multiselect = true
    }, function(item) d:ToggleBase(item.filter) end);

    if (Utils.IsClassic()) then
        self.baseTreeView:Hide();
    end

    self.startButton = _G[frame:GetName().."BottomBarStart"];
    self.stopButton = _G[frame:GetName().."BottomBarStop"];

    self.startButton:Enable();
    self.stopButton:Disable();

    self.maxBuyoutInput = _G[frame:GetName().."SearchBarMaxPPU"];
    self.minLevelInput = _G[frame:GetName().."SearchBarMinLevel"];
    self.clevelRange = _G[frame:GetName().."SearchBarLevelRange"];
    self.qualityInput = _G[frame:GetName().."SearchBarQuality"];
    self.maxPercentInput = _G[frame:GetName().."SearchBarMaxPercent"];
    self.dingCheckBox = _G[frame:GetName().."SearchBarDingSound"];
    self.processingFrame = _G[frame:GetName().."ResultsProcessing"];
    self.processingFrame:Hide();

    self.searchInput = _G[frame:GetName().."SearchBarSearch"];
    self.snipeStatusText = _G[frame:GetName().."BottomBarStatus"];

    MoneyInputFrame_SetCopper(self.maxBuyoutInput, 0);
    self.minLevelInput:SetText("0");
    self.clevelRange:SetText("0-120");

    self.dingCheckBox:SetChecked(Config.Sniper().dingSound);
    self.maxPercentInput:SetText("100");

    local quality = Config.Sniper().minQuality;

    UIDropDownMenu_Initialize(self.qualityInput, BuildQualityDropDown);
    UIDropDownMenu_SetText(self.qualityInput, ITEM_QUALITY_COLORS[quality].hex..AnsQualityToText[quality]);

    frame:Hide();
end

--- builds treeview item list from known filters
function AuctionSnipe:BuildTreeViewFilters()
    local ops = Config.Operations().Sniping or {};

    wipe(opTreeViewItems);
    wipe(self.activeOps);

    for i,v in ipairs(ops) do
        local pf = {};
        pf.selected = Config.SelectionSniper()[v.id] or false;
        if (pf.selected) then
            tinsert(self.activeOps, v);
        end
        pf.name = v.name;
        pf.expanded = false;
        pf.children = {};
        pf.filter = v;

        v.nonActiveGroups = v.nonActiveGroups or {};

        for i,v2 in ipairs(v.groups) do
            local g = Groups.GetGroupFromId(v2);
            if (g) then
                tinsert(pf.children, {
                    name = g.path,
                    selected = (not v.nonActiveGroups[v2]),
                    expanded = false,
                    children = {},
                    group = v2,
                    filter = v
                });
            end
        end

        tinsert(opTreeViewItems, pf);
    end
end

function AuctionSnipe:BuildTreeViewBase()
    wipe(self.baseFilters);
    wipe(baseTreeViewItems);
    
    for k,v in ipairs(BaseData) do
        local pf = {};
        pf.selected = Config.SelectionBase()[v.path] or false;
        if (pf.selected) then
            tinsert(self.baseFilters, v);
        end
        pf.name = v.name;
        pf.expanded = false;
        pf.filter = v;
        pf.children = {};

        for i = 1, #v.children do
            local s = v.children[i];
            local sf = {};
            sf.selected = Config.SelectionBase()[s.path] or false;
            if (sf.selected) then
                tinsert(self.baseFilters, s);
            end
            sf.name = s.name;
            sf.expanded = false;
            sf.filter = s;
            sf.children = {};

            tinsert(pf.children, sf);

            local subchildren = v.children[i].children;
            for j = 1, #subchildren do
                local ss = subchildren[j];
                local ssf = {};
                ssf.selected = Config.SelectionBase()[ss.path] or false;
                if (ssf.selected) then
                    tinsert(self.baseFilters, ss);
                end
                ssf.name = ss.name;
                ssf.expanded = false;
                ssf.filter = ss;
                ssf.children = {};

                tinsert(sf.children, ssf);
            end
        end

        tinsert(baseTreeViewItems, pf);
    end
end

function AuctionSnipe:Sort(type)
    AuctionList:Sort(type);
end

function AuctionSnipe.OnPreviousComplete()
    if (AuctionSnipe.state == STATES.NONE) then
        return;
    end
    
    current = nil;
    AuctionSnipe:NextPriceScan(0, last);
end

function AuctionSnipe.OnPurchaseConfirm(remove, auction, count)
    AuctionList:OnPurchaseConfirm(remove, auction, count);
end

function AuctionSnipe.OnPurchaseStart()
    AuctionList:OnPurchaseStart();
end

function AuctionSnipe.OnGroupScan(count)
    local module = AuctionSnipe.module;

    totalGroups = count;
    last = totalGroups;

    if (count <= 0) then
        AuctionSnipe:NextGroupScan(0);
        return;
    end

    AuctionSnipe:NextPriceScan(0, last);
end

function AuctionSnipe.PrintResults(results)
    local isAllowed = Config.Sniper().chatMessageNew;
    if (not isAllowed) then
        return;
    end
    for i,v in ipairs(results) do
        local isOkay = v.link and v.count and v.ppu and v.count > 0;
        if (isOkay) then
            print("AnS - New Snipe Available: "..v.link.." x "..v.count.." for "..Utils.PriceToString(v.ppu).."|cFFFFFFFF ppu from "..(v.owner or "?")); 
        end
    end
end

function AuctionSnipe.OnPriceScan(results, left)
    local wait = Config.Sniper().scanDelay;
    local module = AuctionSnipe.module;
    local t = #results;

    totalResultsFound = totalResultsFound + t;

    if (t > 0) then
        if (not Utils.IsClassic()) then
            AuctionList:AddItems(results, clearNew);
            clearNew = false;
        else
            AuctionList:SetItems(results);
            AuctionSnipe.PrintResults(results);
        end
    else
        wait = 0;
    end

    if (not Utils.IsClassic()) then
        AuctionList:ClearMissing(currentItem, module.known);
    end

    last = left;

    if (left > 0) then
        if (Utils.IsClassic()) then
            AuctionSnipe.FoundNotification(t);
        else
            wait = 0;
        end

        AuctionSnipe:NextPriceScan(wait, left);
        return;
    end

    AuctionSnipe.FoundNotification(totalResultsFound);
    AuctionSnipe:NextGroupScan(wait);
end

function AuctionSnipe.FoundNotification(count)
    if (count <= 0) then
        return;
    end

    local flash = Config.Sniper().flashWoWIcon;
    local ding = Config.Sniper().dingSound;
    local sound = Config.Sniper().soundKitSound;
    if (ding) then
        PlaySound(SOUNDKIT[sound], "Master");
    end
    if (flash) then
        FlashClientIcon();
    end
end

function AuctionSnipe:UpdateScanStatus(left, total)
     local c = (total - left) + 1;
     local module = self.module;
     local text = module.GetScanText(c, total);
     self.snipeStatusText:SetText(text);
end

function AuctionSnipe:NextPriceScan(wait, left)
    local this = self;
    if (self.state == STATES.NONE) then
        return;
    end

    self.snipeStatusText:SetText("Waiting...");

    local module = self.module;
    Tasker.Delay(GetTime() + wait, function()
        this:UpdateScanStatus(left, totalGroups);
        local item = module:PriceScan(AuctionList.IsKnown);
        
        if (not item) then
            this:NextGroupScan(0);
            return;
        end

        currentItem = item:Clone();
    end, TASKER_TAG);
end

function AuctionSnipe:NextGroupScan(wait)
    if (self.state == STATES.NONE) then
        return;
    end

    currentItem = nil;
    clearNew = true;
    totalResultsFound = 0;
    totalGroups = 0;
    last = 0;

    self.snipeStatusText:SetText("Waiting...");

    local module = self.module;
    Tasker.Delay(GetTime() + wait, function()
        self.snipeStatusText:SetText("Querying...");
        module:GroupScan(DEFAULT_BROWSE_QUERY);
    end, TASKER_TAG);
end

-- function AuctionSnipe.OnCommodityDialogCancel()
--    SniperFSM:Process("CONFIRMED_AUCTION");
-- end

-- function AuctionSnipe.OnChatMessage(msg)
--    Logger.Log("SNIPER", "OnChatMessage: "..msg);
--    if (not SniperFSM or not AuctionSnipe.frame or not AuctionSnipe.frame:IsShown()) then
--        Logger.Log("SNIPER", "OnChatMessage: no frame / FSM");
--        return;
--    end

--    if (strfind(msg, ERR_AUCTION_BID_PLACED) or strfind(msg, ERR_AUCTION_WON)) then
--        Logger.Log("SNIPER", "Received BID PLACED Message");
--        SniperFSM:Process("CONFIRMED_AUCTION");
--    end
-- end

--- handle errors for buying ---
-- function AuctionSnipe.OnErrorMessage(type, msg)
--    Logger.Log("SNIPER", "OnErrorMessage: "..msg);
--    if (not SniperFSM or not AuctionSnipe.frame or not AuctionSnipe.frame:IsShown() or not AuctionList) then
--        Logger.Log("SNIPER", "OnErrorMessage: no frame / FSM");
--        return;
--    end
--    if (SniperFSM.current == "BUYING" and Utils.InTable(ERRORS, msg)) then
--        Logger.Log("SNIPER", "Item Purchased Failed with: "..msg);
--        AuctionList:ConfirmAuctionPurchase();
--        SniperFSM:Process("CANCEL_AUCTION");
--    end
-- end

function AuctionSnipe:RegisterSniperEvents()
    EventManager:On("SNIPER_PRICE_SCAN", AuctionSnipe.OnPriceScan);
    EventManager:On("SNIPER_GROUP_SCAN", AuctionSnipe.OnGroupScan);
    EventManager:On("PURCHASE_COMPLETE", AuctionSnipe.OnPurchaseConfirm);
    EventManager:On("PURCHASE_START", AuctionSnipe.OnPurchaseStart);
    EventManager:On("QUERY_PREVIOUS_COMPLETED", AuctionSnipe.OnPreviousComplete);
end

function AuctionSnipe:UnregisterSniperEvents()
    EventManager:Off("SNIPER_PRICE_SCAN", AuctionSnipe.OnPriceScan);
    EventManager:Off("SNIPER_GROUP_SCAN", AuctionSnipe.OnGroupScan);
    EventManager:Off("PURCHASE_COMPLETE", AuctionSnipe.OnPurchaseConfirm);
    EventManager:Off("PURCHASE_START", AuctionSnipe.OnPurchaseStart);
    EventManager:Off("QUERY_PREVIOUS_COMPLETED", AuctionSnipe.OnPreviousComplete);
end

function AuctionSnipe:OnUpdate(frame, elapsed)
    local module = self.module;
    if (not module) then
        return;
    end  
    module:Process();
end


----
-- Events
---
function AuctionSnipe:RegisterEvents(frame)
    rootFrame = frame;
    frame:RegisterEvent("ADDON_LOADED");
    frame:RegisterEvent("AUCTION_HOUSE_SHOW");
    frame:RegisterEvent("AUCTION_HOUSE_CLOSED");
end

function AuctionSnipe:EventHandler(frame, event, ...)
    if (event == "ADDON_LOADED") then self:OnAddonLoaded(...) end;
    if (event == "AUCTION_HOUSE_SHOW") then self:OnAuctionHouseShow(); end;
    if (event == "AUCTION_HOUSE_CLOSED") then self:OnAuctionHouseClosed(); end;
end

function AuctionSnipe:OnAddonLoaded(...)
    local addonName = select(1, ...);
    if (addonName:lower() == "blizzard_auctionhouseui" or addonName:lower() == "blizzard_auctionui") then
        AHFrame = AuctionHouseFrame or AuctionFrame;
        AHFrameDisplayMode = AuctionHouseFrameDisplayMode or {};
        self:Init();
    end
end

function AuctionSnipe:OnAuctionHouseShow()
end   

function AuctionSnipe:OnAuctionHouseClosed()
    if (not self.isInited) then
        return;
    end

    self:UnregisterSniperEvents();

    self:Stop();
    
    -- clear any confirmation views
    -- in the list view
    AuctionList:ClearConfirms();

    Query.ClearTempBlacklist();
    AuctionList:Recycle();
    
    self.baseTreeView:ReleaseView();
    self.filterTreeView:ReleaseView();

    local module = self.module;
    module.Wipe();
end

---
--- Close Handler
---

function AuctionSnipe:Close()
    if (not self.frame or not self.isInited) then
        return;
    end

    self:UnregisterSniperEvents();

    -- StaticPopup_Hide("ANSCONFIRMAUCTION");
    -- AuctionList.auction = nil;
    -- AuctionList.commodity = nil;
    -- AuctionList.isBuying = nil;

    self:Stop();

    -- clear any confirmation views
    -- in the list view
    AuctionList:ClearConfirms();

    wipe(opTreeViewItems);
    wipe(baseTreeViewItems);

    self.baseTreeView:ReleaseView();
    self.filterTreeView:ReleaseView();

    if (Utils.IsClassic()) then
        AuctionList:Recycle();
    end 
end

--- 
--- Show Handler
---

function AuctionSnipe:Show()
    if (not self.frame or not self.isInited) then
        return;
    end

    self:RegisterSniperEvents();

    self:BuildTreeViewFilters();
    self.filterTreeView.items = opTreeViewItems;
    self.filterTreeView:Refresh();

    self:BuildTreeViewBase();
    self.baseTreeView.items = baseTreeViewItems;
    self.baseTreeView:Refresh();

    self.clevelRange:SetText(Config.Sniper().clevel);
    self.minLevelInput:SetText(Config.Sniper().ilevel);
end

----
--- Button Handlers for Start & Stop 
---

function AuctionSnipe:LoadCLevelFilter()
    local range = self.clevelRange:GetText();

    Config.Sniper().clevel = range;

    if (range) then
        local low, high = strsplit("-", range);
        if (low == nil and high == nil) then
            DEFAULT_BROWSE_QUERY.minLevel = 0;
            DEFAULT_BROWSE_QUERY.maxLevel = 0;
        elseif (low ~= nil and high ~= nil) then
            DEFAULT_BROWSE_QUERY.minLevel = tonumber(low);
            DEFAULT_BROWSE_QUERY.maxLevel = tonumber(high);
        elseif (low ~= nil and high == nil) then
            DEFAULT_BROWSE_QUERY.minLevel = tonumber(low);
            DEFAULT_BROWSE_QUERY.maxLevel = 0;
        end
    else
        DEFAULT_BROWSE_QUERY.minLevel = 0;
        DEFAULT_BROWSE_QUERY.maxLevel = 0;
    end
end

function AuctionSnipe:LoadBaseFilters()
    local quality = Config.Sniper().qualities;

    if (Utils.IsClassic()) then
        wipe(quality);
        quality[Config.Sniper().minQuality] = true;
    end

    DEFAULT_BROWSE_QUERY.quality = Config.Sniper().minQuality;

    wipe(classFilters);
    wipe(qualityFilters);
    wipe(qualityQueryFilters);

    for i,v in pairs(quality) do
        if (v) then
            tinsert(qualityQueryFilters, i);
            tinsert(qualityFilters, AnsQualityToAuctionEnum[i]);
        end
    end

    table.sort(qualityQueryFilters, function(a,b) 
        return a > b;
    end);

    for i = 1, #self.baseFilters do
        local item = self.baseFilters[i];

        if (item) then
            if (Utils.IsClassic()) then
                tinsert(classFilters, {classID = item.classID, subClassID = item.subClassID, inventoryType = item.inventoryType});
            else
                if (item.inventoryType == Data.RUNECARVING) then
                    tinsert(qualityFilters, Enum.AuctionHouseFilter.LegendaryCraftedItemOnly);
                    tinsert(classFilters, {classID = item.classID, subClassID = item.subClassID, inventoryType = nil});
                else
                    tinsert(classFilters, {classID = item.classID, subClassID = item.subClassID, inventoryType = item.inventoryType});
                end
            end
        end
    end
end

function AuctionSnipe:Start()
    if (not self.isInited) then
        return;
    end

    self.startButton:Disable();
    self.stopButton:Enable();

    local maxBuyout = MoneyInputFrame_GetCopper(self.maxBuyoutInput) or 0;
    local ilevel = tonumber(self.minLevelInput:GetText()) or 0;
    local maxPercent = tonumber(self.maxPercentInput:GetText()) or 100;

    local search = self.searchInput:GetText();
    local module = self.module;

    Config.Sniper().ilevel = ilevel;

    self:LoadCLevelFilter();
    self:LoadBaseFilters();

    Sources:Clear();

    DEFAULT_BROWSE_QUERY.searchString = search;
    DEFAULT_BROWSE_QUERY.filters = qualityFilters;
    DEFAULT_BROWSE_QUERY.itemClassFilters = classFilters;

    local module = self.module;

    -- apply classic sort to get 
    -- item sorted by most recent time
    -- posted
    -- if (Utils.IsClassic()) then
    --    SortAuctionClearSort("list");
    --    SortAuctionApplySort("list");
    -- end

    local ops = {};

    for i,v in ipairs(self.activeOps) do
        tinsert(ops, SnipingOp.From(v));
    end

    Query:AssignDefaults(ops);
    module.SetOptions(ilevel, maxBuyout, qualityQueryFilters, maxPercent);
    
    self.state = STATES.RUNNING;
    self:NextGroupScan(0);
end

function AuctionSnipe:Stop()
    if (not self.isInited) then
        return;
    end

    self.state = STATES.NONE;

    local module = self.module;
    module:Interrupt();

    Tasker.Clear(TASKER_TAG);

    self.startButton:Enable();
    self.stopButton:Disable();
    
    if (self.snipeStatusText) then
        self.snipeStatusText:SetText("Stopped");
    end
end

---
--- Updates ding
---

function AuctionSnipe:DingSound(f)
    Config.Sniper().dingSound = f:GetChecked();
end

---
--- Handles removing / adding a selected filter
---

function AuctionSnipe:ClearFilters()
    wipe(Config.SelectionSniper());

    self:BuildTreeViewFilters();
    
    self.filterTreeView.items = opTreeViewItems;
    self.filterTreeView:Refresh();
end

function AuctionSnipe:ClearBase()
    wipe(Config.SelectionBase());

    self:BuildTreeViewBase();
    
    self.baseTreeView.items = baseTreeViewItems;
    self.baseTreeView:Refresh();
end

function AuctionSnipe:ToggleFilter(f)
    if (Config.SelectionSniper()[f.id]) then
        self:RemoveFilter(self.activeOps, f);
        Config.SelectionSniper()[f.id] = false;
    else
        tinsert(self.activeOps, f);
        Config.SelectionSniper()[f.id] = true;
    end
end

function AuctionSnipe:ToggleGroup(f, g)
    if (f.nonActiveGroups[g]) then
        f.nonActiveGroups[g] = nil;
    else
        f.nonActiveGroups[g] = true;
    end
end

function AuctionSnipe:ToggleBase(f)
    if (Config.SelectionBase()[f.path]) then
        self:RemoveFilter(self.baseFilters, f);
        Config.SelectionBase()[f.path] = false;
    else
        tinsert(self.baseFilters, f);
        Config.SelectionBase()[f.path] = true;
    end
end

function AuctionSnipe:RemoveFilter(filters, f)
    for i, v in ipairs(filters) do
        if (v == f) then
            tremove(filters, i);
            return;
        end
    end
end