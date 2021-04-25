local Ans = select(2, ...);

local TextInput = Ans.UI.TextInput;
local Dropdown = Ans.UI.Dropdown;
local Utils = Ans.Utils;
local Sources = Ans.Sources;

local retailDurations = {
    "12 Hours",
    "24 Hours",
    "48 Hours"
};

local classicDurations = {
    "2 Hours",
    "8 Hours",
    "24 Hours"
};

local Actions = {
    "Use Min Price",
    "Use Max Price",
    "Use Normal Price",
    "Do Nothing",
    "Match Price",
};

local References = {
    "iLevel",
    "iLevel+Mods",
    "Base Only",
};

AnsAuctionOperationFrameMixin = {};

function AnsAuctionOperationFrameMixin:Init()
    local this = self;

    self.selected = nil;

    self.name = TextInput:NewFrom(self.OpName);
    self.keepInBags = TextInput:NewFrom(self.KeepInBags);
    self.maxToPost = TextInput:NewFrom(self.MaxToPost);
    self.stackSize = TextInput:NewFrom(self.StackSize);
    self.bidPercent = TextInput:NewFrom(self.BidPercent);
    self.undercut = TextInput:NewFrom(self.Undercut);

    self.minPrice = TextInput:NewFrom(self.MinPrice);
    self.maxPrice = TextInput:NewFrom(self.MaxPrice);
    self.normalPrice = TextInput:NewFrom(self.NormalPrice);
    
    self.valueChangeHandler = function() this:ValuesChanged(); end;

    self.CommodityLow:SetScript("OnClick", self.valueChangeHandler);
    self.ApplyAll:SetScript("OnClick", self.valueChangeHandler);

    self.name.onTextChanged = self.valueChangeHandler;
    self.keepInBags.onTextChanged = self.valueChangeHandler;
    self.maxToPost.onTextChanged = self.valueChangeHandler;
    self.stackSize.onTextChanged = self.valueChangeHandler;
    self.bidPercent.onTextChanged = self.valueChangeHandler;
    self.undercut.onTextChanged = self.valueChangeHandler;

    self.minPrice.onTextChanged = self.valueChangeHandler;
    self.maxPrice.onTextChanged = self.valueChangeHandler;
    self.normalPrice.onTextChanged = self.valueChangeHandler;

    self.minPrice.sourceValidation = Sources;
    self.maxPrice.sourceValidation = Sources;
    self.normalPrice.sourceValidation = Sources;

    self:LoadDropdowns();
end

function AnsAuctionOperationFrameMixin:Set(op)
    self.selected = nil;

    if(not op) then
        self:Hide();
        return;
    end

    self.name:Set(op.name);
    
    self.keepInBags:Set(op.keepInBags.."");
    self.maxToPost:Set(op.maxToPost.."");
    self.stackSize:Set(op.stackSize.."");
    
    self.bidPercent:Set(math.floor((op.bidPercent or 1) * 100).."");
    self.undercut:Set(op.undercut);
    
    self.minPrice:Set(op.minPrice);
    self.maxPrice:Set(op.maxPrice);
    self.normalPrice:Set(op.normalPrice);

    self.CommodityLow:SetChecked(op.commodityLow);
    self.ApplyAll:SetChecked(op.applyAll);

    self.duration:SetSelected(op.duration);
    self.minAction:SetSelected(op.minPriceAction or 4);
    self.maxAction:SetSelected(op.maxPriceAction or 3);

    self.refAction:SetSelected(op.itemReference or 1);

    self.selected = op;
    self:Show();
end

function AnsAuctionOperationFrameMixin:ValuesChanged()
    if (not self.selected) then
        return;
    end

    self.selected.name = self.name:Get() or "";
    self.selected.keepInBags = tonumber(self.keepInBags:Get()) or 0;
    
    self.selected.maxToPost = tonumber(self.maxToPost:Get()) or 0;
    self.selected.stackSize = tonumber(self.stackSize:Get()) or 0;

    self.selected.bidPercent = (tonumber(self.bidPercent:Get()) or 0) / 100;
    self.selected.undercut = self.undercut:Get();

    self.selected.minPrice = self.minPrice:Get();
    self.selected.maxPrice = self.maxPrice:Get();
    self.selected.normalPrice = self.normalPrice:Get();

    self.selected.commodityLow = self.CommodityLow:GetChecked();
    self.selected.applyAll = self.ApplyAll:GetChecked();

    self.selected.duration = self.duration.selected;

    self.selected.minPriceAction = self.minAction.selected;
    self.selected.maxPriceAction = self.maxAction.selected;

    self.selected.itemReference = self.refAction.selected;

    if (self.onEdit) then
        self.onEdit();
    end
end

function AnsAuctionOperationFrameMixin:LoadDropdowns()
    local this = self;

    self.duration = Dropdown:Acquire(nil, self);
    self.duration:SetPoint("TOPLEFT", "TOPLEFT", 0, 32);
    self.duration:SetSize(125, 20);

    local items = retailDurations;
    if (Utils.IsClassic()) then
        items = classicDurations;
    end

    for i,v in ipairs(items) do
        self.duration:AddItem(v, self.valueChangeHandler);
    end

    self.minAction = Dropdown:Acquire(nil, self);
    self.minAction:SetPoint("TOPRIGHT", "TOPRIGHT", -100, -160);
    self.minAction:SetSize(125, 20);

    self.maxAction = Dropdown:Acquire(nil, self);
    self.maxAction:SetPoint("TOPRIGHT", "TOPRIGHT", -100, -230);
    self.maxAction:SetSize(125, 20);

    for i,v in ipairs(Actions) do
        self.minAction:AddItem(v, self.valueChangeHandler);
        self.maxAction:AddItem(v, self.valueChangeHandler);
    end

    self.refAction = Dropdown:Acquire(nil, self);
    self.refAction:SetPoint("TOPLEFT", "TOPLEFT", 210, 30);
    self.refAction:SetSize(125, 20);

    for i,v in ipairs(References) do
        self.refAction:AddItem(v, self.valueChangeHandler);
    end
end