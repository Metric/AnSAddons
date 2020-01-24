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

Query.filters = {};

function Query:AssignFilters(filters, ilevel, buyout, quality, maxPercent)
    wipe(self.filters);

    self.minILevel = ilevel;
    self.maxBuyout = buyout;
    self.quality = quality;
    self.maxPercent = maxPercent;

    local i;
    for i = 1, #filters do
        local f = filters[i]:Clone();
        f:AssignOptions(ilevel, buyout, quality, maxPercent, ANS_GLOBAL_SETTINGS.pricingFn);
        tinsert(self.filters, f);
    end
end

function Query:IsValid(item) 
    if (item.iLevel < self.minILevel) then
        return false;
    end
    if (item.ppu > self.maxBuyout and self.maxBuyout > 0) then
        return false;
    end
    if (item.percent > self.maxPercent) then
        return false;
    end
    if (item.quality < self.quality) then
        return false;
    end

    return true;
end

function Query:IsFiltered(auction)
    local blacklist = ANS_GLOBAL_SETTINGS.characterBlacklist;
    local isOnBlacklist = false;

    if (auction.owner) then
        if (type(auction.owner) ~= "table") then
            isOnBlacklist = Utils:InTable(blacklist, auction.owner:lower());
        end
    end

    if (isOnBlacklist) then
        return false;
    end

    if (ANS_GLOBAL_SETTINGS.itemBlacklist[auction.tsmId]) then
        return false;
    end

    if (auction.buyoutPrice > 0) then
        local avg = Sources:Query(ANS_GLOBAL_SETTINGS.percentFn, auction);
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

        if (#self.filters == 0) then
            local allowed = Sources:Query(ANS_GLOBAL_SETTINGS.pricingFn, auction);

            if (type(allowed) == "boolean") then
                if (allowed and self:IsValid(auction)) then
                    filterAccepted = true;
                end
            else
                filterAccepted = self:IsValid(auction);
            end
        end

        local tf = #self.filters;
        for k = 1, tf do
            if (self.filters[k]:IsValid(auction, true)) then
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

    local groupInfo = C_AuctionHouse.GetItemKeyInfo(group.itemKey);

    if (groupInfo == nil) then
        Recycler:Recycle(auction);
        return nil, true;
    end

    auction.name = groupInfo.itemName;
    auction.itemKey = group.itemKey;
    auction.isCommodity = groupInfo.isCommodity;
    auction.isPet = false;
    auction.iLevel = group.itemKey.itemLevel;
    auction.id = group.itemKey.itemID;
    auction.count = group.totalQuantity;

    auction.ppu = group.minPrice;
    auction.buyoutPrice = auction.ppu;

    local _, link, iquality, iLevel, _, itype, subtype, 
    _, _, itexture, vendorsell = GetItemInfo(auction.id);

    if (group.itemKey.battlePetSpeciesID > 0 and groupInfo.battlePetLink) then
        link = groupInfo.battlePetLink;
        auction.isPet = true;
    elseif (group.itemKey.battlePetSpeciesID > 0 and not groupInfo.battlePetLink) then
        link = nil;
    end

    if (link == nil) then
        Recycler:Recycle(auction);
        return nil, false;
    end

    auction.texture = itexture;
    auction.quality = iquality;
    auction.link = link;
    auction.type = itype;
    auction.subtype = subtype;
    auction.vendorsell = vendorsell;

    if (Utils:IsBattlePetLink(auction.link)) then
        local info = Utils:ParseBattlePetLink(auction.link);
        auction.iLevel = info.level;
        auction.quality = info.breedQuality;
    end
    auction.tsmId = Utils:GetTSMID(auction.link);

    if (auction.buyoutPrice > 0) then
        local avg = Sources:Query(ANS_GLOBAL_SETTINGS.percentFn, auction);
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

        if (#self.filters == 0) then
            local allowed = Sources:Query(ANS_GLOBAL_SETTINGS.pricingFn, auction);

            if (type(allowed) == "boolean" or type(allowed) == "number") then
                if (allowed and self:IsValid(auction)) then
                    filterAccepted = true;
                end
            else
                filterAccepted = self:IsValid(auction);
            end
        end

        local tf = #self.filters;
        for k = 1, tf do
            if (self.filters[k]:IsValid(auction, auction.isPet or auction.isCommodity)) then
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