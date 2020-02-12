local Ans = select(2, ...);
local AuctionList = Ans.AuctionList;

CommodityInputMixin = {};
CommodityInputMixin.__index = CommodityInputMixin;
CommodityInputMixin.isReady = false;
CommodityInputMixin.commodity = nil;
CommodityInputMixin.confirmed = false;

function CommodityInputMixin:OnShow()
    self.ConfirmButton.parent = self;
    self.MaxButton.parent = self;
    self.confirmed = false;

    self.commodity = AuctionList.commodity;

    if (self.commodity == nil) then
        self.Total:SetNumber(0);
        self.ItemName:SetText("");
        return;
    end

    self.ItemName:SetText(self.commodity.name);
    self.Total:SetNumber(self.commodity.count);
end

function CommodityInputMixin:OnHide()
    self:Cancel();
end

function CommodityInputMixin:Max()
    if (self.commodity == nil) then
        return;
    end

    self.Total:SetNumber(self.commodity.count);
end

function CommodityInputMixin:Cancel()
    self.commodity = nil;
    if (not self.confirmed) then
        AuctionList.commodity = nil;
        AuctionList.isBuying = false;
    end
end

function CommodityInputMixin:Purchase()
    AuctionList.commodity.toPurchase = self.Total:GetNumber();
    AuctionList:PurchaseCommodity();

    self.confirmed = true;
    self.commodity = nil;
    self:Hide();
end