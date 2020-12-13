local Ans = select(2, ...);
local MailTracker = Ans.Object.Register("MailTracker", Ans.Analytics);
local Config = Ans.Config;

local Sources = Ans.Sources;
local Utils = Ans.Utils;

local EventManager = Ans.EventManager;
local Transactions = Ans.Analytics.Transactions;

local mailShown = false;
local readyToProcessMail = 0;
local mailCheckTime = time();

local MAX_COPPER = Transactions.MAX_COPPER;
local SECONDS_PER_DAY = Transactions.SECONDS_PER_DAY;

local EXPIRED_TEXT = gsub(AUCTION_EXPIRED_MAIL_SUBJECT, "%%s", "");
local CANCELLED_TEXT = gsub(AUCTION_REMOVED_MAIL_SUBJECT, "%%s", "");
local OUTBID_TEXT = gsub(AUCTION_OUTBID_MAIL_SUBJECT, "%%s", "");

local takeItemQueue = {};
local autoLootQueue = {};
local takeMoneyQueue = {};

local oTakeMoney = nil;
local oTakeItem = nil;
local oAutoLoot = nil;


function MailTracker:OnLoad()
    EventManager:On("MAIL_SHOW", self.OnMailShow);
    EventManager:On("MAIL_CLOSED", self.OnMailClose);
    EventManager:On("MAIL_INBOX_UPDATE", self.OnMailUpdate);
    EventManager:On("UPDATE", self.onUpdate);

    Utils.Hook("TakeInboxItem", MailTracker.TakeItem);
    Utils.Hook("TakeInboxMoney", MailTracker.TakeMoney);
    Utils.Hook("AutoLootMailItem", MailTracker.AutoLoot);
    Utils.Hook("SendMail", MailTracker.SendMail);
end

function MailTracker.AutoLoot(ofn, index)
    oAutoLoot = ofn;

    if (MailTracker:ProcessMail(index)) then
        autoLootQueue[index] = nil;

        return ofn(index);
    else
        autoLootQueue[index] = time();
    end
end

function MailTracker.TakeMoney(ofn, index)
    oTakeMoney = ofn;

    if (MailTracker:ProcessMail(index)) then
        takeMoneyQueue[index] = nil;

        return ofn(index);
    else
        takeMoneyQueue[index] = time();
    end
end

function MailTracker.TakeItem(ofn, index, itemIndex)
    oTakeItem = ofn;

    if (MailTracker:ProcessMail(index, itemIndex)) then
        takeItemQueue[index.."."..itemIndex] = nil;

        return ofn(index, itemIndex);
    else
        if (not takeItemQueue[index.."."..itemIndex]) then
            takeItemQueue[index.."."..itemIndex] = {index, itemIndex, time()};
        else
            takeItemQueue[index.."."..itemIndex][3] = time();
        end
    end
end

function MailTracker.OnUpdate()
    if (mailShown) then
        for k,v in pairs(takeItemQueue) do
            if (v and time() - v[3] >= 2) then
                MailTracker.TakeItem(oTakeItem, v[1], v[2]);
            end
        end
        for k,v in pairs(autoLootQueue) do
            if (v and time() - v >= 2) then
                MailTracker.AutoLoot(oAutoLoot, k);
            end
        end
        for k,v in pairs(takeMoneyQueue) do
            if (v and time() - v >= 2) then
                MailTracker.TakeMoney(oTakeMoney, k);
            end
        end
    end
end

function MailTracker.Prepare()
    -- so data will be availble by the time
    -- the mail is actually opened for looting
    -- in most cases, otherwise the queues will 
    -- handle the rest

    local num = GetInboxNumItems();
    if (readyToProcessMail < num + 1) then
        for i = 1, num do
            local j = GetInboxHeaderInfo(i);
            local k = GetInboxInvoiceInfo(i);
            readyToProcessMail = readyToProcessMail + 1;
        end
    end
end

function MailTracker.OnMailShow()   
    -- clear queues
    wipe(takeMoneyQueue);
    wipe(takeItemQueue);
    wipe(autoLootQueue);

    mailShown = true;
    mailCheckTime = time();
    MailTracker.Prepare();
end

function MailTracker.OnMailClose()
    mailShown = false;
    readyToProcessMail = 0;
    
    -- clear queues
    wipe(takeMoneyQueue);
    wipe(takeItemQueue);
    wipe(autoLootQueue);
end

function MailTracker.OnMailUpdate()
    if (mailShown) then
        if (not Config.General().trackDataAnalytics and Config.General().trackDataAnalytics ~= nil) then
            return;
        end
 
        MailTracker.Prepare();
    end
