local Core = select(2, ...);
local Utils = Ans.API.Utils;
local Scanner = Core.Scanner;
local Logger = Ans.API.Logger;
local Config = Ans.API.Config;
local Realms = Core.Realms;
local Parser = Core.Parser;
local TempTable = Ans.API.TempTable;

local stats = Core.Statistics;

local MAX_DAYS_TO_TRACK = 7;

ANS_AUCTION_DATA = {};
AnsAuctionData = {};
AnsAuctionData.__index = AnsAuctionData;

local Utils = Ans.API.Utils;

local realmName = GetRealmName();

local regionIdToName = {
    "US",
    "KR",
    "EU",
    "TW",
    "CH"
};

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

local keyToRegionIndex = {
    ["min"] = 5,
    ["market"] = 6,
};

local faction = "";

local ValidIDCache = {};

local CraftIDCache = {};

local hooked = false;

local petTipLines = {};

local tracker = {};

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

    --local regionRecent = AnsAuctionData.GetRegionValue(pid, "recent");
    local regionMin = AnsAuctionData.GetRegionValue(pid, "min");
    --local region3Day = AnsAuctionData.GetRegionValue(pid, "3day");
    local regionMarket = AnsAuctionData.GetRegionValue(pid, "market");
    --local regionSeen = AnsAuctionData.GetRegionValue(pid, "count");

    local ltxt = "";
    local rtxt = "";

    if (Config.General().tooltipRealmRecent and realmRecent > 0) then
        p = Utils.PriceToString(realmRecent);

        ltxt = ltxt.."|cFF00BBFFAnS Recent\r\n";
        rtxt = rtxt..p.."\r\n";
    end
    if (Config.General().tooltipRealmMarket and realmMarket > 0) then
        p = Utils.PriceToString(realmMarket);

        ltxt = ltxt.."|cFF00BBFFAnS Market\r\n";
        rtxt = rtxt..p.."\r\n";
    end
    if (Config.General().tooltipRealmMin and realmMin > 0) then
        p = Utils.PriceToString(realmMin);

        ltxt = ltxt.."|cFF00BBFFAnS Min\r\n";
        rtxt = rtxt..p.."\r\n";
    end
    if (Config.General().tooltipRealm3Day and realm3Day > 0) then
        p = Utils.PriceToString(realm3Day);

        ltxt = ltxt.."|cFF00BBFFAnS 3-Day\r\n";
        rtxt = rtxt..p.."\r\n";
    end
    
    --if (Config.General().tooltipRegionRecent and regionRecent > 0) then
    --    p = Utils.PriceToString(regionRecent);

    --    ltxt = ltxt.."|cFF00BBFFAnS Region Recent\r\n";
    --    rtxt = rtxt..p.."\r\n";
    --end
    if (Config.General().tooltipRegionMarket and regionMarket > 0) then
        p = Utils.PriceToString(regionMarket);

        ltxt = ltxt.."|cFF00BBFFAnS Region Market\r\n";
        rtxt = rtxt..p.."\r\n";
    end
    if (Config.General().tooltipRegionMin and regionMin > 0) then
        p = Utils.PriceToString(regionMin);

        ltxt = ltxt.."|cFF00BBFFAnS Region Min\r\n";
        rtxt = rtxt..p.."\r\n";
    end
    --if (Config.General().tooltipRegion3Day and region3Day > 0) then
    --    p = Utils.PriceToString(region3Day);

    --    ltxt = ltxt.."|cFF00BBFFAnS Region 3-Day\r\n";
    --    rtxt = rtxt..p.."\r\n";
    --end
    ---if (Config.General().tooltipRegionSeen and regionSeen > 0) then
    --    ltxt = ltxt.."|cFF00BBFFAnS Region Seen\r\n";
    --    rtxt = rtxt..regionSeen.."\r\n";
    --end

    if (Config.General().showId) then
        ltxt = ltxt.."|c4400BBFFPet ID\r\n";
        rtxt = rtxt..pid.."\r\n";
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

