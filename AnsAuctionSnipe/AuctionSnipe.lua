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
AuctionSnipe.waitingQuery = -1;
AuctionSnipe.quality = 1;

local AnsQualityToText = {};
AnsQualityToText[1] = "Common";
AnsQualityToText[2] = "Uncommon";
AnsQualityToText[3] = "Rare";
AnsQualityToText[4] = "Epic";
AnsQualityToText[5] = "Legendary";

local lastScan = time();

BINDING_NAME_ANSSNIPEBUYSELECT = "Buy Selected Auction";
BINDING_NAME_ANSSNIPEBUYFIRST = "Buy First Auction";

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

function AuctionSnipe:BuySelected()
    local s = AnsSnipeAuctionList;
    if (s and _G["AnsSnipeMainPanel"]:IsShown()) then
        if (s.selectedEntry > -1 and #s.items > 0) then
            local block = s.items[s.selectedEntry];
            if (block) then
                if (s:Purchase(block)) then
                    --AnsRecycler:RecycleBlock(tremove(s.items, s.selectedEntry));
                    s.selectedEntry = -1;
                end

                s:Refresh();
            end
        end
    end 
end

function AuctionSnipe:BuyFirst()
    local s = AnsSnipeAuctionList;
    if (s and _G["AnsSnipeMainPanel"]:IsShown()) then
        if (#s.items > 0) then
            local block = s.items[1];
            if (block) then
                if(s:Purchase(block)) then
                    --AnsRecycler:RecycleBlock(tremove(s.items, 1));
                    if (s.selectedEntry == 1) then
                        s.selectedEntry = -1;
                    end
                end

                s:Refresh();
            end
        end
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

    AnsSnipeDingSound:SetChecked(ANS_GLOBAL_SETTINGS.dingSound);
    AnsSnipeMinMaxPercent:SetText("100");

    UIDropDownMenu_Initialize(_G["AnsSnipeQualityLevel"], BuildQualityDropDown);
    UIDropDownMenu_SetText(_G["AnsSnipeQualityLevel"], ITEM_QUALITY_COLORS[1].hex.."Common");
end

function AuctionSnipe:OnUpdate(frame, elapsed)
    if (self.isSniping) then
        local tdiff = time() - lastScan;
        local notDelayed = AnsSnipeAuctionList.queryDelay <= 0 or not ANS_GLOBAL_SETTINGS.safeBuy;
        local scanReady = tdiff >= ANS_GLOBAL_SETTINGS.rescanTime;

        if (scanReady and notDelayed and not self.waitingForResult and not AnsSnipeAuctionList.buying) then
            if (self.query:IsReady()) then
                AnsSnipeAuctionList:SetStatus(ANS_WAITING_FOR_RESULTS, ANS_GLOBAL_SETTINGS.safeBuy);
                
                self.waitingForResult = true;
                self.query:Search();

                if (AnsSnipeStatus) then
                    AnsSnipeStatus:SetText("Query ID: "..self.query.id.." Page: "..self.query.index.." - Query Sent...");
                end

                lastScan = time();
            end
        end
    end
    
    AnsSnipeAuctionList:UpdateDelay();
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
    self.query:Reset();
    AnsPriceSources:ClearCache();
end

---
--- Auction Update Handler
---

function AuctionSnipe:OnAuctionUpdate(...)
    if (self.isSniping and not self.prepareToSnipe) then
        if (not self.query:IsLastPage()) then
            self.query:LastPage();
            if (AnsSnipeStatus) then
                AnsSnipeStatus:SetText("Query ID: "..self.query.id.." Page: "..self.query.index.." - Waiting to Query...");        
            end
        elseif (self.waitingForResult) then
            self.waitingQuery = self.query.id;
            if (AnsSnipeStatus) then
                AnsSnipeStatus:SetText("Query ID: "..self.query.id.." Page: "..self.query.index.." - Processing Data...");
            end
            AnsSnipeAuctionList:SetStatus(ANS_QUERY_PAGE, self.query.id);
            self.query:Capture();
            self.query:Items(self.sortHow,self.sortAsc,AnsSnipeAuctionList.items);
            AnsSnipeAuctionList.selectedEntry = -1;
            AnsSnipeAuctionList:Refresh();
            AnsSnipeAuctionList:SetStatus(ANS_WAITING_FOR_RESULTS, false);
            self.query:LastPage();

            if (AnsSnipeStatus) then
                AnsSnipeStatus:SetText("Query ID: "..self.query.id.." Page: "..self.query.index.." - Waiting to Query...");        
            end
        else
            if (AnsSnipeStatus) then
                AnsSnipeStatus:SetText("Query ID: "..self.query.id.." Page: "..self.query.index.." - Waiting to Query...");        
            end
        end
    end
    if (not self.isSniping and self.prepareToSnipe) then
        self.prepareToSnipe = false;
        self.isSniping = true;
    end

    self.waitingForResult = false;
end

---
--- Tab Click Override
---

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
    self.query:Items(self.sortHow,self.sortAsc,AnsSnipeAuctionList.items);
    AnsSnipeAuctionList:Refresh();
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
    self.query:Items(self.sortHow,self.sortAsc,AnsSnipeAuctionList.items);
    AnsSnipeAuctionList:Refresh();
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
    self.query:Items(self.sortHow,self.sortAsc,AnsSnipeAuctionList.items);
    AnsSnipeAuctionList:Refresh();
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
    self.query:Items(self.sortHow,self.sortAsc,AnsSnipeAuctionList.items);
    AnsSnipeAuctionList:Refresh();
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
    self.query:Items(self.sortHow,self.sortAsc,AnsSnipeAuctionList.items);
    AnsSnipeAuctionList:Refresh();
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
    local maxPercent = self:GetMaxPercent();

    local search = _G["AnsSnipeSearchBox"]:GetText();
    
    self.query.index = 0;

    AnsSnipeAuctionList.selectedEntry = -1;

    if (search ~= self.query.search) then
        self.query:Set(search);
    end

    if (AnsSnipeStatus) then
        AnsSnipeStatus:SetText("Page: 0 - Starting...");
    end

    AnsSnipeAuctionList:SetStatus(ANS_QUERY_OBJECT, self.query);

    self.query:ClearLastHash();

    self.query:AssignFilters(ilevel, maxBuyout, quality, minSize, maxPercent);

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
    self.waitingQuery = 0;
    AnsSnipeAuctionList.queryDelay = 0;
    if (AnsSnipeStatus) then
        AnsSnipeStatus:SetText("Page: "..self.query.index.." - Stopped...");
    end
end

---
--- Updates ding
---

function AuctionSnipe:DingSound(f)
    ANS_GLOBAL_SETTINGS.dingSound = f:GetChecked();
end

--
-- Helper to get max percent from text box as number
--

function AuctionSnipe:GetMaxPercent()
    local text = AnsSnipeMinMaxPercent:GetText();
    local max = tonumber(text) or 100;
    return max;
end

-- filter view refresh
function AnsSnipeFilterViewRefresh()
    AnsFilterView:Refresh(AnsSnipeFiltersScrollFrame, "AnsSnipeFilterRow");
end