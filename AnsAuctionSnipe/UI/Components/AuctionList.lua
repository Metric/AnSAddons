local Core = select(2, ...);
local Config = Ans.API.Config;
local Query = Ans.API.Auctions.Query;
local TempTable = Ans.API.TempTable;
local AuctionList = {};
AuctionList.__index = AuctionList;

Core.AuctionList = AuctionList;

local Recycler = Ans.API.Auctions.Recycler;
local Query = Ans.API.Auctions.Query;
local Utils = Ans.API.Utils;

AuctionList.selectedEntry = -1;
AuctionList.selectedItem = nil;
AuctionList.items = {};

AuctionList.rows = {};
AuctionList.style = {
    rowHeight = 16
};
AuctionList.isBuying = false;
AuctionList.commodity = nil;
AuctionList.auction = nil;
AuctionList.waitingForSearch = false;

AuctionList.sortMode = {
    ["ppu"] = false,
    ["count"] = false,
    ["name"] = false,
    ["percent"] = false,
    ["iLevel"] = false,
    ["owner"] = false
};

AuctionList.lastSortMode = "percent";
AuctionList.lastBuyTry = time();

local clickCount = 0;
local clickTime = time();

local knownAuctions = {};

local function Hash(item)
    if (item.auctionId) then
        return tostring(item.auctionId);
    end
    return item.ppu.."."..item.count.."."..item.tsmId.."."..item.iLevel;
end

local function KnownKey(item)
    return item.tsmId.."."..item.iLevel.."."..item.suffix;
end

local function AddKnown(item)
    local hash = KnownKey(item);
    local auctionId = Hash(item);
    local known = knownAuctions[hash] or TempTable:Acquire();
    knownAuctions[hash] = known;
    known[auctionId] = item;
end

local function GetKnown(item)
    local hash = KnownKey(item);
    return knownAuctions[hash];
end

local function RemoveKnown(item)
    local hash = KnownKey(item);
    local known = knownAuctions[hash];

    if (not known) then
        return;
    end

    local auctionId = Hash(item);
    known[auctionId] = nil;
end

local function IsKnown(item)
    local hash = KnownKey(item);
    local auctionId = Hash(item);
    local known = knownAuctions[hash];

    if (not known) then
        return false;
    end

    return known[auctionId];
end

function AuctionList:Hash(item)
    return Hash(item);
end

function AuctionList:OnLoad(parent)
    self.parent = parent;
    self.buyNowFrame = _G["AnsSnipeBuy"];
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

function AuctionList:CheckAndPurchase(auction)
    if (auction and not auction.sniped) then
        local index = auction.itemIndex;

        if (not index 
            or not auction.name 
            or not auction.link
            or not auction.buyoutPrice
            or not auction.count) then
                return false;
        end

        local link = GetAuctionItemLink("list", index);
        if (link and auction.link == link) then
            local _,_, count,_,_,_,_,_,_,buyoutPrice, _,_, _, _,
            _, _, _, hasAllInfo = GetAuctionItemInfo("list", index);
            if (hasAllInfo and count == auction.count and buyoutPrice and
                buyoutPrice <= auction.buyoutPrice and GetMoney() >= buyoutPrice) then
                PlaceAuctionBid("list", index, buyoutPrice);
                auction.sniped = true;
                return true;
            end
        end
    end

    return false;
end

