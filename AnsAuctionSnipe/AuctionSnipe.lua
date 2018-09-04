AuctionSnipe = {};
AuctionSnipe.__index = AuctionSnipe;
AuctionSnipe.sortHow = AnsQuerySort.RECENT;
AuctionSnipe.sortAsc = true;
AuctionSnipe.query = AnsQuery:New("");
AuctionSnipe.isSniping = false;
AuctionSnipe.prepareToSnipe = false;
AuctionSnipe.isInited = false;
AuctionSnipe.TAB_ID = 1;
AuctionSnipe.waitingForResult = false;
AuctionSnipe.quality = 1;

local AnsQualityToText = {};
AnsQualityToText[1] = "Common";
AnsQualityToText[2] = "Uncommon";
AnsQualityToText[3] = "Rare";
AnsQualityToText[4] = "Epic";
AnsQualityToText[5] = "Legendary";

local Ans_Orig_AuctionTabClick = nil;
local function TabClick(self, button, down)
    AuctionSnipe:TabClick(self, button, down);
end

local function QualitySelected(self, arg1, arg2, checked)
    AuctionSnipe.quality = arg1;
    UIDropDownMenu_SetText(_G["AnsSnipeQualityLevel"], ITEM_QUALITY_COLORS[arg1].hex..AnsQualityToText[arg1]);
    CloseDropDownMenus();
end
local function BuildQualityDropDown(frame, level, menuList)
    local info = UIDropDownMenu_CreateInfo();
    info.func = QualitySelected;
    local i;

    for i = 1, 5 do
        local c = ITEM_QUALITY_COLORS[i];
        local text = c.hex..AnsQualityToText[i];
        info.text, info.arg1 = text, i;
        UIDropDownMenu_AddButton(info);
    end
end

function AuctionSnipe:Init()
    if (self.isInited) then
        return;
    end;

    self.isInited = true;

    --- create main panel
    local frame = CreateFrame("FRAME", "AnsSnipeMainPanel", AuctionFrame, "AnsSnipeBuyTemplate");
    frame:Hide();

    self:AddTab("Snipe", self.TAB_ID);
    self:SetupHooks();

    _G["AnsSnipeStartButton"]:Enable();
    _G["AnsSnipeStopButton"]:Disable();

    MoneyInputFrame_SetCopper(_G["AnsSnipeMaxBuyout"], 0);
    _G["AnsSnipeMinLevel"]:SetText("0");
    _G["AnsSnipeMinSize"]:SetText("0");
    UIDropDownMenu_Initialize(_G["AnsSnipeQualityLevel"], BuildQualityDropDown);
    UIDropDownMenu_SetText(_G["AnsSnipeQualityLevel"], ITEM_QUALITY_COLORS[1].hex.."Common");
end

function AuctionSnipe:OnUpdate(frame, elapsed)
    if (self.isSniping) then
        if (not self.waitingForResult and not AnsSnipeAuctionList.buying) then
            if (self.query:Search()) then
                self.waitingForResult = true;
            end
        end
    end
end


----
-- Events
---
function AuctionSnipe:RegisterEvents(frame)
    frame:RegisterEvent("ADDON_LOADED");
    frame:RegisterEvent("AUCTION_ITEM_LIST_UPDATE");
    frame:RegisterEvent("AUCTION_HOUSE_SHOW");
    frame:RegisterEvent("AUCTION_HOUSE_CLOSED");
end

function AuctionSnipe:EventHandler(frame, event, ...)
    if (event == "ADDON_LOADED") then self:OnAddonLoaded(...) end;
    if (event == "AUCTION_ITEM_LIST_UPDATE") then self:OnAuctionUpdate(...); end;
    if (event == "AUCTION_HOUSE_SHOW") then self:OnAuctionHouseShow(); end;
    if (event == "AUCTION_HOUSE_CLOSED") then self:OnAuctionHouseClosed(); end;
end

function AuctionSnipe:SetupHooks()
    Ans_Orig_AuctionTabClick = AuctionFrameTab_OnClick;
    AuctionFrameTab_OnClick = TabClick;
end

function AuctionSnipe:OnAddonLoaded(...)
    local addonName = select(1, ...);
    if (addonName:lower() == "blizzard_auctionui") then
        self:Init();
    end
end

function AuctionSnipe:OnAuctionHouseShow()
    AnsSnipeAuctionList:Clear();
end

function AuctionSnipe:OnAuctionHouseClosed()
    self:Stop();
end

function AuctionSnipe:OnAuctionUpdate(...)
    if (self.isSniping and not self.prepareToSnipe) then
        self.query:Capture();
        self.waitingForResult = false;

        if (not self.query:IsLastPage()) then
            self.query = self.query:LastPage();
        else
            AnsSnipeAuctionList:SetItems(self.query:Items(self.sortHow,self.sortAsc));
            self.query = self.query:LastPage();
        end
    end
    if (not self.isSniping and self.prepareToSnipe) then
        self.prepareToSnipe = false;
        self.isSniping = true;
    end
end

function AuctionSnipe:TabClick(btn, index, down)
    if (index == nil or type(index) == "string") then
        index = btn:GetID();
    end

    _G["AnsSnipeMainPanel"]:Hide();

    self:Stop();

    Ans_Orig_AuctionTabClick(btn, index, down);

    if (self:IsTab(index)) then
        AuctionFrameMoneyFrame:Show();
        AuctionFrameAuctions:Hide();
        AuctionFrameBrowse:Hide();
        AuctionFrameBid:Hide();

        PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB);
        PanelTemplates_SetTab(AuctionFrame, index);

        AuctionFrameTopLeft:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Browse-TopLeft");
        AuctionFrameBotLeft:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Browse-BotLeft");
        AuctionFrameTop:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Browse-Top");
        AuctionFrameTopRight:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Browse-TopRight");
        AuctionFrameBotRight:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Bid-BotRight");
        AuctionFrameBot:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Auction-Bot");

        _G["AnsSnipeMainPanel"]:Show();

        AnsSnipeAuctionList:Clear();
        AnsFilterView:Refresh(AnsSnipeFiltersScrollFrame,"AnsSnipeFilterRow");
    end
