local Ans = select(2, ...);
local AuctionList = {};
AuctionList.__index = AuctionList;

Ans.AuctionList = AuctionList;

local Recycler = AnsCore.API.GroupRecycler;
local Utils = AnsCore.API.Utils;

AuctionList.selectedEntry = -1;
AuctionList.items = {};

AuctionList.rows = {};
AuctionList.style = {
    rowHeight = 16
};
AuctionList.isBuying = false;
AuctionList.isPurchaseReady = false;
AuctionList.commodity = nil;

local stepTime = 1;
local clickTime = time();
local clickCount = 0;

local purchaseQueue = {};

function AuctionList:OnLoad(parent)
    self.parent = parent;
    self.frame = _G[parent:GetName().."ResultsItems"];
    self.commodityConfirm = _G[parent:GetName().."ResultsCommodityConfirm"];

    -- get scroll child and set it's size
    -- since we are using a faux scrollframe 
    -- it does not need to be the size of the total items
    self.childFrame = _G[self.frame:GetName().."ScrollChildFrame"];
    self.childFrame:SetSize(self.frame:GetWidth(), self.frame:GetHeight());

    self.style.totalRows = math.floor(self.frame:GetHeight() / self.style.rowHeight);
    self:RegisterEvents();
    self:CreateRows();
end

function AuctionList:RegisterEvents()
    local d = self;
    if (self.frame) then
        self.frame:SetScript("OnVerticalScroll", 
        function(f, offset) 
            FauxScrollFrame_OnVerticalScroll(f, offset, d.style.rowHeight, 
            function() d:Refresh() end); 
        end);
    end
end

