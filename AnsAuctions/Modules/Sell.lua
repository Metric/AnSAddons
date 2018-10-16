local Ans = select(2, ...);

local BagScanner = AnsCore.API.BagScanner;
local Query = AnsCore.API.Query;
local Sources = AnsCore.API.Sources;
local Utils = AnsCore.API.Utils;
local TreeView = AnsCore.API.UI.TreeView;

local AuctionSell = {};
AuctionSell.__index = AuctionSell;
AuctionSell.isInited = false;
AuctionSell.waitingForResult = false;
AuctionSell.scanning = false;
AuctionSell.sortHow = Query.SORT_METHODS.PRICE;
AuctionSell.sortAsc = true;
AuctionSell.query = Query:New("");

Ans.AuctionSell = AuctionSell;

local selected = nil;
local selectedChild = nil;
local itemQueue = {};
local items = {};
local scanIndex = 1;
local clickTime = time();
local clickCount = 0;
local clearTime = time();
local scanningItem = nil;

local numberOfPages = 4;

function AuctionSell:Init()
    local d = self;
    if (isInited) then
        return;
    end

    self.isInited = true;

    local frame = CreateFrame("FRAME", "AnsAuctionSellMainPanel", AuctionFrame, "AnsAuctionSellTemplate");
    self.frame = frame;

    AnsCore:AddAHTab("AnsSell",
        function()
            AuctionSell:Show();
        end,
        function()
            AuctionSell:Close();
        end
    );

    self.treeView = TreeView:New(_G[frame:GetName().."Auctions"], {
        rowHeight = 20,
        childIndent = 16,
        template = "AnsAuctionTreeRowTemplate"
    },
        function(item)
            d:RowClick(item);
        end,
        nil, nil,
        function(row, item)
            d:RenderRow(row, item);
        end
    );

    self.statusText = _G[frame:GetName().."BottomBarStatus"];
    self.pagesEntry = _G[frame:GetName().."SearchBarPages"];

    frame:Hide();
end

function AuctionSell.ShowTip(row)
    local item = row.item;

    if (item) then
        local auction = item;

        if (auction.link ~= nil) then
            Utils:ShowTooltip(row, auction.link, auction.count);
        end
    end
end

function AuctionSell:RenderRow(row, item)
    row:SetScript("OnEnter", AuctionSell.ShowTip);
    row:SetScript("OnLeave", Utils.HideTooltip);

    local name = _G[row:GetName().."Text"];
    local icon = _G[row:GetName().."ItemIcon"];
    local level = _G[row:GetName().."Level"];
    local posts = _G[row:GetName().."Posts"];
    local stack = _G[row:GetName().."Stack"];
    local seller = _G[row:GetName().."Seller"];
    local ppu = _G[row:GetName().."PPU"];
    local percent = _G[row:GetName().."Percent"];

    local color = ITEM_QUALITY_COLORS[item.quality];
    name:SetText(color.hex..item.name);
    stack:SetText(item.count);

    if (item.children) then
        if (item.tex) then
            icon:SetTexture(item.tex);
            icon:Show();
        else
            icon:Hide();
        end
        level:SetText("");
        posts:SetText("");
        seller:SetText("");
        ppu:SetText("");
        percent:SetText("");
    elseif (not item.children or item.parent) then
        local auction = item;

        if (auction.texture) then
            icon:SetTexture(auction.texture);
            icon:Show();
        else
            icon:Hide();
        end

        level:SetText(auction.iLevel);
        
        local realCount = auction.total;

        posts:SetText(realCount);
        stack:SetText(auction.count);
        seller:SetText(auction.owner or "?");
        ppu:SetText(Utils:PriceToString(auction.ppu));
        percent:SetText(auction.percent.."%");

        if (auction.percent >= 100) then
            percent:SetTextColor(1,0,0);
        elseif (auction.percent >= 75) then
            percent:SetTextColor(1,1,1);
        elseif (auction.percent >= 50) then
            percent:SetTextColor(0,1,0);
        else
            percent:SetTextColor(0,0.5,1);
        end
    end
end

function AuctionSell:OnUpdate()
    if (self.frame and self.frame:IsShown() and self.scanning) then
        if (not self.waitingForResult) then
            if (self.query:IsReady()) then
                self.query:Search(0, true);
                self.waitingForResult = true;
            end
        end
    end

    -- this is the only way to prevent the default auctions
    -- UI list showing
    if (self.frame and self.frame:IsShown()) then
        local i;
        for i = 1, 9 do
            _G["AuctionsButton"..i]:Hide();
        end
        AuctionsScrollFrame:Hide();
        self:HideDefaultUI();
        clearTime = time();
    end
end

function AuctionSell:OnAuctionHouseClosed()
    self:Close();
end

