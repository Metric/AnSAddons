AnsGraph = {};
AnsGraph.__index = AnsGraph;

function AnsGraph:New(name, parent)
    local g = {};
    setmetatable(g, AnsGraph);

    -- predefined holders for textures lines etc
    g.lines = {};
    g.bgLines = {};
    g.yFonts = {};
    g.xFonts = {};
    g.fills = {};
    g.tfills = {};
    g.dots = {};
 
    g.data = {};

    g.max = 50;
    g.SECTION_SIZE = 0;
    g.SECTION_SIZE_PCT = 0;
    g.marginX = 0;
    g.marginY = 0;
    g.verticalPoints = 8;
    g.lineColor = {0,1,238/255,1};
    g.fillColor = {0,1,238/255,0.25};

    g.frame = CreateFrame("FRAME", name, parent, "AnsGraph");
    g.parent = parent;
    g.formatFn = nil;

    return g;
end

function AnsGraph:SetFormatter(fn)
    self.formatFn = fn;
end

function AnsGraph:OnDotEnter(f)
    local id = f:GetID();
    local data = self.data[id];

    if (data and self.formatFn) then
        -- show tooltip with amount from data point
        local tooltip = GameTooltip;
        tooltip:ClearLines();
        tooltip:SetOwner(f, "ANCHOR_RIGHT");
        tooltip:AddLine(self.formatFn(data), 1, 1, 1, false);
        tooltip:Show();
    end
end

function AnsGraph:OnDotLeave()
    -- hide tooltip
    local tooltip = GameTooltip;
    tooltip:Hide();
end

function AnsGraph:Load(x,y,point,anchor,width, height)
    local f = self.frame;
    local i;

    f:ClearAllPoints();
    f:SetPoint(point, self.parent, anchor, x, y);
    f:SetSize(width, height);

    self.SECTION_SIZE = math.ceil(f:GetHeight() / self.verticalPoints);
    self.SECTION_SIZE_PCT = self.SECTION_SIZE / f:GetHeight();

    wipe(self.yFonts);
    wipe(self.xFonts);
    wipe(self.fills);
    wipe(self.lines);
    wipe(self.bgLines);
    wipe(self.tfills);
    wipe(self.dots);

    for i = 1, 12 do
        local l = _G[f:GetName().."Line"..i]; 
        local lbg = _G[f:GetName().."LineBg"..i];

        local fill = _G[f:GetName().."Fill"..i];
        local tfill = _G[f:GetName().."TFill"..i];

        local yFont = _G[f:GetName().."YAxisLabel"..i];
        local xFont = _G[f:GetName().."XAxisLabel"..i];

        local dot = _G[f:GetName().."Dot"..i];

        if (dot) then
            tinsert(self.dots, dot);
            dot:SetScript("OnEnter", function(f, arg1) self:OnDotEnter(f) end);
            dot:SetScript("OnLeave", function() self:OnDotLeave() end);
        end

        if (tfill) then
            tinsert(self.tfills, tfill);
        end

        if (fill) then
            tinsert(self.fills, fill);
        end

        if (yFont) then
            tinsert(self.yFonts, yFont);
            yFont:ClearAllPoints();
            yFont:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", self.marginX - 20, (i - 1) * self.SECTION_SIZE + self.marginY);
            yFont:SetFont("Fonts\\FRIZQT__.TTF", 6); 
        end

        if (xFont) then
            tinsert(self.xFonts, xFont);
            xFont:SetFont("Fonts\\FRIZQT__.TTF", 6); 
        end

        tinsert(self.lines, l);

        if (lbg and i <= self.verticalPoints) then
            tinsert(self.bgLines, lbg);

            lbg:SetStartPoint("BOTTOMLEFT", f, self.marginX, (i - 1) * self.SECTION_SIZE + self.marginY);
            lbg:SetEndPoint("BOTTOMLEFT", f, f:GetWidth() - self.marginX, (i - 1) * self.SECTION_SIZE + self.marginY);
            lbg:SetThickness(0.5);
            lbg:SetColorTexture(1,1,1,0.125);

            lbg:Show();
        elseif (lbg) then
            lbg:Hide();
        end
       
        l:SetColorTexture(self.lineColor[1], self.lineColor[2], self.lineColor[3], self.lineColor[4]);
    end
