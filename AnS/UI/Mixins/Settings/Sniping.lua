local Ans = select(2, ...);

local TextInput = Ans.UI.TextInput;
local ListView  = Ans.UI.ListView;
local Config = Ans.Config;
local Dropdown = Ans.UI.Dropdown;
local Sources = Ans.Sources;

local soundKitSounds = {};
local soundKitSoundsToIndex = {};

for k,v in pairs(SOUNDKIT) do
    tinsert(soundKitSounds, k);
end

table.sort(soundKitSounds);

for i,v in ipairs(soundKitSounds) do
    soundKitSoundsToIndex[v] = i;
end

local blacklistItems = {};

AnsSniperSettingsFrameMixin = {};

function AnsSniperSettingsFrameMixin:Init()
    local this = self;

    self:SetScript("OnShow", function() self:Refresh(); end);

    self.valueChangedHandler = function() this:Save(); end;

    self.source = TextInput:NewFrom(self.Source);
    self.source.onTextChanged = self.valueChangedHandler;

    self.price = TextInput:NewFrom(self.Price.Text);
    self.price:EnableMultiLine();
    self.price.onTextChanged = self.valueChangedHandler;
    self.price.sourceValidation = Sources;

    self.CommodityConfirm:SetScript("OnClick", self.valueChangedHandler);
   
    self.scanDelay = TextInput:NewFrom(self.ScanDelay);
    self.scanDelay.onTextChanged = self.valueChangedHandler;

    self.Ding:SetScript("OnClick", self.valueChangedHandler);

    self.TestDing:SetScript("OnClick", function() PlaySound(SOUNDKIT[Config.Sniper().soundKitSound], "Master"); end);

    self.SingleStack:SetScript("OnClick", self.valueChangedHandler);

    self.SkipSeenGroup:SetScript("OnClick", self.valueChangedHandler);
    self.ChatMessageNew:SetScript("OnClick", self.valueChangedHandler);
    self.FlashWoWIcon:SetScript("OnClick", self.valueChangedHandler);
    
    self.IgnoreGroupPercent:SetScript("OnClick", self.valueChangeHandler);

    self.itemsUpdate = TextInput:NewFrom(self.ItemsUpdate);
    self.itemsUpdate.onTextChanged = self.valueChangedHandler;

    self:CreateSoundList();
    self:Hide();
end


function AnsSniperSettingsFrameMixin:Refresh()
    self.SkipSeenGroup:SetChecked(Config.Sniper().skipSeenGroup);
    self.ChatMessageNew:SetChecked(Config.Sniper().chatMessageNew);
    self.scanDelay:Set(Config.Sniper().scanDelay or "10");
    self.source:Set(Config.Sniper().source or "");
    self.price:Set(Config.Sniper().pricing or "");

    self.CommodityConfirm:SetChecked(Config.Sniper().useCommodityConfirm);
    self.Ding:SetChecked(Config.Sniper().dingSound);
    self.itemsUpdate:Set(Config.Sniper().itemsPerUpdate.."");
    self.FlashWoWIcon:SetChecked(Config.Sniper().flashWoWIcon);
    self.soundList:SetSelected(soundKitSoundsToIndex[Config.Sniper().soundKitSound]);
    self.SingleStack:SetChecked(Config.Sniper().ignoreSingleStacks);
    self.IgnoreGroupPercent:SetChecked(Config.Sniper().ignoreGroupMaxPercent or false);
end

function AnsSniperSettingsFrameMixin:CreateSoundList()
    self.soundList = Dropdown:Acquire(nil, self);
    self.soundList:SetPoint("TOPLEFT", "TOPLEFT", 225, -20);
    self.soundList:SetSize(300, 20);

    for i,v in ipairs(soundKitSounds) do
        self.soundList:AddItem(v, self.valueChangedHandler);
    end
end

function AnsSniperSettingsFrameMixin:Save()
    Config.Sniper().soundKitSound = soundKitSounds[self.soundList.selected];
    Config.Sniper().skipSeenGroup = self.SkipSeenGroup:GetChecked();
    Config.Sniper().chatMessageNew = self.ChatMessageNew:GetChecked();
    Config.Sniper().source = self.source:Get();
    Config.Sniper().pricing = self.price:Get();

    Config.Sniper().useCommodityConfirm = self.CommodityConfirm:GetChecked();
    Config.Sniper().dingSound = self.Ding:GetChecked();

    Config.Sniper().itemsPerUpdate = tonumber(self.itemsUpdate:Get()) or 20;
    Config.Sniper().scanDelay = tonumber(self.scanDelay:Get()) or 10;
    Config.Sniper().flashWoWIcon = self.FlashWoWIcon:GetChecked();
    Config.Sniper().ignoreSingleStacks = self.SingleStack:GetChecked();
    Config.Sniper().ignoreGroupMaxPercent = self.IgnoreGroupPercent:GetChecked();
end