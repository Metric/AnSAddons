local Ans = select(2, ...);
local Utils = Ans.Object.Register("Utils");
local TempTable = Ans.TempTable;
local Config = Ans.Config;
local TooltipScanner = Ans.TooltipScanner;

local BASE93_CHRS = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ !?\"'`^#$%@&*+=/.:;|\\_<>[]{}()~";
function Utils.DecodeBase93(s)
    local result = 0;
    local len = #BASE93_CHRS;
    local index = 0;
    
    local ss = strsplit("-", s);
    local offset = #ss;

    while (offset > 0) do
        local c = ss:sub(offset,offset);
        if (c == "-") then
            break;
        end
        local pow = math.pow(len, index);
        local ind = string.find(BASE93_CHRS, c, 1, true);
        
        result = result + pow * (ind - 1); --ind must be zero based

        offset = offset - 1;
        index = index + 1;
    end

    return result, s:sub(index+2);
end


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
local BONUS_ID_CACHE = TempTable:Acquire();
local BONUS_ID_NUMS_CACHE = {};

--- Standard Utils ---

function Utils.IsRetail()
    local v = GetBuildInfo();
    local f,m,p = v:match("(%d+)%.(%d+)%.(%d+)");
    local n = tonumber(f);
    local nm = tonumber(m);

    return n > 8 or (n == 8 and nm >= 3);
end

function Utils.IsClassic()
    local v = GetBuildInfo();
    local f,m,p = v:match("(%d+)%.(%d+)%.(%d+)");
    local n = tonumber(f);

    return n == 1;
end

function Utils.IsClassicEra()
    local v = GetBuildInfo();
    local f,m,p = v:match("(%d+)%.(%d+)%.(%d+)");
    local n = tonumber(f);

    return n >= 1 and n <= 8 and not Utils.IsRetail();
end

function Utils.IsTBC()
    local v = GetBuildInfo();
    local f,m,p = v:match("(%d+)%.(%d+)%.(%d+)");
    local n = tonumber(f);

    return n == 2;
end

function Utils.IsExpansion()
    local v = GetBuildInfo();
    local f,m,p = v:match("(%d+)%.(%d+)%.(%d+)");
    local n = tonumber(f);

    return n >= 2;
end

function Utils.IsWrath()
    local v = GetBuildInfo();
    local f,m,p = v:match("(%d+)%.(%d+)%.(%d+)");
    local n = tonumber(f);
    return n == 3;
end

function Utils.IsCata()
    local v = GetBuildInfo();
    local f,m,p = v:match("(%d+)%.(%d+)%.(%d+)");
    local n = tonumber(f);
    return n == 4;
end

function Utils.IsMists()
    local v = GetBuildInfo();
    local f,m,p = v:match("(%d+)%.(%d+)%.(%d+)");
    local n = tonumber(f);
    return n == 5;
end

function Utils.IsWarlords()
    local v = GetBuildInfo();
    local f,m,p = v:match("(%d+)%.(%d+)%.(%d+)");
    local n = tonumber(f);
    return n == 6;
end

function Utils.IsLegion()
    local v = GetBuildInfo();
    local f,m,p = v:match("(%d+)%.(%d+)%.(%d+)");
    local n = tonumber(f);
    return n == 7;
end

function Utils.IsBFA()
    local v = GetBuildInfo();
    local f,m,p = v:match("(%d+)%.(%d+)%.(%d+)");
    local n = tonumber(f);
    return n == 8;
end

function Utils.IsShadow()
    local v = GetBuildInfo();
    local f,m,p = v:match("(%d+)%.(%d+)%.(%d+)");
    local n = tonumber(f);
    return n == 9;
end

function Utils.IsDragon()
    local v = GetBuildInfo();
    local f,m,p = v:match("(%d+)%.(%d+)%.(%d+)");
    local n = tonumber(f);
    return n == 10;
end

