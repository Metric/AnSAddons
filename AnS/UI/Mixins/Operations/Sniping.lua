local Ans = select(2, ...);

local Dropdown = Ans.UI.Dropdown;
local TextInput = Ans.UI.TextInput;
local Utils = Ans.Utils;
local Sources = Ans.Sources;

local AnsQualityToText = {};
AnsQualityToText[1] = "Common";
AnsQualityToText[2] = "Uncommon";
AnsQualityToText[3] = "Rare";
AnsQualityToText[4] = "Epic";
AnsQualityToText[5] = "Legendary";

AnsSnipeOperationFrameMixin = {};

function AnsSnipeOperationFrameMixin:Init()
    local this = self;
    self.selected = nil;

    self.name = TextInput:NewFrom(self.OpName);
    self.price = TextInput:NewFrom(self.Price.Text);
    self.price:EnableMultiLine();
    self.price.sourceValidation = Sources;
    
    self.maxPercent = TextInput:NewFrom(self.MaxPercent);
    self.minILevel = TextInput:NewFrom(self.MinLevel);
    self.maxPPU = TextInput:NewFrom(self.MaxPPU);
    self.search = TextInput:NewFrom(self.Search);

    self.valueChangeHandler = function() this:ValuesChanged(); end;

    self.ExactMatch:SetScript("OnClick", self.valueChangeHandler);
    self.Recalc:SetScript("OnClick", self.valueChangeHandler);

    self.name.onTextChanged = self.valueChangeHandler;
    self.maxPercent.onTextChanged = self.valueChangeHandler;
    self.price.onTextChanged = self.valueChangeHandler;
    self.minILevel.onTextChanged = self.valueChangeHandler;
    self.maxPPU.onTextChanged = self.valueChangeHandler;
    self.search.onTextChanged = self.valueChangeHandler;

    self.InheritGlobal:SetScript("OnClick", self.valueChangeHandler);

    self:LoadDropdowns();
end

function AnsSnipeOperationFrameMixin:Set(op)
    self.selected = nil;

    if (not op) then
        self:Hide();
        return;
    end

    self.Recalc:SetChecked(op.recalc);
    self.name:Set(op.name);
    self.price:Set(op.price);
    self.maxPercent:Set(op.maxPercent.."");
    self.minILevel:Set(op.minILevel.."");
    self.maxPPU:Set(Utils.PriceToString(op.maxPPU, true, true));
    self.search:Set(op.search);
    self.ExactMatch:SetChecked(op.exactMatch);
    self.minQualityDropdown:SetSelected(op.minQuality + 1);
    self.InheritGlobal:SetChecked(op.inheritGlobal);

    self.selected = op;
    
    self:Show();
end

function AnsSnipeOperationFrameMixin:ValuesChanged()
    if (not self.selected) then
        return;
    end

    self.selected.name = self.name:Get() or "";
    self.selected.price = self.price:Get() or "";
    
    self.selected.maxPercent = tonumber(self.maxPercent:Get()) or 0;
    self.selected.minILevel = tonumber(self.minILevel:Get()) or 0;

    local txt, ppu = Utils.MoneyStringToCopper(self.maxPPU:Get());

    if (not ppu) then
        ppu = 0;
    end

    self.selected.maxPPU = ppu;

    self.selected.search = self.search:Get();
    self.selected.exactMatch = self.ExactMatch:GetChecked();

    self.selected.recalc = self.Recalc:GetChecked();

    self.selected.minQuality = self.minQualityDropdown.selected - 1;

    self.selected.inheritGlobal = self.InheritGlobal:GetChecked();

    if (self.onEdit) then
        self.onEdit();
    end
end

function AnsSnipeOperationFrameMixin:LoadDropdowns()
    local this = self;

    -- add min quality drop down
    self.minQualityDropdown = Dropdown:Acquire(nil, self);
    self.minQualityDropdown:SetPoint("TOPLEFT", "TOPLEFT", 110, -224);
    self.minQualityDropdown:SetSize(125, 20);
    self.minQualityDropdown:AddItem("No Min Quality", self.valueChangeHandler);

    for i,v in ipairs(AnsQualityToText) do
        self.minQualityDropdown:AddItem(v, self.valueChangeHandler);
    end
end