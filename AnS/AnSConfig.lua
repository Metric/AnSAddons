AnsConfig = {};
AnsConfig.__index = AnsConfig;

local function AnsCustomFilterUpdateRow(dataOffset, line)
    local row = _G["AnsCustomFilterRow"..line];
    local nameBox = _G[row:GetName().."Name"];
    local idsBox = _G[row:GetName().."IDs"];

    if (dataOffset <= #ANS_CUSTOM_FILTERS) then
        local f = ANS_CUSTOM_FILTERS[dataOffset];
        row:SetID(dataOffset);

        nameBox:SetText(f.name);
        idsBox:SetText(f.ids);

        row:Show();
    else
        row:Hide();
    end
end

function AnsCustomFilterRefresh()
    local line;
    local fTotal = #ANS_CUSTOM_FILTERS;

    FauxScrollFrame_Update(AnsCustomFilterScrollFrame, fTotal, 6, 64);

    local dataOffset = 0;
    local offset = FauxScrollFrame_GetOffset(AnsCustomFilterScrollFrame);

    for line = 1, 6 do
        dataOffset = offset + line;
        AnsCustomFilterUpdateRow(dataOffset, line);
    end
end

function AnsConfig:LoadMain(f)
    InterfaceOptions_AddCategory (f);
end

local function AnsConfigFinalize()
    AnsCore:LoadCustomFilters();
end

function AnsConfig:LoadPanel(f, name)
    f.name = name;
    f.parent = "AnS";
    
    f.okay = AnsConfigFinalize;
    f.cancel = AnsConfigFinalize;

    _G[f:GetName().."_ATitle"]:SetText(name);
    _G[f:GetName().."_BTitle"]:SetText("");
    InterfaceOptions_AddCategory (f);
end

function AnsConfig:AddFilterRow()
    local id = #ANS_CUSTOM_FILTERS + 1;
    local f = AnsCustomFilter:New("Custom"..id, "");
    ANS_CUSTOM_FILTERS[id] = f;

    FauxScrollFrame_SetOffset(AnsCustomFilterScrollFrame, math.max(id - 6, 0));
    AnsCustomFilterRefresh();
end

function AnsConfig:SaveFilterRow(row)
    local nameBox = _G[row:GetName().."Name"];
    local idsBox = _G[row:GetName().."IDs"];

    local id = row:GetID();

    local f = ANS_CUSTOM_FILTERS[id];
    if (f ~= nil) then
        f.name = nameBox:GetText();
        f.ids = idsBox:GetText();
    else
        print("Unable to save custom filter row...");
    end
end

function AnsConfig:EditedFilterRow(row)
    AnsConfig:SaveFilterRow(row);
end

function AnsConfig:DeleteFilterRow(row)
    local id = row:GetID();
    table.remove(ANS_CUSTOM_FILTERS, id);
    AnsCustomFilterRefresh();
end

function AnsConfig:ImportGroups(editor)
    local i;
    local text = editor:GetText();

    if (text:len() > 0) then
        local filters = AnsFilter:ParseTSMGroups(text);

        local total = #ANS_CUSTOM_FILTERS;

        for i = 1, #filters do
            local f = filters[i];

            local ids = f:ExportIds();
            if (ids ~= nil and ids:len() > 0) then
                local cf = AnsCustomFilter:New(f.name, ids);
                total = total + 1;
                ANS_CUSTOM_FILTERS[total] = cf;
            end
        end

        editor:SetText("");

        FauxScrollFrame_SetOffset(AnsCustomFilterScrollFrame, math.max(total - 6, 0));
        AnsCustomFilterRefresh();
    end
end
