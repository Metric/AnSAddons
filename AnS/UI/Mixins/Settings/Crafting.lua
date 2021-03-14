local Ans = select(2, ...);

local TextInput = Ans.UI.TextInput;
local Dropdown = Ans.UI.Dropdown;
local Sources = Ans.Sources;

local Config = Ans.Config;

local AnsQualityToText = {};
AnsQualityToText[1] = "Common";
AnsQualityToText[2] = "Uncommon";
AnsQualityToText[3] = "Rare";
AnsQualityToText[4] = "Epic";
AnsQualityToText[5] = "Legendary";

AnsCraftingSettingsFrameMixin = {};

function AnsCraftingSettingsFrameMixin:Init()
    local this = self;

    self:SetScript("OnShow", function() this:Refresh(); end);

    self.valueChangedHandler = function() this:Save(); end;

    self.craftValue = TextInput:NewFrom(self.values.CraftValue);
    self.craftValue.sourceValidation = Sources;
    self.materialCost = TextInput:NewFrom(self.values.MaterialCost);
    self.materialCost.sourceValidation = Sources;

    self.craftValue.onTextChanged = self.valueChangedHandler;
    self.materialCost.onTextChanged = self.valueChangedHandler;

    self.destroying.AutoDestroy:SetScript("OnClick", self.valueChangedHandler);
    self.disenchantMinValue = TextInput:NewFrom(self.destroying.DisenchantMinValue);
    self.disenchantMinValue.onTextChanged = self.valueChangedHandler;
    self.values.HideProfit:SetScript("OnClick", self.valueChangedHandler);
    self.values.HideCost:SetScript("OnClick", self.valueChangedHandler);

    self:LoadDropdown();
    self:Hide();
end

function AnsCraftingSettingsFrameMixin:Save()
    Config.Crafting().craftValue = self.craftValue:Get() or "";
    Config.Crafting().materialCost = self.materialCost:Get() or "";
    Config.Crafting().disenchantMinValue = self.disenchantMinValue:Get() or "0c";
    Config.Crafting().autoShowDestroying = self.destroying.AutoDestroy:GetChecked();
    Config.Crafting().destroyMaxQuality = self.destroyMaxQuality.selected - 1;
    Config.Crafting().hideCost = self.values.HideCost:GetChecked();
    Config.Crafting().hideProfit = self.values.HideProfit:GetChecked();
end

function AnsCraftingSettingsFrameMixin:Refresh()
    self.craftValue:Set(Config.Crafting().craftValue or "");
    self.materialCost:Set(Config.Crafting().materialCost or "");
    self.disenchantMinValue:Set(Config.Crafting().disenchantMinValue or "0c");
    self.destroying.AutoDestroy:SetChecked(Config.Crafting().autoShowDestroying);
    self.destroyMaxQuality:SetSelected(Config.Crafting().destroyMaxQuality + 1);
    self.values.HideProfit:SetChecked(Config.Crafting().hideProfit);
    self.values.HideCost:SetChecked(Config.Crafting().hideCost);
end

function AnsCraftingSettingsFrameMixin:LoadDropdown()
    local this = self;

    self.dropValueChanged = function(index) Config.Crafting().destroyMaxQuality = index - 1; end;

    self.destroyMaxQuality = Dropdown:Acquire(nil, self.destroying);
    self.destroyMaxQuality:SetPoint("TOPLEFT", "BOTTOMLEFT", 0, -26, "AutoDestroy");
    self.destroyMaxQuality:SetSize(125, 20);
    self.destroyMaxQuality:AddItem("No Max Quality", self.dropValueChanged);

    for i,v in ipairs(AnsQualityToText) do
        self.destroyMaxQuality:AddItem(v, self.dropValueChanged);
    end
end