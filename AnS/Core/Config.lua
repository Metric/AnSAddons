-- GLOBAL
ANS_CONFIG = {};

local Ans = select(2, ...);
local Config = Ans.Object.Register("Config");

-- default config holders
local GENERAL_DEFAULT = {
    showDressing = false,
    useCoinIcons = false,
    tooltipRealmRecent = true,
    tooltipRealmMin = true,
    tooltipRealm3Day = true,
    tooltipRealmMarket = true,
    tooltipRegionRecent = false,
    tooltipRegionMin = false,
    tooltipRegion3Day = false,
    tooltipRegionMarket = false,
    tooltipRegionSeen = false,
    trackDataAnalytics = true,
    showDebugWindow = false,
    saveWindowLocations = true,
    minimapShown = true,
    showId = true,
    maxDataLimit = 20000,
    defaultTimeMode = 3,
    showPostCancel = true,
    showMailSend = true,
};

local OPERATIONS_DEFAULT = {
    Auctioning = {},
    Crafting = {},
    Mailing = {},
    Shopping = {},
    Sniping = {},
    Vendoring = {},
    Warehousing = {}
};

local SNIPER_DEFAULT = {
    source = "",
    pricing = "",
    characterBlacklist = {},
    useCommodityConfirm = true, -- set to true as default, as I could see someone new accidentally buying more than they expected without it
    dingSound = true,
    itemsPerUpdate = 20,
    itemBlacklist = {},
    scanDelay = 2,
    skipSeenGroup = false,
    chatMessageNew = true,
    clevel = "0-120",
    minQuality = 1,
    qualities = {},
    ilevel = 0,
    reverseSort = false,
    flashWoWIcon = true,
    soundKitSound = "AUCTION_WINDOW_OPEN",
    ignoreSingleStacks = false,
    ignoreGroupMaxPercent = false,
};

local CRAFTING_DEFAULT = {
    craftValue = "",
    materialCost = "",
    excludeCooldowns = false,
    destroyMaxQuality = 2,
    disenchantMinValue = "0c",
    autoShowDestroying = false,
    hideProfit = false,
    hideCost = false,
};

local WINDOWS_DEFAULT = {};

local ANALYTICS_DEFAULT = {};

local VENDOR_DEFAULT = {};
local GROUPS_DEFAULT = {};
local SOURCES_DEFAULT = {};
local SNIPER_SELECTION_DEFAULT = {};
local SNIPER_SELECTION_BASE_DEFAULT = {};
-- end default table holders

function Config.Get(name, default)
    ANS_CONFIG = ANS_CONFIG or {};
    local v = ANS_CONFIG[name] or default or {};
    ANS_CONFIG[name] = v;
    Config.EnsureDefaults(v, default);
    return v;
end

function Config.Set(name, value)
    ANS_CONFIG = ANS_CONFIG or {};
    ANS_CONFIG[name] = value;
end

function Config.EnsureDefaults(config, default)

    if (type(config) ~= "table") then
        return;
    end

    for k,v in pairs(default) do
        if (config[k] == nil) then
            config[k] = v;
        end
    end
end

function Config.Windows()
    return Config.Get("windows", WINDOWS_DEFAULT);
end

function Config.Analytics()
    return Config.Get("analytics", ANALYTICS_DEFAULT);
end

function Config.Vendor()
    return Config.Get("vendor", VENDOR_DEFAULT);
end

function Config.Operations()
    return Config.Get("operations", OPERATIONS_DEFAULT);
end

function Config.General()
    return Config.Get("general", GENERAL_DEFAULT);
end

function Config.MiniButton(v)
    if (not v) then
        return Config.Get("mini.button", 35);
    else
        Config.Set("mini.button", v);
    end
end

function Config.Sniper()
    return Config.Get("sniper", SNIPER_DEFAULT);
end

function Config.CustomSources()
    return Config.Get("custom.sources", SOURCES_DEFAULT);
end

function Config.Groups(v)
    if (not v) then
        return Config.Get("groups", GROUPS_DEFAULT);
    else
        Config.Set("groups", v);
    end
end

function Config.SelectionSniper()
    return Config.Get("selection.sniper", SNIPER_SELECTION_DEFAULT);
end

function Config.SelectionBase()
    return Config.Get("selection.base", SNIPER_SELECTION_BASE_DEFAULT);
end

function Config.Crafting()
    return Config.Get("crafting", CRAFTING_DEFAULT);
end

function Config.MigrateArray(orig, config, clear)
    local oldConfig =_G[orig];
    if (not oldConfig) then
        return false;
    end

    for i,v in ipairs(oldConfig) do
        tinsert(config, v);
    end

    if (clear) then
        _G[orig] = nil;
    end

    return true;
end

function Config.MigrateDict(orig, config, oldToNewMap, clear)
    local oldConfig = _G[orig];
    
    if (not oldConfig) then
        return false;
    end

    for k,v in pairs(oldToNewMap) do
        config[v] = oldConfig[k];
    end

    if (clear) then
        _G[orig] = nil;
    end

    return true;
end

function Config.MigrateCopy(orig, config, clear)
    local oldConfig = _G[orig];
    if (not oldConfig or type(oldConfig) ~= "table") then
        return false;
    end

    for k,v in pairs(oldConfig) do
        config[k] = v;
    end

    if (clear) then
        _G[orig] = nil;
    end

    return true;
end

function Config.MigrateRaw(orig, config)
    local oldConfig = _G[orig];
    
    if (not oldConfig) then
        return false;
    end

    Config.Set(config, oldConfig);

    return true;
end

function Config.MigrateFunc(orig, config, fn, clear)
    local oldConfig = _G[orig];
    if (not oldConfig or not fn) then
        return false;
    end

    fn(oldConfig, config);

    if (clear) then
        _G[orig] = nil;
    end

    return true;
end