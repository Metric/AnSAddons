local Ans = select(2, ...);
local TradeTracker = {};
TradeTracker.__index = TradeTracker;

Ans.Analytics.TradeTracker = TradeTracker;

local Sources = Ans.Sources;

local Transactions = Ans.Analytics.Transactions;
local EventManager = Ans.EventManager;

local info = {player = {}, target = {}};

function TradeTracker:OnLoad()
    EventManager:On("TRADE_ACCEPT_UPDATE", self.OnUpdate);
    EventManager:On("UI_INFO_MESSAGE", self.OnMessage);
end

function TradeTracker:OnTradeComplete()
    if (not ANS_GLOBAL_SETTINGS.trackDataAnalytics and ANS_GLOBAL_SETTINGS.trackDataAnalytics ~= nil) then
        return;
    end

    if (info.player.money or info.player.items or info.target.items or info.target.money) then   
        local titems = info.target.items;
        local pitems = info.player.items;

        if (info.player.money > 0 and #titems > 0) then
            local i;      
            for i = 1, #titems do
                local item = titems[i];
                local ppu = Sources.round(info.player.money / item.count);
                Transactions:InsertBuy("trade", item.count, ppu, item.item, info.target.name, time());
            end
        elseif (info.player.money > 0 and #titems == 0) then
            Transactions:InsertExpense(info.player.money, info.target.name, time());
        end
        if (info.target.money > 0 and #pitems > 0) then
            local i;
            for i = 1, #pitems do
                local item = pitems[i];
                local ppu = Sources.round(info.target.money / item.count);
                Transactions:InsertSale("trade", item.count, ppu, item.item, info.target.name, time());
            end
        elseif (info.target.money > 0 and #pitems == 0) then
            Transactions:InsertIncome(info.target.money, info.target.name, time());
        end

        wipe(info.player);
        wipe(info.target);
    end
end

function TradeTracker.OnUpdate(player, target)
    if (not ANS_GLOBAL_SETTINGS.trackDataAnalytics and ANS_GLOBAL_SETTINGS.trackDataAnalytics ~= nil) then
        return;
    end

    if ((player == 1 or target == 1) and not (GetTradePlayerItemLink(7) or GetTradeTargetItemLink(7))) then
        info.player.money = tonumber(GetPlayerTradeMoney());
        info.target.money = tonumber(GetTargetTradeMoney());
        info.target.name = UnitName("NPC");
        info.player.items = {};
        info.target.items = {};

        local i;
        for i = 1, 6 do
            local link = GetTradeTargetItemLink(i);
            local count = select(3, GetTradeTargetItemInfo(i));
            
            if (link) then
                tinsert(info.target.items, {item = link, count = count});
            end

            link = GetTradePlayerItemLink(i);
            count = select(3, GetTradePlayerItemInfo(i));

            if (link) then
                tinsert(info.player.items, {item = link, count = count});
            end
        end
    else 
        wipe(info.player);
        wipe(info.target);
    end
end

function TradeTracker.OnMessage(msg)
    if (msg == LE_GAME_ERR_TRADE_COMPLETE) then
        TradeTracker:OnTradeComplete();
    end
end

-- we setup events here
TradeTracker:OnLoad();