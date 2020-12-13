local Ans = select(2, ...);
local EventManager = Ans.EventManager;
local Config = Ans.Config;
local TreeView = Ans.UI.TreeView;
local Utils = Ans.Utils;
local Groups = Utils.Groups;
local ConfirmDialog = Ans.UI.ConfirmDialog;
local Importer = Ans.Importer;
local Exporter = Ans.Exporter;

local rootGroup = {
    name = "Base",
    expanded = true,
    selected = false,
    children = {},
    showAddButton = true
};

local treeItems = { rootGroup };
local selectedGroup = nil;

AnsGroupFrameMixin = {};

function AnsGroupFrameMixin:Restore()
    Groups.RestoreDefaultGroups();
    self:Refresh();
end

function AnsGroupFrameMixin:MoveGroupToTarget(selected, item)
    if (selected and selected.filter) then
        -- can't move it into ourself
        if (item.filter == selected.filter) then
            return;
        end

        local f = selected.filter;
        local parent = selected.parent;

        if (parent) then
            for i,v in ipairs(parent.children) do
                if (v == f) then
                    tremove(parent.children, i);
                    break;
                end
            end
        else
            for i,v in ipairs(Config.Groups()) do
                if (v == f) then
                    tremove(Config.Groups(), i);
                    break;
                end
            end
        end

        if (item.filter) then
            tinsert(item.filter.children, f);
            selected.parent = item.filter;
        else
            tinsert(Config.Groups(), f);
            selected.parent = nil;
        end

        self:Refresh();
    end
end

function AnsGroupFrameMixin:DeleteGroup(group)
    if (group and group.filter) then
        local f = group.filter;
        local parent = group.parent;
        if (parent) then
            for i,v in ipairs(parent.children) do
                if (v == f) then
                    tremove(parent.children, i);
                    break;
                end
            end
        else
            for i,v in ipairs(Config.Groups()) do
                if (v == f) then
                    tremove(Config.Groups(), i);
                    break;
                end
            end
        end

        self.Edit:Set(nil);
        self:Refresh();
    end
end

