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
local Classic = Ans.API.Object.Register("Classic", Sniper);

local ERR_AUCTION_WON = gsub(ERR_AUCTION_WON_S or "", "%%s", "");
local ERRORS = {
    ERR_ITEM_NOT_FOUND,
    ERR_AUCTION_DATABASE_ERROR
};

local query = Query:Acquire(0,0,{0},0);

if (Utils.IsClassic()) then
    Sniper.module = Classic;
end

Classic.state = nil;
Classic.validAuctions = {};
Classic.filter = nil;
Classic.blocks = {};

local scanCount = 0;
local validAuctions = Classic.validAuctions;
local blocks = Classic.blocks;

local function Wipe()
    wipe(blocks);
    wipe(validAuctions);
end

Classic.Wipe = Wipe;

function Classic.SetOptions(ilevel, buyout, quality, percent)
    query:SetOptions(ilevel, buyout, quality, percent);
end

function Classic.QualitySelected(self, arg1, arg2, checked)
    local input = Sniper.qualityInput;
    local qualities = Config.Sniper().qualities;
    
    local text = Sniper.AnsQualityToText[arg1];
    local color = ITEM_QUALITY_COLORS[arg1].hex;

    Config.Sniper().minQuality = arg1;
    if (AuctionSnipe.qualityInput ~= nil) then
        UIDropDownMenu_SetText(AuctionSnipe.qualityInput, color..text);
    end

    wipe(qualities);
    qualities[arg1] = arg1 or nil;
    CloseDropDownMenus();
end

function Classic:GroupScan(filter)
    local count = scanCount;
    count = count + 1;
    if (count > 9999) then
        count = 0;
    end
    scanCount = count;
    self.filter = filter;

    local continue = filter ~= nil and 1 or 0;
    Tasker.Schedule(function()
        EventManager:Emit("SNIPER_GROUP_SCAN", continue);
    end, TASKER_TAG);
end

function Classic:PriceScan()
    wipe(validAuctions);
    wipe(blocks);

    local this = self;
    local filter = self.filter;
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
            
            if (v.isOwnerItem) then
                return false;
            end

            local valid = query:IsValidAuction(v);
            if (not valid) then
                return false;
            end

            -- clone via recycler
            -- by doing it this way
            -- we reuse tables for the cloning
            -- rather than always creating new tables
            v = Recycler:Get(v);
            local itemCount = v.count;
            if (not blocks[v.hash]) then
                blocks[v.hash] = v;
                blocks[v.hash].total = 0;
                tinsert(validAuctions, blocks[v.hash]);
            end

            local block = blocks[v.hash];
            if (not block.auctions) then
                block.auctions = {};
            end

            block.total = block.total + itemCount;
            tinsert(block.auctions, v);
        
            return false;
        elseif (name == "QUERY_SEARCH_COMPLETE") then
            Logger.Log("SNIPER", "Search Complete");
            Logger.Log("SNIPER", "Total Valid Found: "..#validAuctions);

            Tasker.Schedule(function()
                EventManager:Emit("SNIPER_PRICE_SCAN", validAuctions, 0);
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
        wipe(blocks);

        self.requested = true;
        query:Search(filter, true);
        return false;
    end
    fn.result = function(self, state)
        return nil;
    end
    self.priceScanFn = fn;

    self.state = EventState:Acquire(fn, "QUERY_SEARCH_COMPLETE", "QUERY_SEARCH_RESULT");
    return true;
end

function Classic.GetScanText(current,total)
    return "Query #"..(scanCount + 1).." page: "..(query.page + 1);
end

function Classic:Recycle(items)
    for i,v in ipairs(items) do
        local recycled = false;

        for k,c in ipairs(v.auctions) do
            if (v == c) then
                recycled = true;
            end
            Recycler:Recycle(c);
        end

        if (not recycled) then
            Recycler:Recycle(v);
        end
    end
end

function Classic:TempBlacklist(items, index, block)
    if (not block) then
        return;
    end

    if (block.auctions and #block.auctions > 0) then
        for i,v in ipairs(block.auctions) do
            Query.TempBlacklist(v);
        end
    end

    Recycler:Recycle(tremove(items, index));
end

function Classic:PermBlacklist(items, index, auction)
    if (not auction) then
        return;
    end

    local blacklist = Config.Sniper().itemBlacklist;
    blacklist[auction.tsmId] = auction.link;
    Recycler:Recycle(tremove(items, index));
end

function Classic:Remove(items, auction, removeKnown, addKnown)
    local hash = Query.ItemHash(auction);
    for i = 1, #items do
        local item = items[i];
        local iHash = Query.ItemHash(item);

        if (hash == iHash
            and item.link == auction.link) then
                
            Recycler:Recycle(tremove(items, i));
            return i;
        end
    end

    return nil;
end

function Classic:RemoveAmount(items, auction, count, removeKnown, addKnown)
    local hash = Query.ItemHash(auction);
    for i = 1, #items do
        local item = items[i];
        local iHash = Query.ItemHash(item);

        if (hash == iHash
            and item.link == auction.link) then
                
            item.total = item.total - count;

            if (item.total <= 0) then
                Recycler:Recycle(tremove(items, i));
                return i;
            end

            break;
        end
    end

    return nil;
end

function Classic:Purchase(block, count)
    if (self:IsActive()) then
        print("Ans - waiting for inactive state");
        return;
    end

    if (not block) then
        print("Ans - no block");
        return;
    end

    if (block.total and block.total <= 0) then
        print("Ans - nothing left in block");
        return;
    end

    local group = block.auctions;
    if (group and #group <= 0) then
        print("Ans - no groups left in block");
        return;
    end

    local auction = group[1];
    if (not auction) then
        print("Ans - no auction available in group");
        return;
    end

    EventManager:Emit("PURCHASE_START", block);

    print("Ans - trying to buy: "..auction.link.." x "..auction.count .." for "..Utils.PriceToString(auction.buyoutPrice));
    local success, wait, bidPlaced = query:PurchaseItem(auction);
    
    if (wait) then
        print("Ans - waiting to purchase");
        EventManager:Emit("QUERY_PREVIOUS_COMPLETED");
        return;
    end

    if (success) then
        tremove(group, 1);
        EventManager:Emit("PURCHASE_COMPLETE", true, block, auction.count);
        EventManager:Emit("QUERY_PREVIOUS_COMPLETED");
    else
        EventManager:Emit("QUERY_PREVIOUS_COMPLETED");
    end
end

function Classic:Interrupt(skipQuery)
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

function Classic:IsQueryActive()
    return query:IsActive();
end

function Classic:IsActive(ignoreQuery)
    if (not ignoreQuery) then
        local activeQuery = query:IsActive();
        if (activeQuery) then
            return true;
        end
    end

    local state = self.state;
    return state ~= nil and (not state.complete or state.processing);
end

function Classic:Process()
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