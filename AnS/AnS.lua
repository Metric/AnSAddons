local Ans = select(2, ...);

local TUJDB = Ans.Database.TUJ;
local TSMDB = Ans.Database.TSM;

local Sources = Ans.Sources;

local Utils = Ans.Utils;

local DefaultGroups = Ans.Data;

local AHTabs = {};
local AHTabIndexToTab = {};

local MinimapIcon = Ans.MinimapIcon;
local EventManager = Ans.EventManager;
local Window = Ans.Window;
local Analytics = Ans.Analytics;
local Operations = Ans.Operations;
local SnipingOperation = Operations.Sniping;

AnsCore = {};
AnsCore.__index = AnsCore;

AnsCore.API = Ans;
AnsCore.Window = Window;

local AH_TAB_CLICK = nil;

StaticPopupDialogs["ANS_NO_PRICING"] = {
    text = "Looks like, you have no data pricing source! TheUndermineJournal, TSM, AnsAuctionData, and Auctionator are currently supported.",
    button1 = "OKAY",
    OnAccept = function() end,
    timeout = 0,
    whileDead = false,
    hideOnEscape = true,
    preferredIndex = 3
};

local TUJOnlyPercentFn = "tujmarket";
local TSMOnlyPercentFn = "dbmarket";
local TUJAndTSMPercentFn = "min(dbmarket,tujmarket)";
local ATRPercentFn = "atrvalue";
local ATRTSMPercentFn = "min(atrvalue,dbmarket)";
local ATRTUJPercentFn = "min(atrvalue,tujmarket)";
local AnsOnlyPercentFn = "min(ansrecent,ansmarket)";

function AnsCore:AddAHTab(name, displayMode)
    local n = #AuctionHouseFrame.Tabs + 1;
    local lastTab = AuctionHouseFrame.Tabs[n - 1];
    local framename = "AuctionHouseFrameTab"..n;
    local frame = CreateFrame("BUTTON", framename, AuctionHouseFrame, "AuctionHouseFrameDisplayModeTabTemplate");

    frame:SetID(n);
    frame:SetText(name);
    frame:SetNormalFontObject(_G["AnsFontOrange"]);
    frame:SetPoint("LEFT", lastTab, "RIGHT", -15, 0);
    frame.displayMode = displayMode;
    frame:HookScript("OnClick", function() AuctionHouseFrame:SetTitle(name) end);

    tinsert(AuctionHouseFrame.Tabs, frame);
    AuctionHouseFrame.tabsForDisplayMode[displayMode] = n;

    PanelTemplates_SetNumTabs(AuctionHouseFrame, n);
end

function AnsCore:RegisterEvents(frame)
    self.frame = frame;
    frame:RegisterEvent("VARIABLES_LOADED");
    Analytics:RegisterEvents(frame);
end

function AnsCore:EventHandler(frame, event, ...)
    EventManager:Emit(event, ...);

    if (event == "VARIABLES_LOADED") then 
        self:OnLoad();
    end
end

function AnsCore.SaveMiniButton(angle)
    ANS_WINDOW_MINI_POSITION = angle;
end

function AnsCore:OnLoad()
    self:MigrateGlobalSettings();
    self:MigrateFiltersToGroups(ANS_FILTERS, ANS_GROUPS);
    self:MigrateFiltersToSnipingOperations(ANS_FILTERS);

    -- clear ANS_FILTERS!
    ANS_FILTERS = {};

    self:SetDefaults();
    self:RegisterPriceSources();
    self:LoadCustomVars();

    Ans.MiniButton = MinimapIcon:New("AnsMiniButton", "Interface\\AddOns\\AnS\\Images\\ansicon", 
    function() Window:Toggle() end, AnsCore.SaveMiniButton, ANS_WINDOW_MINI_POSITION, {"|cFFCC00FFAnS ["..GetAddOnMetadata("AnS", "Version").."]", "Click to Toggle", "Click & Drag to Move"});

    Window:OnLoad(self.frame);
end

