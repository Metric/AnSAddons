local Ans = select(2, ...);
local GroupsView = Ans.GroupsView;
local ConfirmDialog = Ans.UI.ConfirmDialog;
local TextInput = Ans.UI.TextInput;
local ConfirmDialog = Ans.UI.ConfirmDialog;
local Dropdown = Ans.UI.Dropdown;
local TreeView = Ans.UI.TreeView;
local ListView = Ans.UI.ListView;
local Utils = Ans.Utils;

local operationTreeItems = {};
local groupTreeItems = {};

local Operations = {};
Operations.__index = Operations;
Ans.OperationsView = Operations;
Operations.loaded = false;
Operations.selected = false;
Operations.index = 4;
Operations.selectedOp = nil;

local SnipingOp = Ans.Operations.Sniping;
local SnipingOpView = Ans.SnipingOpView;

local selectedGroups = {};

local PI = 3.14159265358;
local Deg2Rad = PI / 180;

function Operations.RenderGroupRow(row, item)
    local moveUp = _G[row:GetName().."MoveUp"];
    local moveDown = _G[row:GetName().."MoveDown"];

    local addButton = _G[row:GetName().."Add"];
    if (addButton) then
        addButton:Hide();
    end

    if (moveUp) then
        moveUp:Hide();
    end

    if (moveDown) then
        moveDown:Hide();
    end
end

function Operations:OnLoad(f)
    local this = self;
    self.loaded = true;
    self.tab = _G[f:GetName().."TabView"..self.index];
    

    self.confirmDelete = self.tab.ConfirmDelete;

    SnipingOpView:OnLoad(self.tab);
    self.opTree = TreeView:New(self.tab.Ops,
        {rowHeight = 20, childIndent = 20, template = "AnsTreeRowAddTemplate", multiselect = false, useNormalTexture = false},
        Operations.Select,
        nil, nil,
        Operations.Add,
        Operations.RenderRow
    );
    SnipingOpView:Hide();
    SnipingOpView.onEdit = function() this:Refresh(); end;

    self.groupTree = TreeView:New(self.tab.Groups,
        {rowHeight = 20, childIndent = 20, template ="AnsTreeRowTemplate", multiselect = true, useNormalTexture = false},
        Operations.SelectGroup,
        nil, nil, nil,
        Operations.RenderGroupRow
    );
end

function Operations:Show()
    if (self.tab) then
        self.tab:Show();
        self.selected = true;
        self:Refresh(true);
    end
end

function Operations:Hide()
    if (self.tab) then
        self.selected = false;
        self.tab:Hide();
    end
end

function Operations.SelectGroup(item)
    local g = item.filter;
    if (Utils:InTable(selectedGroups, g.id)) then
        for i,v in ipairs(selectedGroups) do
            if(v == g.id) then
                tremove(selectedGroups, i);
                return;
            end
        end
    else
        tinsert(selectedGroups, g.id);
    end
end

function Operations.RenderRow(row, item)
    -- item.name == "Sniping" is temporary until all ops
    -- are implemented
    if (item.showAddButton and item.name == "Sniping") then
        local addButton = _G[row:GetName().."Add"];
        if (addButton) then
            addButton:GetNormalTexture():SetRotation(45 * Deg2Rad);
            addButton:GetHighlightTexture():SetRotation(45 * Deg2Rad);
            addButton:Show();
        end
    else
        local addButton = _G[row:GetName().."Add"];
        if (addButton) then
            addButton:Hide();
        end
    end

    if (item.showDelete) then
        local deleteButton = _G[row:GetName().."Delete"];
        if (deleteButton) then
            deleteButton:SetScript("OnClick", 
            function()
                ConfirmDialog:Show(Operations.confirmDelete, "Delete Operation: "..item.parent.."."..item.name.."?", "DELETE",
                    function(data)
                        Operations:Delete(data);
                    end,
                item)
            end);
            deleteButton:Show();
        end
    else
        local deleteButton = _G[row:GetName().."Delete"];
        if (deleteButton) then
            deleteButton:Hide();
        end
    end

    local moveUp = _G[row:GetName().."moveUp"];
    local moveDown = _G[row:GetName().."moveDown"];

    if (moveUp) then
        moveUp:Hide();
    end

    if (moveDown) then
        moveDown:Hide();
    end

    row:SetText(item.name);
end

function Operations.Add(item)
    if (item.name == "Sniping") then
        local opConfig = SnipingOp:NewConfig("Snipe "..(#item.children + 1));
        local tbl = ANS_OPERATIONS[item.name];

        if (tbl) then
            tinsert(tbl, opConfig);
        end

        Operations:Refresh();
    end
end

function Operations:Delete(data)
    if (not data or not data.parent) then
        return;
    end

    local tbl = ANS_OPERATIONS[data.parent];

    if (not tbl) then
        return;
    end

    for i,v in ipairs(tbl) do
        if (v.id == data.op.id) then
            if (data.op == SnipingOpView.selected) then
                SnipingOpView:Hide();
                Operations.groupTree:Hide();
            end
            tremove(tbl, i);
            self:Refresh();
            return;
        end
    end
end

function Operations.Select(item)
    --- hide all views
    SnipingOpView:Hide();
    selectedGroups = {};
    Operations.groupTree:Hide();

    Operations.selectedOp = nil;

    if (item and item.parent and item.op) then
        Operations.selectedOp = item.op;
        if (item.parent == "Sniping") then
            SnipingOpView:Set(item.op);
            selectedGroups = item.op.groups;
            Operations.groupTree:Show();
            Operations:RefreshGroups();
        end
    end

    Operations:Refresh();
end

function Operations:Refresh(sort)
    self:BuildTree();
    self.opTree.items = operationTreeItems;
    self.opTree:Refresh(sort);
end

function Operations:RefreshGroups()
    GroupsView:BuildTree(groupTreeItems, 
        function(v) 
            return Utils:InTable(selectedGroups, v.id); 
        end
    );
    self.groupTree.items = groupTreeItems;
    self.groupTree:Refresh();
end

function Operations:BuildTree(sort)
    local index = 1;
    for k,v in pairs(ANS_OPERATIONS) do
        local t = operationTreeItems[index];

        if (not t) then
            t = {
                name = k,
                expanded = true,
                showAddButton = true,
                showDelete = false,
                selected = false,
                children = {}
            };

            tinsert(operationTreeItems, t);
        else
            t.selected = false;
        end

        if (sort) then
            table.sort(v, function(a,b) return a.name < b.name; end);
        end

        if (#v < #t.children) then
            for i = #v + 1, #t.children do
                tremove(t.children);
            end
        end

        for i,o in ipairs(v) do
            local t2 = t.children[i];

            if (not t2) then
                t2 = {
                    name = o.name,
                    op = o,
                    expanded = false,
                    showAddButton = false,
                    showDelete = true,
                    selected = false,
                    parent = k,
                    children = {}
                }

                tinsert(t.children, t2);
            else
                if(t2.op.id ~= o.id) then
                    if (t2.selected) then
                        t2.selected = false;
                        Operations.Select(nil);
                    end
                end

                
                t2.name = o.name;
                t2.op = o;
                t2.parent = k;
                t2.selected = self.selectedOp and o.id == self.selectedOp.id;
            end
        end

        index = index + 1;
    end
end