local Ans = select(2, ...);

local stats = Ans.Statistics;

local MAX_DAYS_TO_TRACK = 7;

ANS_AUCTION_DATA = {};
AnsAuctionData = {};
AnsAuctionData.__index = AnsAuctionData;

local Utils = AnsCore.API.Utils;

local realmName = GetRealmName();

local regionIdToName = {
    "US",
    "KOREA",
    "EU",
    "TAIWAN",
    "CHINA"
};

-- BFA Special Bonus IDS:
-- 4783 - 4786 is the following: Warforged, Titanforged, ???, ???
-- 4798 - 4801 is the following: Normal+, Heroic, Mythic, Raidfinder
local ValidBonus = {4783,4784,4785,4786,4798,4799,4800,4801};

local region = regionIdToName[GetCurrentRegion()];

local keyToIndex = {
    ["recent"] = 1,
    ["3day"] = 2,
    ["market"] = 3,
    ["min"] = 4,
    ["sum"] = 5,
    ["count"] = 6,
    ["days"] = 7,
    ["updated"] = 8,
    ["dayoffset"] = 9
};

local ValidIDCache = {};

local hooked = false;

local petTipLines = {};

local tracker = {};

local function OnClear(tooltip)
    tooltip.ansDataTooltip = false;
end

local function IsSoulbound()
    local numlines = GameTooltip:NumLines();

    local i;
    for i = 1, numlines do
        local textObject = _G[GameTooltip:GetName().."TextLeft"..i];
        local text = strtrim(textObject and textObject:GetText() or "");

        if ((text == ITEM_BIND_ON_PICKUP and id < 4) or text == ITEM_SOULBOUND or text == ITEM_BIND_QUEST) then
            return true;
        elseif (text == ITEM_ACCOUNTBOUND or text == ITEM_BIND_TO_ACCOUNT or text == ITEM_BIND_TO_BNETACCOUNT or text == ITEM_BNETACCOUNTBOUND) then
            return true;
        end
    end

    return false;
end

local function InitPetLines(tooltip)
    if (not petTipLines[tooltip:GetName()]) then
        local l,r = tooltip:CreateFontString(tooltip:GetName().."Left", "ARTWORK", "GameFontHighlightSmall"), tooltip:CreateFontString(tooltip:GetName().."Right", "ARTWORK", "GameFontHighlightSmall");
        petTipLines[tooltip:GetName()] = {l, r, tooltip:GetHeight()};
        l:SetPoint("BOTTOMLEFT", tooltip, "BOTTOMLEFT", 12, 4);
        l:SetJustifyH("LEFT");
        r:SetPoint("BOTTOMRIGHT", tooltip, "BOTTOMRIGHT", -12, 4);
        r:SetJustifyH("RIGHT");
    end
end

local function HandlePetTip(tooltip)
    local l,r,height = unpack(petTipLines[tooltip:GetName()]);

    local txt = l:GetText();
    if (txt and txt:len() > 0) then
        tooltip:SetHeight(height + 64);
    else
        tooltip:SetHeight(height + 16);
    end
end

