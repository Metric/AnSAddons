local Ans = select(2, ...);
local Utils = Ans.Utils;
local Config = Ans.Config;
local EventManager = Ans.EventManager;

EventManager:On("BAG_UPDATE_DELAYED", 
    function()
        if (UnitIsDead("player") or InCombatLockdown()) then
            return;
        end

        if (AnsDestroyWindow and not AnsDestroyWindow:IsShown() and Config.Crafting().autoShowDestroying) then
            AnsDestroyWindow:Populate(true);
            AnsDestroyWindow:Show();
        end
    end
);