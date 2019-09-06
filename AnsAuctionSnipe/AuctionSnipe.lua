local Ans = select(2, ...);
local Query = AnsCore.API.Query;
local AuctionList = Ans.AuctionList;
local Sources = AnsCore.API.Sources;
local TreeView = AnsCore.API.UI.TreeView;

AuctionSnipe = {};
AuctionSnipe.__index = AuctionSnipe;
AuctionSnipe.sortHow = Query.SORT_METHODS.RECENT;
AuctionSnipe.sortAsc = true;
AuctionSnipe.query = Query:New("");
AuctionSnipe.isSniping = false;
AuctionSnipe.prepareToSnipe = false;
AuctionSnipe.isRewinding = false;
AuctionSnipe.firstRewind = false;
AuctionSnipe.rewindPaused = false;
AuctionSnipe.isInited = false;
AuctionSnipe.waitingForResult = false;
AuctionSnipe.waitingQuery = -1;
AuctionSnipe.quality = 1;
AuctionSnipe.activeFilters = {};

local filterTreeViewItems = {};

local AnsQualityToText = {};
AnsQualityToText[1] = "Common";
AnsQualityToText[2] = "Uncommon";
AnsQualityToText[3] = "Rare";
AnsQualityToText[4] = "Epic";
AnsQualityToText[5] = "Legendary";

local lastScan = time();

BINDING_NAME_ANSSNIPEBUYSELECT = "Buy Selected Auction";
BINDING_NAME_ANSSNIPEBUYFIRST = "Buy First Auction";

