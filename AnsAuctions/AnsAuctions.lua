local Ans = select(2, ...);
local AuctionsBuy = Ans.AuctionBuy;
local AuctionsSell = Ans.AuctionSell;
local AuctionData = Ans.AuctionData;
local Sources = AnsCore.API.Sources;


AnsAuctions = {};
AnsAuctions.__index = AnsAuctions;

----
-- Events
---
function AnsAuctions:RegisterEvents(frame)
    frame:RegisterEvent("ADDON_LOADED");
    frame:RegisterEvent("AUCTION_ITEM_LIST_UPDATE");
    frame:RegisterEvent("AUCTION_HOUSE_SHOW");
    frame:RegisterEvent("AUCTION_HOUSE_CLOSED");
end

function AnsAuctions:EventHandler(frame, event, ...)
    if (event == "ADDON_LOADED") then self:OnAddonLoaded(...) end;
    if (event == "AUCTION_ITEM_LIST_UPDATE") then self:OnAuctionUpdate(...); end;
    if (event == "AUCTION_HOUSE_SHOW") then self:OnAuctionHouseShow(); end;
    if (event == "AUCTION_HOUSE_CLOSED") then self:OnAuctionHouseClosed(); end;
end

function AnsAuctions:OnAddonLoaded(...)
    local addonName = select(1, ...);
    if (addonName:lower() == "blizzard_auctionui") then
        AuctionsBuy:Init();
        AuctionsSell:Init();
        AuctionData:Init();
    end
end

function AnsAuctions:OnAuctionHouseShow()
    AuctionData:Show();
end

function AnsAuctions:OnUpdate()
    AuctionsBuy:OnUpdate();
    AuctionsSell:OnUpdate();
    AuctionData:OnUpdate();
end

function AnsAuctions:OnAuctionHouseClosed()
    AuctionsBuy:OnAuctionHouseClosed();
    AuctionsSell:OnAuctionHouseClosed();
    AuctionData:OnAuctionHouseClosed();
    Sources:ClearCache();
end

function AnsAuctions:OnAuctionUpdate(...)
    AuctionsBuy:OnAuctionUpdate();
    AuctionsSell:OnAuctionUpdate();
    AuctionData:OnAuctionUpdate();
end

function AnsAuctions:PostAuction()
    AuctionsSell:PostSelected();
end

function AnsAuctions:BuyAuction()
    AuctionsBuy:ConfirmPurchase();
end

function AnsAuctions:StartBuyScan()
    AuctionsBuy:StartScan();
end

function AnsAuctions:StopBuyScan()
    AuctionsBuy:StopScan();
end

function AnsAuctions:StartDataScan()
    AuctionData:StartScan();
end

function AnsAuctions:StopDataScan()
    AuctionData:StopScan();
end