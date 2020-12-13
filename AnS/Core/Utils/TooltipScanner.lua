local Ans = select(2, ...);
local TooltipScanner = Ans.Object.Register("TooltipScanner");

function TooltipScanner:Init()
    if (not self.frame) then
        self.frame = CreateFrame("GameTooltip", "AnsTooltipScanner", UIParent, "GameTooltipTemplate");
    end
end

function TooltipScanner:Clear()
    self:Init();
    self.frame:SetOwner(UIParent, "ANCHOR_NONE");
    self.frame:ClearLines();
end

function TooltipScanner:SetBagSlot(bag, slot)
    if (not self.frame) then
        return;
    end
    
    if (bag == BANK_CONTAINER) then
        self.frame:SetInventoryItem("player", bag, slot + BankButtonIDToInvSlotID(0));
    elseif (REAGENTBANK_CONTAINER and bag == REAGENTBANK_CONTAINER) then
        self.frame:SetInventoryItem("player", bag, slot + ReagentBankButtonIDToInvSlotID(0));
    else
        self.frame:SetBagItem(bag, slot);
    end
end

function TooltipScanner:IsSoulbound(bag, slot)
    self:Clear();
    self:SetBagSlot(bag, slot);
    local numLines = self.frame:NumLines();
    if (numLines < 1) then
        return false;
    end

    for id = 1, numLines do
        local textObject = _G["AnsTooltipScannerTextLeft"..id];
        local text = strtrim(textObject and textObject:GetText() or "");

        if ((text == ITEM_BIND_ON_PICKUP and id < 4) or text == ITEM_SOULBOUND or text == ITEM_BIND_QUEST) then
            return true;
        elseif (text == ITEM_ACCOUNTBOUND or text == ITEM_BIND_TO_ACCOUNT or text == ITEM_BIND_TO_BNETACCOUNT or text == ITEM_BNETACCOUNTBOUND) then
            return true;
        end
    end

    return false;
end