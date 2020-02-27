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

local DEFAULT_MIN_PRICE = "max(25% avg(ansmarket, ansrecent, ansmin, ans3day), 150% vendorsell)";
local DEFAULT_NORMAL_PRICE = "max(avg(ansmarket, ansrecent, ansmin, ans3day), 250% vendorsell)";
local DEFAULT_MAX_PRICE = "max(200% avg(ansmarket, ansrecent, ansmin, ans3day), 400% vendorsell)";

local tempTbl = {};
local queue = {};
local waitingForConfirm = false;

function Auctioning:New(name)
    local a = {};
    setmetatable(a, Auctioning);
    a:Init(name);
    return a;
end

function Auctioning.IsWaitingForConfirm()
    return waitingForConfirm;
end

function Auctioning.CancelConfirm(post)
    if (#queue > 0) then
        local v = queue[1];
        if (not post) then
            print("AnS - failed to cancel "..v.link);
        end
    end
    waitingForConfirm = false;
end

function Auctioning.Confirm(post)
    if (#queue > 0) then
        local v = tremove(queue, 1);
        if (post) then
            local total = v.toSell;
            print("AnS - "..v.link.. " posted "..total.." for "..Utils:PriceToString(v.ppu).."|cFFFFFFFF per unit");
        else
            print("AnS - canceled "..v.link);
        end
    end
    waitingForConfirm = false;
end

function Auctioning.QueueCount()
    return #queue;
end

function Auctioning.ClearQueue()
    wipe(queue);
end

function Auctioning:PostNext()
    if (Utils:IsClassic()) then
        return self:PostNextClassic();
    else
        return self:PostNextRetail();
    end
end

function Auctioning:CancelNext()
    if (Utils:IsClassic()) then
        return self:CancelNextClassic();
    else
        return self:CancelNextRetail();
    end
end

function Auctioning:CancelNextClassic()
    if (#queue > 0 and not waitingForConfirm) then
        local v = queue[1];
        local num = Query:OwnedCount();

        -- we need to find the classic index to cancel
        -- based on the hash
        for i = 1, num do 
            local a = Query:GetOwnedAuctionClassic(i);
            if (a) then
                if (a.hash == v.hash) then
                    if (CanCancelAuction(a.itemIndex)) then
                        waitingForConfirm = true;
                        CancelAuction(a.itemIndex);
                        Recycler:Recycle(a);
                        Auctioning.Confirm(false);
                        return true;
                    end
                end

                Recycler:Recycle(a);
            end
        end
    end

    return false;
end

function Auctioning:CancelNextRetail()
    if (#queue > 0 and not waitingForConfirm) then
        local v = queue[1];
        if (C_AuctionHouse.CanCancelAuction(v.auctionId)) then
            waitingForConfirm = true;
            C_AuctionHouse.CancelAuction(v.auctionId);
            Auctioning.Confirm(false)
            return true;
        end
    end

    return false;
end

function Auctioning:PostNextRetail()
    if (#queue > 0 and not waitingForConfirm) then
        local v = queue[1];
        local total = v.toSell;
        local op = v.op;
        local location = ItemLocation:CreateFromBagAndSlot(v.bag, v.slot);
        if (total > 0) then
            local type = C_AuctionHouse.GetItemCommodityStatus(location);
            if (type == 2) then
                waitingForConfirm = true;
                C_AuctionHouse.PostCommodity(location, op.duration, total, v.ppu);
                Auctioning.Confirm(true);
                return true;
            elseif (type == 1) then
                waitingForConfirm = true;
                C_AuctionHouse.PostItem(location, op.duration, total, nil, v.ppu);
                Auctioning.Confirm(true);
                return true;
            end
        end
    end

    return false;
end

function Auctioning:PostNextClassic()
    if(#queue > 0) then
        local v = queue[1];
        local op = v.op;
        local ppu = v.ppu;
        local bidPPU = v.ppu * op.bidPercent;

        PickupContainerItem(v.bag, v.slot);
        ClickAuctionSellItemButton();

        PostAuction(v.count * bidPPU, v.count * ppu, op.duration, v.count, 1);

        local total = v.count;
        print("AnS - "..v.link.. " posted "..total.." for "..Utils:PriceToString(v.ppu).."|cFFFFFFFF per unit");

        tremove(queue, 1);

        return true;
    end

    return false;
end

function Auctioning:Init(name)
    self.id = Utils:Guid();
    self.name = name;
    self.duration = 2;
    self.keepInBags = 0;
    self.maxToPost = 0 -- post everything
    self.stackSize = 0; -- automatic
    self.bidPercent = 1;
    self.undercut = "0c";
    self.minPrice = DEFAULT_MIN_PRICE;
    self.normalPrice = DEFAULT_NORMAL_PRICE;
    self.maxPrice = DEFAULT_MAX_PRICE;
    self.commodityLow = true;
    self.applyAll = false;
    self.groups = {};
    self.ids = {};
    self.idCount = 0;

    self.config = Auctioning:NewConfig(name);
end

function Auctioning:NewConfig(name)
    local t = {
        id = Utils:Guid(),
        name = name,
        duration = 2,
        keepInBags = 0,
        maxToPost = 0,
        stackSize = 0,
        bidPercent = 1,
        undercut = "0c",
        minPrice = DEFAULT_MIN_PRICE,
        maxPrice = DEFAULT_MAX_PRICE,
        normalPrice = DEFAULT_NORMAL_PRICE,
        commodityLow = true,
        applyAll = false,
        groups = {}
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

    for i,v in ipairs(config.groups) do
        local g = Utils:GetGroupFromId(v);
        if (g) then
            tinsert(a.groups, g);
        end
    end

    a.config = config;
    a.idCount = Utils:ParseGroups(a.groups, a.ids);
    return a;
end

function Auctioning:IsValid(auction, ignore, defaultValue)
    local minValue = Sources:QueryID(self.minPrice, auction.link);
    local maxValue = Sources:QueryID(self.maxPrice, auction.link);
    local normalValue = Sources:QueryID(self.normalPrice, auction.link);

    if (ignore or (minValue == 0 and maxValue == 0 and normalValue == 0)) then
        return auction.ppu;
    end

    if (auction.ppu < minValue or auction.ppu > maxValue) then
        return defaultValue or normalValue;
    end

    return auction.ppu;
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
function Auctioning:ApplyPost(item)
    if (Utils:IsClassic()) then
        self:ApplyPostClassic(item);
    else
        self:ApplyPostRetail(item);
    end
end

function Auctioning:ApplyCancel(v)
    if (v.ppu < v.ownedPPU) then
        tinsert(queue, v);
    end
end

function Auctioning:ApplyPostRetail(v)
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

function Auctioning:ApplyPostClassic(v)
    local total = v.total;

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