local Ans = select(2, ...);
local TextInput = Ans.UI.TextInput;
local Config = Ans.Config;
local Dropdown = Ans.UI.Dropdown;
local SniperSettings = {};

local soundKitSounds = {};
local soundKitSoundsToIndex = {};

SniperSettings.__index = SniperSettings;
Ans.SnipeSettingsView = SniperSettings;

-- prep sound kit array

for k,v in pairs(SOUNDKIT) do
    tinsert(soundKitSounds, k);
end

table.sort(soundKitSounds);

for i,v in ipairs(soundKitSounds) do
    soundKitSoundsToIndex[v] = i;
end

function SniperSettings:OnLoad(f)
    self.parent = f;
    self.frame = CreateFrame("Frame", "AnsSnipeOptionsView", f, "AnsSniperSettingsTemplate");

    self.source = TextInput:NewFrom(self.frame.Source);
    self.source.onTextChanged = self.SaveSource;

    self.price = TextInput:NewFrom(self.frame.Price.Text);
    self.price:EnableMultiLine();
    self.price.onTextChanged = self.SavePrice;

    self.blacklist = TextInput:NewFrom(self.frame.Blacklist.Text);
    self.blacklist:EnableMultiLine();
    self.blacklist.onTextChanged = self.SaveBlacklist;

    self.commodityConfirm = self.frame.CommodityConfirm;
    self.commodityConfirm:SetScript("OnClick", self.SaveCommodityConfirm);

    self.scanDelay = TextInput:NewFrom(self.frame.ScanDelay);
    self.scanDelay.onTextChanged = self.SaveScanDelay;

    self.ding = self.frame.Ding;
    self.ding:SetScript("OnClick", self.SaveDing);

    self.skipSeenGroup = self.frame.SkipSeenGroup;
    self.skipSeenGroup:SetScript("OnClick", self.SaveSkipSeen);

    self.chatMessageNew = self.frame.ChatMessageNew;
    self.chatMessageNew:SetScript("OnClick", self.SaveChatMessageNew);

    self.flashWoWIcon = self.frame.FlashWoWIcon;
    self.flashWoWIcon:SetScript("OnClick", self.SaveFlashWoWIcon);

    self.itemsUpdate = TextInput:NewFrom(self.frame.ItemsUpdate);
    self.itemsUpdate.onTextChanged = self.SaveItemsUpdate;

    self:CreateSoundList();
    self.frame:Hide();
end

function SniperSettings:Show()
    if (self.frame) then
        self.frame:Show();
        self:Load();
    end
end

function SniperSettings:Hide()
    if (self.frame) then
        self.frame:Hide();
    end
end

function SniperSettings:Load()
    self.skipSeenGroup:SetChecked(Config.Sniper().skipSeenGroup);
    self.chatMessageNew:SetChecked(Config.Sniper().chatMessageNew);
    self.scanDelay:Set(Config.Sniper().scanDelay or "10");
    self.source:Set(Config.Sniper().source or "");
    self.price:Set(Config.Sniper().pricing or "");
    if (type(Config.Sniper().characterBlacklist) == "table") then
        self.blacklist:Set(table.concat(Config.Sniper().characterBlacklist, "\r\n"));
    else
        Config.Sniper().characterBlacklist = { strsplit("\r\n", Config.Sniper().characterBlacklist:lower()) };
        self.blacklist:Set(table.concat(Config.Sniper().characterBlacklist, "\r\n"));
    end
    self.commodityConfirm:SetChecked(Config.Sniper().useCommodityConfirm);
    self.ding:SetChecked(Config.Sniper().dingSound);
    self.itemsUpdate:Set(Config.Sniper().itemsPerUpdate.."");
    self.flashWoWIcon:SetChecked(Config.Sniper().flashWoWIcon);
    self.soundList:SetSelected(soundKitSoundsToIndex[Config.Sniper().soundKitSound]);
end

function SniperSettings:CreateSoundList()
    self.soundList = Dropdown:New("DingSound", self.frame);
    self.soundList:SetPoint("TOPLEFT", "TOPLEFT", 225, -20);
    self.soundList:SetSize(300, 20);

    for i,v in ipairs(soundKitSounds) do
        self.soundList:AddItem(v, self.SaveSound);
    end
end

function SniperSettings.SaveSound()
    Config.Sniper().soundKitSound = soundKitSounds[SniperSettings.soundList.selected];
end

function SniperSettings.SaveSkipSeen()
    Config.Sniper().skipSeenGroup = SniperSettings.skipSeenGroup:GetChecked();
end

function SniperSettings.SaveChatMessageNew()
    Config.Sniper().chatMessageNew = SniperSettings.chatMessageNew:GetChecked();
end

function SniperSettings.SaveSource()
    Config.Sniper().source = SniperSettings.source:Get();
end

function SniperSettings.SavePrice()
    Config.Sniper().pricing = SniperSettings.price:Get();
end

function SniperSettings.SaveBlacklist()
    Config.Sniper().characterBlacklist = { strsplit("\r\n", SniperSettings.blacklist:Get():lower()) };
end

function SniperSettings.SaveCommodityConfirm()
    Config.Sniper().useCommodityConfirm = SniperSettings.commodityConfirm:GetChecked();
end

function SniperSettings.SaveDing()
    Config.Sniper().dingSound = SniperSettings.ding:GetChecked();
end

function SniperSettings.SaveItemsUpdate()
    Config.Sniper().itemsPerUpdate = tonumber(SniperSettings.itemsUpdate:Get()) or 20;
end

function SniperSettings:SaveScanDelay()
    Config.Sniper().scanDelay = tonumber(SniperSettings.scanDelay:Get()) or 10;
end

function SniperSettings.SaveFlashWoWIcon()
    Config.Sniper().flashWoWIcon = SniperSettings.flashWoWIcon:GetChecked();
end