local Ans = select(2, ...);
local EventManager = Ans.EventManager;
local Analytics = Ans.Object.Register("Analytics");
local Data = Ans.Object.Register("Data", Analytics);
local Config = Ans.Config;
local Utils = Ans.Utils; 

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