local function ShowData(tooltip, extra)
    local name, link = tooltip:GetItem();
    
    if (CraftIDCache[link]) then
        link = CraftIDCache[link];
    end

    link = extra or link;

    if (link) then
        local id = Utils.GetID(link);

        local realmRecent = AnsAuctionData.GetRealmValue(link, "recent");
        local realmMin = AnsAuctionData.GetRealmValue(link, "min");
        local realm3Day = AnsAuctionData.GetRealmValue(link, "3day");
        local realmMarket = AnsAuctionData.GetRealmValue(link, "market");

        --local regionRecent = AnsAuctionData.GetRegionValue(link, "recent");
        local regionMin = AnsAuctionData.GetRegionValue(link, "min");
        --local region3Day = AnsAuctionData.GetRegionValue(link, "3day");
        local regionMarket = AnsAuctionData.GetRegionValue(link, "market");
        --local regionSeen = AnsAuctionData.GetRegionValue(link, "count");

        if (Config.General().tooltipRealmRecent and realmRecent > 0) then
            p = Utils.PriceToString(realmRecent);
            tooltip:AddDoubleLine("AnS Recent", p, 0, 0.75, 1, 1, 1, 1);
        end
        if (Config.General().tooltipRealmMarket and realmMarket > 0) then
            p = Utils.PriceToString(realmMarket);
            tooltip:AddDoubleLine("AnS Market", p, 0, 0.75, 1, 1, 1, 1);
        end
        if (Config.General().tooltipRealmMin and realmMin > 0) then
            p = Utils.PriceToString(realmMin);
            tooltip:AddDoubleLine("AnS Min", p, 0, 0.75, 1, 1, 1, 1);
        end
        if (Config.General().tooltipRealm3Day and realm3Day > 0) then
            p = Utils.PriceToString(realm3Day);
            tooltip:AddDoubleLine("AnS 3-Day", p, 0, 0.75, 1, 1, 1, 1);
        end
        --if (Config.General().tooltipRegionRecent and regionRecent > 0) then
        --    p = Utils.PriceToString(regionRecent);
        --    tooltip:AddDoubleLine("AnS Region Recent", p, 0, 0.75, 1, 1, 1, 1);
        --end
        if (Config.General().tooltipRegionMarket and regionMarket > 0) then
            p = Utils.PriceToString(regionMarket);
            tooltip:AddDoubleLine("AnS Region Market", p, 0, 0.75, 1, 1, 1, 1);
        end
        if (Config.General().tooltipRegionMin and regionMin > 0) then
            p = Utils.PriceToString(regionMin);
            tooltip:AddDoubleLine("AnS Region Min", p, 0, 0.75, 1, 1, 1, 1);
        end
        --if (Config.General().tooltipRegion3Day and region3Day > 0) then
        --    p = Utils.PriceToString(region3Day);
        --    tooltip:AddDoubleLine("AnS Region 3-Day", p, 0, 0.75, 1, 1, 1, 1);
        --end
        --if (Config.General().tooltipRegionSeen and regionSeen > 0) then
        --    tooltip:AddDoubleLine("AnS Region Seen", regionSeen, 0, 0.75, 1, 1, 1, 1);
        --end

        if (Config.General().showId) then
            if (not id or id == "" or id == "i:" or id == "i") then
                return;
            end

            tooltip:AddDoubleLine("Item ID", id, 0, 0.75, 1, 1, 1, 1);
        end
    end
end

local function CaptureLink(link)
    if (link) then
        if (not CraftIDCache[link]) then
            local _, id = strsplit(":", link);
            id = tonumber(id);
            CraftIDCache[link] = id;
        end 
    end
end

