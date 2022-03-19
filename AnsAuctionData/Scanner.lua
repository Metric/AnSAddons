local Core = select(2, ...);
local Query = Ans.API.Auctions.Query;
local Recycler = Ans.API.Auctions.Recycler;
local Utils = Ans.API.Utils;
local Config = Ans.API.Config;
local EventManager = Ans.API.EventManager;

ANS_LAST_DATA_SCAN = 0;

local MIN_WAIT_TIME = (60 * 15);
local query = Query:Acquire(0,0,{0},0);
local itemIndex = 1;

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

    local AHFrame = AuctionHouseFrame or AuctionFrame;

    self.inited = true;

    local frame = CreateFrame("FRAME", "AnsAuctionDataPanel", AHFrame, "AnsAuctionDataPanelTemplate");
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
        local ready, allReady = query:IsReady();

        if (Utils.IsClassic() and not allReady) then
            return;
        elseif (ANS_LAST_DATA_SCAN + MIN_WAIT_TIME > time()) then
            return;
        end

        self.state = STATES.INIT;
        self.startButton:SetText("Cancel Data Scan");
        self.statusText:SetText("Gathering Data...");

    elseif (self.frame and self.state ~= STATES.NONE) then
       self:Stop();
    end
end

function Scanner:Stop()
    query:Interrupt();

    self.state = STATES.NONE;

    if (self.frame) then
        AnsAuctionData:StopTracking();
        self.startButton:SetText("Start Data Scan");
    end
end

function Scanner:Start()
    self.state = STATES.WAITING;
    itemIndex = 1;
    ANS_LAST_DATA_SCAN = time();
    AnsAuctionData:StartTracking();
    query:All();
end

function Scanner:Track()
    local count = 0;
    local auction = Recycler:Get();
    local perFrame = Config.Sniper().itemsPerUpdate;
    local total = query:AllCount();

    while (itemIndex <= total and count < perFrame) do
        self.statusText:SetText("Scanning "..itemIndex.." of "..total);

        auction = query:Next(auction, itemIndex);
        if (auction) then
            AnsAuctionData:AddTracking(auction.tsmId, auction.ppu);
        end

        itemIndex = itemIndex + 1;
        count = count + 1;
    end

    if (itemIndex > total) then
        self.state = STATES.PROCESSING;
    end
end

function Scanner:Process()
    local count = 0;
    local perFrame = Config.Sniper().itemsPerUpdate;

    while (not AnsAuctionData:IsProcessingComplete() and count < perFrame) do
        local step = AnsAuctionData:CurrentProcessingStep();
        local maxStep = AnsAuctionData:TotalItemsToProcess();

        self.statusText:SetText("Processing "..step.." of "..maxStep);

        AnsAuctionData:ProcessNext();
        count = count + 1;
    end
end

function Scanner:OnUpdate()
    if (not self.frame) then
        return;
    end

    if (self.state == STATES.INIT) then
        self:Start();
    elseif (self.state == STATES.ITEMS) then
        self:Track();
    elseif (self.state == STATES.PROCESSING) then
        if (not AnsAuctionData:IsProcessingComplete()) then
            self:Process();
        else
            self.statusText:SetText("Complete");
            self:Stop();
        end
    end

    if (self.frame and self.state == STATES.NONE) then
        self.statusText:SetText("Scan ready in: "..GetFormattedTime());
    end
end

function Scanner:TryProcess()
    if (self.state == STATES.WAITING) then
        self.state = STATES.ITEMS;
    end
end

function Scanner:Show()
    self:Init();
end

function Scanner:Close()
    self:Stop();
end

EventManager:On("AUCTION_HOUSE_SHOW", function()
    Scanner:Show();
end);
EventManager:On("AUCTION_HOUSE_CLOSED", function()
    Scanner:Close();
end);
EventManager:On("AUCTION_ITEM_LIST_UPDATE", function()
    Scanner:TryProcess();
end);
EventManager:On("REPLICATE_ITEM_LIST_UPDATE", function()
    Scanner:TryProcess();
end);