local Core = select(2, ...);

local TUJDB = Core.Database.TUJ;
local TSMDB = Core.Database.TSM;

local Sources = Core.Sources;

local Utils = Core.Utils;
local Groups = Core.Utils.Groups;

local Config = Core.Config;

local MinimapIcon = Core.MinimapIcon;
local EventManager = Core.EventManager;
local Analytics = Core.Analytics;
local Operations = Core.Operations;
local SnipingOperation = Operations.Sniping;

local DefaultGroups = Core.Data;
local AuctionQuery = Core.Auctions.Query;
local Crafting = Core.Crafting;
local Destroy = Core.Destroy;
local Draggable = Utils.Draggable;

local AHFrame = nil;
local AH_TAB_CLICK = nil;

-- temporary for now to make sure
-- ANS_FILTERS exist in some form
-- even if you did not have it originally
ANS_FILTERS = ANS_FILTERS or {};

Ans = {};
Ans.__index = Ans;

Ans.API = Core;

-- note: recopy from other site that always has latest
-- fun fact blizzard still has not fixed this fucking issue on TBC
-- so we will fix it for them, since the function is global
local function FixTBCAuctionHouseUpdate()
    if (Utils.IsTBC()) then
        print("Ans - Applying TBC AuctionHouseUpdate Fix");
        local originalBrowseUpdate = _G["AuctionFrameBrowse_Update"];
        _G["AuctionFrameBrowse_Update"] = function()
            if (not AuctionFrame_DoesCategoryHaveFlag("WOW_TOKEN_FLAG", AuctionFrameBrowse.selectedCategoryIndex)) then
                local numBatchAuctions, totalAuctions = GetNumAuctionItems("list");
                local button, buttonName, buttonHighlight, iconTexture, itemName, color, itemCount, moneyFrame, yourBidText, buyoutFrame, buyoutMoney;
                local offset = FauxScrollFrame_GetOffset(BrowseScrollFrame);
                local index;
                local isLastSlotEmpty;
                local name, texture, count, quality, canUse, level, levelColHeader, minBid, minIncrement, buyoutPrice, duration, bidAmount, highBidder, bidderFullName, owner, ownerFullName, saleStatus, itemId, hasAllInfo;
                local displayedPrice, requiredBid;
                local link;

                BrowseBidButton:Show();
                BrowseBuyoutButton:Show();
                BrowseBidButton:Disable();
                BrowseBuyoutButton:Disable();
                -- Update sort arrows
                AuctionFrameBrowse_UpdateArrows();
        
                -- Show the no results text if no items found
                if ( numBatchAuctions == 0 ) then
                    BrowseNoResultsText:Show();
                else
                    BrowseNoResultsText:Hide();
                end
        
                -- why the fuck are you recalculating this in the for loop blizz?
                local startIndex = NUM_AUCTION_ITEMS_PER_PAGE * AuctionFrameBrowse.page;
                local endIndex = startIndex + numBatchAuctions;

                for i=1, NUM_BROWSE_TO_DISPLAY do
                    index = offset + i + startIndex;
                    button = _G["BrowseButton"..i];
                    local shouldHide = index > endIndex;
                    if ( not shouldHide ) then
                        name, texture, count, quality, canUse, level, levelColHeader, minBid, minIncrement, buyoutPrice, bidAmount, highBidder, bidderFullName, owner, ownerFullName, saleStatus, itemId, hasAllInfo =  GetAuctionItemInfo("list", offset + i);
                        link = GetAuctionItemLink("list", offset + i);
                        -- bug fix for blizz since they cannot check this
                        -- as they don't give a shit

                        -- apparently on TBC hasAllInfo still returns true
                        -- even if it doesn't have all the info for quality, name, texture etc
                        -- So, to really verify if we have all the info
                        -- we need to also check for GetAuctionItemLink("list", offset + i);
                        -- if the link does not exist, then we really do not have all the info

                        if (not hasAllInfo or not link) then --Bug  145328
                            shouldHide = true;
                        end
                    end
                    
                    -- Show or hide auction buttons
                    if ( shouldHide ) then
                        button:Hide();
                        -- If the last button is empty then set isLastSlotEmpty var
                        if ( i == NUM_BROWSE_TO_DISPLAY ) then
                            isLastSlotEmpty = 1;
                        end
                    else
                        button:Show();
        
                        buttonName = "BrowseButton"..i;
                        duration = GetAuctionItemTimeLeft("list", offset + i);
        
                        -- Resize button if there isn't a scrollbar
                        buttonHighlight = _G["BrowseButton"..i.."Highlight"];
                        if ( numBatchAuctions < NUM_BROWSE_TO_DISPLAY ) then
                            button:SetWidth(625);
                            buttonHighlight:SetWidth(589);
                            BrowseCurrentBidSort:SetWidth(207);
                        elseif ( numBatchAuctions == NUM_BROWSE_TO_DISPLAY and totalAuctions <= NUM_BROWSE_TO_DISPLAY ) then
                            button:SetWidth(625);
                            buttonHighlight:SetWidth(589);
                            BrowseCurrentBidSort:SetWidth(207);
                        else
                            button:SetWidth(600);
                            buttonHighlight:SetWidth(562);
                            BrowseCurrentBidSort:SetWidth(184);
                        end
                        -- Set name and quality color
                        color = ITEM_QUALITY_COLORS[quality];

                        -- bug fix for blizz since they cannot check this
                        -- as they are retarded apparently and don't give a shit
                        if (not color) then
                            -- turns out quality can be nil in some cases
                            -- this is due to hasAllInfo not being accurate on TBC
                            color = ITEM_QUALITY_COLORS[0] or ITEM_QUALITY_COLORS[1];
                        end

                        itemName = _G[buttonName.."Name"];
                        itemName:SetText(name);
                        itemName:SetVertexColor(color.r, color.g, color.b);
                        local itemButton = _G[buttonName.."Item"];
        
                        -- Set level
                        if ( levelColHeader == "REQ_LEVEL_ABBR" and level > UnitLevel("player") ) then
                            _G[buttonName.."Level"]:SetText(RED_FONT_COLOR_CODE..level..FONT_COLOR_CODE_CLOSE);
                        else
                            _G[buttonName.."Level"]:SetText(level);
                        end
                        -- Set closing time
                        _G[buttonName.."ClosingTimeText"]:SetText(AuctionFrame_GetTimeLeftText(duration));
                        _G[buttonName.."ClosingTime"].tooltip = AuctionFrame_GetTimeLeftTooltipText(duration);
                        -- Set item texture, count, and usability
                        iconTexture = _G[buttonName.."ItemIconTexture"];
                        iconTexture:SetTexture(texture);
                        if ( not canUse ) then
                            iconTexture:SetVertexColor(1.0, 0.1, 0.1);
                        else
                            iconTexture:SetVertexColor(1.0, 1.0, 1.0);
                        end
                        itemCount = _G[buttonName.."ItemCount"];
                        if ( count > 1 ) then
                            itemCount:SetText(count);
                            itemCount:Show();
                        else
                            itemCount:Hide();
                        end
                        -- Set high bid
                        moneyFrame = _G[buttonName.."MoneyFrame"];
                        -- If not bidAmount set the bid amount to the min bid
                        if ( bidAmount == 0 ) then
                            displayedPrice = minBid;
                            requiredBid = minBid;
                        else
                            displayedPrice = bidAmount;
                            requiredBid = bidAmount + minIncrement ;
                        end
                        MoneyFrame_Update(moneyFrame:GetName(), displayedPrice);
        
                        yourBidText = _G[buttonName.."YourBidText"];
                        if ( highBidder ) then
                            yourBidText:Show();
                        else
                            yourBidText:Hide();
                        end
                        
                        if ( requiredBid >= MAXIMUM_BID_PRICE ) then
                            -- Lie about our buyout price
                            buyoutPrice = requiredBid;
                        end
                        buyoutFrame = _G[buttonName.."BuyoutFrame"];
                        if ( buyoutPrice > 0 ) then
                            moneyFrame:SetPoint("RIGHT", button, "RIGHT", 10, 10);
                            buyoutMoney = _G[buyoutFrame:GetName().."Money"];
                            MoneyFrame_Update(buyoutMoney, buyoutPrice);
                            buyoutFrame:Show();
                        else
                            moneyFrame:SetPoint("RIGHT", button, "RIGHT", 10, 3);
                            buyoutFrame:Hide();
                        end
                        -- Set high bidder
                        --if ( not highBidder ) then
                        --	highBidder = RED_FONT_COLOR_CODE..NO_BIDS..FONT_COLOR_CODE_CLOSE;
                        --end
                        local highBidderFrame = _G[buttonName.."HighBidder"]
                        highBidderFrame.fullName = ownerFullName;
                        highBidderFrame.Name:SetText(owner);
                        
                        -- this is for comparing to the player name to see if they are the owner of this auction
                        local ownerName;
                        if (not ownerFullName) then
                            ownerName = owner;
                        else
                            ownerName = ownerFullName
                        end
                        
                        button.bidAmount = displayedPrice;
                        button.buyoutPrice = buyoutPrice;
                        button.itemCount = count;
                        button.itemIndex = index;
        
                        -- Set highlight
                        if ( GetSelectedAuctionItem("list") and (offset + i) == GetSelectedAuctionItem("list") ) then
                            button:LockHighlight();
                            
                            if ( buyoutPrice > 0 and buyoutPrice >= minBid ) then
                                local canBuyout = 1;
                                if ( GetMoney() < buyoutPrice ) then
                                    if ( not highBidder or GetMoney()+bidAmount < buyoutPrice ) then
                                        canBuyout = nil;
                                    end
                                end
                                if ( canBuyout and (ownerName ~= UnitName("player")) ) then
                                    BrowseBuyoutButton:Enable();
                                    AuctionFrame.buyoutPrice = buyoutPrice;
                                end
                            else
                                AuctionFrame.buyoutPrice = nil;
                            end
                            -- Set bid
                            MoneyInputFrame_SetCopper(BrowseBidPrice, requiredBid);
        
                            if ( not highBidder and ownerName ~= UnitName("player") and GetMoney() >= MoneyInputFrame_GetCopper(BrowseBidPrice) and MoneyInputFrame_GetCopper(BrowseBidPrice) <= MAXIMUM_BID_PRICE ) then
                                BrowseBidButton:Enable();
                            end
                        else
                            button:UnlockHighlight();
                        end
                    end
                end
        
                -- Update scrollFrame
                -- If more than one page of auctions show the next and prev arrows when the scrollframe is scrolled all the way down
                if ( totalAuctions > NUM_AUCTION_ITEMS_PER_PAGE ) then
                    BrowsePrevPageButton.isEnabled = (AuctionFrameBrowse.page ~= 0);
                    BrowseNextPageButton.isEnabled = (AuctionFrameBrowse.page ~= (ceil(totalAuctions/NUM_AUCTION_ITEMS_PER_PAGE) - 1));
                    if ( isLastSlotEmpty ) then
                        BrowsePrevPageButton:Show();
                        BrowseNextPageButton:Show();
                        BrowseSearchCountText:Show();
                        local itemsMin = AuctionFrameBrowse.page * NUM_AUCTION_ITEMS_PER_PAGE + 1;
                        local itemsMax = itemsMin + numBatchAuctions - 1;
                        BrowseSearchCountText:SetFormattedText(NUMBER_OF_RESULTS_TEMPLATE, itemsMin, itemsMax, totalAuctions);
                    else
                        BrowsePrevPageButton:Hide();
                        BrowseNextPageButton:Hide();
                        BrowseSearchCountText:Hide();
                    end
                    
                    -- Artifically inflate the number of results so the scrollbar scrolls one extra row
                    numBatchAuctions = numBatchAuctions + 1;
                else
                    BrowsePrevPageButton.isEnabled = false;
                    BrowseNextPageButton.isEnabled = false;
                    BrowsePrevPageButton:Hide();
                    BrowseNextPageButton:Hide();
                    BrowseSearchCountText:Hide();
                end
                FauxScrollFrame_Update(BrowseScrollFrame, numBatchAuctions, NUM_BROWSE_TO_DISPLAY, AUCTIONS_BUTTON_HEIGHT);
            end
        end
    end
