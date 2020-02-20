local Ans = select(2, ...);

local Utils = Ans.Utils;

local BagScanner = {};
BagScanner.__index = BagScanner;
BagScanner.items = {};

Ans.BagScanner = BagScanner;

local auctionItemCache = {};
local stackTracker = {};

local function Sort(a,b)
    if (a.name == b.name) then
        return a.total < b.total;
    end

    return a.name < b.name;
end

function BagScanner:Release()
    wipe(self.items);
    wipe(auctionItemCache);
    wipe(stackTracker);
end

function BagScanner:GetAuctionable()
    wipe(auctionItemCache);
    wipe(stackTracker);

    for i,v in ipairs(self.items) do
        if (v and v.link and v.bound ~= nil and v.bound == false and v.count > 0 and not v.hidden and v.name) then
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
            if (link) then itemSellPrice = select(11, GetItemInfo(link)); end
            if (link) then boundType = select(14, GetItemInfo(link)); end
            
            if (items[idx]) then
                -- different item than last scan
                if (items[idx].link ~= link or items[idx].count ~= icount or items[idx].id ~= id) then
	
                    items[idx].link = link;
                    items[idx].count = icount;
                    items[idx].quality = quality;
                    items[idx].hidden = false;
					items[idx].vendorsell = itemSellPrice;

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
                    bound = Utils:IsSoulbound(bag, slot) or boundType == 1 or boundType == 4;
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
					vendorsell = itemSellPrice,
                    expanded = false,
                    selected = false,
                    hidden = false,
                    children = {}
                };
                tinsert(items, item);
            end

            idx = idx + 1;
        end
    end
end