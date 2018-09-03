AnsSnipeAuctionList = {};
AnsSnipeAuctionList.__index = AnsSnipeAuctionList;
AnsSnipeAuctionList.selectedEntry = -1;
AnsSnipeAuctionList.items = {};
AnsSnipeAuctionList.buying = false;

local clickTime = time();
local clickCount = 0;

function AnsSnipeAuctionListRefresh() 
    AnsSnipeAuctionList:Refresh();
end

function AnsSnipeAuctionList:ShowLineTip(item)
    local index = item:GetID();
    local auction = self.items[index].item;
    if (auction ~= nil) then
        if (auction.link ~= nil) then
            GameTooltip:SetOwner(item, "ANCHOR_RIGHT");

            if (AnsUtils:IsBattlePetLink(auction.link)) then
                AnsUtils:ShowBattlePetTip(auction.link);
            else
                GameTooltip:SetHyperlink(auction.link, auction.count);
                GameTooltip:Show();
            end
        end
    end
end

function AnsSnipeAuctionList:Click(item, button, down)
    local id = item:GetID();

    if (time() - clickTime > 1) then
        clickCount = 0;
    end

    if (self.selectedEntry ~= id) then
        clickCount = 0;
    end

    self.selectedEntry = id; 

    clickCount = clickCount + 1;

    if (clickCount == 2) then
        self.buying = true;
        --buy it instantly

        local block = self.items[id];
        local auction = block.item;
        local index = block.index;

        if (GetMoney() >= auction.buyoutPrice) then  
            if (self.selectedEntry == id) then
                self.selectedEntry = -1;
            end
        
            table.remove(self.items, id);

            PlaceAuctionBid("list", index, auction.buyoutPrice);
        else
            print("You do not have enough gold to buy that");
        end

        self.buying = false;
    end

    self:Refresh();
    clickTime = time();
end

function AnsSnipeAuctionList:HideLineTip()
    GameTooltip:Hide();
    BattlePetTooltip:Hide();
end

---
-- Updates actual row view
---
function AnsSnipeAuctionList:UpdateRow(dataOffset, line)
    local lineEntry = _G["AnsSnipeAuction"..line];
    lineEntry:SetID(dataOffset);

    if(dataOffset <= #self.items) then
        local auction = self.items[dataOffset].item;
        local name = auction.name;
        local ppu = auction.ppu;
        local price = auction.buyoutPrice;
        local count = auction.count;
        local percent = auction.percent;
        local owner = auction.owner;


        local lineEntry_itemPrice = _G[lineEntry:GetName().."PerItemPrice"];
        local lineEntry_itemText = _G[lineEntry:GetName().."PerItemText"];
        local lineEntry_itemName = _G[lineEntry:GetName().."NameText"]; 
        local lineEntry_itemStack = _G[lineEntry:GetName().."StackPrice"];
        local lineEntry_itemPercent = _G[lineEntry:GetName().."Percent"];
        local lineEntry_itemIcon = _G[lineEntry:GetName().."ItemIcon"];

        lineEntry_itemText:SetText("");
        lineEntry_itemName:SetText("");
        lineEntry_itemStack:SetText("");
        lineEntry_itemPercent:SetText("");

        if (price == 0) then
            lineEntry_itemPrice:Hide();
            lineEntry_itemText:Show();
            lineEntry_itemText:SetText("no buyout price");
        else
            lineEntry_itemPrice:Show();
            MoneyFrame_Update(lineEntry:GetName().."PerItemPrice", ppu);
            lineEntry_itemText:Hide();
        end

        lineEntry_itemStack:SetText(AnsUtils:PriceToString(price));
        lineEntry_itemStack:SetTextColor(0.6,0.6,0.6);

        lineEntry_itemPercent:SetText(percent.."%");

        local color = ITEM_QUALITY_COLORS[auction.quality];
        lineEntry_itemName:SetText("("..count..") "..name);
        lineEntry_itemName:SetTextColor(color.r,color.g,color.b);

        if (auction.texture ~= nil) then
            lineEntry_itemIcon:SetTexture(auction.texture);
            lineEntry_itemIcon:Show();
        else
            lineEntry_itemIcon:Hide();
        end

        if (percent >= 100) then
            lineEntry_itemPercent:SetTextColor(1,0,0);
        elseif (percent >= 75) then
            lineEntry_itemPercent:SetTextColor(1,1,1);
        elseif (percent >= 50) then
            lineEntry_itemPercent:SetTextColor(0,1,0);
        else
            lineEntry_itemPercent:SetTextColor(0,0.5,1);
        end

        if (dataOffset == self.selectedEntry) then
            lineEntry:SetButtonState("PUSHED", true);
        else
            lineEntry:SetButtonState("NORMAL", false);
        end

        lineEntry:Show();
    else
        lineEntry:Hide();
    end
end

----
-- Virtual Scroll Handler
----
function AnsSnipeAuctionList:Clear()
    if(_G["AnsSnipeMainPanel"]:IsShown())then
        local line;
        for line = 1, 15 do
            local entry = _G["AnsSnipeAuction"..line];
            if (entry ~= nil) then
                entry:Hide();
            end
        end
    end
end

function AnsSnipeAuctionList:Refresh()
    self:Clear();

    local line;
    local dataOffset;

    FauxScrollFrame_Update(AnsSnipeScrollFrame, #self.items, 15, 16);

    local offset = FauxScrollFrame_GetOffset(AnsSnipeScrollFrame);

    for line = 1, 15 do
        dataOffset = line + offset;
        self:UpdateRow(dataOffset, line);
    end
end

function AnsSnipeAuctionList:SetItems(items)
    self.items = items;
    self:Refresh();
end