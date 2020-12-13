local Core = select(2, ...);
local Query = Ans.API.Auctions.Query;
local Recycler = Ans.API.Auctions.Recycler;
local Utils = Ans.API.Utils;

ANS_LAST_DATA_SCAN = 0;

local MIN_WAIT_TIME = (60 * 15);

local STATES = {};
STATES.NONE = 0;
STATES.INIT = 1;
STATES.WAITING = 2;
STATES.ITEMS = 3;
STATES.PROCESSING = 4;

local Scanner = {};
Scanner.__index = Scanner;
Scanner.state = STATES.NONE;

Core.Scanner = Scanner;

local function GetFormattedTime()
    local diff = time() - ANS_LAST_DATA_SCAN;
    local wait = MIN_WAIT_TIME - diff;

    if (wait <= 0) then
        return "00:00";
    end

    local minutes = math.floor(wait / 60);
    local seconds = math.floor(wait % 60);

    local formated = "";
    if (minutes < 10) then
        formated = formated.."0"..minutes;
    else
        formated = formated..minutes;
    end
    formated = formated..":";
    if (seconds < 10) then
        formated = formated.."0"..seconds;
    else
        formated = formated..seconds;
    end
    return formated;
end

function Scanner:Init()
    if(self.inited) then
        return;
    end

    self.inited = true;

    if (not Utils.IsClassic()) then
        return;
    end

    local frame = CreateFrame("FRAME", "AnsAuctionDataPanel", AuctionFrame, "AnsAuctionDataPanelTemplate");
    self.frame = frame;

    self.statusText = _G[frame:GetName().."BottomBarStatus"];
    self.startButton = _G[frame:GetName().."BottomBarStart"];

    self.startButton:SetScript("OnClick", 
        function()
            Scanner:Toggle();
        end
    );
end

function Scanner:Toggle()
    if (self.frame and self.state == STATES.NONE) then
        if (Query:IsAllReady()) then
            self.state = STATES.INIT;
            self.startButton:SetText("Cancel Data Scan");
            self.statusText:SetText("Gathering Data...");
        else
            self.statusText:SetText("Must wait at least 15 minutes");    
        end
    elseif (self.frame and self.state ~= STATES.NONE) then
       self:Stop();
    end
end

function Scanner:Stop()
    self.state = STATES.NONE;

    if (self.frame) then
        AnsAuctionData:StopTracking();
        self.startButton:SetText("Start Data Scan");
    end
end

function Scanner:OnUpdate()
    if (not self.frame) then
        return;
    end

    if (self.state == STATES.INIT) then
        if (Query:IsAllReady()) then
            self.state = STATES.WAITING;
            ANS_LAST_DATA_SCAN = time();
            AnsAuctionData:StartTracking();
            Query:All();
        end
    elseif (self.state == STATES.ITEMS) then
        local count = 0;
        local auction = Recycler:Get();
        while (Query:HasNext() and count <= 50) do
            self.statusText:SetText("Scanning "..Query.itemIndex.." of "..Query:Count());
            if (Query:Next(auction)) then
                AnsAuctionData:AddTracking(auction.tsmId, auction.ppu);
            else
                auction = Recycler:Get();
            end
            count = count + 1;
        end

        if (not Query:HasNext()) then
            self.state = STATES.PROCESSING;
        end
    elseif (self.state == STATES.PROCESSING) then
        if (not AnsAuctionData:IsProcessingComplete()) then
            self.statusText:SetText("Processing "..AnsAuctionData:CurrentProcessingStep().." of "..AnsAuctionData:TotalItemsToProcess());
            AnsAuctionData:ProcessNext();
        else
            self.statusText:SetText("Complete");
            self:Stop();
        end
    end

    if (self.frame and self.state == STATES.NONE) then
        self.statusText:SetText("Scan ready in: "..GetFormattedTime());
    end
end

function Scanner:EventHandler(frame, event, ...)
    if (event == "AUCTION_ITEM_LIST_UPDATE") then
        if (self.state == STATES.WAITING) then
            self.state = STATES.ITEMS;
        end
    end

    if (event == "AUCTION_HOUSE_SHOW") then self:Show(); end;
    if (event == "AUCTION_HOUSE_CLOSED") then self:Close(); end;
end

function Scanner:Show()
    self:Init();
end

function Scanner:Close()
    self:Stop();
end