end

-- slash commands for hiding minimap icon
-- and access ans window when icon is hidden
SlashCmdList["ANS_SLASHANS"] = function(msg)
    if (msg == "") then
        AnsMainWindow:Toggle();
    elseif (msg == "resetwindows") then
        Draggable.Reset();
    elseif (msg == "destroy") then
        if (AnsDestroyWindow) then
            AnsDestroyWindow:Populate();
            AnsDestroyWindow:Show();
        end
    end
end
SLASH_ANS_SLASHANS1 = "/ans";

SlashCmdList["ANS_SLASHMINIMAP"] = function(msg)
	if (msg == "") then
		if (Config.General().minimapShown) then
			Config.General().minimapShown = false;
			Ans.MiniButton:Hide();
		else
			Config.General().minimapShown = true;
			Ans.MiniButton:Show();
		end
	else
		local deg = tonumber(msg);
		Ans.MiniButton.angle = deg;
		Ans.MiniButton:Reposition();
		Ans.SaveMiniButton(deg);
	end
end
SLASH_ANS_SLASHMINIMAP1 = "/ansminimap";

StaticPopupDialogs["ANS_NO_PRICING"] = {
    text = "Looks like, you have no data pricing source! TheUndermineJournal, TSM, and AnsAuctionData are currently supported.",
    button1 = "OKAY",
    OnAccept = function() end,
    timeout = 0,
    whileDead = false,
    hideOnEscape = true,
    preferredIndex = 3
};