local function ShowDataPetFloat(tooltip, pet)
    InitPetLines(tooltip);

    local l,r,height = unpack(petTipLines[tooltip:GetName()]);

    local plevel = pet.level;

    if (plevel < 25) then
        plevel = 1;
    end

    local pid = "p:"..pet.speciesID..":"..plevel;

    local realmRecent = AnsAuctionData.GetRealmValue(pid, "recent");
    local realmMin = AnsAuctionData.GetRealmValue(pid, "min");
    local realm3Day = AnsAuctionData.GetRealmValue(pid, "3day");
    local realmMarket = AnsAuctionData.GetRealmValue(pid, "market");

    local regionRecent = AnsAuctionData.GetRegionValue(pid, "recent");
    local regionMin = AnsAuctionData.GetRegionValue(pid, "min");
    local region3Day = AnsAuctionData.GetRegionValue(pid, "3day");
    local regionMarket = AnsAuctionData.GetRegionValue(pid, "market");

    local ltxt = "";
    local rtxt = "";

    if (ANS_GLOBAL_SETTINGS.tooltipRealmRecent and realmRecent > 0) then
        p = Utils:PriceToString(realmRecent);

        ltxt = ltxt.."|cFF00BBFFAnS Recent\r\n";
        rtxt = rtxt..p.."\r\n";
    end
    if (ANS_GLOBAL_SETTINGS.tooltipRealmMarket and realmMarket > 0) then
        p = Utils:PriceToString(realmMarket);

        ltxt = ltxt.."|cFF00BBFFAnS Market\r\n";
        rtxt = rtxt..p.."\r\n";
    end
    if (ANS_GLOBAL_SETTINGS.tooltipRealmMin and realmMin > 0) then
        p = Utils:PriceToString(realmMin);

        ltxt = ltxt.."|cFF00BBFFAnS Min\r\n";
        rtxt = rtxt..p.."\r\n";
    end
    if (ANS_GLOBAL_SETTINGS.tooltipRealm3Day and realm3Day > 0) then
        p = Utils:PriceToString(realm3Day);

        ltxt = ltxt.."|cFF00BBFFAnS 3-Day\r\n";
        rtxt = rtxt..p.."\r\n";
    end
    if (ANS_GLOBAL_SETTINGS.tooltipRegionRecent and regionRecent > 0) then
        p = Utils:PriceToString(regionRecent);

        ltxt = ltxt.."|cFF00BBFFAnS Region Recent\r\n";
        rtxt = rtxt..p.."\r\n";
    end
    if (ANS_GLOBAL_SETTINGS.tooltipRegionMarket and regionMarket > 0) then
        p = Utils:PriceToString(regionMarket);

        ltxt = ltxt.."|cFF00BBFFAnS Region Market\r\n";
        rtxt = rtxt..p.."\r\n";
    end
    if (ANS_GLOBAL_SETTINGS.tooltipRegionMin and regionMin > 0) then
        p = Utils:PriceToString(regionMin);

        ltxt = ltxt.."|cFF00BBFFAnS Region Min\r\n";
        rtxt = rtxt..p.."\r\n";
    end
    if (ANS_GLOBAL_SETTINGS.tooltipRegion3Day and region3Day > 0) then
        p = Utils:PriceToString(region3Day);

        ltxt = ltxt.."|cFF00BBFFAnS Region 3-day\r\n";
        rtxt = rtxt..p.."\r\n";
    end

    if (ltxt:len() > 0) then
        l:Show();
        r:Show();
        l:SetText(ltxt);
        r:SetText(rtxt);
    else
        l:SetText("");
        r:SetText("");
        l:Hide();
        r:Hide();
    end
end

local function ShowData(tooltip)
    if (not tooltip.ansDataTooltip) then
        tooltip.ansDataTooltip = true;

        local name, link = tooltip:GetItem();
        if (link) then
            local realmRecent = AnsAuctionData.GetRealmValue(link, "recent");
            local realmMin = AnsAuctionData.GetRealmValue(link, "min");
            local realm3Day = AnsAuctionData.GetRealmValue(link, "3day");
            local realmMarket = AnsAuctionData.GetRealmValue(link, "market");

            local regionRecent = AnsAuctionData.GetRegionValue(link, "recent");
            local regionMin = AnsAuctionData.GetRegionValue(link, "min");
            local region3Day = AnsAuctionData.GetRegionValue(link, "3day");
            local regionMarket = AnsAuctionData.GetRegionValue(link, "market");

            if (ANS_GLOBAL_SETTINGS.tooltipRealmRecent and realmRecent > 0) then
                p = Utils:PriceToString(realmRecent);

                tooltip:AddDoubleLine("AnS Recent", p, 0, 0.75, 1, 1, 1, 1);
            end
            if (ANS_GLOBAL_SETTINGS.tooltipRealmMarket and realmMarket > 0) then
                p = Utils:PriceToString(realmMarket);

                tooltip:AddDoubleLine("AnS Market", p, 0, 0.75, 1, 1, 1, 1);
            end
            if (ANS_GLOBAL_SETTINGS.tooltipRealmMin and realmMin > 0) then
                p = Utils:PriceToString(realmMin);

                tooltip:AddDoubleLine("AnS Min", p, 0, 0.75, 1, 1, 1, 1);
            end
            if (ANS_GLOBAL_SETTINGS.tooltipRealm3Day and realm3Day > 0) then
                p = Utils:PriceToString(realm3Day);

                tooltip:AddDoubleLine("AnS 3-Day", p, 0, 0.75, 1, 1, 1, 1);
            end
            if (ANS_GLOBAL_SETTINGS.tooltipRegionRecent and regionRecent > 0) then
                p = Utils:PriceToString(regionRecent);

                tooltip:AddDoubleLine("AnS Region Recent", p, 0, 0.75, 1, 1, 1, 1);
            end
            if (ANS_GLOBAL_SETTINGS.tooltipRegionMarket and regionMarket > 0) then
                p = Utils:PriceToString(regionMarket);

                tooltip:AddDoubleLine("AnS Region Market", p, 0, 0.75, 1, 1, 1, 1);
            end
            if (ANS_GLOBAL_SETTINGS.tooltipRegionMin and regionMin > 0) then
                p = Utils:PriceToString(regionMin);

                tooltip:AddDoubleLine("AnS Region Min", p, 0, 0.75, 1, 1, 1, 1);
            end
            if (ANS_GLOBAL_SETTINGS.tooltipRegion3Day and region3Day > 0) then
                p = Utils:PriceToString(region3Day);

                tooltip:AddDoubleLine("AnS Region 3-Day", p, 0, 0.75, 1, 1, 1, 1);
            end
        end
    end
