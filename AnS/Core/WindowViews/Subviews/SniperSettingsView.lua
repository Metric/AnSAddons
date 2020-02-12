local Ans = select(2, ...);
local TextInput = Ans.UI.TextInput;
local SniperSettings = {};
SniperSettings.__index = SniperSettings;
Ans.SnipeSettingsView = SniperSettings;

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

    self.ding = self.frame.Ding;
    self.ding:SetScript("OnClick", self.SaveDing);

    self.itemsUpdate = TextInput:NewFrom(self.frame.ItemsUpdate);
    self.itemsUpdate.onTextChanged = self.SaveItemsUpdate;
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
    self.source:Set(ANS_SNIPE_SETTINGS.source);
    self.price:Set(ANS_SNIPE_SETTINGS.pricing);
    if (type(ANS_SNIPE_SETTINGS.characterBlacklist) == "table") then
        self.blacklist:Set(table.concat(ANS_SNIPE_SETTINGS.characterBlacklist, "\r\n"));
    else
        ANS_SNIPE_SETTINGS.characterBlacklist = { strsplit("\r\n", ANS_SNIPE_SETTINGS.characterBlacklist) };
        self.blacklist:Set(table.concat(ANS_SNIPE_SETTINGS.characterBlacklist, "\r\n"));
    end
    self.commodityConfirm:SetChecked(ANS_SNIPE_SETTINGS.useCommodityConfirm);
    self.ding:SetChecked(ANS_SNIPE_SETTINGS.dingSound);
    self.itemsUpdate:Set(ANS_SNIPE_SETTINGS.itemsPerUpdate.."");
end

function SniperSettings.SaveSource()
    ANS_SNIPE_SETTINGS.source = SniperSettings.source:Get();
end

function SniperSettings.SavePrice()
    ANS_SNIPE_SETTINGS.pricing = SniperSettings.price:Get();
end

function SniperSettings.SaveBlacklist()
    ANS_SNIPE_SETTINGS.characterBlacklist = { strsplit("\r\n", SniperSettings.blacklist:Get()) };
end

function SniperSettings.SaveCommodityConfirm()
    ANS_SNIPE_SETTINGS.useCommodityConfirm = SniperSettings.commodityConfirm:GetChecked();
end

function SniperSettings.SaveDing()
    ANS_SNIPE_SETTINGS.dingSound = SniperSettings.ding:GetChecked();
end

function SniperSettings.SaveItemsUpdate()
    ANS_SNIPE_SETTINGS.itemsPerUpdate = tonumber(SniperSettings.itemsUpdate:Get()) or 20;
end