local TUJOnlyPercentFn = "tujmarket";
local TSMOnlyPercentFn = "dbmarket";
local AtrOnlyPercentFn = "atrvalue";
local TUJAndTSMPercentFn = "avg(dbmarket,tujmarket)";
local AnsOnlyPercentFn = "avg(ansrecent,ansmarket)";
local TSMMaterialCost = "min(dbmarket, first(vendorbuy, dbminbuyout))";
local TSMCraftingValue = "first(dbminbuyout, dbmarket)";
local AnsMaterialCost = "min(ansmarket, first(vendorbuy, ansrecent))";
local AnsCraftingValue = "first(vendorbuy, avg(ansrecent, ansmarket))";
local TujMatCraftValue = "first(vendorbuy, tujmarket)";
local AtrMatCraftValue = "first(vendorbuy, atrvalue)";

local function AuctionTab_OnClick(self, button, down, index)
    AH_TAB_CLICK(self, button, down, index);

    for i = 1, AHFrame.numTabs do
        local tab = _G["AuctionFrameTab"..i];
        if (tab.displayMode) then
            for k,v in ipairs(tab.displayMode) do
                if (AHFrame[v]) then
                    AHFrame[v]:Hide();
                end
            end
        end
    end

    if (self.displayMode) then
        for k,v in ipairs(self.displayMode) do
            if (AHFrame[v]) then
                AHFrame[v]:Show();
            end
        end
    end
