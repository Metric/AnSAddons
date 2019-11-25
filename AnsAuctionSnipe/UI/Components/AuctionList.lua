local Ans = select(2, ...);
local AuctionList = {};
AuctionList.__index = AuctionList;

Ans.AuctionList = AuctionList;

local Recycler = AnsCore.API.Recycler;
local Utils = AnsCore.API.Utils;

AuctionList.selectedEntry = -1;
AuctionList.items = {};
AuctionList.buying = false;
AuctionList.isWaitingForData = false;
AuctionList.queryId = 0;
AuctionList.queryRef = nil;
AuctionList.queryDelay = 0;

AuctionList.WAITING_FOR_RESULTS = "WAITING";
AuctionList.QUERY_ID = "ID";
AuctionList.QUERY_OBJECT = "QUERY";
AuctionList.rows = {};
AuctionList.style = {
    rowHeight = 16
};

local stepTime = 1;
local clickTime = time();
local clickCount = 0;

function AuctionList:OnLoad(parent)
    self.parent = parent;
    self.frame = _G[parent:GetName().."Items"];

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

function AuctionList:CheckAndPurchase(index, auction)
    if (auction and not auction.sniped) then
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

function AuctionList:Purchase(block)
    if (block) then
        local fps = math.floor(GetFramerate());

        self.queryDelay = self.queryDelay + fps;
        self.queryDelay = math.min(self.queryDelay, fps * ANS_GLOBAL_SETTINGS.safeDelay);

        local orig = block.item;
        local auction = block.item;
        local index = block.index;
        local left = 0;

        local total = #auction.group;
        local i;

        if (block.queryId ~= self.queryId or self.isWaitingForData) then
            return false;
        end

        if (not auction.sniped and total == 0) then
            if (self:CheckAndPurchase(index, auction)) then
                return true;
            else
                return false;
            end
        elseif (not auction.sniped) then
            self:CheckAndPurchase(index, auction);
        else
            for i = 1, total do
                local subblock = orig.group[i];
                auction = subblock.item;
                index = subblock.index;

                if (auction and not auction.sniped) then
                    -- just an extra check for precaution
                    -- even though technically both the main block
                    -- and sub blocks are from the same query id
                    if (subblock.queryId ~= self.queryId or self.isWaitingForData) then
                        return false;
                    end

                    if (self:CheckAndPurchase(index, auction)) then
                        break;
                    end
                end
            end
        end

        for i = 1, total do
            local subblock = orig.group[i];
            if (not subblock.item.sniped) then
                left = left + 1;
            end 
        end

        return orig.sniped and left == 0; 
    end

    return false;
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

    self.queryDelay = self.queryDelay + fps;
    self.queryDelay = math.min(self.queryDelay, fps * ANS_GLOBAL_SETTINGS.safeDelay);

    if (clickCount == 1 and IsShiftKeyDown()) then
        local block = self.items[id];

        if (block) then
            if (self.queryRef) then
                self.queryRef:AddToBlacklist(block.item);
                Recycler:RecycleBlock(table.remove(self.items, id));
            end
        end

        self.selectedEntry = -1;
        clickCount = 0;
    elseif (clickCount == 1 and IsControlKeyDown()) then
        local block = self.items[id];

        if (block) then
            if (self.queryRef) then
                self.queryRef:AddAllToBlacklist(block.item);
                Recycler:RecycleBlock(table.remove(self.items, id));
            end
        end

        self.selectedEntry = -1;
        clickCount = 0;
    end

    if (clickCount == 1 and ANS_GLOBAL_SETTINGS.showDressing) then
        local block = self.items[id];

        if (block) then
            if (not DressUpItemLink(block.item.link)) then
                DressUpBattlePet(GetAuctionItemBattlePetInfo("list", block.index));
            end
        end
    end

    if (clickCount >= 2) then
        self.buying = true;
        --buy it instantly

        local block = self.items[id];
        if (block) then
            if (self:Purchase(block)) then
                Recycler:RecycleBlock(table.remove(self.items, id));
                if (self.selectedEntry == id) then
                    self.selectedEntry = -1;
                end
            end
        end
        clickCount = 0;
        self.buying = false;
    end

    self:Refresh();
    clickTime = time();
end

function AuctionList:ShowTip(item)
    local index = item:GetID();
    if (self.items[index]) then
        local auction = self.items[index].item;
        if (auction ~= nil) then
            if (auction.link ~= nil) then
                Utils:ShowTooltip(item, auction.link, auction.count);
            end
        end
    end
end

function AuctionList:SetStatus(status, val)
    if (status == AuctionList.WAITING_FOR_RESULTS) then
        self.isWaitingForData = val;
    elseif (status == AuctionList.QUERY_ID) then
        self.queryId = val;
    elseif (status == AuctionList.QUERY_OBJECT) then
        self.queryRef = val;
    end
end

function AuctionList:UpdateDelay()
    self.queryDelay = self.queryDelay - stepTime;
    self.queryDelay = math.max(self.queryDelay, 0);
end

function AuctionList:UpdateRow(offset, row)
    if (offset <= #self.items) then
        if (not self.items[offset]) then
            row:Hide();
            return;
        end

        row:SetID(offset);

        local auction = self.items[offset].item;
        local name = auction.name;
        local ppu = auction.ppu;
        local price = auction.buyoutPrice;
        local count = auction.count;
        local total = #auction.group;
        local percent = auction.percent;
        local owner = auction.owner;
        local i;

        local realTotal = 0;

        if (not auction.sniped) then
            realTotal = realTotal + 1;
        end

        for i = 1, total do
            local sub = auction.group[i];
            if (not sub.item.sniped) then
                realTotal = realTotal + 1;
            end
        end

        local itemPrice = _G[row:GetName().."PPU"];
        local itemName = _G[row:GetName().."NameText"];
        local itemStack = _G[row:GetName().."StackPrice"];
        local itemPercent = _G[row:GetName().."Percent"];
        local itemIcon = _G[row:GetName().."ItemIcon"];
        local itemLevel = _G[row:GetName().."ILevel"];

        itemLevel:SetText(auction.iLevel);
        itemStack:SetText(owner or "?");
        itemPercent:SetText(percent.."%");

        local color = ITEM_QUALITY_COLORS[auction.quality];
        itemName:SetText(realTotal.." stack of "..count.." "..color.hex..name);

        itemPrice:SetText(Utils:PriceToString(ppu));

        if (auction.texture ~= nil) then
            itemIcon:SetTexture(auction.texture);
            itemIcon:Show();
        else
            itemIcon:Hide();
        end

        if (percent >= 100) then
            itemPercent:SetTextColor(1,0,0);
        elseif (percent >= 75) then
            itemPercent:SetTextColor(1,1,1);
        elseif (percent >= 50) then
            itemPercent:SetTextColor(0,1,0);
        else
            itemPercent:SetTextColor(0,0.5,1);
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