function AnsGroupFrameMixin:BuildTree(rootChildren, selectedComparer, showAdd)
    local filters = Config.Groups();
    local root = rootChildren;

    if (self.Edit) then
        rootGroup.selected = rootGroup == self.Edit.selected;
    end
    
    if (#filters < #root) then
        for i = #filters + 1, #root do
            tremove(root);
        end
    end

    self:UpdateTree(filters, root, nil, selectedComparer, showAdd);
end

function AnsGroupFrameMixin:UpdateTree(children, parent, filter, selectedComparer, showAdd)
    for i,v in ipairs(children) do
        local child = parent[i];
        local selected = selectedComparer(v);

        if (child) then
            child.selected = selected;
            child.parent = filter;

            if (child.filter.id ~= v.id) then
                child.expanded = false;
                child.name = v.name;
                child.filter = v;
                child.children = {};

                if (#v.children > 0) then
                    self:UpdateTree(v.children, child.children, v, selectedComparer, showAdd);
                end
            else
                -- forgot to update the name
                -- if it still the same id doh!
                -- thus it appeared the group name
                -- was not saving properly when editing!
                child.name = v.name;
                if (#v.children > 0) then
                    if (#v.children < #child.children) then
                        for i = #v.children + 1, #child.children do
                            tremove(child.children);
                        end
                    end

                    self:UpdateTree(v.children, child.children, v, selectedComparer, showAdd);
                else
                    wipe(child.children);
                end
            end
        else
            local t = {
                name = v.name,
                selected = selected,
                expanded = false,
                parent = filter,
                filter = v,
                children = {},
                showAddButton = showAdd
            };

            if (#v.children > 0) then
                self:UpdateTree(v.children, t.children, v, selectedComparer, showAdd);
            end

            tinsert(parent, t);
        end
    end
end

function AnsGroupFrameMixin:Refresh()
    Groups.BuildGroupPaths(Config.Groups());

    if (#treeItems == 0) then
        tinsert(treeItems, rootGroup);
    end

    self:BuildTree(rootGroup.children, 
        function(v) 
            if (not self.Edit.selected) then
                return false;
            end

            return v == self.Edit.selected.filter
        end,
        true
    );
    self.groupsTree.items = treeItems;
    self.groupsTree:Refresh();
end

function AnsGroupFrameMixin:ImportData()
    local this = self;
    if (not selectedGroup or selectedGroup == rootGroup) then
        ConfirmDialog:ShowInput(self.ConfirmInput, "Import Group Data", "IMPORT",
            function(data)
                if (data and data ~= "" and data:len() > 2) then
                    Importer:ImportGroups(data, Config.Groups());
                    this:Refresh();
                end
            end
        );
        return;
    end

    if (not selectedGroup.filter) then
        return;
    end

    ConfirmDialog:ShowInput(self.ConfirmInput, "Import Group Data", "IMPORT",
        function(data)
            if (data and data ~= "" and data:len() > 2) then
                Importer:Import(data, selectedGroup.filter);
                this.Edit:Set(selectedGroup);
                this:Refresh();
            end
        end
    );
end

function AnsGroupFrameMixin:ExportData()
    local this = self;
    if (not selectedGroup or selectedGroup == rootGroup) then
        ConfirmDialog:ShowInput(self.ConfirmInput, "Exported Data", "OKAY",
            nil, Exporter:ExportGroups(Config.Groups())
        );
        return;
    end

    if (not selectedGroup.filter) then
        return;
    end

    ConfirmDialog:ShowInput(self.ConfirmInput, "Exported Data", "OKAY",
        nil, Exporter:GetGroup(selectedGroup.filter)
    );
end

function AnsGroupFrameMixin:NewGroup(item)
    local i = 1;
    local t = {
        id = Utils.Guid(),
        name = "New Group ",
        ids = "",
        children = {},
    };

    if (item == rootGroup) then
        i = #Config.Groups() + 1;
        t.name = t.name..i;
        tinsert(Config.Groups(), t);
    elseif (item.filter) then
        i = #item.filter.children + 1;
        t.name = t.name..i;
        tinsert(item.filter.children, t);
    end

    self:Refresh();
end

function AnsGroupFrameMixin:MoveGroupUp(s)
    local p = s.parent;
    if (not p) then
        p = Config.Groups();
    else
        p = s.parent.children;
    end

    local idx = 0;
    for i,v in ipairs(p) do
        if (v == s.filter) then
            idx = i;
            break;
        end
    end

    if (idx - 1 > 0) then
        tremove(p, idx);
        tinsert(p, idx - 1, s.filter);

        self:Refresh();
    end
end

function AnsGroupFrameMixin:MoveGroupDown(s)
    local p = s.parent;
    
    if (not p) then
        p = Config.Groups();
    else
        p = s.parent.children;
    end

    local idx = 0;

    for i,v in ipairs(p) do
        if (v == s.filter) then
            idx = i;
            break;
        end
    end

    if (idx > 0 and idx + 1 <= #p) then
        tremove(p, idx);
        tinsert(p, idx + 1, s.filter);

        self:Refresh();
    end
end

function AnsGroupFrameMixin:Init()
    local this = self;

    self:SetScript("OnShow", function() this:Refresh(); end);

    self.Edit.onDelete = function(data)
        this:DeleteGroup(data);
    end;

    self.Edit.onSave = function()
        this:Refresh();
    end;

    self.RestoreDefault:SetScript("OnClick", function() this:Restore(); end);
    self.groupsTree = TreeView:Acquire(self.Groups,
    {
        rowHeight = 20,
        childIndent = 16,
        template = "AnsTreeRowTemplate",
        multiselect = false,
        useNormalTexture = false,
        dragAndDrop = function(item, target) this:MoveGroupToTarget(item, target); end,
        dragTemplate = "AnsTreeRowDragTemplate"
    },
        function(s)
            --select
            selectedGroup = s;
            this.Edit:Set(s);
            this:Refresh();
        end,
        function(s)
            --up
            this:MoveGroupUp(s);
        end,
        function(s)
            --down
            this:MoveGroupDown(s);
        end,
        function(s)
            --new
            this:NewGroup(s);
        end
    );

    self.groupsTree.items = treeItems;
    
    self.Import:SetScript("OnClick", function() this:ImportData(); end);
    self.Import:SetScript("OnEnter", function(f) Utils.ShowTooltipText(f, "Import raw data into selected group"); end);
    self.Import:SetScript("OnLeave", Utils.HideTooltip);
    self.Export:SetScript("OnClick", function() this:ExportData(); end);
    self.Export:SetScript("OnEnter", function(f) Utils.ShowTooltipText(f, "Export raw data from selected group"); end);
    self.Export:SetScript("OnLeave", Utils.HideTooltip);

    self.Edit:Hide();
end