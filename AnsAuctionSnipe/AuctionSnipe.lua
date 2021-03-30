local Core = select(2, ...);
local Config = Ans.API.Config;
local Data = Ans.API.Data;
local BaseData = Ans.API.BaseData;
local Query = Ans.API.Auctions.Query;
local Recycler = Ans.API.Auctions.Recycler;
local AuctionList = Core.AuctionList;
local Sources = Ans.API.Sources;
local TreeView = Ans.API.UI.TreeView;
local Utils = Ans.API.Utils;
local Groups = Utils.Groups;
local EventManager = Ans.API.EventManager;
local SnipingOp = Ans.API.Operations.Sniping;
local FSM = Ans.API.FSM;
local FSMState = Ans.API.FSMState;
local Tasker = Ans.API.Tasker;
local Logger = Ans.API.Logger;
local SniperFSM = nil;

local EVENTS_TO_REGISTER = {};

local TASKER_TAG = "SNIPER";
local TASKER_PURCHASE_TAG = "SNIPER_PURCHASE";
local PURCHASE_WAIT_TIME = 10;

local AHFrame = nil;
local AHFrameDisplayMode = nil;

if (not Utils.IsClassic()) then
    EVENTS_TO_REGISTER = {
        "COMMODITY_PRICE_UPDATED",
        "COMMODITY_PRICE_UNAVAILABLE",
        "COMMODITY_PURCHASED",
        "COMMODITY_PURCHASE_FAILED",
        "COMMODITY_PURCHASE_SUCCEEDED",
        "ITEM_KEY_ITEM_INFO_RECEIVED",
        "GET_ITEM_INFO_RECEIVED",
        "AUCTION_HOUSE_THROTTLED_MESSAGE_DROPPED"
    };
end

local ERRORS = {
    ERR_ITEM_NOT_FOUND,
    ERR_AUCTION_DATABASE_ERROR
};

local rootFrame = nil;

local DEFAULT_BROWSE_QUERY = {};
DEFAULT_BROWSE_QUERY.searchString = "";
DEFAULT_BROWSE_QUERY.minLevel = 0; -- zero = any
DEFAULT_BROWSE_QUERY.maxLevel = 0; -- zero = any
DEFAULT_BROWSE_QUERY.filters = {};
DEFAULT_BROWSE_QUERY.itemClassFilters = {};
DEFAULT_BROWSE_QUERY.sorts = {};
DEFAULT_BROWSE_QUERY.quality = 1;

local DEFAULT_ITEM_SORT = { sortOrder = 0, reverseSort = false };

AuctionSnipe = {};
AuctionSnipe.__index = AuctionSnipe;
AuctionSnipe.isInited = false;
AuctionSnipe.activeOps = {};
AuctionSnipe.baseFilters = {};

local opTreeViewItems = {};
local baseTreeViewItems = {};

local AnsQualityToText = {};
AnsQualityToText[1] = "Common";
AnsQualityToText[2] = "Uncommon";
AnsQualityToText[3] = "Rare";
AnsQualityToText[4] = "Epic";
AnsQualityToText[5] = "Legendary";

local AnsQualityToAuctionEnum = {};
AnsQualityToAuctionEnum[1] = 5;
AnsQualityToAuctionEnum[2] = 6;
AnsQualityToAuctionEnum[3] = 7;
AnsQualityToAuctionEnum[4] = 8;
AnsQualityToAuctionEnum[5] = 9;

local qualityFilters = {};
local classFilters = {};

local browseResults = {};
local itemsFound = {};
local lastItemId = nil;
local currentItemScan = nil;
local validAuctions = {};
local infoKey = nil;

local scanIndex = 1;
local totalResultsFound = 0;
local totalValidAuctionsFound = 0;

local lastSeenGroupLowest = {};
local throttleMessageReceived = true;
local throttleWaitingForSend = false;
local throttleTime = time();

local lastSuccessScan = time();
local blocks = {};
local blockList = {};
local browseItem = 0;
local clearNew = true;

local currentAuctionIds = {};

local scanCount = 0;

local ERR_AUCTION_WON = gsub(ERR_AUCTION_WON_S or "", "%%s", "");

-- this dialog is used when in browse query
-- and you try to buy an auction
-- when this is displayed we are out of 
-- then browse state and have entered
-- a viable search state to purchase
StaticPopupDialogs["ANSCONFIRMAUCTION"] = {
    text = "Purchase %s for %s?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function()
        AuctionList:PurchaseAuction();
        Tasker.Delay(GetTime() + PURCHASE_WAIT_TIME, function()                    
            SniperFSM:Process("CANCEL_AUCTION");
        end, TASKER_PURCHASE_TAG);
    end,
    OnCancel = function()
        SniperFSM:Process("CANCEL_AUCTION");
    end,
    timeout = 0,
    whileDead = false,
    hideOnEscape = true,
    preferredIndex = 3
  };

local function RegisterEvents(frame, events) 
    for i,v in ipairs(events) do
        frame:RegisterEvent(v);
    end
end

local function UnregisterEvents(frame, events)
    for i,v in ipairs(events) do
        frame:UnregisterEvent(v);
    end
end

