local Ans = select(2, ...);
local Utils = Ans.Utils;
local Config = Ans.Config;
local GoldTracker = Ans.Object.Register("GoldTracker", Ans.Analytics);
GoldTracker.log = {};

local guildOpen = false;
local MAX_TIME_LIMIT = 60 * 24 * 30 * 11;
local MAX_DATA_LIMIT = 20000;

local EventManager = Ans.EventManager;
local Data = Ans.Analytics.Data;

local DEFAULT_GOLD_TAG = "GOLD_LOG_";
local GOLD_LOG_TAG = DEFAULT_GOLD_TAG;
local ALL_GOLD_LOGS = {};

function GoldTracker:GetNames(tbl,includeGuilds)
    wipe(tbl);

    for k,v in pairs(ALL_GOLD_LOGS) do
        local realm = select(3, strsplit("_", k));
        for p,_ in pairs(v) do
            if (includeGuilds) then
                tinsert(tbl, realm..":"..p);
            else
                if (strmatch(p, " %- ")) then
                    tinsert(tbl, realm..":"..p);     
                end
            end
        end
    end
end

function GoldTracker:OnLoad()
    if (not Config.General().trackDataAnalytics and Config.General().trackDataAnalytics ~= nil) then
        return;
    end

    MAX_DATA_LIMIT = Config.General().maxDataLimit or 20000;
    Data:Find(DEFAULT_GOLD_TAG, ALL_GOLD_LOGS);
    GOLD_LOG_TAG = GOLD_LOG_TAG..GetRealmName();

    self.log = Data:Get(GOLD_LOG_TAG) or {};
    self.name = UnitName("player").." - "..UnitFactionGroup("player");
    if (not self.log[self.name]) then self.log[self.name] = {ledger = {}, current = 0}; end;
    self.guildName = GetGuildInfo("player");
    if (self.guildName and not self.log[self.guildName]) then self.log[self.guildName] = {ledger = {}, current = 0}; end;

    EventManager:On("PLAYER_MONEY", self.OnPlayerMoneyChange);
    EventManager:On("GUILDBANKFRAME_OPENED", self.OnGuildVaultOpened);
    EventManager:On("GUILDBANKFRAME_CLOSED", self.OnGuildVaultClosed)
    EventManager:On("GUILDBANK_UPDATE_MONEY", self.OnGuildVaultMoneyChange);
    EventManager:On("PLAYER_ENTERING_WORLD", self.OnPlayerWorld);

    self:CompactLog(self.log[self.name].ledger);

    if (self.guildName) then
        self:CompactLog(self.log[self.guildName].ledger);
    end

    if (not ALL_GOLD_LOGS[GOLD_LOG_TAG]) then
        ALL_GOLD_LOGS[GOLD_LOG_TAG] = self.log;
    end
end

function GoldTracker.OnPlayerWorld()
    GoldTracker:LogGold();
end

function GoldTracker:GetGuildLog(name)
    if (not name) then
        name = self.guildName;
    end

    local realm = select(1, strsplit(":", name));
    local realName = select(2, strsplit(":", name));
    if (realName) then
        name = realName;
    end

    if (not realName) then
        return self.log[name];
    end

    local logName = DEFAULT_GOLD_TAG..realm;
    if (ALL_GOLD_LOGS[logName]) then
        return ALL_GOLD_LOGS[logName][name];
    end

    return nil;
end

function GoldTracker:GetPlayerLog(name)
    if (not name) then
        name = self.name;
    end

    local realm = select(1, strsplit(":", name));
    local realName = select(2, strsplit(":", name));
    if (realName) then
        name = realName;
    end

    if (not realName) then
        return self.log[name];
    end

    local logName = DEFAULT_GOLD_TAG..realm;
    if (ALL_GOLD_LOGS[logName]) then
        return ALL_GOLD_LOGS[logName][name];
    end

    return nil;
end

function GoldTracker.OnGuildVaultClosed()
    guildOpen = false;
end

function GoldTracker.OnGuildVaultMoneyChange()
    if (guildOpen and GoldTracker.guildName) then
        GoldTracker:LogGuildGold();
    end
end

function GoldTracker.OnGuildVaultOpened()
    guildOpen = true;

    if (GoldTracker.guildName) then
        GoldTracker:LogGuildGold();
    end
end

function GoldTracker.OnPlayerMoneyChange()
    GoldTracker:LogGold();
end

function GoldTracker:LogGold()
    local copper = GetMoney();
    local log = self.log[self.name];
    local copperDiff = copper - log.current;
    local lcount = #log.ledger;
    local previous = log.ledger[lcount];
    local ctime = math.floor(time() / 60);

    -- combine if within same minute
    if (previous and ctime - previous.time == 0) then
        previous.change = previous.change + copperDiff;
        previous.total = copper;
    else
        tinsert(log.ledger , {time = math.floor(time() / 60), change = copperDiff, total = copper});

        if (#log.ledger > MAX_DATA_LIMIT) then
            tremove(log.ledger, 1);
        end
    end

    EventManager:Emit("GOLDLOG_UPDATE");

    log.current = copper;

    Data:Set(GOLD_LOG_TAG, self.log);
end

function GoldTracker:LogGuildGold()
    local copper = GetGuildBankMoney();
    local log = self.log[self.guildName];
    local lcount = #log.ledger;
    local previous = log.ledger[lcount];
    local copperDiff = copper - log.current;
    local ctime = math.floor(time() / 60);

    -- combine if within same minute
    if (previous and ctime - previous.time == 0) then
        previous.change = previous.change + copperDiff;
        previous.total = copper;
    else
        tinsert(log.ledger , {time = math.floor(time() / 60), change = copperDiff, total = copper});

        if (#log.ledger > MAX_DATA_LIMIT) then
            tremove(log.ledger, 1);
        end
    end

    log.current = copper;

    Data:Set(GOLD_LOG_TAG, self.log);
end

function GoldTracker:CompactLog(log)
    local lt = math.floor(time() / 60) - MAX_TIME_LIMIT;
    local i;

    for i = 1, #log do
        local l = log[i];

        if (not l or l.time < lt) then
            tremove(log, i);
            i = i - 1;
        end
    end
end

EventManager:On("ANS_DATA_READY", 
    function()
        GoldTracker:OnLoad();
    end
);

