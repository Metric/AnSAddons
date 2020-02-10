local Ans = select(2, ...);

local Utils = Ans.Utils;
local Sources = Ans.Sources;

local Query = {};
Query.__index = Query;
Ans.GroupQuery = Query;

local Recycler = { auctions = {}};
Recycler.__index = Recycler;

Ans.GroupRecycler = Recycler;

local Auction = {};
Auction.__index = Auction;

local SnipingOp = Ans.Operations.Sniping;

function Auction:New()
    local a = {};
    setmetatable(a, Auction);
    a.itemKey = nil;
    a.id = nil;
    a.name = nil;
    a.texture = nil;
    a.count = 1;
    a.level = 0;
    a.ppu = 0;
    a.owner = nil;
    a.link = nil;
    a.sniped = false;
    a.tsmId  = nil;
    a.percent = -1;
    a.quality = 0;
    
    a.iLevel = 0;
    a.vendorsell = 0;
    a.isCommodity = false;
    a.auctionId = nil;
    a.avg = 1;
    return a;
end

function Auction:Clone()
    local a = Recycler:Get();
    setmetatable(a, Auction);
    a.id = self.id;
    a.itemKey = self.itemKey;
    a.name = self.name;
    a.texture = self.texture;
    a.quality = self.quality;
    a.count = self.count;
    a.level = self.level;
    a.ppu = self.ppu;
    a.buyoutPrice = self.buyoutPrice;
    a.owner = self.owner;
    a.link = self.link;
    a.sniped = self.sniped;
    a.tsmId = self.tsmId;
    a.percent = self.percent;
    a.iLevel = self.iLevel;
    a.vendorsell = self.vendorsell;
    a.isCommodity = self.isCommodity;
    a.auctionId = self.auctionId;
    a.avg = self.avg;
    return a;
end

function Recycler:Reset()
    wipe(self.auctions);
end

function Recycler:Recycle(auction)
    wipe(auction);
    tinsert(self.auctions, auction);
end

