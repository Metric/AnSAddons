local Ans = select(2, ...);
local Config = Ans.Config;
local Utils = Ans.Utils;
local Draggable = Utils.Draggable;
local EventManager = Ans.EventManager;
local SendView = Ans.UI.MailSendView;
local MailHook = {};
MailHook.__index = MailHook;

local didHook = false;

EventManager:On("MAIL_SHOW", 
    function()
        MailHook.shown = true;

        if (not MailFrame) then
            return;
        end

        if (not didHook) then
            didHook = true;

            SendView:OnLoad(MailFrame);
            Draggable:Acquire(MailFrame, "mailWindow");
        end

        if (Config.General().showMailSend) then
            SendView:Show();
        else
            SendView:Hide();
        end
    end);

EventManager:On("MAIL_CLOSED",
    function()
        MailHook.shown = false;
    end);