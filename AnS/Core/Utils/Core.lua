local Ans = select(2, ...);
local Utils = Ans.Object.Register("Utils");
local TempTable = Ans.TempTable;
local Config = Ans.Config;
local TooltipScanner = Ans.TooltipScanner;

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

local HOOK_CACHE = TempTable:Acquire();
local LINK_CACHE = TempTable:Acquire();
local PET_CACHE = TempTable:Acquire();
local ID_CACHE = TempTable:Acquire();

--- Standard Utils ---

function Utils.IsClassic()
    local v = GetBuildInfo();
    local f = v:match("%d");
    return f == "1" or f == "2" or f == "3";
end

function Utils.GSC(val) 
    local rv = math.floor(val);

    local g = math.floor (rv/10000);
  
    rv = rv - g*10000;
  
    local s = math.floor (rv/100);
  
    rv = rv - s*100;
  
    local c = rv;
  
    return g, s, c
end

function Utils.GetName(link)
    if (not link) then
        return "";
    end

    if (LINK_CACHE[link]) then
        return LINK_CACHE[link][4];
    end

    local tbl = { strsplit("%|", link) };
    LINK_CACHE[link] = tbl;
    return tbl[4];
end

function Utils.CollectGarbage()
    local preGC = collectgarbage("count")
    collectgarbage("collect")
    print("AnS - Collected " .. math.ceil((preGC-collectgarbage("count")) / 1024) .. " MB of garbage");
end

function Utils.FormatNumber(amount)
    local formatted = amount
    while true do  
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if (k==0) then
            break
        end
    end
    return formatted
end

function Utils.PriceToFormatted(prefix, val, negative)
    local color = "|cFFFFFFFF";

    if (negative) then
        color = "|cFFFF0000";
    end

    local gold, silver, copper = Utils.GSC(val);
    local st = "";

    if (gold ~= 0) then
        st = color..prefix..Utils.FormatNumber(""..gold).."|cFFD7BC45g ";
    end

    if (st ~= "") then
        st = st..color..format("%02i|cFF9C9B9Cs ", silver);
    elseif (silver ~= 0) then
        st = st..color..prefix..silver.."|cFF9C9B9Cs ";
    end

    if (st ~= "") then
        st = st..color..format("%02i|cFF9B502Fc", copper);
    elseif (copper ~= 0) then
        st = st..color..prefix..copper.."|cFF9B502Fc";
    end

    if (st == "") then
        st = color.."0|cFF9B502Fc";
    end

    return st;
end

function Utils.PriceToString(val, override, noFormatting)
    if (Config.General().useCoinIcons and not override) then
        return GetMoneyString(val, true);
    end

    local gold, silver, copper = Utils.GSC(val);
    local st = "";

    if (noFormatting) then
        if (gold ~= 0) then
            st = gold.."g";
        end
        if (silver ~= 0) then
            st = st..silver.."s";
        end
        if (copper ~= 0) then
            st = st..copper.."c";
        end
        if (st == "") then
            st = "0c";
        end
        return st;
    end

    if (gold ~= 0) then
        st = "|cFFFFFFFF"..Utils.FormatNumber(""..gold).."|cFFD7BC45g ";
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

    if (st == "") then
        st = "|cFFFFFFFF0|cFF9B502Fc";
    end

    return st;
end

function Utils.IsBattlePetLink(link)
    if (link) then
        return string.find(link,"Hbattlepet:",1) ~= nil;
    else
        return false;
    end
end

function Utils.ParseBattlePetLink(link)
    local _, id, level, quality, health, power, speed, other = strsplit(":", link);
    local name, icon, type = C_PetJournal.GetPetInfoBySpeciesID(tonumber(id));

    PET_CACHE.speciesID = tonumber(id);
    PET_CACHE.name = name;
    PET_CACHE.level = tonumber(level);
    PET_CACHE.breedQuality = tonumber(quality);
    PET_CACHE.petType = type;
    PET_CACHE.maxHealth = tonumber(health);
    PET_CACHE.power = tonumber(power);
    PET_CACHE.speed = tonumber(speed);
    PET_CACHE.customName = nil;
    PET_CACHE.icon = icon;

    return PET_CACHE;
end

function Utils.ShowTooltip(f, link, quantity)
    GameTooltip:SetOwner(f, "ANCHOR_RIGHT");
    if (Utils.IsBattlePetLink(link)) then
        Utils.ShowBattlePetTip(link);
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

function Utils.ShowTooltipText(f, txt)
    GameTooltip:SetOwner(f, "ANCHOR_RIGHT");
    GameTooltip:ClearLines();
    GameTooltip:SetText(txt);
    GameTooltip:Show();
end

function Utils.ShowBattlePetTip(link)
	if BattlePetTooltip then
		local pet = Utils.ParseBattlePetLink(link);
		BattlePetTooltipTemplate_SetBattlePet(BattlePetTooltip, pet);
		BattlePetTooltip:SetSize(260,136);
		BattlePetTooltip:Show();
		BattlePetTooltip:ClearAllPoints();
		BattlePetTooltip:SetPoint(GameTooltip:GetPoint());
	end
end

function Utils.IsAddonInstalled(name)
    return select(2, GetAddOnInfo(name)) and true or false;
end

function Utils.IsAddonEnabled(name)
    return GetAddOnEnableState(UnitName("player"), name) == 2 and select(4, GetAddOnInfo(name)) and true or false;
end

function Utils.ClearCache()
    ID_CACHE:Release();
    ID_CACHE = TempTable:Acquire();
end

function Utils.SortLowToHigh(x,y) 
    return x < y;
end

