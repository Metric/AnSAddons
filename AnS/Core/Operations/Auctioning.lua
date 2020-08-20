local Ans = select(2, ...);
local Config = Ans.Config;
local Sources = Ans.Sources;
local Query = Ans.Auctions.Query;
local Recycler = Ans.Auctions.Recycler;
local Utils = Ans.Utils;
local BagScanner = Ans.BagScanner;
local Auctioning = {};
Auctioning.__index = Auctioning;
Ans.Operations.Auctioning = Auctioning;

local DEFAULT_MIN_PRICE_ANS = "max(25% avg(ansmarket, ansrecent, ansmin, ans3day), 150% vendorsell)";
local DEFAULT_NORMAL_PRICE_ANS = "max(avg(ansmarket, ansrecent, ansmin, ans3day), 250% vendorsell)";
local DEFAULT_MAX_PRICE_ANS = "max(200% avg(ansmarket, ansrecent, ansmin, ans3day), 400% vendorsell)";

local DEFAULT_MIN_PRICE_TSM = "max(25% avg(dbmarket, dbminbuyout), 150% vendorsell)";
local DEFAULT_NORMAL_PRICE_TSM = "max(avg(dbmarket, dbminbuyout), 250% vendorsell)";
local DEFAULT_MAX_PRICE_TSM = "max(200% avg(dbmarket, dbminbuyout), 400% vendorsell)";

local ACTIONS = {};
ACTIONS.MIN_PRICE = 1;
ACTIONS.MAX_PRICE = 2;
ACTIONS.NORMAL_PRICE = 3;
ACTIONS.NONE = 4;

Auctioning.ACTIONS = ACTIONS;

local tempTbl = {};

function Auctioning:New(name)
    local a = {};
    setmetatable(a, Auctioning);
    a:Init(name);
    return a;
end

function Auctioning:Init(name)
    local isTSMActive = TSM_API or TSMAPI;
    self.id = Utils:Guid();
    self.name = name;
    self.duration = 2;
    self.keepInBags = 0;
    self.maxToPost = 0 -- post everything
    self.stackSize = 0; -- automatic
    self.bidPercent = 1;
    self.undercut = "0c";
    self.minPrice = isTSMActive and DEFAULT_MIN_PRICE_TSM or DEFAULT_MIN_PRICE_ANS;
    self.normalPrice = isTSMActive and DEFAULT_NORMAL_PRICE_TSM or DEFAULT_NORMAL_PRICE_ANS;
    self.maxPrice = isTSMActive and DEFAULT_MAX_PRICE_TSM or DEFAULT_MAX_PRICE_ANS;
    self.commodityLow = true;
    self.applyAll = false;
    self.groups = {};
    self.ids = {};
    self.idCount = 0;
    self.minPriceAction = 4;
    self.maxPriceAction = 3;
    self.nonActiveGroups = {};
    self.totalListed = 0;

    self.config = Auctioning:NewConfig(name);
end

function Auctioning:NewConfig(name)
    local isTSMActive = TSM_API or TSMAPI;
    local t = {
        id = Utils:Guid(),
        name = name,
        duration = 2,
        keepInBags = 0,
        maxToPost = 0,
        stackSize = 0,
        bidPercent = 1,
        undercut = "0c",
        minPrice = isTSMActive and DEFAULT_MIN_PRICE_TSM or DEFAULT_MIN_PRICE_ANS,
        maxPrice = isTSMActive and DEFAULT_MAX_PRICE_TSM or DEFAULT_MAX_PRICE_ANS,
        normalPrice = isTSMActive and DEFAULT_NORMAL_PRICE_TSM or DEFAULT_NORMAL_PRICE_ANS,
        commodityLow = true,
        applyAll = false,
        minPriceAction = 4,
        maxPriceAction = 3,
        groups = {},
        nonActiveGroups = {}
    };

    return t;
end

function Auctioning:FromConfig(config)
    local a = Auctioning:New(config.name);
    a.duration = config.duration;
    a.keepInBags = config.keepInBags;
    a.maxToPost = config.maxToPost;
    a.stackSize = config.stackSize;
    a.bidPercent = config.bidPercent;
    a.undercut = config.undercut;
    a.minPrice = config.minPrice;
    a.normalPrice = config.normalPrice;
    a.maxPrice = config.maxPrice;
    a.commodityLow = config.commodityLow;
    a.applyAll = config.applyAll;
    a.minPriceAction = config.minPriceAction or 4;
    a.maxPriceAction = config.maxPriceAction or 3;
    a.nonActiveGroups = config.nonActiveGroups or {};

    for i,v in ipairs(config.groups) do
        if (not a.nonActiveGroups[v]) then
            local g = Utils:GetGroupFromId(v);
            if (g) then
                tinsert(a.groups, g);
            end
        end
    end

    a.totalListed = 0;
    a.config = config;
    a.idCount = Utils:ParseGroups(a.groups, a.ids);
    return a;
