AnsCore = {};
AnsCore.__index = AnsCore;

AnsCustomFilter = {};
AnsCustomFilter.__index = AnsCustomFilter;

local TUJOnlyPercentFn = "avg(tujmarket,tujrecent,tujglobalmedian,tujglobalmean)";
local TSMOnlyPercentFn = "avg(dbmarket,dbminbuyout,dbhistorical)";
local TUJAndTSMPercentFn = "min(avg(tujmarket,tujrecent,tujglobalmedian,tujglobalmean),avg(dbmarket,dbminbuyout,dbhistorical))";

local DefaultFilters = {};
local TUJTempTable = {};

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

    local auctiondb = nil;

    if (TSM) then
        for k,v in pairs(TSM) do
            print("TSM: "..k);
        end
    end
    
    if (AnsTSMAuctionDB) then
        -- do note, doing this we basically steal the data
        -- from TSM and only way to allow TSM to operate
        -- further is to remove line 23 from TradeSkillMaster_AppHelper.lua
        -- tsmEnabled = AnsTSMHelper:GrabData();
        tsmEnabled = true;
        auctiondb = AnsTSMAuctionDB;
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

    if (tsmEnabled) then
        print("found TSM pricing source");
        AnsPriceSources:Register("DBMarket", auctiondb.GetRealmItemData, "marketValue");
        AnsPriceSources:Register("DBMinBuyout", auctiondb.GetRealmItemData, "minBuyout");
        AnsPriceSources:Register("DBHistorical", auctiondb.GetRealmItemData, "historical");
        AnsPriceSources:Register("DBRegionMinBuyoutAvg", auctiondb.GetRegionItemData, "regionMinBuyout");
        AnsPriceSources:Register("DBRegionMarketAvg", auctiondb.GetRegionItemData, "regionMarketValue");
        AnsPriceSources:Register("DBRegionHistorical", auctiondb.GetRegionItemData, "regionHistorical");
        AnsPriceSources:Register("DBRegionSaleAvg", auctiondb.GetRegionItemData, "regionSale");
        AnsPriceSources:Register("DBRegionSaleRate", auctiondb.GetRegionSaleInfo, "regionSalePercent");
        AnsPriceSources:Register("DBRegionSoldPerDay", auctiondb.GetRegionSaleInfo, "regionSoldPerDay");
    end

    if (tujEnabled) then
        print("found TUJ pricing source");
        AnsPriceSources:Register("TUJMarket", GetTUJPrice, "market");
        AnsPriceSources:Register("TUJRecent", GetTUJPrice, "recent");
        AnsPriceSources:Register("TUJGlobalMedian", GetTUJPrice, "globalMedian");
        AnsPriceSources:Register("TUJGlobalMean", GetTUJPrice, "globalMean");
        AnsPriceSources:Register("TUJAge", GetTUJPrice, "age");
        AnsPriceSources:Register("TUJDays", GetTUJPrice, "days");
        AnsPriceSources:Register("TUJStdDev", GetTUJPrice, "stddev");
        AnsPriceSources:Register("TUJGlobalStdDev", GetTUJPrice, "globalStdDev");
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