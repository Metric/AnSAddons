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
    self.groups = {};
    self.ids = {};
    self.idCount = 0;

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
        search = "",
        groups = {}
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
    n.maxPPU = snipe.maxPPU;
    n.minQuality = snipe.minQuality;
    n.exactMatch = snipe.exactMatch;
    n.search = snipe.search;
    

    for i,v in ipairs(snipe.groups) do
        local g = Sniping.GetGroupFromId(v);
        if (g) then
            tinsert(n.groups, g);
        end
    end

    n.config = snipe;

    return n;
end

function Sniping:ContainsGroup(id)
    for i,v in ipairs(self.groups) do
        if (v.id == id) then
            return true;
        end
    end

    return false;
end

function Sniping.GetGroupFromId(id)
    wipe(tempTbl);
    wipe(queueTbl);

    for i,v in ipairs(Config.Groups()) do
        tinsert(queueTbl, v);
    end

    while (#queueTbl > 0) do
        local g = tremove(queueTbl, 1);
        if (not tempTbl[g.id]) then
            tempTbl[g.id] = 1;
            if (g.id == id) then
                wipe(queueTbl);
                wipe(tempTbl);
                return g;
            end

            for i,v in ipairs(g.children) do
                if (not tempTbl[v.id]) then
                    tinsert(queueTbl, v);
                end
            end
        end
    end

    wipe(tempTbl);
    wipe(queueTbl);

    return nil;
end

function Sniping:ToConfig()
    local t = self.config;

    if (not t) then
        t = {
            id = self.id,
            name = self.name,
            price = self.price,
            maxPercent = self.maxPercent,
            minILevel = self.minILevel,
            maxPPU = self.maxPPU,
            minQuality = self.minQuality,
            exactMatch = self.exactMatch,
            search = self.search,
            groups = {}
        };
    else
        t.id = self.id;
        t.name = self.name;
        t.price = self.price;
        t.maxPercent = self.maxPercent;
        t.minILevel = self.minILevel;
        t.maxPPU = self.maxPPU;
        t.minQuality = self.minQuality;
        t.exactMatch = self.exactMatch;
        t.search = self.search;
    end

    wipe(t.groups);
    for i,v in ipairs(self.groups) do
        tinsert(t.groups, v.id);
    end

    return t;
end

function Sniping:ParseGroups()
    wipe(self.ids);
    wipe(tempTbl);
    wipe(queueTbl);
    self.idCount = 0;
    for i,v in ipairs(self.groups) do
        tinsert(queueTbl, v);
    end

    while (#queueTbl > 0) do
        local g = tremove(queueTbl, 1);
        if (not tempTbl[g.id]) then
            tempTbl[g.id] = 1;
            self:ParseIds(g.ids);

            for i,v in ipairs(g.children) do
                if (not tempTbl[v.id]) then
                    tinsert(queueTbl, v);
                end
            end
        end
    end

    wipe(tempTbl);
    wipe(queueTbl);
end

function Sniping:HasIds()
    return self.idCount > 0;
end

function Sniping:ParseIds(ids)
    local tmp = "";
    for i = 1, #ids do
        local c = ids:sub(i,i);
        if (c == ",") then
            self:ParseItem(tmp);
            tmp = "";
        else
            tmp = tmp..c;
        end
    end

    if (#tmp > 0) then
        self:ParseItem(tmp);
    end
end

function Sniping:ParseItem(item)
    local _, id = strsplit(":", item);
    if (id) then
        self.ids[_..":"..id] = 1;
        self.ids[item] = 1;
        self.idCount = self.idCount + 1;
    else

        local tn = tonumber(_);
        if (tn) then
            self.ids["i:"..tn] = 1;
            self.idCount = self.idCount + 1;
        end
    end
end

function Sniping:UpdatePercent(item, avg)
    if (not avg or avg <= 1) then
        return;
    end

    item.avg = avg;
    item.percent = math.floor(item.ppu / avg * 100);
end

function Sniping:IsValid(item, exact)
    local isExact = false;
    if (exact and self.exactMatch) then
        isExact = true;
    end

    local price = self.price;
    local presult = nil;
    if (price ~= nil and #price > 0) then
        presult = Sources:Query(price, item);
        if ((type(presult) == "boolean" and presult == false) or (type(presult) == "number" and presult > item.ppu)) then
            return false;
        end
    end

    if (presult and type(presult) == "number" and presult > 0) then
        self:UpdatePercent(item, presult);
    end

    if (item.iLevel < self.minILevel and self.minILevel > 0) then
        return false;
    end
    if (item.quality < self.minQuality and self.minQuality > 0) then
        return false;
    end
    if (item.ppu > self.maxPPU and self.maxPPU > 0) then
        return false;
    end
    if (item.percent > self.maxPercent and self.maxPercent > 0) then
        return false;
    end
    if (item.name and self.search and self.search ~= "" and not strfind(item.name, self.search)) then
        return false;
    end

    if (self:HasIds()) then
        local t,id = strsplit(":", item.tsmId);
        return self.ids[item.tsmId] == 1 or (not isExact and self.ids[t..":"..id] == 1);
    end

    return price ~= nil and #price > 0 and not self:HasIds();
end