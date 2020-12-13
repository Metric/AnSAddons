local Ans = select(2, ...);
local PriceSource = Ans.Object.Register("PriceSource");

function PriceSource:Acquire(name, fn, key)
    local s = PriceSource:New();
    s.name = name;
    s.fn = fn;
    s.key = key;
    return s;
end
