local Ans = select(2, ...);
local Utils = Ans.Utils;
local Config = Ans.Config;
local Draggable = Ans.Object.Register("Draggable", Utils);

local registered = {};

function Draggable:Acquire(frame, configKey)
    local o = Draggable:New();
    o.frame = frame;
    tinsert(registered, frame);
    o.configKey = configKey;
    o:Init();
    return o;
end

function Draggable.Reset()
    local windows = Config.Windows();
    wipe(windows);

    if (AnsMainWindow) then
        AnsMainWindow:ClearAllPoints();
        AnsMainWindow:SetPoint("CENTER", 0, 0);
    end

    for i,v in ipairs(registered) do
        v:ClearAllPoints();
        v:SetPoint("CENTER", v:GetParent(), "CENTER", 0, 0);
    end
end

function Draggable:Init()
    self.frame:SetMovable(true);
    self.frame:RegisterForDrag("LeftButton");
    self.frame:HookScript("OnDragStart",
        function(f)
            f:StartMoving();
        end
    );
    self.frame:HookScript("OnDragStop",
        function(f)
            f:StopMovingOrSizing();
            self:Store();
        end
    );
    self.frame:HookScript("OnShow", 
        function(f)
            self:Restore();
        end
    );
end

function Draggable:Restore()
    local pos = Config.Windows()[self.configKey];
    if (pos and Config.General().saveWindowLocations) then
        self.frame:ClearAllPoints();
        self.frame:SetPoint("BOTTOMLEFT", self.frame:GetParent(), "BOTTOMLEFT", pos.x, pos.y);
    end
end

function Draggable:Store()
    local left, bottom, width, height = self.frame:GetRect();
    Config.Windows()[self.configKey] = {x = left, y = bottom};
end
