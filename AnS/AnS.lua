AnsCore = {};
AnsCore.__index = AnsCore;

AnsCustomFilter = {};
AnsCustomFilter.__index = AnsCustomFilter;

StaticPopupDialogs["ANS_NO_PRICING"] = {
    text = "Looks like, you have no data pricing source! TheUndermineJournal, TSM, and Auctionator are currently supported.",
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

local DefaultFilters = {};
local TUJTempTable = {};

local AnsAuctionDB = {};
local TSM_MAJOR_VERSION = AnsUtils:GetAddonVersion("TradeSkillMaster");

function AnsAuctionDB.GetTSMPrice(link, key, name) 
    local id = AnsUtils:GetTSMID(link);

    if(TSM_MAJOR_VERSION == "3") then
        return TSMAPI:GetCustomPriceValue(name, id);
    else
        return TSM_API.GetCustomPriceValue(name, id);
    end
end

function AnsAuctionDB.GetSaleInfo(link, key, name)
    local r = AnsAuctionDB.GetTSMPrice(link, key, name);
    if (TSM_MAJOR_VERSION == "3") then
        if (not r) then r = 0; end;
        return r / 100;
    else
        return r;
    end
end

local function GetTUJPrice(itemId, key)
    TUJMarketInfo(itemId, TUJTempTable);
    return TUJTempTable[key];
end

function AnsCustomFilter:New(name,ids)
    local f = {};
    setmetatable(f, AnsCustomFilter);
    
    f.name = name;
    f.ids = ids;
    f.priceFn = "tujdays ~= 252";
    f.globalMaxBuyout = true;
    f.globalMinStack = true;
    f.globalMinQuality = true;
    f.globalMinILevel = true;
    f.types = "";
    f.subtypes = "";

    return f;
end

function AnsCore:RegisterEvents(frame)
    frame:RegisterEvent("VARIABLES_LOADED");
end

function AnsCore:EventHandler(frame, event, ...)
    if (event == "VARIABLES_LOADED") then AnsCore:OnLoad(); end;
end

function AnsCore:OnLoad()
    self:MigrateGlobalSettings();
    self:MigrateCustomFilters();
    self:RegisterPriceSources();
    self:StoreDefaultFilters();
    self:LoadCustomFilters();
    self:LoadCustomVars();
end

function AnsCore:StoreDefaultFilters()
    ANS_FILTER_SELECTION = ANS_FILTER_SELECTION or {};
    local i;
    local total = #AnsFilterList;

    for i = 1, total do
        DefaultFilters[i] = AnsFilterList[i];
    end
end

function AnsCore:RegisterPriceSources()
    local tsmEnabled = false;
    local tujEnabled = false;
    local auctionatorEnabled = false;

    if (AnsUtils:IsAddonEnabled("Auctionator") and Atr_GetAuctionBuyout) then
       auctionatorEnabled = true; 
    end
    
    if (TSM_API or TSMAPI) then
        tsmEnabled = true;
    end

    if (TUJMarketInfo) then
        tujEnabled = true;
    end

    if (tujEnabled and tsmEnabled and ANS_GLOBAL_SETTINGS.percentFn:len() == 0) then
        print("setting default tuj and tsm percent fn");
        ANS_GLOBAL_SETTINGS.percentFn = TUJAndTSMPercentFn;
    elseif (tujEnabled and not tsmEnabled and ANS_GLOBAL_SETTINGS.percentFn:len() == 0) then
        print("setting default tuj percent fn");
        ANS_GLOBAL_SETTINGS.percentFn = TUJOnlyPercentFn;
    elseif (tsmEnabled and not tujEnabled and ANS_GLOBAL_SETTINGS.percentFn:len() == 0) then
        print("setting default tsm percent fn");
        ANS_GLOBAL_SETTINGS.percentFn = TSMOnlyPercentFn;
    end

    if (not tsmEnabled and not tujEnabled and not auctionatorEnabled) then
        StaticPopup_Show("ANS_NO_PRICING");
    end

    if (tsmEnabled) then
        print("AnS found TSM pricing source");
        AnsPriceSources:Register("DBMarket", AnsAuctionDB.GetTSMPrice, "marketValue");
        AnsPriceSources:Register("DBMinBuyout", AnsAuctionDB.GetTSMPrice, "minBuyout");
        AnsPriceSources:Register("DBHistorical", AnsAuctionDB.GetTSMPrice, "historical");
        AnsPriceSources:Register("DBRegionMinBuyoutAvg", AnsAuctionDB.GetTSMPrice, "regionMinBuyout");
        AnsPriceSources:Register("DBRegionMarketAvg", AnsAuctionDB.GetTSMPrice, "regionMarketValue");
        AnsPriceSources:Register("DBRegionHistorical", AnsAuctionDB.GetTSMPrice, "regionHistorical");
        AnsPriceSources:Register("DBRegionSaleAvg", AnsAuctionDB.GetTSMPrice, "regionSale");
        AnsPriceSources:Register("DBRegionSaleRate", AnsAuctionDB.GetSaleInfo, "regionSalePercent");
        AnsPriceSources:Register("DBRegionSoldPerDay", AnsAuctionDB.GetSaleInfo, "regionSoldPerDay");
        AnsPriceSources:Register("DBGlobalMinBuyoutAvg", AnsAuctionDB.GetTSMPrice, "globalMinBuyout");
        AnsPriceSources:Register("DBGlobalMarketAvg", AnsAuctionDB.GetTSMPrice, "globalMarketValue");
        AnsPriceSources:Register("DBGlobalHistorical", AnsAuctionDB.GetTSMPrice, "globalHistorical");
        AnsPriceSources:Register("DBGlobalSaleAvg", AnsAuctionDB.GetTSMPrice, "globalSale");
        AnsPriceSources:Register("DBGlobalSaleRate", AnsAuctionDB.GetSaleInfo, "globalSalePercent");
        AnsPriceSources:Register("DBGlobalSoldPerDay", AnsAuctionDB.GetSaleInfo, "globalSoldPerDay");
    end

    if (tujEnabled) then
        print("AnS found TUJ pricing source");
        AnsPriceSources:Register("TUJMarket", GetTUJPrice, "market");
        AnsPriceSources:Register("TUJRecent", GetTUJPrice, "recent");
        AnsPriceSources:Register("TUJGlobalMedian", GetTUJPrice, "globalMedian");
        AnsPriceSources:Register("TUJGlobalMean", GetTUJPrice, "globalMean");
        AnsPriceSources:Register("TUJAge", GetTUJPrice, "age");
        AnsPriceSources:Register("TUJDays", GetTUJPrice, "days");
        AnsPriceSources:Register("TUJStdDev", GetTUJPrice, "stddev");
        AnsPriceSources:Register("TUJGlobalStdDev", GetTUJPrice, "globalStdDev");
    end

    if (auctionatorEnabled) then
        print("AnS found Auctionator pricing source");
        AnsPriceSources:Register("AtrValue", Atr_GetAuctionBuyout, nil);
    end
end

function AnsCore:LoadCustomVars()
    ANS_CUSTOM_VARS = ANS_CUSTOM_VARS or {};
    AnsPriceSources:ClearCache();
    AnsPriceSources:LoadCustomVars();
end

function AnsCore:LoadCustomFilters()
    local i;
    local total = #DefaultFilters;

    local temp = {};
    local temp2 = {};

    for i = 1, total do
        temp[i] = DefaultFilters[i];
        temp2[i] = ANS_FILTER_SELECTION[i] or AnsFilterSelected[i];
    end

    local fparent = AnsFilter:New("Custom");
    fparent.subfilters = {};

    total = total + 1;
    temp[total] = fparent;
    temp2[total] = false;

    local vtotal = 1;

    for i = 1, #ANS_CUSTOM_FILTERS do
        local cf = ANS_CUSTOM_FILTERS[i];
        if ((cf.ids and cf.ids:len() > 0) or (cf.types and cf.types:len() > 0)) then
            local f = AnsFilter:New(cf.name);
            f.isSub = true;
            f.priceFn = cf.priceFn;
            
            f.isCustom = true;

            f.useGlobalMaxBuyout = cf.globalMaxBuyout;
            f.useGlobalMinStack = cf.globalMinStack;
            f.useGlobalMinQuality = cf.globalMinQuality;
            f.useGlobalMinILevel = cf.globalMinILevel;

            if (cf.types and cf.types:len() > 0) then
                f.types = { strsplit(",", string.gsub(cf.types:lower(), " ", "")) };
            end

            if (cf.subtypes and cf.subtypes:len() > 0) then
                f.subtypes = { strsplit(",", string.gsub(cf.subtypes:lower(), " ", "")) };
            end

            if (cf.ids and cf.ids:len() > 0) then
                f:ParseTSM(cf.ids);
            end

            fparent.subfilters[vtotal] = f;
            vtotal = vtotal + 1;
            total = total + 1;
            temp[total] = f;
            temp2[total] = ANS_CUSTOM_FILTER_SELECTION[i] or false;
        end
    end

    AnsFilterList = temp;
    AnsFilterSelected = temp2;
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
end

function AnsCore:MigrateCustomFilters()
    ANS_CUSTOM_FILTERS = ANS_CUSTOM_FILTERS or {};
    ANS_CUSTOM_FILTER_SELECTION = ANS_CUSTOM_FILTER_SELECTION or {};

    local i;
    local total = #ANS_CUSTOM_FILTERS;

    for i = 1, total do
        local f = ANS_CUSTOM_FILTERS[i];
        if (f.priceFn == nil) then
            f.priceFn = "";
        end

        if (f.globalMaxBuyout == nil) then
            f.globalMaxBuyout = true;
        end

        if (f.globalMinStack == nil) then
            f.globalMinStack = true;
        end

        if (f.globalMinQuality == nil) then
            f.globalMinQuality = true;
        end

        if (f.globalMinILevel == nil) then 
            f.globalMinILevel = true;
        end

        if (f.types == nil) then
            f.types = "";
        end
        if (f.subtypes == nil) then
            f.subtypes = "";
        end
    end
end