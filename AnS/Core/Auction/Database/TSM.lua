local Ans = select(2, ...);
local TSMDB = {};
TSMDB.__index = TSMDB;
Ans.Database.TSM = TSMDB;

local Utils = Ans.Utils;
local TSM_MAJOR_VERSION = Utils:GetAddonVersion("TradeSkillMaster");

function TSMDB.GetPrice(link, key, name)
    local id = Utils:GetTSMID(link);
    if(TSM_MAJOR_VERSION == "3") then
        return TSMAPI:GetCustomPriceValue(name, id);
    else
        return TSM_API.GetCustomPriceValue(name, id);
    end
end

function TSMDB.GetSaleInfo(link, key, name)
    local r = TSMDB.GetPrice(link, key, name);
    if (TSM_MAJOR_VERSION == "3") then
        if (not r) then r = 0; end;
        return r / 100;
    else
        return r;
    end
end