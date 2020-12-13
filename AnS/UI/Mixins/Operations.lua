local Ans = select(2, ...);

local ConfirmDialog = Ans.UI.ConfirmDialog;
local TreeView = Ans.UI.TreeView;
local Utils = Ans.Utils;
local Groups = Utils.Groups;
local Config = Ans.Config;
local Importer = Ans.Importer;

local operationTreeItems = {};
local groupTreeItems = {};

local SnipingOp = Ans.Operations.Sniping;
local AuctioningOp = Ans.Operations.Auctioning;
local MailOp = Ans.Operations.Mailing;
local Json = Utils.Json;

local selectedGroups = {};

local tempTbl = {};
local tempTbl2 = {};

local PI = 3.14159265358;
local Deg2Rad = PI / 180;

local function RenderGroupRow(row, item)
    local moveUp = row.MoveUp;
    local moveDown = row.MoveDown;
    local addButton = row.Add;

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

AnsOperationsFrameMixin = {};

function AnsOperationsFrameMixin:Init()
    local this = self;

    self:SetScript("OnShow", function() this:Refresh(); end);

    self.editHandler = function() this:Refresh(); end;
    
    self.SnipeEdit.onEdit = self.editHandler;
    self.AuctionEdit.onEdit = self.editHandler;
    self.MailEdit.onEdit = self.editHandler;

    self.opTree = TreeView:Acquire(self.Ops,
        {rowHeight = 20, childIndent = 20, template = "AnsTreeRowAddTemplate", multiselect = false, useNormalTexture = false},
        function(item)
            --select
            this:Select(item);
        end,
        nil, nil,
        function(item)
            -- add
            this:Add(item);
        end,
        function(row, item)
            this:RenderRow(row, item);
        end
    );

    self.groupTree = TreeView:Acquire(self.Groups,
        {rowHeight = 20, childIndent = 20, template = "AnsTreeRowTemplate", multiselect = true, useNormalTexture = false},
        function(item)
            this:SelectGroup(item);
        end,
        nil, nil, nil,
        RenderGroupRow
    );

    self.Import:SetScript("OnClick", function() this:ImportData(); end);
    self.Import:SetScript("OnEnter", function(f) Utils.ShowTooltipText(f, "Import raw operation data"); end);
    self.Import:SetScript("OnLeave", Utils.HideTooltip);
    self.Export:SetScript("OnClick", function() this:ExportData(); end);
    self.Export:SetScript("OnEnter", function(f) Utils.ShowTooltipText(f, "Export raw data from selected operation / operation group"); end);
    self.Export:SetScript("OnLeave", Utils.HideTooltip);

end

function AnsOperationsFrameMixin:ImportData()
    local this = self;
    ConfirmDialog:ShowInput(self.ConfirmInput, "Import Operation Data", "IMPORT",
        function(data)
            local tbl = Json.decode(data);

            if (not tbl) then
                print("AnS - failed to decode json data for operation import");
                return;
            end

            Groups.Flatten(Config.Groups(), tempTbl2);

            for k,v in pairs(tbl) do
                if (k == "Auctioning") then
                    for i,v in ipairs(v) do
                        if (AuctioningOp.IsValidConfig(v)) then
                            tempTbl = v.groups;
                            v.groups = {};

                            -- assign new guid
                            v.id = Utils.Guid();

                            -- find possible groups
                            for i,v2 in ipairs(tempTbl) do
                                Groups.GetGroupIdFromPath(tempTbl2, v2, v.groups);
                            end
                            if (Config.Operations()[k]) then
                                tinsert(Config.Operations()[k], v);
                            end
                        else
                            print("AnS - invalid auctioning config");
                        end
                    end
                elseif (k == "Mailing") then
                    for i,v in ipairs(v) do
                        if (MailOp.IsValidConfig(v)) then
                            tempTbl = v.groups;
                            v.groups = {};

                            -- assign new guid
                            v.id = Utils.Guid();

                            -- find possible groups
                            for i,v2 in ipairs(tempTbl) do
                                Groups.GetGroupIdFromPath(tempTbl2, v2, v.groups);
                            end
                            if (Config.Operations()[k]) then
                                tinsert(Config.Operations()[k], v);
                            end
                        else
                            print("AnS - invalid mail config");
                        end
                    end
                elseif (k == "Sniping") then
                    for i,v in ipairs(v) do
                        if (SnipingOp.IsValidConfig(v)) then
                            tempTbl = v.groups;
                            v.groups = {};

                            -- assign new guid
                            v.id = Utils.Guid();

                            -- find possible groups
                            for i,v2 in ipairs(tempTbl) do
                                Groups.GetGroupIdFromPath(tempTbl2, v2, v.groups);
                            end
                            if (Config.Operations()[k]) then
                                tinsert(Config.Operations()[k], v);
                            end
                        else
                            print("AnS - invalid sniping config");
                        end
                    end
                end
            end

            -- clear up memory
            wipe(tempTbl);
            wipe(tempTbl2);

            this:Refresh();
        end
    );
end

function AnsOperationsFrameMixin:ExportData()
    if (not self.selectedOp) then
        return;
    end

    local config = Config.Operations();
    
    wipe(tempTbl2);

    local primaryKey = "";

    if (self.selectedOp.parent) then
        primaryKey = self.selectedOp.parent;
        tinsert(tempTbl2, self.selectedOp.op);
    else
        primaryKey = self.selectedOp.name;
        if (config[primaryKey]) then
            for i,v in ipairs(config[primaryKey]) do
                tinsert(tempTbl2, v);
            end
        end
    end

    wipe(tempTbl);

    tempTbl[primaryKey] = tempTbl2;

    for k,g in pairs(tempTbl) do
        for i,v in ipairs(g) do
            if (k == "Auctioning") then
                g[i] = AuctioningOp.PrepareExport(v);
            elseif (k == "Mailing") then
                g[i] = MailOp.PrepareExport(v);
            elseif (k == "Sniping") then
                g[i] = SnipingOp.PrepareExport(v);
            end
        end
    end

    ConfirmDialog:ShowInput(self.ConfirmInput, "Exported Data", "OKAY",
        nil, Json.encode(tempTbl)
    );

    wipe(tempTbl);
    wipe(tempTbl2);
