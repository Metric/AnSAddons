local Ans = select(2, ...);
local TUJ = {};
TUJ.__index = TUJ;

Ans.Database.TUJ = TUJ;

local temp = {};

function TUJ.GetPrice(id, key)
    if (strfind(id, "[ip]:%d+%(%d+%)")) then
        return 0;
    end

    TUJMarketInfo(id, temp);
    return temp[key];
end