local Ans = select(2, ...);

local Utils = Ans.Utils;

local BagScanner = {};
BagScanner.__index = BagScanner;
BagScanner.items = {};

local BagItem = {};
BagItem.__index = BagItem;


Ans.BagScanner = BagScanner;

local auctionItemCache = {};
local stackTracker = {};

local function Sort(a,b)
    if (a.name == b.name) then
        return a.total < b.total;
    end

    return a.name < b.name;
end

function BagItem:NewFrom(t)
    setmetatable(t, BagItem);
    return t;
end

function BagItem:Clone()
    local b = {
        link = self.link,
        iLevel = self.iLevel,
        count = self.count,
        quality = self.quality,
        bound = self.bound,
        bag = self.bag,
        slot = self.slot,
        tex = self.tex,
        id = self.id,
        name = self.name,
        vendorsell = self.vendorsell,
        total = self.total,
        stack = self.stacks,
        isEquipment = self.isEquipment,
        isCommodity = self.isCommodity,
        itemKey = self.itemKey,
        tsmId = self.tsmId
    };
    setmetatable(b, BagItem);
    return b;
end

function BagScanner:Release()
    wipe(self.items);
    wipe(auctionItemCache);
    wipe(stackTracker);
end

function BagScanner:Exists(item, checkCount)
    local bag = item.bag;
    local slot = item.slot;
    local _, icount, locked, quality, _, lootable, link, filtered, noValue, id = GetContainerItemInfo(bag, slot);

    if (checkCount) then
        return link == item.link and item.count <= icount;
    end

    return link == item.link;
end

function BagScanner:IsLocked(item)
    local bag = item.bag;
    local slot = item.slot;
    local _, icount, locked, quality, _, lootable, link, filtered, noValue, id = GetContainerItemInfo(bag, slot);
    return locked;
end

function BagScanner:IsFullDurability(item)
    local bag = item.bag;
    local slot = item.slot;
    local current, maximum = GetContainerItemDurability(bag,slot);

    return current == maximum;
end

function BagScanner:FullDurability(bag, slot)
    local current, maximum = GetContainerItemDurability(bag, slot);
    return current == maximum;
end

function BagScanner:GetAuctionable()
    wipe(auctionItemCache);
    wipe(stackTracker);

    for i,v in ipairs(self.items) do
        if (v and v.link and v.bound ~= nil and v.bound == false and v.count > 0 and not v.hidden and v.name and v.fullDurability) then
            if (not stackTracker[v.link]) then
                stackTracker[v.link] = v;
                if (v.stacks) then
                    wipe(v.stacks);
                else
                    v.stacks = {};
                end
                v.total = v.count;
                tinsert(auctionItemCache, v);
            else
                local c = stackTracker[v.link]
                c.total = c.total + v.count;
                tinsert(c.stacks, v);
            end
        end
    end


    table.sort(auctionItemCache, Sort);
    return auctionItemCache;
end

function BagScanner:Scan()
    local bag;
    local idx = 1;
    local items = self.items;

    for bag = 0, NUM_BAG_SLOTS do
        local slots = GetContainerNumSlots(bag);

        local slot;
        for slot = 1, slots do
            local _, icount, locked, quality, _, lootable, link, filtered, noValue, id = GetContainerItemInfo(bag, slot);
            link = GetContainerItemLink(bag, slot);
            local itemSellPrice = 0;
            local boundType = 0;
            local fullDurability = self:FullDurability(bag, slot);
            if (link) then itemSellPrice = select(11, GetItemInfo(link)); end
            if (link) then boundType = select(14, GetItemInfo(link)); end
            
            if (items[idx]) then
                -- we always update this on scanning
                items[idx].fullDurability = fullDurability;

                -- different item than last scan
                if (items[idx].link ~= link or items[idx].count ~= icount or items[idx].id ~= id) then
	
                    items[idx].link = link;
                    if (link) then
                        items[idx].tsmId = Utils:GetTSMID(link);
                    else
                        items[idx].tsmId = nil;
                    end
                    items[idx].count = icount;
                    items[idx].quality = quality;
                    items[idx].hidden = false;
                    items[idx].vendorsell = itemSellPrice or 0;

                    -- if not pet cage then use tooltip soulbound check
                    -- otherwise cages are never soulbound
                    if (id ~= 82800) then
                        items[idx].bound = Utils:IsSoulbound(bag, slot) or boundType == 1 or boundType == 4;
                    else
                        items[idx].bound = false;
                    end
                    items[idx].bag = bag;
                    items[idx].slot = slot;
                    items[idx].tex = _;
                    items[idx].id = id;
                    items[idx].children = {};

                    if (link) then
                        if (Utils:IsBattlePetLink(link)) then
                            local pet = Utils:ParseBattlePetLink(link);
                            items[idx].name = pet.name;
                            items[idx].iLevel = pet.level;
                        else
                            local name, _, _, iLevel = GetItemInfo(link);
                            items[idx].name = name;
                            items[idx].iLevel = iLevel;
                        end
                    else
                        items[idx].name = nil;
                    end
                end
            else
                local bound = false;
                local name = nil;
                local tsmId = nil;
                local iLevel = 0;
                local _ = nil;

                if (id ~= 82800) then
                    bound = Utils:IsSoulbound(bag, slot) or boundType == 1 or boundType == 4;
                end

                if (link) then
                    tsmId = Utils:GetTSMID(link);

                    if (Utils:IsBattlePetLink(link)) then
                        local pet = Utils:ParseBattlePetLink(link);
                        name = pet.name;
                        iLevel = pet.level;
                    else
                        name, _, _, iLevel= GetItemInfo(link);
                    end
                end

                local item = BagItem:NewFrom({
                    fullDurability = fullDurability,
                    link = link,
                    iLevel = iLevel,
                    tsmId = tsmId,
                    count = icount,
                    quality = quality,
                    bound = bound,
                    bag = bag,
                    slot = slot,
                    tex = _,
                    id = id,
                    name = name,
                    vendorsell = itemSellPrice or 0,
                    expanded = false,
                    selected = false,
                    hidden = false,
                    children = {}
                });
                tinsert(items, item);
            end

            idx = idx + 1;
        end
    end
end