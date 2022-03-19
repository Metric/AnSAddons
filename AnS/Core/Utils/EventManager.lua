local Ans = select(2, ...);
local Utils = Ans.Utils;
local EventManager = Ans.Object.Register("EventManager");
EventManager.listeners = {};

local SHARED_EVENTS_TO_REGISTER = {
    "LOOT_CLOSED",
    "UNIT_SPELLCAST_START",
    "UNIT_SPELLCAST_FAILED",
    "UNIT_SPELLCAST_FAILED_QUIET",
    "UNIT_SPELLCAST_INTERRUPTED",
    "TRADE_SKILL_SHOW",
    "TRADE_SKILL_CLOSE",
    "UI_ERROR_MESSAGE",
    "PLAYER_MONEY",
    "BANKFRAME_OPENED",
    "BANKFRAME_CLOSED",
    "BAG_UPDATE_DELAYED",
    "MAIL_SHOW",
    "MAIL_CLOSED",
    "MAIL_INBOX_UPDATE",
    "MAIL_FAILED",
    "MAIL_SUCCESS",
    "TRADE_ACCEPT_UPDATE",
    "UI_INFO_MESSAGE",
    "MERCHANT_UPDATE",
    "PLAYER_ENTERING_WORLD",
    "GET_ITEM_INFO_RECEIVED",
    "AUCTION_HOUSE_SHOW",
    "AUCTION_HOUSE_CLOSED",
    "CHAT_MSG_SYSTEM",
};

local RETAIL_EVENTS_TO_REGISTER = {
    "AUCTION_HOUSE_BROWSE_RESULTS_ADDED",
    "AUCTION_HOUSE_BROWSE_RESULTS_UPDATED",
    "ITEM_SEARCH_RESULTS_ADDED",
    "ITEM_SEARCH_RESULTS_UPDATED",
    "ITEM_KEY_ITEM_INFO_RECEIVED",
    "COMMODITY_SEARCH_RESULTS_ADDED",
    "COMMODITY_SEARCH_RESULTS_UPDATED",
    "OWNED_AUCTIONS_UPDATED",
    "AUCTION_HOUSE_AUCTION_CREATED",
    "AUCTION_MULTISELL_FAILURE",
    "REPLICATE_ITEM_LIST_UPDATE",
    "TRADE_SKILL_DATA_SOURCE_CHANGED",
    "AUCTION_HOUSE_SHOW_NOTIFICATION",
    "AUCTION_HOUSE_SHOW_FORMATTED_NOTIFICATION",
    "AUCTION_HOUSE_SHOW_ERROR",
    "COMMODITY_PRICE_UPDATED",
    "COMMODITY_PRICE_UNAVAILABLE",
    "COMMODITY_PURCHASED",
    "COMMODITY_PURCHASE_FAILED",
    "COMMODITY_PURCHASE_SUCCEEDED",
    "BIDS_UPDATED",
    "GUILDBANKFRAME_OPENED",
    "GUILDBANKFRAME_CLOSED",
    "GUILDBANK_UPDATE_MONEY",
    "REAGENTBANK_UPDATE"
};

local CLASSIC_EVENTS_TO_REGISTER = {
    "AUCTION_MULTISELL_FAILURE",
    "AUCTION_ITEM_LIST_UPDATE",
    "AUCTION_OWNED_LIST_UPDATE",
    "TRADE_SKILL_UPDATE",
};

function EventManager:Register(frame)
    if (not frame) then
        return;
    end

    for i,v in ipairs(SHARED_EVENTS_TO_REGISTER) do
        frame:RegisterEvent(v);
    end

    local events = nil;

    if (Utils.IsClassic()) then
        events = CLASSIC_EVENTS_TO_REGISTER;
    else
        events = RETAIL_EVENTS_TO_REGISTER;
    end

    for i,v in ipairs(events) do
        frame:RegisterEvent(v);
    end
end

function EventManager:Emit(event, ...)
    local listeners = self.listeners[event];

    if (listeners) then
        for _, v in ipairs(listeners) do
            v(...);
        end
    end
end

function EventManager:On(event, fn)
    local listeners = self.listeners[event] or {};
    
    if (type(fn) == 'function') then
        tinsert(listeners, fn);
    end

    self.listeners[event] = listeners;
end

function EventManager:Off(event, fn)
    local listeners = self.listeners[event];

    if (listeners) then
        for i, v in ipairs(listeners) do
            if (v == fn) then
                tremove(listeners, i);
                break;
            end
        end
    end
end
