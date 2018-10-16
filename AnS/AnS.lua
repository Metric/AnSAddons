local Ans = select(2, ...);

local TUJDB = Ans.Database.TUJ;
local TSMDB = Ans.Database.TSM;

local Sources = Ans.Sources;

local Utils = Ans.Utils;

local Data = Ans.Data;

local Filter = Ans.Filter;

local AHTabs = {};
local AHTabIndexToTab = {};

AnsCore = {};
AnsCore.__index = AnsCore;

Ans.Filters = {};

AnsCore.API = Ans;

local AH_TAB_CLICK = nil;

StaticPopupDialogs["ANS_NO_PRICING"] = {
    text = "Looks like, you have no data pricing source! TheUndermineJournal, TSM, and Auctionator are currently supported.",
    button1 = "OKAY",
    OnAccept = function() end,
    timeout = 0,
    whileDead = false,
    hideOnEscape = true,
    preferredIndex = 3
};

local function AHTabClick(self, button, down)
    AH_TAB_CLICK(self, button, down);
    AnsCore:AHTabClick(self, button, down);
end

local TUJOnlyPercentFn = "tujmarket";
local TSMOnlyPercentFn = "dbmarket";
local TUJAndTSMPercentFn = "min(dbmarket,tujmarket)";
local ATRPercentFn = "atrvalue";
local ATRTSMPercentFn = "min(atrvalue,dbmarket)";
local ATRTUJPercentFn = "min(atrvalue,tujmarket)";

function AnsCore:AHTabClick(t, button, down)
    for k, v in pairs(AHTabs) do
        if (v.onClose) then
            v.onClose();
        end
    end

    local id = t:GetID();

    if (AHTabIndexToTab[id]) then
        local n = AHTabIndexToTab[id];
        local tab = AHTabs[n];

        if (tab and tab.onShow) then
            tab.onShow();
            PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB);
        end
    end

    PanelTemplates_SetTab(AuctionFrame, id);
end

function AnsCore:AddAHTab(name, showFn, closeFn)
    local n = AuctionFrame.numTabs + 1;
    local framename = "AuctionFrameTab"..n;
    local frame = CreateFrame("BUTTON", framename, AuctionFrame, "AuctionTabTemplate");

    frame:SetID(n);
    frame:SetText(name);
    frame:SetNormalFontObject(_G["AnsFontOrange"]);
    frame:SetPoint("LEFT", _G["AuctionFrameTab"..(n-1)], "RIGHT", -8, 0);

    PanelTemplates_SetNumTabs(AuctionFrame, n);
    PanelTemplates_EnableTab(AuctionFrame, n);

    if (AH_TAB_CLICK == nil) then
        -- setup hook
        AH_TAB_CLICK = AuctionFrameTab_OnClick;
        AuctionFrameTab_OnClick = AHTabClick;
    end

    local ansTab = {
        name = name,
        onShow = showFn,
        onClose = closeFn
    };

    AHTabs[name] = ansTab;
    AHTabIndexToTab[n] = name;
end

function AnsCore:RegisterEvents(frame)
    frame:RegisterEvent("VARIABLES_LOADED");
end

function AnsCore:EventHandler(frame, event, ...)
    if (event == "VARIABLES_LOADED") then self:OnLoad(); end;
end

