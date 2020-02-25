local Ans = select(2, ...);
local Config = {};
Config.__index = Config;

ANS_CONFIG = {};

Ans.Config = Config;

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

function Config.Analytics()
    return Config.Get("analytics", {});
end

function Config.Vendor()
    return Config.Get("vendor", {});
end

function Config.Operations()
    return Config.Get("operations", {
        Auctioning = {},
        Crafting = {},
        Mailing = {},
        Shopping = {},
        Sniping = {},
        Vendoring = {},
        Warehousing = {}
    });
end

function Config.General()
    return Config.Get("general", {
        showDressing = false,
        useCoinIcons = false,
        tooltipRealmRecent = true,
        tooltipRealmMin = true,
        tooltipRealm3Day = true,
        tooltipRealmMarket = true,
        trackDataAnalytics = true
    });
end

function Config.MiniButton(v)
    if (not v) then
        return Config.Get("mini.button", 35);
    else
        Config.Set("mini.button", v);
    end
end

function Config.Sniper()
    return Config.Get("sniper", {
        source = "",
        pricing = "",
        characterBlacklist = "",
        useCommodityConfirm = false,
        dingSound = true,
        itemsPerUpdate = 20,
        itemBlacklist = {},
        scanDelay = 10,
        skipSeenGroup = false,
        chatMessageNew = true
    });
end

function Config.CustomSources()
    return Config.Get("custom.sources", {});
end

function Config.Groups(v)
    if (not v) then
        return Config.Get("groups", {});
    else
        Config.Set("groups", v);
    end
end

function Config.SelectionSniper()
    return Config.Get("selection.sniper", {});
end

function Config.SelectionBase()
    return Config.Get("selection.base", {});
end

function Config.Crafting()
    return Config.Get("crafting", {
        craftValue = "",
        materialCost = "",
        excludeCooldowns = false,
        tradeWindowPosition = nil
    });
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