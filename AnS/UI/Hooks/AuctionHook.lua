local Ans = select(2, ...);
local Sources = Ans.Sources;
local TempTable = Ans.TempTable;
local Recycler = Ans.Auctions.Recycler;
local Config = Ans.Config;
local Utils = Ans.Utils;
local Draggable = Utils.Draggable;
local EventManager = Ans.EventManager;
local PostingView = Ans.UI.AuctionPostingView;
local AuctionHook = {};
AuctionHook.__index = AuctionHook;

local AHFrame = nil;
local didHook = false;

EventManager:On("AUCTION_HOUSE_SHOW", 
    function()
        AuctionHook.shown = true;

        AHFrame = AuctionHouseFrame or AuctionFrame;

        if (not AHFrame) then
            return;
        end

        -- clear sources cache on AH show
        Sources:Clear();

        if (not didHook) then
            didHook = true;

            PostingView:OnLoad(AHFrame);
            PostingView:Hide();

            Draggable:Acquire(AHFrame, "auctionWindow");
        end

        if (didHook and Config.General().showPostCancel) then
            PostingView:HookTabs();
        elseif (didHook and not Config.General().showPostCancel) then
            PostingView:UnhookTabs();
        end
    end);

EventManager:On("AUCTION_HOUSE_CLOSED",
    function()
        
        -- clear sources cache on AH close
        Sources:Clear();

        -- clear these on AH close to free up memory
        -- faster
        TempTable.Reset();
        Recycler:Reset();

        AuctionHook.shown = false;
    end
);