function AuctionList:ClassicPurchase(block)
    if (not block) then
        return false;
    end

    if (block.total and block.total <= 0) then
        return false;
    end

    if (#block.auctions <= 0) then
        return false;
    end

    local auction = block.auctions[1];
    if (not auction) then
        return false;
    end

    if (self:CheckAndPurchase(auction)) then
        tremove(block.auctions, 1);
        
        self:RemoveAuctionAmount(block, auction.count);

        if (auction ~= block) then
            Recycler:Recycle(auction);
        end
        return true;
    end

    return false;
end

function AuctionList:Buy(block, forcePurchase) 
    if (self.frame and block) then
        if (not self.isBuying and self.commodity == nil and self.auction == nil) then
            if (Utils.IsClassic()) then
                self:ClassicPurchase(block);
            else
                self:Purchase(block, forcePurchase);
            end
        end

        self.lastBuyTry = time();
    end
end

function AuctionList:IsSelectedSameAsLastId(id)
    if (self.frame and self.selectedItem) then
        return self.selectedItem.id == id;
    end
    return false;
end

function AuctionList:IsFirstSameAsLastId(id)
    if (self.frame and #self.items > 0) then
        return self.items[1].id == id;
    end
    return false;
end

function AuctionList:BuyFirst(forcePurchase) 
    if (self.frame and #self.items > 0) then
        self:Buy(self.items[1], forcePurchase);
        return true;
    end

    return false;
end

function AuctionList:BuySelected(forcePurchase)
    if (self.frame and self.selectedItem) then
        self:Buy(self.selectedItem, forcePurchase);
        return true;
    end

    return false;
end

function AuctionList:ItemsExist()
    return #self.items > 0;
end

function AuctionList:AddItems(items,clearNew)
    if (clearNew) then
        for i,v in ipairs(self.items) do
            v.isNew = false;
        end
    end

    for i,v in ipairs(items) do
        local c = v;
        c.isNew = true;
        AddKnown(c);
        tinsert(self.items, c);
    end 

    self:Sort(self.lastSortMode, true);
end

function AuctionList:IsKnown(item)
    return IsKnown(item);
end

function AuctionList:ClearMissing(item, current)
    local known = GetKnown(item);
    if (not known) then
        return;
    end

    for k,v in pairs(known) do
        if (v and not current[k]) then
            self:RemoveAuction(v);
        end
    end
end

function AuctionList:SetItems(items)
    wipe(self.items);
    for i,v in ipairs(items) do
        tinsert(self.items, v);
    end 
    self:Sort(self.lastSortMode, true);
end

function AuctionList:Purchase(block, forcePurchaseAuction)
    local b = block;

    if (self.commodity ~= nil) then
        return false, false;
    end

    if (block.auctionId ~= nil and not block.isCommodity) then
        if (GetMoney() >= block.buyoutPrice) then
            self.isBuying = true;
            self.auction = block;
            if (forcePurchaseAuction) then
                self.waitingForSearch = false;
                self:PurchaseAuction();
            else
                self.waitingForSearch = true;
            end
            return true, false;
        end
    elseif (block.auctionId == nil and block.isCommodity) then
        -- waiting for confirm is for item auctions only on retail
        -- commodities have their own states already for this
        self.waitingForSearch = false;

        if (Config.Sniper().useCommodityConfirm) then
            self.isBuying = true;
            self.commodity = block:Clone();
            self.auction = self.commodity;
            self.commodityConfirm:Show();
            return true, true;
        elseif (GetMoney() >= block.buyoutPrice) then
            self.isBuying = true;
            self.commodity = block:Clone();
            self.auction = block;
            self.commodity.toPurchase = self.commodity.count;
            self:PurchaseCommodity();
            return true, true;
        end
    end

    return false, false;
end

-- retail only
function AuctionList:PurchaseAuction()
    local block = self.auction;

    if (GetMoney() >= block.buyoutPrice) then
        C_AuctionHouse.PlaceBid(block.auctionId, block.buyoutPrice);
    else
        print("AnS - Not enough money to purchase auction");
    end
end

-- retail only
function AuctionList:ConfirmAuctionPurchase()
    local block = self.auction;
    if (not block) then
        return;
    end

    self:RemoveAuctionAmount(block, 1);
    self.auction = nil;
    self.isBuying = false;
    self:Refresh();
end

function AuctionList:Sort(t, noFlip)
    if (self.sortMode[t]) then
        table.sort(self.items, 
            function(x,y) 
                local xnew = x.isNew and 1 or 0;
                local ynew = y.isNew and 1 or 0;

                if (xnew == ynew) then
                    local xvalue = x[t];
                    local yvalue = y[t];

                    if (not xvalue or not yvalue) then
                        return false;
                    end

                    if (type(xvalue) == "table") then
                        xvalue = "Multiple";
                    end
                    if (type(yvalue) == "table") then
                        yvalue = "Multiple";
                    end

                    return xvalue > yvalue;
                end
                
                return xnew > ynew;
            end);
        if (not noFlip) then
            self.sortMode[t] = false;
        end
    else
        table.sort(self.items, 
            function(x,y)
                local xnew = x.isNew and 1 or 0;
                local ynew = y.isNew and 1 or 0;

                if (xnew == ynew) then              
                    local xvalue = x[t];
                    local yvalue = y[t];

                    if (not xvalue or not yvalue) then
                        return true;
                    end

                    if (type(xvalue) == "table") then
                        xvalue = "Multiple";
                    end
                    if (type(yvalue) == "table") then
                        yvalue = "Multiple";
                    end

                    return xvalue < yvalue;
                end
                
                return xnew > ynew;
            end);
        if (not noFlip) then
            self.sortMode[t] = true;
        end
    end
    self.lastSortMode = t;
    self:Refresh();
end

function AuctionList:PurchaseCommodity()
    if (self.commodity == nil or not self.commodity.toPurchase or self.commodity.toPurchase < 1) then
        self.auction = nil;
        self.commodity = nil;
        self.isBuying = false;

        return false;
    end
    
    if (self.commodity.toPurchase * self.commodity.ppu > GetMoney()) then
        print("AnS: Not enough gold to purchase "..total.." of "..self.commodity.name);
        
        self.auction = nil;
        self.commodity = nil;
        self.isBuying = false;

        return false;
    end
    
    self.removeListing = false;
    C_AuctionHouse.StartCommoditiesPurchase(self.commodity.id, self.commodity.toPurchase, self.commodity.ppu);
    return true;
end

-- the second boolean returned is whether to remove
-- the listing on cancel
function AuctionList:ConfirmCommoditiesPurchase()
    if (self.commodity == nil) then
        self.removeListing = false;
        return false;
    end

    if (self.commodityTotal > self.commodity.ppu * self.commodity.toPurchase) then
        print("AnS: Updated total price of commodities is higher than original total purchase price.");
        self.removeListing = true;
        return false;
    elseif (self.commodityPPU * self.commodity.toPurchase > GetMoney()) then
        print("AnS: You do not have enough gold to purchase everything at the updated price per unit!");
        self.removeListing = false;
        return false;
    end

    C_AuctionHouse.ConfirmCommoditiesPurchase(self.commodity.id, self.commodity.toPurchase);
    self.removeListing = false;
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
    self.auction = nil;
    self.commodity = nil;
end

function AuctionList:CancelCommoditiesPurchase()
    if (self.commodity == nil) then
        return;
    end

    self.isBuying = false;
    C_AuctionHouse.CancelCommoditiesPurchase();
    
    if (self.removeListing) then
        self:RemoveAuction(self.commodity);
    end

    self.removeListing = false;
    self.auction = nil;
    self.commodity = nil;
end

function AuctionList:Recycle()
    if (Utils.IsClassic()) then
        for i,v in ipairs(self.items) do
            if (v.auctions) then
                for k,c in ipairs(v.auctions) do
                    Recycler:Recycle(c);
                end
            else
                Recycler:Recycle(v);
            end
        end
    end

    self.selectedItem = nil;

    for k,v in pairs(knownAuctions) do
        v:Release();
    end

    wipe(knownAuctions);
    wipe(self.items);
    self:Refresh();
    self:ShowSelectedItem();
end

function AuctionList:RemoveAuctionAmount(block, count)
    local blockHash = Hash(block);

    -- finding block
    for i = 1, #self.items do
        local item = self.items[i];

        if (Hash(item) == blockHash and item.link == block.link) then
            if (not Utils.IsClassic()) then
                RemoveKnown(item);
            end
        
            if (Utils.IsClassic()) then
                item.total = item.total - count;
            else
                item.count = item.count - count;

                -- ensure block counts match on retail
                block.count = item.count;
            end

            -- for commodities
            if (not Utils.IsClassic() and item.count > 0) then
                AddKnown(item);
            end

            local isRecycled = false;
            if (Utils.IsClassic() and item.total <= 0) then
                isRecycled = true;
                Recycler:Recycle(tremove(self.items, i));
            elseif (not Utils.IsClassic() and item.count <= 0) then
                isRecycled = true;
                tremove(self.items, i);
            end

            if (isRecycled) then
                if (self.selectedEntry == i or item == self.selectedItem) then
                    self.selectedEntry = -1;
                    self.selectedItem = nil;
                    self:ShowSelectedItem();
                end
            end

            self:Refresh();
            return;
        end
    end 
end

function AuctionList:RemoveAuction(block) 
    local blockHash = Hash(block);

    -- finding block
    for i = 1, #self.items do
        local item = self.items[i];
        if (Hash(item) == blockHash and item.link == block.link) then
            RemoveKnown(item);

            if (Utils.IsClassic()) then
                Recycler:Recycle(tremove(self.items, i));
            else
                tremove(self.items, i);
            end

            if (self.selectedEntry == i or item == self.selectedItem) then
                self.selectedEntry = -1;
                self.selectedItem = nil;
                self:ShowSelectedItem();
            end

            self:Refresh();
            return;
        end
    end
end

function AuctionList:ShowSelectedItem()
    if (not self.selectedItem) then
        self.buyNowFrame:SetWidth(1);
        self.buyNowFrame:Hide();
    else
        local quality = self.selectedItem.quality;
        local texture = self.selectedItem.texture;
        local name = self.selectedItem.name;
        local count = self.selectedItem.count;
        local ppu = self.selectedItem.ppu;

        local total = ppu * count;

        local color = ITEM_QUALITY_COLORS[quality];
        self.buyNowFrame.Icon:SetTexture(texture);
        self.buyNowFrame.Name:SetText("stack of "..count.." "..color.hex..name);
        self.buyNowFrame.Price:SetText(Utils.PriceToString(total));

        self.buyNowFrame:SetWidth(168);

        self.buyNowFrame:Show();
    end
end

function AuctionList:Click(row, button, down) 
    local id = row:GetID();

    if(id ~= self.selectedEntry) then
        clickCount = 0;
    end

    self.selectedEntry = id;
    self.selectedItem = self.items[id];

    if (time() - clickTime > 2) then
        clickCount = 0;
    end

    if (IsShiftKeyDown() and not IsControlKeyDown()) then
        local block = self.items[id];

        if (block) then

            if (block.auctions and #block.auctions > 0) then
                for i,v in ipairs(block.auctions) do
                    Query:Blacklist(v);
                end
            else
                Query:Blacklist(block);
            end
            
            if (Utils.IsClassic()) then
                Recycler:Recycle(table.remove(self.items, id));
            else
                table.remove(self.items, id);
            end
        end

        self.selectedEntry = -1;
        self.selectedItem = nil;
        clickCount = 0;
    elseif (IsShiftKeyDown() and IsControlKeyDown()) then
        local block = self.items[id];

        if (block) then
            Config.Sniper().itemBlacklist[block.tsmId] = block.link;
            
            if (Utils.IsClassic()) then
                Recycler:Recycle(table.remove(self.items, id));
            else
                table.remove(self.items, id);
            end
        end

        self.selectedEntry = -1;
        self.selectedItem = nil;
        clickCount = 0;
    end

    if (Config.General().showDressing and self.selectedItem) then
        local block = self.selectedItem;

        if (block) then
            local itemLink = block.link;
            if (not block.isCommodity and not block.isPet) then
                DressUpItemLink(itemLink)
            end
        end
    end

    clickCount = clickCount + 1;
    clickTime = time();

    if (clickCount > 1) then
        AuctionSnipe:BuySelected();
        clickCount = 0;
    end

    self:Refresh();
    self:ShowSelectedItem();
end

function AuctionList:ShowTip(item)
    local index = item:GetID();
    if (self.items[index]) then
        local auction = self.items[index];
        if (auction ~= nil) then
            local itemLink = auction.link;
            local count = auction.count;
            if (itemLink ~= nil) then
                Utils.ShowTooltip(item, itemLink, count);
            end
        end
    end
end

function AuctionList:UpdateRow(offset, row)
    if (offset <= #self.items) then
        if (not self.items[offset] 
            or not self.items[offset].name
            or not self.items[offset].count
            or not self.items[offset].id
            or not self.items[offset].ppu) then
                row:Hide();
                return;
        end

        row:SetID(offset);
        row.item = self.items[offset];

        local auction = self.items[offset];
        local itemKey = auction.itemKey;

        local owner = auction.owner;
        local ppu = auction.ppu;
        local itemID = auction.id;
        local ilevel = auction.iLevel;
        local percent = auction.percent;
        local count = auction.total or auction.count;

        local texture = auction.texture;
        local quality = auction.quality;
        local name = auction.name;

        local itemPrice = _G[row:GetName().."PPU"];
        local itemName = _G[row:GetName().."NameText"];
        local itemOwner = _G[row:GetName().."Owner"];
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
        itemPrice:SetText(Utils.PriceToString(ppu));    
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

        if (row.item.isNew) then
            row.NewHighlight:Show();
        else
            row.NewHighlight:Hide();
        end

        if (row.item == self.selectedItem) then
            row:SetButtonState("PUSHED", true);
        else
            row:SetButtonState("NORMAL", false);
        end

        if (type(owner) == "table") then
            itemOwner:SetText("Multiple");
        else
            itemOwner:SetText(owner);
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