end

----
-- Tabs
---
function AuctionSnipe:AddTab(name, tab)
    local n = AuctionFrame.numTabs+1;
    local framename = "AuctionFrameTab"..n;
    local frame = CreateFrame("Button", framename, AuctionFrame, "AuctionTabTemplate");

    frame:SetID(n);
    frame:SetText(name);
    frame:SetNormalFontObject(_G["AnsFontOrange"]);
    frame.ansTab = tab;
    frame:SetPoint("LEFT", _G["AuctionFrameTab"..n-1], "RIGHT", -8, 0);

    PanelTemplates_SetNumTabs(AuctionFrame, n);
    PanelTemplates_EnableTab(AuctionFrame, n);
end

function AuctionSnipe:IsTabSelected(whichTab)
    if (not AuctionFrame or not AuctionFrame:IsShown()) then
        return false;
    end
    if (not whichTab) then
        return self:IsTabSelected(self.TAB_ID);
    end

    return PanelTemplates_GetSelectedTab(AuctionFrame) == self:FindTabIndex(whichTab);
end

function AuctionSnipe:IsTab(index)
    if (index == self:FindTabIndex(self.TAB_ID)) then
        return true;
    end

    return false;
end

function AuctionSnipe:FindTabIndex(whichTab)
    local i;
    for i = 4,20 do
        local tab = _G["AuctionFrameTab"..i];
        if (tab and tab.ansTab and tab.ansTab == whichTab) then
            return i;
        end
    end

    return 0;
end

-----
--- Sort Methods
----

function AuctionSnipe:SortByPrice()
    if (self.sortHow ~= AnsQuerySort.PRICE) then
        self.sortAsc = true;
    else
        if(self.sortAsc)then
            self.sortAsc = false;
        else
            self.sortAsc = true;
        end
    end

    self.sortHow = AnsQuerySort.PRICE;
    AnsSnipeAuctionList:SetItems(self.query:Items(self.sortHow, self.sortAsc));
end

function AuctionSnipe:SortByName()
    if (self.sortHow ~= AnsQuerySort.NAME) then
        self.sortAsc = true;
    else
        if (self.sortAsc) then
            self.sortAsc = false;
        else
            self.sortAsc = true;
        end
    end

    self.sortHow = AnsQuerySort.NAME;
    AnsSnipeAuctionList:SetItems(self.query:Items(self.sortHow, self.sortAsc));
end

function AuctionSnipe:SortByPercent()
    if (self.sortHow ~= AnsQuerySort.PERCENT) then
        self.sortAsc = true;
    else
        if (self.sortAsc) then
            self.sortAsc = false;
        else
            self.sortAsc = true;
        end
    end

    self.sortHow = AnsQuerySort.PERCENT;
    AnsSnipeAuctionList:SetItems(self.query:Items(self.sortHow, self.sortAsc));
end

function AuctionSnipe:SortByRecent()
    if (self.sortHow ~= AnsQuerySort.RECENT) then
        self.sortAsc = false;
    else
        if (self.sortAsc) then
            self.sortAsc = false;
        else
            self.sortAsc = true;
        end
    end

    self.sortHow = AnsQuerySort.RECENT;
    AnsSnipeAuctionList:SetItems(self.query:Items(self.sortHow, self.sortAsc));
end

function AuctionSnipe:SortByILevel()
    if (self.sortHow ~= AnsQuerySort.ILEVEL) then
        self.sortAsc = false;
    else
        if (self.sortAsc) then
            self.sortAsc = false;
        else
            self.sortAsc = true;
        end
    end

    self.sortHow = AnsQuerySort.ILEVEL;
    AnsSnipeAuctionList:SetItems(self.query:Items(self.sortHow, self.sortAsc));
end

----
--- Button Handlers for Start & Stop 
---

function AuctionSnipe:Start()
    _G["AnsSnipeStartButton"]:Disable();
    _G["AnsSnipeStopButton"]:Enable();

    local maxBuyout = MoneyInputFrame_GetCopper(_G["AnsSnipeMaxBuyout"]) or 0;
    local ilevel = tonumber(_G["AnsSnipeMinLevel"]:GetText()) or 0;
    local minSize = tonumber(_G["AnsSnipeMinSize"]:GetText()) or 0;
    local quality = self.quality;

    local search = _G["AnsSnipeSearchBox"]:GetText();
    
    self.query.index = 0;

    if (search ~= self.query.search) then
        AnsSnipeAuctionList.selectedEntry = -1;
        self.query:Set(search);
    end

    self.query:AssignFilters(ilevel, maxBuyout, quality, minSize);

    self.isSniping = false;
    self.prepareToSnipe = true;

    SortAuctionClearSort("list");
    SortAuctionApplySort("list");
end

function AuctionSnipe:Stop()
    _G["AnsSnipeStartButton"]:Enable();
    _G["AnsSnipeStopButton"]:Disable();
    self.isSniping = false;
    self.waitingForResult = false;
    self.prepareToSnipe = false;
end

-- filter view refresh
function AnsSnipeFilterViewRefresh()
    AnsFilterView:Refresh(AnsSnipeFiltersScrollFrame, "AnsSnipeFilterRow");
end