local Ans = select(2, ...);
local Config = Ans.Config;
local Sources = Ans.Sources;
local EventManager = Ans.EventManager;
local SendView = Ans.Mailing.SendView;
local MailHook = {};
MailHook.__index = MailHook;

local didHook = false;

function MailHook.MakeDraggable()
    if (MailFrame) then
        MailFrame:SetMovable(true);
        MailFrame:RegisterForDrag("LeftButton");
        MailFrame:HookScript("OnDragStart", 
            function(self)
                self:StartMoving();
            end
        );
        MailFrame:HookScript("OnDragStop", 
            function(self)
                self:StopMovingOrSizing();
            end
        );
    end
end

EventManager:On("MAIL_SHOW", 
    function()
        MailHook.shown = true;

        if (not MailFrame) then
            return;
        end

        Sources:ClearCache();

        if (not didHook) then
            didHook = true;

            SendView:OnLoad(MailFrame);
            MailHook.MakeDraggable();
        end
    end);

EventManager:On("MAIL_CLOSED",
    function()
        MailHook.shown = false;
    end);