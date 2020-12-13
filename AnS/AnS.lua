local Core = select(2, ...);

local TUJDB = Core.Database.TUJ;
local TSMDB = Core.Database.TSM;

local Sources = Core.Sources;

local Utils = Core.Utils;
local Groups = Core.Utils.Groups;

local Config = Core.Config;

local MinimapIcon = Core.MinimapIcon;
local EventManager = Core.EventManager;
local Analytics = Core.Analytics;
local Operations = Core.Operations;
local SnipingOperation = Operations.Sniping;

local DefaultGroups = Core.Data;
local AuctionQuery = Core.Auctions.Query;
local Crafting = Core.Crafting;
local Destroy = Core.Destroy;
local Draggable = Utils.Draggable;

local AHFrame = nil;
local AH_TAB_CLICK = nil;

-- temporary for now to make sure
-- ANS_FILTERS exist in some form
-- even if you did not have it originally
ANS_FILTERS = ANS_FILTERS or {};

Ans = {};
Ans.__index = Ans;

Ans.API = Core;

-- slash commands for hiding minimap icon
-- and access ans window when icon is hidden
SlashCmdList["ANS_SLASHANS"] = function(msg)
    if (msg == "") then
        AnsMainWindow:Toggle();
    elseif (msg == "resetwindows") then
        Draggable.Reset();
    elseif (msg == "destroy") then
        if (AnsDestroyWindow) then
            AnsDestroyWindow:Populate();
            AnsDestroyWindow:Show();
        end
    end
end
SLASH_ANS_SLASHANS1 = "/ans";

SlashCmdList["ANS_SLASHMINIMAP"] = function(msg)
	if (msg == "") then
		if (Config.General().minimapShown) then
			Config.General().minimapShown = false;
			Ans.MiniButton:Hide();
		else
			Config.General().minimapShown = true;
			Ans.MiniButton:Show();
		end
	else
		local deg = tonumber(msg);
		Ans.MiniButton.angle = deg;
		Ans.MiniButton:Reposition();
		Ans.SaveMiniButton(deg);
	end
end
SLASH_ANS_SLASHMINIMAP1 = "/ansminimap";

StaticPopupDialogs["ANS_NO_PRICING"] = {
    text = "Looks like, you have no data pricing source! TheUndermineJournal, TSM, and AnsAuctionData are currently supported.",
    button1 = "OKAY",
    OnAccept = function() end,
    timeout = 0,
    whileDead = false,
    hideOnEscape = true,
    preferredIndex = 3
};

local TUJOnlyPercentFn = "tujmarket";
local TSMOnlyPercentFn = "dbmarket";
local TUJAndTSMPercentFn = "avg(dbmarket,tujmarket)";
local AnsOnlyPercentFn = "avg(ansrecent,ansmarket)";
local TSMMaterialCost = "min(dbmarket, first(vendorbuy, dbminbuyout))";
local TSMCraftingValue = "first(dbminbuyout, dbmarket)";
local AnsMaterialCost = "min(ansmarket, first(vendorbuy, ansrecent))";
local AnsCraftingValue = "first(ansmin, ansmarket)";
local TujMatCraftValue = "min(tujmarket, vendorbuy)";

local function AuctionTab_OnClick(self, button, down, index)
    AH_TAB_CLICK(self, button, down, index);

    for i = 1, AHFrame.numTabs do
        local tab = _G["AuctionFrameTab"..i];
        if (tab.displayMode) then
            for k,v in ipairs(tab.displayMode) do
                if (AHFrame[v]) then
                    AHFrame[v]:Hide();
                end
            end
        end
    end

    if (self.displayMode) then
        for k,v in ipairs(self.displayMode) do
            if (AHFrame[v]) then
                AHFrame[v]:Show();
            end
        end
    end
end

local function AddRetailAHTab(name, displayMode)
    local n = #AHFrame.Tabs + 1;
    local lastTab = AHFrame.Tabs[n - 1];
    local framename = "AuctionHouseFrameTab"..n;
    local frame = CreateFrame("BUTTON", framename, AHFrame, "AuctionHouseFrameDisplayModeTabTemplate");

    frame:SetID(n);
    frame:SetText(name);
    frame:SetNormalFontObject(_G["AnsFontOrange"]);
    frame:SetPoint("LEFT", lastTab, "RIGHT", -15, 0);
    frame.displayMode = displayMode;
    frame:HookScript("OnClick", function() AHFrame:SetTitle(name) end);

    tinsert(AuctionHouseFrame.Tabs, frame);
    AuctionHouseFrame.tabsForDisplayMode[displayMode] = n;

    PanelTemplates_SetNumTabs(AuctionHouseFrame, n);
end

