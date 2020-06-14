local Ans = select(2, ...);
local Utils = Ans.Utils;
local Macro = Ans.Macro;
local MacroView = {};
MacroView.__index = MacroView;

Ans.MacroSettingsView = MacroView;

function MacroView:OnLoad(f)
    self.parent = f;
    self.frame = CreateFrame("Frame", "AnsMacroOptionsView", f, "AnsMacroSettingsTemplate");

    self.frame.CreateMacroBtn:SetScript("OnClick", MacroView.CreateMacro);

    self.frame:Hide();
end

function MacroView:Show()
    if (self.frame) then
        self.frame:Show();
        self:Load();
    end
end

function MacroView:Hide()
    if (self.frame) then
        self.frame:Hide();
    end
end

function MacroView.CreateMacro()
    local mods = Macro.MODIFIER_MAPPING;
    local buttons = Macro.BUTTON_MAPPING;
    local up = MacroView.frame.up:GetChecked();
    local down = MacroView.frame.down:GetChecked();

    local actualMods = Utils:GetTable();
    local commands = Utils:GetTable();

    for k,v in pairs(mods) do
        if (MacroView.frame[k]:GetChecked()) then
            tinsert(actualMods, k);
        end
    end

    for k,v in pairs(buttons) do
        if (MacroView.frame[k]:GetChecked()) then
            tinsert(commands, v);
        end
    end

    Macro.Create(commands, actualMods, up, down);

    Utils:ReleaseTable(actualMods);
    Utils:ReleaseTable(commands);
end

function MacroView:Load()
    local activeMods = Macro.ActiveModifiers();

    for k,v in pairs(activeMods) do
        self.frame[k]:SetChecked(v);
    end

    local activeButtons = Macro.ActiveButtons();

    for k,v in pairs(activeButtons) do
        self.frame[k]:SetChecked(v);
    end
end