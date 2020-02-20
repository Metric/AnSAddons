local Ans = select(2, ...);
local EventManager = Ans.EventManager;
local PostingView = Ans.Auctions.PostingView;
local AuctionHook = {};
AuctionHook.__index = AuctionHook;

local AHFrame = nil;
local didHook = false;

local wx, wy = nil, nil;

function AuctionHook.MakeDraggable()
    if (AHFrame and AHFrame:IsShown()) then
        AHFrame:SetMovable(true);
        AHFrame:RegisterForDrag("LeftButton");
        AHFrame:HookScript("OnDragStart", 
            function(self)
                self:StartMoving();
            end
        );
        AHFrame:HookScript("OnDragStop", 
            function(self)
                self:StopMovingOrSizing();
                AuctionHook.StoreWindowPosition(self);
            end
        );
        AHFrame:HookScript("OnShow", function(self) AuctionHook.RestoreWindowPosition(self) end);
    end
end

function AuctionHook.StoreWindowPosition(self)
    wx, wy = self:GetRect();
    -- eventually add save settings here
end

function AuctionHook.RestoreWindowPosition(self)
    if (not self) then
        return;
    end

    if (not wx and not wy) then
        self:ClearAllPoints();
        self:SetPoint("CENTER", self:GetParent(), "CENTER", 0, 0);
    else
        self:ClearAllPoints();
        self:SetPoint("BOTTOMLEFT", self:GetParent(), "BOTTOMLEFT", wx, wy);
    end
end

EventManager:On("AUCTION_HOUSE_SHOW", 
    function()
        AuctionHook.shown = true;

        AHFrame = AuctionHouseFrame or AuctionFrame;

        if (not didHook) then
            didHook = true;

            PostingView:OnLoad(AHFrame);
            PostingView:Hide();

            AuctionHook.RestoreWindowPosition(AHFrame);
            AuctionHook.MakeDraggable();
        end
    end);

EventManager:On("AUCTION_HOUSE_CLOSED",
    function()
        AuctionHook.shown = false;
    end
);