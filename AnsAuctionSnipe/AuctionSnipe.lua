local Ans = select(2, ...);
local Config = AnsCore.API.Config;
local BaseData = AnsCore.API.BaseData;
local Query = AnsCore.API.Auctions.Query;
local Recycler = AnsCore.API.Auctions.Recycler;
local AuctionList = Ans.AuctionList;
local Sources = AnsCore.API.Sources;
local TreeView = AnsCore.API.UI.TreeView;
local Utils = AnsCore.API.Utils;

local EVENTS_TO_REGISTER = {};

local AHFrame = nil;
local AHFrameDisplayMode = nil;

if (Utils:IsClassic()) then
    EVENTS_TO_REGISTER = {
        "AUCTION_ITEM_LIST_UPDATE"
    };
else
    EVENTS_TO_REGISTER = {
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
        "GET_ITEM_INFO_RECEIVED",
        "AUCTION_HOUSE_THROTTLED_MESSAGE_RESPONSE_RECEIVED",
        "AUCTION_HOUSE_THROTTLED_MESSAGE_DROPPED",
        "AUCTION_HOUSE_THROTTLED_MESSAGE_SENT",
        "AUCTION_HOUSE_THROTTLED_MESSAGE_QUEUED"
    };
end


local rootFrame = nil;

local DEFAULT_BROWSE_QUERY = {};
DEFAULT_BROWSE_QUERY.searchString = "";
DEFAULT_BROWSE_QUERY.minLevel = 0; -- zero = any
DEFAULT_BROWSE_QUERY.maxLevel = 0; -- zero = any
DEFAULT_BROWSE_QUERY.filters = {};
DEFAULT_BROWSE_QUERY.itemClassFilters = {};
DEFAULT_BROWSE_QUERY.sorts = {};
DEFAULT_BROWSE_QUERY.quality = 1;

local DEFAULT_ITEM_SORT = { sortOrder = 0, reverseSort = false };

local STATES = {}
STATES.NONE = 0;
STATES.INIT = 1;
STATES.WAITING = 2;
STATES.FINDING = 3;
STATES.ITEMS = 4;
STATES.ITEMS_WAITING = 5;
STATES.INFO = 6;
STATES.SEARCH = 7;
STATES.SEARCH_MORE = 8;
STATES.BROWSE_MORE = 9;
STATES.CONFIRM_COMMODITY = 10;
STATES.CANCEL_COMMODITY = 11;
STATES.UPDATING_COMMODITY = 12;
STATES.WAITING_COMMODITY_PURCHASE = 13;

AuctionSnipe = {};
AuctionSnipe.__index = AuctionSnipe;
AuctionSnipe.isInited = false;
AuctionSnipe.quality = 1;
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

local qualityFilters = {};
local classFilters = {};

local browseResults = {};
local itemsFound = {};
local currentItemScan = nil;
local validAuctions = {};
local infoKey = nil;

local scanIndex = 1;
local totalResultsFound = 0;
local totalValidAuctionsFound = 0;

local seenResults = {};
local throttleMessageReceived = true;
local throttleWaitingForSend = false;
local throttleTime = time();

local lastSuccessScan = time();
local blocks = {};
local blockList = {};

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

    local snipeTemplate = "AnsSnipeBuyTemplate";
    local snipeFilterTemplate = "AnsFilterRowTemplate";

    if (Utils:IsClassic()) then
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

    AnsCore:AddAHTab("Snipe", AHFrameDisplayMode.Snipe);

    self.filterTreeView = TreeView:New(_G[frame:GetName().."FilterList"], {
        rowHeight = 21,
        childIndent = 16,
        template = snipeFilterTemplate, multiselect = true
    }, function(item) d:ToggleFilter(item.filter) end);

    self.baseTreeView = TreeView:New(_G[frame:GetName().."BaseList"], {
        rowHeight = 21,
        childIndent = 16,
        template = snipeFilterTemplate, multiselect = true
    }, function(item) d:ToggleBase(item.filter) end);

    if (Utils:IsClassic()) then
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

    self.searchInput = _G[frame:GetName().."SearchBarSearch"];
    self.snipeStatusText = _G[frame:GetName().."BottomBarStatus"];

    MoneyInputFrame_SetCopper(self.maxBuyoutInput, 0);
    self.minLevelInput:SetText("0");
    self.clevelRange:SetText("0-120");

    self.dingCheckBox:SetChecked(Config.Sniper().dingSound);
    self.maxPercentInput:SetText("100");

    UIDropDownMenu_Initialize(self.qualityInput, BuildQualityDropDown);
    UIDropDownMenu_SetText(self.qualityInput, ITEM_QUALITY_COLORS[1].hex.."Common");

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

