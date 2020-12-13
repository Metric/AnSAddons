local Ans = select(2, ...);
local TSMDB = Ans.Object.Register("TSM", Ans.Database);

local Utils = Ans.Utils;
local TSM_MAJOR_VERSION = Utils.GetAddonVersion("TradeSkillMaster");

function TSMDB.GetPrice(link, key, name)
    if (strfind(link, "[ip]:%d+%(%d+%)")) then
        return 0;
    end

    local id = Utils.GetID(link);
    if(TSM_MAJOR_VERSION == "3") then
        return TSMAPI:GetCustomPriceValue(name, id) or 0;
    else
        return TSM_API.GetCustomPriceValue(name, id) or 0;
    end
end

function TSMDB.GetSaleInfo(link, key, name)
    if (strfind(link, "[ip]:%d+%(%d+%)")) then
        return 0;
    end

    local r = TSMDB.GetPrice(link, key, name);
    if (TSM_MAJOR_VERSION == "3") then
        if (not r) then r = 0; end;
        return r / 100;
    else
        return r or 0;
    end
end