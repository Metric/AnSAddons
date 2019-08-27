local Ans = select(2, ...);
local Utils = {};
Utils.__index = Utils;

Ans.Utils = Utils;

local MinimapIcon = {};
MinimapIcon.__index = MinimapIcon;

Ans.MinimapIcon = MinimapIcon;

local temporaryTables = {};
local TooltipScanner = nil;

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

function MinimapIcon:New(name, icon, clickFn, onMoveFn, angle, tooltipLines)
    local micon = {};
    setmetatable(micon, MinimapIcon);
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

function MinimapIcon:ShowTip()
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

function MinimapIcon:HideTip()
    GameTooltip:Hide();
end

function MinimapIcon:Reposition()
    if (self.onMoveFn) then
        self.onMoveFn(self.angle);
    end
    self.frame:SetPoint("TOPLEFT", "Minimap", "TOPLEFT", 52 - (80*cos(self.angle)), (80*sin(self.angle)) - 52);
end

function MinimapIcon:OnUpdate()
    if (self.isDragging) then
        local xpos, ypos = GetCursorPosition();
        local xmin, ymin = Minimap:GetLeft(), Minimap:GetBottom();

        xpos = xmin-xpos/UIParent:GetScale() + 72;
        ypos = ypos/UIParent:GetScale() - ymin - 72;

        self.angle = math.deg(math.atan2(ypos,xpos));
        self:Reposition();
    end
end

function MinimapIcon:OnDragStart()
    self.frame:LockHighlight();
    self.isDragging = true;
end

function MinimapIcon:OnDragStop()
    self.frame:UnlockHighlight();
    self.isDragging = false;
end

function MinimapIcon:Hide() 
    self.frame:Hide();
end

function MinimapIcon:Show()
    self.frame:Show();
end

--- Standard Utils ---