function Utils.ToWowItemString(itemString)
	local _, itemId, rand, extra = strsplit(":", itemString);
	local level = UnitLevel("player");
	local spec = not Utils.IsClassic() and GetSpecialization() or nil;
	spec = spec and GetSpecializationInfo(spec) or "";
	local extraPart = extra and strmatch(itemString, "i:[0-9]+:[0-9%-]*:(.+)") or "";
	return "item:"..itemId.."::::::"..(rand or "").."::"..level..":"..spec..":::"..extraPart..":::";
end

function Utils.GetLink(itemString)
	if (not itemString) then return nil; end
	local link = nil
	local itemStringType, speciesId, level, quality, health, power, speed, petId = strsplit(":", itemString)
	if itemStringType == "p" then
		local name, icon, type = C_PetJournal.GetPetInfoBySpeciesID(tonumber(speciesId));
		local fullItemString = strjoin(":", speciesId, level or "", quality or "", health or "", power or "", speed or "", petId or "")
		quality = tonumber(quality) or 0
		local qualityColor = ITEM_QUALITY_COLORS[quality] and ITEM_QUALITY_COLORS[quality].hex or "|cffff0000"
		link = qualityColor.."|Hbattlepet:"..fullItemString.."|h["..name.."]|h|r"
	else
        local name, _, quality = GetItemInfo(tonumber(speciesId));
        
        if (not name) then
            -- not in cache
            return nil;
        end

		local qualityColor = ITEM_QUALITY_COLORS[quality] and ITEM_QUALITY_COLORS[quality].hex or "|cffff0000"
		link = qualityColor.."|H"..Utils.ToWowItemString(itemString).."|h["..(name or "UNKNOWN").."]|h|r"
	end
	return link
end

function Utils.GetID(link)
    if (ID_CACHE[link]) then
        return ID_CACHE[link];
    end

    if (Utils.IsBattlePetLink(link)) then
        local pet = Utils.ParseBattlePetLink(link);
        local fresult = "p:"..pet.speciesID..":"..pet.level..":"..pet.breedQuality;
        ID_CACHE[link] = fresult;
        return fresult;
    else
        if (type(link) == "number") then
            return "i:"..link;
        end

        if (string.find(link, "i:") or string.find(link, "p:")) then
            ID_CACHE[link] = link;
            return ID_CACHE[link];
        end

        local tbl = TempTable:Acquire(strsplit(":", link));
        local bonusCount = tbl[14];
        local id = tbl[2];
        local tempBonus = TempTable:Acquire();
        local extra = "";

        if (bonusCount) then
            bonusCount = tonumber(bonusCount);

            if(bonusCount and bonusCount > 0) then
                local i;
                for i = 1, bonusCount do
                    local num = tonumber(tbl[14+i]);

                    if (num) then
                        tinsert(tempBonus, num);
                    end
                end

                table.sort(tempBonus, Utils.SortLowToHigh);

                extra = "::"..bonusCount..":"..strjoin(":", unpack(tempBonus));

                tempBonus:Release();
            end
        end

        tbl:Release();

        if (id == nil) then
            return nil;
        end

        local fresult = "i:"..id..extra;
        ID_CACHE[link] = fresult;
        return fresult;
    end
end

function Utils.GetAddonVersion(name)
    local v = GetAddOnMetadata(name, "Version");
    if (v) then
        local maj, min = string.match(v, "(%d+).(%d+)");
        return maj, min;
    end

    return "0","0";
end

function Utils.ReplaceTabReturns(str)
    str = gsub(str, "[\r\n\t]+", "");
    return str;
end

function Utils.ReplaceOpShortHand(str)
    for k, v in pairs(OP_SIM_HAND) do
        str = gsub(str, k.."[^%(]", v);
    end
    for k, v in pairs(OP_SHORT_HAND) do
        str = gsub(str, k.."[^%(^e]", v);
    end
    return str;
end

function Utils.ReplaceMoneyShorthand(str)
    local s, v = Utils.MoneyStringToCopper(str);

    while (s and v) do
        str = gsub(str, s, v);
        s,v = Utils.MoneyStringToCopper(str);
    end
    return str;
end

function Utils.ReplaceShortHandPercent(str)
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

function Utils.MoneyStringToCopper(str)
    local g, s2, s, s3, c = string.match(str, "(%d+)g(%s*)(%d+)s(%s*)(%d+)c");

    if (g and s and c) then
        return g.."g"..(s2 or "")..s.."s"..(s3 or "")..c.."c", tonumber(g) * 10000 + tonumber(s) * 100 + tonumber(c);
    end

    g, s2, s = string.match(str, "(%d+)g(%s*)(%d+)s");

    if (g and s) then
        return g.."g"..(s2 or "")..s.."s", tonumber(g) * 10000 + tonumber(s) * 100;
    end

    g, s2, c = string.match(str, "(%d+)g(%s*)(%d+)c");

    if (g and c) then
        return g.."g"..(s2 or "")..c.."c", tonumber(g) * 10000 + tonumber(c);
    end

    s, s2, c = string.match(str, "(%d+)s(%s*)(%d+)c");

    if (s and c) then
        return s.."s"..(s2 or "")..c.."c", tonumber(s) * 100 + tonumber(c);
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

function Utils.IsSoulbound(bag, slot)
    return TooltipScanner:IsSoulbound(bag, slot);
end

function Utils.InTable(tbl, val)
    local t = #tbl;
    local i;
    for i = 1, t do
        if (tbl[i] == val) then
            return true;
        end
    end

    return false;
end

function Utils.HookSecure(name, fn)
    hooksecurefunc(_G, name, fn);
end

function Utils.Hook(name, fn)
    HOOK_CACHE[name] = _G[name];
    _G[name] = function(...) fn(HOOK_CACHE[name], ...); end;
end

function Utils.Guid()
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
end