function Utils.ReagentBankAvailable()
    local v = GetBuildInfo();
    local f,m,p = v:match("(%d+)%.(%d+)%.(%d+)");
    local n = tonumber(f);
    return n >= 6;
end

function Utils.BattlePetsAvailable()
    local v = GetBuildInfo();
    local f,m,p = v:match("(%d+)%.(%d+)%.(%d+)");
    local n = tonumber(f);
    return n >= 5;
end

function Utils.GlyphsAvailable()
    local v = GetBuildInfo();
    local f,m,p = v:match("(%d+)%.(%d+)%.(%d+)");
    local n = tonumber(f);
    return n >= 3;
end

function Utils.GemsAvailable()
    local v = GetBuildInfo();
    local f,m,p = v:match("(%d+)%.(%d+)%.(%d+)");
    local n = tonumber(f);
    return n >= 2;
end

function Utils.GSC(val)
    -- prevent nil exception 
    if (not val) then
        val = 0;
    end

    local g = val / (COPPER_PER_SILVER * SILVER_PER_GOLD);

     -- mathmatically speaking this is equal to floor((val - (g * COPPER_PER_SILVER * SILVER_PER_GOLD)) / COPPER_PER_SILVER)
    local s = mod(val / COPPER_PER_SILVER, COPPER_PER_SILVER);
    local c = mod(val, COPPER_PER_SILVER);
  
    return math.floor(g), math.floor(s), math.floor(c);
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
    local formatted, k = amount, nil;
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
    -- prevent nil exception from happening
    if (not val) then
        val = 0;
    end

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

function Utils.ShowTooltip(f, link, quantity, anchor)
    if (not anchor) then
        anchor = "ANCHOR_RIGHT";
    end

    GameTooltip:SetOwner(f, anchor);
    if (Utils.IsBattlePetLink(link)) then
        Utils.ShowBattlePetTip(link);
    else
        GameTooltip:SetHyperlink(link, quantity or 1);
        GameTooltip:Show();
    end
end

function Utils.HideTooltip()
    GameTooltip:Hide();
	
    if (Utils.BattlePetsAvailable()) then
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
    if (not Utils.BattlePetsAvailable()) then
        return;
    end

	BattlePetToolTip_ShowLink(link);
end

function Utils.GetAddonVersion(name)
    if (not Utils.IsAddonInstalled(name)) then
        return "0","0";
    end

    local v = C_AddOns.GetAddOnMetadata(name, "Version");
    if (v) then
        local maj, min = string.match(v, "(%d+).(%d+)");
        return maj, min;
    end

    return "0","0";
end

function Utils.IsAddonInstalled(name)
    return select(2, C_AddOns.GetAddOnInfo(name)) and true or false;
end

function Utils.IsAddonEnabled(name)
    return C_AddOns.GetAddOnEnableState(UnitName("player"), name) == 2 and select(4, C_AddOns.GetAddOnInfo(name)) and true or false;
end

function Utils.ClearCache()
    LINK_CACHE:Release();
    LINK_CACHE = TempTable:Acquire();
    ID_CACHE:Release();
    ID_CACHE = TempTable:Acquire();
    BONUS_ID_CACHE:Release();
    BONUS_ID_CACHE = TempTable:Acquire();
    wipe(BONUS_ID_NUMS_CACHE);
end

function Utils.SortLowToHigh(x,y) 
    return x < y;
end

function Utils.ToWowItemString(itemString)
	local _, itemId, rand, extra = strsplit(":", itemString);
	local level = UnitLevel("player");
	local spec = not Utils.IsClassicEra() and GetSpecialization() or nil;
	spec = spec and GetSpecializationInfo(spec) or "";
	local extraPart = extra and strmatch(itemString, "i:[0-9]+:[0-9%-]*:(.+)") or "";
	return "item:"..itemId.."::::::"..(rand or "").."::"..level..":"..spec..":::"..extraPart..":::";
end

