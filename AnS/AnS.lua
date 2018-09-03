ANS_CUSTOM_FILTERS = {};

AnsCore = {};
AnsCore.__index = AnsCore;

AnsCustomFilter = {};
AnsCustomFilter.__index = AnsCustomFilter;

local DefaultFilters = {};

function AnsCustomFilter:New(name,ids)
    local f = {};
    setmetatable(f, AnsCustomFilter);
    f.name = name;
    f.ids = ids;
    return f;
end

function AnsCore:RegisterEvents(frame)
    frame:RegisterEvent("VARIABLES_LOADED");
end

function AnsCore:EventHandler(frame, event, ...)
    if (event == "VARIABLES_LOADED") then AnsCore:OnLoad(); end;
end

function AnsCore:OnLoad()
    self:StoreDefaultFilters();
    self:LoadCustomFilters();
end

function AnsCore:StoreDefaultFilters()
    local i;
    local total = #AnsFilterList;

    for i = 1, total do
        DefaultFilters[i] = AnsFilterList[i];
    end
end

function AnsCore:LoadCustomFilters()
    local i;
    local total = #DefaultFilters;

    local temp = {};
    local temp2 = {};

    for i = 1, total do
        temp[i] = DefaultFilters[i];
        temp2[i] = AnsFilterSelected[i];
    end

    local fparent = AnsFilter:New("Custom");
    fparent.subfilters = {};

    total = total + 1;
    temp[total] = fparent;
    temp2[total] = false;

    local vtotal = 1;

    for i = 1, #ANS_CUSTOM_FILTERS do
        local cf = ANS_CUSTOM_FILTERS[i];
        if (cf.ids ~= nil and cf.ids:len() > 0) then
            local f = AnsFilter:New(cf.name);
            f.isSub = true;
            f:ParseTSM(cf.ids);
            fparent.subfilters[vtotal] = f;
            vtotal = vtotal + 1;
            total = total + 1;
            temp[total] = f;
            temp2[total] = false;
        end
    end

    AnsFilterList = temp;
    AnsFilterSelected = temp2;
end