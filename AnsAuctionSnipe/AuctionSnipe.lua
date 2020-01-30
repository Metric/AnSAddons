local Ans = select(2, ...);
local BaseData = AnsCore.API.BaseData;
local Query = AnsCore.API.GroupQuery;
local Recycler = AnsCore.API.GroupRecycler;
local AuctionList = Ans.AuctionList;
local Sources = AnsCore.API.Sources;
local TreeView = AnsCore.API.UI.TreeView;
local Utils = AnsCore.API.Utils;


local EVENTS_TO_REGISTER = {
    "AUCTION_HOUSE_BROWSE_RESULTS_ADDED",
    "AUCTION_HOUSE_BROWSE_RESULTS_UPDATED",
    "ITEM_SEARCH_RESULTS_ADDED",
    "ITEM_SEARCH_RESULTS_UPDATED",
    "COMMODITY_SEARCH_RESULTS_ADDED",
    "COMMODITY_SEARCH_RESULTS_UPDATED",
    "COMMODITY_PRICE_UPDATED",
    "COMMODITY_PRICE_UNAVAILABLE",
    "COMMODITY_PURCHASED",
    "COMMODITY_PURCHASE_FAILED",
    "COMMODITY_PURCHASE_SUCCEEDED",
    "ITEM_KEY_ITEM_INFO_RECEIVED",
    "GET_ITEM_INFO_RECEIVED"
};

local rootFrame = nil;

local DEFAULT_BROWSE_QUERY = {};
DEFAULT_BROWSE_QUERY.searchString = "";
DEFAULT_BROWSE_QUERY.minLevel = 0; -- zero = any
DEFAULT_BROWSE_QUERY.maxLevel = 0; -- zero = any
DEFAULT_BROWSE_QUERY.filters = {};
DEFAULT_BROWSE_QUERY.itemClassFilters = {};
DEFAULT_BROWSE_QUERY.sorts = {};

local DEFAULT_ITEM_SORT = { sortOrder = 0, reverseSort = false };

local STATES = {}
STATES.NONE = 0;
STATES.INIT = 1;
STATES.WAITING = 2;
STATES.FINDING = 3;
STATES.ITEMS = 4;
STATES.ITEMS_WAITING = 5;
STATES.INFO = 6;

AuctionSnipe = {};
AuctionSnipe.__index = AuctionSnipe;
AuctionSnipe.isInited = false;
AuctionSnipe.quality = 1;
AuctionSnipe.activeFilters = {};
AuctionSnipe.baseFilters = {};
AuctionSnipe.state = STATES.NONE;

local filterTreeViewItems = {};
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

local qualityFilters = {};
local classFilters = {};

local browseResults = {};
local itemsFound = {};
local currentItemScan = nil;
local validAuctions = {};
local infoKey = nil;
local scanIndex = 1;
local totalResultsFound = 0;

local needsToProcessPreviousScan = false;
local commodityConfirmTime = 0;

local lastScan = time();
local lastSuccessScan = time();
local lastResult = time();

BINDING_NAME_ANSSNIPEBUYSELECT = "Buy Selected Auction";
BINDING_NAME_ANSSNIPEBUYFIRST = "Buy First Auction";

