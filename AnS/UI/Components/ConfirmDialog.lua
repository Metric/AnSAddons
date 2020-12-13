local Ans = select(2, ...);
local TextInput = Ans.UI.TextInput;
local ConfirmDialog = Ans.Object.Register("ConfirmDialog", Ans.UI);

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

function ConfirmDialog:ShowInput(frame, message, confirmText, onConfirm, data)
    local dialog = frame.Dialog;
    if (not dialog) then
        return;
    end

    local input = dialog.input;

    if (not input and dialog.Input and dialog.Input.Text) then
        input = TextInput:NewFrom(dialog.Input.Text);
        input:EnableMultiLine();
    end

    if (input) then
        input:Set(data or "");
    end

    local cancelButton = dialog.Cancel;
    if (cancelButton) then
        cancelButton:SetScript("OnClick", 
            function()
                if (input) then
                    input:Set("");
                end

                frame:Hide();
            end
        );
    end
    local confirmButton = dialog.Confirm;
    if (confirmButton) then
        confirmButton:SetText(confirmText);
        confirmButton:SetScript("OnClick",
            function()
                frame:Hide();
                if (onConfirm) then
                    onConfirm(input and input:Get() or "");
                end
                if (input) then
                    input:Set("");
                end
            end
        );
    end
    local messageText = dialog.Message;
    if (messageText) then
        messageText:SetText(message);
    end
    frame:Show();
end