function AuctionList:Buy(index)
    if (self.frame and #self.items > 0 and index > 0 and index <= #self.items) then
        local block = self.items[index];
        if (block and not self.isBuying and self.commodity == nil) then
            if (self.isPurchaseReady) then
                self.isBuying = true;
                local success, isCommodity = self:Purchase(block);
                if (not isCommodity and success and block.count <= 0) then
                    Recycler:Recycle(table.remove(self.items, index));
                    if (self.selectedEntry == index) then
                        self.selectedEntry = -1;
                    end
                end
                if (not isCommodity or not success) then
                    self.isBuying = false;
                end
                self:Refresh();
            end
        end
    end
end

function AuctionList:BuyFirst() 
    if (self.frame and #self.items > 0) then
        self:Buy(1);
    end
end

function AuctionList:BuySelected()
    if (self.frame and #self.items > 0 and self.selectedEntry > 0) then
        self:Buy(self.selectedEntry);
    end
end

function AuctionList:ItemsExist()
    return #self.items > 0;
end

function AuctionList:AddItems(items)
    for i,v in ipairs(items) do
        tinsert(self.items, v:Clone());
    end 
    table.sort(self.items, function(a,b) 
        return a.percent < b.percent;
    end);
    self:Refresh();
end

function AuctionList:SetItems(items)
    wipe(self.items);
    for i,v in ipairs(items) do
        tinsert(self.items, v:Clone());
    end 
    table.sort(self.items, function(a,b) 
        return a.percent < b.percent;
    end)
    self:Refresh();
end

function AuctionList:Purchase(block)
    if (self.commodity ~= nil) then
        return false, false;
    end

    if (block.auctionId ~= nil and not block.isCommodity) then
        if (GetMoney() >= block.buyoutPrice) then
            C_AuctionHouse.PlaceBid(block.auctionId, block.buyoutPrice);
            block.count = block.count - 1;
            return true, false;
        end
    elseif (block.auctionId == nil and block.isCommodity) then
        if (ANS_SNIPE_SETTINGS.useCommodityConfirm) then
            self.commodity = block:Clone();
            self.commodityConfirm:Show();
            return true, true;
        elseif (GetMoney() >= block.buyoutPrice) then
            self.commodity = block:Clone();
            self:PurchaseCommodity(self.commodity.count);
            return true, true;
        end
    end

    return false, false;
end

function AuctionList:PurchaseCommodity(total)
    if (self.commodity == nil or total < 1) then
        return false;
    end

    self.commodity.toPurchase = total;
    
    if (self.commodity.toPurchase * self.commodity.ppu > GetMoney()) then
        print("AnS: Not enough gold to purchase "..total.." of "..self.commodity.name);
        return false;
    end
    

    C_AuctionHouse.StartCommoditiesPurchase(self.commodity.id, self.commodity.toPurchase, self.commodity.ppu);
    return true;
end

function AuctionList:ConfirmCommoditiesPurchase(ppu, total)
    if (self.commodity == nil) then
        return false;
    end

    if (total > self.commodity.ppu * self.commodity.toPurchase) then
        print("AnS: Updated total price of commodities is higher than original total purchase price.");
        self:CancelCommoditiesPurchase(true);
        return false;
    elseif (ppu * self.commodity.toPurchase > GetMoney()) then
        print("AnS: You do not have enough gold to purchase everything at the updated price per unit!");
        self:CancelCommoditiesPurchase(false);
        return false;
    end

    C_AuctionHouse.ConfirmCommoditiesPurchase(self.commodity.id, self.commodity.toPurchase);
    return true;
end

function AuctionList:OnCommondityPurchased(failed)
    if (self.commodity == nil) then
        return;
    end

    self.isBuying = false;
    if (not failed) then
        self:RemoveAuctionAmount(self.commodity, self.commodity.toPurchase);
    else
        print("AnS: Failed to buy "..self.commodity.toPurchase.." of "..self.commodity.name);
    end
    self.commodity = nil;
end

function AuctionList:CancelCommoditiesPurchase(remove)
    if (self.commodity == nil) then
        return;
    end

    self.isBuying = false;
    C_AuctionHouse.CancelCommoditiesPurchase();
    
    if (remove) then
        self:RemoveAuction(self.commodity);
    end

    self.commodity = nil;
end

function AuctionList:RemoveAuctionAmount(block, count)
    for i = 1, #self.items do
        local item = self.items[i];
        if (item.id == block.id
            and item.link == block.link
            and item.name == block.name
            and item.ppu == block.ppu
            and item.buyoutPrice == block.buyoutPrice
            and item.count == block.count) then

            block.count = block.count - count;
            item.count = item.count - count;

            if (item.count <= 0) then
                Recycler:Recycle(table.remove(self.items, i));

                if (self.selectedEntry == i) then
                    self.selectedEntry = -1;
                end
            end

            self:Refresh();
            return;
        end
    end 
end

function AuctionList:RemoveAuction(block) 
    for i = 1, #self.items do
        local item = self.items[i];
        if (item.id == block.id
            and item.link == block.link
            and item.name == block.name
            and item.ppu == block.ppu
            and item.buyoutPrice == block.buyoutPrice
            and item.count == block.count) then

            Recycler:Recycle(table.remove(self.items, i));

            if (self.selectedEntry == i) then
                self.selectedEntry = -1;
            end

            self:Refresh();
            return;
        end
    end
end

function AuctionList:Click(row, button, down) 
    local id = row:GetID();

    if (time() - clickTime > 1) then
        clickCount = 0;
    end

    if (self.selectedEntry ~= id) then
        clickCount = 0;
    end

    self.selectedEntry = id; 

    clickCount = clickCount + 1;

    local fps = math.floor(GetFramerate());

    if (clickCount == 1 and IsControlKeyDown()) then
        local block = self.items[id];

        if (block) then
            ANS_SNIPE_SETTINGS.itemBlacklist[block.tsmId] = block.link;
            Recycler:Recycle(table.remove(self.items, id));
        end

        self.selectedEntry = -1;
        clickCount = 0;
    end

    if (clickCount == 1 and ANS_GLOBAL_SETTINGS.showDressing) then
        local block = self.items[id];

        if (block) then
            local itemLink = block.link;
            if (not block.isCommodity and not block.isPet) then
                DressUpItemLink(itemLink)
            end
        end
    end

    if (clickCount == 2) then
        self:Buy(id);
        clickCount = 0;
    end

    self:Refresh();
    clickTime = time();
end

function AuctionList:ShowTip(item)
    local index = item:GetID();
    if (self.items[index]) then
        local auction = self.items[index];
        if (auction ~= nil) then
            local itemLink = auction.link;
            local count = auction.count;
            if (itemLink ~= nil) then
                Utils:ShowTooltip(item, itemLink, count);
            end
        end
    end
end

function AuctionList:UpdateRow(offset, row)
    if (offset <= #self.items) then
        if (not self.items[offset]) then
            row:Hide();
            return;
        end

        row:SetID(offset);

        local auction = self.items[offset];
        local itemKey = auction.itemKey;

        local ppu = auction.ppu;
        local itemID = auction.id;
        local ilevel = auction.iLevel;
        local percent = auction.percent;
        local count = auction.count;

        local texture = auction.texture;
        local quality = auction.quality;
        local name = auction.name;

        local itemPrice = _G[row:GetName().."PPU"];
        local itemName = _G[row:GetName().."NameText"];
        local itemStack = _G[row:GetName().."StackPrice"];
        local itemPercent = _G[row:GetName().."Percent"];
        local itemIcon = _G[row:GetName().."ItemIcon"];
        local itemLevel = _G[row:GetName().."ILevel"];

        local color = ITEM_QUALITY_COLORS[quality];
        if (color) then
            itemName:SetText("stack of "..count.." "..color.hex..name);
        else
            itemName:SetText("stack of "..count.." "..name);
        end
        itemLevel:SetText(ilevel);
        itemPrice:SetText(Utils:PriceToString(ppu));    
        itemPercent:SetText(auction.percent.."%");

        if (percent >= 100) then
            itemPercent:SetTextColor(1,0,0);
        elseif (percent >= 75) then
            itemPercent:SetTextColor(1,1,1);
        elseif (percent >= 50) then
            itemPercent:SetTextColor(0,1,0);
        elseif (percent < 0) then
            itemPercent:SetTextColor(0.5,0.5,0.5);
        else
            itemPercent:SetTextColor(0,0.5,1);
        end

        if (texture ~= nil) then
            itemIcon:SetTexture(texture);
            itemIcon:Show();
        else
            itemIcon:Hide();
        end

        if (offset == self.selectedEntry) then
            row:SetButtonState("PUSHED", true);
        else
            row:SetButtonState("NORMAL", false);
        end

        row:Show();
    else
        row:Hide();
    end
end

function AuctionList:CreateRows()
    local d = self;
    local i;
    for i = 1, self.style.totalRows do
        local f = CreateFrame("BUTTON", self.frame:GetName().."ItemRow"..i, self.frame:GetParent(), "AnsAuctionRowTemplate");
        f:SetScript("OnClick", function(r,button,down) d:Click(r,button,down) end);
        f:SetScript("OnLeave", Utils.HideTooltip);
        f:SetScript("OnEnter", function(r) d:ShowTip(r) end);
        f:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, (i - 1) * -self.style.rowHeight);
        tinsert(self.rows, f);
    end
end

function AuctionList:Clear()
    if (_G["AnsSnipeMainPanel"]:IsShown()) then
        local i;
        for i = 1, self.style.totalRows do
            self.rows[i]:Hide();
        end
    end
end

function AuctionList:Refresh()
    self:Clear();

    local i;
    local doffset;

    local offset = FauxScrollFrame_GetOffset(self.frame);

    for i = 1, self.style.totalRows do
        doffset = i + offset;
        local row = self.rows[i];
        self:UpdateRow(doffset, row);
    end

    FauxScrollFrame_Update(self.frame, #self.items, self.style.totalRows, self.style.rowHeight);
end