local function QualitySelected(self, arg1, arg2, checked)
    AuctionSnipe.quality = arg1;
    if (AuctionSnipe.qualityInput ~= nil) then
        UIDropDownMenu_SetText(AuctionSnipe.qualityInput, ITEM_QUALITY_COLORS[arg1].hex..AnsQualityToText[arg1]);
    end
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
    local s = AuctionList;
    if (s and self.frame and self.frame:IsShown()) then
        if (s.selectedEntry > -1 and #s.items > 0) then
            local block = s.items[s.selectedEntry];
            if (block) then
                if (s:Purchase(block)) then
                    s.selectedEntry = -1;
                end

                s:Refresh();
            end
        end
    end 
end

function AuctionSnipe:BuyFirstOnly()
    local s = AuctionList;
    if (s and self.frame and self.frame:IsShown()) then
        if (#s.items > 0) then
            local block = s.items[1];

            if (block) then
                if(s:Purchase(block)) then
                    if (s.selectedEntry == 1) then
                        s.selectedEntry = -1;
                    end
                end

                s:Refresh();
            end
        end
    end
end

function AuctionSnipe:BuyFirst()
    local s = AuctionList;
    if (s and self.frame and self.frame:IsShown()) then
        if (#s.items > 0) then
            local block = self:GetNextAvailable();

            if (block) then
                if(s:Purchase(block)) then
                    if (s.selectedEntry == 1) then
                        s.selectedEntry = -1;
                    end
                end

                s:Refresh();
            end
        end
    end
end

function AuctionSnipe:GetNextAvailable()
    local s = AuctionList;
    for i,v in ipairs(s.items) do
        if (not self:IsSniped(v.item)) then
            return v;
        end 
    end

    return nil;
end

function AuctionSnipe:IsSniped(auction)
    if (not auction.sniped) then
        return false;
    end

    for i,v in ipairs(auction.group) do
        if (not v.item.sniped) then
            return false;
        end
    end

    return true;
end

function AuctionSnipe:Init()
    local d = self;
    if (self.isInited) then
        return;
    end;

    self.isInited = true;

    --- create main panel
    local frame = CreateFrame("FRAME", "AnsSnipeMainPanel", AuctionFrame, "AnsSnipeBuyTemplate");
    self.frame = frame;

    AuctionList:OnLoad(frame);

    AnsCore:AddAHTab("Snipe", 
        function()
            AuctionSnipe:Show();
        end,
        function()
            AuctionSnipe:Close();
        end
    );

    self.filterTreeView = TreeView:New(frame, {
        rowHeight = 20,
        childIndent = 16, 
        template = "AnsFilterRowTemplate"
    }, function(item) d:ToggleFilter(item.filter) end);

    self.startButton = _G[frame:GetName().."BottomBarStart"];
    self.stopButton = _G[frame:GetName().."BottomBarStop"];
    self.rewindButton = _G[frame:GetName().."BottomBarRewind"];

    self.startButton:Enable();
    self.stopButton:Disable();
    self.rewindButton:Enable();

    self.maxBuyoutInput = _G[frame:GetName().."SearchBarMaxPPU"];
    self.minLevelInput = _G[frame:GetName().."SearchBarMinLevel"];
    self.minSizeInput = _G[frame:GetName().."SearchBarMinSize"];
    self.qualityInput = _G[frame:GetName().."SearchBarQuality"];
    self.maxPercentInput = _G[frame:GetName().."SearchBarMaxPercent"];
    self.dingCheckBox = _G[frame:GetName().."SearchBarDingSound"];

    self.searchInput = _G[frame:GetName().."SearchBarSearch"];
    self.snipeStatusText = _G[frame:GetName().."BottomBarStatus"];

    MoneyInputFrame_SetCopper(self.maxBuyoutInput, 0);
    self.minLevelInput:SetText("0");
    self.minSizeInput:SetText("0");

    self.dingCheckBox:SetChecked(ANS_GLOBAL_SETTINGS.dingSound);
    self.maxPercentInput:SetText("100");

    UIDropDownMenu_Initialize(self.qualityInput, BuildQualityDropDown);
    UIDropDownMenu_SetText(self.qualityInput, ITEM_QUALITY_COLORS[1].hex.."Common");

    frame:Hide();
end

--- builds treeview item list from known filters
function AuctionSnipe:BuildTreeViewFilters()
    local filters = AnsCore.API.Filters;

    wipe(self.activeFilters);

    if (#filters < #filterTreeViewItems) then
        while (#filterTreeViewItems > #filters) do
            tremove(filterTreeViewItems);
        end
    end

    self:UpdateSubTreeFilters(filters, filterTreeViewItems);
end

function AuctionSnipe:UpdateSubTreeFilters(children, parent)
    for i, v in ipairs(children) do
        local pf = parent[i];

        if (pf) then
            pf.selected = ANS_FILTER_SELECTION[v:GetPath()] or false;

            if (pf.selected) then
                tinsert(self.activeFilters, v);
            end

            if (pf.name ~= v.name) then
                pf.expanded = false;
                pf.name = v.name;
                pf.filter = v;
                pf.children = {};

                if(#v.subfilters > 0) then
                    self:BuildSubTreeFilters(v.subfilters, pf.children);
                end
            else
                if(#v.subfilters > 0) then
                    if (#v.subfilters < #pf.children) then
                        while (#pf.children > #v.subfilters) do
                            tremove(pf.children);
                        end
                    end

                    self:UpdateSubTreeFilters(v.subfilters, pf.children);
                else
                    pf.children = {};
                end
            end
        else
            local t = {
                selected = ANS_FILTER_SELECTION[v:GetPath()] or false,
                name = v.name,
                expanded = false,
                filter = v,
                children = {}
            };

            if (t.selected) then
                tinsert(self.activeFilters, v);
            end

            if (#v.subfilters > 0) then
                self:BuildSubTreeFilters(v.subfilters, t.children);
            end
    
            tinsert(parent, t);
        end
    end
end

function AuctionSnipe:BuildSubTreeFilters(children, parent)
    for i,v in ipairs(children) do
        local t = {
            selected = ANS_FILTER_SELECTION[v:GetPath()] or false,
            name = v.name,
            expanded = false,
            filter = v,
            children = {}
        };

        if (t.selected) then
            tinsert(self.activeFilters, v);
        end

        if (#v.subfilters > 0) then
            self:BuildSubTreeFilters(v.subfilters, t.children);
        end

        tinsert(parent, t);
    end
end

function AuctionSnipe:OnUpdate(frame, elapsed)
    if (self.isSniping or (self.isRewinding and not self.rewindPaused)) then
        local tdiff = time() - lastScan;
        local notDelayed = AuctionList.queryDelay <= 0 or not ANS_GLOBAL_SETTINGS.safeBuy;
        local scanReady = tdiff >= ANS_GLOBAL_SETTINGS.rescanTime;

        if (scanReady and notDelayed and not self.waitingForResult and not AuctionList.buying) then
            if (self.query:IsReady()) then
                AuctionList:SetStatus(AuctionList.WAITING_FOR_RESULTS, ANS_GLOBAL_SETTINGS.safeBuy);
                
                self.waitingForResult = true;
                self.query:Search();

                if (self.snipeStatusText) then
                    self.snipeStatusText:SetText("Query ID: "..self.query.id.." Page: "..self.query.index.." - Query Sent...");
                end

                lastScan = time();
            end
        end

        -- if we haven't received a response within 30 seconds
        -- reset and try again
        if (tdiff > 30 and self.waitingForResult) then
            self:Stop();
            self.query:Reset();
            Sources:ClearCache();
            self:Start();
        end
    end
    
    AuctionList:UpdateDelay();
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

function AuctionSnipe:OnAddonLoaded(...)
    local addonName = select(1, ...);
    if (addonName:lower() == "blizzard_auctionui") then
        self:Init();
    end
end

function AuctionSnipe:OnAuctionHouseShow()
    AuctionList:Clear();
end   

function AuctionSnipe:OnAuctionHouseClosed()
    self:Stop();
    self.query:Reset();
    self.filterTreeView:ReleaseView();
    Sources:ClearCache();
end

---
--- Auction Update Handler
---

function AuctionSnipe:OnAuctionUpdate(...)
    if (self.isSniping and not self.prepareToSnipe) then
        if (not self.query:IsLastPage()) then
            self.query:LastPage();
            if (self.snipeStatusText) then
                self.snipeStatusText:SetText("Query ID: "..self.query.id.." Page: "..self.query.index.." - Waiting to Query...");        
            end
            self.waitingForResult = false;
        elseif (self.waitingForResult) then
            self.waitingQuery = self.query.id;
            if (self.snipeStatusText) then
                self.snipeStatusText:SetText("Query ID: "..self.query.id.." Page: "..self.query.index.." - Processing Data...");
            end
            AuctionList:SetStatus(AuctionList.QUERY_ID, self.query.id);
            self.query:Capture();
            self.query:Items(self.sortHow, self.sortAsc, AuctionList.items);
            AuctionList.selectedEntry = -1;
            AuctionList:Refresh();
            AuctionList:SetStatus(AuctionList.WAITING_FOR_RESULTS, false);
            self.query:LastPage();

            if (self.snipeStatusText) then
                self.snipeStatusText:SetText("Query ID: "..self.query.id.." Page: "..self.query.index.." - Waiting to Query...");        
            end
            self.waitingForResult = false;
        else
            if (self.snipeStatusText) then
                self.snipeStatusText:SetText("Query ID: "..self.query.id.." Page: "..self.query.index.." - Waiting to Query...");        
            end
        end
    elseif (self.isRewinding and not self.prepareToSnipe) then
        if (self.firstRewind) then
            self.query:LastPage();
            if (self.snipeStatusText) then
                self.snipeStatusText:SetText("Query ID: "..self.query.id.." Page: "..self.query.index.." - Waiting to Query..."); 
            end
            self.waitingForResult = false;
            self.firstRewind = false;
        elseif (self.waitingForResult) then
            self.waitingQuery = self.query.id;
            if (self.snipeStatusText) then
                self.snipeStatusText:SetText("Query ID: "..self.query.id.." Page: "..self.query.index.." - Processing Data...");
            end
            AuctionList:SetStatus(AuctionList.QUERY_ID, self.query.id);
            self.query:Capture();
            self.query:Items(self.sortHow, self.sortAsc, AuctionList.items);
            AuctionList.selectedEntry = -1;
            AuctionList:Refresh();
            AuctionList:SetStatus(AuctionList.WAITING_FOR_RESULTS, false);
            self.query:Previous();

            if (self.query.index <= 0) then
                self.query:LastPage();
            end

            if (self.snipeStatusText) then
                self.snipeStatusText:SetText("Query ID: "..self.query.id.." Page: "..self.query.index.." - Waiting to Query...");        
            end
            self.waitingForResult = false;
        else
            if (self.snipeStatusText) then
                self.snipeStatusText:SetText("Query ID: "..self.query.id.." Page: "..self.query.index.." - Waiting to Query...");        
            end
        end
    end
    if (self.prepareToSnipe and not self.isRewinding) then
        self.prepareToSnipe = false;
        self.isSniping = true;
    elseif (self.prepareToSnipe and self.isRewinding) then
        self.prepareToSnipe = false;
        self.isSniping = false;
    end
end

---
--- Close Handler
---

function AuctionSnipe:Close()
    self.frame:Hide();
    self:Stop();
    self.query:Reset();

    wipe(filterTreeViewItems);
    self.filterTreeView:ReleaseView();
end

--- 
--- Show Handler
---

function AuctionSnipe:Show()
    AuctionFrameMoneyFrame:Show();
    AuctionFrameAuctions:Hide();
    AuctionFrameBrowse:Hide();
    AuctionFrameBid:Hide();

    AuctionFrameTopLeft:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Browse-TopLeft");
    AuctionFrameBotLeft:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Browse-BotLeft");
    AuctionFrameTop:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Browse-Top");
    AuctionFrameTopRight:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Browse-TopRight");
    AuctionFrameBotRight:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Bid-BotRight");
    AuctionFrameBot:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Auction-Bot");

    self.frame:Show();

    AuctionList:Clear();
    
    self:BuildTreeViewFilters();
    self.filterTreeView.items = filterTreeViewItems;
    self.filterTreeView:Refresh();
end

-----
--- Sort Methods
----

function AuctionSnipe:SortByPrice()
    if (self.sortHow ~= Query.SORT_METHODS.PRICE) then
        self.sortAsc = true;
    else
        if(self.sortAsc)then
            self.sortAsc = false;
        else
            self.sortAsc = true;
        end
    end

    self.sortHow = Query.SORT_METHODS.PRICE;
    self.query:Items(self.sortHow,self.sortAsc,AuctionList.items);
    AuctionList:Refresh();
end

function AuctionSnipe:SortByName()
    if (self.sortHow ~= Query.SORT_METHODS.NAME) then
        self.sortAsc = true;
    else
        if (self.sortAsc) then
            self.sortAsc = false;
        else
            self.sortAsc = true;
        end
    end

    self.sortHow = Query.SORT_METHODS.NAME;
    self.query:Items(self.sortHow,self.sortAsc,AuctionList.items);
    AuctionList:Refresh();
end

function AuctionSnipe:SortByPercent()
    if (self.sortHow ~= Query.SORT_METHODS.PERCENT) then
        self.sortAsc = true;
    else
        if (self.sortAsc) then
            self.sortAsc = false;
        else
            self.sortAsc = true;
        end
    end

    self.sortHow = Query.SORT_METHODS.PERCENT;
    self.query:Items(self.sortHow,self.sortAsc,AuctionList.items);
    AuctionList:Refresh();
end

function AuctionSnipe:SortByRecent()
    if (self.sortHow ~= Query.SORT_METHODS.RECENT) then
        self.sortAsc = false;
    else
        if (self.sortAsc) then
            self.sortAsc = false;
        else
            self.sortAsc = true;
        end
    end

    self.sortHow = Query.SORT_METHODS.RECENT;
    self.query:Items(self.sortHow,self.sortAsc,AuctionList.items);
    AuctionList:Refresh();
end

function AuctionSnipe:SortByILevel()
    if (self.sortHow ~= Query.SORT_METHODS.ILEVEL) then
        self.sortAsc = false;
    else
        if (self.sortAsc) then
            self.sortAsc = false;
        else
            self.sortAsc = true;
        end
    end

    self.sortHow = Query.SORT_METHODS.ILEVEL;
    self.query:Items(self.sortHow,self.sortAsc,AuctionList.items);
    AuctionList:Refresh();
end

----
--- Button Handlers for Start & Stop 
---

function AuctionSnipe:Start()
    self.startButton:Disable();
    self.stopButton:Enable();

    if (not self.isRewinding) then
        self.rewindButton:Disable();
    end

    AuctionList:SetStatus(AuctionList.WAITING_FOR_RESULTS, false);

    self.waitingForResult = false;
    self.firstRewind = true;

    local maxBuyout = MoneyInputFrame_GetCopper(self.maxBuyoutInput) or 0;
    local ilevel = tonumber(self.minLevelInput:GetText()) or 0;
    local minSize = tonumber(self.minSizeInput:GetText()) or 0;
    local quality = self.quality;
    local maxPercent = tonumber(self.maxPercentInput:GetText()) or 100;

    local search = self.searchInput:GetText();
    
    self.query.index = 0;

    AuctionList.selectedEntry = -1;

    if (search ~= self.query.search) then
        self.query:Set(search);
    end

    if (self.snipeStatusText) then
        self.snipeStatusText:SetText("Page: 0 - Starting...");
    end

    AuctionList:SetStatus(AuctionList.QUERY_OBJECT, self.query);

    self.query:ClearLastHash();

    --- add filters into here
    self.query:AssignFilters(self.activeFilters, ilevel, maxBuyout, quality, minSize, maxPercent);

    self.isSniping = false;
    self.prepareToSnipe = true;

    SortAuctionClearSort("list");
    SortAuctionApplySort("list");
end

function AuctionSnipe:Stop()
    self.rewindButton:Enable();
    self.startButton:Enable();
    self.stopButton:Disable();
    self.rewindButton:SetText("Rewind Scan");
    self.isSniping = false;
    self.isRewinding = false;
    self.firstRewind = true;
    self.waitingForResult = false;
    self.prepareToSnipe = false;
    self.waitingQuery = 0;
    AuctionList:SetStatus(AuctionList.WAITING_FOR_RESULTS, false);
    AuctionList.queryDelay = 0;
    if (self.snipeStatusText) then
        self.snipeStatusText:SetText("Page: "..self.query.index.." - Stopped...");
    end
end

---
--- Rewind Button Handler
---
function AuctionSnipe:Rewind()
    if (self.isRewinding) then
        if (not self.rewindPaused) then
            self.rewindPaused = true;
            self.rewindButton:SetText("Resume Rewind");
        else
            self.rewindPaused = false;
            self.rewindButton:SetText("Pause Rewind");
        end
    else
        self.rewindButton:SetText("Pause Rewind");
        self.isRewinding = true;
        self:Start();
    end
end

---
--- Updates ding
---

function AuctionSnipe:DingSound(f)
    ANS_GLOBAL_SETTINGS.dingSound = f:GetChecked();
end

---
--- Handles removing / adding a selected filter
---

function AuctionSnipe:ClearFilters()
    wipe(ANS_FILTER_SELECTION);

    self:BuildTreeViewFilters();
    
    self.filterTreeView.items = filterTreeViewItems;
    self.filterTreeView:Refresh();
end

function AuctionSnipe:ToggleFilter(f)
    local path = f:GetPath();
    if (ANS_FILTER_SELECTION[path]) then
        self:RemoveFilter(f);
        ANS_FILTER_SELECTION[path] = false;
    else
        tinsert(self.activeFilters, f);
        ANS_FILTER_SELECTION[path] = true;
    end
end

function AuctionSnipe:RemoveFilter(f)
    for i, v in ipairs(self.activeFilters) do
        if (v == f) then
            tremove(self.activeFilters, i);
            return;
        end
    end
end