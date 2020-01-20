local Ans = select(2, ...);
local MinimapIcon = {};
MinimapIcon.__index = MinimapIcon;

Ans.MinimapIcon = MinimapIcon;

--- Minimap  Icon ---

function MinimapIcon:New(name, icon, clickFn, onMoveFn, angle, tooltipLines)
    local micon = {};
    setmetatable(micon, MinimapIcon);
    micon.clickFn = clickFn;
    micon.tooltipLines = tooltipLines;
    micon.name = name;
    micon.angle = angle or 45;
    micon.onMoveFn = onMoveFn;

    micon.frame = CreateFrame("BUTTON", name, Minimap, "AnsMiniButtonTemplate");
    micon.frame:SetScript("OnClick", micon.clickFn);
    micon.frame:SetScript("OnDragStart", function() micon:OnDragStart() end);
    micon.frame:SetScript("OnDragStop", function() micon:OnDragStop() end);
    micon.frame:SetScript("OnUpdate", function() micon:OnUpdate() end);
    micon.frame:SetScript("OnEnter", function() micon:ShowTip() end);
    micon.frame:SetScript("OnLeave", function() micon:HideTip() end);

    micon.isDragging = false;

    local ictex = _G[micon.frame:GetName().."Icon"];
    ictex:SetTexture(icon);

    micon:Reposition();

    return micon;
end

function MinimapIcon:ShowTip()
    local tip = GameTooltip;
    if (self.tooltipLines and #self.tooltipLines > 0) then
        tip:ClearLines();
        tip:SetOwner(self.frame, "ANCHOR_LEFT");

        for i,v in ipairs(self.tooltipLines) do
            tip:AddLine(v, 1, 1, 1, false);
        end

        tip:Show();
    end
end

function MinimapIcon:HideTip()
    GameTooltip:Hide();
end

function MinimapIcon:Reposition()
    if (self.onMoveFn) then
        self.onMoveFn(self.angle);
    end
    self.frame:SetPoint("TOPLEFT", "Minimap", "TOPLEFT", 52 - (80*cos(self.angle)), (80*sin(self.angle)) - 52);
end

function MinimapIcon:OnUpdate()
    if (self.isDragging) then
        local xpos, ypos = GetCursorPosition();
        local xmin, ymin = Minimap:GetLeft(), Minimap:GetBottom();

        xpos = xmin-xpos/UIParent:GetScale() + 72;
        ypos = ypos/UIParent:GetScale() - ymin - 72;

        self.angle = math.deg(math.atan2(ypos,xpos));
        self:Reposition();
    end
end

function MinimapIcon:OnDragStart()
    self.frame:LockHighlight();
    self.isDragging = true;
end

function MinimapIcon:OnDragStop()
    self.frame:UnlockHighlight();
    self.isDragging = false;
end

function MinimapIcon:Hide() 
    self.frame:Hide();
end

function MinimapIcon:Show()
    self.frame:Show();
end