function AnsCore:OnLoad()
    self:MigrateGlobalSettings();
    self:CreateDefaultFilters();
    self:MigrateCustomFilters();
    self:RegisterPriceSources();
    self:LoadFilters();
    self:LoadCustomVars();
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
        ansEnabled = AnsAuctionData:HasData();
    end

    if (TUJMarketInfo) then
        tujEnabled = true;
    end

    if (tujEnabled and tsmEnabled and ANS_GLOBAL_SETTINGS.percentFn:len() == 0) then
        print("AnS: setting default tuj and tsm percent fn");
        ANS_GLOBAL_SETTINGS.percentFn = TUJAndTSMPercentFn;
    elseif (tujEnabled and not tsmEnabled and not auctionatorEnabled and ANS_GLOBAL_SETTINGS.percentFn:len() == 0) then
        print("AnS: setting default tuj percent fn");
        ANS_GLOBAL_SETTINGS.percentFn = TUJOnlyPercentFn;
    elseif (tsmEnabled and not tujEnabled and not auctionatorEnabled and ANS_GLOBAL_SETTINGS.percentFn:len() == 0) then
        print("AnS: setting default tsm percent fn");
        ANS_GLOBAL_SETTINGS.percentFn = TSMOnlyPercentFn;
    elseif (auctionatorEnabled and not tsmEnabled and not tujEnabled and ANS_GLOBAL_SETTINGS.percentFn:len() == 0) then
        print("AnS: setting default auctionator percent fn");
        ANS_GLOBAL_SETTINGS.percentFn = ATRPercentFn;
    elseif (auctionatorEnabled and tujEnabled and not tsmEnabled and ANS_GLOBAL_SETTINGS.percentFn:len() == 0) then
        print("AnS: setting default auctionator and tuj percent fn");
        ANS_GLOBAL_SETTINGS.percentFn = ATRTUJPercentFn;
    elseif (auctionatorEnabled and tsmEnabled and not tujEnabled and ANS_GLOBAL_SETTINGS.percentFn:len() == 0) then
        print("AnS: setting default auctionator and tsm percent fn");
        ANS_GLOBAL_SETTINGS.percentFn = ATRTSMPercentFn;
    end

    if (not tsmEnabled and not tujEnabled and not auctionatorEnabled) then
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
        Sources:Register("ANSHistorical", AnsAuctionData.GetRealmValue, "3day");
        Sources:Register("ANSRegionRecentAvg", AnsAuctionData.GetRegionValue, "recent");
        Sources:Register("ANSRegionAvg", AnsAuctionData.GetRegionValue, "market");
        Sources:Register("ANSRegionMin", AnsAuctionData.GetRegionValue, "min");
        Sources:Register("ANSRegionHistorical", AnsAuctionData.GetRegionValue, "3day");
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