end

function AnsOperationsFrameMixin:SelectGroup(item)
    local g = item.filter;
    if (Utils.InTable(selectedGroups, g.id)) then
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

function AnsOperationsFrameMixin:RenderRow(row, item)
    local this = self;
    -- item.name == "Sniping" is temporary until all ops
    -- are implemented
    if (item.showAddButton and (item.name == "Sniping" or item.name == "Auctioning" or item.name == "Mailing")) then
        local addButton = row.Add;
        if (addButton) then
            addButton:GetNormalTexture():SetRotation(45 * Deg2Rad);
            addButton:GetHighlightTexture():SetRotation(45 * Deg2Rad);
            addButton:Show();
        end
    else
        local addButton = row.Add;
        if (addButton) then
            addButton:Hide();
        end
    end

    if (item.showDelete) then
        local deleteButton = row.Delete;
        if (deleteButton) then
            deleteButton:SetScript("OnClick", 
            function()
                ConfirmDialog:Show(this.ConfirmDelete, "Delete Operation: "..item.parent.."."..item.name.."?", "DELETE",
                    function(data)
                        this:Delete(data);
                    end,
                item)
            end);
            deleteButton:Show();
        end
    else
        local deleteButton = row.Delete;
        if (deleteButton) then
            deleteButton:Hide();
        end
    end

    local moveUp = row.MoveUp;
    local moveDown = row.MoveDown;

    if (moveUp) then
        moveUp:Hide();
    end

    if (moveDown) then
        moveDown:Hide();
    end

    row:SetText(item.name);
end

function AnsOperationsFrameMixin:Add(item)
    if (item.name == "Sniping") then
        local opConfig = SnipingOp.Config("Snipe "..(#item.children + 1));
        local tbl = Config.Operations()[item.name];

        if (tbl) then
            tinsert(tbl, opConfig);
        end
    elseif (item.name == "Auctioning") then
        local opConfig = AuctioningOp.Config("Auctioning "..(#item.children + 1));
        local tbl = Config.Operations()[item.name];
        if (tbl) then
            tinsert(tbl, opConfig);
        end
    elseif (item.name == "Mailing") then
        local opConfig = MailOp.Config("Mailing "..(#item.children + 1));
        local tbl = Config.Operations()[item.name];
        if (tbl) then
            tinsert(tbl, opConfig);
        end
    end

    self:Refresh();
end

function AnsOperationsFrameMixin:Select(item)
    self.selectedOp = nil;

    --- hide all views
    self.SnipeEdit:Set(nil);
    self.AuctionEdit:Set(nil);
    self.MailEdit:Set(nil);
    
    selectedGroups = {};

    self.groupTree:Hide();

    if (item and item.parent and item.op) then
        -- Operations.selectedOp = item.op;
        if (item.parent == "Sniping") then
            self.SnipeEdit:Set(item.op);
            selectedGroups = item.op.groups;
            self.groupTree:Show();
            self:RefreshGroups();
        elseif (item.parent == "Auctioning") then
            self.AuctionEdit:Set(item.op);
            selectedGroups = item.op.groups;
            self.groupTree:Show();
            self:RefreshGroups();
        elseif (item.parent == "Mailing") then
            self.MailEdit:Set(item.op);
            selectedGroups = item.op.groups;
            self.groupTree:Show();
            self:RefreshGroups();
        end
    end

    self.selectedOp = item;

    self:Refresh();
end

function AnsOperationsFrameMixin:Delete(data)
    if (not data or not data.parent) then
        return;
    end

    local tbl = Config.Operations()[data.parent];

    if (not tbl) then
        return;
    end

    for i,v in ipairs(tbl) do
        if (v.id == data.op.id) then
            if (data.op == self.SnipeEdit.selected) then
                self.SnipeEdit:Set(nil);
                self.groupTree:Hide();
            elseif (data.op == self.AuctionEdit.selected) then
                self.AuctionEdit:Set(nil);
                self.groupTree:Hide();
            elseif (data.op == self.MailEdit.selected) then
                self.MailEdit:Set(nil);
                self.groupTree:Hide();
            end
            tremove(tbl, i);
            self:Refresh();
            return;
        end
    end
end

function AnsOperationsFrameMixin:Refresh()
    self:BuildTree();
    self.opTree.items = operationTreeItems;
    self.opTree:Refresh();
end

function AnsOperationsFrameMixin:RefreshGroups()
    AnsGroupFrameMixin:BuildTree(groupTreeItems,
        function(v)
            return Utils.InTable(selectedGroups, v.id);
        end
    );
    self.groupTree.items = groupTreeItems;
    self.groupTree:Refresh();
end

function AnsOperationsFrameMixin:BuildTree(sort)
    local index = 1;
    for k,v in pairs(Config.Operations()) do
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
            t.selected = self.selectedOp == t;
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
                        self:Select(nil);
                    end
                end

                
                t2.name = o.name;
                t2.op = o;
                t2.parent = k;
                t2.selected = self.selectedOp and self.selectedOp.op and o.id == self.selectedOp.op.id;
            end
        end

        index = index + 1;
    end
end