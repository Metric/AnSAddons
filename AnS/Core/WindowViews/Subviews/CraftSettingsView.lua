local Ans = select(2, ...);
local TextInput = Ans.UI.TextInput;
local Config = Ans.Config;
local CraftSettings = {};
CraftSettings.__index = CraftSettings;
Ans.CraftSettingsView = CraftSettings;

function CraftSettings:OnLoad(f)
    self.parent = f;
    self.frame = CreateFrame("Frame", "AnsCraftOptionsView", f, "AnsCraftSettingsTemplate");

    self.craftValue = TextInput:NewFrom(self.frame.CraftValue);
    self.craftValue.onTextChanged = self.SaveCraftValue;

    self.materialCost = TextInput:NewFrom(self.frame.MaterialCost);
    self.materialCost.onTextChanged = self.SaveMaterialCost;

    self.frame:Hide();
end

function CraftSettings.SaveCraftValue()
    Config.Crafting().craftValue = CraftSettings.craftValue:Get();
end

function CraftSettings.SaveMaterialCost()
    Config.Crafting().materialCost = CraftSettings.materialCost:Get();
end

function CraftSettings:Show()
    if (self.frame) then
        self.frame:Show();
        self:Load();
    end
end

function CraftSettings:Hide()
    if (self.frame) then
        self.frame:Hide();
    end
end

function CraftSettings:Load()
    self.craftValue:Set(Config.Crafting().craftValue or "");
    self.materialCost:Set(Config.Crafting().materialCost or "");
end