end

function AnsGraph:Update(data, xlabels, ylabels, max)
    self.data = data;
    self.max = max;

    for i, v in ipairs(ylabels) do
        local f = self.yFonts[i];
        if (f) then
            f:SetText(v);
            f:Show();
        end
    end

    for i, v in ipairs(xlabels) do
        local f = self.xFonts[i];
        if (f) then
            f:SetText(v);
            f:Show();
        end
    end

    if (self.frame) then
        self:Render();
    end
end

function AnsGraph:SetRectFill(frame, fill, x, y, x2, y2)
    fill:SetTexture("Interface\\Buttons\\WHITE8X8");
    fill:SetTexCoord(0,1,0,1);
    fill:SetHorizTile(true);
    fill:SetVertTile(true);
    
    fill:ClearAllPoints();
    fill:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", x, self.marginY);
    fill:SetPoint("TOPRIGHT", frame, "BOTTOMLEFT", x2, math.min(y,y2));

    fill:SetVertexColor(self.fillColor[1], self.fillColor[2], self.fillColor[3], self.fillColor[4]);
end

function AnsGraph:SetTriangleFill(frame, fill, asc, x, y, x2, y2)  
    fill:SetTexture("Interface\\AddOns\\AnS\\Images\\triangle");

    if (asc) then
        fill:SetTexCoord(0, 0, 0, 1, 1, 0, 1, 1);
    else
        fill:SetTexCoord(1, 0, 1, 1, 0, 0, 0, 1);
    end

    fill:SetHorizTile(false);
    fill:SetVertTile(false); 

    fill:ClearAllPoints();
    fill:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", x, math.min(y2, y));
    fill:SetPoint("TOPRIGHT", frame, "BOTTOMLEFT", x2, math.max(y2, y));

    fill:SetVertexColor(self.fillColor[1], self.fillColor[2], self.fillColor[3], self.fillColor[4]);
end

function AnsGraph:Render()
    local f = self.frame;

    if (not f) then
        return;
    end

    if (#self.data == 0) then
        local i;
        for i = 1, 12 do
            self.lines[i]:Hide();
            self.xFonts[i]:Hide();
            self.fills[i]:Hide();
            self.tfills[i]:Hide();
            self.dots[i]:Hide();
        end

        for i = 1, 8 do
            self.yFonts[i]:Hide();
        end
        return;
    end

    local t = #self.data;
    local spacing = math.floor((f:GetWidth() - self.marginX) / ((t - 1) or 1));

    local prevXOffset = self.marginX;
    local prevYOffset = self.marginY;
    local i;

    for i = 1, t do
        local v = self.data[i];
        local xOffset = (i - 1) * spacing + self.marginX;
        local yOffset = math.floor(v / self.max * (f:GetHeight() - (self.SECTION_SIZE * 0.5))) + self.marginY;

        self.xFonts[i]:ClearAllPoints();
        self.xFonts[i]:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", xOffset - 6, self.marginY - 20);

        local dot = self.dots[i];

        if (dot) then
            dot:ClearAllPoints();
            dot:SetID(i);
            dot:SetPoint("CENTER", f, "BOTTOMLEFT", xOffset, yOffset);
        end

        local l = self.lines[i];

        l:SetStartPoint("BOTTOMLEFT", f, prevXOffset, prevYOffset);
        l:SetEndPoint("BOTTOMLEFT", f, xOffset, yOffset);
        l:SetThickness(1);
        l:Show();

        local fill = self.fills[i];
        local tfill = self.tfills[i];

        if (fill) then
            self:SetRectFill(f, fill, prevXOffset, prevYOffset, xOffset, yOffset);
            fill:Show();
        end

        if (tfill) then
            self:SetTriangleFill(f, tfill, prevYOffset < yOffset, prevXOffset, prevYOffset, xOffset, yOffset);
            tfill:Show();
        end

        prevXOffset = xOffset;
        prevYOffset = yOffset;
    end

    for i = #self.data+1, 12 do
        self.lines[i]:Hide();
        self.xFonts[i]:Hide();
        self.fills[i]:Hide();
        self.tfills[i]:Hide();
        self.dots[i]:Hide();
    end
end