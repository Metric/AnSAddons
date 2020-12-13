local Ans = select(2, ...);
local Utils = Ans.Utils;
local Macro = Ans.Macro;
local TempTable = Ans.TempTable;

AnsMacroSettingsFrameMixin = {};

function AnsMacroSettingsFrameMixin:Init()
    local this = self;
    self:SetScript("OnShow", function() this:Refresh(); end);
    self.CreateMacroBtn:SetScript("OnClick", function() this:CreateMacro(); end);
    self:Hide();
end

function AnsMacroSettingsFrameMixin:CreateMacro()
    local mods = Macro.MODIFIER_MAPPING;
    local buttons = Macro.BUTTON_MAPPING;
    local up = self.mouse.direction.up:GetChecked();
    local down = self.mouse.direction.down:GetChecked();

    local actualMods = TempTable:Acquire();
    local commands = TempTable:Acquire();

    for k,v in pairs(mods) do
        if (self.mouse.modifiers[k]:GetChecked()) then
            tinsert(actualMods, k);
        end
    end

    for k,v in pairs(buttons) do
        if (self.tsm[k] and self.tsm[k]:GetChecked()) then
            tinsert(commands, v);
        elseif (self.ans[k] and self.ans[k]:GetChecked()) then
            tinsert(commands, v);
        end
    end

    Macro.Create(commands, actualMods, up, down);

    actualMods:Release();
    commands:Release();
end

function AnsMacroSettingsFrameMixin:Refresh()
    local activeMods = Macro.ActiveModifiers();

    for k,v in pairs(activeMods) do
        if (self.mouse.modifiers[k]) then
            self.mouse.modifiers[k]:SetChecked(v);
        elseif (self.mouse.direction[k]) then
            self.mouse.direction[k]:SetChecked(v)
        end
    end

    local activeButtons = Macro.ActiveButtons();

    for k,v in pairs(activeButtons) do
        if (self.tsm[k]) then
            self.tsm[k]:SetChecked(v);
        elseif (self.ans[k]) then
            self.ans[k]:SetChecked(v);
        end
    end
end