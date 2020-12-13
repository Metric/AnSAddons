local Ans = select(2, ...);
local ListView = Ans.Object.Register("ListView", Ans.UI);

function ListView:Acquire(parent, style, selectFn, upFn, downFn, renderFn)
    local fv = ListView:New();
    fv.view = {};
    fv.items = {};

    fv.lastSelectedIndex = 0;

    fv.frame = parent.ScrollFrame;
    fv.scrollFrame = fv.frame;
    fv.childFrame = fv.scrollFrame.ScrollChildFrame;
    fv.childFrame:SetSize(fv.frame:GetWidth(), fv.frame:GetHeight());

    fv.parent = parent;

    fv.rows = {};

    fv.style = style or {
        rowHeight = 20,
        childIndent = 16,
        template = "AnsTreeRowTemplate",
        multiselect = false,
        usePushTexture = false
    };
    
    fv.style.totalRows = math.floor(fv.frame:GetHeight() / fv.style.rowHeight);

    fv.selectFn = selectFn;
    fv.upFn = upFn;
    fv.downFn = downFn;
    fv.renderFn = renderFn;

    fv.selected = 1;

    fv:RegisterEvents();
    fv:CreateRows(1, fv.style.totalRows);

    return fv;
end

function ListView:CreateRows(start,endIndex)
    local fv = self;
    local i;
    for i = start, endIndex do
        local f = CreateFrame("BUTTON", nil, self.scrollFrame:GetParent(), self.style.template);
        tinsert(self.rows, f);
        
        f:SetHeight(self.style.rowHeight);
        f:SetWidth(self.scrollFrame:GetWidth());
        f:ClearAllPoints();
        f:SetPoint("TOPLEFT", self.scrollFrame, "TOPLEFT", 0, (i - 1) * -self.style.rowHeight);

        local moveUp = f.MoveUp;
        if (moveUp) then
            moveUp:SetScript("OnClick", function() fv:OnUp(f) end);
        end
        local moveDown = f.MoveDown;
        if (moveDown) then
            moveDown:SetScript("OnClick", function() fv:OnDown(f) end);
        end

        f:SetScript("OnClick", function() fv:OnSelect(f) end);
    end
end

function ListView:SetPoint(point, anchor, x, y, relativeTo)
    self.frame:ClearAllPoints();
    self.frame:SetPoint(point, relativeTo and self.parent[relativeTo] or self.parent, anchor, x, y);
end

function ListView:Resize()
    local total = math.floor(self.frame:GetHeight() / self.style.rowHeight);
    if (self.style.totalRows < total) then
        self:CreateRows(self.style.totalRows, total);
    end

    for i = 1, total do
        self.rows[i]:ClearAllPoints();
        self.rows[i]:SetPoint("TOPLEFT", self.scrollFrame, "TOPLEFT", 0, (i - 1) * -self.style.rowHeight);
    end

    self.style.totalRows = total;
    self:Refresh();
end

function ListView:OnUp(r)
    if (self.upFn) then
        self.upFn(r.item);
    end
end

function ListView:OnDown(r)
    if (self.downFn) then
        self.downFn(r.item);
    end
end

function ListView:Refresh()
    local fv = self;
    local offset = FauxScrollFrame_GetOffset(self.scrollFrame);
    local i;
    for i = 1, self.style.totalRows do
        local doffset = i + offset;
        self:UpdateRow(doffset, self.rows[i]);
    end

    FauxScrollFrame_Update(self.scrollFrame, #self.items, self.style.totalRows, self.style.rowHeight);
end

function ListView:ReleaseView()
    wipe(self.items);

    for i,v in ipairs(self.rows) do
        v.item = nil;
    end

    FauxScrollFrame_Update(self.scrollFrame, #self.items, self.style.totalRows, self.style.rowHeight);
end

function ListView:UpdateRow(offset, row)
    if (offset <= #self.items) then
        row.item = self.items[offset];

        if (not row.item) then
            row:Hide();
            return;
        end

        row:SetID(offset);

        if (not self.style.usePushTexture) then
            if (row.item.selected) then
                row:LockHighlight();
            else
                row:UnlockHighlight();
            end
        else
            if (row.item.selected) then
                row:SetButtonState("PUSHED", true);
            else
                row:SetButtonState("NORMAL", false);
            end
        end

        if (row.Text) then
            row.Text:SetText(row.item.name);
        end

        if (self.renderFn) then
            self.renderFn(row, row.item);
        end

        row:Show();
    else
        row:Hide();
    end
end

function ListView:RemoveSelections()
    if (not self.style.multiselect) then
        if (self.items[self.selected]) then
            self.items[self.selected].selected = false;
        end
        for i,v in ipairs(self.rows) do
            self:UpdateRow(v:GetID(), v);
        end
    end
end

function ListView:SetSelected(index)
    if (index < 1 or index > #self.items) then
        index = 1;
    end

    if (not self.style.multiselect) then
        if (self.items[self.selected]) then
            self.items[self.selected].selected = false;
        end
    end
    
    local item = self.items[index];
    if (item) then
        if (self.style.multiselect) then
            item.selected = not item.selected;
        else
            item.selected = true;
        end
    end

    self.selected = index;
    
    if (self.selectFn) then
        self.selectFn(item, self.selected);
    end

    for i,v in ipairs(self.rows) do
        self:UpdateRow(v:GetID(), v);
    end
end

function ListView:ApplyShiftSelect(index)
    if (self.style.multiselect and IsShiftKeyDown() and index) then
        if (self.lastSelectedIndex and self.lastSelectedIndex > 0) then
            local last = self.lastSelectedIndex;
            self.lastSelectedIndex = 0;

            local startIndex = last > index and index or last;
            local endIndex = last > index and last or index;

            for i = startIndex + 1, endIndex - 1 do
                self:SetSelected(i);
            end
        end
    end

    if (index) then
        self.lastSelectedIndex = index;
    end
end

function ListView:OnSelect(f)
    self:RemoveSelections();

    self.selected = f:GetID();

    if (self.style.multiselect) then
        if (f.item.selected) then
            f.item.selected = false;
        else
            f.item.selected = true;
        end
    else
        f.item.selected = true;
    end

    if (self.selectFn) then
        self.selectFn(f.item, self.selected);
    end

    self:UpdateRow(f:GetID(), f);
    self:ApplyShiftSelect(self.selected);
end

function ListView:RegisterEvents()
    local fv = self;
    self.scrollFrame:SetScript("OnVerticalScroll", 
        function(f, offset)
            FauxScrollFrame_OnVerticalScroll(f, offset, fv.style.rowHeight,
            function()
                fv:Refresh();
            end);
        end);
end