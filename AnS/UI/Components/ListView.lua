local Ans = select(2, ...);
local ListView = {};
ListView.__index = ListView;

Ans.UI.ListView = ListView;

function ListView:New(parent, style, selectFn, upFn, downFn, renderFn)
    local fv = {};
    setmetatable(fv, ListView);
    fv.view = {};
    fv.items = {};

    fv.frame = _G[parent:GetName().."ListView"];
    fv.scrollFrame = fv.frame;
    fv.childFrame = _G[fv.scrollFrame:GetName().."ScrollChildFrame"];
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

    fv:RegisterEvents();
    fv:CreateRows();

    return fv;
end

function ListView:CreateRows()
    local fv = self;
    local i;
    for i = 1, self.style.totalRows do
        local f = CreateFrame("BUTTON", self.frame:GetName().."ItemRow"..i, self.scrollFrame:GetParent(), self.style.template);
        tinsert(self.rows, f);
        
        f:SetHeight(self.style.rowHeight);
        f:SetWidth(self.scrollFrame:GetWidth());
        f:ClearAllPoints();
        f:SetPoint("TOPLEFT", self.scrollFrame, "TOPLEFT", 0, (i - 1) * -self.style.rowHeight);

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

        if (_G[row:GetName().."Text"]) then
            _G[row:GetName().."Text"]:SetText(row.item.name);
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
        for i,v in ipairs(self.items) do
            v.selected = false;
        end
        for i,v in ipairs(self.rows) do
            self:UpdateRow(v:GetID(), v);
        end
    end
end

function ListView:OnSelect(f)
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