end

local function AddRetailAHTab(name, displayMode)
    local n = #AHFrame.Tabs + 1;
    local lastTab = AHFrame.Tabs[n - 1];
    local framename = "AuctionHouseFrameTab"..n;
    local frame = CreateFrame("BUTTON", framename, AHFrame, "AuctionHouseFrameDisplayModeTabTemplate");

    frame:SetID(n);
    frame:SetText(name);
    frame:SetNormalFontObject(_G["AnsFontOrange"]);
    frame:SetPoint("LEFT", lastTab, "RIGHT", -15, 0);
    frame.displayMode = displayMode;
    frame:HookScript("OnClick", function() AHFrame:SetTitle(name) end);

    tinsert(AuctionHouseFrame.Tabs, frame);
    AuctionHouseFrame.tabsForDisplayMode[displayMode] = n;

    PanelTemplates_SetNumTabs(AuctionHouseFrame, n);
end

local function AddClassicAHTab(name, displayMode)
    local n = AHFrame.numTabs + 1;
    local lastTab = _G["AuctionFrameTab"..(n - 1)];
    local framename = "AuctionFrameTab"..n;
    local frame = CreateFrame("BUTTON", framename, AHFrame, "AuctionTabTemplate");

    frame:SetID(n);
    frame:SetText(name);
    frame:SetNormalFontObject(_G["AnsFontOrange"]);
    frame:SetPoint("LEFT", lastTab, "RIGHT", -15, 0);
    frame.displayMode = displayMode;
    frame:SetScript("OnClick", AuctionTab_OnClick);

    PanelTemplates_SetNumTabs(AHFrame, n);
    PanelTemplates_EnableTab(AHFrame, n);

    if (AH_TAB_CLICK == nil) then
        AH_TAB_CLICK = AuctionFrameTab_OnClick;
        AuctionFrameTab_OnClick = AuctionTab_OnClick;
    end
