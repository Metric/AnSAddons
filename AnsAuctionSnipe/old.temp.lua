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
            PlaySound(SOUNDKIT[], "Master");
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
        Tasker.Delay(GetTime() + 5, function()
            if (fsm.current == "SEARCH") then
                Logger.Log("SNIPER", "timed out on search");
                fsm:Process("SEARCH_COMPLETE");
            end
        end, TASKER_TAG_QUERY);
        return nil;
    end);

    fsmSearch:AddEvent("ITEM_RESULT", function(self, event, item)
        Tasker.Clear(TASKER_TAG_QUERY);

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

            if (item.isOwnerItem) then
                Recycler:Recycle(item);
                return nil;
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
        Tasker.Clear(TASKER_TAG_QUERY);
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
        Tasker.Clear(TASKER_TAG_QUERY);
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
        if (not Utils.IsClassic()) then
            self.innerState = "CONFIRMED_AUCTION";
            Tasker.Clear(TASKER_PURCHASE_TAG);
            AuctionList:ConfirmAuctionPurchase();
            Logger.Log("SNIPER", "Item Purchase");
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
                Tasker.Delay(GetTime() + 0.5, function()
                    SniperFSM:Process("CONFIRMED_AUCTION");
                end, TASKER_TAG);
            end
        end
    end
end

function Remove(auction)
    -- todo: implement in module system
    local blockHash = Hash(auction);

    -- finding block
    for i = 1, #self.items do
        local item = self.items[i];
        if (Hash(item) == blockHash and item.link == auction.link) then
            RemoveKnown(item);

            if (Utils.IsClassic()) then
                Recycler:Recycle(tremove(self.items, i));
            else
                tremove(self.items, i);
            end

            if (self.selectedEntry == i or item == self.selectedItem) then
                self.selectedEntry = -1;
                self.selectedItem = nil;
                self:ShowSelectedItem();
            end

            self:Refresh();
            return;
        end
    end
end

function RemoveAmount(auction, count)
    -- todo: implement this in the module system itself
    local blockHash = Hash(block);

    -- finding block
    for i = 1, #self.items do
        local item = self.items[i];

        if (Hash(item) == blockHash and item.link == block.link) then
            if (not Utils.IsClassic()) then
                RemoveKnown(item);
            end
        
            if (Utils.IsClassic()) then
                item.total = item.total - count;
            else
                item.count = item.count - count;

                -- ensure block counts match on retail
                block.count = item.count;
            end

            -- for commodities
            if (not Utils.IsClassic() and item.count > 0) then
                AddKnown(item);
            end

            local isRecycled = false;
            if (Utils.IsClassic() and item.total <= 0) then
                isRecycled = true;
                Recycler:Recycle(tremove(self.items, i));
            elseif (not Utils.IsClassic() and item.count <= 0) then
                isRecycled = true;
                tremove(self.items, i);
            end

            if (isRecycled) then
                if (self.selectedEntry == i or item == self.selectedItem) then
                    self.selectedEntry = -1;
                    self.selectedItem = nil;
                    self:ShowSelectedItem();
                end
            end

            self:Refresh();
            return;
        end
    end 
end