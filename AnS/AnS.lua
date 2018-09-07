AnsCore = {};
AnsCore.__index = AnsCore;

AnsCustomFilter = {};
AnsCustomFilter.__index = AnsCustomFilter;

StaticPopupDialogs["ANS_TSM_MOD"] = {
    text = "Looks like you have TSM installed, but the required lua modification is not here for AnS to grab TSM data! See readme for details.",
    button1 = "OKAY",
    OnAccept = function() end,
    timeout = 0,
    whileDead = false,
    hideOnEscape = true,
    preferredIndex = 3
};

StaticPopupDialogs["ANS_NO_PRICING"] = {
    text = "Looks like, you have no data pricing source! TheUndermineJournal, TSM (with lua mod), and Auctionator are currently supported.",
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

function AnsAuctionDB.GetRealmItemData(link, key) 
    local id = AnsUtils:GetTSMID(link);

    if(TSM_MAJOR_VERSION == "3") then
        return AnsTSMAuctionDB:GetRealmItemData(id, key)
    else
        return AnsTSMAuctionDB.GetRealmItemData(id, key);
    end
end

function AnsAuctionDB.GetRegionItemData(link, key)
    local id = AnsUtils:GetTSMID(link);

    if (TSM_MAJOR_VERSION == "3") then
        return AnsTSMAuctionDB:GetRegionItemData(id, key)
    else
        return AnsTSMAuctionDB.GetRegionItemData(id, key);
    end
end

function AnsAuctionDB.GetRegionSaleInfo(link, key)
    local r = AnsAuctionDB.GetRegionItemData(link, key);
    if (not r) then r = 0; end;
    return r / 100;
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
end

function AnsCore:StoreDefaultFilters()
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
    
    if (AnsTSMAuctionDB) then
        -- do note, doing this we basically steal the data
        -- from TSM and only way to allow TSM to operate
        -- further is to remove line 23 from TradeSkillMaster_AppHelper.lua
        -- tsmEnabled = AnsTSMHelper:GrabData();
        tsmEnabled = true;
    end

    if (AnsUtils:IsAddonEnabled("TradeSkillMaster") and not AnsTSMAuctionDB) then
        StaticPopup_Show("ANS_TSM_MOD");
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
        AnsPriceSources:Register("DBMarket", AnsAuctionDB.GetRealmItemData, "marketValue");
        AnsPriceSources:Register("DBMinBuyout", AnsAuctionDB.GetRealmItemData, "minBuyout");
        AnsPriceSources:Register("DBHistorical", AnsAuctionDB.GetRealmItemData, "historical");
        AnsPriceSources:Register("DBRegionMinBuyoutAvg", AnsAuctionDB.GetRegionItemData, "regionMinBuyout");
        AnsPriceSources:Register("DBRegionMarketAvg", AnsAuctionDB.GetRegionItemData, "regionMarketValue");
        AnsPriceSources:Register("DBRegionHistorical", AnsAuctionDB.GetRegionItemData, "regionHistorical");
        AnsPriceSources:Register("DBRegionSaleAvg", AnsAuctionDB.GetRegionItemData, "regionSale");
        AnsPriceSources:Register("DBRegionSaleRate", AnsAuctionDB.GetRegionSaleInfo, "regionSalePercent");
        AnsPriceSources:Register("DBRegionSoldPerDay", AnsAuctionDB.GetRegionSaleInfo, "regionSoldPerDay");
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

function AnsCore:LoadCustomFilters()
    local i;
    local total = #DefaultFilters;

    local temp = {};
    local temp2 = {};

    for i = 1, total do
        temp[i] = DefaultFilters[i];
        temp2[i] = AnsFilterSelected[i];
    end

    local fparent = AnsFilter:New("Custom");
    fparent.subfilters = {};

    total = total + 1;
    temp[total] = fparent;
    temp2[total] = false;

    local vtotal = 1;

    for i = 1, #ANS_CUSTOM_FILTERS do
        local cf = ANS_CUSTOM_FILTERS[i];
        if (cf.ids ~= nil and cf.ids:len() > 0) then
            local f = AnsFilter:New(cf.name);
            f.isSub = true;
            f.priceFn = cf.priceFn;
            
            f.useGlobalMaxBuyout = cf.globalMaxBuyout;
            f.useGlobalMinStack = cf.globalMinStack;
            f.useGlobalMinQuality = cf.globalMinQuality;
            f.useGlobalMinILevel = cf.globalMinILevel;

            f:ParseTSM(cf.ids);
            fparent.subfilters[vtotal] = f;
            vtotal = vtotal + 1;
            total = total + 1;
            temp[total] = f;
            temp2[total] = false;
        end
    end

    AnsFilterList = temp;
    AnsFilterSelected = temp2;
end

function AnsCore:MigrateGlobalSettings()
    if (ANS_GLOBAL_SETTINGS.rescanTime == nil) then
        ANS_GLOBAL_SETTINGS.rescanTime = 0;
    end
end

function AnsCore:MigrateCustomFilters()
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
    end
end