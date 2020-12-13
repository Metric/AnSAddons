local Ans = select(2, ...);

local ListView = Ans.UI.ListView;
local ConfirmDialog = Ans.UI.ConfirmDialog;
local TextInput = Ans.UI.TextInput;
local Config = Ans.Config;
local Sources = Ans.Sources;

local listItems = {};

AnsCustomSourcesSettingsFrameMixin = {};

function AnsCustomSourcesSettingsFrameMixin:Init()
    local this = self;

    self:SetScript("OnShow", function() this:Refresh(); end);

    self.listView = ListView:Acquire(self,
        { rowHeight = 28, childIndent = 0, template = "AnsCustomSourceRowTemplate", multiselect = false, useNormalTexture = false},
        nil,
        function(item)
            -- move up
            this:MoveUp(item);
        end,
        function (item)
            -- move down
            this:MoveDown(item);
        end,
        function (row, item)
            this:RenderRow(row, item);
        end
    );

    self.NewSource:SetScript("OnClick", function() this:Add(); end);
    self:Hide();
end

function AnsCustomSourcesSettingsFrameMixin:Add()
    local id = #Config.CustomSources() + 1;
    local f = {name = "Source"..id, value = ""};
    Config.CustomSources()[id] = f;
    self:Refresh();
end

function AnsCustomSourcesSettingsFrameMixin:MoveUp(item)
    local items = Config.CustomSources();
    if (#items <= 1) then
        return;
    end

    for i,v in ipairs(items) do
        if (i == 1 and v == item.source) then
            break;
        elseif (v == item.source) then
            tremove(items, i);
            tinsert(items, i-1, v);
            break;
        end
    end

    self:Refresh();
end

function AnsCustomSourcesSettingsFrameMixin:MoveDown(item)
    local items = Config.CustomSources();
    if (#items <= 1) then
        return;
    end

    local count = #items;
    for i,v in ipairs(items) do
        if (i == count and v == item.source) then
            break;
        elseif (v == item.source) then
            tremove(items, i);
            tinsert(items, i+1, v);
            break;
        end
    end

    self:Refresh();
end

function AnsCustomSourcesSettingsFrameMixin:Refresh()
    wipe(listItems);

    for i,v in ipairs(Config.CustomSources()) do
        local pf = {};
        pf.source = v;
        tinsert(listItems, pf);
    end

    self.listView.items = listItems;
    self.listView:Refresh();
end

function AnsCustomSourcesSettingsFrameMixin:Remove(id)
    tremove(Config.CustomSources(), id);
    self:Refresh();
end

function AnsCustomSourcesSettingsFrameMixin:RenderRow(row, item)
    local this = self;
    local source = item.source;
    if (not row.NameInput) then
        row.NameInput = TextInput:NewFrom(row.Name);
    end
    if (not row.ValueInput) then
        row.ValueInput = TextInput:NewFrom(row.Value);
        row.ValueInput.sourceValidation = Sources;
    end
    if (row.Name) then
        row.Name:SetText(source.name);
        row.Name:SetScript("OnTextChanged", 
            function(f) 
                source.name = f:GetText(); 
            end);
    end
    if (row.Value) then
        row.Value:SetText(source.value);
        row.Value:SetScript("OnTextChanged", 
            function(f) 
                source.value = f:GetText(); 
            end);
    end
    if (row.Delete) then
        row.Delete:SetScript("OnClick", function() 
            ConfirmDialog:Show(this.ConfirmDelete, "Delete source ["..source.name.."]?", "DELETE",
                function(data)
                    this:Remove(data);
                end,
            row:GetID());
        end);
    end
end



