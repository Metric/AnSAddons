local Core = select(2, ...);
local Config = Ans.API.Config;
local Query = Ans.API.Auctions.Query;
local Recycler = Ans.API.Auctions.Recycler;
local Utils = Ans.API.Utils;
local EventManager = Ans.API.EventManager;
local EventState = Ans.API.EventState;

local Tasker = Ans.API.Tasker;
local TASKER_TAG = "SNIPER";

local Logger = Ans.API.Logger;

local Sniper = AuctionSnipe;
local Retail = Ans.API.Object.Register("Retail", Sniper);

local query = Query:Acquire(0,0,{0},0);

if (not Utils.IsClassic()) then
    Sniper.module = Retail;
end

Retail.state = nil;
Retail.validAuctions = {};
Retail.lastSeenGroups = {};
Retail.known = {};

local validAuctions = Retail.validAuctions;
local lastSeenGroups = Retail.lastSeenGroups;
local known = Retail.known;

local function Wipe()
    wipe(validAuctions);
    wipe(lastSeenGroups);
    wipe(known);
end

Retail.Wipe = Wipe;

function Retail.SetOptions(ilevel, buyout, quality, percent)
    query:SetOptions(ilevel, buyout, quality, percent);
end

function Retail.QualitySelected(self, arg1, arg2, checked)
    local input = Sniper.qualityInput;
    local qualities = Config.Sniper().qualities;
    
    local text = Sniper.AnsQualityToText[arg1];
    local color = ITEM_QUALITY_COLORS[arg1].hex;

    if (checked) then
        Config.Sniper().minQuality = arg1;
        if (input ~= nil) then
            UIDropDownMenu_SetText(Sniper.qualityInput, color..text);
        end
    end

    qualities[arg1] = checked and arg1 or nil;
end

function Retail.GroupFilter(item)
    local info = query:GetItemKeyInfo(item.itemKey);
    local hash = Query.ItemKeyHash(item.itemKey);
    local ppu = item.minPrice;

    if (hash) then
        Logger.Log("SNIPER", "trying to filter browse group: "..hash);
    end

    if (not info or not hash or not ppu) then
        return nil;
    end

    if (Config.Sniper().skipSeenGroup) then
        if (lastSeenGroups[hash]) then
            if (lastSeenGroups[hash] == ppu) then
                return nil;
            end

            lastSeenGroups[hash] = ppu;
        else
            lastSeenGroups[hash] = ppu;
        end
    end

    local g = query:NextGroup(item, info);
    if (not g) then
        return nil;
    end
    local isValid = query:IsValidGroup(g);
    if (not isValid) then
        Recycler:Recycle(g);
        return nil;
    end
    return g;
end

