local Ans = select(2, ...);

AnsBlacklistsSettingsFrameMixin = {};

function AnsBlacklistsSettingsFrameMixin:Init()
    self:SetScript("OnShow",
        function(f)
            f.Characters:Refresh();
            f.Items:Refresh();
        end
    );
    self:Hide();
end