local Ans = select(2, ...);
local Config = Ans.Config;
local Sources = Ans.Sources;
local Query = Ans.Auctions.Query;
local Recycler = Ans.Auctions.Recycler;
local Utils = Ans.Utils;
local Groups = Utils.Groups;
local Exporter = Ans.Exporter;
local TempTable = Ans.TempTable;
local BagScanner = Ans.BagScanner;
local Auctioning = Ans.Object.Register("Auctioning", Ans.Operations);

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

local ITEM_REF_ILEVEL = 1;
local ITEM_REF_ILEVELMODS = 2;

Auctioning.ACTIONS = ACTIONS;
Auctioning.REFERENCES = {
    ILevel = ITEM_REF_ILEVEL,
    ILevelMods = ITEM_REF_ILEVELMODS,
};

local tempTbl = {};

function Auctioning.IsValidConfig(c)
    return c.name and c.duration 
        and c.keepInBags and c.maxToPost 
        and c.stackSize and c.bidPercent
        and c.undercut and c.minPrice
        and c.maxPrice and c.normalPrice
        and type(c.commodityLow) == "boolean" and type(c.applyAll) == "boolean"
        and c.minPriceAction and c.maxPriceAction
        and c.groups; 
end

function Auctioning.Config(name)
    local isTSMActive = TSM_API or TSMAPI;
    local t = {
        id = Utils.Guid(),
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
        itemReference = 1,
        groups = {},
        nonActiveGroups = {}
    };

    return t;
end

function Auctioning.PrepareExport(config)
    local a = {};
    a.name = config.name;
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
    a.itemReference = config.itemReference or 1;
    a.groups = {};

    for i,v in ipairs(config.groups) do
        local g = Groups.GetGroupFromId(v);
        if (g) then
            tinsert(a.groups, g.path);
        end
    end

    return a;
end

function Auctioning.From(config)
    local a = Auctioning:New();
    a.name = config.name;
    a.id = config.id;
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
    a.itemReference = config.itemReference or 1;
    a.groups = {};
    a.ids = {};

    for i,v in ipairs(config.groups) do
        if (not a.nonActiveGroups[v]) then
            local g = Groups.GetGroupFromId(v);
            if (g) then
                tinsert(a.groups, g);
            end
        end
    end

    a.totalListed = 0;
    a.config = config;
    a.idCount = Groups.ParseGroups(a.groups, a.ids);
    return a;
end

function Auctioning:GetReferenceID(item)
    if (self.itemReference == ITEM_REF_ILEVEL) then
        return Utils.BonusID(item.tsmId or Utils.GetID(item), false);
    else
        return item.tsmId or item;
    end
end

function Auctioning:Track(item)
    if (item.isOwnerItem or item.owner == UnitName("player")) then
        self.totalListed = self.totalListed + item.count;
    end
end

function Auctioning:MaxPosted()
    return self.totalListed >= self.maxToPost and self.maxToPost > 0;
end

function Auctioning:IsValid(ppu, id, ignore, defaultValue)
    local minValue = Sources:QueryID(self.minPrice, id);
    local maxValue = Sources:QueryID(self.maxPrice, id);
    local normalValue = Sources:QueryID(self.normalPrice, id);

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
    if (self.ids[v.tsmId] or self.ids[_..":"..id] or (self.applyAll and v.quality > 0)) then
        return true;
    end

    return false;
end

function Auctioning:GetNormalValue(item)
    return Sources:QueryID(self.normalPrice, item.link);
end

function Auctioning:GetAvailableItems()
    wipe(tempTbl);

    BagScanner.Release();
    BagScanner.Scan();
    local auctionable = BagScanner.GetAuctionable();

    for i,v in ipairs(auctionable) do
        local vid = self:GetReferenceID(v);
        local _, id = strsplit(":", vid);
        if (self.ids[vid] or self.ids[_..":"..id] or (self.applyAll and v.quality > 0)) then
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

    if (Utils.IsClassic()) then
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