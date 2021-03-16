local Ans = select(2, ...);
local Auction = Ans.Object.Register("Auction", Ans.Auctions);

function Auction:Acquire(o)
    local a = Auction:New(o);
    a.itemKey = nil;
    a.itemIndex = 0;
    a.id = nil;
    a.name = nil;
    a.texture = nil;
    a.hash = "";
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
    a.isEquipment = false;
    a.isPet = false;
    a.auctionId = nil;
    a.avg = 1;
    a.op = nil;
    a.suffix = 0;
    return a;
end

function Auction:Clone()
    return Auction:New({
        id = self.id,
        itemKey = self.itemKey,
        name = self.name,
        hash = self.hash,
        texture = self.texture,
        quality = self.quality,
        count = self.count,
        level = self.level,
        ppu = self.ppu,
        buyoutPrice = self.buyoutPrice,
        owner = self.owner,
        link = self.link,
        sniped = self.sniped,
        tsmId = self.tsmId,
        percent = self.percent,
        iLevel = self.iLevel,
        vendorsell = self.vendorsell,
        isCommodity = self.isCommodity,
        isPet = self.isPet,
        auctionId = self.auctionId,
        itemIndex = self.itemIndex,
        avg = self.avg,
        auctions = self.auctions,
        op = self.op,
        isEquipment = self.isEquipment,
        suffix = self.suffix
    });
end