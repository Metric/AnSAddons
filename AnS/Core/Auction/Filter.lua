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
    f.types = {};
    f.subtypes = {};
    f.minSize = 0;
    f.subfilters = {};
    f.typeCount = 0;
    f.subtypeCount = 0;
    f.idCount = 0;
    
    f.priceFn = "";
    f.maxPercent = 100;

    f.useGlobalMaxBuyout = true;
    f.useGlobalMinStack = true;
    f.useGlobalMinQuality = true;
    f.useGlobalMinILevel = true;
    f.useGlobalPercent = true;

    f.parent = nil;

    return f;
end

function Filter:GetSubTypes()
    local tbl = Utils:GetTable();
    
    tinsert(tbl, self);

    while (#tbl > 0) do
        local v = tremove(tbl, 1);

        if (v.subtypeCount > 0) then
            Utils:ReleaseTable(tbl);
            return v;
        elseif (v.parent) then
            tinsert(tbl, v.parent);
        end
    end

    Utils:ReleaseTable(tbl);

    return self;
end

function Filter:GetTypes()
    local tbl = Utils:GetTable();
    
    tinsert(tbl, self);

    while (#tbl > 0) do
        local v = tremove(tbl, 1);

        if (v.typeCount > 0) then
            Utils:ReleaseTable(tbl);
            return v;
        elseif (v.parent) then
            tinsert(tbl, v.parent);
        end
    end

    Utils:ReleaseTable(tbl);

    return self;
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

function Filter:AssignOptions(ilevel, buyout, quality, size, maxPercent, pricingFn)
    self.maxPercent = maxPercent or 100;
    self.minILevel = ilevel;
    self.maxBuyout = buyout;
    self.minSize = size;
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
            v.minSize = size;
            v.maxBuyout = buyout;
            v.minQuality = quality;

            local subtypes = v:GetSubTypes();
            v.subtypes = subtypes.subtypes;
            v.subtypeCount = subtypes.subtypeCount;

            local types = v:GetTypes();
            v.types = types.types;
            v.typeCount = types.typeCount;

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

function Filter:ParseTypes(types)
    if (types and types:len() > 0) then
        local trim = string.gsub(types:lower(), " ,", ",");
        trim = string.gsub(trim, ", ", ",");
        local tbl = { strsplit(",", trim) };
        self.typeCount = #tbl;
        wipe(self.types);
        for i,v in ipairs(tbl) do
            self.types[v] = 1;
        end
    end
end

function Filter:ParseSubtypes(types) 
    if (types and types:len() > 0) then
        local trim = string.gsub(types:lower(), " ,", ",");
        trim = string.gsub(trim, ", ", ",");
        local tbl = { strsplit(",", trim) };
        self.subtypeCount = #tbl;
        wipe(self.subtypes);
        for i,v in ipairs(tbl) do
            self.subtypes[v] = 1;
        end
    end
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
    f.types = self.types;
    f.subtypes = self.subtypes;
    f.minSize = self.minSize;
    f.subtypeCount = self.subtypeCount;
    f.typeCount = self.typeCount;
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
    f.useGlobalMinStack = self.useGlobalMinStack;
    f.useGlobalPercent = self.useGlobalPercent;

    f.parent = self.parent;

    return f;
end

function Filter:ParseTSMGroups(str)
    local items = { strsplit(",", str) };
    local i;

    local temp = "";
    local f = nil;

    local filters = {};
    local sep = "";

    for i = 1, #items do
        local _, id = strsplit(":", items[i]);
        if (id ~= nil) then
            if (_ == "group") then
                if (temp:len() > 0 and f ~= nil) then
                    f:ParseTSM(temp); 
                elseif (temp:len() > 0 and f == nil) then
                    f = Filter:New("Custom"..(#filters + 1));
                    f:ParseTSM(temp);
                end

                if (f ~= nil and temp:len() > 0) then
                    tinsesrt(filters, f);
                end

                sep = "";
                temp = "";
                f = Filter:New(id);
            else
                temp = temp..sep..items[i];
                sep = ",";
            end
        else
            local tn = tonumber(_);

            if(tn ~= nil) then
                temp = temp..sep.._;
                sep = ",";
            end
        end
    end

    -- take into account last amount of data
    -- or if there was never a group
    if (temp:len() > 0 and f ~= nil) then
        f:ParseTSM(temp);
    elseif (temp:len() > 0 and f == nil) then
        f = Filter:New("Custom"..(#filters + 1));
        f:ParseTSM(temp);
    end

    if(f ~= nil and temp:len() > 0) then
        tinsert(filters, f);
    end
    
    return filters;
end

function Filter:ParseTSM(str)
    local items = { strsplit(",", str) };

    self.idCount = 0;
    wipe(self.ids);

    for i,v in ipairs(items) do
        local _, id = strsplit(":", v);
        if (id ~= nil) then
            self.ids[v] = 1;
            self.idCount = self.idCount + 1;
        else
            local tn = tonumber(_);
            if (tn ~= nil) then
                self.ids["i:"..tn] = 1;
                self.idCount = self.idCount + 1;
            end
        end
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

function Filter:IsValid(item)
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
    if (item.count < self.minSize and self.useGlobalMinStack) then
        return false;
    end
    if (item.percent > self.maxPercent and self.useGlobalPercent) then
        return false;
    end

    if (self.idCount > 0) then
        local t,id = strsplit(":", item.tsmId);
        if (self.ids[item.tsmId] == 1 or self.ids[t..":"..id] == 1) then
            return true;
        end
    end

    local ttypes = self.typeCount;
    local tstypes = self.subtypeCount;
    
    local types = self.types;
    local subtypes = self.subtypes;

    if (ttypes > 0) then
        if (types[item.type] == 1) then
            if (tstypes > 0) then
                if (subtypes[item.subtype] == 1) then
                    return true;
                end 
            else
                return true;
            end
        end
    end

    return false;
end
