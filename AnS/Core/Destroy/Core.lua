local Ans = select(2, ...);
local Destroy = Ans.Object.Register("Destroy");

function Destroy:RegisterEvents(f)
    f:RegisterEvent("LOOT_CLOSED");
    f:RegisterEvent("UNIT_SPELLCAST_START");
    f:RegisterEvent("UNIT_SPELLCAST_FAILED");
    f:RegisterEvent("UNIT_SPELLCAST_FAILED_QUIET");
    f:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED");
end