local Ans = select(2, ...);
local Utils = Ans.Utils;
local Sources = Ans.Sources;
local Sniping = Ans.Object.Register("Sniping", Ans.Operations);
local Exporter = Ans.Exporter;

local tempTbl = {};
local queueTbl = {};

local Config = Ans.Config;
local Groups = Utils.Groups;

function Sniping.IsValidConfig(c)
    return c.name and c.price 
        and c.maxPercent and c.minILevel 
        and c.maxPPU and c.minQuality
        and type(c.exactMatch) == "boolean" and type(c.recalc) == "boolean"
        and c.search and c.groups
        and type(c.inheritGlobal) == "boolean";
end

function Sniping.PrepareExport(snipe)
    local n = {};
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
    n.groups = {};

    for i,v in ipairs(snipe.groups) do
        local g = Groups.GetGroupFromId(v);
        if (g) then
            tinsert(n.groups, g.path);
        end
    end

    return n;
end

function Sniping.Config(name)
    local t  = {
        id = Utils.Guid(),
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

function Sniping.From(snipe)
    local n = Sniping:New();
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
    n.groups = {};
    n.ids = {};

    for i,v in ipairs(snipe.groups) do
        if (not n.nonActiveGroups[v]) then
            local g = Groups.GetGroupFromId(v);
            if (g) then
                tinsert(n.groups, g);
            end
        end
    end

    n.config = snipe;
    n.idCount = Groups.ParseGroups(n.groups, n.ids);
    return n;
end

function Sniping:ContainsGroup(id)
    return Groups.ContainsGroup(self.groups, id);
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

function Sniping:IsValid(item, exact)
    local isExact = false;
    if (exact and self.exactMatch) then
        isExact = true;
    end

    local price = self.price;
    local presult = nil;
    if (price ~= nil and #price > 0) then
        presult = Sources:Query(price, item);
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
        return self.ids[item.tsmId] == 1 or (not isExact and self.ids[t..":"..id] == 1);
    end

    return (price ~= nil and #price > 0 and not self:HasIds()) 
        or (not self:HasIds() and nameFilter)
        or (not self:HasIds() and minlevel)
        or (not self:HasIds() and quality)
        or (not self:HasIds() and maxPPU)
        or (not self:HasIds() and percent);
end