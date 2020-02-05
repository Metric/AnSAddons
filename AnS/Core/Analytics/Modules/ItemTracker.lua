local Ans = select(2, ...);

local Utils = Ans.Utils;

local ItemTracker = { log = {}, name = nil};
local guildOpen = false;

ItemTracker.__index = ItemTracker;
Ans.Analytics.ItemTracker = ItemTracker;

local EventManager = Ans.EventManager;
local Data = Ans.Analytics.Data;
local ITEMS_TAG = "ITEMS_";

local bankFrameOpen = false;
local guildVaultOpen = false;

local INVENTORY = "Inventory";
local BANK = "Bank";
local GUILD = "Guild";

function ItemTracker:OnLoad()
    ITEMS_TAG = ITEMS_TAG..GetRealmName();

    self.log = Data:Get(ITEMS_TAG) or {};
    self.name = UnitName("player").." - "..UnitFactionGroup("player");
    if (not self.log[self.name]) then self.log[self.name] = {}; end;
    --self.guildName = GetGuildInfo("player");
    --if (self.guildName and not self.log[self.guildName]) then self.log[self.guildName] = {}; end;

    EventManager:On("BAG_UPDATE_DELAYED", self.OnBagUpdate);
	if (BattlePetTooltip) then
		EventManager:On("GUILDBANKFRAME_OPENED", self.OnGuildVaultOpened);
		EventManager:On("GUILDBANKFRAME_CLOSED", self.OnGuildVaultClosed)
		EventManager:On("REAGENTBANK_UPDATE", self.OnReagentUpdate);
    end
    EventManager:On("BANKFRAME_OPENED", self.OnBankFrameOpened);
    EventManager:On("BANKFRAME_CLOSED", self.OnBankFrameClosed);

    EventManager:On("PLAYER_ENTERING_WORLD", self.OnPlayerWorld);
end

function ItemTracker:GetNames(tbl)
    wipe(tbl);

    for k,v in pairs(self.log) do
        tinsert(tbl, k);
    end
end

function ItemTracker:Get(name)
    return self.log[name];
end

function ItemTracker.OnBankFrameOpened()
    -- scan bank
    bankFrameOpen = true;
    ItemTracker:ScanBags(BANK);
end

function ItemTracker.OnBankFrameClosed()
    bankFrameOpen = false;
end

function ItemTracker.OnBagUpdate()
    ItemTracker:ScanBags(BANK);
    ItemTracker:ScanBags(INVENTORY);
end

function ItemTracker.OnGuildVaultOpened()
    guildVaultOpen = true;
end

function ItemTracker.OnGuildVaultClosed()
    guildVaultOpen = false;
end

function ItemTracker.OnReagentUpdate()
    ItemTracker:ScanBags(BANK);
end

function ItemTracker.OnPlayerWorld()
    ItemTracker:ScanBags(INVENTORY);
end

function ItemTracker.IsSoulBound(bag, slot, link)
    local boundType = select(14, GetItemInfo(link));
    return Utils:IsSoulBound(bag, slot) or boundType == 1 or boundType == 4;
end

function ItemTracker:ScanBags(type)
    local log = self.log[self.name];
    local container = log[type] or {};

    -- reset it as we only keep track of current for items
    wipe(container);

    if (type == BANK) then
        local BANK_NUM_SLOTS = GetContainerNumSlots(BANK_CONTAINER);
        for i = 1, BANK_NUM_SLOTS do
            local link = GetContainerItemLink(BANK_CONTAINER, i);
            local _, count = GetContainerItemInfo(BANK_CONTAINER, i);
            if (link and count) then
                local id = Utils:GetTSMID(link);
                local prev = container[id] or {link = link, count = 0};
                prev.count = prev.count + count;
                container[id] = prev;
            end
        end

        if (BattlePetTooltip) then
            local REAGENT_NUM_SLOTS = GetContainerNumSlots(REAGENTBANK_CONTAINER);
            for i = 1, REAGENT_NUM_SLOTS do
                local link = GetContainerItemLink(REAGENTBANK_CONTAINER, i);
                local _, count = GetContainerItemInfo(REAGENTBANK_CONTAINER, i);
                if (link and count) then
                    local id = Utils:GetTSMID(link);
                    local prev = container[id] or {link = link, count = 0};
                    prev.count = prev.count + count;
                    container[id] = prev;
                end
            end
        end

        for i = NUM_BAG_SLOTS + 1, NUM_BAG_SLOTS + NUM_BANKBAGSLOTS do
            local slots = GetContainerNumSlots(i);
            for k = 1, slots do
                local link = GetContainerItemLink(i, k);
                local _, count = GetContainerItemInfo(i, k);
                if (link and count) then
                    local id = Utils:GetTSMID(link);
                    local prev = container[id] or {link = link, count = 0};
                    prev.count = prev.count + count;
                    container[id] = prev;
                end
            end
        end
    elseif (type == INVENTORY) then
        for i = 0, NUM_BAG_SLOTS do
            local slots = GetContainerNumSlots(i);
            for k = 1, slots do
                local link = GetContainerItemLink(i, k);
                local _, count = GetContainerItemInfo(i, k);
                if (link and count) then
                    local id = Utils:GetTSMID(link);
                    local prev = container[id] or {link = link, count = 0};
                    prev.count = prev.count + count;
                    container[id] = prev;
                end
            end
        end
    end

    log[type] = container;
    Data:Set(ITEMS_TAG, self.log);
end


EventManager:On("VARIABLES_LOADED", 
    function()
        ItemTracker:OnLoad();
    end
);