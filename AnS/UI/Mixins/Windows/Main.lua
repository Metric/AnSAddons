local Ans = select(2, ...);
local TOTAL_TABS = 5;

AnsMainWindowFrameMixin = {};

function AnsMainWindowFrameMixin:Toggle()
    if (self:IsShown()) then
        self:Hide();
    else
        self:Show();
    end
end

function AnsMainWindowFrameMixin:Init()
    local this = self;
    self.tabs = {};
    self.views = {};

    for i = 1, TOTAL_TABS do
        tinsert(self.tabs, self.Tabs["Tab"..i]);
        tinsert(self.views, self["TabView"..i]);
        self.tabs[i]:SetButtonState("NORMAL", false);
        self.views[i]:Hide();

        self.tabs[i]:SetScript("OnClick", function(f)
            local id = f:GetID();
            this:SetActiveTab(tonumber(id));
        end);
    end

    self.tabs[1]:SetButtonState("PUSHED", true);
    self.views[1]:Show();
end

function AnsMainWindowFrameMixin:SetActiveTab(id)
    if (id < 1 or id > TOTAL_TABS) then
        return;
    end

    for i = 1, TOTAL_TABS do
        self.tabs[i]:SetButtonState("NORMAL", false);
        self.views[i]:Hide();
    end

    self.tabs[id]:SetButtonState("PUSHED", true);
    self.views[id]:Show();
end