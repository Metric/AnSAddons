local Ans = select(2, ...);
local GeneralSettings = {};
GeneralSettings.__index = GeneralSettings;
Ans.GeneralSettingsView = GeneralSettings;

function GeneralSettings:OnLoad(f)
    self.parent = f;
    self.frame = CreateFrame("Frame", "AnsGeneralOptionsView", f, "AnsGeneralSettingsTemplate");

    self.dressup = self.frame.DressUp;
    self.coins = self.frame.Coins;
    self.analytics = self.frame.Analytics;
    self.rrtooltip = self.frame.RRTooltip;
    self.rmtooltip = self.frame.RMTooltip;
    self.r3tooltip = self.frame.RThreeTooltip;
    self.rmmtooltip = self.frame.RMMTooltip;

    self.dressup:SetScript("OnClick", self.Save);
    self.coins:SetScript("OnClick", self.Save);
    self.analytics:SetScript("OnClick", self.Save);
    self.rrtooltip:SetScript("OnClick", self.Save);
    self.rmtooltip:SetScript("OnClick", self.Save);
    self.r3tooltip:SetScript("OnClick", self.Save);
    self.rmmtooltip:SetScript("OnClick", self.Save);
    self.frame:Hide();
end

function GeneralSettings:Show()
    if (self.frame) then
        self.frame:Show();
        self:Load();
    end
end

function GeneralSettings:Hide()
    if (self.frame) then
        self.frame:Hide();
    end
end

function GeneralSettings.Save()
    ANS_GLOBAL_SETTINGS.showDressing = GeneralSettings.dressup:GetChecked();
    ANS_GLOBAL_SETTINGS.useCoinIcons = GeneralSettings.coins:GetChecked();
    ANS_GLOBAL_SETTINGS.trackDataAnalytics = GeneralSettings.analytics:GetChecked();
    ANS_GLOBAL_SETTINGS.tooltipRealmRecent = GeneralSettings.rrtooltip:GetChecked();
    ANS_GLOBAL_SETTINGS.tooltipRealmMin = GeneralSettings.rmtooltip:GetChecked();
    ANS_GLOBAL_SETTINGS.tooltipRealm3Day = GeneralSettings.r3tooltip:GetChecked();
    ANS_GLOBAL_SETTINGS.tooltipRealmMarket = GeneralSettings.rmmtooltip:GetChecked();
end

function GeneralSettings:Load()
    self.dressup:SetChecked(ANS_GLOBAL_SETTINGS.showDressing);
    self.coins:SetChecked(ANS_GLOBAL_SETTINGS.useCoinIcons);
    self.analytics:SetChecked(ANS_GLOBAL_SETTINGS.trackDataAnalytics);
    self.rrtooltip:SetChecked(ANS_GLOBAL_SETTINGS.tooltipRealmRecent);
    self.rmtooltip:SetChecked(ANS_GLOBAL_SETTINGS.tooltipRealmMin);
    self.r3tooltip:SetChecked(ANS_GLOBAL_SETTINGS.tooltipRealm3Day);
    self.rmmtooltip:SetChecked(ANS_GLOBAL_SETTINGS.tooltipRealmMarket);
end