function Utils:GetTable()
    if (#temporaryTables > 0) then
        return tremove(temporaryTables);
    else
        return {};
    end
end

function Utils:ReleaseTable(t)
    wipe(t);
    tinsert(temporaryTables, t);
end

local BattlePetTempTable = Utils:GetTable();
local TSMID_CACHE = Utils:GetTable();
local TempBonusID = Utils:GetTable();

function Utils:GSC(val) 
    local rv = math.floor(val);

    local g = math.floor (rv/10000);
  
    rv = rv - g*10000;
  
    local s = math.floor (rv/100);
  
    rv = rv - s*100;
  
    local c = rv;
  
    return g, s, c
end

function Utils:FormatNumber(amount)
    local formatted = amount
    while true do  
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if (k==0) then
            break
        end
    end
    return formatted
end


function Utils:PriceToString(val)
    if (ANS_GLOBAL_SETTINGS.useCoinIcons) then
        return GetMoneyString(val, true);
    end

    local gold, silver, copper  = self:GSC(val);
    local st = "";

    if (gold ~= 0) then
        st = "|cFFFFFFFF"..self:FormatNumber(""..gold).."|cFFD7BC45g ";
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

function Utils:IsBattlePetLink(link)
    return string.find(link,"Hbattlepet:",1) ~= nil;
end

function Utils:ParseBattlePetLink(link)
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

function Utils:ShowTooltip(f, link, quantity)
    GameTooltip:SetOwner(f, "ANCHOR_RIGHT");
    if (self:IsBattlePetLink(link)) then
        self:ShowBattlePetTip(link);
    else
        GameTooltip:SetHyperlink(link, quantity or 1);
        GameTooltip:Show();
    end
end

function Utils.HideTooltip()
    GameTooltip:Hide();
	
	-- take into account wow classic not having this
	if BattlePetTooltip then
		BattlePetTooltip:Hide();
	end
end

function Utils:ShowBattlePetTip(link)
	if BattlePetTooltip then
		local pet = self:ParseBattlePetLink(link);
		BattlePetTooltipTemplate_SetBattlePet(BattlePetTooltip, pet);
		BattlePetTooltip:SetSize(260,136);
		BattlePetTooltip:Show();
		BattlePetTooltip:ClearAllPoints();
		BattlePetTooltip:SetPoint(GameTooltip:GetPoint());
	end
end

function Utils:IsAddonInstalled(name)
    return select(2, GetAddOnInfo(name)) and true or false;
end

function Utils:IsAddonEnabled(name)
    return GetAddOnEnableState(UnitName("player"), name) == 2 and select(4, GetAddOnInfo(name)) and true or false;
end

function Utils:ClearTSMIDCache()
    wipe(TSMID_CACHE);
end

function Utils.SortLowToHigh(x,y) 
    return x < y;
end

function Utils:GetTSMID(link)
    if (TSMID_CACHE[link]) then
        return TSMID_CACHE[link];
    end

    if (self:IsBattlePetLink(link)) then
        local pet = self:ParseBattlePetLink(link);
        local fresult = "p:"..pet.speciesID..":"..pet.level..":"..pet.breedQuality;
        TSMID_CACHE[link] = fresult;
        return fresult;
    else
        if (type(link) == "number") then
            return "i:"..link;
        end

        if (string.find(link, "i:") or string.find(link, "p:")) then
            TSMID_CACHE[link] = link;
            return TSMID_CACHE[link];
        end

        local tbl = { strsplit(":", link) };
        local bonusCount = tbl[14];
        local id = tbl[2];
        local extra = "";

        if (bonusCount) then
            bonusCount = tonumber(bonusCount);

            if(bonusCount and bonusCount > 0) then
                local i;
                for i = 1, bonusCount do
                    local num = tonumber(tbl[14+i]);

                    if (num) then
                        tinsert(TempBonusID, num);
                    end
                end

                table.sort(TempBonusID, Utils.SortLowToHigh);

                extra = "::"..bonusCount..":"..strjoin(":", unpack(TempBonusID));

                wipe(TempBonusID);
            end
        end

        local fresult = "i:"..id..extra;
        TSMID_CACHE[link] = fresult;
        return fresult;
    end
end

function Utils:GetAddonVersion(name)
    local v = GetAddOnMetadata(name, "Version");
    if (v) then
        local maj, min = string.match(v, "(%d+).(%d+)");
        return maj, min;
    end

    return "0","0";
end

function Utils:ReplaceOpShortHand(str)
    for k, v in pairs(OP_SIM_HAND) do
        str = gsub(str, k.."[^%(]", v);
    end
    for k, v in pairs(OP_SHORT_HAND) do
        str = gsub(str, k.."[^%(^e]", v);
    end
    return str;
end

function Utils:ReplaceMoneyShorthand(str)
    local s, v = self:MoneyStringToCopper(str);

    while (s and v) do
        str = gsub(str, s, v);
        s,v = self:MoneyStringToCopper(str);
    end
    return str;
end

function Utils:ReplaceShortHandPercent(str)
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

function Utils:MoneyStringToCopper(str)
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

function Utils:IsSoulbound(bag, slot)
    if (not TooltipScanner) then
        TooltipScanner = CreateFrame("GameTooltip", "AnsTooltipScanner", UIParent, "GameTooltipTemplate");
    end

    TooltipScanner:SetOwner(UIParent, "ANCHOR_NONE");
    TooltipScanner:ClearLines();
    if (bag == BANK_CONTAINER) then
        TooltipScanner:SetInventoryItem("player", bag, slot + BankButtonIDToInvSlotID(0));
    elseif (REAGENTBANK_CONTAINER and bag == REAGENTBANK_CONTAINER) then
        TooltipScanner:SetInventoryItem("player", bag, slot + ReagentBankButtonIDToInvSlotID(0));
    else
        TooltipScanner:SetBagItem(bag, slot);
    end
    local numlines = TooltipScanner:NumLines();
    
    if (numlines < 1) then
        return nil;
    end

    for id = 1, numlines do
        local textObject = _G["AnsTooltipScannerTextLeft"..id];
        local text = strtrim(textObject and textObject:GetText() or "");

        if ((text == ITEM_BIND_ON_PICKUP and id < 4) or text == ITEM_SOULBOUND or text == ITEM_BIND_QUEST) then
            return true;
        elseif (text == ITEM_ACCOUNTBOUND or text == ITEM_BIND_TO_ACCOUNT or text == ITEM_BIND_TO_BNETACCOUNT or text == ITEM_BNETACCOUNTBOUND) then
            return true;
        end
    end

    return false;
end

function Utils:InTable(tbl, val)
    local t = #tbl;
    local i;
    for i = 1, t do
        if (tbl[i] == val) then
            return true;
        end
    end

    return false;
end