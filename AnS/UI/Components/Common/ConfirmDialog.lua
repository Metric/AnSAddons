local Ans = select(2, ...);
local ConfirmDialog = {};
ConfirmDialog.__index = ConfirmDialog;
Ans.UI.ConfirmDialog = ConfirmDialog;

function ConfirmDialog:Show(frame, message, confirmText, onConfirm, data)
    local dialog = frame.Dialog;
    if (not dialog) then
        return;
    end

    local cancelButton = dialog.Cancel;
    if (cancelButton) then
        cancelButton:SetScript("OnClick", function() frame:Hide(); end);
    end
    local confirmButton = dialog.Confirm;
    if (confirmButton) then
        confirmButton:SetText(confirmText);
        confirmButton:SetScript("OnClick", 
            function() 
                frame:Hide(); 
                if (onConfirm) then onConfirm(data); end 
            end);
    end
    local messageText = dialog.Message;
    if (messageText) then
        messageText:SetText(message);
    end
    frame:Show();
end