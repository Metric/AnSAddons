local Ans = select(2, ...);
local Filter = {};
Filter.__index = Filter;

Ans.Filter = Filter;

local Utils = Ans.Utils;

local Sources = Ans.Sources;

function Filter:New(name)
    local f = {};
    setmetatable(f, Filter);

    f.name = name;
    f.minILevel = 0;
    f.minQuality = 1;
    f.maxBuyout = 0;
    f.ids = {};
    f.subfilters = {};
    f.idCount = 0;
    
    f.priceFn = "";
    f.maxPercent = 100;

    f.useGlobalMaxBuyout = true;
    f.useGlobalMinQuality = true;
    f.useGlobalMinILevel = true;
    f.useGlobalPercent = true;

    f.parent = nil;

    return f;
end

function Filter:GetPriceFn()
    local tbl = Utils:GetTable();
    
    tinsert(tbl, self);

    while (#tbl > 0) do
        local v = tremove(tbl, 1);

        if (v.priceFn and v.priceFn:len() > 0) then
            Utils:ReleaseTable(tbl);
            return v.priceFn;
        elseif (v.parent) then
            tinsert(tbl, v.parent);
        end
    end

    Utils:ReleaseTable(tbl);

    return self.priceFn;
end

function Filter:AssignOptions(ilevel, buyout, quality, maxPercent, pricingFn)
    self.maxPercent = maxPercent or 100;
    self.minILevel = ilevel;
    self.maxBuyout = buyout;
    self.minQuality = quality;

    if (self:GetPriceFn():len() == 0) then
        self.priceFn = pricingFn;
    end

    local tbl = Utils:GetTable();

    if (#self.subfilters > 0) then
        for i,v in ipairs(self.subfilters) do
            tinsert(tbl, v);
        end

        while (#tbl > 0) do
            local v = tremove(tbl, 1);

            v.maxPercent = maxPercent or 100;
            v.minILevel = ilevel;
            v.maxBuyout = buyout;
            v.minQuality = quality;
            v.priceFn = v:GetPriceFn();

            if (#v.subfilters > 0) then
                for i, v2 in ipairs(v.subfilters) do
                    tinsert(tbl, v2);
                end
            end
        end
    end

    Utils:ReleaseTable(tbl);
end

function Filter:RemoveChild(sfilter)
    if (self.subfilters) then
        local i;
        for i = 1, #self.subfilters do
            if (self.subfilters[i] == sfilter) then
                sfilter.parent = nil;
                tremove(self.subfilters, i);
                return;
            end
        end
    end
end

function Filter:AddChild(sfilter)
    if (sfilter.parent) then
        sfilter.parent:RemoveChild(sfilter);
    end

    if (not self.subfilters) then
        self.subfilters = {};
    end

    tinsert(self.subfilters, sfilter);
    sfilter.parent = self;
end

function Filter:GetPath()
    if (self.parent) then
        return self.parent:GetPath().."."..self.name;
    else
        return self.name;
    end
end

function Filter:Clone()
    local f = Filter:New(self.name);
    f.minILevel = self.minILevel;
    f.minQuality = self.minQuality;
    f.minPetLevel = self.minPetLevel;
    f.maxBuyout = self.maxBuyout;
    f.ids = self.ids;
    f.idCount = self.idCount;

    if (self.subfilters) then
        f.subfilters = {};

        for i, v in ipairs(self.subfilters) do
            f.subfilters[i] = v:Clone();
            f.subfilters[i].parent = f;
        end
    else
        f.subfilters = {};
    end

    f.priceFn = self.priceFn;
    f.maxPercent = self.maxPercent;
    f.useGlobalMaxBuyout = self.useGlobalMaxBuyout;
    f.useGlobalMinILevel = self.useGlobalMinILevel;
    f.useGlobalMinQuality = self.useGlobalMinQuality;
    f.useGlobalPercent = self.useGlobalPercent;

    f.parent = self.parent;

    return f;
end

function Filter:IdsAsString()
    local tmp = "";
    local sep = "";
    for k,v in pairs(self.ids) do
        tmp = tmp..sep..k;
        sep = ",";
    end
    return tmp;
end

function Filter:ToConfigFilter()
    local f = {
        name = self.name,
        ids = self:IdsAsString(),
        useMaxPPU = self.useGlobalMaxBuyout,
        useMinLevel = self.useGlobalMinILevel,
        useQuality = self.useGlobalMinQuality,
        usePercent = self.useGlobalPercent,
        priceFn = self.priceFn,
        children = {}
    };

    if (#self.subfilters > 0) then
        for i, v in ipairs(self.subfilters) do
            tinsert(f.children, v:ToConfigFilter());
        end
    end

    return f;
end

local function GroupFilters(groups, children)
    local temp = Utils:GetTable();

    for i,v in ipairs(children) do
        tinsert(temp, { parent = nil, root = v });
    end

    while (#temp > 0) do
        local g = tremove(temp);
        local sub = { root = g.root, children = {} };

        if (g.parent == nil) then
            groups[sub.root.name] = sub;
        else
            g.parent.children[sub.root.name] = sub;
        end

        if (#sub.root.subfilters > 0) then
            for i,v in ipairs(sub.root.subfilters) do
                tinsert(temp, { parent = sub, root = v });
            end
        end
    end

    Utils:ReleaseTable(temp);
end

function Filter:ParseTSMGroupItem(item, f, groups)
    local _, id = strsplit(":", item);
    if (id ~= nil) then
        if (_ == "group") then
            local subgroups = { strsplit("`", id) };
            local group = nil;

            if (#subgroups > 0) then
                if (groups[subgroups[1]]) then
                    group = groups[subgroups[1]];
                else
                    group = { root = Filter:New(subgroups[1]), children = {} };
                    self:AddChild(group.root);
                    groups[subgroups[1]] = group;
                end

                for k = 2, #subgroups do
                    if (group.children[subgroups[k]]) then
                        group = group.children[subgroups[k]];
                    else
                        local root = group.root;
                        local c = Filter:New(subgroups[k]);
                        local sub = { root = c, children = {} };
                        root:AddChild(c);
                        group.children[subgroups[k]] = sub;
                        group = sub;
                    end
                end
            end

            if (group == nil) then
                f = Filter:New(id);
                groups[f.name] = { root = f, children = {} };
                self:AddChild(f);
            else
                f = group.root;    
            end
        else
            if (f == nil) then
                f = Filter:New("Custom"..(#self.subfilters + 1));
                self:AddChild(f);
            end 

            if (not f.ids[item]) then
                f.ids[item] = 1;
                f.idCount = f.idCount + 1; 
            end
        end
    else
        if (f == nil) then
            f = Filter:New("Custom"..(#self.subfilters + 1));
            self:AddChild(f);
        end

        local tn = tonumber(_);
        if (tn ~= nil) then
            if (not f.ids["i:"..tn]) then
                f.ids["i:"..tn] = 1;
                f.idCount = f.idCount + 1;
            end
        end
    end

    return f;
end

function Filter:ParseTSMGroups(str)
    local i = 0;
    local f = nil;

    local groups = Utils:GetTable();
    local group = nil;

    -- setup groups
    GroupFilters(groups, self.subfilters);

    local tmp = "";
    for i = 1, #str do
        local c = str:sub(i,i);
        if (c == ",") then
            f = self:ParseTSMGroupItem(tmp, f, groups);
            tmp = "";
        else
            tmp = tmp..c;
        end
    end

    if (#tmp > 0) then
        f = self:ParseTSMGroupItem(tmp, f, groups);
    end

    Utils:ReleaseTable(groups);
end

function Filter:ParseTSMItem(item) 
    local _, id = strsplit(":", item);
    if (id ~= nil) then
        self.ids[_..":"..id] = 1;
        self.ids[item] = 1;
        self.idCount = self.idCount + 1;
    else
        local tn = tonumber(_);
        if (tn ~= nil) then
            self.ids["i:"..tn] = 1;
            self.idCount = self.idCount + 1;
        end
    end
end

function Filter:ParseTSM(ids)
    wipe(self.ids);
    self.idCount = 0;

    local tmp = "";
    -- new method so no stack overflow!
    for i = 1, #ids do
        local c = ids:sub(i,i);
        if (c == ",") then
            self:ParseTSMItem(tmp);
            tmp = "";
        else
            tmp = tmp..c;
        end
    end

    -- handle left over
    if (#tmp > 0) then
        self:ParseTSMItem(tmp);
    end
end

function Filter:HasIds()
    if (self.idCount > 0) then
        return true;
    end

    for i,v in ipairs(self.subfilters) do
        if (v:HasIds()) then
            return true;
        end
    end

    return false;
end

function Filter:IsValid(item, exact)
    if (self.subfilters and #self.subfilters > 0) then
        for i, v in ipairs(self.subfilters) do
            if (v:IsValid(item)) then
                return true;
            end
        end
    end

    local priceFn = self.priceFn;

    if (priceFn ~= nil and priceFn:len() > 0) then
        local presult = Sources:Query(priceFn, item);

        if ((type(presult) == "boolean" and presult == false) or (type(presult) == "number" and presult <= 0)) then
            return false;
        end
    end

    if (item.iLevel < self.minILevel and self.useGlobalMinILevel) then
        return false;
    end
    if (item.quality < self.minQuality and self.useGlobalMinQuality) then
        return false;
    end
    if (item.ppu >= self.maxBuyout and self.maxBuyout > 0 and self.useGlobalMaxBuyout) then
        return false;
    end
    if (item.percent > self.maxPercent and self.useGlobalPercent) then
        return false;
    end

    if (self.idCount > 0) then
        local t,id = strsplit(":", item.tsmId);
        return self.ids[item.tsmId] == 1 or (not exact and self.ids[t..":"..id] == 1);
    end

    return priceFn ~= nil and priceFn:len() > 0;
end