local function GetOwners(result)
    if (#result.owners == 0) then
        return "";
    elseif (#result.owners == 1) then
        return result.owners[1];
    else
        return result.owners;
    end
end

local function ClearItemsFound()
    Logger.Log("SNIPER", "Clearing previous items found: "..#itemsFound);
    for i,v in ipairs(itemsFound) do
        Recycler:Recycle(v);
    end
    wipe(itemsFound);
end

local function ClearValidAuctions()
    Logger.Log("SNIPER", "Clearing previous valid auctions: "..#validAuctions);
    wipe(validAuctions);
end

local function QualitySelected(self, arg1, arg2, checked)
    Config.Sniper().minQuality = arg1;
    if (AuctionSnipe.qualityInput ~= nil) then
        UIDropDownMenu_SetText(AuctionSnipe.qualityInput, ITEM_QUALITY_COLORS[arg1].hex..AnsQualityToText[arg1]);
    end
    CloseDropDownMenus();
end

local function BuildQualityDropDown(frame, level, menuList)
    local i;

    for i = 1, 5 do
        local info = UIDropDownMenu_CreateInfo();
        info.func = QualitySelected;

        local c = ITEM_QUALITY_COLORS[i];
        local text = c.hex..AnsQualityToText[i];
        info.text, info.arg1 = text, i;
        UIDropDownMenu_AddButton(info);
    end
end

local function BuildStateMachine()
    local fsm = FSM:Acquire("SniperFSM");
    local scanDelay = 0;

    local none = FSMState:Acquire("NONE");
    none:AddEvent("START_BUYING", function(self, event, previous)
        -- we return the real previous state
        -- before we switch to BUYING
        -- so it can be restored once
        -- the buying state is over
        Logger.Log("SNIPER", "trying to start buying");
        return "BUYING", previous;
    end);
    none:AddEvent("BUYING");


    fsm:Add(none);
    fsm:Add(FSMState:Acquire("START_BUYING"));

    local idle = FSMState:Acquire("IDLE");
    idle:AddEvent("START");
    idle:AddEvent("START_BUYING", function(self, event, previous)
        Logger.Log("SNIPER", "trying to start buying from idle");
        return "BUYING", previous;
    end);
    
    idle:AddEvent("BUYING");

    fsm:Add(idle);

    local start = FSMState:Acquire("START");
    start:SetOnEnter(function(self)
        currentItemScan = nil;
        totalResultsFound = 0;
        scanIndex = 1;
        browseItem = 0;
        totalValidAuctionsFound = 0;
        scanDelay = 0;
        clearNew = true;

        ClearItemsFound();
        ClearValidAuctions();

        wipe(browseResults);
        wipe(blocks);
        wipe(currentAuctionIds);

        Query.Clear();

        if (not Utils.IsClassic()) then
            Query.results = browseResults;
            Query.browseFilter = AuctionSnipe.BrowseFilter;

            if (AuctionSnipe.snipeStatusText) then
                AuctionSnipe.snipeStatusText:SetText("Waiting for Results");
            end

            Query.Browse(DEFAULT_BROWSE_QUERY);
        else
            AuctionList:Recycle();
            return "SEARCH";
        end

        return nil;
    end);
    start:AddEvent("FINDING");
    start:AddEvent("SEARCH");

    fsm:Add(start);

    local finding = FSMState:Acquire("FINDING");
    finding:SetOnEnter(function(self)
        if (#browseResults == 0 and Query.fullBrowseResults) then
            return "START";
        elseif (#browseResults == 0 and not Query.fullBrowseResults) then
            return "BROWSE_MORE";
        end

        for i,v in ipairs(browseResults) do
            tinsert(itemsFound, v);
        end

        if (AuctionSnipe.snipeStatusText) then
            AuctionSnipe.snipeStatusText:SetText("Gathering Auctions");
        end

        scanIndex = 1;
        totalResultsFound = totalResultsFound + #browseResults;
        wipe(browseResults);

        return "ITEMS";
    end);
    finding:AddEvent("START");
    finding:AddEvent("BROWSE_MORE");
    finding:AddEvent("ITEMS");

    fsm:Add(finding);

    local fsmbrowseMore = FSMState:Acquire("BROWSE_MORE");
    fsmbrowseMore:SetOnEnter(function(self)
        -- reset scan delay here as well
        -- otherwise there will be a delay
        -- even if no items found in the next
        -- browse page
        scanDelay = 0;
        clearNew = true;
        Query.BrowseMore();
        return nil;
    end);
    fsmbrowseMore:AddEvent("FINDING");

    fsm:Add(fsmbrowseMore);

    local items = FSMState:Acquire("ITEMS");
    items:SetOnEnter(function(self)
        Logger.Log("SNIPER", "on items");
        
        if (not Utils.IsClassic()) then
            if (validAuctions and #validAuctions > 0) then
                totalValidAuctionsFound = totalValidAuctionsFound + #validAuctions;
                AuctionList:AddItems(validAuctions, clearNew);
                clearNew = false;
                ClearValidAuctions();
            end
            if (scanIndex <= #itemsFound and #itemsFound > 0) then
                if (AuctionSnipe.snipeStatusText) then
                    AuctionSnipe.snipeStatusText:SetText("Gathering Auctions "..scanIndex.." of "..#itemsFound..' out of '..totalResultsFound);
                end

                Logger.Log("SNIPER", "Next Scan Index: "..scanIndex);

                currentItemScan = itemsFound[scanIndex];
                scanIndex = scanIndex + 1;

                return "SEARCH";
            end
        end

        ClearItemsFound();
        
        scanIndex = 1;

        if (totalValidAuctionsFound > 0) then
            scanDelay = Config.Sniper().scanDelay;
            if (Config.Sniper().flashWoWIcon) then
                FlashClientIcon();
            end
        end

        if (totalValidAuctionsFound > 0 and Config.Sniper().dingSound) then
            PlaySound(SOUNDKIT[Config.Sniper().soundKitSound], "Master");
        end

        totalValidAuctionsFound = 0;
        
        if (Utils.IsClassic()) then
            wipe(blocks);
            Query:Last();
        end

        if (AuctionSnipe.snipeStatusText) then
            AuctionSnipe.snipeStatusText:SetText("Waiting to Query");
        end

        if (not Query.fullBrowseResults and not Utils.IsClassic()) then
            Tasker.Delay(GetTime() + scanDelay, function()
                SniperFSM:Process("BROWSE_MORE");
            end, TASKER_TAG);
            return nil;
        end

        Tasker.Delay(GetTime() + scanDelay, function()
            SniperFSM:Process("START");
        end, TASKER_TAG);
        return nil;
    end);
    items:SetOnExit(function(self, next)
        if (not next) then
            scanIndex = scanIndex - 1;
            currentItemScan = itemsFound[scanIndex];
        end
    end);
    items:AddEvent("SEARCH");
    items:AddEvent("START");
    items:AddEvent("BROWSE_MORE");

    fsm:Add(items);

    local fsmSearch = FSMState:Acquire("SEARCH");

    fsmSearch:SetOnEnter(function(self)
        if (Utils.IsClassic()) then
            
            Logger.Log("SNIPER", "Sending classic search query");

            scanCount = scanCount + 1;

            if (scanCount > 9999) then scanCount = 1; end

            if (AuctionSnipe.snipeStatusText) then
                AuctionSnipe.snipeStatusText:SetText("Query: "..scanCount.." Page: "..Query.page.." - Query Sent...");
            end

            Query:Search(DEFAULT_BROWSE_QUERY);
        else
            if (#itemsFound == 0) then
                -- we have cleared items found
                -- which means current item scan
                -- has no values in it really
                -- go back to the ITEMS state
                -- to ensure proper continuation
                return "ITEMS";
            else
                lastItemId = currentItemScan.id;
                Logger.Log("SNIPER", "Searching for: "..currentItemScan.id.."."..currentItemScan.iLevel);
                Query.SearchForItem(currentItemScan:Clone());
            end
        end
        return nil;
    end);

    fsmSearch:AddEvent("ITEM_RESULT", function(self, event, item)
        Logger.Log("SNIPER", "item result");

        if (item == nil) then
            return nil;
        end

        if (Utils.IsClassic()) then
            if (not Query:IsLast()) then
                Logger.Log("SNIPER", "Not last classic page");
                return nil;
            end

            if (AuctionSnipe.snipeStatusText) then
                AuctionSnipe.snipeStatusText:SetText("Filtering "..Query.itemIndex.." of "..Query:Count());
            end

            if (not Query:IsFiltered(item)) then
                Recycler:Recycle(item);
                return nil;
            end

            local itemCount = item.count;
            if (not blocks[item.hash]) then
                blocks[item.hash] = item;
                blocks[item.hash].total = 0;
                tinsert(validAuctions, blocks[item.hash]);
            end
        
            local block = blocks[item.hash];
        
            if(not block.auctions) then
                block.auctions = {};
            end
        
            block.total = block.total + itemCount;
            tinsert(block.auctions, item);
        else
            -- we track all current auction ids for the search
            -- so we can remove ones that are no longer there
            -- on search complete
            currentAuctionIds[AuctionList:Hash(item)] = true;

            local preventResult = AuctionList:IsKnown(item);
            
            if (Config.Sniper().ignoreSingleStacks and not item.auctionId) then
                if (item.count == 1) then
                    Logger.Log("SNIPER", "Ignoring single stack for commodity");
                    return nil;
                end
            end

            if (not preventResult and not item.isOwnerItem) then
                if (Query:IsFiltered(item)) then
                    tinsert(validAuctions, item:Clone());
                    return nil;
                end
            end
        end

        return nil;
    end);
    fsmSearch:AddEvent("SEARCH_COMPLETE", function(self)
        Logger.Log("SNIPER", "search complete");
        if (not Utils.IsClassic()) then
            AuctionList:ClearMissing(currentItemScan, currentAuctionIds);
        else
            if (AuctionSnipe.snipeStatusText) then
                AuctionSnipe.snipeStatusText:SetText("Query: "..scanCount.." Complete");
            end
        end
        return "ITEMS";
    end);
    fsmSearch:SetOnExit(function(self, next)
        -- handle displaying items that have already been processed
        -- when the FSM was interrupted
        if (validAuctions and #validAuctions > 0) then
            totalValidAuctionsFound = totalValidAuctionsFound + #validAuctions;

            if (not Utils.IsClassic()) then
                AuctionList:AddItems(validAuctions, clearNew);
                clearNew = false;
                ClearValidAuctions();
            else
                AuctionList:SetItems(validAuctions);
                if (Config.Sniper().chatMessageNew) then
                    for i,v in ipairs(validAuctions) do
                        if (v.link and v.count and v.ppu and v.count > 0) then
                            print("AnS - New Snipe Available: "..v.link.." x "..v.count.." for "..Utils.PriceToString(v.ppu).."|cFFFFFFFF ppu from "..(v.owner or "?")); 
                        end
                    end
                end
                ClearValidAuctions(); 
            end
        end

        if (not next and not Utils.IsClassic()) then
            scanIndex = scanIndex - 1;
            currentItemScan = itemsFound[scanIndex];
        end
    end);
    fsmSearch:AddEvent("ITEMS");
    
    fsm:Add(fsmSearch);
    fsm:Add(FSMState:Acquire("DROPPED"));

    fsm:Add(FSMState:Acquire("SEARCH_COMPLETE"));
    fsm:Add(FSMState:Acquire("ITEM_RESULT"));

    local buying = FSMState:Acquire("BUYING");
    buying:SetOnEnter(function(self, previous)
        Logger.Log("SNIPER", "initating buying");
        if (AuctionSnipe.processingFrame) then
            AuctionSnipe.processingFrame:Show();
        end

        self.innerState = nil;
        self.previous = previous;
        Logger.Log("SNIPER", "Previous state before buy: "..self.previous);
        return nil;
    end);
    buying:AddEvent("CONFIRM_COMMODITY", function(self)
        self.innerState = "CONFIRM_COMMODITY";
        if (not AuctionList:ConfirmCommoditiesPurchase()) then
            AuctionList:CancelCommoditiesPurchase();
            return "BUY_FINISH", self.previous;
        end
        return nil;
    end);
    buying:AddEvent("CONFIRM_AUCTION", function(self)
        Logger.Log("SNIPER", "confirm auction");
        self.innerState = "CONFIRM_AUCTION";

        if (AuctionList.auction) then
            Logger.Log("SNIPER", "interrupting query and sending search");
            Query.Clear();
            lastItemId = AuctionList.auction.id;
            Query.SearchForItem(AuctionList.auction:Clone(), false, true);
            return nil;
        else
            return "BUY_FINISH", self.previous;
        end
    end)
    buying:AddEvent("SEARCH_COMPLETE", function(self)
        if (self.innerState == "CONFIRM_AUCTION") then
            self.innerState = "SEARCH_COMPLETE";
            StaticPopup_Show ("ANSCONFIRMAUCTION", AuctionList.auction.link, Utils.PriceToString(AuctionList.auction.buyoutPrice));
        end
        return nil;
    end);
    buying:AddEvent("CONFIRMED_AUCTION", function(self)
        if (not Utils.IsClassic() and (self.innerState == "SEARCH_COMPLETE" or self.innerState == nil)) then
            self.innerState = "CONFIRMED_AUCTION";
            Tasker.Clear(TASKER_PURCHASE_TAG);
            AuctionList:ConfirmAuctionPurchase();
            Logger.Log("SNIPER", "Item Purchase Successful");
            return "BUY_FINISH", self.previous;
        elseif (Utils.IsClassic()) then
            return "BUY_FINISH", self.previous;
        end
        return nil;
    end);
    buying:AddEvent("CANCEL_AUCTION", function(self)
        self.innerState = "CANCEL_AUCTION";
        Logger.Log("SNIPER", "Purchase Canceled");
        return "BUY_FINISH", self.previous;
    end);
    buying:AddEvent("CANCEL_COMMODITY", function(self)
        self.innerState = "CANCEL_COMMODITY";
        AuctionList:CancelCommoditiesPurchase();
        return "BUY_FINISH", self.previous;
    end);
    buying:AddEvent("CONFIRMED_COMMODITY", function(self)
        self.innerState = "CONFIRMED_COMMODITY";
        return "BUY_FINISH", self.previous;
    end);
    buying:AddEvent("DROPPED", function(self)
        -- we test for this inner state
        -- since the QueryFSM will automatically retry
        -- the SearchForItem until it can do it
        -- otherwise if it dropped during another part
        -- of a commodity buy then cancel the commodity
        if (self.innerState ~= "CONFIRM_AUCTION" and self.innerState ~= nil) then
            return "BUY_FINISH", self.previous;
        end
        return nil;
    end);
    buying:SetOnExit(function(self, next)
        if (not next or next == "BUY_FINISH") then
            Logger.Log("SNIPER", "exiting buy mode");
            if (AuctionSnipe.processingFrame) then
                AuctionSnipe.processingFrame:Hide();
            end
            AuctionList.commodity = nil;
            AuctionList.auction = nil;
            AuctionList.isBuying = false;
        end
    end);
    buying:AddEvent("BUY_FINISH");

    fsm:Add(buying);
    fsm:Add(FSMState:Acquire("CONFIRM_COMMODITY"));
    fsm:Add(FSMState:Acquire("CONFIRM_AUCTION"));
    fsm:Add(FSMState:Acquire("CONFIRMED_AUCTION"));
    fsm:Add(FSMState:Acquire("CANCEL_COMMODITY"));
    fsm:Add(FSMState:Acquire("CANCEL_AUCTION"));
    fsm:Add(FSMState:Acquire("CONFIRMED_COMMODITY"));

    local buyFinish = FSMState:Acquire("BUY_FINISH");
    buyFinish:SetOnEnter(function(self, previous)
        self.previous = previous;
        if (previous) then
            self:AddEvent(previous);
        end

        return previous;
    end);

    buyFinish:SetOnExit(function(self)
        if (self.previous) then
            Logger.Log("SNIPER", "Buy finished returning to previous state: "..self.previous);
            self:RemoveEvent(self.previous);
        end
    end);

    fsm:Add(buyFinish);

    fsm:Start("IDLE");

    return fsm;
end

function AuctionSnipe:StartBuyState()
    if (SniperFSM and AuctionList.auction and SniperFSM.current ~= "NONE" 
        and SniperFSM.current ~= "START_BUYING" and SniperFSM.current ~= "BUYING") then
        
        Logger.Log("SNIPER", "interrupting for buying");
        -- have to adjust previous state based
        -- on whether we are buying from items or idle
        -- so the buy state will return to the proper place
        -- afterward
        local previous = SniperFSM.previous;
        if (SniperFSM.current == "ITEMS") then
            -- ensure previous as ITEMS
            previous = "ITEMS";
        elseif (SniperFSM.current == "IDLE") then
            -- ensure previous as IDLE
            previous = "IDLE";
        end

        Logger.Log("SNIPER", "Starting buying with previous: "..previous);

        -- clear tasker of sniper tasks
        Tasker.Clear(TASKER_TAG);
        -- interrupt fsm
        SniperFSM:Interrupt();

        -- set fsm to none
        -- so we can start buying
        -- without any other state
        -- possibly trying to interrupt
        SniperFSM.current = "NONE";
        SniperFSM:Process("START_BUYING", previous);

        -- it is just an item auction with a search needed
        if (AuctionList.waitingForSearch and not AuctionList.commodity) then
            Logger.Log("SNIPER", "confirming auction with search");
            SniperFSM:Process("CONFIRM_AUCTION");
        -- we purchased the auction without a search required
        -- go ahead wait for success or timeout
        elseif (not AuctionList.waitingForSearch and not AuctionList.commodity) then
            Logger.Log("SNIPER", "confirming auction");
            if (not Utils.IsClassic()) then
                Tasker.Delay(GetTime() + PURCHASE_WAIT_TIME, function()                    
                    SniperFSM:Process("CANCEL_AUCTION");
                end, TASKER_PURCHASE_TAG);
            else
                SniperFSM:Process("CONFIRMED_AUCTION");
            end
        end
    end
end

function AuctionSnipe:BuySelected()
    if (AuctionList and SniperFSM and AuctionList.selectedItem
        and SniperFSM and SniperFSM.current ~= "NONE" and SniperFSM.current ~= "START_BUYING"
        and SniperFSM.current ~= "BUYING" and not AuctionList.auction) then
        -- interrupt current query fsm
        Query.Clear();
        if ((SniperFSM.current == "ITEMS" and lastItemId and AuctionList:IsSelectedSameAsLastId(lastItemId)) or Utils.IsClassic() 
        or (SniperFSM.current == "IDLE" and Query.lastQueryType == "SEARCH"  and lastItemId and AuctionList:IsSelectedSameAsLastId(lastItemId))) then
            AuctionList:BuySelected(true);
        else
            AuctionList:BuySelected();
        end
        self:StartBuyState();
    end
end

function AuctionSnipe:BuyFirst()
    if (AuctionList and SniperFSM and #AuctionList.items > 0 
        and SniperFSM and SniperFSM.current ~= "NONE" and SniperFSM.current ~= "START_BUYING"
        and SniperFSM.current ~= "BUYING" and not AuctionList.auction) then
        -- interrupt current query fsm
        Query.Clear();
        if ((SniperFSM.current == "ITEMS" and lastItemId and AuctionList:IsFirstSameAsLastId(lastItemId)) or Utils.IsClassic() 
        or (SniperFSM.current == "IDLE" and Query.lastQueryType == "SEARCH" and lastItemId and AuctionList:IsFirstSameAsLastId(lastItemId))) then
            AuctionList:BuyFirst(true);
        else
            AuctionList:BuyFirst();
        end
        self:StartBuyState();
    end
end

function AuctionSnipe:Init()
    local d = self;
    if (self.isInited) then
        return;
    end;

    local snipeTemplate = "AnsSnipeBuyTemplate";
    local snipeFilterTemplate = "AnsFilterRowTemplate";

    if (Utils.IsClassic()) then
        snipeTemplate = "AnsSnipeBuyClassicTemplate";
        snipeFilterTemplate = "AnsFilterRowClassicTemplate";
    end

    self.isInited = true;

    --- create main panel
    local frame = CreateFrame("FRAME", "AnsSnipeMainPanel", AHFrame, snipeTemplate);

    local this = self;
    self.frame = frame;

    frame:HookScript("OnShow", function() AuctionSnipe:Show() end);
    frame:HookScript("OnHide", function() AuctionSnipe:Close() end);

    -- new in 8.3 let the AH itself handle the tabs
    -- thanks to blizzard new tab implementation
    -- we only have to set the Key Value to the Frame
    -- Add a DisplayMode for the Frame and Tab

    AHFrame["AnsSnipeMainPanel"] = frame;
    AHFrameDisplayMode.Snipe = {"AnsSnipeMainPanel"};

    AuctionList:OnLoad(frame);

    Ans:AddAHTab("Snipe", AHFrameDisplayMode.Snipe);

    self.filterTreeView = TreeView:Acquire(_G[frame:GetName().."FilterList"], {
        rowHeight = 21,
        childIndent = 16,
        template = snipeFilterTemplate, multiselect = true
    }, function(item)
        if (item.filter and not item.group) then 
            d:ToggleFilter(item.filter)
        elseif (item.filter and item.group) then
            d:ToggleGroup(item.filter, item.group);
        end 
    end);

    self.baseTreeView = TreeView:Acquire(_G[frame:GetName().."BaseList"], {
        rowHeight = 21,
        childIndent = 16,
        template = snipeFilterTemplate, multiselect = true
    }, function(item) d:ToggleBase(item.filter) end);

    if (Utils.IsClassic()) then
        self.baseTreeView:Hide();
    end

    self.startButton = _G[frame:GetName().."BottomBarStart"];
    self.stopButton = _G[frame:GetName().."BottomBarStop"];

    self.startButton:Enable();
    self.stopButton:Disable();

    self.maxBuyoutInput = _G[frame:GetName().."SearchBarMaxPPU"];
    self.minLevelInput = _G[frame:GetName().."SearchBarMinLevel"];
    self.clevelRange = _G[frame:GetName().."SearchBarLevelRange"];
    self.qualityInput = _G[frame:GetName().."SearchBarQuality"];
    self.maxPercentInput = _G[frame:GetName().."SearchBarMaxPercent"];
    self.dingCheckBox = _G[frame:GetName().."SearchBarDingSound"];
    self.processingFrame = _G[frame:GetName().."ResultsProcessing"];
    self.processingFrame:Hide();

    self.searchInput = _G[frame:GetName().."SearchBarSearch"];
    self.snipeStatusText = _G[frame:GetName().."BottomBarStatus"];

    MoneyInputFrame_SetCopper(self.maxBuyoutInput, 0);
    self.minLevelInput:SetText("0");
    self.clevelRange:SetText("0-120");

    self.dingCheckBox:SetChecked(Config.Sniper().dingSound);
    self.maxPercentInput:SetText("100");

    local quality = Config.Sniper().minQuality;

    UIDropDownMenu_Initialize(self.qualityInput, BuildQualityDropDown);
    UIDropDownMenu_SetText(self.qualityInput, ITEM_QUALITY_COLORS[quality].hex..AnsQualityToText[quality]);

    frame:Hide();
end

--- builds treeview item list from known filters
function AuctionSnipe:BuildTreeViewFilters()
    local ops = Config.Operations().Sniping or {};

    wipe(opTreeViewItems);
    wipe(self.activeOps);

    for i,v in ipairs(ops) do
        local pf = {};
        pf.selected = Config.SelectionSniper()[v.id] or false;
        if (pf.selected) then
            tinsert(self.activeOps, v);
        end
        pf.name = v.name;
        pf.expanded = false;
        pf.children = {};
        pf.filter = v;

        v.nonActiveGroups = v.nonActiveGroups or {};

        for i,v2 in ipairs(v.groups) do
            local g = Groups.GetGroupFromId(v2);
            if (g) then
                tinsert(pf.children, {
                    name = g.path,
                    selected = (not v.nonActiveGroups[v2]),
                    expanded = false,
                    children = {},
                    group = v2,
                    filter = v
                });
            end
        end

        tinsert(opTreeViewItems, pf);
    end
end

function AuctionSnipe:BuildTreeViewBase()
    wipe(self.baseFilters);
    wipe(baseTreeViewItems);
    
    for k,v in ipairs(BaseData) do
        local pf = {};
        pf.selected = Config.SelectionBase()[v.path] or false;
        if (pf.selected) then
            tinsert(self.baseFilters, v);
        end
        pf.name = v.name;
        pf.expanded = false;
        pf.filter = v;
        pf.children = {};

        for i = 1, #v.children do
            local s = v.children[i];
            local sf = {};
            sf.selected = Config.SelectionBase()[s.path] or false;
            if (sf.selected) then
                tinsert(self.baseFilters, s);
            end
            sf.name = s.name;
            sf.expanded = false;
            sf.filter = s;
            sf.children = {};

            tinsert(pf.children, sf);

            local subchildren = v.children[i].children;
            for j = 1, #subchildren do
                local ss = subchildren[j];
                local ssf = {};
                ssf.selected = Config.SelectionBase()[ss.path] or false;
                if (ssf.selected) then
                    tinsert(self.baseFilters, ss);
                end
                ssf.name = ss.name;
                ssf.expanded = false;
                ssf.filter = ss;
                ssf.children = {};

                tinsert(sf.children, ssf);
            end
        end

        tinsert(baseTreeViewItems, pf);
    end
end

function AuctionSnipe:Sort(type)
    AuctionList:Sort(type);
end

function AuctionSnipe.OnQuerySearchResult(item)
    SniperFSM:Process("ITEM_RESULT", item);
end

function AuctionSnipe.OnCommodityDialogCancel()
    SniperFSM:Process("CONFIRMED_AUCTION");
end

function AuctionSnipe.OnQuerySearchComplete()
    Logger.Log("SNIPER", "query search complete");
    SniperFSM:Process("SEARCH_COMPLETE");
end

function AuctionSnipe.OnQueryBrowseResults()
    SniperFSM:Process("FINDING");
end

function AuctionSnipe.OnChatMessage(msg)
    if (not SniperFSM or not AuctionSnipe.frame or not AuctionSnipe.frame:IsShown()) then
        return;
    end

    if (strfind(msg, ERR_AUCTION_BID_PLACED) or strfind(msg, ERR_AUCTION_WON)) then
        Logger.Log("SNIPER", "Received BID PLACED Message");
        SniperFSM:Process("CONFIRMED_AUCTION");
    end
end

--- handle errors for buying ---
function AuctionSnipe.OnErrorMessage(type, msg)
    if (not SniperFSM or not AuctionSnipe.frame or not AuctionSnipe.frame:IsShown() or not AuctionList) then
        return;
    end
    if (SniperFSM.current == "BUYING" and Utils.InTable(ERRORS, msg)) then
        Logger.Log("SNIPER", "Item Purchased Failed with: "..msg);
        AuctionList:ConfirmAuctionPurchase();
        SniperFSM:Process("CANCEL_AUCTION");
    end
end

function AuctionSnipe.BrowseFilter(item)
    local self = AuctionSnipe;

    -- if we are not even in the proper state
    -- don't bother to try and filter
    -- just return nil
    if (SniperFSM.current ~= "BROWSE_MORE" and SniperFSM.current ~= "START") then
        return nil;
    end

    browseItem = browseItem + 1;

    if (self.snipeStatusText) then
        self.snipeStatusText:SetText("Filtering Group "..browseItem);
    end

    local hash = Query:GetGroupHash(item);
    local ppu = item.minPrice;

    if (hash and ppu and Config.Sniper().skipSeenGroup) then
        if (lastSeenGroupLowest[hash]) then
            if (lastSeenGroupLowest[hash] == ppu) then
                return nil;
            end

            lastSeenGroupLowest[hash] = ppu;
        else
            lastSeenGroupLowest[hash] = ppu;
        end
    end

    local filtered = Query:GetAuctionData(item);
    return Query:IsFilteredGroup(filtered);
end

function AuctionSnipe:RegisterQueryEvents()
    EventManager:On("QUERY_SEARCH_RESULT", AuctionSnipe.OnQuerySearchResult);
    EventManager:On("QUERY_SEARCH_COMPLETE", AuctionSnipe.OnQuerySearchComplete);
    EventManager:On("QUERY_BROWSE_RESULTS", AuctionSnipe.OnQueryBrowseResults);
    EventManager:On("COMMODITY_DIALOG_CANCEL", AuctionSnipe.OnCommodityDialogCancel);
    EventManager:On("CHAT_MSG_SYSTEM", AuctionSnipe.OnChatMessage);
    EventManager:On("UI_ERROR_MESSAGE", AuctionSnipe.OnErrorMessage);
end

function AuctionSnipe:UnregisterQueryEvents()
    EventManager:Off("QUERY_SEARCH_RESULT", AuctionSnipe.OnQuerySearchResult);
    EventManager:Off("QUERY_SEARCH_COMPLETE", AuctionSnipe.OnQuerySearchComplete);
    EventManager:Off("QUERY_BROWSE_RESULTS", AuctionSnipe.OnQueryBrowseResults);
    EventManager:Off("COMMODITY_DIALOG_CANCEL", AuctionSnipe.OnCommodityDialogCancel);
    EventManager:Off("CHAT_MSG_SYSTEM", AuctionSnipe.OnChatMessage);
    EventManager:Off("UI_ERROR_MESSAGE", AuctionSnipe.OnErrorMessage);
end

function AuctionSnipe:OnUpdate(frame, elapsed)  
end


----
-- Events
---
function AuctionSnipe:RegisterEvents(frame)
    rootFrame = frame;

    frame:RegisterEvent("ADDON_LOADED");
    frame:RegisterEvent("AUCTION_HOUSE_SHOW");
    frame:RegisterEvent("AUCTION_HOUSE_CLOSED");
    --frame:RegisterEvent("PLAYER_MONEY");
end

function AuctionSnipe:EventHandler(frame, event, ...)
    if (event == "ADDON_LOADED") then self:OnAddonLoaded(...) end;

    if(event == "AUCTION_HOUSE_THROTTLED_MESSAGE_DROPPED") then
        -- cancel purchase screen if the throttle message is dropped
        SniperFSM:Process("DROPPED");
    end

    if (event == "COMMODITY_PURCHASE_FAILED" or event == "COMMODITY_PURCHASED" or event == "COMMODITY_PURCHASE_SUCCEEDED") then
        AuctionList:OnCommondityPurchased(event == "COMMODITY_PURCHASE_FAILED");
        SniperFSM:Process("CONFIRMED_COMMODITY");
    end 
    if (event == "COMMODITY_PRICE_UPDATED") then
        local unit, total = ...;
        AuctionList.removeListing = true;
        AuctionList.commodityTotal = total;
        AuctionList.commodityPPU = unit;
        SniperFSM:Process("CONFIRM_COMMODITY");
    end
    if (event == "COMMODITY_PRICE_UNAVAILABLE") then
        AuctionList.removeListing = false;
        SniperFSM:Process("CANCEL_COMMODITY");
    end

    if (event == "AUCTION_HOUSE_SHOW") then self:OnAuctionHouseShow(); end;
    if (event == "AUCTION_HOUSE_CLOSED") then self:OnAuctionHouseClosed(); end;
end

function AuctionSnipe:OnAddonLoaded(...)
    local addonName = select(1, ...);
    if (addonName:lower() == "blizzard_auctionhouseui" or addonName:lower() == "blizzard_auctionui") then
        AHFrame = AuctionHouseFrame or AuctionFrame;
        AHFrameDisplayMode = AuctionHouseFrameDisplayMode or {};
        self:Init();
    end
end

function AuctionSnipe:OnAuctionHouseShow()
end   

function AuctionSnipe:OnAuctionHouseClosed()
    if (self.isInited) then
        if(self.frame) then
            UnregisterEvents(rootFrame, EVENTS_TO_REGISTER);
        end

        self:Stop();

        Query.ClearThrottle();
        
        if (not Utils.IsClassic()) then
            AuctionList:CancelCommoditiesPurchase();
        end
        
        Query.page = 0;
        Query:ClearBlacklist();
        AuctionList:Recycle();
        
        self.baseTreeView:ReleaseView();
        self.filterTreeView:ReleaseView();

        -- clear known auction ids
        wipe(currentAuctionIds);

        -- clear this data
        -- as it is no longer
        -- needed once AH is closed
        -- free up memory
        ClearItemsFound();
        ClearValidAuctions();

        -- clear group lowest
        wipe(lastSeenGroupLowest);
    end
end

---
--- Close Handler
---

function AuctionSnipe:Close()
    if(self.frame and self.isInited) then
        UnregisterEvents(rootFrame, EVENTS_TO_REGISTER);
        self:UnregisterQueryEvents();
    end

    StaticPopup_Hide("ANSCONFIRMAUCTION");
    AuctionList.auction = nil;
    AuctionList.commodity = nil;
    AuctionList.isBuying = nil;

    self:Stop();

    wipe(opTreeViewItems);
    wipe(baseTreeViewItems);

    self.baseTreeView:ReleaseView();
    self.filterTreeView:ReleaseView();

    if (Utils.IsClassic()) then
        AuctionList:SetItems({});
    end 
end

--- 
--- Show Handler
---

function AuctionSnipe:Show()
    if (self.frame and self.isInited) then
        RegisterEvents(rootFrame, EVENTS_TO_REGISTER);
        self:RegisterQueryEvents();
    end

    SniperFSM = BuildStateMachine();

    self:BuildTreeViewFilters();
    self.filterTreeView.items = opTreeViewItems;
    self.filterTreeView:Refresh();

    self:BuildTreeViewBase();
    self.baseTreeView.items = baseTreeViewItems;
    self.baseTreeView:Refresh();

    self.clevelRange:SetText(Config.Sniper().clevel);

    self.minLevelInput:SetText(Config.Sniper().ilevel);
end

----
--- Button Handlers for Start & Stop 
---

function AuctionSnipe:LoadCLevelFilter()
    local range = self.clevelRange:GetText();

    Config.Sniper().clevel = range;

    if (range) then
        local low, high = strsplit("-", range);
        if (low == nil and high == nil) then
            DEFAULT_BROWSE_QUERY.minLevel = 0;
            DEFAULT_BROWSE_QUERY.maxLevel = 0;
        elseif (low ~= nil and high ~= nil) then
            DEFAULT_BROWSE_QUERY.minLevel = tonumber(low);
            DEFAULT_BROWSE_QUERY.maxLevel = tonumber(high);
        elseif (low ~= nil and high == nil) then
            DEFAULT_BROWSE_QUERY.minLevel = tonumber(low);
            DEFAULT_BROWSE_QUERY.maxLevel = 0;
        end
    else
        DEFAULT_BROWSE_QUERY.minLevel = 0;
        DEFAULT_BROWSE_QUERY.maxLevel = 0;
    end
end

function AuctionSnipe:LoadBaseFilters()
    local quality = Config.Sniper().minQuality;

    DEFAULT_BROWSE_QUERY.quality = quality;

    wipe(classFilters);
    wipe(qualityFilters);

    for i = quality, 5 do
        tinsert(qualityFilters, AnsQualityToAuctionEnum[i]);
    end

    for i = 1, #self.baseFilters do
        local item = self.baseFilters[i];

        if (item) then
            if (not Utils.IsClassic()) then
                if (item.inventoryType == Data.RUNECARVING) then
                    tinsert(qualityFilters, Enum.AuctionHouseFilter.LegendaryCraftedItemOnly);
                    tinsert(classFilters, {classID = item.classID, subClassID = item.subClassID, inventoryType = nil});
                else
                    tinsert(classFilters, {classID = item.classID, subClassID = item.subClassID, inventoryType = item.inventoryType});
                end
            else
                tinsert(classFilters, {classID = item.classID, subClassID = item.subClassID, inventoryType = item.inventoryType});
            end
        end
    end
end

function AuctionSnipe:Start()
    self.startButton:Disable();
    self.stopButton:Enable();

    local maxBuyout = MoneyInputFrame_GetCopper(self.maxBuyoutInput) or 0;
    local ilevel = tonumber(self.minLevelInput:GetText()) or 0;
    local quality = Config.Sniper().minQuality;
    local maxPercent = tonumber(self.maxPercentInput:GetText()) or 100;

    local search = self.searchInput:GetText();

    Config.Sniper().ilevel = ilevel;

    self:LoadCLevelFilter();
    self:LoadBaseFilters();

    ClearItemsFound();
    ClearValidAuctions();
    
    wipe(blocks);

    Sources:Clear();

    DEFAULT_BROWSE_QUERY.searchString = search;
    DEFAULT_BROWSE_QUERY.filters = qualityFilters;
    DEFAULT_BROWSE_QUERY.itemClassFilters = classFilters;

    -- apply classic sort to get 
    -- item sorted by most recent time
    -- posted
    if (Utils.IsClassic()) then
        SortAuctionClearSort("list");
        SortAuctionApplySort("list");
    end

    local realOps = {};

    for i,v in ipairs(self.activeOps) do
        tinsert(realOps, SnipingOp.From(v));
    end

    Query:AssignSnipingOps(realOps);

    scanIndex = 1;
    Query.page = 0;
    Query:AssignDefaults(ilevel, maxBuyout, quality, maxPercent);

    SniperFSM:Process("START");
end

function AuctionSnipe:Stop()
    ClearValidAuctions(); 
    ClearItemsFound();
    
    wipe(lastSeenGroupLowest);
    wipe(browseResults);
    wipe(blocks);

    Tasker.Clear(TASKER_TAG);

    if (SniperFSM) then
        SniperFSM:Interrupt();

        -- reset both previous and current
        -- after interrupt
        SniperFSM.previous = "IDLE";
        SniperFSM.current = "IDLE";
    end

    Query.Clear();

    self.startButton:Enable();
    self.stopButton:Disable();
    
    if (self.snipeStatusText) then
        self.snipeStatusText:SetText("Stopped");
    end
end

---
--- Updates ding
---

function AuctionSnipe:DingSound(f)
    Config.Sniper().dingSound = f:GetChecked();
end

---
--- Handles removing / adding a selected filter
---

function AuctionSnipe:ClearFilters()
    wipe(Config.SelectionSniper());

    self:BuildTreeViewFilters();
    
    self.filterTreeView.items = opTreeViewItems;
    self.filterTreeView:Refresh();
end

function AuctionSnipe:ClearBase()
    wipe(Config.SelectionBase());

    self:BuildTreeViewBase();
    
    self.baseTreeView.items = baseTreeViewItems;
    self.baseTreeView:Refresh();
end

function AuctionSnipe:ToggleFilter(f)
    if (Config.SelectionSniper()[f.id]) then
        self:RemoveFilter(self.activeOps, f);
        Config.SelectionSniper()[f.id] = false;
    else
        tinsert(self.activeOps, f);
        Config.SelectionSniper()[f.id] = true;
    end
end

function AuctionSnipe:ToggleGroup(f, g)
    if (f.nonActiveGroups[g]) then
        f.nonActiveGroups[g] = nil;
    else
        f.nonActiveGroups[g] = true;
    end
end

function AuctionSnipe:ToggleBase(f)
    if (Config.SelectionBase()[f.path]) then
        self:RemoveFilter(self.baseFilters, f);
        Config.SelectionBase()[f.path] = false;
    else
        tinsert(self.baseFilters, f);
        Config.SelectionBase()[f.path] = true;
    end
end

function AuctionSnipe:RemoveFilter(filters, f)
    for i, v in ipairs(filters) do
        if (v == f) then
            tremove(filters, i);
            return;
        end
    end
end