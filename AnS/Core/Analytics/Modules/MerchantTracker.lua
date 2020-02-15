local Ans = select(2, ...);
local MerchantTracker = {};
local Config = Ans.Config;
MerchantTracker.__index = MerchantTracker;
Ans.Analytics.MerchantTracker = MerchantTracker;

local Sources = Ans.Sources;
local Utils = Ans.Utils;

local pending = {};
pending.item = {};
pending.time = {};
pending.quantity = {};
pending.copper = {};

local Transactions = Ans.Analytics.Transactions;
local EventManager = Ans.EventManager;

function MerchantTracker:OnLoad()
    EventManager:On("MERCHANT_UPDATE", self.OnUpdate);
    Utils:Hook("BuyMerchantItem", self.Buy);
    Utils:Hook("BuybackItem", self.Buyback);
    Utils:Hook("RepairAllItems", self.RepairAll);
    Utils:HookSecure("UseContainerItem", self.Sell);
end

function MerchantTracker.Buy(ofn, ...)
    if (not Config.General().trackDataAnalytics and Config.General().trackDataAnalytics ~= nil) then
        return ofn(...);
    end

    local index, qty = select(1, ...);
    local link = GetMerchantItemLink(index);
    local name, _, price, quantity, numAvailable, isPurchasable = GetMerchantItemInfo(index);
    local q = qty or quantity;

    if (price and isPurchasable and GetMoney() >= price * q and price > 0) then
        Transactions:InsertBuy("vendor", q, Sources.round(price / quantity), link, "MERCHANT", time());
    end

    return ofn(...);
end

function MerchantTracker.Buyback(ofn, ...)
    if (not Config.General().trackDataAnalytics and Config.General().trackDataAnalytics ~= nil) then
        return ofn(...);
    end

    local index = select(1, ...);
    local link = GetBuybackItemLink(index);
    local name, _, price, quantity, numAvailable = GetBuybackItemInfo(index);

    if (price and price > 0 and index > 0 and index <= GetNumBuybackItems() and GetMoney() >= price) then
        Transactions:InsertBuy("vendor", quantity, Sources.round(price /quantity), link, "MERCHANT", time());
    end

    return ofn(...);
end

function MerchantTracker.RepairAll(ofn, ...)
    if (not Config.General().trackDataAnalytics and Config.General().trackDataAnalytics ~= nil) then
        return ofn(...);
    end

    local isGuildRepair = select(1, ...);
    local cost, canRepair = GetRepairAllCost();
 
    if (not isGuildRepair and GetMoney() >= cost and canRepair) then
        Transactions:InsertRepair(cost, time());
    end

    return ofn(...);
end

function MerchantTracker.Sell(bag, slot) 
    if (not Config.General().trackDataAnalytics and Config.General().trackDataAnalytics ~= nil) then
        return;
    end

    if (MerchantFrame:IsShown()) then
        local _, count, locked, quality, readable, lootable, link, isFiltered, noValue, id = GetContainerItemInfo(bag, slot);
        if (link) then
            local name, ilink, rarity, level, minlevel, type, subtype, stackcount, equiploc, itemicon, itemSellPrice = GetItemInfo(link);
        
            if (itemSellPrice ~= 0) then
                tinsert(pending.item, link);
                tinsert(pending.copper, itemSellPrice);
                tinsert(pending.time, time());
                tinsert(pending.quantity, count);
            end
        end
    end
end

function MerchantTracker.OnUpdate()
    if (not Config.General().trackDataAnalytics and Config.General().trackDataAnalytics ~= nil) then
        return;
    end

    local i;
    local tpending = #pending.item;

    for i = 1, tpending do
        local t = pending.time[i];
        local item = pending.item[i];
        local copper = pending.copper[i];
        local quantity = pending.quantity[i];

        if (time() - t < 8) then
            Transactions:InsertSale("vendor", quantity, copper, item, "MERCHANT", t);
        end
    end

    wipe(pending.time);
    wipe(pending.item);
    wipe(pending.copper);
    wipe(pending.quantity);

    MerchantTracker.Scan();
end

function MerchantTracker.Scan()
    for i = 1, GetMerchantNumItems() do
        local id = Utils:GetTSMID(GetMerchantItemLink(i));
        if (id) then
            local currentValue = Config.Vendor()[id];
            local newValue = nil;
            local _, _, price, quantity, _, _, _, extendedCost = GetMerchantItemInfo(i);
			if (price > 0 and (not extendedCost or GetMerchantItemCostInfo(i) == 0)) then
				newValue = Sources.round(price / quantity);
			end
			if (newValue ~= currentValue) then
				Config.Vendor()[id] = newValue;
			end
        end
    end
end

-- we hook and setup events here
MerchantTracker:OnLoad();