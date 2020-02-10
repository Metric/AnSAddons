local Ans = select(2, ...);
local TextInput = Ans.UI.TextInput;
local ConfirmDialog = Ans.UI.ConfirmDialog;
local TreeView = Ans.UI.TreeView;
local ListView = Ans.UI.ListView;
local Utils = Ans.Utils;

local Query = Ans.Analytics.Query;

local rootGroup = {
    name = "Base",
    expanded = true,
    selected = false,
    children = {},
    showAddButton = true
};

local groupTreeItems = { rootGroup };
local selectedInventoryItems = {};
local inventoryItems = {};
local inventoryItemList = {};

local Groups = {};
local GroupEdit = {};
GroupEdit.__index = GroupEdit;
GroupEdit.selected = nil;
GroupEdit.onDelete = nil;
GroupEdit.onMove = nil;
GroupEdit.onSave = nil;

Groups.__index = Groups;
Groups.index = 3;
Groups.selected = false;
Groups.loaded = false;

Ans.GroupsView = Groups;

function GroupEdit:OnLoad(f)
    local this = self;
    self.frame = f.Edit;

    self.nameEdit = TextInput:New(self.frame, "NameInput");
    self.nameEdit:SetPoint("TOPLEFT", "TOPLEFT", 0, 0);
    self.nameEdit:SetLabel("Group Name");
    self.nameEdit.onTextChanged = function() this:Save(); end;
    self.nameEdit:SetSize(125, 24);
    
    self.idEdit = TextInput:NewFrom(self.frame.Ids.Text);
    self.idEdit:SetPoint("TOPLEFT", "TOPLEFT", 0, 0);
    self.idEdit:EnableMultiLine();
    self.idEdit:SetLabel("Item ids e.g. i:1204,p:20");
    self.idEdit.onTextChanged = function() this:Save(); end;

    self.addItem = self.frame.AddItem;

    self.addItem:SetScript("OnClick", function() this:AddItems(); end);

    self.moveGroup = self.frame.MoveGroup;
    self.removeGroup = self.frame.RemoveGroup;
    self.confirmDelete = self.frame.ConfirmDelete;

    if(self.removeGroup) then
        self.removeGroup:SetScript("OnClick", 
            function()
                if (not this.selected) then
                    return;
                end
                ConfirmDialog:Show(this.confirmDelete, "Deleting this group will delete all sub groups.", "DELETE",
                    function(data)
                        if (this.onDelete) then
                            this.onDelete(data);
                        end
                    end,
                    this.selected
                );
            end 
        );
    end

    if (self.moveGroup) then
        self.moveGroup:SetScript("OnClick", 
            function()
                if (not this.selected) then
                    return;
                end
                if (this.onMove) then
                    this.onMove(this.moveGroup);
                end
            end
        );
    end

    self.inventoryList = ListView:New(self.frame.InventoryList,
        { rowHeight = 16, childIndent = 0, template = "AnsInventoryRowTemplate", multiselect = true},
        GroupEdit.SelectInventory,
        nil,nil,
        GroupEdit.RenderInventoryRow
    );

    self.frame:Hide();
end

function GroupEdit.ShowTooltip(row, record)
    if (record and record.link and string.find(record.link, "%|H")) then
        Utils:ShowTooltip(row, record.link, record.count);
    end
end

function GroupEdit.RenderInventoryRow(row, item)
    local nameText = _G[row:GetName().."Name"];
    nameText:SetText(item.link);
    row:SetScript("OnEnter", function() GroupEdit.ShowTooltip(row, item); end);
    row:SetScript("OnLeave", Utils.HideTooltip);
end

function GroupEdit.SelectInventory(item)
    if (selectedInventoryItems[item.link]) then
        selectedInventoryItems[item.link] = nil;
    else
        selectedInventoryItems[item.link] = Utils:GetTSMID(item.link);
    end
end

function GroupEdit:BuildInventoryList()
    Query:GetAllInventory(inventoryItems, true);
    wipe(inventoryItemList);
    wipe(selectedInventoryItems);

    local txt = self.idEdit:Get();
    local txtCount = #txt;
    
    for i,v in pairs(inventoryItems) do
        if (txtCount == 0) then
            tinsert(inventoryItemList, v);
        else
            local id = Utils:GetTSMID(v.link);
            if (not strfind(txt, id)) then
                tinsert(inventoryItemList, v);
            end
        end
    end

    self.inventoryList.items = inventoryItemList;
    self.inventoryList:Refresh();
end

