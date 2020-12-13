local Ans = select(2, ...);
local EventManager = Ans.EventManager;
local Graph = Ans.UI.Graph;
local Dropdown = Ans.UI.Dropdown;
local Utils = Ans.Utils;
local ListView = Ans.UI.ListView;
local Config = Ans.Config;

local DataQuery = Ans.Analytics.Query;

local TIME_MINUTES = 1;
local TIME_HOURS = 2;
local TIME_DAYS = 3;
local TIME_MONTHS = 4;

local TIME_SCALE = {TIME_MINUTES,TIME_HOURS,TIME_DAYS,TIME_MONTHS};

local GOLD_QUERY_TABLE_CACHE = {{},{},{},{},{},{},{},{},{},{},{},{}};
local GOLD_MINUTES = {60,55,50,45,35,30,25,20,15,10,5,0};
local GOLD_HOURS = {60 * 11, 60 * 10, 60 * 9, 60 * 8, 60 * 7, 60 * 6, 60 * 5, 60 * 4, 60 * 3, 60 * 2, 60, 0};
local GOLD_DAYS = {60 * 24 * 11, 60 * 24 * 10, 60 * 24 * 9, 60 * 24 * 8, 60 * 24 * 7, 60 * 24 * 6, 60 * 24 * 5, 60 * 24 * 4, 60 * 24 * 3, 60 * 24 * 2, 60 * 24, 0}; 
local GOLD_MONTHS = {};

for i,v in ipairs(GOLD_DAYS) do
    tinsert(GOLD_MONTHS, v * 30);
end

local CHAR_CACHE = {};
local SALES_CACHE = {};
local PURCHASE_CACHE = {};

local DEFAULT_MODE = TIME_DAYS;

-- temp tables for stuff
local t1 = {};
local t2 = {};
local t3 = {};

AnsDashboardFrameMixin = {};

function AnsDashboardFrameMixin:Init()
    local this = self;
    self:SetScript("OnShow", function() this:OnShow(); end);
    EventManager:On("ANS_DATA_READY", function() this:Ready(); end);
end

function AnsDashboardFrameMixin:Ready()
    local this = self;
    -- register for event updates to gold log
    -- get known characters
    EventManager:On("GOLDLOG_UPDATE", function() this:UpdateGraph() end);
    EventManager:On("LOG_UPDATE", function() this:LoadRecentData() end);

    CHAR_CACHE = { unpack(DataQuery:GetGoldCharacters()) };
    table.sort(CHAR_CACHE, function(x,y) return x < y; end);

    self:LoadTimeScaleDropdown();
    self:LoadCharacterGoldDropdown();

    self:LoadGraph();

    self:LoadRecentSales();
    self:LoadRecentPurchases();

    self.graphTimeScale:SetSelected(Config.General().defaultTimeMode or DEFAULT_MODE);
end

function AnsDashboardFrameMixin:OnShow()
    self:LoadRecentData();
    self:UpdateGraph();
end

function AnsDashboardFrameMixin:RefreshStats()
    if (not self.characterGold) then
        return;
    end

    local saleTotalText = self.StatSales.Total;
    local saleAverage = self.StatSales.Average;

    local expenseTotalText = self.StatExpenses.Total; -- _G[self.statsExpenses:GetName().."Total"];
    local expenseAverage = self.StatExpenses.Average; -- _G[self.statsExpenses:GetName().."Average"];

    local profitTotalText = self.StatProfit.Total; -- _G[self.statsProfit:GetName().."Total"];
    local profitAverage = self.StatProfit.Average; -- _G[self.statsProfit:GetName().."Average"];

    local t = 0;
    if (self.timeMode == TIME_MINUTES) then
        t = 60 * 60;
    elseif (self.timeMode == TIME_HOURS) then
        t = 60 * 60 * 11;
    elseif (self.timeMode == TIME_DAYS) then
        t = 60 * 60 * 24 * 11;
	elseif (self.timeMode == TIME_MONTHS) then
		t = 60 * 60 * 24 * 30 * 11;
    end

    local chrs = CHAR_CACHE;

    if (self.characterGold.selected > 1) then
        chrs = {CHAR_CACHE[self.characterGold.selected - 1]};
    end

    local p, pavg = DataQuery:JoinTotalProfit(chrs, time() - t);
    local s, savg = DataQuery:JoinTotalSales(chrs, time() - t);
    local e, eavg = DataQuery:JoinTotalExpenses(chrs, time() - t);

    saleTotalText:SetText(Utils.PriceToString(s));
    saleAverage:SetText(Utils.PriceToString(savg));

    expenseTotalText:SetText(Utils.PriceToString(e));
    expenseAverage:SetText(Utils.PriceToString(eavg));

    profitTotalText:SetText(Utils.PriceToString(p));
    profitAverage:SetText(Utils.PriceToString(pavg));