end

function Auctioning:Track(item)
    if (item.isOwnerItem or item.owner == UnitName("player")) then
        self.totalListed = self.totalListed + item.count;
    end
end

function Auctioning:MaxPosted()
    return self.totalListed >= self.maxToPost and self.maxToPost > 0;
end

function Auctioning:IsValid(ppu, link, ignore, defaultValue)
    local minValue = Sources:QueryID(self.minPrice, link);
    local maxValue = Sources:QueryID(self.maxPrice, link);
    local normalValue = Sources:QueryID(self.normalPrice, link);

    if (ignore or (minValue == 0 and maxValue == 0 and normalValue == 0)) then
        return ppu;
    end

    if (ppu < minValue and ppu > 0) then
        if (self.minPriceAction == ACTIONS.MIN_PRICE) then
            return minValue;
        elseif (self.minPriceAction == ACTIONS.MAX_PRICE) then
            return maxValue;
        elseif (self.minPriceAction == ACTIONS.NORMAL_PRICE) then
            return normalValue;
        else
            return 0;
        end
    elseif (ppu > maxValue) then
        if (self.maxPriceAction == ACTIONS.MIN_PRICE) then
            return minValue;
        elseif (self.maxPriceAction == ACTIONS.MAX_PRICE) then
            return maxValue;
        elseif (self.maxPriceAction == ACTIONS.NORMAL_PRICE) then
            return normalValue;
        else
            return 0;
        end
    -- whoops forgot to take this into account where no
    -- item may be listed on AH currently
    -- ppu == 0 means nothing currently posted on AH to compare to
    -- so return normal value or 0
    elseif (ppu <= 0) then
        return normalValue or 0;
    end

    return ppu;
end

function Auctioning:ContainsItem(v)
    -- the item should already be assigned a tsmId here
    local _, id = strsplit(":", v.tsmId);
    if (self.ids[tsmId] or self.ids[_..":"..id] or (self.applyAll and v.quality > 0)) then
        return true;
    end

    return false;
end

function Auctioning:GetNormalValue(item)
    return Sources:QueryID(self.normalPrice, item.link);
end

function Auctioning:GetAvailableItems()
    wipe(tempTbl);

    BagScanner:Release();
    BagScanner:Scan();
    local auctionable = BagScanner:GetAuctionable();

    for i,v in ipairs(auctionable) do
        local tsmId = Utils:GetTSMID(v.link);
        local _, id = strsplit(":", tsmId);
        if (self.ids[tsmId] or self.ids[_..":"..id] or (self.applyAll and v.quality > 0)) then
            -- assign op to the items
            v.op = self;
            for k,o in ipairs(v.stacks) do
                o.op = self;
            end

            tinsert(tempTbl, v);
        end
    end

    return tempTbl;
end

-- items should have had a .ppu assigned to them at this point
function Auctioning:ApplyPost(item, queue)
    if (self:MaxPosted()) then
        return;
    end

    if (Utils:IsClassic()) then
        self:ApplyPostClassic(item, queue);
    else
        self:ApplyPostRetail(item, queue);
    end
end

function Auctioning:ApplyCancel(v, queue)
    if (v.ppu < v.ownedPPU) then
        tinsert(queue, v);
    end
end

function Auctioning:ApplyPostRetail(v, queue)
    local total = v.total;

    total = total - self.keepInBags;

    if (total > self.maxToPost and self.maxToPost > 0) then
        total = self.maxToPost;
    end

    if (total > 0) then
        v.toSell = total;
        tinsert(queue, v);
    end
end

function Auctioning:ApplyPostClassic(v, queue)
    local total = v.total;
    local ppu = v.ppu;

    total = total - self.keepInBags;
    if (total > self.maxToPost and self.maxToPost > 0) then
        total = self.maxToPost;
    end

    if (total > 0) then
        local prevTotal = total;
        
        for i,o in ipairs(v.stacks) do
            if ((self.stackSize > 0 and o.count <= self.stackSize) or self.stackSize <= 0) then
                prevTotal = total;
                total = total - o.count;
                o.ppu = ppu;

                if (total < 0) then
                    o.count = prevTotal;
                end

                tinsert(queue, o);
    
                if (total <= 0) then
                    return;
                end
            end
        end

        if (total > 0) then
            if ((self.stackSize > 0 and v.count <= self.stackSize) or self.stackSize <= 0) then
                prevTotal = total;
                total = total - v.count;
                
                if (total < 0) then
                    v.count = prevTotal;
                end

                tinsert(queue, v);
            end
        end
    end
end