end

local function HookTooltip() 
    if (not hooked) then
        hooked = true;

        GameTooltip:HookScript("OnTooltipSetItem", function(...) ShowData(GameTooltip); end);
        GameTooltip:HookScript("OnTooltipCleared", function(...) OnClear(GameTooltip); end);
        ItemRefTooltip:HookScript("OnTooltipSetItem", function(...) ShowData(ItemRefTooltip); end);
        ItemRefTooltip:HookScript("OnTooltipCleared", function(...) OnClear(ItemRefTooltip); end);

		if (BattlePetToolTip_Show and BattlePetTooltipTemplate_SetBattlePet and FloatingBattlePet_Show) then
			hooksecurefunc(_G, "BattlePetTooltipTemplate_SetBattlePet", ShowDataPetFloat);
			hooksecurefunc(_G, "BattlePetToolTip_Show", function() HandlePetTip(BattlePetTooltip) end);
			hooksecurefunc(_G, "FloatingBattlePet_Show", function() HandlePetTip(FloatingBattlePetTooltip) end);
		end
    end
end

function AnsAuctionData:OnLoad()
    self:Unpack();
    HookTooltip();
end

function AnsAuctionData:Unpack()
    local r = ANS_AUCTION_DATA[realmName];
    if (r) then
        for k,v in pairs(r) do
            if (type(v) == "string") then
                r[k] = {strsplit(",", v)};
                for i, s in ipairs(r[k]) do
                    r[k][i] = tonumber(s); 
                end
            end
        end
    end
    r = ANS_AUCTION_DATA[region];
    if (r) then
        for k,v in pairs(r) do
            if (type(v) == "string") then
                r[k] = {strsplit("," , v)};
                for i, s in ipairs(r[k]) do
                    r[k][i] = tonumber(s); 
                end
            end
        end
    end
end

