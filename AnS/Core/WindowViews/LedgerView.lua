local Ans = select(2, ...);
local EventManager = Ans.EventManager;
local Ledger = {};
Ledger.__index = Ledger;
Ledger.selected = false;
Ledger.loaded = false;
Ledger.index = 2;
Ledger.filter = "sales";

local Dropdown = Ans.UI.Dropdown;
local TextInput = Ans.UI.TextInput;
local ListView = Ans.UI.ListView;
local Utils = Ans.Utils;

Ans.LedgerView = Ledger;

local DataQuery = Ans.Analytics.Query;
local tempTbl = {};

local filters = { 
    {name = "Sales", selected = true}, 
    {name = "Purchases", selected = false}, 
    {name = "Expenses", selected = false}, 
    {name = "Income", selected = false},
    {name = "Expired", selected = false},
    {name = "Cancelled", selected = false}
};

local subfilters = {
    "All Subtypes",
    "Auction",
    "Trade",
    "Vendor"
};

local expenseFilters = {
    {name = "All Expenses", types = {"buy", "cod", "expense", "postage", "repair"}},
    {name = "Purchase", types = {"buy"}},
    {name = "COD", types = {"cod"}},
    {name = "Expense", types = {"expense"}},
    {name = "Postage", types = {"postage"}},
    {name = "Repair", types = {"repair"}}
};

function Ledger:OnLoad(f)
    self.loaded = true;
    local this = self;
    local tab = _G[f:GetName().."TabView"..self.index];
    self.tab = tab;

    EventManager:On("LOG_UPDATE", function() this:Refresh(); end);
    self.characters = { unpack(DataQuery:GetGoldCharacters()) };
    table.sort(self.characters, function(x,y) return x < y; end);

    self.listView = tab.List;
    self.totalText = _G[tab:GetName().."ListStatsTotal"];
    self.totalItemsText = _G[tab:GetName().."ListStatsTotalItems"];
    self.filtersView = tab.Filters;

    self:LoadCharacterDropdown();
    self:LoadListView();
    self:LoadFilters();
    self:LoadSubFilterDropdown();
    self:LoadSearchInput();
    self:LoadExpenseDropdown();
end

function Ledger:Show()
    if (self.tab) then
        self.tab:Show();
        self.selected = true;
        self:Refresh();
    end
end

function Ledger:Hide()
    if (self.tab) then
        self.selected = false;
        self.tab:Hide();
    end
end

function Ledger.SelectFilter(item)
    if (item) then
        Ledger.filter = item.name:lower();
        Ledger:Refresh();
    end
end

function Ledger:LoadFilters()
    self.filtersList = ListView:New(self.filtersView,
        {rowHeight = 24, childIndent = 0, template="AnsTab2Template", multiselect = false, usePushTexture = true},
        Ledger.SelectFilter, nil, nil, nil);
    self.filtersList.items = filters;
    self.filtersList:Refresh();
end

function Ledger:LoadSubFilterDropdown()
    local tab = self.tab;
    local this = self;
    self.subfilterSelect = Dropdown:New(tab:GetName().."Filters", tab);
    self.subfilterSelect:SetPoint("TOPRIGHT", "TOPRIGHT", -10, 0);
    self.subfilterSelect:SetSize(125, 24);
    for i,v in ipairs(subfilters) do
        self.subfilterSelect:AddItem(v, function() this:Refresh(); end);
    end
end

function Ledger:LoadSearchInput()
    local tab = self.tab;
    local this = self;
    self.searchFilter = nil;
    self.searchInput = TextInput:New(tab, tab:GetName().."SearchInput");
    self.searchInput:SetPoint("TOPRIGHT", "TOPRIGHT", -280, 0);
    self.searchInput:SetSize(125, 24);
    self.searchInput.onTextChanged = function(txt) this.searchFilter = txt; this:Refresh(); end;  
    self.searchInput:SetLabel("Search");
end

function Ledger:LoadCharacterDropdown()
    local tab = self.tab;
    local this = self;
    self.characterSelect = Dropdown:New(tab:GetName().."Characters", tab);
    self.characterSelect:SetPoint("TOPRIGHT", "TOPRIGHT", -145, 0);
    self.characterSelect:SetSize(125, 24);

    self.characterSelect:AddItem("All Realm Characters", function() this:Refresh(); end);
    
    for i, v in ipairs(self.characters) do
        self.characterSelect:AddItem(v, function() this:Refresh(); end);
    end