end

function MailTracker.SendMail(ofn, ...)
    local destination = select(1, ...);
    local moneyAmount = GetSendMailMoney();
    local mailCost = GetSendMailPrice();

    if (moneyAmount > 0) then
        Transactions:InsertExpense(moneyAmount, destination, time());
    end

    Transactions:InsertPostage(mailCost >= moneyAmount and (mailCost - moneyAmount) or mailCost, destination, time());

    return ofn(...);
end

function MailTracker:ProcessMail(idx, itemIndex)
    if (not Config.General().trackDataAnalytics and Config.General().trackDataAnalytics ~= nil) then
        return true;
    end

    local _, stationaryIcon, sender, subject, money, codAmount, daysLeft, itemCount, wasRead = GetInboxHeaderInfo(idx);
    local invoiceType, itemName, buyer, bid, _, deposit, ahcut, _, _, _, quantity = GetInboxInvoiceInfo(idx);

    if (not subject) then
        return false;
    end

    if (not buyer and invoiceType == "seller") then
        buyer = AUCTION_HOUSE_MAIL_MULTIPLE_BUYERS;
    elseif (not buyer and invoiceType == "buyer") then
        buyer = AUCTION_HOUSE_MAIL_MULTIPLE_SELLERS;
    elseif (not buyer) then
        buyer = "";
    end

    -- why are we using mailCheckTime and not time() for time calc?
    -- it is to prevent duplication
    -- that way if it really is the same item
    -- it will be exactly the same time period
    -- since mailCheckTime is only set when the mailbox is opened
    -- and daysLeft is fractional

    -- AH sale
    if (invoiceType == "seller" and buyer ~= "") then
        local saleTime = mailCheckTime + (daysLeft - 30) * SECONDS_PER_DAY;
        local ppu = Sources.round(money / quantity);
        local name, link = GetItemInfo(itemName);
        Transactions:InsertSale("auction", quantity, ppu, link or itemName, buyer, saleTime);
    -- AH buy
    elseif (invoiceType == "buyer" and buyer ~= "") then
        local buyTime = mailCheckTime + (daysLeft - 30) * SECONDS_PER_DAY;

        if (itemIndex) then
            local link = GetInboxItemLink(idx, itemIndex);
            if (link) then
                local ppu = Sources.round(bid / quantity);
                Transactions:InsertBuy("auction", quantity, ppu, link, buyer, buyTime);
            end
        else
            for i = 1, ATTACHMENTS_MAX_RECEIVE do
                local link = GetInboxItemLink(idx, i);
                if (link) then
                    local ppu = Sources.round(bid / quantity);
                    Transactions:InsertBuy("auction", quantity, ppu, link, buyer, buyTime);
                end
            end
        end
    -- COD
    elseif (codAmount > 0) then
        if (itemIndex) then
            local link = GetInboxItemLink(idx, itemIndex);
            local count = select(4, GetInboxItem(idx, itemIndex)) or 0;

            if (link and count and count > 0) then
                local ppu = Sources.round(codAmount / count);
                local buyTime = mailCheckTime + (daysLeft - 3) * SECONDS_PER_DAY;
                Transactions:InsertCOD(count, ppu, link, sender, buyTime);
            end
        end
    -- Auction expired
    elseif (string.find(subject, EXPIRED_TEXT)) then
        local expiredTime = mailCheckTime + (daysLeft - 30) * SECONDS_PER_DAY;
        if (itemIndex) then
            local link = GetInboxItemLink(idx, itemIndex);
            local qty = select(4, GetInboxItem(idx, itemIndex)) or 0;

            if (link and qty and qty > 0) then
                Transactions:InsertExpire(qty, link, expiredTime);
            end
        end
    -- Auction cancelled
    elseif (string.find(subject, CANCELLED_TEXT)) then
        local cancelTime = mailCheckTime + (daysLeft - 30) * SECONDS_PER_DAY;
        if (itemIndex) then
            local link = GetInboxItemLink(idx, itemIndex);
            local qty = select(4, GetInboxItem(idx, itemIndex)) or 0;

            if (link and qty and qty > 0) then
                Transactions:InsertCancel(qty, link, cancelTime);
            end
        end
    elseif (money > 0 and not string.find(subject, OUTBID_TEXT)) then
        local saleTime = mailCheckTime + (daysLeft - 30) * SECONDS_PER_DAY;
        Transactions:InsertIncome(money, sender, saleTime);
    end

    return true;
end

-- We Hook and Setup Events here
MailTracker:OnLoad();