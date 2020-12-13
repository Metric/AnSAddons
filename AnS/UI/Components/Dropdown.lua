local Ans = select(2, ...);
local ListView = Ans.UI.ListView;
local Dropdown = Ans.Object.Register("Dropdown", Ans.UI);

function Dropdown:Acquire(name, parent)
    local dp = Dropdown:New();
    dp.items = {};
    dp.frame = CreateFrame("BUTTON", name, parent, "AnsDropdownTemplate");

    dp.list = dp.frame.List;
    dp.listView = ListView:Acquire(dp.frame.List, 
        {rowHeight = 24, childIndent = 0, template = "AnsDropdownItemTemplate"},
        function(item, index)
            dp:ItemClick(index);
        end, nil, nil,
        function(row, item)
            row:SetScript("OnEnter", function() dp.hoverCount = dp.hoverCount + 1; end);
            row:SetScript("OnLeave", function() dp.hoverCount = dp.hoverCount - 1; end); 
        end 
    );
    dp.listView.items = dp.items;

    dp.scrollFrame = dp.frame.List.ScrollFrame;
    dp.scrollBar = dp.frame.List.ScrollFrame.ScrollBar;
    dp.childFrame = dp.scrollFrame.ScrollChildFrame;

    dp.selected = 1;
    dp.parent = parent;
    dp.hoverCount = 0;

    dp:RegisterEvents();

    return dp;
end

function Dropdown:SetSize(width, height)
    self.frame:SetSize(width, height);
    self.list:SetSize(width, height * 4);
    self.scrollFrame:SetSize(width, height * 4);
    self.childFrame:SetSize(width, height * 4);
    self.listView:Resize();
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

function Dropdown:SetPoint(point, anchor, x, y, relativeTo)
    self.frame:ClearAllPoints();
    self.frame:SetPoint(point, relativeTo and self.parent[relativeTo] or self.parent, anchor, x, y);
end

function Dropdown:RegisterEvents()
    local dp = self;
    self.frame:SetScript("OnClick", function() dp:Toggle(); end);
    self.frame:SetScript("OnUpdate", function(f) dp:IsMouseOver() end);
    self.frame:SetScript("OnEnter", function() dp.hoverCount = dp.hoverCount + 1; end);
    self.frame:SetScript("OnLeave", function() dp.hoverCount = dp.hoverCount - 1; end);

    self.list:SetScript("OnEnter", function() dp.hoverCount = dp.hoverCount + 1; end);
    self.list:SetScript("OnLeave", function() dp.hoverCount = dp.hoverCount - 1; end);

    self.scrollFrame:SetScript("OnEnter", function() dp.hoverCount = dp.hoverCount + 1; end);
    self.scrollFrame:SetScript("OnLeave", function() dp.hoverCount = dp.hoverCount - 1; end);

    self.scrollBar:SetScript("OnEnter", function() dp.hoverCount = dp.hoverCount + 1; end);
    self.scrollBar:SetScript("OnLeave", function() dp.hoverCount = dp.hoverCount - 1; end);
end

function Dropdown:IsMouseOver()
    if(self.hoverCount <= 0) then
        self:Close();
    end
end

function Dropdown:ItemClick(index)
    self:SetSelected(index);
    self:Close();
end

function Dropdown:ClearItems()
    wipe(self.items);
    self.selected = 1;
    self:Refresh();
    self:Close();
end

function Dropdown:SetSelected(index)
    if(index < 1) then
        index = 1;
    elseif (index > #self.items) then
        index = 1;
    end

    local previous = self.items[self.selected];
    if (previous) then
        previous.selected = false;
    end

    local item = self.items[index];

    self.selected = index;

    if (item) then
        item.selected = true;
        self.frame:SetText(item.name);
    end

    if (item and item.fn) then
        item.fn(index);
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
    tinsert(self.items, {name = text, fn = fn, selected = #self.items == 0});

    if(#self.items == 1) then
        self.frame:SetText(text);
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

function Dropdown:Open()
    self.list:Show();
end

function Dropdown:Close()
    self.list:Hide();
end

function Dropdown:Refresh()
    self.listView:Refresh();
end