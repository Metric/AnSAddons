local Ans = select(2, ...);
local EventManager = Ans.EventManager;
local Dashboard = {};
Dashboard.__index = Dashboard;
Dashboard.selected = true;
Dashboard.loaded = false;

local Graph = Ans.UI.Graph;
local Dropdown = Ans.UI.Dropdown;
local Utils = Ans.Utils;
local ListView = Ans.UI.ListView;

Ans.DashboardView = Dashboard;

local DataQuery = Ans.Analytics.Query;

local TIME_DAYS = 0;
local TIME_HOURS = 1;
local TIME_MINUTES = 2;
local TIME_MONTHS = 3;
local TIME_SCALE = {TIME_MINUTES,TIME_HOURS,TIME_DAYS,TIME_MONTHS};
local GOLD_QUERY_TABLE_CACHE = {{},{},{},{},{},{},{},{},{},{},{},{}};
local GOLD_MINUTES = {60,55,50,45,35,30,25,20,15,10,5,0};
local GOLD_HOURS = {60 * 11, 60 * 10, 60 * 9, 60 * 8, 60 * 7, 60 * 6, 60 * 5, 60 * 4, 60 * 3, 60 * 2, 60, 0};
local GOLD_DAYS = {60 * 24 * 11, 60 * 24 * 10, 60 * 24 * 9, 60 * 24 * 8, 60 * 24 * 7, 60 * 24 * 6, 60 * 24 * 5, 60 * 24 * 4, 60 * 24 * 3, 60 * 24 * 2, 60 * 24, 0}; 
local GOLD_MONTHS = {};

for i,v in ipairs(GOLD_DAYS) do
	tinsert(GOLD_MONTHS, v * 30);
end

local characters = {};
local recentSalesTable = {};
local recentPurchasesTable = {};

local t1 = {};
local t2 = {};
local t3 = {};

function Dashboard:OnLoad(f)
    local this = self;
    self.loaded = true;
    local tab = _G[f:GetName().."TabView1"];
    self.tab = tab;
    
    EventManager:On("ANS_DATA_READY", function() this:Init(); end);
end

function Dashboard:Init()
    local this = self;
    local tab = self.tab;

    -- register for event updates to gold log
    -- get known characters
    EventManager:On("GOLDLOG_UPDATE", function() this:UpdateGraph() end);
    EventManager:On("LOG_UPDATE", function() this:LoadRecentData() end);
    characters = { unpack(DataQuery:GetGoldCharacters()) };
    table.sort(characters, function(x,y) return x < y; end);

    -- grab stat areas
    self.statsSales = tab.StatSales;
    self.statsExpenses = tab.StatExpenses;
    self.statsProfit = tab.StatProfit;

    -- load time scale dropdown
    self:LoadTimeScaleDropdown();
    self:LoadCharacterGoldDropdown();

    -- load and setup graph
    self:LoadGraph();

    -- setup recent sales list
    self.recentSales = tab.RecentSales;
    self.recentPurchases = tab.RecentPurchases;
    self:LoadRecentSales();
    self:LoadRecentPurchases();
end

function Dashboard:Show()
    if (self.tab) then
        self.tab:Show();
        self.selected = true;
        self:LoadRecentData();
        self:UpdateGraph();
    end
end

function Dashboard:Hide()
    if (self.tab) then
        self.selected = false;
        self.tab:Hide();
    end
end

function Dashboard.ShowTooltip(row, record)
    if (record and record.item and string.find(record.item, "%|H")) then
        Utils:ShowTooltip(row, record.item, record.quantity);
    end
end

function Dashboard.RenderRow(row, record)
    local nameText = _G[row:GetName().."Name"];
    local whoText = _G[row:GetName().."Who"];
    local amountText = _G[row:GetName().."Amount"];
    local typeText = _G[row:GetName().."Type"];
    local stackText = _G[row:GetName().."Stack"];

    row:SetScript("OnEnter", function() Dashboard.ShowTooltip(row, record) end);
    row:SetScript("OnLeave", Utils.HideTooltip);

    nameText:SetText(record.item);
    whoText:SetText(record.from);

    local type = "";
    if (record.subtype) then
        type = record.subtype:upper();
    end

    typeText:SetText(type);
    stackText:SetText(record.quantity or "");
    amountText:SetText(Utils:PriceToString(record.copper));
end

function Dashboard:RefreshStats()
    local saleTotalText = _G[self.statsSales:GetName().."Total"];
    local saleAverage = _G[self.statsSales:GetName().."Average"];

    local expenseTotalText = _G[self.statsExpenses:GetName().."Total"];
    local expenseAverage = _G[self.statsExpenses:GetName().."Average"];

    local profitTotalText = _G[self.statsProfit:GetName().."Total"];
    local profitAverage = _G[self.statsProfit:GetName().."Average"];

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

    local chrs = characters;

    if (self.characterGold.selected > 1) then
        chrs = {characters[self.characterGold.selected - 1]};
    end

    local p, pavg = DataQuery:JoinTotalProfit(chrs, time() - t);
    local s, savg = DataQuery:JoinTotalSales(chrs, time() - t);
    local e, eavg = DataQuery:JoinTotalExpenses(chrs, time() - t);

    saleTotalText:SetText(Utils:PriceToString(s));
    saleAverage:SetText(Utils:PriceToString(savg));

    expenseTotalText:SetText(Utils:PriceToString(e));
    expenseAverage:SetText(Utils:PriceToString(eavg));

    profitTotalText:SetText(Utils:PriceToString(p));
    profitAverage:SetText(Utils:PriceToString(pavg));
