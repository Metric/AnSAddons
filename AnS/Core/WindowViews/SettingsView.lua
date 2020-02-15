local Ans = select(2, ...);

local ListView = Ans.UI.ListView;
local GeneralSettings = Ans.GeneralSettingsView;
local SniperSettings = Ans.SnipeSettingsView;
local CustomSources = Ans.CustomSourcesView;
local CraftingSettings = Ans.CraftSettingsView;

local Settings = {};
local selectedItem = GeneralSettings;
local listItems = {
    { name = "General", view = GeneralSettings, selected = true},
    { name = "Crafting", view = CraftingSettings, selected = false},
    { name = "Sniper", view = SniperSettings, selected = false},
    { name = "Custom Sources", view = CustomSources, selected = false}
};

Settings.__index = Settings;
Settings.selected = false;
Settings.loaded = false;
Settings.index = 5;

Ans.SettingsView = Settings;

function Settings:OnLoad(f)
    self.loaded = true;
    local this = self;
    local tab = _G[f:GetName().."TabView"..self.index];
    self.tab = tab;

    GeneralSettings:OnLoad(self.tab);
    SniperSettings:OnLoad(self.tab);
    CustomSources:OnLoad(self.tab);
    CraftingSettings:OnLoad(self.tab);

    self.listView = ListView:New(self.tab.Items,
        {rowHeight = 24, childIndent = 0, template="AnsTab2Template", multiselect = false, usePushTexture = true},
        Settings.Select, nil, nil, nil);

    self.listView.items = listItems;
end

function Settings:Show()
    if (self.tab) then
        self.selected = true;
        self.tab:Show();
        self.listView:Refresh();

        if (selectedItem) then
            selectedItem:Show();
        end
    end
end

function Settings:Hide()
    if (self.tab) then
        self.selected = false;
        self.tab:Hide();
    end
end

function Settings.Select(item)
    if (selectedItem) then
        selectedItem:Hide();
    end
    selectedItem = item.view;
    selectedItem:Show();
end