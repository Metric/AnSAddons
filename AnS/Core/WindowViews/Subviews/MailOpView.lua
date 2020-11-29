local Ans = select(2, ...);
local GroupsView = Ans.GroupsView;
local TextInput = Ans.UI.TextInput;
local ConfirmDialog = Ans.UI.ConfirmDialog;
local Dropdown = Ans.UI.Dropdown;
local TreeView = Ans.UI.TreeView;
local ListView = Ans.UI.ListView;
local Utils = Ans.Utils;
local MailOp = Ans.Operations.Mailing;

local MailView = {}
MailView.__index = MailView;
MailView.onEdit = nil;

Ans.MailOpView = MailView;

function MailView:OnLoad(f)
    local this = self;
    self.selected = nil;
    self.parent = f;
    self.frame = CreateFrame("Frame", "AnsMailEditor", f, "AnsMailOpEditorTemplate");

    self.name = TextInput:NewFrom(self.frame.OpName);
    self.keepInBags = TextInput:NewFrom(self.frame.KeepInBags);

    self.to = TextInput:NewFrom(self.frame.To);
    self.subject = TextInput:NewFrom(self.frame.Subject);

    self.name.onTextChanged = function() this:ValuesChanged(); end;
    self.keepInBags.onTextChanged = function() this:ValuesChanged(); end;
    self.to.onTextChanged = function() this:ValuesChanged(); end;
    self.subject.onTextChanged = function() this:ValuesChanged(); end;
end

function MailView:Hide()
    self.selected = nil;
    if (self.frame) then
        self.frame:Hide();
    end
end

function MailView:Set(op)
    self.selected = nil;

    self.name:Set(op.name);
    
    self.keepInBags:Set(op.keepInBags.."");
    self.to:Set(op.to.."");
    self.subject:Set(op.subject.."");
    
    self.selected = op;

    self.frame:Show();
end

function MailView:ValuesChanged()
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