end

function Ans:AddAHTab(name, displayMode)
    if (Utils.IsClassic()) then
        AddClassicAHTab(name, displayMode);
    else
        AddRetailAHTab(name, displayMode);
    end
end

function Ans:RegisterEvents(frame)
    self.frame = frame;

    frame:RegisterEvent("VARIABLES_LOADED");
    frame:RegisterEvent("ADDON_LOADED");

    EventManager:Register(frame);
end

function Ans:AddOnLoaded(...)
    local addonName = select(1, ...);
    if (addonName:lower() == "blizzard_auctionhouseui" or addonName:lower() == "blizzard_auctionui") then
        AHFrame = AuctionHouseFrame or AuctionFrame;
        FixTBCAuctionHouseUpdate();
    end
end

function Ans:EventHandler(frame, event, ...)
    if (event == "VARIABLES_LOADED") then 
        self:OnLoad();
        return;
    end

    if (event == "ADDON_LOADED") then
        self:AddOnLoaded(...);
    end

    EventManager:Emit(event, ...);
end

function Ans:OnUpdate(elapsed)
    EventManager:Emit("UPDATE", elapsed);
end

function Ans.SaveMiniButton(angle)
    Config.MiniButton(angle);
end

local function CreateMiniButton()
    Ans.MiniButton = MinimapIcon:Acquire("AnsMiniButton", "Interface\\AddOns\\AnS\\Images\\ansicon", 
    function() AnsMainWindow:Toggle() end, 
    function() 
        if (AnsDestroyWindow) then
            AnsDestroyWindow:Populate(false);
            AnsDestroyWindow:Show();
        end
    end,
    Draggable.Reset,
    Ans.SaveMiniButton, Config.MiniButton(), {"|cFFCC00FFAnS ["..GetAddOnMetadata("AnS", "Version").."]", "Click to Toggle", "Click & Drag to Move", "Ctrl+Click to Reset Window Positions", "Right Click to Show Destroy Window"});

    if (Config.General().minimapShown) then
        Ans.MiniButton:Show();
    else
        Ans.MiniButton:Hide();
    end
end

function Ans:OnLoad()
    self:Migrate();
    self:RegisterPriceSources();

    CreateMiniButton();

    Groups.BuildGroupPaths(DefaultGroups);
    Groups.BuildGroupPaths(Config.Groups());

    EventManager:Emit("ANS_DATA_READY");
end