function Retail:GroupScan(filter)
    local this = self;
    local fn = self.groupScanFn or {};
    wipe(fn);
    fn.event = function(self, state, name)
        if (not self.requested) then
            return false;
        end

        Tasker.Schedule(function()
            EventManager:Emit("SNIPER_GROUP_SCAN", #query.results);
        end, TASKER_TAG);
        return true;
    end
    fn.process = function(self, state)
        if (query:IsActive()) then
            return true;
        end

        self.requested = true;
        query:Browse(filter, this.GroupFilter);
        return false;
    end
    fn.result = function(self, state)
        return nil;
    end
    self.groupScanFn = fn;
    self.state = EventState:Acquire(fn, "QUERY_BROWSE_COMPLETE");
end

function Retail:PriceScan(isKnown)
    wipe(validAuctions);
    wipe(known);

    local inventory = query.results;
    local item = inventory[1];

    if (not item) then
        return nil;
    end

    local this = self;
    local fn = self.priceScanFn or {};
    wipe(fn);
    fn.event = function(self, state, name, v)
        if (not self.requested) then
            return false;
        end

        if (name == "QUERY_SEARCH_RESULT") then
            if (not v) then
                return false;
            end

            Logger.Log("SNIPER", "Search Result");

            local hash = Query.ItemHash(v);
            known[hash] = true;

            local preventResult = isKnown and isKnown(v);
            local ignoreSingles = Config.Sniper().ignoreSingleStacks;
        
            if (ignoreSingles and not v.auctionId and v.count == 1) then
                Logger.Log("SNIPER", "Ignoring single stack for commodity");
                return false;
            end
            
            if (not preventResult and not v.isOwnerItem) then
                local valid = query:IsValidAuction(v);
                if (valid) then
                    tinsert(validAuctions, v:Clone());
                end
            end
        
            return false;
        elseif (name == "QUERY_SEARCH_COMPLETE") then
            Logger.Log("SNIPER", "Search Complete");
            Logger.Log("SNIPER", "Total Valid Found: "..#validAuctions);

            Recycler:Recycle(item);
            tremove(inventory, 1); 

            Tasker.Schedule(function()
                EventManager:Emit("SNIPER_PRICE_SCAN", validAuctions, #inventory);
            end, TASKER_TAG);

            return true;
        end

        return false;
    end
    fn.process = function(self, state)
        if (query:IsActive()) then
            return true;
        end

        wipe(validAuctions);
        wipe(known);

        self.requested = true;
        query:Search(item:Clone(), item.isEquipment, false);
        return false;
    end
    fn.result = function(self, state)
        return nil;
    end
    self.priceScanFn = fn;

    self.state = EventState:Acquire(fn, "QUERY_SEARCH_COMPLETE", "QUERY_SEARCH_RESULT");
    return item;
end

function Retail.GetScanText(current,total)
    return "Scanning "..current.." of "..total;
end

function Retail:Recycle(items)
    
end

function Retail:TempBlacklist(items, index, auction)
    if (not auction) then
        return;
    end

    Query.TempBlacklist(auction);
    tremove(items, index);
end

function Retail:PermBlacklist(items, index, auction)
    if (not auction) then
        return;
    end

    local blacklist = Config.Sniper().itemBlacklist;
    blacklist[auction.tsmId] = auction.link;
    tremove(items, index);
end

function Retail:Remove(items, auction, removeKnown, addKnown)
    local hash = Query.ItemHash(auction);
    for i = 1, #items do
        local item = items[i];
        local iHash = Query.ItemHash(item);

        if (hash == iHash
            and item.link == auction.link) then
                
            removeKnown(item);
            tremove(items, i);

            return i;
        end
    end

    return nil;
end

function Retail:RemoveAmount(items, auction, count, removeKnown, addKnown)
    local hash = Query.ItemHash(auction);
    for i = 1, #items do
        local item = items[i];
        local iHash = Query.ItemHash(item);

        if (hash == iHash
            and item.link == auction.link) then
                
            removeKnown(item);
            item.count = item.count - count;
            auction.count = item.count;
            addKnown(item);

            if (item.count <= 0) then
                tremove(items, i);
                return i;
            end

            break;
        end
    end

    return nil;
end

function Retail:Purchase(auction, count)
    if (not auction) then
        return;
    end

    if (not count) then
        count = auction.count;
    end

    self:Interrupt(true);

    if (auction.isCommodity) then
        query:PurchaseCommodity(auction, count);
    else
        query:PurchaseItem(auction);
    end
end

function Retail:Interrupt(skipQuery)
    Tasker.Clear(TASKER_TAG);

    if (not skipQuery) then
        query:Interrupt();
    end

    local state = self.state;
    if (not state) then
        return;
    end

    state:Release();
    self.state = nil;
end

function Retail:IsQueryActive()
    return query:IsActive();
end

function Retail:IsActive()
    local activeQuery = query:IsActive();
    if (activeQuery) then
        return true;
    end

    local state = self.state;
    return state ~= nil and (not state.complete or state.processing);
end

function Retail:Process()
    query:Process();

    local state = self.state;
    if (not state) then
        return;
    end

    state:Process();
    if (state.complete and not state.processing) then
        self.state = nil;
    end
end