function Utils.GetLink(itemString,ignoreDetails)
	if (not itemString) then return nil; end
	local link = nil
    local itemStringType, speciesId, level, quality, health, power, speed, petId = strsplit(":", itemString)
	if itemStringType == "p" then
		local name, icon, type = C_PetJournal.GetPetInfoBySpeciesID(tonumber(speciesId));
        local fullItemString = strjoin(":", speciesId, level or "", quality or "", health or "", power or "", speed or "", petId or "")
        
        if (quality) then
            quality = tonumber(quality) or 1
            if (quality == 0) then
                quality = 1;
            end
        else
            quality = 1;
        end

		local qualityColor = ITEM_QUALITY_COLORS[quality] and ITEM_QUALITY_COLORS[quality].hex or "|cffff0000";
		link = qualityColor.."|Hbattlepet:"..fullItemString.."|h["..name.."]|h|r"
    else
        if (ignoreDetails) then
            return "|H"..Utils.ToWowItemString(itemString).."|h[UNKNOWN]|h|r";
        end

        local name, _, quality = GetItemInfo(tonumber(speciesId));
        
        if (not name) then
            -- not in cache
            return nil;
        end

        if (quality) then
            quality = tonumber(quality) or 1
            if (quality == 0) then
                quality = 1;
            end
        else
            quality = 1;
        end

		local qualityColor = ITEM_QUALITY_COLORS[quality] and ITEM_QUALITY_COLORS[quality].hex or "|cffff0000"
		link = qualityColor.."|H"..Utils.ToWowItemString(itemString).."|h["..(name or "UNKNOWN").."]|h|r"
	end
	return link
end

function Utils.BonusID(id,mods,tbl,isSocketBonus)
    local socket = false;

    if (tbl) then
        wipe(tbl);
    end

    if (not id or type(id) == "number") then
        return id;
    end
    if (BONUS_ID_CACHE[id] and not mods) then
        local nums = BONUS_ID_NUMS_CACHE[id];
        if (tbl and nums) then
            for i,v in ipairs(nums) do
                tbl[v] = 1;
                if (isSocketBonus and isSocketBonus(v)) then
                    socket = true;
                end
            end
        end
        return BONUS_ID_CACHE[id], socket;
    end

    local tmp = TempTable:Acquire(strsplit(":", id));
    if (tmp[1] ~= "i") then
        BONUS_ID_CACHE[id] = id;
        tmp:Release();
        return id;
    end

    local bonusCount = tmp[4];
    if (not bonusCount and not mods) then
        BONUS_ID_CACHE[id] = tmp[1]..":"..tmp[2];
        tmp:Release();
        return BONUS_ID_CACHE[id];
    end

    bonusCount = bonusCount and tonumber(bonusCount) or 0;
    if ((not bonusCount or bonusCount == 0) and not mods) then
        BONUS_ID_CACHE[id] = tmp[1]..":"..tmp[2];
        tmp:Release();
        return BONUS_ID_CACHE[id];
    end

    local extra = "";
    if (bonusCount and bonusCount > 0) then
        local btemp = BONUS_ID_NUMS_CACHE[id] or {};
        wipe(btemp);

        for i = 1, bonusCount do
            local num = tmp[4+i];
            if (num) then
                num = tonumber(num) or 0;
                
                if (tbl) then
                    tbl[num] = 1;
                    if (isSocketBonus and isSocketBonus(num)) then
                        socket = true;
                    end
                end

                tinsert(btemp, num);
            end
        end

        table.sort(btemp, Utils.SortLowToHigh);

        extra = "::"..bonusCount..":"..strjoin(":", unpack(btemp));
        BONUS_ID_CACHE[id] = tmp[1]..":"..tmp[2]..extra;
        BONUS_ID_NUMS_CACHE[id] = btemp; 
    end

    if (not bonusCount) then
        bonusCount = 0;
    end

    local modifiers = "";

    if (mods) then
        local sep = ":";
        local sindex = 4 + bonusCount + 1;
        for i = sindex, #tmp do
            modifiers = modifiers..sep..tmp[i];
        end
    end

    extra = (modifiers ~= "" and extra == "") and "::" or extra;

    local fresult = tmp[1]..":"..tmp[2]..extra..modifiers; 
    tmp:Release();
    return fresult, socket;
