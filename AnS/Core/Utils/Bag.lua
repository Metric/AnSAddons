local Ans = select(2, ...);
local Utils = Ans.Utils;
local Bag = Ans.Object.Register("Bag");
local BagItem = Ans.Object.Register("BagItem", Bag);

local AUCTION_CACHE = {};
local STACK_CACHE = {};
local ITEM_CACHE = {};

local function Sort(a,b)
    if (a.name == b.name) then
        return a.total < b.total;
    end

    return a.name < b.name;
end

local function BagItemInfo(bag, slot)
    local t = C_Container.GetContainerItemInfo(bag, slot);
    
    if (t == nil) then
        return nil;
    end

    return t.iconFileID,t.stackCount,t.isLocked,t.quality,t.isReadable,t.hasLoot,t.hyperlink,t.isFiltered,t.hasNoValue,t.itemID,t.isBound;
end

function BagItem:Clone()
    return BagItem:New({
        link = self.link,
        iLevel = self.iLevel,
        count = self.count,
        quality = self.quality,
        bag = self.bag,
        slot = self.slot,
        tex = self.tex,
        id = self.id,
        name = self.name,
        vendorsell = self.vendorsell,
        total = self.total,
        stacks = self.stacks,
        isEquipment = self.isEquipment,
        isCommodity = self.isCommodity,
        itemKey = self.itemKey,
        tsmId = self.tsmId,
        bindType = self.bindType
    });
end

function BagItem:Exists(checkCount, checkCountExact)
    local bag = self.bag;
    local slot = self.slot;
    local _, icount, locked, quality, _, lootable, link, filtered, noValue, id = BagItemInfo(bag, slot);

    if (checkCount) then
        if (checkCountExact) then
            return link == self.link and checkCountExact == icount;
        end
        return link == self.link and self.count <= icount;
    end

    return link == self.link;
end

function BagItem:IsFullDurability()
    local bag = self.bag;
    local slot = self.slot;
    local current, maximum = C_Container.GetContainerItemDurability(bag,slot);

    return current == maximum;
end

function BagItem:IsLocked()
    local bag = self.bag;
    local slot = self.slot;
    local _, icount, locked, quality, _, lootable, link, filtered, noValue, id = BagItemInfo(bag, slot);
    return locked;
end

function BagItem:IsSoulbound()
    local bag = self.bag;
    local slot = self.slot;

    return Utils.IsSoulbound(bag, slot);
end

function BagItem:IsBoP()
    return self.bindType == LE_ITEM_BIND_ON_ACQUIRE;
end

Bag.ItemInfo = BagItemInfo;

function Bag.Release()
    wipe(ITEM_CACHE);
    wipe(AUCTION_CACHE);
    wipe(STACK_CACHE);
end

function Bag.FullDurability(bag, slot)
    local current, maximum = C_Container.GetContainerItemDurability(bag, slot);
    return current == maximum;
end

function Bag.GetDestroyable(result, craftingHandler, ignoreBOP)
    wipe(result);

    if (not craftingHandler) then
        return;
    end

    for i,v in ipairs(ITEM_CACHE) do
        local ignore = v and v:IsBoP() and ignoreBOP;
        local valid = v and v.tsmId and v.link and v.count > 0 and not v.hidden and v.name and craftingHandler.IsDestroyable(v.tsmId, v.link) and craftingHandler.HasMinimumCount(v);
        if (not ignore and valid) then
            if (not result[v.id]) then
                result[v.id] = {};
            end
            tinsert(result[v.id], v);
        end
    end
end

function Bag.GetSendable(result)
    wipe(result);
    for i,v in ipairs(ITEM_CACHE) do
        if (v and v.link and v.count > 0 and not v:IsSoulbound() and not v.hidden and v.name and v:IsFullDurability()) then
            tinsert(result, v);
        end
    end
end

