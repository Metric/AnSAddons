local Ans = select(2, ...);
local TUJ = Ans.Object.Register("TUJ", Ans.Database);

local temp = {};

function TUJ.GetPrice(id, key)
    if (strfind(id, "[ip]:%d+%(%d+%)")) then
        return 0;
    end

    TUJMarketInfo(id, temp);
    return temp[key];
end