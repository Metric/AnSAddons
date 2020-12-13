local Ans = select(2, ...);
local Crafting = Ans.Object.Register("Crafting");

function Crafting:RegisterEvents(frame)
    frame:RegisterEvent("TRADE_SKILL_SHOW");
    frame:RegisterEvent("TRADE_SKILL_CLOSE");
end