end

function Dashboard:LoadRecentPurchases()
    local dash = self;
    self.recentPurchasesList = ListView:New(self.recentPurchases, 
        {rowHeight = 16, childIndent = 0, template = "AnsRecordRowMinTemplate"},
        nil, nil, nil,
        Dashboard.RenderRow);
    self:LoadRecentData();
end

function Dashboard:LoadRecentSales()
    local dash = self;
    self.recentSalesList = ListView:New(self.recentSales,
        {rowHeight = 16, childIndent = 0, template = "AnsRecordRowMinTemplate"},
        nil, nil, nil,
        Dashboard.RenderRow);
    self:LoadRecentData();
end

function Dashboard:LoadRecentData()
    -- we ignore updates if we are not selected, loaded, or the main window is not shown
    if (not self.selected or not self.loaded and not AnsLedgerCore:IsShown()) then
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

    local chrs = characters;

    if (self.characterGold.selected > 1) then
        chrs = {characters[self.characterGold.selected - 1]};
    end

    if (self.recentSalesList) then
        DataQuery:JoinTransactions(chrs, "sale", nil, time() - t, time(), recentSalesTable, 100);
        self.recentSalesList.items = recentSalesTable;
        self.recentSalesList:Refresh();
    end

    if (self.recentPurchasesList) then
        DataQuery:JoinTransactions(chrs, "buy", nil, time() - t, time(), recentPurchasesTable, 100);
        self.recentPurchasesList.items = recentPurchasesTable;
        self.recentPurchasesList:Refresh();
    end

    self:RefreshStats();
end

function Dashboard.TimeScaleChanged()
    local selected = Dashboard.graphTimeScale.selected;
    Dashboard.timeMode = TIME_SCALE[selected];
    Dashboard:UpdateGraph();
    Dashboard:LoadRecentData();
end

function Dashboard:LoadGraph()
    local tab = self.tab;
    local gparent = tab.GraphArea;
    self.graph = Graph:New(gparent:GetName().."View", gparent);
    self.graph:SetFormatter(Dashboard.GraphFormatter);
    self.graph:Load(32,-5,"TOPLEFT","TOPLEFT", gparent:GetWidth() - 40, gparent:GetHeight() - 40);
    self.graphMode = "player";
    self.timeMode = TIME_MINUTES;
    self:UpdateGraph();
end

function Dashboard:LoadTimeScaleDropdown()
    local tab = self.tab;
    local gparent = tab.GraphArea;
    -- setup combobox
    self.graphTimeScale = Dropdown:New(gparent:GetName().."GoldTimeScale", gparent);
    self.graphTimeScale:SetPoint("BOTTOMRIGHT", "TOPRIGHT", 0, 8);
    self.graphTimeScale:SetSize(125, 24);

    self.graphTimeScale:AddItem("Recent", Dashboard.TimeScaleChanged);
    self.graphTimeScale:AddItem("Hours Ago", Dashboard.TimeScaleChanged);
    self.graphTimeScale:AddItem("Days Ago", Dashboard.TimeScaleChanged);
	self.graphTimeScale:AddItem("Months Ago", Dashboard.TimeScaleChanged);
end

function Dashboard:LoadCharacterGoldDropdown()
    local tab = self.tab;
    local gparent = tab.GraphArea;
    self.characterGold = Dropdown:New(gparent:GetName().."CharacterGold", gparent);
    self.characterGold:SetPoint("BOTTOMRIGHT", "TOPRIGHT", -130, 8);
    self.characterGold:SetSize(125, 24);

    self.characterGold:AddItem("All Realm Characters", Dashboard.TimeScaleChanged);
    
    for i, v in ipairs(characters) do
        self.characterGold:AddItem(v, Dashboard.TimeScaleChanged);
    end
end

function Dashboard.GraphFormatter(v)
    return Utils:PriceToString(v);
end

function Dashboard:UpdateGraph()
    if (not self.selected or not self.loaded) then
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
            DataQuery:JoinGoldAt(characters, self.graphMode, gtime - timeTable[i], GOLD_QUERY_TABLE_CACHE[i]);
        else
            DataQuery:JoinGoldAt({characters[self.characterGold.selected - 1]}, self.graphMode, gtime - timeTable[i], GOLD_QUERY_TABLE_CACHE[i]);
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
				tinsert(t3, math.floor(gold / 10000000000).."B");
			elseif (gold > 1000000000) then
				tinsert(t3, math.floor(gold / 1000000000).."B");
			elseif (gold > 10000000) then
				tinsert(t3, math.floor(gold / 10000000).."M");
            elseif (gold > 1000000) then
                tinsert(t3, math.floor(gold / 1000000).."M");
            elseif (gold > 10000) then
                tinsert(t3, math.floor(gold / 1000).."K");
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