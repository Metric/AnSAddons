local Ans = select(2, ...);
local TextInput = Ans.Object.Register("TextInput", Ans.UI);

function TextInput:Acquire(parent, name)
    local t = TextInput:New();
    t:Init(parent, name);
    return t;
end

function TextInput:NewFrom(f)
    local t = TextInput:New();
    t:InitFrom(f);
    return t;
end

function TextInput:Init(parent, name)
    local this = self;
    self.parent = parent;
    self.name = name;
    self.lastInputTime = time();
    
    self.onTextChanged = nil;
    self.asyncWait = 1;
    self.textDidChange = false;
    self.frame = CreateFrame("EDITBOX", name, parent, "AnsEditBoxTemplate");
    self.frame:HookScript("OnTextSet", function() this:OnTextChanged() end);
    self.frame:HookScript("OnTextChanged", function() this:OnTextChanged() end);
    self.frame:HookScript("OnUpdate", function() this:OnUpdate() end);
    self.frame:SetTextInsets(5,10,5,5);
    self.frame:ClearFocus();
    self.clearButton = self.frame.Clear;
    self.placeholderLabel = self.frame.PlaceHolder;
    self.clearButton:SetScript("OnClick", function() this:Clear(); end);
    self.clearButton:Hide();
end

function TextInput:InitFrom(f)
    local this = self;
    local name = f:GetName();
    self.parent = f:GetParent();
    self.name = f:GetName();
    self.lastInputTime = time();
    self.frame = f;

    self.onTextChanged = nil;
    self.asyncWait = 1;
    self.textDidChange = false;
    self.frame:HookScript("OnTextSet", function() this:OnTextChanged() end);
    self.frame:HookScript("OnTextChanged", function() this:OnTextChanged() end);
    self.frame:HookScript("OnUpdate", function() this:OnUpdate() end);
    self.frame:SetTextInsets(5,10,5,5);
    self.frame:ClearFocus();
    self.clearButton = self.frame.Clear;
    self.placeholderLabel = self.frame.PlaceHolder;
    self.clearButton:SetScript("OnClick", function() this:Clear(); end);
    self.clearButton:Hide();
end

function TextInput:Clear()
    self.frame:SetText("");
end

function TextInput:Hide()
    if (not self.frame) then
        return;
    end

    self.frame:Hide();
end

function TextInput:EnableMultiLine()
    if (not self.frame) then
        return;
    end

    self.placeholderLabel:ClearAllPoints();
    self.placeholderLabel:SetPoint("TOPLEFT", 5, -2);
    self.clearButton:Hide();
    self.frame:SetMultiLine(true);
    self.frame.Background:Hide();
end

function TextInput:DisableMultiLine()
    if (not self.frame) then
        return;
    end

    local txt = self:Get();
    if (txt and txt ~= "") then
        self.clearButton:Show();
    end

    
    self.placeholderLabel:ClearAllPoints();
    self.placeholderLabel:SetPoint("LEFT", 5, 0);
    self.frame:SetMultiLine(false);
    self.frame.Background:Show();
end

function TextInput:EnableWrap()
    if (not self.frame) then
        return;
    end

    self.frame:GetRegions():SetNonSpaceWrap(true);
    self.frame:GetRegions():SetWordWrap(true);
end

function TextInput:DisableWrap()
    if (not self.frame) then
        return;
    end

    self.frame:GetRegions():SetNonSpaceWrap(false);
    self.frame:GetRegions():SetWordWrap(false);
end

function TextInput:Show()
    if (not self.frame) then
        return;
    end

    self.frame:Show();
end

function TextInput:SetLabel(txt)
    self.placeholderLabel:SetText(txt);
end

function TextInput:OnUpdate()
    if (time() - self.lastInputTime >= self.asyncWait and self.textDidChange) then
        if (self.onTextChanged) then
            self.onTextChanged(self:Get());
        end
        self.textDidChange = false;
    end
end

function TextInput:OnTextChanged()
    self.textDidChange = true;
    self.lastInputTime = time();
    local ctext = self:Get();
    if (not ctext or ctext == "") then
        self.placeholderLabel:Show();
        self.clearButton:Hide();
    else
        self.placeholderLabel:Hide();

        if (not self.frame:IsMultiLine()) then
            self.clearButton:Show();
        end
    end

    if (self.sourceValidation and ctext ~= "") then
        self.sourceValidation:Clear();
        if (self.sourceValidation:Validate(ctext)) then
            self.frame.Validated:Show();
        else
            self.frame.Validated:Hide();
        end       
    end
end

function TextInput:SetSize(width, height)
    self.frame:SetSize(width, height);
end

function TextInput:SetPoint(point, anchor, x, y, relativeTo)
    self.frame:ClearAllPoints();
    self.frame:SetPoint(point, relativeTo and self.parent[relativeTo] or self.parent, anchor, x, y);
end

function TextInput:Set(txt) 
    if (not self.frame) then
        return;
    end

    self.frame:SetText(txt);
end

function TextInput:Get()
    if (not self.frame) then 
        return "";
    end

    return strtrim(self.frame:GetText());
end