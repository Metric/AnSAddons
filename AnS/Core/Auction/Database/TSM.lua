local Ans = select(2, ...);
local TSMDB = Ans.Object.Register("TSM", Ans.Database);

local Utils = Ans.Utils;
local TSM_MAJOR_VERSION = Utils.GetAddonVersion("TradeSkillMaster");

function TSMDB.GetPrice(link, key, name)
    local id = Utils.GetID(link);
    if(TSM_MAJOR_VERSION == "3") then
        return TSMAPI:GetCustomPriceValue(name, id) or 0;
    else
        return TSM_API.GetCustomPriceValue(name, id) or 0;
    end
end