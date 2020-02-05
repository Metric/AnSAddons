local Ans = select(2, ...);
local MailTracker = {};
MailTracker.__index = MailTracker;

Ans.Analytics.MailTracker = MailTracker;

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

function MailTracker:OnLoad()
    EventManager:On("MAIL_SHOW", self.OnMailShow);
    EventManager:On("MAIL_CLOSED", self.OnMailClose);
    EventManager:On("MAIL_INBOX_UPDATE", self.OnMailUpdate);

    Utils:Hook("TakeInboxItem", MailTracker.TakeItem);
    Utils:Hook("TakeInboxMoney", MailTracker.TakeMoney);
    Utils:Hook("AutoLootMailItem", MailTracker.AutoLoot);
    Utils:Hook("SendMail", MailTracker.SendMail);
end

function MailTracker.AutoLoot(ofn, index)
    if (MailTracker:ProcessMail(index)) then
        return ofn(index);
    end
end

function MailTracker.TakeMoney(ofn, index)
    if (MailTracker:ProcessMail(index)) then
        return ofn(index);
    end
end

function MailTracker.TakeItem(ofn, index, itemIndex)
    if (MailTracker:ProcessMail(index, itemIndex)) then
        return ofn(index, itemIndex);
    end
end

function MailTracker.OnMailShow()
    mailShown = true;
    mailCheckTime = time();
end

function MailTracker.OnMailClose()
    mailShown = false;
    readyToProcessMail = 0;
end

function MailTracker.OnMailUpdate()
    if (mailShown) then
        -- so data will be availble by the time
        -- the mail is actually opened for looting
        local num = GetInboxNumItems();
        if (readyToProcessMail < num + 1) then
            for i = 1, num do
                local j = GetInboxHeaderInfo(i);
                local k = GetInboxInvoiceInfo(i);
            end
            readyToProcessMail = readyToProcessMail + 1;
        end
    end
end

function MailTracker.SendMail(ofn, ...)
    local destination = select(1, ...);
    local moneyAmount = GetSendMailMoney();
    local mailCost = GetSendMailPrice();

    if (moneyAmount > 0) then
        Transactions:InsertExpense(moneyAmount, destination, time());
    end

    Transactions:InsertPostage(mailCost, destination, time());

    return ofn(...);
end

function MailTracker:ProcessMail(idx, itemIndex)
    local sender, subject, money, codAmount, daysLeft, itemCount, wasRead = select(3, GetInboxHeaderInfo(idx));

    if (wasRead or not subject or idx > readyToProcessMail) then
        return false;
    end

    local invoiceType, itemName, buyer, bid, _, deposit, ahcut, _, _, _, quantity = GetInboxInvoiceInfo(idx);

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
        else
            for i = 1, ATTACHMENTS_MAX_RECEIVE do
                local link = GetInboxItemLink(idx, i);
                local count = select(4, GetInboxItem(idx, i)) or 0;

                if (link and count and count > 0) then
                    local ppu = Sources.round(codAmount / count);
                    local buyTime = mailCheckTime + (daysLeft - 3) * SECONDS_PER_DAY;
                    Transactions:InsertCOD(count, ppu, link, sender, buyTime);
                end
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
        else
            for i = 1, ATTACHMENTS_MAX_RECEIVE do
                local link = GetInboxItemLink(idx, i);
                local qty = select(4, GetInboxItem(idx, i)) or 0;

                if (link and qty and qty > 0) then
                    Transactions:InsertExpire(qty, link, expiredTime);
                end
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
        else
            for i = 1, ATTACHMENTS_MAX_RECEIVE do
                local link = GetInboxItemLink(idx, i);
                local qty = select(4, GetInboxItem(idx, i)) or 0;

                if (link and qty and qty > 0) then
                    Transactions:InsertCancel(qty, link, cancelTime);
                end
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