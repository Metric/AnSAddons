local Ans = select(2, ...);
local Dashboard = Ans.DashboardView;
local Ledger = Ans.LedgerView;
local Groups = Ans.GroupsView;
local Operations = Ans.OperationsView;

local Window = {};
Window.__index = Window;
Window.selectedTab = 1;
Window.tabs = {Dashboard, Ledger, Groups, Operations};
Window.frame = nil;

Ans.Window = Window;

function Window:Toggle()
    if (self.frame:IsShown()) then
        self.frame:Hide();
    else
        self.frame:Show();
    end
end

function Window:OnTabClick(f)
    local id = f:GetID();
    local tab = self.tabs[id];
    if (not tab) then
        return;
    end

    self.selectedTab = id;
    self:UpdateTabStates();
end

function Window:UpdateTabStates()
    for i,v in ipairs(self.tabs) do
        if (i ~= self.selectedTab) then
            local t = _G[self.frame:GetName().."TabsTab"..i];

            if (t) then
                t:SetButtonState("NORMAL", false);
            end

            if (v) then
                v:Hide();
            end
        else
            local t = _G[self.frame:GetName().."TabsTab"..i];
            if (t) then
                t:SetButtonState("PUSHED", true);
            end
            if (v) then
                v:Show();
            end
        end
    end                                                                 
end

function Window:OnShow()
    self:UpdateTabStates();
end

function Window:OnHide()
    for i,v in ipairs(self.tabs) do
        v:Hide();
    end
end

function Window:OnLoad(f)
    self.frame = f;
    for i,v in ipairs(self.tabs) do
        v:OnLoad(f);
    end
end