---
-- Format for price
---

AnsUtils = {};
AnsUtils.__index = AnsUtils;

AnsMinimapIcon = {};
AnsMinimapIcon.__index = AnsMinimapIcon;

local TempTable = {};
local BattlePetTempTable = {};
local TSMID_CACHE = {};
local TempBonusID = {};

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

--- Minimap  Icon ---

function AnsMinimapIcon:New(name, icon, clickFn, onMoveFn, angle, tooltipLines)
    local micon = {};
    setmetatable(micon, AnsMinimapIcon);
    micon.clickFn = clickFn;
    micon.tooltipLines = tooltipLines;
    micon.name = name;
    micon.angle = angle or 45;
    micon.onMoveFn = onMoveFn;

    micon.frame = CreateFrame("BUTTON", name, Minimap, "AnsMiniButtonTemplate");
    micon.frame:SetScript("OnClick", micon.clickFn);
    micon.frame:SetScript("OnDragStart", function() micon:OnDragStart() end);
    micon.frame:SetScript("OnDragStop", function() micon:OnDragStop() end);
    micon.frame:SetScript("OnUpdate", function() micon:OnUpdate() end);
    micon.frame:SetScript("OnEnter", function() micon:ShowTip() end);
    micon.frame:SetScript("OnLeave", function() micon:HideTip() end);

    micon.isDragging = false;

    local ictex = _G[micon.frame:GetName().."Icon"];
    ictex:SetTexture(icon);

    micon:Reposition();

    return micon;
end

function AnsMinimapIcon:ShowTip()
    local tip = GameTooltip;
    if (self.tooltipLines and #self.tooltipLines > 0) then
        tip:ClearLines();
        tip:SetOwner(self.frame, "ANCHOR_LEFT");

        for i,v in ipairs(self.tooltipLines) do
            tip:AddLine(v, 1, 1, 1, false);
        end

        tip:Show();
    end
end

function AnsMinimapIcon:HideTip()
    GameTooltip:Hide();
end

function AnsMinimapIcon:Reposition()
    if (self.onMoveFn) then
        self.onMoveFn(self.angle);
    end
    self.frame:SetPoint("TOPLEFT", "Minimap", "TOPLEFT", 52 - (80*cos(self.angle)), (80*sin(self.angle)) - 52);
end

function AnsMinimapIcon:OnUpdate()
    if (self.isDragging) then
        local xpos, ypos = GetCursorPosition();
        local xmin, ymin = Minimap:GetLeft(), Minimap:GetBottom();

        xpos = xmin-xpos/UIParent:GetScale() + 72;
        ypos = ypos/UIParent:GetScale() - ymin - 72;

        self.angle = math.deg(math.atan2(ypos,xpos));
        self:Reposition();
    end
end

function AnsMinimapIcon:OnDragStart()
    self.frame:LockHighlight();
    self.isDragging = true;
end

function AnsMinimapIcon:OnDragStop()
    self.frame:UnlockHighlight();
    self.isDragging = false;
end

function AnsMinimapIcon:Hide() 
    self.frame:Hide();
end

function AnsMinimapIcon:Show()
    self.frame:Show();
end

--- Standard Utils ---

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
        st = "|cFFFFFFFF"..gold.."|cFFD7BC45g ";
    end

    if (st ~= "") then
        st = st.."|cFFFFFFFF"..format("%02i|cFF9C9B9Cs ", silver);
    elseif (silver ~= 0) then
        st = st.."|cFFFFFFFF"..silver.."|cFF9C9B9Cs ";
    end

    if (st ~= "") then
        st = st.."|cFFFFFFFF"..format("%02i|cFF9B502Fc", copper);
    elseif (copper ~= 0) then
        st = st.."|cFFFFFFFF"..copper.."|cFF9B502Fc";
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
        local fresult = "p:"..pet.speciesID..":"..pet.level..":"..pet.breedQuality;
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
                wipe(TempBonusID);

                local i;
                for i = 1, bonusCount do
                    local num = tonumber(tbl[14+i]);

                    if (num) then
                        tinsert(TempBonusID, num);
                    end
                end

                table.sort(TempBonusID, function(x,y) return x < y; end);

                extra = "::"..bonusCount..":"..strjoin(":", unpack(TempBonusID));
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
        str = gsub(str, k.."[^%(]", v);
    end
    for k, v in pairs(OP_SHORT_HAND) do
        str = gsub(str, k.."[^%(^e]", v);
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

function AnsUtils:ReplaceShortHandPercent(str)
    local s = string.match(str, "(%d+)%%");

    while (s) do
        local num = tonumber(s);

        if (num) then
            local perc = num / 100;
            str = string.gsub(str, s.."%%", perc.." *");
        else
            break;
        end

        s = string.match(str, "(%d+)%%");
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