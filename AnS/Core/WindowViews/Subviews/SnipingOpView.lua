local Ans = select(2, ...);
local GroupsView = Ans.GroupsView;
local TextInput = Ans.UI.TextInput;
local ConfirmDialog = Ans.UI.ConfirmDialog;
local Dropdown = Ans.UI.Dropdown;
local TreeView = Ans.UI.TreeView;
local ListView = Ans.UI.ListView;
local Utils = Ans.Utils;
local BaseData = Ans.BaseData;

local AnsQualityToText = {};
AnsQualityToText[1] = "Common";
AnsQualityToText[2] = "Uncommon";
AnsQualityToText[3] = "Rare";
AnsQualityToText[4] = "Epic";
AnsQualityToText[5] = "Legendary";

local SnipingView = {}
SnipingView.__index = SnipingView;
SnipingView.onUpdate = nil;
Ans.SnipingOpView = SnipingView;

function SnipingView:OnLoad(f)
    local this = self;
    self.selected = nil;
    self.parent = f;
    self.frame = CreateFrame("FRAME", "SnipingEditor", f, "AnsSnipeOpEditorTemplate");
    
    self.name = TextInput:NewFrom(self.frame.OpName);
    self.price = TextInput.NewFrom(self.frame.Price);
    self.price:EnableMultiLine();

    self.maxPercent = TextInput.NewFrom(self.frame.maxPercent);
    self.minILevel = TextInput.NewFrom(self.frame.MinLevel);
    self.minCLevel = TextInput.NewFrom(self.frame.MinCLevel);
    self.maxCLevel = TextInput.NewFrom(self.frame.MaxCLevel);
    self.maxPPU = TextInput.NewFrom(self.frame.MaxPPU);
    self.search = TextInput.NewFrom(self.frame.Search);

    self.exactMatch = self.frame.exactMatch;
    self.exactMatch:SetScript("OnClick", function(f) this:ValuesChanged(); end);


    self.name.onTextChanged = function() this:ValuesChanged(); end;
    self.maxPercent.onTextChanged = function() this:ValuesChanged(); end;
    self.price.onTextChanged = function() this:ValuesChanged(); end;
    self.minILevel.onTextChanged = function() this:ValuesChanged(); end;
    self.minCLevel.onTextChanged = function() this:ValuesChanged(); end;
    self.maxCLevel.onTextChanged = function() this:ValuesChanged(); end;
    self.maxPPU.onTextChanged = function() this:ValuesChanged(); end;
    self.search.onTextChanged = function() this:ValuesChanged(); end;

    self.classIDSelected = 0;
    self.subClassIDSelected = 0;
    self.inventoryTypeSelected = 0;

    self:LoadDropdowns();
end

function SnipingOpView:Hide()
    self.selected = nil;
    if (self.frame) then
        self.frame:Hide();
    end
end

function SnipingView:Set(snipeOp)
    self.selected = snipeOp;

    self.name:Set(snipeOP.name);
    self.price:Set(snipeOp.price);
    self.maxPercent:Set(snipeOp.maxPercent.."");
    self.minILevel:Set(snipeOp.minILevel.."");
    self.minCLevel:Set(snipeOp.minCLevel.."");
    self.maxCLevel:Set(snipeOp.maxCLevel.."");
    self.maxPPU:Set(snipeOp.maxPPU.."");
    self.search:Set(snipeOp.search);
    self.exactMatch:SetChecked(snipeOp.exactMatch);


    self.classIDDropdown:SetSelected(snipeOp.classIDIndex);

    if (snipeOp.classIDIndex > 1) then
        self.subClassIDDropdown:SetSelected(snipeOp.subClassIDIndex);
    end

    if (snipeOp.subClassIDIndex > 1) then
        self.inventoryTypeDropdown:SetSelected(snipeOp.inventoryTypeIndex);
    end

    self:minQualityDropdown:SetSelected(snipeOp.minQuality + 1);
end

function SnipingView:ValuesChanged()
    if (not self.selected) then
        return;
    end

    self.selected.name = self.name:Get() or "";
    self.selected.price = self.price:Get() or "";
    
    self.selected.maxPercent = tonumber(self.maxPercent:Get()) or 0;
    self.selected.minILevel = tonumber(self.minILevel:Get()) or 0;
    
    self.selected.minCLevel = tonumber(self.minCLevel:Get()) or 0;
    self.selected.maxCLevel = tonumber(self.maxCLevel:Get()) or 0;

    self.selected.maxPPU = tonumber(self.maxPPU:Get()) or 0;
    self.selected.search = self.search:Get();
    self.selected.exactMatch = self.exactMatch:GetChecked();

    self.selected.minQuality = self.minQualityDropdown.selected - 1;

    if (self.onUpdate) then
        self.onUpdate();
    end
