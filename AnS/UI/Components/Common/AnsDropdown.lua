AnsDropdown = {};
AnsDropdown.__index = AnsDropdown;

function AnsDropdown:New(name, parent)
    local dp = {};
    setmetatable(dp, AnsDropdown);
    dp.items = {};
    dp.frame = CreateFrame("BUTTON", name, parent, "AnsDropdownTemplate");

    dp.list = _G[dp.frame:GetName().."List"];
    dp.selected = 1;
    dp.scrollFrame = _G[dp.list:GetName().."ScrollFrame"];

    dp.parent = parent;
    dp.hoverCount = 0;

    dp:RegisterEvents();

    return dp;
end

function AnsDropdown:SetSize(width, height)
    self.frame:SetSize(width, height);
    self.list:SetSize(width, height * 4);
    self.scrollFrame:SetSize(width, height * 4);
    _G[self.scrollFrame:GetName().."ScrollChildFrame"]:SetSize(width, height * 4);
    _G[self.list:GetName().."BG"]:SetSize(width, height * 4);

    local i;
    for i = 1, 4 do
        _G[self.list:GetName().."Item"..i]:SetSize(width, height);
    end
end

function AnsDropdown:SetPoint(point, anchor, x, y)
    self.frame:ClearAllPoints();
    self.frame:SetPoint(point, self.parent, anchor, x, y);
end

function AnsDropdown:RegisterEvents()
    local dp = self;
    self.frame:SetScript("OnUpdate", function(f) dp:IsMouseOver() end);
    self.frame:SetScript("OnEnter", function() dp.hoverCount = dp.hoverCount + 1; end);
    self.frame:SetScript("OnLeave", function() dp.hoverCount = dp.hoverCount - 1; end);
    self.scrollFrame:SetScript("OnVerticalScroll", function(f, offset) 
        FauxScrollFrame_OnVerticalScroll(f, offset, dp.frame:GetHeight(), 
        function() 
            dp:Refresh(); 
        end); 
    end);
    self.frame:SetScript("OnClick", function(f, arg1) dp:Toggle() end);
    self.list:SetScript("OnEnter", function() dp.hoverCount = dp.hoverCount + 1; end);
    self.list:SetScript("OnLeave", function() dp.hoverCount = dp.hoverCount - 1; end);

    local i;
    for i = 1, 4 do
        local litem = _G[dp.list:GetName().."Item"..i];
        if (litem) then
            litem:SetScript("OnClick", function(f, arg1) dp:ItemClick(f) end);
            litem:SetScript("OnEnter", function() dp.hoverCount = dp.hoverCount + 1; end);
            litem:SetScript("OnLeave", function() dp.hoverCount = dp.hoverCount - 1; end);        
        end
    end
end

function AnsDropdown:IsMouseOver()
    if(self.hoverCount <= 0) then
        self:Close();
    end
end

function AnsDropdown:ItemClick(f)
    local offset = f:GetID();

    local item = self.items[offset];
    self.selected = offset;

    self.frame:SetText(item.text);

    item.fn();

    self:Close();
end

function AnsDropdown:ClearItems()
    wipe(self.items);
    self:Refresh();
    self:Close();
end

function AnsDropdown:SetSelected(index)
    self.selected = index;

    if(self.selected < 1) then
        self.selected = 1;
    elseif (self.selected > #self.items) then
        self.selected = 1;
    end

    local item = self.items[self.selected];

    if (item) then
        item.fn();
    end

    self:Refresh();
end

function AnsDropdown:SetItems(items)
    self:ClearItems();

    local i;
    for i = 1, #items do
        local c = items[i];
        self:AddItem(c.text, c.fn);
    end
end

function AnsDropdown:AddItem(text, fn)
    tinsert(self.items, {text = text, fn = fn});

    if(#self.items == 1) then
        self.frame:SetText(text);
    end

    self:Refresh();
end

function AnsDropdown:Toggle()
    if (self.list:IsShown()) then
        self.list:Hide();
    else
        self.list:Show();
    end
end

function AnsDropdown:Close()
    self.list:Hide();
end

function AnsDropdown:ClearView()
    local i;
    for i = 1, 4 do
        local litem = _G[self.list:GetName().."Item"..i];
        if (litem) then
            litem:Hide();
        end
    end
end

function AnsDropdown:UpdateRow(offset, line)
    local litem = _G[self.list:GetName().."Item"..line];
    if(offset <= #self.items) then
        local d = self.items[offset];
        litem:SetID(offset);

        if(offset == self.selected) then
            litem:SetButtonState("PUSHED", true);
        else
            litem:SetButtonState("NORMAL", false);
        end

        litem:SetText(d.text);

        litem:Show();
    else
        litem:Hide();
    end
end

function AnsDropdown:Refresh()
    --self:ClearView();

    FauxScrollFrame_Update(self.scrollFrame, #self.items, 4, self.frame:GetHeight());

    local offset = FauxScrollFrame_GetOffset(self.scrollFrame);
    local line;
    local dataOffset;

    for line = 1, 4 do
        dataOffset = line + offset;
        self:UpdateRow(dataOffset, line);
    end
end