function Bag.GetAuctionable()
    wipe(AUCTION_CACHE);
    wipe(STACK_CACHE);

    for i,v in ipairs(ITEM_CACHE) do
        if (v and v.link and v.count > 0 and not v.hidden and v.name and v:IsFullDurability() and not v:IsSoulbound()) then
            if (not STACK_CACHE[v.link]) then
                STACK_CACHE[v.link] = v;
                if (v.stacks) then
                    wipe(v.stacks);
                else
                    v.stacks = {};
                end
                v.total = v.count;
                tinsert(AUCTION_CACHE, v);
            else
                local c = STACK_CACHE[v.link]
                c.total = c.total + v.count;
                tinsert(c.stacks, v);
            end
        end
    end


    wipe(STACK_CACHE);

    table.sort(AUCTION_CACHE, Sort);
    return AUCTION_CACHE;
end

function Bag.Scan(self)
    local bag;
    local idx = 1;

    for bag = 0, NUM_BAG_SLOTS do
        local slots = C_Container.GetContainerNumSlots(bag);

        local slot;
        for slot = 1, slots do
            local _, icount, locked, quality, _, lootable, link, filtered, noValue, id = BagItemInfo(bag, slot);
            link = C_Container.GetContainerItemLink(bag, slot);
            local itemSellPrice = 0;
            local bindType = LE_ITEM_BIND_NONE;
            if (link) then 
                itemSellPrice = select(11, GetItemInfo(link));
                bindType = select(14, GetItemInfo(link)); 
            end
            
            if (ITEM_CACHE[idx]) then
                -- different item than last scan
                if (ITEM_CACHE[idx].link ~= link or ITEM_CACHE[idx].count ~= icount or ITEM_CACHE[idx].id ~= id) then
	
                    ITEM_CACHE[idx].link = link;
                    if (link) then
                        ITEM_CACHE[idx].tsmId = Utils.GetID(link);
                    else
                        ITEM_CACHE[idx].tsmId = nil;
                    end
                    ITEM_CACHE[idx].count = icount;
                    ITEM_CACHE[idx].quality = quality;
                    ITEM_CACHE[idx].hidden = false;
                    ITEM_CACHE[idx].vendorsell = itemSellPrice or 0;
                    ITEM_CACHE[idx].bag = bag;
                    ITEM_CACHE[idx].slot = slot;
                    ITEM_CACHE[idx].tex = _;
                    ITEM_CACHE[idx].id = id;
                    ITEM_CACHE[idx].bindType = bindType;
                    ITEM_CACHE[idx].children = {};

                    if (link) then
                        if (Utils.IsBattlePetLink(link)) then
                            local pet = Utils.ParseBattlePetLink(link);
                            ITEM_CACHE[idx].name = pet.name;
                            ITEM_CACHE[idx].iLevel = pet.level;
                        else
                            local name, _, _, iLevel = GetItemInfo(link);

                            if (_G["GetDetailedItemLevelInfo"]) then
                                local eff, preview, base = GetDetailedItemLevelInfo(link);
                                if (eff) then
                                    iLevel = eff;
                                end
                            end
                        
                            ITEM_CACHE[idx].name = name;
                            ITEM_CACHE[idx].iLevel = iLevel;
                        end
                    else
                        ITEM_CACHE[idx].name = nil;
                    end
                end
            else
                local bound = false;
                local name = nil;
                local tsmId = nil;
                local iLevel = 0;
                local _ = nil;

                if (link) then
                    tsmId = Utils.GetID(link);

                    if (Utils.IsBattlePetLink(link)) then
                        local pet = Utils.ParseBattlePetLink(link);
                        name = pet.name;
                        iLevel = pet.level;
                    else
                        name, _, _, iLevel = GetItemInfo(link);
                        
                        if (_G["GetDetailedItemLevelInfo"]) then
                            local eff, preview, base = GetDetailedItemLevelInfo(link);
                            if (eff) then
                                iLevel = eff;
                            end
                        end
                    end
                end

                local item = BagItem:New({
                    link = link,
                    iLevel = iLevel,
                    tsmId = tsmId,
                    count = icount,
                    quality = quality,
                    bag = bag,
                    slot = slot,
                    tex = _,
                    id = id,
                    name = name,
                    vendorsell = itemSellPrice or 0,
                    expanded = false,
                    selected = false,
                    hidden = false,
                    bindType = bindType,
                    children = {}
                });
                tinsert(ITEM_CACHE, item);
            end

            idx = idx + 1;
        end
    end
end