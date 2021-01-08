local Ans = select(2, ...);
local Config = Ans.Config;
local TextInput = Ans.UI.TextInput;

AnsGeneralSettingsFrameMixin = {};

local basic = {
    "showDressing",
    "useCoinIcons",
    "showId",
};

local tooltipRealm = {
    "tooltipRealmRecent",
    "tooltipRealmMin",
    "tooltipRealm3Day",
    "tooltipRealmMarket"
};

local tooltipRegion = {
    "tooltipRegionMin",
    "tooltipRegionMarket"
};

local windows = {
    "saveWindowLocations",
    "showDebugWindow",
    "showPostCancel",
    "showMailSend",
};

local analytics = {
    "trackDataAnalytics",
};

function AnsGeneralSettingsFrameMixin:Init()
    local this = self;

    self.valueChangedHandler = function() this:Save(); end;

    self:SetScript("OnShow", function() this:Refresh(); end);

    for k,v in ipairs(basic) do
        if (self.basicOptions[v]) then
            self.basicOptions[v]:SetScript("OnClick", self.valueChangedHandler);
        end
    end

    for k,v in ipairs(windows) do
        if (self.windowOptions[v]) then
            self.windowOptions[v]:SetScript("OnClick", self.valueChangedHandler);
        end
    end

    for k,v in ipairs(analytics) do
        if (self.analyticOptions[v]) then
            self.analyticOptions[v]:SetScript("OnClick", self.valueChangedHandler);
        end
    end

    for k,v in ipairs(tooltipRealm) do
        if (self.tooltipOptions.realm[v]) then
            self.tooltipOptions.realm[v]:SetScript("OnClick", self.valueChangedHandler);
        end
    end

    for k,v in ipairs(tooltipRegion) do
        if (self.tooltipOptions.region[v]) then
            self.tooltipOptions.region[v]:SetScript("OnClick", self.valueChangedHandler);
        end
    end

    self.maxDataLimit = TextInput:NewFrom(self.analyticOptions.maxDataLimit);
    self.maxDataLimit.onTextChanged = self.valueChangedHandler;

    AnsDashboardFrameMixin:LoadTimeScaleDropdown(self, self.analyticOptions, self.valueChangedHandler);

    self.graphTimeScale:SetPoint("LEFT", "RIGHT", 170, 0, "trackDataAnalytics");

    self:Hide();
end

function AnsGeneralSettingsFrameMixin:Save()
    local config = Config.General();

    for k,v in ipairs(basic) do
        if (self.basicOptions[v]) then
            config[v] = self.basicOptions[v]:GetChecked();
        end
    end

    for k,v in ipairs(windows) do
        if (self.windowOptions[v]) then
            config[v] = self.windowOptions[v]:GetChecked();
        end
    end

    for k,v in ipairs(analytics) do
        if (self.analyticOptions[v]) then
            config[v] = self.analyticOptions[v]:GetChecked();
        end
    end

    for k,v in ipairs(tooltipRealm) do
        if (self.tooltipOptions.realm[v]) then
            config[v] = self.tooltipOptions.realm[v]:GetChecked();
        end
    end

    for k,v in ipairs(tooltipRegion) do
        if (self.tooltipOptions.region[v]) then
            config[v] = self.tooltipOptions.region[v]:GetChecked();
        end
    end

    config.maxDataLimit = tonumber(self.maxDataLimit:Get()) or 20000;
    config.defaultTimeMode = self.graphTimeScale.selected;
end

function AnsGeneralSettingsFrameMixin:Refresh()
    local config = Config.General();

    for k,v in ipairs(basic) do
        if (self.basicOptions[v]) then
            self.basicOptions[v]:SetChecked(config[v] or false);
        end
    end

    for k,v in ipairs(windows) do
        if (self.windowOptions[v]) then
            self.windowOptions[v]:SetChecked(config[v] == nil and true or config[v]);
        end
    end

    for k,v in ipairs(analytics) do
        if (self.analyticOptions[v]) then
            self.analyticOptions[v]:SetChecked(config[v] or false);
        end
    end

    for k,v in ipairs(tooltipRealm) do
        if (self.tooltipOptions.realm[v]) then
            self.tooltipOptions.realm[v]:SetChecked(config[v] or false);
        end
    end

    for k,v in ipairs(tooltipRegion) do
        if (self.tooltipOptions.region[v]) then
            self.tooltipOptions.region[v]:SetChecked(config[v] or false);
        end
    end

    self.maxDataLimit:Set(config.maxDataLimit.."");
    self.graphTimeScale:SetSelected(config.defaultTimeMode or 3);
end