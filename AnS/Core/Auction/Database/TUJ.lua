local Ans = select(2, ...);
local TUJ = {};
TUJ.__index = TUJ;

Ans.Database.TUJ = TUJ;

local temp = {};

function TUJ.GetPrice(id, key)
    TUJMarketInfo(id, temp);
    return temp[key];
end