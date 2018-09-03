AnsFilterView = {};
AnsFilterView.__index = AnsFilterView;

function AnsFilterView:SelectClear()
    local i;
    for i = 1, #AnsFilterSelected do
        AnsFilterSelected[i] = false;
    end
end

function AnsFilterView:UpdateRow(parent, row, dataOffset, line)
    local text = _G[row:GetName().."NormalText"];
    local total = #parent;

    if (dataOffset <= total) then
        local filter = parent[dataOffset];
        
        row:SetID(dataOffset);

        if (AnsFilterSelected[dataOffset]) then
            row:LockHighlight();
        else
            row:UnlockHighlight();
        end

        if (not filter.isSub) then
            text:SetPoint("LEFT", row, "LEFT", 4, 0);
            row:GetNormalTexture():SetAlpha(1.0);
        else
            text:SetPoint("LEFT", row, "LEFT", 12, 0);
            row:GetNormalTexture():SetAlpha(0);
        end

        row:SetText(filter.name);

        row:Show();
    else
        row:Hide();
    end
end

function AnsFilterView:Refresh(frame, templateName)
    local line;
    local fTotal = #AnsFilterList;

    FauxScrollFrame_Update(frame, fTotal, 15, 20);

    local offset = FauxScrollFrame_GetOffset(frame);
    local dataOffset = 0;

    for line = 1, 15 do
        local row = _G[templateName..line];
        dataOffset = offset + line;
        self:UpdateRow(AnsFilterList, row, dataOffset, line);
    end
end

function AnsFilterView:Click(row, frame, templateName)
    local id = row:GetID();
    local filter = AnsFilterList[id];
    local text = _G[row:GetName().."NormalText"];

    if (AnsFilterSelected[id]) then
        AnsFilterSelected[id] = false;
    else
        AnsFilterSelected[id] = true;
    end

    self:Refresh(frame, templateName);

    if (not filter.isSub) then
        text:SetPoint("LEFT", row, "LEFT", 4, 0);
        row:GetNormalTexture():SetAlpha(1.0);
    else
        text:SetPoint("LEFT", row, "LEFT", 12, 0);
        row:GetNormalTexture():SetAlpha(0);
    end
end