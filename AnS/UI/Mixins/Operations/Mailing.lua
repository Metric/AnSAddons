local Ans = select(2, ...);

local TextInput = Ans.UI.TextInput;
local Utils = Ans.Utils;

AnsMailOperationFrameMixin = {};

function AnsMailOperationFrameMixin:Init()
    local this = self;
    self.selected = nil;
    self.name = TextInput:NewFrom(self.OpName);
    self.keepInBags = TextInput:NewFrom(self.KeepInBags);

    self.to = TextInput:NewFrom(self.To);
    self.subject = TextInput:NewFrom(self.Subject);

    self.valueChangeHandler = function() this:ValuesChanged(); end;

    self.name.onTextChanged = self.valueChangeHandler;
    self.keepInBags.onTextChanged = self.valueChangeHandler;
    self.to.onTextChanged = self.valueChangeHandler;
    self.subject.onTextChanged = self.valueChangeHandler;
end

function AnsMailOperationFrameMixin:Set(op)
    self.selected = nil;
    if (not op) then
        self:Hide();
        return;
    end

    self.name:Set(op.name);
    
    self.keepInBags:Set(op.keepInBags or "");
    self.to:Set(op.to or "");
    self.subject:Set(op.subject or "");
    
    self.selected = op;

    self:Show();
end

function AnsMailOperationFrameMixin:ValuesChanged()
    if (not self.selected) then
        return;
    end

    self.selected.name = self.name:Get() or "";
    self.selected.keepInBags = tonumber(self.keepInBags:Get()) or 0;
    
    self.selected.to = self.to:Get() or "";
    self.selected.subject = self.subject:Get() or "";

    if (self.onEdit) then
        self.onEdit();
    end
end