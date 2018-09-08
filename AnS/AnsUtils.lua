---
-- Format for price
---

AnsUtils = {};
AnsUtils.__index = AnsUtils;

local TempTable = {};
local BattlePetTempTable = {};
local TSMID_CACHE = {};

local OP_SIM_HAND = {
    lte = "<=",
    gte = ">=",
    neq = "~=",
    uncommon = "2"
};

local OP_SHORT_HAND = {
    lt = "<",
    gt = ">",
    eq = "==",
    common = "1",
    rare = "3",
    epic = "4",
    legendary = "5"
};

function AnsUtils:GSC(val) 
    local rv = math.floor(val);

    local g = math.floor (rv/10000);
  
    rv = rv - g*10000;
  
    local s = math.floor (rv/100);
  
    rv = rv - s*100;
  
    local c = rv;
  
    return g, s, c
end


function AnsUtils:PriceToString(val)
    local gold, silver, copper  = self:GSC(val);
    local st = "";

    if (gold ~= 0) then
        st = gold.."g ";
    end

    if (st ~= "") then
        st = st..format("%02is ", silver);
    elseif (silver ~= 0) then
        st = st..silver.."s ";
    end

    if (st ~= "") then
        st = st..format("%02ic", copper);
    elseif (copper ~= 0) then
        st = st..copper.."c";
    end

    return st;
end

function AnsUtils:IsBattlePetLink(link)
    return string.find(link,"Hbattlepet:",1) ~= nil;
end

function AnsUtils:ParseBattlePetLink(link)
    local _, id, level, quality, health, power, speed, other = strsplit(":", link);
    local name, icon, type = C_PetJournal.GetPetInfoBySpeciesID(tonumber(id));
    
    BattlePetTempTable.speciesID = tonumber(id);
    BattlePetTempTable.name = name;
    BattlePetTempTable.level = tonumber(level);
    BattlePetTempTable.breedQuality = tonumber(quality);
    BattlePetTempTable.petType = type;
    BattlePetTempTable.maxHealth = tonumber(health);
    BattlePetTempTable.power = tonumber(power);
    BattlePetTempTable.speed = tonumber(speed);
    BattlePetTempTable.customName = nil;

    return BattlePetTempTable;
end

function AnsUtils:ShowBattlePetTip(link)
    local pet = self:ParseBattlePetLink(link);
    BattlePetTooltipTemplate_SetBattlePet(BattlePetTooltip, pet);
    BattlePetTooltip:SetSize(260,136);
    BattlePetTooltip:Show();
    BattlePetTooltip:ClearAllPoints();
    BattlePetTooltip:SetPoint(GameTooltip:GetPoint());
end

function AnsUtils:IsAddonInstalled(name)
    return select(2, GetAddOnInfo(name)) and true or false;
end

function AnsUtils:IsAddonEnabled(name)
    return GetAddOnEnableState(UnitName("player"), name) == 2 and select(4, GetAddOnInfo(name)) and true or false;
end

function AnsUtils:ClearTSMIDCache()
    wipe(TSMID_CACHE);
end

function AnsUtils:GetTSMID(link)
    if (TSMID_CACHE[link]) then
        return TSMID_CACHE[link];
    end

    if (AnsUtils:IsBattlePetLink(link)) then
        local pet = AnsUtils:ParseBattlePetLink(link);
        local fresult = "p:"..pet.speciesID;
        TSMID_CACHE[link] = fresult;
        return fresult;
    else
        if (type(link) == "number") then
            return "i:"..link;
        end

        local tbl = { strsplit(":", link) };
        local bonusCount = tbl[14];
        local id = tbl[2];
        local extra = "";

        if (bonusCount) then
            bonusCount = tonumber(bonusCount);

            if(bonusCount and bonusCount > 0) then
                local i;
                local sep = ":";
                extra = "::"..bonusCount;
                for i = 1, bonusCount do
                    extra = extra..sep..tbl[14+i];
                end
            end
        end

        local fresult = "i:"..id..extra;
        TSMID_CACHE[link] = fresult;
        return fresult;
    end
end

function AnsUtils:GetAddonVersion(name)
    local v = GetAddOnMetadata(name, "Version");
    if (v) then
        local maj, min = string.match(v, "(%d+).(%d+)");
        return maj, min;
    end

    return "0","0";
end

function AnsUtils:ReplaceOpShortHand(str)
    for k, v in pairs(OP_SIM_HAND) do
        str = gsub(str, k, v);
    end
    for k, v in pairs(OP_SHORT_HAND) do
        str = gsub(str, k, v);
    end
    return str;
end

function AnsUtils:ReplaceMoneyShorthand(str)
    local s, v = self:MoneyStringToCopper(str);

    while (s and v) do
        str = gsub(str, s, v);
        s,v = self:MoneyStringToCopper(str);
    end
    return str;
end

function AnsUtils:MoneyStringToCopper(str)
    local g, s, c = string.match(str, "(%d+)g(%d+)s(%d+)c");
    local value = 0;

    if (g and s and c) then
        return g.."g"..s.."s"..c.."c", tonumber(g) * 10000 + tonumber(s) * 100 + tonumber(c);
    end

    g, s = string.match(str, "(%d+)g(%d+)s");

    if (g and s) then
        return g.."g"..s.."s", tonumber(g) * 10000 + tonumber(s) * 100;
    end

    g,c = string.match(str, "(%d+)g(%d+)c");

    if (g and c) then
        return g.."g"..c.."c", tonumber(g) * 10000 + tonumber(c);
    end

    s, c = string.match(str, "(%d+)s(%d+)c");

    if (s and c) then
        return s.."s"..c.."c", tonumber(s) * 100 + tonumber(c);
    end

    c = string.match(str, "(%d+)c");

    if (c) then
        return c.."c", tonumber(c);
    end

    s = string.match(str, "(%d+)s");

    if (s) then
        return s.."s", tonumber(s) * 100;
    end

    g = string.match(str, "(%d+)g");

    if (g) then
        return g.."g", tonumber(g) * 10000;
    end

    return nil, nil;
end