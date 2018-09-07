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
    f.pets = {};
    f.types = {};
    f.minSize = 0;
    f.isSub = false;
    f.subfilters = nil;
    f.priceFn = "";
    f.maxPercent = 100;
    f.useGlobalMaxBuyout = true;
    f.useGlobalMinStack = true;
    f.useGlobalMinQuality = true;
    f.useGlobalMinILevel = true;

    return f;
end

function AnsFilter:Clone()
    local f = AnsFilter:New(self.name);
    f.minILevel = self.minILevel;
    f.minQuality = self.minQuality;
    f.minPetLevel = self.minPetLevel;
    f.maxBuyout = self.maxBuyout;
    f.ids = self.ids;
    f.pets = self.pets;
    f.types = self.types;
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
        str = str..sep.."i:"..self.ids[i];
        sep = ",";
    end

    for i = 1, #self.pets do
        str = str..sep.."p:"..self.pets[i];
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

    self.ids = {};
    self.pets = {};

    local pcount = 0;
    local icount = 0;

    for i = 1, #items do
        local _ , id = strsplit(":", items[i]);
        if (id ~= nil) then
            if (_ == "i") then
                icount = icount + 1;
                self.ids[icount] = tonumber(id); 
            elseif (_ == "p") then
                pcount = pcount + 1;
                self.pets[pcount] = tonumber(id);
            end
        else
            local tn = tonumber(_);
            if (tn ~= nil) then
                icount = icount + 1;
                self.ids[icount] = tn;
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

        if (type(presult) == "boolean" and not presult) then
            return false;
        end
    end

    if (item.iLevel < self.minILevel) then
        return false;
    end
    if (item.quality < self.minQuality) then
        return false;
    end
    if (item.ppu >= self.maxBuyout and self.maxBuyout > 0) then
        return false;
    end
    if (item.count < self.minSize) then
        return false;
    end
    if (item.percent > self.maxPercent) then
        return false;
    end

    local tids = #self.ids;
    if (tids > 0) then
        local i;
        for i = 1, tids do
            if (self.ids[i] == item.id) then
                return true;
            end
        end
    end

    local ttypes = #self.types;
    if (ttypes > 0) then
        local i;
        for i = 1, ttypes do
            if (self.types[i] == item.type:lower()) then
                return true;
            end
        end
    end

    local tpets = #self.pets;
    if (tpets > 0) then
        if (AnsUtils:IsBattlePetLink(item.link)) then
            local pet = AnsUtils:ParseBattlePetLink(item.link);
            local i;
            for i = 1, tpets do
                if (self.pets[i] == pet.speciesID) then
                    return true;
                end
            end
        end
    end

    return false;
end
