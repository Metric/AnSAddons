local Ans = select(2, ...);
local PriceSource = {};
PriceSource.__index = PriceSource;
Ans.PriceSource = PriceSource;

function PriceSource:New(name,fn,key)
    local s = {};
    setmetatable(s, PriceSource);
    s.name = name;
    s.fn = fn;
    s.key = key;
    return s;
end
