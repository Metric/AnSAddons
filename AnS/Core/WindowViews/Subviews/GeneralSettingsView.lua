local Ans = select(2, ...);
local GeneralSettings = {};
local Config = Ans.Config;
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

    self.rrrtooltip = self.frame.RRRTooltip;
    self.rrmtooltip = self.frame.RRMTooltip;
    self.rr3tooltip = self.frame.RRThreeTooltip;
    self.rrmmtooltip = self.frame.RRMMTooltip;
    self.saveWindowLocations = self.frame.SaveWindowLocations;

    self.showDebug = self.frame.ShowDebug;

    self.dressup:SetScript("OnClick", self.Save);
    self.coins:SetScript("OnClick", self.Save);
    self.analytics:SetScript("OnClick", self.Save);
    
    self.rrtooltip:SetScript("OnClick", self.Save);
    self.rmtooltip:SetScript("OnClick", self.Save);
    self.r3tooltip:SetScript("OnClick", self.Save);
    self.rmmtooltip:SetScript("OnClick", self.Save);

    self.rrrtooltip:SetScript("OnClick", self.Save);
    self.rrmtooltip:SetScript("OnClick", self.Save);
    self.rr3tooltip:SetScript("OnClick", self.Save);
    self.rrmmtooltip:SetScript("OnClick", self.Save);
    self.saveWindowLocations:SetScript("OnClick", self.Save);


    self.showDebug:SetScript("OnClick", self.Save);
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
    Config.General().showDressing = GeneralSettings.dressup:GetChecked();
    Config.General().useCoinIcons = GeneralSettings.coins:GetChecked();
    Config.General().trackDataAnalytics = GeneralSettings.analytics:GetChecked();
    
    Config.General().tooltipRealmRecent = GeneralSettings.rrtooltip:GetChecked();
    Config.General().tooltipRealmMin = GeneralSettings.rmtooltip:GetChecked();
    Config.General().tooltipRealm3Day = GeneralSettings.r3tooltip:GetChecked();
    Config.General().tooltipRealmMarket = GeneralSettings.rmmtooltip:GetChecked();

    Config.General().tooltipRegionRecent = GeneralSettings.rrrtooltip:GetChecked();
    Config.General().tooltipRegionMin = GeneralSettings.rrmtooltip:GetChecked();
    Config.General().tooltipRegion3Day = GeneralSettings.rr3tooltip:GetChecked();
    Config.General().tooltipRegionMarket = GeneralSettings.rrmmtooltip:GetChecked();

    Config.General().showDebugWindow = GeneralSettings.showDebug:GetChecked();

    Config.General().saveWindowLocations = GeneralSettings.saveWindowLocations:GetChecked();
end

function GeneralSettings:Load()
    self.dressup:SetChecked(Config.General().showDressing);
    self.coins:SetChecked(Config.General().useCoinIcons);
    self.analytics:SetChecked(Config.General().trackDataAnalytics);

    self.rrtooltip:SetChecked(Config.General().tooltipRealmRecent);
    self.rmtooltip:SetChecked(Config.General().tooltipRealmMin);
    self.r3tooltip:SetChecked(Config.General().tooltipRealm3Day);
    self.rmmtooltip:SetChecked(Config.General().tooltipRealmMarket);
    
    self.rrrtooltip:SetChecked(Config.General().tooltipRegionRecent);
    self.rrmtooltip:SetChecked(Config.General().tooltipRegionMin);
    self.rr3tooltip:SetChecked(Config.General().tooltipRegion3Day);
    self.rrmmtooltip:SetChecked(Config.General().tooltipRegionMarket);

    self.saveWindowLocations:SetChecked(Config.General().saveWindowLocations);

    self.showDebug:SetChecked(Config.General().showDebugWindow);
end