end

function AnsDashboardFrameMixin:ShowTooltip(row, record)
    if (record and record.item and string.find(record.item, "%|H")) then
        Utils.ShowTooltip(row, record.item, record.quantity);
    end
end

function AnsDashboardFrameMixin:RenderRow(row, record)
    local dash = self;
    local nameText =  row.Name; --_G[row:GetName().."Name"];
    local whoText = row.Who; --_G[row:GetName().."Who"];
    local amountText = row.Amount; -- _G[row:GetName().."Amount"];
    local typeText = row.Type; --_G[row:GetName().."Type"];
    local stackText = row.Stack; --_G[row:GetName().."Stack"];

    row:SetScript("OnEnter", function() dash:ShowTooltip(row, record) end);
    row:SetScript("OnLeave", Utils.HideTooltip);

    nameText:SetText(record.item);
    whoText:SetText(record.from);

    local type = "";
    if (record.subtype) then
        type = record.subtype:upper();
    end

    typeText:SetText(type);
    stackText:SetText(record.quantity or "");
    amountText:SetText(Utils.PriceToString(record.copper));
end

function AnsDashboardFrameMixin:LoadRecentPurchases()
    local dash = self;
    self.recentPurchasesList = ListView:Acquire(self.RecentPurchases, 
        {rowHeight = 16, childIndent = 0, template = "AnsRecordRowMinTemplate"},
        nil, nil, nil,
        function(row, record)
            dash:RenderRow(row, record);
        end);
    self:LoadRecentData();
end

function AnsDashboardFrameMixin:LoadRecentSales()
    local dash = self;
    self.recentSalesList = ListView:Acquire(self.RecentSales,
        {rowHeight = 16, childIndent = 0, template = "AnsRecordRowMinTemplate"},
        nil, nil, nil,
        function(row, record)
            dash:RenderRow(row, record);
        end);
    self:LoadRecentData();
end

function AnsDashboardFrameMixin:LoadRecentData()
    if (not self:IsShown() or not self.characterGold) then
        return;
    end

    local t = 0;
    if (self.timeMode == TIME_MINUTES) then
        t = 60 * 60;
    elseif (self.timeMode == TIME_HOURS) then
        t = 60 * 60 * 11;
    elseif (self.timeMode == TIME_DAYS) then
        t = 60 * 60 * 24 * 11;
	elseif (self.timeMode == TIME_MONTHS) then
		t = 60 * 60 * 24 * 30 * 11;
    end

    local chrs = CHAR_CACHE;

    if (self.characterGold.selected > 1) then
        chrs = {CHAR_CACHE[self.characterGold.selected - 1]};
    end

    if (self.recentSalesList) then
        DataQuery:JoinTransactions(chrs, "sale", nil, time() - t, time(), SALES_CACHE, 100);
        self.recentSalesList.items = SALES_CACHE;
        self.recentSalesList:Refresh();
    end

    if (self.recentPurchasesList) then
        DataQuery:JoinTransactions(chrs, "buy", nil, time() - t, time(), PURCHASE_CACHE, 100);
        self.recentPurchasesList.items = PURCHASE_CACHE;
        self.recentPurchasesList:Refresh();
    end

    self:RefreshStats();
end

function AnsDashboardFrameMixin:LoadGraph()
    local gparent = self.GraphArea;
    self.graph = Graph:Acquire(nil, gparent);
    self.graph:SetFormatter(Utils.PriceToString);
    self.graph:Load(32, -5, "TOPLEFT", "TOPLEFT", gparent:GetWidth() - 40, gparent:GetHeight() - 40);
    self.graphMode = "player";
    self.timeMode = TIME_MINUTES;
    self:UpdateGraph();
end

function AnsDashboardFrameMixin:LoadTimeScaleDropdown(o, p, changeHandler)
    local dash = o or self;
    local gparent = p or self.GraphArea;

    dash.graphTimeScale = Dropdown:Acquire(nil, gparent);
    dash.graphTimeScale:SetPoint("BOTTOMRIGHT", "TOPRIGHT", 0, 8);
    dash.graphTimeScale:SetSize(125, 24);

    if (not o and not changeHandler) then
        self.timeScaleChanged = function()
            dash.timeMode = TIME_SCALE[dash.graphTimeScale.selected];
            dash:UpdateGraph();
            dash:LoadRecentData();
        end
    end

    dash.graphTimeScale:AddItem("Recent", changeHandler or self.timeScaleChanged);
    dash.graphTimeScale:AddItem("Hours Ago", changeHandler or self.timeScaleChanged);
    dash.graphTimeScale:AddItem("Days Ago",  changeHandler or self.timeScaleChanged);
    dash.graphTimeScale:AddItem("Months Ago",  changeHandler or self.timeScaleChanged);
