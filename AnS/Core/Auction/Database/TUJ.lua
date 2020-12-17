local Ans = select(2, ...);
local Utils = Ans.Utils;
local TUJ = Ans.Object.Register("TUJ", Ans.Database);


local temp = {};

function TUJ.GetPrice(id, key)
    if (strfind(id, "[ip]:%d+")) then
        -- need to conver to actual link if possible
        -- we don't actually care about the name
        id = Utils.GetLink(id, true);
    end

    TUJMarketInfo(id, temp);
    return temp[key];
end