function AnsCore:MigrateFiltersToGroups(parent, root)
    for i,f in ipairs(parent) do
        local t = {
            id = Utils:Guid(),
            name = f.name,
            ids = f.ids,
            children = {}
        };

        f.id = t.id;
        tinsert(root, t);

        if (#f.children > 0) then
            self:MigrateFiltersToGroups(f.children, t.children);
        end
    end
end

function AnsCore:MigrateFiltersToSnipingOperations(items, parentName)
    for i,f in ipairs(items) do
        local snipeName = f.name;
        if (parentName) then
            snipeName = parentName.."."..f.name;
        end

        if (f.priceFn and #f.priceFn > 0) then
            local tmp = SnipingOperation:NewConfig(snipeName);
            tmp.price = f.priceFn;
            tmp.exactMatch = f.exactMatch;
            if (f.id) then
                tinsert(tmp.groups, f.id);
            end
            tinsert(ANS_OPERATIONS.Sniping, tmp);
        end

        if (#f.children > 0) then
            self:MigrateFiltersToSnipingOperations(f.children, snipeName);
        end
    end
end

function AnsCore:SetDefaults()
    if (#ANS_GROUPS == 0) then
        ANS_GROUPS = DefaultGroups;
    end
end

function AnsCore:RegisterPriceSources()
    local tsmEnabled = false;
    local tujEnabled = false;
    local ansEnabled = false;
    local auctionatorEnabled = false;

    if (Utils:IsAddonEnabled("Auctionator") and Atr_GetAuctionBuyout) then
       auctionatorEnabled = true; 
    end
    
    if (TSM_API or TSMAPI) then
        tsmEnabled = true;
    end

    if (AnsAuctionData) then
        ansEnabled = true;
    end

    if (TUJMarketInfo) then
        tujEnabled = true;
    end

    if (tujEnabled and tsmEnabled and ANS_SNIPE_SETTINGS.source:len() == 0) then
        print("AnS: setting default tuj and tsm percent fn");
        ANS_SNIPE_SETTINGS.source = TUJAndTSMPercentFn;
    elseif (tujEnabled and not tsmEnabled and not auctionatorEnabled and ANS_SNIPE_SETTINGS.source:len() == 0) then
        print("AnS: setting default tuj percent fn");
        ANS_SNIPE_SETTINGS.source = TUJOnlyPercentFn;
    elseif (tsmEnabled and not tujEnabled and not auctionatorEnabled and ANS_SNIPE_SETTINGS.source:len() == 0) then
        print("AnS: setting default tsm percent fn");
        ANS_SNIPE_SETTINGS.source = TSMOnlyPercentFn;
    elseif (auctionatorEnabled and not tsmEnabled and not tujEnabled and ANS_SNIPE_SETTINGS.source:len() == 0) then
        print("AnS: setting default auctionator percent fn");
        ANS_SNIPE_SETTINGS.source = ATRPercentFn;
    elseif (auctionatorEnabled and tujEnabled and not tsmEnabled and ANS_SNIPE_SETTINGS.source:len() == 0) then
        print("AnS: setting default auctionator and tuj percent fn");
        ANS_SNIPE_SETTINGS.source = ATRTUJPercentFn;
    elseif (auctionatorEnabled and tsmEnabled and not tujEnabled and ANS_SNIPE_SETTINGS.source:len() == 0) then
        print("AnS: setting default auctionator and tsm percent fn");
        ANS_SNIPE_SETTINGS.source = ATRTSMPercentFn;
    elseif (ansEnabled and ANS_SNIPE_SETTINGS.source:len() == 0) then
        print("AnS: setting default AnsAuctionData percent fn");
        ANS_SNIPE_SETTINGS.source = AnsOnlyPercentFn;
    end

    if (not tsmEnabled and not tujEnabled and not auctionatorEnabled and not ansEnabled) then
        StaticPopup_Show("ANS_NO_PRICING");
    end

    if (tsmEnabled) then
        print("AnS: found TSM pricing source");
        Sources:Register("DBMarket", TSMDB.GetPrice, "marketValue");
        Sources:Register("DBMinBuyout", TSMDB.GetPrice, "minBuyout");
        Sources:Register("DBHistorical", TSMDB.GetPrice, "historical");
        Sources:Register("DBRegionMinBuyoutAvg", TSMDB.GetPrice, "regionMinBuyout");
        Sources:Register("DBRegionMarketAvg", TSMDB.GetPrice, "regionMarketValue");
        Sources:Register("DBRegionHistorical", TSMDB.GetPrice, "regionHistorical");
        Sources:Register("DBRegionSaleAvg", TSMDB.GetPrice, "regionSale");
        Sources:Register("DBRegionSaleRate", TSMDB.GetSaleInfo, "regionSalePercent");
        Sources:Register("DBRegionSoldPerDay", TSMDB.GetSaleInfo, "regionSoldPerDay");
        Sources:Register("DBGlobalMinBuyoutAvg", TSMDB.GetPrice, "globalMinBuyout");
        Sources:Register("DBGlobalMarketAvg", TSMDB.GetPrice, "globalMarketValue");
        Sources:Register("DBGlobalHistorical", TSMDB.GetPrice, "globalHistorical");
        Sources:Register("DBGlobalSaleAvg", TSMDB.GetPrice, "globalSale");
        Sources:Register("DBGlobalSaleRate", TSMDB.GetSaleInfo, "globalSalePercent");
        Sources:Register("DBGlobalSoldPerDay", TSMDB.GetSaleInfo, "globalSoldPerDay");
    end

    if (tujEnabled) then
        print("AnS: found TUJ pricing source");
        Sources:Register("TUJMarket", TUJDB.GetPrice, "market");
        Sources:Register("TUJRecent", TUJDB.GetPrice, "recent");
        Sources:Register("TUJGlobalMedian", TUJDB.GetPrice, "globalMedian");
        Sources:Register("TUJGlobalMean", TUJDB.GetPrice, "globalMean");
        Sources:Register("TUJAge", TUJDB.GetPrice, "age");
        Sources:Register("TUJDays", TUJDB.GetPrice, "days");
        Sources:Register("TUJStdDev", TUJDB.GetPrice, "stddev");
        Sources:Register("TUJGlobalStdDev", TUJDB.GetPrice, "globalStdDev");
    end

    if (ansEnabled) then
        print("AnS: found AnS pricing source");
        Sources:Register("ANSRecent", AnsAuctionData.GetRealmValue, "recent");
        Sources:Register("ANSMarket", AnsAuctionData.GetRealmValue, "market");
        Sources:Register("ANSMin", AnsAuctionData.GetRealmValue, "min");
        Sources:Register("ANS3Day", AnsAuctionData.GetRealmValue, "3day");
        --Sources:Register("ANSRegionRecent", AnsAuctionData.GetRegionValue, "recent");
        --Sources:Register("ANSRegionMarket", AnsAuctionData.GetRegionValue, "market");
        --Sources:Register("ANSRegionMin", AnsAuctionData.GetRegionValue, "min");
        --Sources:Register("ANSRegion3Day", AnsAuctionData.GetRegionValue, "3day");
    end

    if (auctionatorEnabled) then
        print("AnS: found Auctionator pricing source");
        Sources:Register("AtrValue", Atr_GetAuctionBuyout, nil);
    end
end

function AnsCore:LoadCustomVars()
    ANS_CUSTOM_VARS = ANS_CUSTOM_VARS or {};
    Sources:ClearCache();
    Sources:LoadCustomVars();
end

function AnsCore:MigrateGlobalSettings()
    if (ANS_GLOBAL_SETTINGS.percentFn and ANS_GLOBAL_SETTINGS.percentFn ~= "") then
        ANS_SNIPE_SETTINGS.source = ANS_GLOBAL_SETTINGS.percentFn;
        ANS_GLOBAL_SETTINGS.percentFn = nil;
    end
    if (ANS_GLOBAL_SETTINGS.priceFn and ANS_GLOBAL_SETTINGS.priceFn ~= "") then
        ANS_SNIPE_SETTINGS.pricing = ANS_SNIPE_SETTINGS.priceFn;
        ANS_GLOBAL_SETTINGS.priceFn = nil;
    end
    if (ANS_GLOBAL_SETTINGS.rescanTime ~= nil) then
        ANS_GLOBAL_SETTINGS.rescanTime = nil;
    end
    if (ANS_GLOBAL_SETTINGS.showDressing == nil) then
        ANS_GLOBAL_SETTINGS.showDressing = false;
    end
    if (ANS_GLOBAL_SETTINGS.dingSound ~= nil) then
        ANS_SNIPE_SETTINGS.dingSound = ANS_GLOBAL_SETTINGS.dingSound;
        ANS_GLOBAL_SETTINGS.dingSound = nil;
    end
    if (ANS_GLOBAL_SETTINGS.scanDelayTime ~= nil) then
        ANS_GLOBAL_SETTINGS.scanDelayTime = nil;
    end
    if (ANS_GLOBAL_SETTINGS.useCoinIcons == nil) then
        ANS_GLOBAL_SETTINGS.useCoinIcons = false;
    end
    if (ANS_GLOBAL_SETTINGS.itemsPerUpdate ~= nil) then
        ANS_SNIPE_SETTINGS.itemsPerUpdate = ANS_GLOBAL_SETTINGS.itemsPerUpdate;
        ANS_GLOBAL_SETTINGS.itemsPerUpdate = nil;
    end
    if (ANS_GLOBAL_SETTINGS.itemBlacklist ~= nil) then
        ANS_SNIPE_SETTINGS.itemBlacklist = ANS_GLOBAL_SETTINGS.itemBlacklist;
        ANS_GLOBAL_SETTINGS.itemBlacklist = nil;
    end
    if (ANS_GLOBAL_SETTINGS.useCommodityConfirm ~= nil) then
        ANS_SNIPE_SETTINGS.useCommodityConfirm = ANS_GLOBAL_SETTINGS.useCommodityConfirm;
        ANS_GLOBAL_SETTINGS.useCommodityConfirm = nil;
    end
    if (ANS_GLOBAL_SETTINGS.tooltipRealm3Day == nil) then
        ANS_GLOBAL_SETTINGS.tooltipRealm3Day = true;
    end
	if (ANS_GLOBAL_SETTINGS.tooltipRealmMarket == nil) then
        ANS_GLOBAL_SETTINGS.tooltipRealmMarket = true;
    end
    if (ANS_GLOBAL_SETTINGS.tooltipRealmRecent == nil) then
        ANS_GLOBAL_SETTINGS.tooltipRealmRecent = true;
    end
    if (ANS_GLOBAL_SETTINGS.tooltipRealmMin == nil) then
        ANS_GLOBAL_SETTINGS.tooltipRealmMin = true;
    end
    if (ANS_GLOBAL_SETTINGS.trackDataAnalytics == nil) then
        ANS_GLOBAL_SETTINGS.trackDataAnalytics = true;
    end
    if (ANS_GLOBAL_SETTINGS.characterBlacklist ~= nil) then
        ANS_SNIPE_SETTINGS.characterBlacklist = ANS_GLOBAL_SETTINGS.characterBlacklist;
        ANS_GLOBAL_SETTINGS.characterBlacklist = nil;
    end
end