end

function AnsDashboardFrameMixin:LoadCharacterGoldDropdown()
    local gparent = self.GraphArea;
    self.characterGold = Dropdown:Acquire(nil, gparent);
    self.characterGold:SetPoint("BOTTOMRIGHT", "TOPRIGHT", -130, 8);
    self.characterGold:SetSize(400, 24);

    self.characterGold:AddItem("All Characters", self.timeScaleChanged);
    
    for i, v in ipairs(CHAR_CACHE) do
        self.characterGold:AddItem(v, self.timeScaleChanged);
    end
end

function AnsDashboardFrameMixin:UpdateGraph()
    if (not self:IsShown() or not self.characterGold) then
        return;
    end

    local gtime = math.floor(time() / 60);
    local i;
    local timeTable = GOLD_MINUTES;

    if (self.timeMode == TIME_MINUTES) then
        timeTable = GOLD_MINUTES;
    elseif (self.timeMode == TIME_HOURS) then
        timeTable = GOLD_HOURS;
    elseif (self.timeMode == TIME_DAYS) then
        timeTable = GOLD_DAYS;
	elseif (self.timeMode == TIME_MONTHS) then
		timeTable = GOLD_MONTHS;
    end

    for i = 1, 12 do
        wipe(GOLD_QUERY_TABLE_CACHE[i]);

        if (self.characterGold.selected == 1) then
            DataQuery:JoinGoldAt(CHAR_CACHE, self.graphMode, gtime - timeTable[i], GOLD_QUERY_TABLE_CACHE[i]);
        else
            DataQuery:JoinGoldAt({CHAR_CACHE[self.characterGold.selected - 1]}, self.graphMode, gtime - timeTable[i], GOLD_QUERY_TABLE_CACHE[i]);
        end
    end

    -- update graph
    local gmax = 0;
    local lastGoodValue = 0;

    wipe(t2);
    wipe(t3);
    wipe(t1);

    for i = 1, 12 do
        local tbl = GOLD_QUERY_TABLE_CACHE[i];
        local p = tbl[1];

        if (p) then
            gmax = math.max(gmax, p);
            tinsert(t1, p);
            lastGoodValue = p;
        else
            tinsert(t1, lastGoodValue);
        end

        local t = timeTable[i];

        if (self.timeMode == TIME_MINUTES) then
            tinsert(t2, t.."m");
        elseif (self.timeMode == TIME_HOURS) then
            local tt = time() - (t * 60);
            local tstr =  string.gsub(date("%I%p", tt), "^[0]", "");
            local dstr = date("%a", tt);
            tinsert(t2, tstr.."\r\n"..dstr);
        elseif (self.timeMode == TIME_DAYS) then
            local tt = time() - (t * 60);
            local tstr =  string.gsub(date("%I%p", tt), "^[0]", "");
            local dstr = date("%a", tt);
            tinsert(t2, tstr.."\r\n"..dstr);
		elseif (self.timeMode == TIME_MONTHS) then
			local tt = time() - (t * 60);
            local tstr =  string.gsub(date("%I%p", tt), "^[0]", "");
            local dstr = date("%b", tt);
            tinsert(t2, tstr.."\r\n"..dstr);
        else
            tinsert(t2, "?");
        end
    end

    gmax = math.max(gmax + math.floor(gmax * (self.graph.SECTION_SIZE_PCT * 0.5)), 100);

    local perY = gmax / (#self.graph.yFonts - 1);
    local totalY = 0;

    local ftotal = #self.graph.yFonts;
    for i = 1, ftotal do
        if (i == 1) then
            tinsert(t3, 0);
        else
            -- round to gold only
            local gold = math.floor(totalY / 10000);
			if (gold > 10000000000) then
				tinsert(t3, string.format("%.0f", gold / 10000000000).."B");
			elseif (gold > 1000000000) then
				tinsert(t3, string.format("%.2f", gold / 1000000000).."B");
			elseif (gold > 10000000) then
				tinsert(t3, string.format("%.0f", gold / 10000000).."M");
            elseif (gold > 1000000) then
                tinsert(t3, string.format("%.2f", gold / 1000000).."M");
            elseif (gold > 10000) then
                tinsert(t3, string.format("%.0f", gold / 1000).."K");
            elseif (gold > 1000) then
                tinsert(t3, string.format("%.2f", gold / 1000).."K");
            else
                tinsert(t3, gold);
            end
        end
        totalY = totalY + perY;
    end

    self.graph:Update(t1, t2, t3, gmax);
end