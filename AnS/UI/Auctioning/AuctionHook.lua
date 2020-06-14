local Ans = select(2, ...);
local Sources = Ans.Sources;
local Config = Ans.Config;
local EventManager = Ans.EventManager;
local PostingView = Ans.Auctions.PostingView;
local AuctionHook = {};
AuctionHook.__index = AuctionHook;

local AHFrame = nil;
local didHook = false;

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
    local left, bottom, width, height = self:GetRect();
    Config.General().auctionWindowPosition = {x = left, y = bottom};
end

function AuctionHook.RestoreWindowPosition(self)
    if (not self) then
        return;
    end

    local pos = Config.General().auctionWindowPosition;

    if (pos and Config.General().saveWindowLocations) then
        self:ClearAllPoints();
        self:SetPoint("BOTTOMLEFT", self:GetParent(), "BOTTOMLEFT", pos.x, pos.y);
    end
end

EventManager:On("AUCTION_HOUSE_SHOW", 
    function()
        AuctionHook.shown = true;

        AHFrame = AuctionHouseFrame or AuctionFrame;

        -- clear sources cache on AH show
        Sources:ClearCache();

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
        -- clear sources cache on AH close
        Sources:ClearCache();

        AuctionHook.shown = false;
    end
);