local Ans = select(2, ...);
local Config = Ans.Config;
local Utils = Ans.Utils;
local Tasker = Ans.Tasker;
local TASKER_TAG = "LOGGER";
local Logger = {};
Logger.__index = Logger;
Logger.maxLines = 1000;
Ans.Logger = Logger;

function Logger.Log(tag, msg)
    local showWindow = Config.General().showDebugWindow;

    -- ignore log messages if 
    -- window is not shown
    if (not showWindow) then
        return;
    end

    local txt = AnsCoreLogWindow.Log.Text:GetText() or "";
    txt = txt.."("..(msg and tag or "UNKNOWN")..")".." "..(msg or tag or "").."\r\n";
    local lines = Utils:GetTable(strsplit("\r\n", txt));

    if (#lines >= Logger.maxLines) then
        AnsCoreLogWindow.Log.Text:SetText(lines[#lines].."\r\n");
    else
        AnsCoreLogWindow.Log.Text:SetText(txt);
    end

    -- always clear the tasker first
    Tasker.Clear(TASKER_TAG);

    Tasker.Delay(GetTime() + 0.01, function()
        local max = AnsCoreLogWindow.Log:GetVerticalScrollRange();
        if (max > 0) then
            max = max - 0.01;
        end
        AnsCoreLogWindow.Log:SetVerticalScroll(max);
    end, TASKER_TAG);

    Utils:ReleaseTable(lines);
end

function Logger.Update()
    local showWindow = Config.General().showDebugWindow;

    if (showWindow) then
         AnsCoreLogWindow:Show();
    else
         AnsCoreLogWindow:Hide();
    end
end
