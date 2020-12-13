local Ans = select(2, ...);
local Config = Ans.Config;
local TempTable = Ans.TempTable;
local Tasker = Ans.Tasker;
local TASKER_TAG = "LOGGER";
local Logger = Ans.Object.Register("Logger");
Logger.maxLines = 1000;

function Logger.Log(tag, msg)
    local showWindow = Config.General().showDebugWindow;

    -- ignore log messages if 
    -- window is not shown
    if (not showWindow) then
        return;
    end

    if (Logger.Input) then
        local txt = Logger.Input:Get() or "";
        txt = txt.."("..(msg and tag or "UNKNOWN")..")".." "..(msg or tag or "").."\r\n";
        local lines = TempTable:Acquire(strsplit("\r\n", txt));

        if (#lines >= Logger.maxLines) then
            AnsLogWindow.Log.Text:SetText(lines[#lines].."\r\n");
        else
            AnsLogWindow.Log.Text:SetText(txt);
        end

        -- always clear the tasker first
        Tasker.Clear(TASKER_TAG);

        Tasker.Delay(GetTime() + 0.01, function()
            local max = AnsLogWindow.Log:GetVerticalScrollRange();
            if (max > 0) then
                max = max - 0.01;
            end
            AnsLogWindow.Log:SetVerticalScroll(max);
        end, TASKER_TAG);

        lines:Release();
    end
end

function Logger.Update()
    local showWindow = Config.General().showDebugWindow;

    if (showWindow) then
        AnsLogWindow:Show();
    else
        AnsLogWindow:Hide();
    end
end
