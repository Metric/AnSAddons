---
-- Format for price
---

AnsUtils = {};
AnsUtils.__index = AnsUtils;

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
    return {
        speciesID = tonumber(id), 
        name = name,
        level = tonumber(level), 
        breedQuality = tonumber(quality), 
        petType = type,
        maxHealth = tonumber(health), 
        power = tonumber(power), 
        speed = tonumber(speed),
        customName = nil
    };
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

function AnsUtils:GetTSMID(link)
    if (AnsUtils:IsBattlePetLink(link)) then
        local pet = AnsUtils:ParseBattlePetLink(link);
        return "p:"..pet.speciesID;
    else
        local _, id = strsplit(":", link);
        return "i:"..id;
    end
end