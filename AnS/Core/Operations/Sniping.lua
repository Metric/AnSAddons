local Ans = select(2, ...);
local Utils = Ans.Utils;
local Sources = Ans.Sources;
local Sniping = {};

local tempTbl = {};
local queueTbl = {};

local Config = Ans.Config;

Sniping.__index = Sniping;
Ans.Operations.Sniping = Sniping;

function Sniping:New(name)
    local t = {};
    setmetatable(t, Sniping);
    t:Init(name);
    return t;
end

function Sniping:Init(name)
    self.id = Utils:Guid();
    self.name = name;
    self.price = "";
    self.maxPercent = 100;
    self.minILevel = 0;
    self.maxPPU = 0;
    self.minQuality = 0;
    self.minCLevel = 0;
    self.maxCLevel = 120;
    self.exactMatch = false;
    self.search = "";
    self.recalc = false;
    self.groups = {};
    self.ids = {};
    self.idCount = 0;
    self.inheritGlobal = false;
    self.nonActiveGroups = {};

    self.config = Sniping:NewConfig(name);
end

function Sniping:NewConfig(name)
    local t  = {
        id = Utils:Guid(),
        name = name,
        price = "",
        maxPercent = 0,
        minILevel = 0,
        maxPPU = 0,
        minQuality = 0,
        exactMatch = false,
        recalc = false,
        search = "",
        groups = {},
        inheritGlobal = false,
        nonActiveGroups = {}
    };

    return t;
end

function Sniping:FromConfig(snipe)
    local n = Sniping:New(snipe.name);
    n.id = snipe.id;
    n.name = snipe.name;
    n.price = snipe.price;
    n.maxPercent = snipe.maxPercent;
    n.minILevel = snipe.minILevel;
    n.recalc = snipe.recalc;
    n.maxPPU = snipe.maxPPU;
    n.minQuality = snipe.minQuality;
    n.exactMatch = snipe.exactMatch;
    n.search = snipe.search;
    n.inheritGlobal = snipe.inheritGlobal;
    n.nonActiveGroups = snipe.nonActiveGroups or {};

    for i,v in ipairs(snipe.groups) do
        if (not n.nonActiveGroups[v]) then
            local g = Utils:GetGroupFromId(v);
            if (g) then
                tinsert(n.groups, g);
            end
        end
    end

    n.config = snipe;
    n.idCount = Utils:ParseGroups(n.groups, n.ids);
    return n;
end

function Sniping:ContainsGroup(id)
    return Utils:ContainsGroup(self.groups, id);
end

function Sniping:HasIds()
    return self.idCount > 0;
end

function Sniping:UpdatePercent(item, avg)
    if (not avg or avg <= 1) then
        return;
    end

    item.avg = avg;
    item.percent = math.floor(item.ppu / avg * 100);
end

function Sniping:IsValid(item, exact, isGroup)
    local isExact = false;
    if (exact and self.exactMatch) then
        isExact = true;
    end

    local price = self.price;
    local presult = nil;
    if (price ~= nil and #price > 0) then
        if (isGroup and item.groupId) then
            presult = Sources:Query(price, item, item.groupId);

            if(not presult or presult == 0) then
                presult = Sources:Query(price, item);
            end
        else
            presult = Sources:Query(price, item);
        end
        if ((type(presult) == "boolean" and presult == false) or (type(presult) == "number" and item.ppu > presult)) then
            return false;
        end
    end

    if (presult and type(presult) == "number" and presult > 0 and self.recalc) then
        self:UpdatePercent(item, presult);
    end

    local minlevel = self.minILevel > 0;
    if (item.iLevel < self.minILevel and self.minILevel > 0) then
        return false;
    end
    local quality = self.minQuality > 0;
    if (item.quality < self.minQuality and self.minQuality > 0) then
        return false;
    end
    local maxPPU = self.maxPPU > 0;
    if (item.ppu > self.maxPPU and self.maxPPU > 0) then
        return false;
    end
    local percent = self.maxPercent > 0;
    if (item.percent > self.maxPercent and self.maxPercent > 0) then
        return false;
    end

    local nameFilter = item.name and self.search and self.search ~= "";
    if (nameFilter and not strfind(item.name, self.search)) then
        return false;
    end

    if (self:HasIds()) then
        local t,id = strsplit(":", item.tsmId);
        return self.ids[item.tsmId] == 1 or (not isExact and self.ids[t..":"..id] == 1) or (isGroup and item.groupId and self.ids[item.groupId] == 1);
    end

    return (price ~= nil and #price > 0 and not self:HasIds()) 
        or (not self:HasIds() and nameFilter)
        or (not self:HasIds() and minlevel)
        or (not self:HasIds() and quality)
        or (not self:HasIds() and maxPPU)
        or (not self:HasIds() and percent);
end