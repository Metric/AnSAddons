local Ans = select(2, ...);
local Auction = Ans.Auctions.Auction;
local Recycler = Ans.Object.Register("Recycler", Ans.Auctions);
Recycler.auctions = {};

function Recycler:Reset()
    wipe(self.auctions);
end

function Recycler:Recycle(auction)
    wipe(auction);
    tinsert(self.auctions, auction);
end

function Recycler:Get()
    -- free up a memory at this point
    if (#self.auctions > 800) then
        wipe(self.auctions);
    end
    if (#self.auctions > 0) then
        return Auction:Acquire(tremove(self.auctions, 1));
    end
    return Auction:Acquire();
end