local Core = select(2, ...);
local AuctionList = Core.AuctionList;

CommodityDialogMixin = {};
CommodityDialogMixin.__index = CommodityDialogMixin;
CommodityDialogMixin.isReady = false;
CommodityDialogMixin.commodity = nil;
CommodityDialogMixin.confirmed = false;

function CommodityDialogMixin:OnShow()

end

function CommodityDialogMixin:Open(commodity)
    self.ConfirmButton.parent = self;
    self.MaxButton.parent = self;
    self.confirmed = false;

    self.commodity = commodity;

    if (self.commodity == nil) then
        self.Total:SetNumber(0);
        self.ItemName:SetText("");
        return;
    end

    self.ItemName:SetText(self.commodity.name);
    self.Total:SetNumber(self.commodity.count);

    self:Show();
end

function CommodityDialogMixin:OnHide()
    self:Cancel();
end

function CommodityDialogMixin:Max()
    if (self.commodity == nil) then
        return;
    end

    self.Total:SetNumber(self.commodity.count);
end

function CommodityDialogMixin:Cancel()
    self.commodity = nil;
end

function CommodityDialogMixin:Purchase()
    local count = self.Total:GetNumber();
    local commodity = self.commodity;

    AuctionList:Purchase(commodity, count);

    self.confirmed = true;
    self.commodity = nil;

    self:Hide();
end