function AuctionSell:OnAuctionUpdate()
    if (self.frame and self.frame:IsShown() and self.scanning) then
        if (self.waitingForResult) then
            local index = self.query.index;
            if (index == 0) then
                -- create a new auction table
                -- so the scan results are preserved
                -- for the previous scan in the item.children
                self.query.auctions = {};
            end

            self.query:CaptureLight();

            local item = items[scanIndex];

            if (item and item == scanningItem) then
                item.children = self.query:Items(self.sortHow, self.sortAsc);
                self:RefreshView();
            end

            if (index < numberOfPages - 1 and not self.query:IsLastPage() and item == scanningItem) then
                self.query:Next();
                index = self.query.index;

                self.statusText:SetText(self.query.search.." page: "..(index + 1));
            else
                if (#itemQueue > 0 and scanningItem == item) then
                    local idx = tremove(itemQueue, 1);
                    local nitem = items[idx];

                    item.scanned = true;
                    scanningItem = nitem;

                    if (nitem) then
                        self.query:Set(nitem.name);
                        index = self.query.index;
                        scanIndex = idx;
                        self.statusText:SetText(self.query.search.." page: "..(index + 1));
                    else
                        self:StopScan();
                        self.statusText:SetText("Invalid Item For Scan. Scan Stopped.");
                    end
                else
                    self:StopScan();
                    self.statusText:SetText("Scan Complete");
                end
            end

            self.waitingForResult = false;
        end
    end 
end

function AuctionSell:GetSelectedIndex()
    if (not selected) then
        return -1;
    end

    for i,v in ipairs(items) do
        if (v == selected) then
            return i;
        end
    end

    return -1;
end

function AuctionSell:SetItem(item)
    selected = item;

    -- pickup and set on auctionitemsbutton
    local aName, _, aCount = GetAuctionSellItemInfo();

    if (aName ~= item.name or aCount ~= item.count) then
        PickupContainerItem(item.bag, item.slot);
        ClickAuctionSellItemButton(AuctionsItemButton, "LeftButton");
        self:HideDefaultUI();
        ClearCursor();
    end

    if (not item.scanned) then
        self:ScanSelected();
    end

    -- set price from pricing source
    local t = Utils:GetTable();
        
    -- create temporary for getting price from
    -- our price source percentfn
    t.link = item.link;
    t.count = item.count;
    t.buyoutPrice = 0;
    t.quality = item.quality;
    t.iLevel = 0;
    t.percent = 0;
    t.ppu = 0;
    t.vendorsell = 0;

    local d = Sources:Query(ANS_GLOBAL_SETTINGS.percentFn, t);
    
    if (not d) then
        d = 0;
    end

    Utils:ReleaseTable(t);

    MoneyInputFrame_SetCopper(BuyoutPrice, d);
end

function AuctionSell:PostSelected()
    if(selected and selected.children) then
        local copper = MoneyInputFrame_GetCopper(BuyoutPrice);
        self:Sell(selected, copper);
    end
end

function AuctionSell:RowClick(item)
    if (time() - clickTime > 1) then
        clickCount = 0;
    end

    clickCount = clickCount + 1;

    if (item and item.children) then
        if (selected ~= item) then
            self:SetItem(item);
        end
    elseif (item and item.parent) then
        local os = item.parent;
        if (selected ~= os) then
            self:SetItem(os);
        end
        
        selectedChild = item;
        MoneyInputFrame_SetCopper(BuyoutPrice, item.ppu);
    end

    if (clickCount == 2 and item and not item.children) then
        if (item.parent and item.parent == selected) then
            -- this is a shortcut to sell for this price
            self:Sell(item.parent, item.ppu);
        end
        clickCount = 0;
    end

    self:RefreshView();

    clickTime = time();
end

function AuctionSell:RestoreDefaultUI()
    AuctionsBidSort:Show();
    AuctionsHighBidderSort:Show();
    AuctionsDurationSort:Show();
    AuctionsQualitySort:Show();
    StartPrice:Show();
    AuctionsCloseButton:Show();
    AuctionsCancelAuctionButton:Show();
    AuctionsCreateAuctionButton:Show();
end

function AuctionSell:HideDefaultUI()
    AuctionsBidSort:Hide();
    AuctionsHighBidderSort:Hide();
    AuctionsDurationSort:Hide();
    AuctionsQualitySort:Hide();
    PriceDropDown:Hide();
    StartPrice:Hide();
    AuctionsWowTokenAuctionFrame:Hide();
    AuctionsCloseButton:Hide();
    AuctionsCancelAuctionButton:Hide();
    AuctionsCreateAuctionButton:Hide();
    AuctionsBlockFrame:Hide();
end

function AuctionSell:Sell(item, ppu)
    -- validate the desired auction is in the sell slot
    local aName, _, aCount = GetAuctionSellItemInfo();
    if (aName ~= item.name or aCount ~= item.count) then
        return;
    end

    if (ppu <= 0) then
        return;
    end

    -- get auction house post time settings
    local time = UIDropDownMenu_GetSelectedID(DurationDropDown);

    local stackSize = item.count;
    local numStacks = 1;
    local totalAvailable = AuctionsItemButton.totalCount or 0;
    local totalStackCount = AuctionsItemButton.stackCount or 0;

    if (AuctionsNumStacksEntry:IsShown()) then
        numStacks = AuctionsNumStacksEntry:GetNumber();
    end

    if (AuctionsStackSizeEntry:IsShown()) then
        stackSize = AuctionsStackSizeEntry:GetNumber();
    end

    if (numStacks <= 0) then
        numStacks = 1;
    end

    if (stackSize <= 0) then 
        stackSize = 1;
    end

    -- stack size larger than available do nothing
    if (stackSize > totalStackCount) then
        return;
    end

    local totalPosting = numStacks * stackSize;

    -- make sure the totalPosting is actually available
    if (totalPosting > totalAvailable) then
        return;
    end

    local copper = stackSize * ppu;
    local icount = item.count;

    PostAuction(copper, copper, time, stackSize, numStacks);

    item.count = item.count - totalPosting;

    if (item.count <= 0) then
        item.count = 0;
        self:RemoveItem(item);
    end

    if (totalPosting > icount) then
        local diff = totalPosting - icount;

        -- find the other items in the inventory that match the current one
        while (diff > 0) do
            local other = self:FindSimilar(item);
            if (not other) then
                break;
            end

            if (diff >= other.count) then
                diff = diff - other.count;
                other.count = 0;
                self:RemoveItem(other);
            else
                other.count = other.count - diff;
                diff = 0;
            end
        end
    end

    self:HideDefaultUI();
    self:RefreshView();
end

function AuctionSell:FindSimilar(item)
    for i,v in ipairs(items) do
        if (not v.hidden) then
            if (v.name == item.name and v.count > 0 and v ~= item) then
                return v;
            end
        end
    end

    return nil;
end

function AuctionSell:ScanSelected()
    numberOfPages = self.pagesEntry:GetNumber() or 4;
    local idx = self:GetSelectedIndex();

    if (idx == -1) then
        return;
    end

    for i, v in ipairs(itemQueue) do
        if (v == idx) then
            return;
        end
    end

    tinsert(itemQueue, idx);

    if (#itemQueue == 1 and not self.scanning) then
        -- set default sort based
        -- on unitprice
        -- this snippet is modified
        -- based on actual blizzard 
        -- auctionhouseui code

        SortAuctionClearSort("list");
        for i, r in pairs(AuctionSort["list_unitprice"]) do
            SortAuctionSetSort("list", r.column, r.reverse);
        end

        scanIndex = tremove(itemQueue, 1);
        scanningItem = items[scanIndex];
        self.query:Set(scanningItem.name);
        self.waitingForResult = false;
        self.scanning = true;
    end
end

function AuctionSell:RemoveItem(item)
    item.hidden = true;

    if (selected == item) then
        selected = nil;
        selectedChild = nil;
    end
end

function AuctionSell:RefreshView()
    for i, v in ipairs(items) do
        v.selected = v == selected;

        if (v.children and #v.children > 0) then
            for i1, v2 in ipairs(v.children) do
                -- make sure child to parent exists
                v2.parent = v;
                -- always set selected to false
                v2.selected = v2 == selectedChild and v2.parent == selected;
            end
        end
    end

    self.treeView.items = items;
    self.treeView:Refresh();
end

function AuctionSell:StopScan()
    self.waitingForResult = false;
    self.scanning = false;
    self.query.auctions = {};
    self.query:Reset();
end

function AuctionSell:Show()
    -- scan bags real quick
    self.frame:Show();

    AuctionFrameMoneyFrame:Show();
    AuctionFrameBrowse:Hide();
    AuctionFrameBid:Hide();

    AuctionFrameTopLeft:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Auction-TopLeft");
    AuctionFrameTop:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Auction-Top");
    AuctionFrameTopRight:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Auction-TopRight");
    AuctionFrameBotLeft:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Auction-BotLeft");
    --AuctionFrameBot:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Auction-Bot");
    --AuctionFrameBotRight:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Auction-BotRight");

    AuctionFrameBotRight:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Bid-BotRight");
    AuctionFrameBot:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Auction-Bot");

    AuctionFrameAuctions:Show();

    self:HideDefaultUI();
    self:ScanBags();
end

function AuctionSell:ScanBags()
    if (not self.scanning) then
        BagScanner:Scan();
        items = BagScanner:GetAuctionable();

        -- update tree view
        self:RefreshView();
    end
end

function AuctionSell:Close()
    if (self.frame:IsShown()) then
        self.frame:Hide();

        self:StopScan();
        wipe(itemQueue);
        items = nil;
        BagScanner:Release();

        self:RestoreDefaultUI();

        self.treeView:ReleaseView();
    end
end