function Ans:MigrateFiltersToGroups(parent, root)
    for i,f in ipairs(parent) do
        local t = {
            id = Utils.Guid(),
            name = f.name,
            ids = f.ids,
            children = {}
        };

        f.id = t.id;
        tinsert(root, t);

        if (#f.children > 0) then
            self:MigrateFiltersToGroups(f.children, t.children);
        end
    end
end

function Ans:MigrateFiltersToSnipingOperations(items, parentName)
    for i,f in ipairs(items) do
        local snipeName = f.name;
        if (parentName) then
            snipeName = parentName.."."..f.name;
        end

        if (f.priceFn and #f.priceFn > 0) then
            local tmp = SnipingOperation.Config(snipeName);
            tmp.price = f.priceFn;
            tmp.exactMatch = f.exactMatch;
            if (f.id) then
                tinsert(tmp.groups, f.id);
            end
            tinsert(Config.Operations().Sniping, tmp);
        end

        if (#f.children > 0) then
            self:MigrateFiltersToSnipingOperations(f.children, snipeName);
        end
    end
end

local function RegisterTSMCustomDataSources() 
    if (not TSM_API) then
        return;
    end

    local keys = {};
    TSM_API.GetPriceSourceKeys(keys);
    for i,v in ipairs(keys) do
        if (type(v) == "string") then
            Sources:Register(v, TSMDB.GetPrice, v);
        end
    end
end

function Ans:RegisterPriceSources()
    local tsmEnabled = false;
    local tujEnabled = false;
    local ansEnabled = false;
    
    local auctionatorEnabled = false;

    if (Utils.IsAddonEnabled("Auctionator")) then
        auctionatorEnabled = true; 
    end
    
    if (TSM_API or TSMAPI) then
        tsmEnabled = true;
    end

    if (AnsAuctionData) then
        ansEnabled = true;
    end

    if (TUJMarketInfo) then
        tujEnabled = true;
    end

    -- set sniping default source
    if (tujEnabled and tsmEnabled and (not Config.Sniper().source or Config.Sniper().source:len() == 0)) then
        print("AnS: setting default tuj and tsm source");
        Config.Sniper().source = TUJAndTSMPercentFn;
    elseif (tujEnabled and not tsmEnabled and (not Config.Sniper().source or Config.Sniper().source:len() == 0)) then
        print("AnS: setting default tuj source");
        Config.Sniper().source = TUJOnlyPercentFn;
    elseif (tsmEnabled and not tujEnabled and (not Config.Sniper().source or Config.Sniper().source:len() == 0)) then
        print("AnS: setting default tsm source");
        Config.Sniper().source = TSMOnlyPercentFn;
    elseif (auctionatorEnabled and (not Config.Sniper().source or Config.Sniper().source:len() == 0)) then
        print("AnS: setting default auctionator source");
        Config.Snipe().source = AtrOnlyPercentFn;
    elseif (ansEnabled and (not Config.Sniper().source or Config.Sniper().source:len() == 0)) then
        print("AnS: setting default AnsAuctionData source");
        Config.Sniper().source = AnsOnlyPercentFn;
    end

    -- set default crafting stuff
    if (tujEnabled and tsmEnabled and (not Config.Crafting().materialCost or Config.Crafting().materialCost:len() == 0)) then
        Config.Crafting().materialCost = TSMMaterialCost;
        Config.Crafting().craftValue = TSMCraftingValue;
    elseif (tujEnabled and not tsmEnabled and (not Config.Crafting().materialCost or Config.Crafting().materialCost:len() == 0)) then
        Config.Crafting().materialCost = TujMatCraftValue;
        Config.Crafting().craftValue = TujMatCraftValue;
    elseif (tsmEnabled and not tujEnabled and (not Config.Crafting().materialCost or Config.Crafting().materialCost:len() == 0)) then
        Config.Crafting().materialCost = TSMMaterialCost;
        Config.Crafting().craftValue = TSMCraftingValue;
    elseif (auctionatorEnabled and (not Config.Crafting().materialCost or Config.Crafting().materialCost:len() == 0)) then
        Config.Crafting().materialCost = AtrMatCraftValue;
        Config.Crafting().craftValue = AtrMatCraftValue;
    elseif (ansEnabled and (not Config.Crafting().materialCost or Config.Crafting().materialCost:len() == 0)) then
        Config.Crafting().materialCost = AnsMaterialCost;
        Config.Crafting().craftValue = AnsCraftingValue;
    end

    if (not tsmEnabled and not tujEnabled and not ansEnabled and not auctionatorEnabled) then
        StaticPopup_Show("ANS_NO_PRICING");
    end

    if (tsmEnabled) then

        print("AnS: found TSM pricing source");
        Sources:Register("DBMarket", TSMDB.GetPrice, "DBMarket");
        Sources:Register("DBMinBuyout", TSMDB.GetPrice, "DBMinBuyout");
        Sources:Register("DBHistorical", TSMDB.GetPrice, "DBHistorical");
        Sources:Register("DBRegionMinBuyoutAvg", TSMDB.GetPrice, "DBRegionMinBuyoutAvg");
        Sources:Register("DBRegionMarketAvg", TSMDB.GetPrice, "DBRegionMarketAvg");
        Sources:Register("DBRegionHistorical", TSMDB.GetPrice, "DBRegionHistorical");
        Sources:Register("DBRegionSaleAvg", TSMDB.GetPrice, "DBRegionSaleAvg");
        Sources:Register("DBRegionSaleRate", TSMDB.GetSaleInfo, "DBRegionSaleRate");
        Sources:Register("DBRegionSoldPerDay", TSMDB.GetSaleInfo, "DBRegionSoldPerDay");
        Sources:Register("AvgSell", TSMDB.GetPrice, "AvgSell");
        Sources:Register("AvgBuy", TSMDB.GetPrice, "AvgBuy");
        Sources:Register("Destroy", TSMDB.GetPrice, "Destroy");
        Sources:Register("MaxBuy", TSMDB.GetPrice, "MaxBuy");
        Sources:Register("MaxSell", TSMDB.GetPrice, "MaxSell");
        Sources:Register("NumInventory", TSMDB.GetPrice, "NumInventory");

        RegisterTSMCustomDataSources();
    end

    if (tujEnabled) then
        print("AnS: found TUJ pricing source");
        Sources:Register("TUJMarket", TUJDB.GetPrice, "market");
        Sources:Register("TUJRecent", TUJDB.GetPrice, "recent");
        Sources:Register("TUJGlobalMedian", TUJDB.GetPrice, "globalMedian");
        Sources:Register("TUJGlobalMean", TUJDB.GetPrice, "globalMean");
        Sources:Register("TUJAge", TUJDB.GetPrice, "age");
        Sources:Register("TUJDays", TUJDB.GetPrice, "days");
        Sources:Register("TUJStdDev", TUJDB.GetPrice, "stddev");
        Sources:Register("TUJGlobalStdDev", TUJDB.GetPrice, "globalStdDev");
    end

    if (ansEnabled) then
        print("AnS: found AnS pricing source");
        Sources:Register("ANSRecent", AnsAuctionData.GetRealmValue, "recent");
        Sources:Register("ANSMarket", AnsAuctionData.GetRealmValue, "market");
        Sources:Register("ANSMin", AnsAuctionData.GetRealmValue, "min");
        Sources:Register("ANS3Day", AnsAuctionData.GetRealmValue, "3day");
        Sources:Register("ANSRegionMarket", AnsAuctionData.GetRegionValue, "market");
        Sources:Register("ANSRegionMin", AnsAuctionData.GetRegionValue, "min");
    end

    if (auctionatorEnabled) then
         print("AnS: found Auctionator pricing source");

         if (Atr_GetAuctionBuyout) then
            Sources:Register("AtrValue", function(link, key)
                if (strfind(link, "[ip]:")) then
                    link = Utils.GetLink(link, true);
                end
                
                return Atr_GetAuctionBuyout(link) or 0;
            end, nil);
        elseif (Auctionator and Auctionator.API 
            and Auctionator.API.v1 
            and Auctionator.API.v1.GetAuctionPriceByItemLink 
            and Auctionator.API.v1.GetAuctionPriceByItemID) then
            
            Sources:Register("AtrValue", function(link, key)
                if (type(link) == "string" 
                    and strfind(link, "[ip]:")) then
                        link = Utils.GetLink(link, true);
                end

                if (type(link) == "number") then
                    return Auctionator.API.v1.GetAuctionPriceByItemID("AnS", link) or 0;
                else
                    return Auctionator.API.v1.GetAuctionPriceByItemLink("AnS", link) or 0;
                end
            end, nil);
        end
    end
end

function Ans:Migrate()

    Config.MigrateCopy("ANS_ANALYTICS_DATA", Config.Analytics(), true);
    Config.MigrateArray("ANS_CUSTOM_VARS", Config.CustomSources(), true);
    Config.MigrateDict("ANS_GLOBAL_SETTINGS", Config.General(),
        {
            ["showDressing"] = "showDressing",
            ["useCoinIcons"] = "useCoinIcons",
            ["tooltipRealm3Day"] = "tooltipRealm3Day",
            ["tooltipRealmMarket"] = "tooltipRealmMarket",
            ["tooltipRealmRecent"] = "tooltipRealmRecent",
            ["tooltipRealmMin"] = "tooltipRealmMin"
        }
    );
    Config.MigrateDict("ANS_GLOBAL_SETTINGS", Config.Sniper(),
        {
            ["percentFn"] = "source",
            ["priceFn"] = "pricing",
            ["dingSound"] = "dingSound",
            ["itemsPerUpdate"] = "itemsPerUpdate",
            ["useCommodityConfirm"] = "useCommodityConfirm",
            ["characterBlacklist"] = "characterBlacklist"
        },
        true
    );

    self:MigrateFiltersToGroups(ANS_FILTERS, Config.Groups());
    self:MigrateFiltersToSnipingOperations(ANS_FILTERS);

    wipe(ANS_FILTERS);

    if (#Config.Groups() == 0) then
        Config.Groups(DefaultGroups);
    end
end