end

function Utils.GetID(link)
    if (not link) then
        return link;
    end

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

        local extra = "";
        local modifiers = "";
        local modCount = 0;
        local modCountOffset = 0;

        if (bonusCount) then
            bonusCount = tonumber(bonusCount);

            if(bonusCount and bonusCount > 0) then
                local tempBonus = TempTable:Acquire();

                modCountOffset = bonusCount + 1;

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
            else
                modCountOffset = 1;
            end
        else
            modCountOffset = 1;
        end

        modCount = tbl[14 + modCountOffset];
        if (modCount) then
            modCount = tonumber(modCount);
            if (modCount and modCount > 0) then
                local tempMods = TempTable:Acquire();
                local offset = 14 + modCountOffset + 1;

                for i = 0, modCount - 1 do
                    local id = tbl[offset+(i * 2)];

                    -- skip 9 as that is just what level the characte was
                    -- when the item was generated via loot or crafting etc
                    -- we don't care about that one
                    if (id and id ~= "9") then
                        tinsert(tempMods, id);
                        tinsert(tempMods, tbl[offset+(i * 2)+1]);
                    end
                end

                modCount = math.floor(#tempMods / 2);
                modifiers = ":"..modCount..":"..strjoin(":", unpack(tempMods))

                tempMods:Release();
            end
        end

        tbl:Release();

        local fresult = "";
        if (modCount and modCount > 0) then
            fresult = "i:"..id..((extra == "" and modifiers ~= "") and "::" or extra)..modifiers;
        else
            fresult = "i:"..id..extra;
        end

        ID_CACHE[link] = fresult;
        return fresult;
    end
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
            str = string.gsub(str, s.."%%", perc.." *", 1);
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
        return g.."g"..(s2 or "")..s.."s"..(s3 or "")..c.."c", tonumber(g) * (COPPER_PER_SILVER * SILVER_PER_GOLD) + tonumber(s) * COPPER_PER_SILVER + tonumber(c);
    end

    g, s2, s = string.match(str, "(%d+)g(%s*)(%d+)s");

    if (g and s) then
        return g.."g"..(s2 or "")..s.."s", tonumber(g) * (COPPER_PER_SILVER * SILVER_PER_GOLD) + tonumber(s) * COPPER_PER_SILVER;
    end

    g, s2, c = string.match(str, "(%d+)g(%s*)(%d+)c");

    if (g and c) then
        return g.."g"..(s2 or "")..c.."c", tonumber(g) * (COPPER_PER_SILVER * SILVER_PER_GOLD) + tonumber(c);
    end

    s, s2, c = string.match(str, "(%d+)s(%s*)(%d+)c");

    if (s and c) then
        return s.."s"..(s2 or "")..c.."c", tonumber(s) * COPPER_PER_SILVER + tonumber(c);
    end

    c = string.match(str, "(%d+)c");

    if (c) then
        return c.."c", tonumber(c);
    end

    s = string.match(str, "(%d+)s");

    if (s) then
        return s.."s", tonumber(s) * COPPER_PER_SILVER;
    end

    g = string.match(str, "(%d+)g");

    if (g) then
        return g.."g", tonumber(g) * (COPPER_PER_SILVER * SILVER_PER_GOLD);
    end

    return nil, nil;
end

function Utils.IsBoP(bag, slot)
    return TooltipScanner:IsBoP(bag, slot);
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

function Utils.HookSecure(name, fn, context)
    hooksecurefunc(context or _G, name, fn);
end

function Utils.Hook(name, fn, context)
    local ctx = context or _G;
    local ctxfn = ctx[name];
    local tmpfn = function(...) fn(HOOK_CACHE[name], ...); end;

    HOOK_CACHE[name] = ctxfn;
    ctx[name] = tmpfn;
end

function Utils.Guid()
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
end