function GroupEdit:AddItems()
    if (self.selected and self.selected.filter) then
        local txt = self.idEdit:Get();
        local comma = strsub(txt, #txt, #txt);
        local sep = ",";
        if (comma == sep or #txt == 0) then
            sep = "";
        end

        for i,v in pairs(selectedInventoryItems) do
            if (v) then
                txt = txt..sep..v;
            end
            sep = ",";
        end

        self.idEdit:Set(txt);
    end
end

function GroupEdit:Set(item)
    self.selected = item;
    if (item) then
        local f = item.filter;
        if (f) then
            self.nameEdit:Set(f.name);
            self.idEdit:Set(f.ids);
            self.frame:Show();
            self:BuildInventoryList();
        else
            self.frame:Hide();
        end
    else
        self.frame:Hide();
    end
end

function GroupEdit:Save()
    if (not self.selected or not self.selected.filter) then
        return;
    end

    local g = self.selected.filter;
    g.name = self.nameEdit:Get();
    g.ids = self.idEdit:Get();

    self:BuildInventoryList();

    if (self.onSave) then
        self.onSave();
    end
end

function Groups:OnLoad(f)
    self.loaded = true;
    local this = self;
    local tab = _G[f:GetName().."TabView"..self.index];
    self.tab = tab;

    GroupEdit:OnLoad(self.tab);

    GroupEdit.onDelete = self.DeleteGroup;
    GroupEdit.onMove = self.ToggleGroupMoveView;
    GroupEdit.onSave = self.OnEdit;


    self.groups = tab.Groups;
    self.moveGroup = tab.MoveGroup;

    self.groupsTree = TreeView:New(self.groups,
        nil,
        this.Select,
        this.MoveGroupUp,
        this.MoveGroupDown,
        this.NewGroup
    );
    self.moveGroupTree = TreeView:New(self.moveGroup,
        nil,
        function(item) this:MoveGroupTo(item); end,
        nil, nil,
        this.RenderMoveRow
    );
end

function Groups:Show()
    if (self.tab) then
        self.tab:Show();
        self.selected = true;
        self:Refresh();
    end
end

function Groups:Hide()
    if (self.tab) then
        self.selected = false;
        self.tab:Hide();
    end
end

function Groups.OnEdit()
    Groups:Refresh();
end

function Groups:MoveGroupTo(item)
    local selected = GroupEdit.selected;
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
            for i,v in ipairs(ANS_GROUPS) do
                if (v == f) then
                    tremove(ANS_GROUPS, i);
                    break;
                end
            end
        end

        if (item.filter) then
            tinsert(item.filter.children, f);
            selected.parent = item.filter;
        else
            tinsert(ANS_GROUPS, f);
            selected.parent = nil;
        end

        self.moveGroup:Hide();

        self:Refresh();
    end
end

function Groups.DeleteGroup(group)
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
            for i,v in ipairs(ANS_GROUPS) do
                if (v == f) then
                    tremove(ANS_GROUPS, i);
                    break;
                end
            end
        end

        GroupEdit:Set(nil);
        Groups:Refresh();
    end
end

function Groups.ToggleGroupMoveView(parent)
    local view = Groups.moveGroup;
    if (view:IsShown()) then
        view:Hide();
    else
        view:Show();
        view:ClearAllPoints();
        view:SetPoint("BOTTOMLEFT", parent, "TOPLEFT", 0, 0);
    end
end

function Groups:Refresh()
    if (#groupTreeItems == 0) then
        tinsert(groupTreeItems, rootGroup);
    end

    self:BuildTree(rootGroup.children, 
        function(v) 
            if (not GroupEdit.selected) then
                return false;
            end

            return v == GroupEdit.selected.filter
        end,
        true
    );
    self.groupsTree.items = groupTreeItems;
    self.groupsTree:Refresh();
    self.moveGroupTree.items = groupTreeItems;
    self.moveGroupTree:Refresh();
end

function Groups.MoveGroupUp(s)
    local p = s.parent;
    if (not p) then
        p = ANS_GROUPS;
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

        Groups:Refresh();
    end
end

function Groups.MoveGroupDown(s)
    local p = s.parent;
    
    if (not p) then
        p = ANS_GROUPS;
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

        Groups:Refresh();
    end
end

function Groups.Select(s)
    GroupEdit:Set(s);
    Groups:Refresh();
end

function Groups.RenderMoveRow(row, item)
    local moveUp = _G[row:GetName().."MoveUp"];
    local moveDown = _G[row:GetName().."MoveDown"];

    if (moveUp) then
        moveUp:Hide();
    end
    if (moveDown) then
        moveDown:Hide();
    end
end

function Groups:BuildTree(rootChildren, selectedComparer, showAdd)
    local filters = ANS_GROUPS;
    local root = rootChildren;

    rootGroup.selected = rootGroup == GroupEdit.selected;
    if (#filters < #root) then
        for i = #filters + 1, #root do
            tremove(root);
        end
    end

    self:UpdateTree(filters, root, nil, selectedComparer, showAdd);
end

function Groups:UpdateTree(children, parent, filter, selectedComparer, showAdd)
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

function Groups.NewGroup(item)
    local i = 1;
    local t = {
        id = Utils:Guid(),
        name = "New Group ",
        ids = "",
        children = {},
    };

    if (item == rootGroup) then
        i = #ANS_GROUPS + 1;
        t.name = t.name..i;
        tinsert(ANS_GROUPS, t);
    elseif (item.filter) then
        i = #item.filter.children + 1;
        t.name = t.name..i;
        tinsert(item.filter.children, t);
    end

    Groups:Refresh();
end