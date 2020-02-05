local Ans = select(2, ...);
local Dropdown = {};
Dropdown.__index = Dropdown;
Ans.UI.Dropdown = Dropdown;

function Dropdown:New(name, parent)
    local dp = {};
    setmetatable(dp, Dropdown);
    dp.items = {};
    dp.frame = CreateFrame("BUTTON", name, parent, "AnsDropdownTemplate");

    dp.list = _G[dp.frame:GetName().."List"];
    dp.scrollFrame = _G[dp.list:GetName().."ScrollFrame"];
    dp.scrollBar = _G[dp.scrollFrame:GetName().."ScrollBar"];

    dp.selected = 1;
    dp.multiselect = false;
    dp.parent = parent;
    dp.hoverCount = 0;

    dp:RegisterEvents();

    return dp;
end

function Dropdown:SetSize(width, height)
    self.frame:SetSize(width, height);
    self.list:SetSize(width, height * 4);
    self.scrollFrame:SetSize(width, height * 4);
    _G[self.list:GetName().."BG"]:SetSize(width, height * 4);

    local i;
    for i = 1, 4 do
        _G[self.list:GetName().."Item"..i]:SetSize(width, height);
    end
end

function Dropdown:Hide()
    if (not self.frame) then
        return;
    end

    self.frame:Hide();
end

function Dropdown:Show()
    if (not self.frame) then
        return;
    end

    self.frame:Show();
end

function Dropdown:SetPoint(point, anchor, x, y)
    self.frame:ClearAllPoints();
    self.frame:SetPoint(point, self.parent, anchor, x, y);
end

function Dropdown:RegisterEvents()
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

    self.scrollFrame:SetScript("OnEnter", function() dp.hoverCount = dp.hoverCount + 1; end);
    self.scrollFrame:SetScript("OnLeave", function() dp.hoverCount = dp.hoverCount - 1; end);

    self.scrollBar:SetScript("OnEnter", function() dp.hoverCount = dp.hoverCount + 1; end);
    self.scrollBar:SetScript("OnLeave", function() dp.hoverCount = dp.hoverCount - 1; end);

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

function Dropdown:IsMouseOver()
    if(self.hoverCount <= 0) then
        self:Close();
    end
end

function Dropdown:ItemClick(f)
    local offset = f:GetID();
    self:SetSelected(offset);
    self:Close();
end

function Dropdown:ClearItems()
    wipe(self.items);
    if (self.multiselect) then
        self.selected = {};
    else
        self.selected = 1;
    end
    self:Refresh();
    self:Close();
end

function Dropdown:SetSelected(index)
    if(index < 1) then
        index = 1;
    elseif (index > #self.items) then
        index = 1;
    end

    local item = self.items[index];

    if (self.multiselect) then
        if (type(self.selected) ~= "table") then
            if (self.selected == index) then
                self.selected = {};
            else
                self.selected = {index};
            end
        else
            if (Utils:InTable(self.selected, index)) then
                for i,v in ipairs(self.selected) do
                    if (v == index) then
                        tremove(self.selected, i);
                        break;
                    end
                end
            else
                tinsert(self.selected, index);
            end
        end
    else
        self.selected = index;
    end

    if (self.multiselect) then
        local label = "";
        local sep = "";
        for i,v in ipairs(self.selected) do
            local item = self.items[v];
            if (item) then
                label = label..sep..item.text;
                sep = ",";
            end
        end
        self.frame:SetText(label);
    elseif (item) then
        self.frame:SetText(item.text);
    end

    if (item) then
        item.fn();
    end

    self:Refresh();
end

function Dropdown:SetItems(items)
    self:ClearItems();

    local i;
    for i = 1, #items do
        local c = items[i];
        self:AddItem(c.text, c.fn);
    end
end

function Dropdown:AddItem(text, fn)
    tinsert(self.items, {text = text, fn = fn});

    if (not self.multiselect) then
        if(#self.items == 1) then
            self.frame:SetText(text);
        end
    end

    self:Refresh();
end

function Dropdown:Toggle()
    if (self.list:IsShown()) then
        self.list:Hide();
    else
        self.list:Show();
    end
end

function Dropdown:Close()
    self.list:Hide();
end

function Dropdown:ClearView()
    local i;
    for i = 1, 4 do
        local litem = _G[self.list:GetName().."Item"..i];
        if (litem) then
            litem:Hide();
        end
    end
end

function Dropdown:UpdateRow(offset, line)
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

function Dropdown:Refresh()
    local offset = FauxScrollFrame_GetOffset(self.scrollFrame);
    local line;
    local dataOffset;

    for line = 1, 4 do
        dataOffset = line + offset;
        self:UpdateRow(dataOffset, line);
    end

    FauxScrollFrame_Update(self.scrollFrame, #self.items, 4, self.frame:GetHeight());
end