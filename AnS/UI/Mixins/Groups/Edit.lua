local Ans = select(2, ...);
local EventManager = Ans.EventManager;
local TextInput = Ans.UI.TextInput;
local ConfirmDialog = Ans.UI.ConfirmDialog;
local Config = Ans.Config;
local ListView = Ans.UI.ListView;
local TempTable = Ans.TempTable;
local Utils = Ans.Utils;
local Groups = Utils.Groups;

local Query = Ans.Analytics.Query;

local selectedInventory = {};
local selectedItems = {};

AnsGroupEditFrameMixin = {};
AnsGroupEditFrameMixin.selected = nil;
AnsGroupEditFrameMixin.onDelete = nil;
AnsGroupEditFrameMixin.onMove = nil;
AnsGroupEditFrameMixin.onSave = nil;
AnsGroupEditFrameMixin.modified = false;

local waitingForInfo = {};
local items = {};
local ids = {};
local inventoryItemsAvailable = {};
local inventoryItems = {};

-- TODO: come back and add dialog for adding raw item ids to group

function AnsGroupEditFrameMixin:ShowTip(row, record)
    if (record and record.link and string.find(record.link, "%|H")) then
        Utils.ShowTooltip(row, record.link, record.count or 1);
    end
end

function AnsGroupEditFrameMixin:Save()
    if (not self.selected or not self.selected.filter) then
        return;
    end

    if (self.modified) then
        local sep = "";
        local txt = "";
        for k,v in pairs(ids) do
            txt = txt..sep..k;
            sep = ",";
        end
        self.selected.filter.ids = txt;
    end

    self.selected.filter.name = self.nameEdit:Get() or "";
    self.modified = false;

    if (self.onSave) then
        self.onSave();
    end
end

function AnsGroupEditFrameMixin:Remove(id)
    if (ids[id]) then
        ids[id] = nil;
        self.modified = true;
        for i,v in ipairs(items) do
            if (v.name == id) then
                tremove(items, i);
                break;
            end
        end
    end
end

function AnsGroupEditFrameMixin:Set(sel)
    self.selected = sel;

    if (sel) then
        local f = sel.filter;
        if (f) then
            self.nameEdit:Set(f.name);
            self:BuildIdList();
            self:BuildInventoryList();
            self:Show();
        else
            self:Hide();
        end
    else
        self:Hide();
    end
end

function AnsGroupEditFrameMixin:BuildIdList()
    wipe(items);
    wipe(ids);
    wipe(selectedItems);

    if (not self.selected or not self.selected.filter) then
        return;
    end

    Groups.ParseIds(self.selected.filter.ids, ids, true);
    for k,v in pairs(ids) do
        tinsert(items, {name = k, link = nil});
    end
    table.sort(items, function(x,y) return x.name < y.name; end);
    self.idList:Refresh();
end

function AnsGroupEditFrameMixin:BuildInventoryList()
    wipe(inventoryItemsAvailable);
    Query:GetAllInventory(inventoryItemsAvailable, true);
    
    wipe(inventoryItems);
    wipe(selectedInventory);

    for i,v in pairs(inventoryItemsAvailable) do
        local id = Utils.GetID(v.link);
        if (not ids[id]) then
            tinsert(inventoryItems, v);
        end
    end

    table.sort(inventoryItems, function(x,y) return Utils.GetName(x.link) < Utils.GetName(y.link); end);
    self.inventoryList:Refresh();
end

function AnsGroupEditFrameMixin:AddItems()
    for k,v in pairs(selectedInventory) do
        local id = Utils.GetID(k);
        ids[id] = 1;
        tinsert(items, {name = id, link = k});
        self.modified = true;
    end
    table.sort(items, function(x,y) return x.name < y.name; end);
    self:Save();
    self:BuildInventoryList();
    self.idList:Refresh();
end

function AnsGroupEditFrameMixin:RemoveItems()
    for k,v in pairs(selectedItems) do
        self:Remove(k);
    end
    wipe(selectedItems);
    self:Save();
    self.idList:Refresh();
    self:BuildInventoryList();
end

function AnsGroupEditFrameMixin:Init()
    local this = self;

    self.nameEdit = TextInput:Acquire(self, "NameInput");
    self.nameEdit:SetPoint("TOPLEFT", "TOPLEFT", 0, 0);
    self.nameEdit:SetLabel("Group Name");
    self.nameEdit.onTextChanged = function() this:Save(); end;
    self.nameEdit:SetSize(280, 24);

    self.idList = ListView:Acquire(self.ItemList, 
        { rowHeight = 16, childIndent = 0, template = "AnsInventoryRowTemplate", multiselect = true},
        function(item)
            if (selectedItems[item.name]) then
                selectedItems[item.name] = nil;
            else
                selectedItems[item.name] = item.name;
            end
        end, nil, nil,
        function(row, item)
            if (not item.link) then
                local link = Utils.GetLink(item.name);
                if (not link) then
                    local _,id = strsplit(":", item.name);
                    waitingForInfo[tonumber(id)] = true;
                end
                item.link = link;
            end
            if (row.Text) then
                row.Text:SetText(item.link or item.name);
            end
            row:SetScript("OnEnter", function() this:ShowTip(row, item); end);
            row:SetScript("OnLeave", Utils.HideTooltip);
        end
    );

    self.AddItem:SetScript("OnClick", function() this:AddItems(); end);
    self.RemoveItem:SetScript("OnClick", function()
        ConfirmDialog:Show(this:GetParent().ConfirmDelete, "Remove selected items from group?", "REMOVE",
            function(data)
                this:RemoveItems();
            end, nil
        ); 
    end);

    self.idList.items = items;

    self.inventoryList = ListView:Acquire(self.InventoryList,
        { rowHeight = 16, childIndent = 0, template = "AnsInventoryRowTemplate", multiselect = true},
        function(item)
            if (selectedInventory[item.link]) then
                selectedInventory[item.link] = nil;
            else
                selectedInventory[item.link] = Utils.GetID(item.link);
            end
        end,
        nil,nil,
        function(row, item)
            if (row.Text) then
                row.Text:SetText(item.link);
            end
            row:SetScript("OnEnter", function() this:ShowTip(row, item); end);
            row:SetScript("OnLeave", Utils.HideTooltip);
        end
    );

    self.inventoryList.items = inventoryItems;

    self.RemoveGroup:SetScript("OnClick", 
        function()
            if (not this.selected) then
                return;
            end
            ConfirmDialog:Show(this:GetParent().ConfirmDelete, "Deleting this group will delete all sub groups.", "DELETE",
                function(data)
                    if (this.onDelete) then
                        this.onDelete(data);
                    end
                end,
                this.selected
            );
        end 
    );

    EventManager:On("GET_ITEM_INFO_RECEIVED", function(id)
        if (waitingForInfo[id]) then
            waitingForInfo[id] = nil;
            if (this:IsShown()) then
                this.idList:Refresh();
            end
        end
    end)
end