local function AddClassicAHTab(name, displayMode)
    local n = AHFrame.numTabs + 1;
    local lastTab = _G["AuctionFrameTab"..(n - 1)];
    local framename = "AuctionFrameTab"..n;
    local frame = CreateFrame("BUTTON", framename, AHFrame, "AuctionTabTemplate");

    frame:SetID(n);
    frame:SetText(name);
    frame:SetNormalFontObject(_G["AnsFontOrange"]);
    frame:SetPoint("LEFT", lastTab, "RIGHT", -15, 0);
    frame.displayMode = displayMode;
    frame:SetScript("OnClick", AuctionTab_OnClick);

    PanelTemplates_SetNumTabs(AHFrame, n);
    PanelTemplates_EnableTab(AHFrame, n);

    if (AH_TAB_CLICK == nil) then
        AH_TAB_CLICK = AuctionFrameTab_OnClick;
        AuctionFrameTab_OnClick = AuctionTab_OnClick;
    end
end

function Ans:AddAHTab(name, displayMode)
    if (Utils.IsClassic()) then
        AddClassicAHTab(name, displayMode);
    else
        AddRetailAHTab(name, displayMode);
    end
end

function Ans:RegisterEvents(frame)
    self.frame = frame;

    frame:RegisterEvent("VARIABLES_LOADED");
    frame:RegisterEvent("ADDON_LOADED");

    Crafting:RegisterEvents(frame);
    Analytics:RegisterEvents(frame);
    AuctionQuery:RegisterEvents(frame);
    Destroy:RegisterEvents(frame);
end

function Ans:AddOnLoaded(...)
    local addonName = select(1, ...);
    if (addonName:lower() == "blizzard_auctionhouseui" or addonName:lower() == "blizzard_auctionui") then
        AHFrame = AuctionHouseFrame or AuctionFrame;
    end
end

function Ans:EventHandler(frame, event, ...)
    EventManager:Emit(event, ...);

    if (event == "ADDON_LOADED") then
        self:AddOnLoaded(...);
    end

    if (event == "VARIABLES_LOADED") then 
        self:OnLoad();
    end
end

function Ans:OnUpdate(elapsed)
    EventManager:Emit("UPDATE", elapsed);
end

function Ans.SaveMiniButton(angle)
    Config.MiniButton(angle);
end

local function CreateMiniButton()
    Ans.MiniButton = MinimapIcon:Acquire("AnsMiniButton", "Interface\\AddOns\\AnS\\Images\\ansicon", 
    function() AnsMainWindow:Toggle() end, 
    function() 
        if (AnsDestroyWindow) then
            AnsDestroyWindow:Populate(false);
            AnsDestroyWindow:Show();
        end
    end,
    Draggable.Reset,
    Ans.SaveMiniButton, Config.MiniButton(), {"|cFFCC00FFAnS ["..GetAddOnMetadata("AnS", "Version").."]", "Click to Toggle", "Click & Drag to Move", "Ctrl+Click to Reset Window Positions", "Right Click to Show Destroy Window"});

    if (Config.General().minimapShown) then
        Ans.MiniButton:Show();
    else
        Ans.MiniButton:Hide();
    end
end

function Ans:OnLoad()
    self:Migrate();
    self:RegisterPriceSources();

    CreateMiniButton();

    Groups.BuildGroupPaths(DefaultGroups);
    Groups.BuildGroupPaths(Config.Groups());
    EventManager:Emit("ANS_DATA_READY");
end