end

function Ledger:LoadExpenseDropdown()
    local tab = self.tab;
    local this = self;
    self.expenseSelect = Dropdown:New(tab:GetName().."Expenses", tab);
    self.expenseSelect:SetPoint("TOPRIGHT", "TOPRIGHT", -415, 0);
    self.expenseSelect:SetSize(125, 24);

    for i,v in ipairs(expenseFilters) do
        self.expenseSelect:AddItem(v.name, function() this:Refresh(); end);
    end

    self.expenseSelect:Hide();
end

function Ledger.ShowTooltip(row)
    local id = row:GetID();

    record = tempTbl[id];

    if (record and record.item and string.find(record.item, "%|H")) then
        Utils:ShowTooltip(row, record.item, record.quantity);
    end
end

function Ledger.RenderRow(row, record)
    local nameText = _G[row:GetName().."Name"];
    local whoText = _G[row:GetName().."Who"];
    local amountText = _G[row:GetName().."Amount"];
    local typeText = _G[row:GetName().."Type"];
    local stackText = _G[row:GetName().."Stack"];
    local dateText = _G[row:GetName().."Date"];

    row:SetScript("OnEnter", function() Ledger.ShowTooltip(row); end);
    row:SetScript("OnLeave", Utils.HideTooltip);

    nameText:SetText(record.item);
    whoText:SetText(record.from);

    local type = "";
    if (record.subtype) then
        type = record.subtype:upper();
    else
        type = record.type:upper();
    end

    typeText:SetText(type);
    stackText:SetText(record.quantity or "");
    amountText:SetText(Utils:PriceToString(record.copper));
    dateText:SetText(date("%D", record.time));
end

function Ledger:LoadListView()
    local this = self;
    self.list = ListView:New(self.listView, 
        {rowHeight = 16, childIndent = 0, template = "AnsRecordRowFullTemplate"},
        nil, nil, nil,
        Ledger.RenderRow);
end

function Ledger:Refresh()
    local index = self.characterSelect.selected;

    if (index == 1) then
        -- load all realm character data
        self:LoadData(self.characters);
    else
        -- specific character data
        self:LoadData({self.characters[index - 1]});
    end
end

function Ledger:LoadData(names)
    if (not self.selected or not self.loaded and not AnsLedgerCore:IsShown() or not names) then
        return;
    end

    local neg = "";

    local subtypeSelected = self.subfilterSelect.selected;
    local subtype = nil;
    if (subtypeSelected > 1) then
        subtype = subfilters[subtypeSelected]:lower();
    end

    self.expenseSelect:Hide();

    if (self.filter == "sales") then
        DataQuery:JoinSales(names, subtype, tempTbl, self.searchFilter);
    elseif (self.filter == "purchases") then
        DataQuery:JoinPurchases(names, subtype, tempTbl, self.searchFilter);
        neg = "-";
    elseif (self.filter == "expenses") then
        local expenseSelected = self.expenseSelect.selected;
        DataQuery:JoinExpenses(names, expenseFilters[expenseSelected].types, subtype, tempTbl, self.searchFilter);
        self.expenseSelect:Show();
        neg = "-";
    elseif (self.filter == "income") then
        DataQuery:JoinIncome(names, subtype, tempTbl, self.searchFilter);
    elseif (self.filter == "cancelled") then
        DataQuery:JoinCancelled(names, tempTbl, self.searchFilter);
    elseif (self.filter == "expired") then
        DataQuery:JoinExpired(names, tempTbl, self.searchFilter);
    end

    local total = 0;
    for i,v in ipairs(tempTbl) do
        if (v.quantity == 0) then
            total = total + v.copper;
        else
            total = total + (v.copper * v.quantity);
        end
    end

    self.totalItemsText:SetText("Total Items: "..tostring(#tempTbl));
    self.totalText:SetText("Total Amount: "..neg..Utils:PriceToString(total));
    self.list.items = tempTbl;
    self.list:Refresh();
end