local Ans = select(2, ...);
local EventManager = Ans.EventManager;
local Analytics = Ans.Object.Register("Analytics");
local Data = Ans.Object.Register("Data", Analytics);
local Config = Ans.Config;
local Utils = Ans.Utils; 

function Analytics:RegisterEvents(frame)
    frame:RegisterEvent("PLAYER_MONEY");
	
	if (not Utils.IsClassic()) then
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
    frame:RegisterEvent("MAIL_FAILED");
    frame:RegisterEvent("MAIL_SUCCESS");
    
    frame:RegisterEvent("TRADE_ACCEPT_UPDATE");
    
    frame:RegisterEvent("UI_INFO_MESSAGE");
    frame:RegisterEvent("MERCHANT_UPDATE");

    frame:RegisterEvent("PLAYER_ENTERING_WORLD");
    
    frame:RegisterEvent("GET_ITEM_INFO_RECEIVED");
end

function Data:OnLoad()
    self:Set("PREVIOUS_LOGIN", Config.Analytics()["LOGIN_TIME"] or time()); 
    self:Set("LOGIN_TIME", time());
end

function Data:Get(name)
    return Config.Analytics()[name];
end

function Data:Find(search, tbl)
    local analytics = Config.Analytics();
    wipe(tbl);
    for k,v in pairs(analytics) do
        if (strfind(k, search)) then
            tbl[k] = v;
        end
    end
end

function Data:Set(name, value)
    Config.Analytics()[name] = value;
end

EventManager:On("ANS_DATA_READY", 
    function()
        Data:OnLoad();
    end
);