function Ans:MigrateFiltersToGroups(parent, root)
    for i,f in ipairs(parent) do
        local t = {
            id = Utils.Guid(),
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

function Ans:MigrateFiltersToSnipingOperations(items, parentName)
    for i,f in ipairs(items) do
        local snipeName = f.name;
        if (parentName) then
            snipeName = parentName.."."..f.name;
        end

        if (f.priceFn and #f.priceFn > 0) then
            local tmp = SnipingOperation.Config(snipeName);
            tmp.price = f.priceFn;
            tmp.exactMatch = f.exactMatch;
            if (f.id) then
                tinsert(tmp.groups, f.id);
            end
            tinsert(Config.Operations().Sniping, tmp);
        end

        if (#f.children > 0) then
            self:MigrateFiltersToSnipingOperations(f.children, snipeName);
        end
    end
end

function Ans:RegisterPriceSources()
    local tsmEnabled = false;
    local tujEnabled = false;
    local ansEnabled = false;
    
    --local auctionatorEnabled = false;

    -- if (Utils.IsAddonEnabled("Auctionator") and Atr_GetAuctionBuyout) then
    --    auctionatorEnabled = true; 
    -- end
    
    if (TSM_API or TSMAPI) then
        tsmEnabled = true;
    end

    if (AnsAuctionData) then
        ansEnabled = true;
    end

    if (TUJMarketInfo) then
        tujEnabled = true;
    end

    -- set sniping default source
    if (tujEnabled and tsmEnabled and (not Config.Sniper().source or Config.Sniper().source:len() == 0)) then
        print("AnS: setting default tuj and tsm source");
        Config.Sniper().source = TUJAndTSMPercentFn;
    elseif (tujEnabled and not tsmEnabled and (not Config.Sniper().source or Config.Sniper().source:len() == 0)) then
        print("AnS: setting default tuj source");
        Config.Sniper().source = TUJOnlyPercentFn;
    elseif (tsmEnabled and not tujEnabled and (not Config.Sniper().source or Config.Sniper().source:len() == 0)) then
        print("AnS: setting default tsm source");
        Config.Sniper().source = TSMOnlyPercentFn;
    elseif (ansEnabled and (not Config.Sniper().source or Config.Sniper().source:len() == 0)) then
        print("AnS: setting default AnsAuctionData source");
        Config.Sniper().source = AnsOnlyPercentFn;
    end

    -- set default crafting stuff
    if (tujEnabled and tsmEnabled and (not Config.Crafting().materialCost or Config.Crafting().materialCost:len() == 0)) then
        Config.Crafting().materialCost = TSMMaterialCost;
        Config.Crafting().craftValue = TSMCraftingValue;
    elseif (tujEnabled and not tsmEnabled and (not Config.Crafting().materialCost or Config.Crafting().materialCost:len() == 0)) then
        Config.Crafting().materialCost = TujMatCraftValue;
        Config.Crafting().craftValue = TujMatCraftValue;
    elseif (tsmEnabled and not tujEnabled and (not Config.Crafting().materialCost or Config.Crafting().materialCost:len() == 0)) then
        Config.Crafting().materialCost = TSMMaterialCost;
        Config.Crafting().craftValue = TSMCraftingValue;
    elseif (ansEnabled and (not Config.Crafting().materialCost or Config.Crafting().materialCost:len() == 0)) then
        Config.Crafting().materialCost = AnsMaterialCost;
        Config.Crafting().craftValue = AnsCraftingValue;
    end

    if (not tsmEnabled and not tujEnabled and not ansEnabled) then
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
        Sources:Register("AvgSell", TSMDB.GetPrice, "AvgSell");
        Sources:Register("AvgBuy", TSMDB.GetPrice, "AvgBuy");
        Sources:Register("Destroy", TSMDB.GetPrice, "Destroy");
        Sources:Register("MaxBuy", TSMDB.GetPrice, "MaxBuy");
        Sources:Register("MaxSell", TSMDB.GetPrice, "MaxSell");
        Sources:Register("NumInventory", TSMDB.GetPrice, "NumInventory");
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
        Sources:Register("ANSRegionRecent", AnsAuctionData.GetRegionValue, "recent");
        Sources:Register("ANSRegionMarket", AnsAuctionData.GetRegionValue, "market");
        Sources:Register("ANSRegionMin", AnsAuctionData.GetRegionValue, "min");
        Sources:Register("ANSRegion3Day", AnsAuctionData.GetRegionValue, "3day");
    end

    -- if (auctionatorEnabled) then
    --     print("AnS: found Auctionator pricing source");
    --     Sources:Register("AtrValue", function(link, key)
    --         if (strfind(link, "[ip]:%d+%(%d+%)")) then
    --             return 0;
    --         end
            
    --         return Atr_GetAuctionBuyout(link);
    --     end, nil);
    -- end
end

function Ans:Migrate()

    Config.MigrateCopy("ANS_ANALYTICS_DATA", Config.Analytics(), true);
    Config.MigrateArray("ANS_CUSTOM_VARS", Config.CustomSources(), true);
    Config.MigrateDict("ANS_GLOBAL_SETTINGS", Config.General(),
        {
            ["showDressing"] = "showDressing",
            ["useCoinIcons"] = "useCoinIcons",
            ["tooltipRealm3Day"] = "tooltipRealm3Day",
            ["tooltipRealmMarket"] = "tooltipRealmMarket",
            ["tooltipRealmRecent"] = "tooltipRealmRecent",
            ["tooltipRealmMin"] = "tooltipRealmMin"
        }
    );
    Config.MigrateDict("ANS_GLOBAL_SETTINGS", Config.Sniper(),
        {
            ["percentFn"] = "source",
            ["priceFn"] = "pricing",
            ["dingSound"] = "dingSound",
            ["itemsPerUpdate"] = "itemsPerUpdate",
            ["useCommodityConfirm"] = "useCommodityConfirm",
            ["characterBlacklist"] = "characterBlacklist"
        },
        true
    );

    self:MigrateFiltersToGroups(ANS_FILTERS, Config.Groups());
    self:MigrateFiltersToSnipingOperations(ANS_FILTERS);

    wipe(ANS_FILTERS);

    if (#Config.Groups() == 0) then
        Config.Groups(DefaultGroups);
    end
end