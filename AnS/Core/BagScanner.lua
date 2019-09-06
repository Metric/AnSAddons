local Ans = select(2, ...);

local Utils = Ans.Utils;

local BagScanner = {};
BagScanner.__index = BagScanner;
BagScanner.items = {};

Ans.BagScanner = BagScanner;

local auctionItemCache = {};

function BagScanner:Release()
    wipe(self.items);
    wipe(auctionItemCache);
end

function BagScanner:GetAuctionable()
    wipe(auctionItemCache);

    for i,v in ipairs(self.items) do
        if (v and v.link and v.bound ~= nil and v.bound == false and v.count > 0 and not v.hidden and v.name) then
            tinsert(auctionItemCache, v);
        end
    end

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

            if (items[idx]) then
                -- different item than last scan
                if (items[idx].link ~= link or items[idx].count ~= icount or items[idx].id ~= id) then
                    items[idx].link = link;
                    items[idx].count = icount;
                    items[idx].quality = quality;
                    items[idx].hidden = noValue;

                    -- if not pet cage then use tooltip soulbound check
                    -- otherwise cages are never soulbound
                    if (id ~= 82800) then
                        items[idx].bound = Utils:IsSoulbound(bag, slot);
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
                        else
                            local name = GetItemInfo(link);
                            items[idx].name = name;
                        end
                    else
                        items[idx].name = nil;
                    end
                end
            else
                local bound = false;
                local name = nil;

                if (id ~= 82800) then
                    bound = Utils:IsSoulbound(bag, slot);
                end

                if (link) then
                    if (Utils:IsBattlePetLink(link)) then
                        local pet = Utils:ParseBattlePetLink(link);
                        name = pet.name;
                    else
                        name = GetItemInfo(link);
                    end
                end

                local item = {
                    link = link,
                    count = icount,
                    quality = quality,
                    bound = bound,
                    bag = bag,
                    slot = slot,
                    tex = _,
                    id = id,
                    name = name,
                    expanded = false,
                    selected = false,
                    hidden = noValue,
                    children = {}
                };
                tinsert(items, item);
            end

            idx = idx + 1;
        end
    end
end