local function HookTooltip() 
    if (not hooked) then
        hooked = true;

        GameTooltip:HookScript("OnTooltipSetItem", ShowData);
        ItemRefTooltip:HookScript("OnTooltipSetItem", ShowData);

		if (BattlePetToolTip_Show and BattlePetTooltipTemplate_SetBattlePet and FloatingBattlePet_Show) then
			hooksecurefunc(_G, "BattlePetTooltipTemplate_SetBattlePet", ShowDataPetFloat);
			hooksecurefunc(_G, "BattlePetToolTip_Show", function() HandlePetTip(BattlePetTooltip) end);
            hooksecurefunc(_G, "FloatingBattlePet_Show", function() HandlePetTip(FloatingBattlePetTooltip) end);
            hooksecurefunc(GameTooltip, "SetRecipeReagentItem", 
                function(self, recipeID, reagentIndex) 
                    ShowData(self, C_TradeSkillUI.GetRecipeReagentItemLink(recipeID, reagentIndex));
                end);
            hooksecurefunc(GameTooltip, "SetRecipeResultItem", 
                function(self, recipeID)
                    CaptureLink(C_TradeSkillUI.GetRecipeItemLink(recipeID));
                end);
		end
    end
end

function AnsAuctionData:OnLoad(frame)
    HookTooltip();

    self.frame = frame;

    frame:RegisterEvent("AUCTION_HOUSE_SHOW");
    frame:RegisterEvent("AUCTION_HOUSE_CLOSED");

    if (Utils.IsClassic()) then
        frame:RegisterEvent("AUCTION_ITEM_LIST_UPDATE");
    end

    if (Realms.F) then
        Realms.F(region, region.."-"..realmName);
        Realms.F = nil;
    end
end

function AnsAuctionData:OnUpdate()
    Scanner:OnUpdate();
end

function AnsAuctionData:EventHandler(frame, event, ...)
    Scanner:EventHandler(frame, event, ...);
end

function AnsAuctionData:GetValidID(tsm) 
    if (ValidIDCache[tsm]) then
        return ValidIDCache[tsm];
    end

    local t, id, plvl, quality = strsplit(":", tsm);

    if (t == "p") then
        if (plvl and quality) then
            local pn = tonumber(plvl);

            if (pn < 25) then
                pn = 1;
            end

            ValidIDCache[tsm] = "p:"..id..":"..pn..":"..quality;
            return ValidIDCache[tsm];
        elseif (plvl) then
            local pn = tonumber(plvl);

            if (pn < 25) then
                pn = 1;
            end

            ValidIDCache[tsm] = "p:"..id..":"..pn;
            return ValidIDCache[tsm];
        else
            ValidIDCache[tsm] = "p:"..id;
            return ValidIDCache[tsm];
        end
    end

    ValidIDCache[tsm] = Utils.BonusID(tsm, true);
    return ValidIDCache[tsm];
end

function AnsAuctionData:CheckFaction() 
    if (Utils.IsClassic()) then
        faction = UnitFactionGroup("player");
        if (not faction) then
            faction = "";
        else
            faction = "-"..faction;
        end
    end
end

function AnsAuctionData:GetRawData(localOnly)
    self:CheckFaction();

    local r = nil;
    if (not localOnly) then
        r = Realms[region.."-"..realmName];
    end
    if (not r) then
        r = ANS_AUCTION_DATA[region.."-"..realmName..faction];
        if (not r) then
            r = ANS_AUCTION_DATA[realmName];
            if (r) then
                ANS_AUCTION_DATA[region..'-'..realmName..faction] = r;
                ANS_AUCTION_DATA[realmName] = nil;
            end
        end
    end
    return r;
end

function AnsAuctionData:HasData()
    self:CheckFaction();

    if (not ANS_AUCTION_DATA[region.."-"..realmName..faction] 
        and not ANS_AUCTION_DATA[realmName] and not Realms[region.."-"..realmName]) then
        return false;
    end

    return true;
end

function AnsAuctionData:ResetRealm()
    self:CheckFaction();

    if (ANS_AUCTION_DATA[realmName]) then
        ANS_AUCTION_DATA[realmName] = nil;
    end

    ANS_AUCTION_DATA[region.."-"..realmName..faction] = {};
end

