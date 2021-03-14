local Ans = select(2, ...);
local Utils = Ans.Utils;
local Crafting = Ans.Object.Register("Crafting");

function Crafting:RegisterEvents(frame)
    frame:RegisterEvent("TRADE_SKILL_SHOW");
    frame:RegisterEvent("TRADE_SKILL_CLOSE");
    
    if (not Utils.IsClassic()) then
        frame:RegisterEvent("TRADE_SKILL_DATA_SOURCE_CHANGED");
    else
        frame:RegisterEvent("TRADE_SKILL_UPDATE");
    end
end