function AnsAuctionData:GetValidID(tsm) 
    if (ValidIDCache[tsm]) then
        return ValidIDCache[tsm];
    end

    local t, id, plvl = strsplit(":", tsm);

    if (t == "p") then
        if (plvl) then
            local pn = tonumber(plvl);

            if (pn < 25) then
                pn = 1;
            end

            ValidIDCache[tsm] = "p:"..id..":"..pn;
            return ValidIDCache[tsm];
        else
            ValidIDCache[tsm] = "p:"..id..":1";
            return ValidIDCache[tsm];
        end
    end

    local tmp = Utils:GetTable();

    local c = 1;
    for n in string.gmatch(tsm, "%d+") do
        -- ignore the first number as that is the item id
        if (c ~= 1) then
            local nn = tonumber(n);
            if (Utils:InTable(ValidBonus, nn) or (nn >= 1472 and nn <= 1672)) then
                tinsert(tmp, nn);
            end
        end
        c = c + 1;
    end

    if (#tmp > 0) then
        table.sort(tmp, function(x,y) return x < y end);
        local bonus = table.concat(tmp, ":");
        Utils:ReleaseTable(tmp);

        ValidIDCache[tsm] = t..":"..id..":"..bonus;
        return ValidIDCache[tsm];
    end

    Utils:ReleaseTable(tmp);
    ValidIDCache[tsm] = t..":"..id;
    return ValidIDCache[tsm];
end

function AnsAuctionData:HasData()
    if (not ANS_AUCTION_DATA[realmName] and not ANS_AUCTION_DATA[region]) then
        return false;
    end

    return true;
end

function AnsAuctionData:ResetRealm()
    ANS_AUCTION_DATA[realmName] = {};
end

function AnsAuctionData.GetRealmValue(link, key)
    if (not ANS_AUCTION_DATA[realmName]) then
        return 0;
    end

    local tsmId = Utils:GetTSMID(link);

    local vid = AnsAuctionData:GetValidID(tsmId);

    local kindex = keyToIndex[key];

    if (kindex) then
        local r = ANS_AUCTION_DATA[realmName];
        if (r and r[vid]) then
            local data = nil;
            data = r[vid][kindex];
            return data or 0;
        end
    end

    return 0;
end

function AnsAuctionData.GetValue(id, key)
    local kindex = keyToIndex[key];
    if (kindex) then
        local r = ANS_AUCTION_DATA[realmName];
        if (r and r[id]) then
            local data = nil;
            data = r[id][kindex];
            return data or 0;
        end
    end
    return 0;
end

function AnsAuctionData.SetValue(id, min, avg, sum, count)
    local r = ANS_AUCTION_DATA[realmName];
    if (not r) then
        r = {};
        ANS_AUCTION_DATA[realmName] = r;
    end

    if (r[id]) then
        r[id][1] = avg;
        r[id][4] = min;
        r[id][5] = sum;
        r[id][6] = count;

        local offset = r[id][9];

        -- handle in case this was a previous entry
        -- before these changes
        if (not offset) then
            offset = 1;
            r[id][9] = 1;
        end

        local dwnow = date("*t").wday;

        -- handle in case this was a previous entry
        -- before these changes
        if (not r[id][8]) then
            r[id][8] = dwnow;
        end

        if (dwnow ~= r[id][8]) then
            offset = offset + 1;
            if (offset > MAX_DAYS_TO_TRACK) then
                offset = 1;
            end
            r[id][9] = offset;
            r[id][8] = dwnow;
        end

        local days = r[id][7];

        -- handle in case this was a previous entry
        -- before these changes
        if (not days) then
            days = {};
            r[id][7] = days;

            for i = 1, MAX_DAYS_TO_TRACK do
                tinsert(days, avg);
            end
        end
        
        days[offset] = avg;

        local market = stats:RoundToInt(stats:Sum(days) / #days);
        r[id][3] = market;

        -- handle wrapping
        -- since days are wrapped 
        -- we wrap in reverse
        local prevDay = offset - 1;
        if (prevDay == 0) then
            prevDay = MAX_DAYS_TO_TRACK;
        end
        local twoDaysAgo = offset - 2;
        if (twoDaysAgo < 0) then
            twoDaysAgo = MAX_DAYS_TO_TRACK - 1;
        elseif (twoDaysAgo == 0) then
            twoDaysAgo = MAX_DAYS_TO_TRACK;
        end

        local threeDayAvg = stats:RoundToInt((days[offset] + days[prevDay] + days[twoDaysAgo]) / 3);
        r[id][2] = threeDayAvg;
    else
        local days = {};
        for i = 1, MAX_DAYS_TO_TRACK do
            tinsert(days, avg);
        end
        r[id] = {avg,avg,avg,min,sum,count,days,date("*t").wday,1};
    end
end

function AnsAuctionData.GetRegionValue(link, key)
    if (not ANS_AUCTION_DATA[region]) then
        return 0;
    end

    local tsmId = Utils:GetTSMID(link);
    local vid = AnsAuctionData:GetValidID(tsmId);
    local kindex = keyToIndex[key];

    if (kindex) then
        local r = ANS_AUCTION_DATA[region];

        if (r and r[vid]) then
            local data = nil;
            data = r[vid][kindex];
            return data or 0;
        end
    end

    return 0;
end


-- Tracking processing
local processingIndex = 1;
local keys = {};
local totalItems = 0;

function AnsAuctionData:StartTracking() 
	wipe(tracker);
    wipe(keys);
    processingIndex = 1;
    totalItems = 0;
end

function AnsAuctionData:StopTracking()
    wipe(tracker);
    wipe(keys);
    processingIndex = 1;
    totalItems = 0;
end

function AnsAuctionData:AddTracking(tsmId, copper)
    tsmId = AnsAuctionData:GetValidID(tsmId);
	if (tracker[tsmId]) then
		local track = tracker[tsmId];
		tinsert(track, copper);
	else
		local track = {};
		tinsert(track, copper);
        tracker[tsmId] = track;
        tinsert(keys, tsmId);
        totalItems = #keys;
	end
end

function AnsAuctionData:TotalItemsToProcess()
	return totalItems;
end

function AnsAuctionData:CurrentProcessingStep() 
	return processingIndex;
end

function AnsAuctionData:IsProcessingComplete()
	return processingIndex > totalItems;
end

function AnsAuctionData:ProcessNext()
	if (processingIndex <= totalItems) then
        local id = keys[processingIndex];
        local values = tracker[id];
        if (id and values) then
            local prevSum = AnsAuctionData.GetValue(id, "sum");
            local prevCount = AnsAuctionData.GetValue(id, "count");

            local mina, avg, sum, count = stats:Calculate(values, prevSum, prevCount);

            AnsAuctionData.SetValue(id, mina, avg, sum, count);
        end

		processingIndex = processingIndex + 1;
	end
end