end

function SnipingView:OnSelectClassID()
    local i = self.classIDDropdown.selected - 1;
    self.selected.classIDIndex = self.classIDDropdown.selected;
    self.classIDSelected = i;

    if (i > 0) then
        self.selected.classID = BaseData[i].classID;
    else
        self.selected.classID = 0;
    end

    self.selected.inventoryType = 0;
    self.selected.subClassID = 0;

    self.subClassIDDropdown:ClearItems();
    self.subClassIDDropdown:Hide();

    self.subClassIDSelected = 0;
    self.inventoryTypeSelected = 0;

    self.inventoryTypeDropdown:ClearItems();
    self.inventoryTypeDropdown:Hide();

    if (i > 0) then
        self:LoadSubClassDropdown();
    end
end


function SnipingView:OnSelectSubClassID()
    local i = self.subClassIDDropdown.selected - 1;

    self.selected.subClassIDIndex = self.subClassIDDropdown.selected;
    self.subClassIDSelected = i;

    if (i > 0) then
        self.selected.subClassID = BaseData[self.classIDSelected].children[i].subClassID;
    else
        self.selected.subClassID = 0;
    end

    self.inventoryTypeSelected = 0;
    self.selected.inventoryType = 0;

    self.inventoryTypeDropdown:ClearItems();
    self.inventoryTypeDropdown:Hide();

    if (i > 0) then
        self:LoadInventoryTypeDropdown();
    end
end

function SnipingView:OnSelectInventoryType()
    local i = self.inventoryTypeDropdown.selected - 1;
    self.selected.inventoryTypeIndex = self.inventoryTypeDropdown.selected;
    self.inventoryTypeSelected = i;

    if (i > 0) then
        self.selected.inventoryType = BaseData[self.classIDSelected].children[self.subClassIDSelected].children[i].inventoryType;
    else
        self.selected.inventoryType = 0;
    end
end

function SnipingView:LoadInventoryTypeDropdown()
    local this = self;
    local classItem = BaseData[self.classIDSelected];
    local sub = classItem.children[self.subClassIDSelected];

    if (#sub.children > 0) then
        self.inventoryTypeDropdown:AddItem("No Inventory Type", function() this:OnSelectInventoryType(); end);
        for i,v in ipairs(sub.children) do
            self.inventoryTypeDropdown:AddItem(v.name, function() this:OnSelectInventoryType(); end);
        end
        self.inventoryTypeDropdown:Show();
    end
end

function SnipingView:LoadSubClassDropdown()
    local this = self;
    local classItems = BaseData[self.classIDSelected];
    if (#classItems.children > 0) then
        self.subClassIDDropdown:AddItem("No Subtype", function() this:OnSelectSubClassID(); end);
        for i,v in ipairs(classItems.children) do
            self.subClassIDDropdown:AddItem(v.name, function() this:OnSelectSubClassID(); end);
        end
        self.subClassIDDropdown:Show();
    end
end

function SnipingView:LoadDropdowns()
    local this = self;
    self.classIDDropdown = Dropdown:New("ClassID", self.frame);
    self.subClassIDDropdown = Dropdown:New("SubClassID", self.frame);
    self.inventoryTypeDropdown = Dropdown:New("InventoryType", self.frame);

    -- set positions and heights
    self.classIDDropdown:SetSize(100, 20);
    self.classIDDropdown:SetPoint("TOPLEFT", "TOPLEFT", 110, 138);
    self.subClassIDDropdown:SetPoint("TOPLEFT", "TOPLEFT", 110, 168);
    self.subClassIDDropdown:SetSize(100, 20);
    self.inventoryTypeDropdown:SetPoint("TOPLEFT", "TOPLEFT", 110, 188);
    self.inventoryTypeDropdown:SetSize(100, 20);

    self.classIDDropdown:AddItem("No Class", function() this:OnSelectClassID(); end);

    for i,v in ipairs(BaseData) do
        self.classIDDropdown:AddItem(v.name, function() this:OnSelectClassID(); end);
    end

    -- sub class and inventory type
    self.subClassIDDropdown:Hide();
    self.inventoryTypeDropdown:Hide();

    -- add min quality drop down
    self.minQualityDropdown = Dropdown:New("MinQuality", self.frame);
    self.minQualityDropdown:SetSize(100, 20);
    self.minQualityDropdown:SetPoint("TOPLEFT", "TOPLEFT", 110, 208);

    self.minQualityDropdown:AddItem("No Min Quality", function() this:ValuesChanged(); end);

    for i,v in ipairs(AnsQualityToText) do
        self.minQualityDropdown:AddItem(v, function() this:ValuesChanged(); end);
    end
end