function Recycler:Get()
    if (#self.auctions > 0) then
        return tremove(self.auctions);
    end
    return Auction:New();
end

local function Truncate(str)
    if(str:len() <= 63) then
        return str;
    end

    return str:sub(1, 62);
end

local function ItemHash(item)
    local owner = "?";

    if (item.owner) then
        owner = item.owner;
    end

    return item.link..item.count..item.ppu..owner;
end

Query.ops = {};

function Query:AssignDefaults(ilevel, buyout, quality, maxPercent)
    self.minILevel = ilevel;
    self.maxBuyout = buyout;
    self.quality = quality;
    self.maxPercent = maxPercent;
end

function Query:AssignSnipingOps(ops) 
    wipe(self.ops);

    for i,v in ipairs(ops) do
        local op = SnipingOp:FromConfig(v);
        op:ParseGroups();
        tinsert(self.ops, op);
    end
end

function Query:IsValid(item) 
    if (item.iLevel < self.minILevel and self.minILevel > 0) then
        return false;
    end
    if (item.ppu > self.maxBuyout and self.maxBuyout > 0) then
        return false;
    end
    if (item.percent > self.maxPercent and self.maxPercent > 0) then
        return false;
    end
    if (item.quality < self.quality and self.quality > 0) then
        return false;
    end

    return true;
end

function Query:IsFiltered(auction)
    local blacklist = ANS_SNIPE_SETTINGS.characterBlacklist;

    -- ensure the blacklist is in table
    -- format, if not make it table and cache it
    -- this won't hurt anything since
    -- the config already handles if it is in a table
    -- and will fill in the edit box appropriately
    if (type(blacklist) == "string") then
        if (blacklist == "" or blacklist:len() == 0) then
            blacklist = {};
        else
            blacklist = { strsplit("\r\n", blacklist:lower()) };
            ANS_SNIPE_SETTINGS.characterBlacklist = blacklist;
        end
    end

    local isOnBlacklist = false;

    if (auction.owner and #blacklist > 0) then
        if (type(auction.owner) ~= "table") then
            if (auction.owner ~= "" and auction.owner:len() > 0) then
                isOnBlacklist = Utils:InTable(blacklist, auction.owner:lower());
            end
        else
            for i,v in ipairs(auction.owner) do
                if (v ~= "" and v:len() > 0) then
                    local contains = Utils:InTable(blacklist, v:lower());
                    if (contains) then
                        isOnBlacklist = true;
                        break;
                    end
                end
            end
        end
    end

    if (isOnBlacklist) then
        return false;
    end

    if (ANS_SNIPE_SETTINGS.itemBlacklist[auction.tsmId]) then
        return false;
    end

    if (auction.buyoutPrice > 0) then
        local avg = Sources:Query(ANS_SNIPE_SETTINGS.source, auction);
        if (not avg or avg <= 0) then avg = auction.vendorsell or 1; end;

        if (avg <= 1) then
            auction.avg = 1;
            auction.percent = 9999;
        else
            auction.avg = avg;
            auction.percent = math.floor(auction.ppu / avg * 100);
        end

        local filterAccepted = false;
        local k;

        if (#self.ops == 0) then
            local allowed = Sources:Query(ANS_SNIPE_SETTINGS.pricing, auction);

            if (type(allowed) == "boolean") then
                if (allowed and self:IsValid(auction)) then
                    filterAccepted = true;
                end
            else
                filterAccepted = self:IsValid(auction);
            end
        end

        local tf = #self.ops;
        for k = 1, tf do
            if (self.ops[k]:IsValid(auction, true)) then
                filterAccepted = true;
                break;
            end
        end

        return filterAccepted;
    end

    return false;
end

function Query:IsFilteredGroup(group)
    local auction = Recycler:Get();

    auction.name = nil;
    auction.itemKey = group.itemKey;
    auction.isCommodity = false;
    auction.isPet = false;
    auction.texture = nil;
    auction.quality = 99;
    auction.iLevel = group.itemKey.itemLevel or 0;
    auction.id = group.itemKey.itemID;
    auction.count = group.totalQuantity;

    auction.ppu = group.minPrice;
    auction.buyoutPrice = auction.ppu;

    auction.link = nil;

    local groupInfo = C_AuctionHouse.GetItemKeyInfo(group.itemKey);

    if (group.itemKey.battlePetSpeciesID > 0) then
        if (not groupInfo) then
            Recycler:Recycle(auction);
            return nil, false;
        end

        auction.link = groupInfo.battlePetLink;
        auction.isPet = true;
    end
    
    if (groupInfo) then
        auction.quality = groupInfo.quality;
        auction.texture = groupInfo.iconFileID;
        auction.name = groupInfo.itemName;
        auction.isCommodity = groupInfo.isCommodity;
    end

    auction.type = 0;
    auction.subtype = 0;
    auction.vendorsell = 0;

    if (auction.link and Utils:IsBattlePetLink(auction.link)) then
        local info = Utils:ParseBattlePetLink(auction.link);
        auction.texture = info.icon;
        auction.iLevel = info.level;
        auction.name = info.name;
        auction.quality = info.breedQuality;
        auction.tsmId = Utils:GetTSMID(auction.link);
    else
        auction.tsmId = "i:"..auction.id;
    end

    if (auction.buyoutPrice > 0) then
        local avg = Sources:Query(ANS_SNIPE_SETTINGS.source, auction);
        if (not avg or avg <= 0) then 
            avg = auction.vendorsell or 1; 
        end

        if (avg <= 1) then
            auction.avg = 1;
            auction.percent = 9999;
        else
            auction.avg = avg;
            auction.percent = math.floor(auction.ppu / avg * 100);
        end

        local filterAccepted = false;
        local k;

        if (#self.ops == 0) then
            local allowed = Sources:Query(ANS_SNIPE_SETTINGS.pricing, auction);

            if (type(allowed) == "boolean" or type(allowed) == "number") then
                if (type(allowed) == "number") then
                    if (allowed > 0 and self:IsValid(auction)) then
                        filterAccepted = true;
                    end
                else
                    if (allowed and self:IsValid(auction)) then
                        filterAccepted = true;
                    end
                end
            else
                filterAccepted = self:IsValid(auction);
            end
        end

        local tf = #self.ops;
        for k = 1, tf do
            if (self.ops[k]:IsValid(auction, auction.isPet)) then
                filterAccepted = true;
                break;
            end
        end

        if (filterAccepted) then
            return auction;
        end
    end

    Recycler:Recycle(auction);
    return nil, false;
end