local Ans = select(2, ...);
local TreeView = {};
TreeView.__index = TreeView;

Ans.UI.TreeView = TreeView;

function TreeView:New(parent, style, selectFn, upFn, downFn, renderFn)
    local fv = {};
    setmetatable(fv, TreeView);
    fv.view = {};
    fv.items = {};

    fv.frame = _G[parent:GetName().."TreeView"];
    fv.scrollFrame = fv.frame;
    fv.childFrame = _G[fv.scrollFrame:GetName().."ScrollChildFrame"];
    fv.childFrame:SetSize(fv.frame:GetWidth(), fv.frame:GetHeight());

    fv.parent = parent;

    fv.rows = {};

    fv.style = style or {
        rowHeight = 20,
        childIndent = 16,
        template = "AnsTreeRowTemplate",
        multiselect = true,
        useNormalTexture = false
    };
    
    fv.style.totalRows = math.floor(fv.frame:GetHeight() / fv.style.rowHeight);

    fv.selectFn = selectFn;
    fv.upFn = upFn;
    fv.downFn = downFn;
    fv.renderFn = renderFn;

    fv:RegisterEvents();
    fv:CreateRows();

    return fv;
end

function TreeView:CreateRows()
    local fv = self;
    local i;
    for i = 1, self.style.totalRows do
        local f = CreateFrame("BUTTON", self.frame:GetName().."ItemRow"..i, self.scrollFrame:GetParent(), self.style.template);
        tinsert(self.rows, f);

        f.origTextWidth = 0;

        local txt = _G[f:GetName().."Text"];

        if (txt) then
            f.origTextWidth = txt:GetWidth();
        end

        f:SetHeight(self.style.rowHeight);
        f:SetWidth(self.scrollFrame:GetWidth());
        f:ClearAllPoints();
        f:SetPoint("TOPLEFT", self.scrollFrame, "TOPLEFT", 0, (i - 1) * -self.style.rowHeight);

        local expander = _G[f:GetName().."Expander"];
        if (expander) then
            expander:SetScript("OnClick", function() fv:ToggleExpand(f) end);
        end
        local moveUp = _G[f:GetName().."MoveUp"];
        if (moveUp) then
            moveUp:SetScript("OnClick", function() fv:OnUp(f) end);
        end
        local moveDown = _G[f:GetName().."MoveDown"];
        if (moveDown) then
            moveDown:SetScript("OnClick", function() fv:OnDown(f) end);
        end

        f:SetScript("OnClick", function() fv:OnSelect(f) end);
    end
end

function TreeView:OnUp(r)
    if (self.upFn) then
        self.upFn(r.item);
    end
end

function TreeView:OnDown(r)
    if (self.downFn) then
        self.downFn(r.item);
    end
end

function TreeView:Refresh()
    local fv = self;
    wipe(self.view);

    -- clear row items link
    for i,v in ipairs(self.rows) do
        v.item = nil;
    end

    for i,v in ipairs(self.items) do
        if (not v.hidden) then
            if (i == 1) then
                v.offset = 0;
            else
                v.offset = self.style.childIndent;
            end
            tinsert(self.view, v);

            if (v.children and #v.children > 0 and v.expanded) then
                self:InsertChildren(v.children, v.offset);
            end
        end
    end

    local offset = FauxScrollFrame_GetOffset(self.scrollFrame);
    local i;
    for i = 1, self.style.totalRows do
        local doffset = i + offset;
        self:UpdateRow(doffset, self.rows[i]);
    end

    FauxScrollFrame_Update(self.scrollFrame, #self.view, self.style.totalRows, self.style.rowHeight);
end

function TreeView:ReleaseView()
    wipe(self.items);
    wipe(self.view);

    for i,v in ipairs(self.rows) do
        v.item = nil;
    end

    FauxScrollFrame_Update(self.scrollFrame, #self.view, self.style.totalRows, self.style.rowHeight);
end

function TreeView:UpdateByData(data)
    for i,v in ipairs(self.rows) do
        if (v.item == data) then
            self:UpdateRow(v:GetID(), v);
            return;
        end
    end
end

function TreeView:UpdateRow(offset, row)
    if (offset <= #self.view) then
        row.item = self.view[offset];

        if (not row.item) then
            row:Hide();
            return;
        end

        row:SetID(offset);

        local expander = _G[row:GetName().."Expander"];
        if (expander) then
            if (row.item.children and #row.item.children > 0) then
                if (row.item.expanded) then
                    expander:SetText("-");
                else
                    expander:SetText("+");
                end
                expander:Show();
            else
                expander:Hide();
            end
        end

        if (row.item.selected) then
            row:LockHighlight();
        else
            row:UnlockHighlight();
        end

        if (_G[row:GetName().."Text"]) then
            _G[row:GetName().."Text"]:SetPoint("TOPLEFT", row.item.offset, 0);
            _G[row:GetName().."Text"]:SetWidth(row.origTextWidth - row.item.offset);
            _G[row:GetName().."Text"]:SetText(row.item.name);
        end

        if (row:GetNormalTexture() and self.style.useNormalTexture) then
            if (row.item.offset > self.style.childIndent) then
                row:GetNormalTexture():SetAlpha(0);
            else
                row:GetNormalTexture():SetAlpha(1);
            end
        end

        if (self.renderFn) then
            self.renderFn(row, row.item);
        end

        row:Show();
    else
        row:Hide();
    end
end

function TreeView:InsertChildren(children, offset)
    for i, v in ipairs(children) do
        if (not v.hidden) then
            v.offset = offset + math.floor(self.style.childIndent / 2);
            tinsert(self.view, v);

            if (v.children and #v.children > 0 and v.expanded) then
                self:InsertChildren(v.children, v.offset);
            end
        end
    end
end

function TreeView:RemoveSelections()
    if (not self.style.multiselect) then
        for i,v in ipairs(self.items) do
            v.selected = false;
        end
        for i,v in ipairs(self.rows) do
            self:UpdateRow(v:GetID(), v);
        end
    end
end

function TreeView:OnSelect(f)
    self:RemoveSelections();

    if (f.item.selected) then
        f.item.selected = false;
    else
        f.item.selected = true;
    end

    if (self.selectFn) then
        self.selectFn(f.item);
    end

    self:UpdateRow(f:GetID(), f);
end

function TreeView:ToggleExpand(f)
    if (f.item.expanded) then
        f.item.expanded = false;
    else
        f.item.expanded = true;
    end

    self:Refresh();
end

function TreeView:RegisterEvents()
    local fv = self;
    self.scrollFrame:SetScript("OnVerticalScroll", 
        function(f, offset)
            FauxScrollFrame_OnVerticalScroll(f, offset, fv.style.rowHeight,
            function()
                fv:Refresh();
            end);
        end);
end