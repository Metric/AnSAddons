local Ans = select(2, ...);
local EventManager = Ans.EventManager;
local Analytics = {};
local Data = {store = {}};

ANS_ANALYTICS_DATA = {};

Data.__index = Data;
Analytics.__index = Analytics;
Ans.Analytics = Analytics;

Ans.Analytics.Data = Data; 

function Analytics:RegisterEvents(frame)
    self.frame = frame;

    frame:RegisterEvent("PLAYER_MONEY");
	
	if (BattlePetTooltip) then
		frame:RegisterEvent("GUILDBANKFRAME_OPENED");
		frame:RegisterEvent("GUILDBANKFRAME_CLOSED");
        frame:RegisterEvent("GUILDBANK_UPDATE_MONEY");
        
        frame:RegisterEvent("REAGENTBANK_UPDATE");
	end
    
    frame:RegisterEvent("BANKFRAME_OPENED");
    frame:RegisterEvent("BANKFRAME_CLOSED");
    
    frame:RegisterEvent("BAG_UPDATE_DELAYED");

    frame:RegisterEvent("MAIL_SHOW");
    frame:RegisterEvent("MAIL_CLOSED");
    frame:RegisterEvent("MAIL_INBOX_UPDATE");
    
    frame:RegisterEvent("TRADE_ACCEPT_UPDATE");
    
    frame:RegisterEvent("UI_INFO_MESSAGE");
    frame:RegisterEvent("MERCHANT_UPDATE");

    frame:RegisterEvent("PLAYER_ENTERING_WORLD");
    
    frame:RegisterEvent("GET_ITEM_INFO_RECEIVED");
end

function Data:OnLoad()
    self.store = ANS_ANALYTICS_DATA or {};
    self:Set("PREVIOUS_LOGIN", self.store["LOGIN_TIME"] or time()); 
    self:Set("LOGIN_TIME", time());
end

function Data:Get(name)
    return self.store[name];
end

function Data:Set(name, value)
    self.store[name] = value;
    ANS_ANALYTICS_DATA = self.store;
end

EventManager:On("VARIABLES_LOADED", 
    function()
        Data:OnLoad();
    end
);