function AnsAuctionData.GetRegionValue(link, key)
    if (not link) then
        return 0;
    end

    if (not AnsAuctionData:HasData()) then
        return 0;
    end

    local tsmId = Utils.GetID(link);

    if (not tsmId) then
        return 0;
    end

    local vid = AnsAuctionData:GetValidID(tsmId);
    local fid = "final:"..vid;
    local kindex = keyToRegionIndex[key];

    if (kindex) then
        local r = AnsAuctionData:GetRawData();
        local cid = fid;

        if (Utils.IsClassic()) then
            cid = vid;
        end

        if (r and r[cid]) then
            local data = r[cid];
            data = data and data[kindex] or nil;
            return data or 0;
        else
            local _,base = strsplit(":", vid);
            local bid = _..":"..base;
            if (r and r[bid]) then
				local data = nil;
                local tmp = TempTable:Acquire(strsplit(",", r[bid]));
                for i,v in ipairs(tmp) do
                    if (v == vid) then
                        local value = tmp[i+1];
                        if (value) then
                            data = value;
                            r[fid] = {}
                            for i = 1, 6 do
                                local n, d = Utils.DecodeBase93(data);
                                tinsert(r[fid], n * 100);
                                data = d;
                            end
                            data = r[fid];
                        end
                        break;
                    end
                end
				tmp:Release();
                data = data and data[kindex] or nil;
                return data or 0;
            end 
        end
    end

    return 0;
end

function AnsAuctionData.GetRealmValue(link, key)
    if (not link) then
        return 0;
    end

    if (not AnsAuctionData:HasData()) then
        return 0;
    end

    local tsmId = Utils.GetID(link);

    if (not tsmId) then
        return 0;
    end

    local vid = AnsAuctionData:GetValidID(tsmId);
    local fid = "final:"..vid;
    local kindex = keyToIndex[key];

    if (kindex) then
        local r = AnsAuctionData:GetRawData();
        local cid = fid;

        if (Utils.IsClassic()) then
            cid = vid;
        end

        if (r and r[cid]) then
            local data = r[cid];
            data = data and data[kindex] or nil;
            return data or 0;
        else
            local _,base = strsplit(":", vid);
            local bid = _..":"..base;
            if (r and r[bid]) then
				local data = nil;
                local tmp = TempTable:Acquire(strsplit(",", r[bid]));
                for i,v in ipairs(tmp) do
                    if (v == vid) then
                        local value = tmp[i+1];
                        if (value) then
                            data = value;
                            r[fid] = {}
                            for i = 1, 6 do
                                local n, d = Utils.DecodeBase93(data);
                                tinsert(r[fid], n * 100);
                                data = d;
                            end
                            data = r[fid];
                        end
                        break;
                    end
                end
				tmp:Release();
                data = data and data[kindex] or nil;
                return data or 0;
            end 
        end
    end

    return 0;
end

function AnsAuctionData.GetValue(id, key)
    local kindex = keyToIndex[key];
    if (kindex) then
        local r = AnsAuctionData:GetRawData(true);
        if (r and r[id]) then
            local data = nil;
            data = r[id][kindex];
            return data or 0;
        end
    end
    return 0;
end

function AnsAuctionData.SetValue(id, min, avg, sum, count)
    local r = AnsAuctionData:GetRawData(true);
    if (not r) then
        r = {};
        ANS_AUCTION_DATA[region.."-"..realmName..faction] = r;
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

	local _,i = strsplit(":", tsmId);
	local base = _..":"..i;
	local bonus = Utils.BonusID(tsmId);

	if (tsmId ~= base) then
		if (tracker[base]) then
			local track = tracker[base];
			tinsert(track, copper);
		else
			local track = {};
			tinsert(track, copper);
			tracker[base] = track;
			tinsert(keys, base);
			totalItems = #keys;
		end
	end

	if (tsmId ~= bonus) then
		if (tracker[bonus]) then
			local track = tracker[bonus];
			tinsert(track, copper);
		else
			local track = {};
			tinsert(track, copper);
			tracker[bonus] = track;
			tinsert(keys, bonus);
			totalItems = #keys;
		end
	end

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