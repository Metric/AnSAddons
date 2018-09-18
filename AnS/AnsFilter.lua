AnsFilter = {};
AnsFilter.__index = AnsFilter;

AnsFilterList = {};
AnsFilterSelected = {};

function AnsFilter:New(name)
    local f = {};
    setmetatable(f, AnsFilter);

    f.name = name;
    f.minILevel = 0;
    f.minQuality = 1;
    f.minPetLevel = 0;
    f.maxBuyout = 0;
    f.ids = {};
    f.types = {};
    f.subtypes = {};
    f.minSize = 0;
    f.isSub = false;
    f.subfilters = nil;
    f.priceFn = "";
    f.maxPercent = 100;
    f.useGlobalMaxBuyout = true;
    f.useGlobalMinStack = true;
    f.useGlobalMinQuality = true;
    f.useGlobalMinILevel = true;

    f.isCustom = false;

    return f;
end

function AnsFilter:Clone()
    local f = AnsFilter:New(self.name);
    f.minILevel = self.minILevel;
    f.minQuality = self.minQuality;
    f.minPetLevel = self.minPetLevel;
    f.maxBuyout = self.maxBuyout;
    f.ids = self.ids;
    f.types = self.types;
    f.subtypes = self.subtypes;
    f.minSize = self.minSize;
    f.isSub = self.isSub;

    if (self.subfilters) then
        f.subfilters = {};

        for i, v in ipairs(self.subfilters) do
            f.subfilters[i] = v:Clone();
        end
    else
        f.subfilters = nil;
    end

    f.isCustom = self.isCustom;

    f.priceFn = self.priceFn;
    f.maxPercent = self.maxPercent;
    f.useGlobalMaxBuyout = self.useGlobalMaxBuyout;
    f.useGlobalMinILevel = self.useGlobalMinILevel;
    f.useGlobalMinQuality = self.useGlobalMinQuality;
    f.useGlobalMinStack = self.useGlobalMinStack;
    
    return f;
end

function AnsFilter:Export()
    return "group:"..self.name..","..self:ExportIds();
end

function AnsFilter:ExportIds()
    local str = "";
    local sep = "";

    local i;

    for i = 1, #self.ids do
        str = str..sep..self.ids[i];
        sep = ",";
    end

    return str;
end

function AnsFilter:ParseTSMGroups(str)
    local items = { strsplit(",", str) };
    local i;

    local temp = "";
    local f = nil;

    local filters = {};
    local fcount = 1;
    local sep = "";

    for i = 1, #items do
        local _, id = strsplit(":", items[i]);
        if (id ~= nil) then
            if (_ == "group") then
                if (temp:len() > 0 and f ~= nil) then
                    f:ParseTSM(temp); 
                elseif (temp:len() > 0 and f == nil) then
                    f = AnsFilter:New("Custom"..fcount);
                    f:ParseTSM(temp);
                end

                if (f ~= nil and temp:len() > 0) then
                    filters[fcount] = f;
                    fcount = fcount + 1;
                end

                sep = "";
                temp = "";
                f = AnsFilter:New(id);
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
        f = AnsFilter:New("Custom"..fcount);
        f:ParseTSM(temp);
    end

    if(f ~= nil and temp:len() > 0) then
        filters[fcount] = f;
    end
    
    return filters;
end

function AnsFilter:ParseTSM(str)
    local items = { strsplit(",", str) };
    local i;

    wipe(self.ids);

    for i = 1, #items do
        local _, id  = strsplit(":", items[i]);
        if (id ~= nil) then
            tinsert(self.ids, items[i]); 
        else
            local tn = tonumber(_);
            if (tn ~= nil) then
                tinsert(self.ids, "i:"..tn);
            end 
        end
    end
end

function AnsFilter:IsValid(item)
    if (self.subfilters ~= nil) then
        local fi;
        local tsubs = #self.subfilters;
        for fi = 1, tsubs do
            local filter = self.subfilters[fi];
            if (filter:IsValid(item)) then
                return true;
            end
        end

        return false;
    end

    if (self.priceFn ~= nil and self.priceFn:len() > 0) then
        local presult = AnsPriceSources:Query(self.priceFn, item);

        if ((type(presult) == "boolean" and presult == false) or (type(presult) == "number" and presult <= 0)) then
            return false;
        end
    end

    if (not self.isCustom) then
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
        if (item.percent > self.maxPercent) then
            return false;
        end
    end

    local tids = #self.ids;
    if (tids > 0) then
        local i;
        for i = 1, tids do
            if (self.ids[i] == item.tsmId or string.find(self.ids[i], item.tsmId)) then
                return true;
            end
        end
    end

    local ttypes = #self.types;
    if (ttypes > 0) then
        local i;
        for i = 1, ttypes do
            if (self.types[i] == item.type) then
                local tstypes = #self.subtypes;
                if (tstypes > 0) then
                    local j;
                    for j = 1, tstypes do
                        if (self.subtypes[j] == item.subtype) then
                            return true;
                        end
                    end
                else
                    return true;
                end
            end
        end
    end

    return false;
end
