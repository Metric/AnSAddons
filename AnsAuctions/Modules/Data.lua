local Ans = select(2, ...);
local AuctionData = {};
local Query = AnsCore.API.Query;
local Utils = AnsCore.API.Utils;
local Recycler = AnsCore.API.Recycler;

local SORT_METHOD = Query.SORT_METHODS.PRICE;

AuctionData.__index = AuctionData;
AuctionData.isInited = false;
AuctionData.query = Query:New("");
AuctionData.waitingForResult = false;
AuctionData.waitingQuery = -1;
AuctionData.scanning = false;
AuctionData.processing = false;
AuctionData.scanProcessing = false;
AuctionData.scanIndex = 1;

Ans.AuctionData = AuctionData;

ANS_LAST_DATA_SCAN = 0;

local MIN_WAIT_TIME = (60 * 15);

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

function AuctionData:Init()
    local d = slef;
    if (self.isInited) then
        return;
    end

    self.isInited = true;

    if (not AnsAuctionData) then
        return;
    end

    local frame = CreateFrame("FRAME", "AnsAuctionDataMainPanel", AuctionFrame, "AnsAuctionDataTemplate");
    self.frame = frame;

    self.statusText = _G[frame:GetName().."BottomBarStatus"];
    self.startButton = _G[frame:GetName().."BottomBarStart"];
end

function AuctionData:StartScan()
    if (self.frame and not self.scanning and not self.scanProcessing and not self.processing) then
        self.query:Reset();

        if (self.query:IsGetAllReady()) then
            self.scanIndex = 1;
            AnsAuctionData:StartTracking();

            self.query:Set("");
            self.scanning = true;
            self.waitingForResult = false;
            self.scanProcessing = false;
            self.processing = false;

            self.startButton:SetText("Cancel Data Scan");
            self.statusText:SetText("Gathering Data...");
        else
            self.statusText:SetText("Must wait at least 15 minutes");
        end
    elseif (self.frame and (self.scanning or self.scanProcessing or self.processing)) then
        self:StopScan();
    end
end

function AuctionData:StopScan()
    if (self.frame) then
        AnsAuctionData:StopTracking();
        self.scanning = false;
        self.scanProcessing = false;
        self.waitingForResult = false;
        self.processing = false;
        self.startButton:SetText("Start Data Scan");
        self.query:Reset();
    end
end

function AuctionData:OnUpdate()
    if(self.frame and self.frame:IsShown() and (self.scanning or self.scanProcessing or self.processing)) then
        if (not self.waitingForResult) then
            if (self.scanning) then
                if (self.query:IsGetAllReady()) then
                --if (self.query:IsReady()) then
                    self.query:GetAll();
                    self.waitingForResult = true;
                end
            elseif (self.scanProcessing) then
                for i = 1, NUM_AUCTION_ITEMS_PER_PAGE / 4 do 
                    if (self.scanIndex <= self.query.count) then
                        self.statusText:SetText("Scanning "..self.scanIndex.." of "..self.query.count);
                        self.query:CaptureTrack(self.scanIndex, AnsAuctionData);
                        self.scanIndex = self.scanIndex + 1;
                    else
                        self.scanProcessing = false;
                        self.processing = true;
                        break;
                    end
                end
            elseif (self.processing) then
                if (not AnsAuctionData:IsProcessingComplete()) then
                    self.statusText:SetText("Processing "..AnsAuctionData:CurrentProcessingStep().." of "..AnsAuctionData:TotalItemsToProcess());
                    AnsAuctionData:ProcessNext();
                else
                    self.statusText:SetText("Complete");
                    self:StopScan();
                    ANS_LAST_DATA_SCAN = time();
                end
            end
        end
    end

    if (self.frame and not self.scanning and not self.scanProcessing and not self.processing) then
        self.statusText:SetText("Scan ready in: "..GetFormattedTime());
    end
end

function AuctionData:OnAuctionUpdate()
    if (self.frame and self.frame:IsShown() and self.scanning) then
        if (self.waitingForResult) then
            
            self.query:CaptureTrack(self.scanIndex, AnsAuctionData);
            self.scanIndex = self.scanIndex + 1;

            self.scanning = false;
            self.scanProcessing = true;
            self.query.isGettingAll = false;
            self.waitingForResult = false;
        end
    end
end

function AuctionData:OnAuctionHouseClosed()
    self:Close();
end

function AuctionData:Close()
    if (self.frame and self.frame:IsShown()) then
        self.frame:Hide();
        self:StopScan();
    end
end

function AuctionData:Show()
    if (self.frame) then
        self.frame:Show();
    end
end