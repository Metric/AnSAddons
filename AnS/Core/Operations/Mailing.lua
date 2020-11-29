local Ans = select(2, ...);
local Config = Ans.Config;
local Utils = Ans.Utils;
local BagScanner = Ans.BagScanner;
local Mailing = {};
Mailing.__index = Mailing;
Ans.Operations.Mailing = Mailing;

local tempTbl = {};

local PLAYER_NAME = UnitName("player")
local PLAYER_NAME_REALM = string.gsub(PLAYER_NAME.."-"..GetRealmName(), "%s+", "")

function Mailing:New(name)
    local a = {};
    setmetatable(a, Mailing);
    a:Init(name);
    return a;
end

function Mailing:Init(name)
    self.id = Utils:Guid();
    self.name = name;
    self.to = "";
    self.subject = "";
    self.keepInBags = 0;
    self.groups = {};
    self.ids = {};
    self.idCount = 0;

    self.totalToSend = 0;

    self.config = Mailing:NewConfig(name);
    self.config.id = self.id;
end

function Mailing:NewConfig(name)
    local t = {
        id = Utils:Guid(),
        name = name,
        to = "",
        subject = "",
        keepInBags = 0,
        groups = {},
        nonActiveGroups = {}
    };
    return t;
end

function Mailing:FromConfig(config)
    local a = Mailing:New(config.name);
    a.id = config.id;
    a.keepInBags = config.keepInBags;
    a.to = config.to;
    a.subject = config.subject;
    a.groups = {};
    a.nonActiveGroups = config.nonActiveGroups or {};

    for i,v in ipairs(config.groups) do
        if (not a.nonActiveGroups[v]) then
            local g = Utils:GetGroupFromId(v);
            if (g) then
                tinsert(a.groups, g);
            end
        end
    end
    
    a.pending = 0;
    a.currentGroup = nil;
    a.lastItem = nil;
    a.totalToSend = 0;
    a.itemInfo = {};
    a.total = {};
    a.config = config;
    a.idCount = Utils:ParseGroups(a.groups, a.ids);
    return a;
end

function Mailing:Track(id, count)
    self.totalToSend = self.totalToSend + count;
    self.total[id] = (self.total[id] or 0) + count;
end

function Mailing:MaxSent(id)
    return self.total[id] and self.total[id] >= self.keepInBags and self.keepInBags > 0;
end

function Mailing:ContainsItem(v)
    local _, id = strsplit(":", v.tsmId);
    if (self.ids[tsmId] or self.ids[_..":"..id] or (self.applyAll and v.quality > 0)) then
        return true;
    end

    return false;
end

function Mailing:GetAvailableItems(sendable)
    wipe(tempTbl);
    
    for i,v in ipairs(sendable) do
        local tsmId = Utils:GetTSMID(v.link);
        local _, id = strsplit(":", tsmId);
        if (self.ids[tsmId] or self.ids[_..":"..id]) then
            tinsert(tempTbl, v);
        end
    end

    return tempTbl;
end

function Mailing:Prepare(items)
	if (self.to == "" or self.to == PLAYER_NAME or self.to == PLAYER_NAME_REALM) then
		return;
    end

    if (self.subject == "") then
        self.subject = "AnS Mailing";
    end
    
    if (not items or #items == 0) then
        -- TODO: add support for sending gold
        return;
    end

    ClearSendMail();

    local itemInfo = self.itemInfo;

    for i,v in ipairs(items) do
        local slot = v.slot;
        local bag = v.bag;
        local count = v.count;
        if (not BagScanner:IsLocked(v) and not self:MaxSent(v.link)) then
            if (self.total[v.link] and self.total[v.link] + count > self.keepInBags and self.keepInBags > 0) then
                count = self.keepInBags - self.total[v.link];
            end
            self:Track(v.link, count);
            if (not itemInfo[v.link]) then
                itemInfo[v.link] = {};
            end
            tinsert(itemInfo[v.link], {bag = bag, slot = slot, count = count, ref = v});
        end
    end
end

function Mailing:Next()
    if (self.currentGroup == nil) then
        for k,v in pairs(self.itemInfo) do
            if (v) then
                self.lastItem = k;
                self.currentGroup = v;
                return 1;
            end
        end

        return 0;
    end

    return -1;
end

function Mailing:ReadyToSend()
    if (self.pending == ATTACHMENTS_MAX_SEND) then
        return true;
    end

    return false;
end

function Mailing:PendingAttachments()
    return self.pending > 0;
end

function Mailing:Process()
    if (self.currentGroup and #self.currentGroup > 0) then
        local info = tremove(self.currentGroup, 1);
        
        if (BagScanner:Exists(info.ref, true, info.count) and not BagScanner:IsLocked(info.ref)) then
            PickupContainerItem(info.bag, info.slot);
            ClickSendMailItemButton();
            self.pending = self.pending + 1;
        end

        return true;
    end

    if (self.lastItem) then
        self.itemInfo[self.lastItem] = nil;
        self.lastItem = nil;
    end

    self.currentGroup = nil;

    return false;
end

function Mailing:SendMail()
    if (self.pending == 0) then
        return;
    end
    -- TODO add support for money sending
    SetSendMailCOD(0);
    SendMail(self.to, self.subject, "");
    self.pending = 0;
end

function Mailing:Reset()
    wipe(self.itemInfo);
    wipe(self.total);
end