function AuctionSnipe:TryAndSearch()
    if (self:IsThrottled()) then
        return;
    end

    if (self.state ~= STATES.SEARCH) then
        return;    
    end

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
            C_AuctionHouse.SendSearchQuery(currentItemScan.itemKey, DEFAULT_ITEM_SORT, true);
        end
    end
    -- if neither item info or item key info
    -- then we must wait for the events for item info or item key info
    -- then try again
    -- otherwise, the SendSearchQuery may fail for some unknown reason
    -- and will never trigger an event properly.
end

function AuctionSnipe:IsThrottled()
    return time() - throttleTime < 5;
end

function AuctionSnipe:OnUpdate(frame, elapsed)
    if (Utils:IsClassic()) then
        self:OnClassicUpdate();
    else
        self:OnRetailUpdate();
    end    
end

function AuctionSnipe:OnClassicUpdate()
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
        local tdiff = time() - lastSuccessScan;
        local tdiff2 = time() - AuctionList.lastBuyTry;
        local ready = tdiff >= Config.Sniper().scanDelay and tdiff2 >= Config.Sniper().scanDelay;

        if (self.snipeStatusText) then
            self.snipeStatusText:SetText("Waiting to Query");
        end

        if (ready) then
            Sources:ClearValueCache();
            
            wipe(blocks);
            wipe(blockList);

            AuctionList:Recycle();

            self.state = STATES.SEARCH;
        end
    elseif (self.state == STATES.SEARCH) then
        if (Query:Search(DEFAULT_BROWSE_QUERY)) then
            self.state = STATES.WAITING;
            if (self.snipeStatusText) then
                self.snipeStatusText:SetText("Page: "..Query.page.." - Query Sent...");
            end
        end
    elseif (self.state == STATES.ITEMS) then
        if (not Query:IsLast()) then
            Query:Last();
            self.state = STATES.INIT;
        elseif (Query:HasNext()) then   
            if (self.snipeStatusText) then
                self.snipeStatusText:SetText("Filtering Auctions "..Query.itemIndex.." of "..Query:Count());
            end

            local auction = Query:Next();

            if (not auction) then
                return;
            end

            if (not Query:IsFiltered(auction)) then
                Recycler:Recycle(auction);
                return;
            end

            if (not blocks[auction.hash]) then
                blocks[auction.hash] = auction:Clone();
                blocks[auction.hash].count = 0;
                tinsert(blockList, blocks[auction.hash]);
            end

            local block = blocks[auction.hash];

            if(not block.auctions) then
                block.auctions = {};
            end

            block.count = block.count + auction.count;
            tinsert(block.auctions, auction);
        else
            AuctionList:SetItems(blockList);

            if (#blockList > 0 and Config.Sniper().dingSound) then
                PlaySound(SOUNDKIT.AUCTION_WINDOW_OPEN, "Master");
            end

            if (#blockList > 0) then
                lastSuccessScan = time();
            end

            wipe(blockList);
            wipe(blocks);

            Query:Last();

            self.state = STATES.INIT;
        end
    end
end

function AuctionSnipe:OnRetailUpdate()
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

    if (not throttleMessageReceived or throttleWaitingForSend) then
        throttleTime = time();
        return;
    end

    if (AuctionList.auction and AuctionList.commodity) then
        if (self:IsThrottled()) then
            return;
        end

        if (self.commodityState == STATES.CONFIRM_COMMODITY) then         
            if (AuctionList:ConfirmCommoditiesPurchase()) then
                self.commodityState = STATES.WAITING_COMMODITY_PURCHASE;
            else
                self.commodityState = STATES.CANCEL_COMMODITY;
            end
        elseif (self.commodityState == STATES.CANCEL_COMMODITY) then
            self.commodityState = STATES.NONE;

            AuctionList:CancelCommoditiesPurchase();

            -- continue on if we got caught in a weird state
            if (self.state == STATES.ITEMS_WAITING) then
                self.state = STATES.ITEMS;
            elseif (self.state == STATES.WAITING) then
                self.state = STATES.BROWSE_MORE;
            end
        end
        return;
    end

    if (self.state == STATES.SEARCH) then
        self:TryAndSearch();
    elseif(self.state == STATES.BROWSE_MORE) then
        if (self:IsThrottled()) then
            return;
        end

        self.state = STATES.WAITING;

        C_AuctionHouse.RequestMoreBrowseResults();
    elseif (self.state == STATES.SEARCH_MORE) then
        if (self:IsThrottled()) then
            return;
        end

        self.state = STATES.ITEMS_WAITING;

        if (currentItemScan.isCommodity) then
            C_AuctionHouse.RequestMoreCommoditySearchResults(currentItemScan.id);
        else
            C_AuctionHouse.RequestMoreItemSearchResults(currentItemScan.itemKey);
        end
    elseif (self.state == STATES.INIT) then
        if (self:IsThrottled()) then
            return;
        end

        currentItemScan = nil;
        
        self.fullBrowseResults = false;

        totalResultsFound = 0;
        scanIndex = 1;

        totalValidAuctionsFound = 0;

        Sources:ClearValueCache();
        ClearItemsFound();
        ClearValidAuctions();
        wipe(browseResults);
        
        self.state = STATES.WAITING;

        if (self.snipeStatusText) then
            self.snipeStatusText:SetText("Waiting for Results");
        end
        
        C_AuctionHouse.SendBrowseQuery(DEFAULT_BROWSE_QUERY);
    elseif (self.state == STATES.FINDING) then
        if (#browseResults == 0) then
            self.state = STATES.INIT;
            return;
        end

        local itemsPerUpdate = Config.Sniper().itemsPerUpdate;
        local count = 0;

        while (scanIndex <= #browseResults and count < itemsPerUpdate) do
            if (self.snipeStatusText) then
                self.snipeStatusText:SetText("Processed Groups "..(scanIndex + totalResultsFound));
            end

            local group = browseResults[scanIndex];
            local auction, noInfo = Query:IsFilteredGroup(group);

            if (auction) then
                tinsert(itemsFound, auction);
            end

            scanIndex = scanIndex + 1;
            count = count + 1;
        end

        if (scanIndex > #browseResults) then
            if (#itemsFound > 0) then
                if (self.snipeStatusText) then
                    self.snipeStatusText:SetText("Gathering Auctions");
                end

                scanIndex = 1;
                self.state = STATES.ITEMS;
                totalResultsFound = totalResultsFound + #browseResults;
                wipe(browseResults);
            elseif (self.fullBrowseResults) then
                if (self.snipeStatusText) then
                    self.snipeStatusText:SetText("Waiting to Query");
                end

                scanIndex = 1;
                self.state = STATES.INIT;

                wipe(browseResults);
            else
                totalResultsFound = totalResultsFound + #browseResults;
                scanIndex = 1;
                wipe(browseResults);
                self.state = STATES.BROWSE_MORE;
            end
        end
    elseif (self.state == STATES.ITEMS and not AuctionList.isBuying and not AuctionList.auction and not AuctionList.commodity) then
        if (scanIndex <= #itemsFound) then
            if (validAuctions and #validAuctions > 0) then
                totalValidAuctionsFound = totalValidAuctionsFound + #validAuctions;
                AuctionList:AddItems(validAuctions);
                ClearValidAuctions();
            end

            if (self.snipeStatusText) then
                self.snipeStatusText:SetText("Gathering Auctions "..scanIndex.." of "..#itemsFound..' out of '..totalResultsFound);
            end

            currentItemScan = itemsFound[scanIndex];
            scanIndex = scanIndex + 1;

            self.state = STATES.SEARCH;
        else
            if (validAuctions and #validAuctions > 0) then
                totalValidAuctionsFound = totalValidAuctionsFound + #validAuctions;
                AuctionList:AddItems(validAuctions);
                ClearValidAuctions();
            end

            if (totalValidAuctionsFound > 0 and Config.Sniper().dingSound) then
                PlaySound(SOUNDKIT.AUCTION_WINDOW_OPEN, "Master");
            end

            totalValidAuctionsFound = 0;

            ClearItemsFound();

            if (not self.fullBrowseResults) then
                scanIndex = 1;
                self.state = STATES.BROWSE_MORE;
            else
                if (self.snipeStatusText) then
                    self.snipeStatusText:SetText("Waiting to Query");
                end
                scanIndex = 1;

                self.state = STATES.INIT;
            end
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
        local id = select(1, ...);
        if (currentItemScan and currentItemScan.id == id and self.state == STATES.INFO) then
            self.state = STATES.SEARCH;
        end
    elseif (event == "GET_ITEM_INFO_RECEIVED") then
        local id = select(1, ...);
        if (currentItemScan and currentItemScan.id == id and self.state == STATES.INFO) then
            self.state = STATES.SEARCH;
        end
    end

    if (event == "AUCTION_HOUSE_THROTTLED_MESSAGE_RESPONSE_RECEIVED") then
        throttleTime = time();
        throttleMessageReceived = true;
    elseif (event == "AUCTION_HOUSE_THROTTLED_MESSAGE_QUEUED") then
        throttleMessageReceived = false;
        throttleWaitingForSend = true;
    elseif(event == "AUCTION_HOUSE_THROTTLED_MESSAGE_DROPPED") then
        throttleWaitingForSend = false;
        throttleMessageReceived = true;

        -- cancel purchase screen if the throttle message is dropped
        if (AuctionList.auction and AuctionList.commodity) then
            self.commodityState = STATES.CANCEL_COMMODITY;
        end
    elseif (event == "AUCTION_HOUSE_THROTTLED_MESSAGE_SENT") then
        throttleTime = time();
        throttleWaitingForSend = false;
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
        if (self.commodityState == STATES.WAITING_COMMODITY_PURCHASE) then
            self.commodityState = STATES.NONE;

            -- continue on if we got caught in a weird state
            if (self.state == STATES.ITEMS_WAITING) then
                self.state = STATES.ITEMS;
            elseif (self.state == STATES.WAITING) then
                self.state = STATES.BROWSE_MORE;
            end
        end
    end 
    if (event == "COMMODITY_PRICE_UPDATED") then
        local unit, total = ...;
        if (AuctionList.isBuying and AuctionList.commodity) then
            AuctionList.commodityTotal = total;
            AuctionList.commodityPPU = unit;
            self.commodityState = STATES.CONFIRM_COMMODITY;
        end
    end
    if (event == "COMMODITY_PRICE_UNAVAILABLE") then
        if (AuctionList.isBuying and AuctionList.commodity) then
            AuctionList.removeListing = false;
            self.commodityState = STATES.CANCEL_COMMODITY;
        end
    end

    if (event == "AUCTION_ITEM_LIST_UPDATE") then
        if (self.state == STATES.WAITING) then
            self.state = STATES.ITEMS;
        end
    end

    if (event == "AUCTION_HOUSE_SHOW") then self:OnAuctionHouseShow(); end;
    if (event == "AUCTION_HOUSE_CLOSED") then self:OnAuctionHouseClosed(); end;
end

function AuctionSnipe:OnItemResults() 
    if (currentItemScan and currentItemScan.itemKey) then
        local item = currentItemScan:Clone();
        item.isCommodity = false;

        if (not C_AuctionHouse.HasFullItemSearchResults(currentItemScan.itemKey)) then
            self.state = STATES.SEARCH_MORE;
            return;
        end

        for searchIndex = 1, C_AuctionHouse.GetNumItemSearchResults(currentItemScan.itemKey) do
            local result = C_AuctionHouse.GetItemSearchResultInfo(currentItemScan.itemKey, searchIndex);

            if (result.buyoutAmount) then
                item.count = result.quantity;
                item.ppu = result.buyoutAmount;
                item.buyoutPrice = result.buyoutAmount;
                item.owner = GetOwners(result);
                item.isOwnerItem = result.containsOwnerItem or result.containsAccountItem;

                if (result.itemLink) then
                    item.link = result.itemLink;

                    local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemIcon, itemSellPrice, itemClassID, itemSubClassID, bindType, expacID, itemSetID, isCraftingReagent = GetItemInfo(item.link); 

                    item.quality = itemRarity;
                    item.name = itemName;
                    item.texture = itemIcon;
                    item.vendorsell = itemSellPrice;

                    if (Utils:IsBattlePetLink(item.link)) then
                        local info = Utils:ParseBattlePetLink(item.link);
                        item.name = info.name;
                        item.iLevel = info.level;
                        item.quality = info.breedQuality;
                        item.texture = info.icon;
                    end

                    item.tsmId = Utils:GetTSMID(item.link);
                end

                local preventResult = seenResults[result.auctionID];

                if (not preventResult and not item.isOwnerItem) then
                    seenResults[result.auctionID] = true;
                    if (Query:IsFiltered(item)) then
                        item.auctionId = result.auctionID;
                        tinsert(validAuctions, item:Clone());
                    end
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
        local item = currentItemScan:Clone();
        item.isCommodity = true;
        
        if (not C_AuctionHouse.HasFullCommoditySearchResults(currentItemScan.id)) then
            self.state = STATES.SEARCH_MORE;
            return;
        end

        for searchIndex = 1, C_AuctionHouse.GetNumCommoditySearchResults(item.id) do
            local result = C_AuctionHouse.GetCommoditySearchResultInfo(item.id, searchIndex);
            item.count = result.quantity;
            item.ppu = result.unitPrice;
            item.buyoutPrice = result.unitPrice * result.quantity;
            item.owner = GetOwners(result);
            item.isOwnerItem = result.containsOwnerItem or result.containsAccountItem;

            local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemIcon, itemSellPrice, itemClassID, itemSubClassID, bindType, expacID, itemSetID, isCraftingReagent = GetItemInfo(item.id); 

            if (itemName and itemLink) then
                item.link = itemLink;
                item.quality = itemRarity;
                item.name = itemName;
                item.texture = itemIcon;
                item.vendorsell = itemSellPrice;
            end

            local commodityId = item.id..item.count..item.ppu;
            local preventResult = seenResults[commodityId];

            if (not item.isOwnerItem and not preventResult and item.name) then
                seenResults[commodityId] = true;
                
                if (Query:IsFiltered(item)) then
                    tinsert(validAuctions, item:Clone());
                end
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
    if (addonName:lower() == "blizzard_auctionhouseui" or addonName:lower() == "blizzard_auctionui") then
        AHFrame = AuctionHouseFrame or AuctionFrame;
        AHFrameDisplayMode = AuctionHouseFrameDisplayMode or {};
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
        wipe(seenResults);
        Query:ClearBlacklist();
        AuctionList:Recycle();
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

    wipe(opTreeViewItems);
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
    self.filterTreeView.items = opTreeViewItems;
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

    DEFAULT_BROWSE_QUERY.quality = quality;

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

    ClearItemsFound();
    ClearValidAuctions();
    Sources:ClearValueCache();

    DEFAULT_BROWSE_QUERY.searchString = search;
    DEFAULT_BROWSE_QUERY.filters = qualityFilters;
    DEFAULT_BROWSE_QUERY.itemClassFilters = classFilters;

    -- apply classic sort to get 
    -- item sorted by most recent time
    -- posted
    if (Utils:IsClassic()) then
        SortAuctionClearSort("list");
        SortAuctionApplySort("list");
    end

    scanIndex = 1;
    Query.index = 0;
    Query:AssignDefaults(ilevel, maxBuyout, quality, maxPercent);
    Query:AssignSnipingOps(self.activeOps);
    self.state = STATES.INIT;
end

function AuctionSnipe:Stop()
    ClearValidAuctions(); 
    ClearItemsFound();
    
    wipe(browseResults);

    wipe(blockList);
    wipe(blocks);

    if (not Utils:IsClassic()) then
        AuctionList:CancelCommoditiesPurchase();
    end

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