function AnsCore:LoadFilters()
    wipe(Ans.Filters);

    for i, f in ipairs(ANS_FILTERS) do
        local filter = Filter:New(f.name);
        
        filter.priceFn = f.priceFn;
        filter.useGlobalMaxBuyout = f.useMaxPPU;
        filter.useGlobalMinILevel = f.useMinLevel;
        filter.useGlobalMinQuality = f.useQuality;
        filter.useGlobalMinStack = f.useMinStack;
        filter.useGlobalPercent = f.usePercent;
        filter:ParseTSM(f.ids);
        filter:ParseTypes(f.types);
        filter.ParseSubtypes(f.subtypes);

        if (#f.children > 0) then
            self:LoadSubFilters(f.children, filter);
        end

        tinsert(Ans.Filters, filter);
    end
end

function AnsCore:LoadSubFilters(filters, parent)
    for i, f in ipairs(filters) do
        local filter = Filter:New(f.name);
        filter.priceFn = f.priceFn;
        filter.useGlobalMaxBuyout = f.useMaxPPU;
        filter.useGlobalMinILevel = f.useMinLevel;
        filter.useGlobalMinQuality = f.useQuality;
        filter.useGlobalMinStack = f.useMinStack;
        filter.useGlobalPercent = f.usePercent;
        filter:ParseTSM(f.ids);
        filter:ParseTypes(f.types);
        filter:ParseSubtypes(f.subtypes);

        parent:AddChild(filter);

        -- probably should do this as a stack
        -- but for now will do recursive
        if (#f.children > 0) then
            self:LoadSubFilters(f.children, filter);
        end
    end
end

function AnsCore:MigrateGlobalSettings()
    if (ANS_GLOBAL_SETTINGS.rescanTime == nil) then
        ANS_GLOBAL_SETTINGS.rescanTime = 0;
    end
    if (ANS_GLOBAL_SETTINGS.showDressing == nil) then
        ANS_GLOBAL_SETTINGS.showDressing = true;
    end
    if (ANS_GLOBAL_SETTINGS.dingSound == nil) then
        ANS_GLOBAL_SETTINGS.dingSound = true;
    end
    if (ANS_GLOBAL_SETTINGS.safeBuy == nil) then
        ANS_GLOBAL_SETTINGS.safeBuy = true;
    end
    if (ANS_GLOBAL_SETTINGS.safeDelay == nil) then
        ANS_GLOBAL_SETTINGS.safeDelay = 2;
    end
    if (ANS_GLOBAL_SETTINGS.characterBlacklist == nil) then
        ANS_GLOBAL_SETTINGS.characterBlacklist = "";
    end
    if (ANS_GLOBAL_SETTINGS.tooltipRegionRecent == nil) then
        ANS_GLOBAL_SETTINGS.tooltipRegionRecent = true;
    end
    if (ANS_GLOBAL_SETTINGS.tooltipRegionMin == nil) then
        ANS_GLOBAL_SETTINGS.tooltipRegionMin = true;
    end
    if (ANS_GLOBAL_SETTINGS.tooltipRealmRecent == nil) then
        ANS_GLOBAL_SETTINGS.tooltipRealmRecent = true;
    end
    if (ANS_GLOBAL_SETTINGS.tooltipRealmMin == nil) then
        ANS_GLOBAL_SETTINGS.tooltipRealmMin = true;
    end
    if (ANS_GLOBAL_SETTINGS.tooltipRegionHistorical == nil) then
        ANS_GLOBAL_SETTINGS.tooltipRegionHistorical = true;
    end
    if (ANS_GLOBAL_SETTINGS.tooltipRealmHistorical == nil) then
        ANS_GLOBAL_SETTINGS.tooltipRealmHistorical = true;
    end
    if (ANS_GLOBAL_SETTINGS.useCoinIcons == nil) then
        ANS_GLOBAL_SETTINGS.useCoinIcons = false;
    end
end

function AnsCore:MigrateCustomFilters()
    ANS_CUSTOM_FILTERS = ANS_CUSTOM_FILTERS or {};

    if (#ANS_CUSTOM_FILTERS > 0) then
        for i, v in ipairs(ANS_CUSTOM_FILTERS) do
            local t = {
                name = v.name,
                ids = v.ids,
                children = {},
                useMaxPPU = false,
                useMinLevel = false,
                useQuality = false,
                useMinStack = false,
                usePercent = true,
                priceFn = v.priceFn,
                types = v.types,
                subtypes = v.subtypes,
            };

            tinsert(ANS_FILTERS, t);
        end
    end

    -- migrating away from custom filters
    -- and combined them with all filters
    ANS_CUSTOM_FILTERS = {};
end

function AnsCore:RestoreDefaultFilters()
    self:RestoreFilter(Data, ANS_FILTERS);
end

function AnsCore:RestoreFilter(children, parent)
    for i,v in ipairs(children) do
        local restored = false;

        for i2, v2 in ipairs(parent) do
            if (v2.name == v.name) then
                v2.ids = v.ids;
                v2.useMaxPPU = v.useMaxPPU;
                v2.useMinLevel = v.useMinLevel;
                v2.useQuality = v.useQuality;
                v2.useMinStack = v.useMinStack;
                v2.usePercent = v.usePercent;
                v2.priceFn = v.priceFn;
                v2.types = v.types;
                v2.subtypes = v.subtypes;
                
                if (v.children and #v.children > 0) then
                    self:RestoreFilter(v.children, v2.children);
                end

                restored = true;
                break;
            end
        end

        if (not restored) then
            self:PopulateFilter(v, parent);
        end
    end
end

function AnsCore:CreateDefaultFilters()
    if (not ANS_FILTERS or #ANS_FILTERS == 0) then
        ANS_FILTERS = {};
        -- reset filter selection as a new method will now
        -- be used
        ANS_FILTER_SELECTION = {};
        self:RestoreFilter(Data, ANS_FILTERS);
    end
end

function AnsCore:PopulateFilter(v, parent)
    local t = {
        name = v.name,
        ids = v.ids,
        children = {},
        useMaxPPU = v.useMaxPPU,
        useMinLevel = v.useMinLevel,
        useQuality = v.useQuality,
        useMinStack = v.useMinStack,
        usePercent = v.usePercent,
        priceFn = v.priceFn,
        types = v.types,
        subtypes = v.subtypes,
    };

    if (v.children and #v.children > 0) then
        for i2, v2 in ipairs(v.children) do
            self:PopulateFilter(v2, t.children);
        end 
    end

    tinsert(parent, t);
end