local function GetOwners(result)
    if (#result.owners == 0) then
        return "";
    elseif (#result.owners == 1) then
        return result.owners[1];
    else
        return result.owners;
    end
end

local function ClearItemsFound()
    for i,v in ipairs(itemsFound) do
        Recycler:Recycle(v);
    end
    wipe(itemsFound);
end

local function ClearValidAuctions()
    wipe(validAuctions);
end

local function QualitySelected(self, arg1, arg2, checked)
    AuctionSnipe.quality = arg1;
    if (AuctionSnipe.qualityInput ~= nil) then
        UIDropDownMenu_SetText(AuctionSnipe.qualityInput, ITEM_QUALITY_COLORS[arg1].hex..AnsQualityToText[arg1]);
    end
    CloseDropDownMenus();
end

local function BuildQualityDropDown(frame, level, menuList)
    local info = UIDropDownMenu_CreateInfo();
    info.func = QualitySelected;
    local i;

    for i = 1, 5 do
        local c = ITEM_QUALITY_COLORS[i];
        local text = c.hex..AnsQualityToText[i];
        info.text, info.arg1 = text, i;
        UIDropDownMenu_AddButton(info);
    end
end

function AuctionSnipe:BuySelected()
    if (AuctionList) then
        AuctionList:BuySelected();
    end
end

function AuctionSnipe:BuyFirst()
    if (AuctionList) then
        AuctionList:BuyFirst();
    end
end

function AuctionSnipe:Init()
    local d = self;
    if (self.isInited) then
        return;
    end;

    self.isInited = true;

    --- create main panel
    local frame = CreateFrame("FRAME", "AnsSnipeMainPanel", AuctionHouseFrame, "AnsSnipeBuyTemplate");
    local this = self;
    self.frame = frame;

    frame:HookScript("OnShow", function() AuctionSnipe:Show() end);
    frame:HookScript("OnHide", function() AuctionSnipe:Close() end);

    -- new in 8.3 let the AH itself handle the tabs
    -- thanks to blizzard new tab implementation
    -- we only have to set the Key Value to the Frame
    -- Add a DisplayMode for the Frame and Tab
    AuctionHouseFrame["AnsSnipeMainPanel"] = frame;
    AuctionHouseFrameDisplayMode.Snipe = {"AnsSnipeMainPanel"};

    AuctionList:OnLoad(frame);

    AnsCore:AddAHTab("Snipe", AuctionHouseFrameDisplayMode.Snipe);

    self.filterTreeView = TreeView:New(_G[frame:GetName().."FilterList"], {
        rowHeight = 21,
        childIndent = 16, 
        template = "AnsFilterRowTemplate"
    }, function(item) d:ToggleFilter(item.filter) end);

    self.baseTreeView = TreeView:New(_G[frame:GetName().."BaseList"], {
        rowHeight = 21,
        childIndent = 16,
        template = "AnsFilterRowTemplate"
    }, function(item) d:ToggleBase(item.filter) end);

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

    self.searchInput = _G[frame:GetName().."SearchBarSearch"];
    self.snipeStatusText = _G[frame:GetName().."BottomBarStatus"];

    MoneyInputFrame_SetCopper(self.maxBuyoutInput, 0);
    self.minLevelInput:SetText("0");
    self.clevelRange:SetText("0-120");

    self.dingCheckBox:SetChecked(ANS_GLOBAL_SETTINGS.dingSound);
    self.maxPercentInput:SetText("100");

    UIDropDownMenu_Initialize(self.qualityInput, BuildQualityDropDown);
    UIDropDownMenu_SetText(self.qualityInput, ITEM_QUALITY_COLORS[1].hex.."Common");

    frame:Hide();
end

--- builds treeview item list from known filters
function AuctionSnipe:BuildTreeViewFilters()
    local filters = AnsCore.API.Filters;

    wipe(self.activeFilters);

    if (#filters < #filterTreeViewItems) then
        while (#filterTreeViewItems > #filters) do
            tremove(filterTreeViewItems);
        end
    end

    self:UpdateSubTreeFilters(filters, filterTreeViewItems);
end

function AuctionSnipe:BuildTreeViewBase()
    wipe(self.baseFilters);
    wipe(baseTreeViewItems);
    
    for k,v in ipairs(BaseData) do
        local pf = {};
        pf.selected = ANS_BASE_SELECTION[v.path] or false;
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
            sf.selected = ANS_BASE_SELECTION[s.path] or false;
            if (sf.selected) then
                tinsert(self.baseFilters, s);
            end
            sf.name = s.name;
            sf.expanded = false;
            sf.filter = s;
            sf.children = {};

            tinsert(pf.children, sf);

            local subchildren = v.children[i].children;
            for k = 1, #subchildren do
                local ss = subchildren[k];
                local ssf = {};
                ssf.selected = ANS_BASE_SELECTION[ss.path] or false;
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

function AuctionSnipe:UpdateSubTreeFilters(children, parent)
    for i, v in ipairs(children) do
        local pf = parent[i];

        if (pf) then
            pf.selected = ANS_FILTER_SELECTION[v:GetPath()] or false;

            if (pf.selected) then
                tinsert(self.activeFilters, v);
            end

            if (pf.name ~= v.name) then
                pf.expanded = false;
                pf.name = v.name;
                pf.filter = v;
                pf.children = {};

                if(#v.subfilters > 0) then
                    self:BuildSubTreeFilters(v.subfilters, pf.children);
                end
            else
                if(#v.subfilters > 0) then
                    if (#v.subfilters < #pf.children) then
                        while (#pf.children > #v.subfilters) do
                            tremove(pf.children);
                        end
                    end

                    self:UpdateSubTreeFilters(v.subfilters, pf.children);
                else
                    pf.children = {};
                end
            end
        else
            local t = {
                selected = ANS_FILTER_SELECTION[v:GetPath()] or false,
                name = v.name,
                expanded = false,
                filter = v,
                children = {}
            };

            if (t.selected) then
                tinsert(self.activeFilters, v);
            end

            if (#v.subfilters > 0) then
                self:BuildSubTreeFilters(v.subfilters, t.children);
            end
    
            tinsert(parent, t);
        end
    end
end

function AuctionSnipe:BuildSubTreeFilters(children, parent)
    for i,v in ipairs(children) do
        local t = {
            selected = ANS_FILTER_SELECTION[v:GetPath()] or false,
            name = v.name,
            expanded = false,
            filter = v,
            children = {}
        };

        if (t.selected) then
            tinsert(self.activeFilters, v);
        end

        if (#v.subfilters > 0) then
            self:BuildSubTreeFilters(v.subfilters, t.children);
        end

        tinsert(parent, t);
    end
end

--- do not use without first checking
--- the actual self.state
function AuctionSnipe:TryAndSearch()
    if (not currentItemScan) then
        return;
    end

    self.state = STATES.INFO;
    --before sending query GetItemInfo
    local _ = GetItemInfo(currentItemScan.id);

    if (_) then
        -- get itemKey info
        local info = C_AuctionHouse.GetItemKeyInfo(currentItemScan.itemKey);
        if (info) then
            self.state = STATES.ITEMS_WAITING;
            C_AuctionHouse.SendSearchQuery(currentItemScan.itemKey, DEFAULT_ITEM_SORT, false);
        end
    end
    -- if neither item info or item key info
    -- then we must wait for the events for item info or item key info
    -- then try again
    -- otherwise, the SendSearchQuery may fail for some unknown reason
    -- and will never trigger an event properly.
end

function AuctionSnipe:OnUpdate(frame, elapsed)
    if (self.frame) then   
        if (AuctionList.commodity ~= nil or AuctionList.isBuying) then
            -- show buying spinner
            if (self.processingFrame) then
                self.processingFrame:Show();
            end
        else
            -- hide buying spinner
            if (self.processingFrame) then
                self.processingFrame:Hide();
            end
        end
    end

    if (self.state == STATES.INIT) then
        local tdiff = time() - lastScan;
        local tdiff2 = time() - lastSuccessScan;
        local scanReady = tdiff >= ANS_GLOBAL_SETTINGS.rescanTime;
        local scanDelayReady = tdiff2 >= ANS_GLOBAL_SETTINGS.scanDelayTime;

        if (scanReady and scanDelayReady and self.state ~= STATES.WAITING 
            and AuctionList.commodity == nil and not AuctionList.isBuying) then
            
            currentItemScan = nil;
            self.fullBrowseResults = false;
            totalResultsFound = 0;
            needsToProcessPreviousScan = false;
            AuctionList.isPurchaseReady = false;
            scanIndex = 1;

            Sources:ClearValueCache();
            ClearItemsFound();
            ClearValidAuctions();
            wipe(browseResults);

            AuctionList:SetItems(validAuctions);
            
            self.state = STATES.WAITING;

            if (self.snipeStatusText) then
                self.snipeStatusText:SetText("Waiting for Results");
            end

            C_AuctionHouse.SendBrowseQuery(DEFAULT_BROWSE_QUERY);
        end
    elseif (self.state == STATES.FINDING) then
        AuctionList.isPurchaseReady = true;

        if (#browseResults == 0) then
            self.state = STATES.INIT;
            return;
        end

        local itemsPerUpdate = ANS_GLOBAL_SETTINGS.itemsPerUpdate;
        local count = 0;

        while (scanIndex <= #browseResults and count < itemsPerUpdate) do
            if (self.snipeStatusText) then
                self.snipeStatusText:SetText("Processed Groups "..(scanIndex + totalResultsFound));
            end

            local group = browseResults[scanIndex];
            local auction, noInfo = Query:IsFilteredGroupNoInfo(group);

            if (auction) then
                tinsert(itemsFound, auction);
            end

            scanIndex = scanIndex + 1;
            count = count + 1;
        end

        if (scanIndex > #browseResults and #itemsFound > 0) then
            if (self.fullBrowseResults) then

                if (self.snipeStatusText) then
                    self.snipeStatusText:SetText("Gathering Auctions");
                end

                self.state = STATES.ITEMS;
                scanIndex = 1;
                totalResultsFound = totalResultsFound + #browseResults;
                wipe(browseResults);
            else
                totalResultsFound = totalResultsFound + #browseResults;
                scanIndex = 1;
                wipe(browseResults);
                self.state = STATES.WAITING;
                C_AuctionHouse.RequestMoreBrowseResults();
            end
        elseif (scanIndex > #browseResults and #itemsFound == 0) then
            if (self.fullBrowseResults) then
                
                if (self.snipeStatusText) then
                    self.snipeStatusText:SetText("Waiting to Query");
                end

                scanIndex = 1;
                lastScan = time();
                self.state = STATES.INIT;
                wipe(browseResults);
            else
                totalResultsFound = totalResultsFound + #browseResults;
                scanIndex = 1;
                wipe(browseResults);
                self.state = STATES.WAITING;
                C_AuctionHouse.RequestMoreBrowseResults();
            end
        end
    elseif (self.state == STATES.ITEMS and AuctionList.commodity == nil and not AuctionList.isBuying) then
        if (time() - commodityConfirmTime < 2) then
            return;
        end

        if (needsToProcessPreviousScan) then
            if (currentItemScan and currentItemScan.itemKey) then
                self:TryAndSearch();
            else
                currentItemScan = itemsFound[scanIndex - 1];
                if (currentItemScan and currentItemScan.itemKey) then
                    self:TryAndSearch();
                end
            end 
            needsToProcessPreviousScan = false;
            return;
        end

        if (scanIndex <= #itemsFound) then
            if (validAuctions and #validAuctions > 0) then
                AuctionList:AddItems(validAuctions);
                ClearValidAuctions();
            end

            if (self.snipeStatusText) then
                self.snipeStatusText:SetText("Gathering Auctions "..scanIndex.." of "..#itemsFound..' out of '..totalResultsFound);
            end

            currentItemScan = itemsFound[scanIndex];
            scanIndex = scanIndex + 1;

            self:TryAndSearch();
        else
            if (validAuctions and #validAuctions > 0) then
                AuctionList:AddItems(validAuctions);
                ClearValidAuctions();
            end

            if (self.snipeStatusText) then
                self.snipeStatusText:SetText("Waiting to Query");
            end

            if (AuctionList:ItemsExist() and ANS_GLOBAL_SETTINGS.dingSound) then
                PlaySound(SOUNDKIT.AUCTION_WINDOW_OPEN, "Master");
            end

            if (AuctionList:ItemsExist()) then
                lastSuccessScan = time();
            end

            lastScan = time();
            self.state = STATES.INIT;
        end
    end
end

----
-- Events
---
function AuctionSnipe:RegisterEvents(frame)
    rootFrame = frame;

    frame:RegisterEvent("ADDON_LOADED");
    frame:RegisterEvent("AUCTION_HOUSE_SHOW");
    frame:RegisterEvent("AUCTION_HOUSE_CLOSED");
    --frame:RegisterEvent("PLAYER_MONEY");
end

function AuctionSnipe:EventHandler(frame, event, ...)
    if (event == "ADDON_LOADED") then self:OnAddonLoaded(...) end;

    if (event == "ITEM_KEY_ITEM_INFO_RECEIVED") then
        lastResult = time();
        local id = select(1, ...);
        if (currentItemScan and currentItemScan.id == id and self.state == STATES.INFO) then
            self:TryAndSearch();
        end
    elseif (event == "GET_ITEM_INFO_RECEIVED") then
        lastResult = time();
        local id = select(1, ...);
        if (currentItemScan and currentItemScan.id == id and self.state == STATES.INFO) then
            self:TryAndSearch();
        end
    end

    if (event == "AUCTION_HOUSE_BROWSE_RESULTS_UPDATED" or event == "AUCTION_HOUSE_BROWSE_RESULTS_ADDED") then
        self:OnBrowseResults(...);
    end
    if (event == "ITEM_SEARCH_RESULTS_UPDATED" or event == "ITEM_SEARCH_RESULTS_ADDED") then
        self:OnItemResults();
    end
    if (event == "COMMODITY_SEARCH_RESULTS_UPDATED" or event == "COMMODITY_SEARCH_RESULTS_ADDED") then
        self:OnCommidityResults();
    end
    if (event == "COMMODITY_PURCHASE_FAILED" or event == "COMMODITY_PURCHASED" or event == "COMMODITY_PURCHASE_SUCCEEDED") then
        AuctionList:OnCommondityPurchased(event == "COMMODITY_PURCHASE_FAILED");
        commodityConfirmTime = time();
        if (self.state == STATES.ITEMS_WAITING) then
            needsToProcessPreviousScan = true;
            self.state = STATES.ITEMS;
        end
    end 
    if (event == "COMMODITY_PRICE_UPDATED") then
        local unit, total = ...;
        if (not AuctionList:ConfirmCommoditiesPurchase(unit, total)) then
            commodityConfirmTime = time();
            if (self.state == STATES.ITEMS_WAITING) then
                needsToProcessPreviousScan = true;
                self.state = STATES.ITEMS;
            end
        end
    end
    if (event == "COMMODITY_PRICE_UNAVAILABLE") then
        AuctionList:CancelCommoditiesPurchase(true);
        commodityConfirmTime = time();
        if (self.state == STATES.ITEMS_WAITING) then
            needsToProcessPreviousScan = true;
            self.state = STATES.ITEMS;
        end
    end

    if (event == "AUCTION_HOUSE_SHOW") then self:OnAuctionHouseShow(); end;
    if (event == "AUCTION_HOUSE_CLOSED") then self:OnAuctionHouseClosed(); end;
end

function AuctionSnipe:OnItemResults() 
    if (currentItemScan and currentItemScan.itemKey) then
        local item = currentItemScan;
        item.isCommodity = false;

        local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemIcon, itemSellPrice, itemClassID, itemSubClassID, bindType, expacID, itemSetID, isCraftingReagent = GetItemInfo(item.id); 

        item.quality = itemRarity;
        item.name = itemName;
        item.link = itemLink;
        item.type = itemType;
        item.subtype = itemSubType;
        item.texture = itemIcon;
        item.vendorsell = itemSellPrice;

        if (not item.name) then
            if (self.state == STATES.ITEMS_WAITING) then
                self.state = STATES.ITEMS;
            end
            return;
        end

        if (not C_AuctionHouse.HasFullItemSearchResults(currentItemScan.itemKey)) then
            C_AuctionHouse.RequestMoreItemSearchResults(currentItemScan.itemKey);
            return;
        end

        for searchIndex = 1, C_AuctionHouse.GetNumItemSearchResults(currentItemScan.itemKey) do
            local result = C_AuctionHouse.GetItemSearchResultInfo(currentItemScan.itemKey, searchIndex);
            if (result.buyoutAmount) then
                item.count = result.quantity;
                item.ppu = result.buyoutAmount;
                item.buyoutPrice = result.buyoutAmount;
                item.owner = GetOwners(result);

                if (result.itemLink) then
                    item.link = result.itemLink;

                    if (Utils:IsBattlePetLink(item.link)) then
                        local info = Utils:ParseBattlePetLink(item.link);
                        item.name = info.name;
                        item.iLevel = info.level;
                        item.quality = info.breedQuality;
                        item.texture = info.icon;
                    end

                    item.tsmId = Utils:GetTSMID(item.link);
                end

                if (Query:IsFiltered(item)) then
                    item.auctionId = result.auctionID;
                    tinsert(validAuctions, item:Clone());
                end
            end
        end

        if (self.state == STATES.ITEMS_WAITING) then
            self.state = STATES.ITEMS;
        end
    end
end

function AuctionSnipe:OnCommidityResults()
    if (currentItemScan and currentItemScan.itemKey) then
        local item = currentItemScan;
        item.isCommodity = true;
        local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemIcon, itemSellPrice, itemClassID, itemSubClassID, bindType, expacID, itemSetID, isCraftingReagent = GetItemInfo(item.id); 
        item.quality = itemRarity;
        item.name = itemName;
        item.link = itemLink;
        item.type = itemType;
        item.subtype = itemSubType;
        item.texture = itemIcon;
        item.vendorsell = itemSellPrice;

        if (not item.name) then
            if (self.state == STATES.ITEMS_WAITING) then
                self.state = STATES.ITEMS;
            end
            return;
        end

        if (not C_AuctionHouse.HasFullCommoditySearchResults(currentItemScan.id)) then
            C_AuctionHouse.RequestMoreCommoditySearchResults(currentItemScan.id);
            return;
        end

        for searchIndex = 1, C_AuctionHouse.GetNumCommoditySearchResults(item.id) do
            local result = C_AuctionHouse.GetCommoditySearchResultInfo(item.id, searchIndex);
            item.count = result.quantity;
            item.ppu = result.unitPrice;
            item.buyoutPrice = result.unitPrice * result.quantity;
            item.owner = GetOwners(result);

            if (result.itemLink) then
                item.link = result.itemLink;
                item.tsmId = Utils:GetTSMID(item.link);
            end

            if (Query:IsFiltered(item)) then
                tinsert(validAuctions, item:Clone());
            else
                -- we can break here because it is sorted by price
                -- and thus if we find one that is not compatible
                -- we can give up sooner
                break;
            end
        end

        if (self.state == STATES.ITEMS_WAITING) then
            self.state = STATES.ITEMS;
        end
    end
end

function AuctionSnipe:OnBrowseResults(added)
    if (self.state ~= STATES.WAITING) then 
        return; 
    end

    if (added) then
        for i,v in ipairs(added) do
            tinsert(browseResults, v);
        end
    else
        browseResults = C_AuctionHouse.GetBrowseResults();
    end

    self.fullBrowseResults = C_AuctionHouse.HasFullBrowseResults();

    if (self.snipeStatusText) then
        self.snipeStatusText:SetText("Finding Deals...");
    end

    if (self.state == STATES.WAITING) then
        self.state = STATES.FINDING;
    end
end

function AuctionSnipe:OnAddonLoaded(...)
    local addonName = select(1, ...);
    if (addonName:lower() == "blizzard_auctionhouseui") then
        self:Init();
    end
end

function AuctionSnipe:OnAuctionHouseShow()
    if (self.isInited) then
        AuctionList:Clear();
    end
end   

function AuctionSnipe:OnAuctionHouseClosed()
    if (self.isInited) then
        self:Stop();
        self.baseTreeView:ReleaseView();
        self.filterTreeView:ReleaseView();
        Sources:ClearCache();
    end
end

local function RegisterEvents(frame, events) 
    for i,v in ipairs(events) do
        frame:RegisterEvent(v);
    end
end

local function UnregisterEvents(frame, events)
    for i,v in ipairs(events) do
        frame:UnregisterEvent(v);
    end
end

---
--- Close Handler
---

function AuctionSnipe:Close()
    if(self.frame and self.isInited) then
        UnregisterEvents(rootFrame, EVENTS_TO_REGISTER);
    end

    self:Stop();

    wipe(filterTreeViewItems);
    wipe(baseTreeViewItems);

    self.baseTreeView:ReleaseView();
    self.filterTreeView:ReleaseView();
end

--- 
--- Show Handler
---

function AuctionSnipe:Show()
    if (self.frame and self.isInited) then
        RegisterEvents(rootFrame, EVENTS_TO_REGISTER);
    end

    AuctionList:Clear();

    self:BuildTreeViewFilters();
    self.filterTreeView.items = filterTreeViewItems;
    self.filterTreeView:Refresh();

    self:BuildTreeViewBase();
    self.baseTreeView.items = baseTreeViewItems;
    self.baseTreeView:Refresh();
end

----
--- Button Handlers for Start & Stop 
---

function AuctionSnipe:LoadCLevelFilter()
    local range = self.clevelRange:GetText();

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
    local quality = self.quality;

    wipe(classFilters);
    wipe(qualityFilters);

    for i = quality, 5 do
        tinsert(qualityFilters, AnsQualityToAuctionEnum[i]);
    end

    for i = 1, #self.baseFilters do
        local item = self.baseFilters[i];

        if (item) then
            tinsert(classFilters, {classID = item.classID, subClassID = item.subClassID, inventoryType = item.inventoryType});
        end
    end
end

function AuctionSnipe:Start()
    self.startButton:Disable();
    self.stopButton:Enable();

    local maxBuyout = MoneyInputFrame_GetCopper(self.maxBuyoutInput) or 0;
    local ilevel = tonumber(self.minLevelInput:GetText()) or 0;
    local quality = self.quality;
    local maxPercent = tonumber(self.maxPercentInput:GetText()) or 100;

    local search = self.searchInput:GetText();
    
    self:LoadCLevelFilter();
    self:LoadBaseFilters();

    DEFAULT_BROWSE_QUERY.searchString = search;
    DEFAULT_BROWSE_QUERY.filters = qualityFilters;
    DEFAULT_BROWSE_QUERY.itemClassFilters = classFilters;

    scanIndex = 1;
    Query:AssignFilters(self.activeFilters, ilevel, maxBuyout, quality, maxPercent);
    self.state = STATES.INIT;
end

function AuctionSnipe:Stop()
    ClearValidAuctions(); 
    ClearItemsFound();
    wipe(browseResults);
    
    self.startButton:Enable();
    self.stopButton:Disable();
    self.state = STATES.NONE;
    
    if (self.snipeStatusText) then
        self.snipeStatusText:SetText("Stopped");
    end
end

---
--- Updates ding
---

function AuctionSnipe:DingSound(f)
    ANS_GLOBAL_SETTINGS.dingSound = f:GetChecked();
end

---
--- Handles removing / adding a selected filter
---

function AuctionSnipe:ClearFilters()
    wipe(ANS_FILTER_SELECTION);

    self:BuildTreeViewFilters();
    
    self.filterTreeView.items = filterTreeViewItems;
    self.filterTreeView:Refresh();
end

function AuctionSnipe:ClearBase()
    wipe(ANS_BASE_SELECTION);

    self:BuildTreeViewBase();
    
    self.baseTreeView.items = baseTreeViewItems;
    self.baseTreeView:Refresh();
end

function AuctionSnipe:ToggleFilter(f)
    local path = f:GetPath();
    if (ANS_FILTER_SELECTION[path]) then
        self:RemoveFilter(self.activeFilters, f);
        ANS_FILTER_SELECTION[path] = false;
    else
        tinsert(self.activeFilters, f);
        ANS_FILTER_SELECTION[path] = true;
    end
end

function AuctionSnipe:ToggleBase(f)
    if (ANS_BASE_SELECTION[f.path]) then
        self:RemoveFilter(self.baseFilters, f);
        ANS_BASE_SELECTION[f.path] = false;
    else
        tinsert(self.baseFilters, f);
        ANS_BASE_SELECTION[f.path] = true;
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