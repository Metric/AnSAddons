local Ans = select(2, ...);
local ListView = Ans.UI.ListView;
local TextInput = Ans.UI.TextInput;
local CustomSources = {};
CustomSources.__index = CustomSources;
Ans.CustomSourcesView = CustomSources;

local listItems = {};

function CustomSources:OnLoad(f)
    self.parent = f;
    self.frame = CreateFrame("Frame", "AnsSourcesView", f, "AnsCustomSourcesTemplate");

    self.listView = ListView:New(self.frame, 
        { rowHeight = 29, childIndent = 0, template = "AnsCustomSourceRowTemplate", multiselect = false, useNormalTexture = false},
        nil, nil, nil,
        CustomSources.RenderRow
    );

    self.add = self.frame.NewSource;
    self.add:SetScript("OnClick", function() CustomSources:Add(); end);
    self.frame:Hide();
end

function CustomSources:Hide()
    if (self.frame) then
        self.frame:Hide();
    end
end

function CustomSources:Show()
    if (self.frame) then
        self.frame:Show();
        self:Refresh();
    end
end

function CustomSources:Add()
    local id = #ANS_CUSTOM_VARS + 1;
    local f = {name = "Source"..id, value = ""};
    ANS_CUSTOM_VARS[id] = f;
    self:Refresh();
end

function CustomSources:Refresh()
    wipe(listItems);
    for i,v in ipairs(ANS_CUSTOM_VARS) do
        local pf = {};
        pf.source = v;
        tinsert(listItems, pf);
    end

    self.listView.items = listItems;
    self.listView:Refresh();
end

function CustomSources:Remove(id)
    tremove(ANS_CUSTOM_VARS, id);
    self:Refresh();
end

function CustomSources.RenderRow(row, item)
    local source = item.source;
    if (not row.NameInput) then
        row.NameInput = TextInput:NewFrom(row.Name);
    end
    if (not row.ValueInput) then
        row.ValueInput = TextInput:NewFrom(row.Value);
    end
    row.Name:SetText(source.name);
    row.Value:SetText(source.value);
    row.Name:SetScript("OnTextChanged", 
        function(f) 
            source.name = f:GetText(); 
        end);
    row.Value:SetScript("OnTextChanged", 
        function(f) 
            source.value = f:GetText(); 
        end);
    row.Delete:SetScript("OnClick", function() CustomSources:Remove(row:GetID()); end);
end