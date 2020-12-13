local Ans = select(2, ...);
local EventManager = Ans.EventManager;
local Dropdown = Ans.UI.Dropdown;
local ListView = Ans.UI.ListView;
local TextInput = Ans.UI.TextInput;
local Utils = Ans.Utils;
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

AnsLedgerFrameMixin = {};

function AnsLedgerFrameMixin:Init()
    local this = self;

    self.lastSortMode = "time";

    self.sortMode = {
        ["copper"] = false,
        ["from"] = false,
        ["quantity"] = false,
        ["type"] = false,
        ["item"] = false,
        ["time"] = true 
    };

    self.filter = "sales";

    self:SetScript("OnShow", function() this:OnShow(); end);
    EventManager:On("ANS_DATA_READY", function() this:Ready(); end);
end

function AnsLedgerFrameMixin:Ready()
    local this = self;
    EventManager:On("LOG_UPDATE", function() this:Refresh(); end);
    self.characters = { unpack(DataQuery:GetGoldCharacters()) };
    table.sort(self.characters, function(x,y) return x < y; end);
    self.totalText = self.List.Stats.Total;
    self.totalItemsText = self.List.Stats.TotalItems;
    self.List.Header.dataProvider = self;

    self:LoadCharacterDropDown();
    self:LoadFilters();
    self:LoadSubFilterDropdown();
    self:LoadSearchInput();
    self:LoadExpenseDropdown();
    self:Refresh();
end

function AnsLedgerFrameMixin:Sort(type, noFlip)
    self.lastSortMode = type;
    if (not noFlip) then
        if (self.sortMode[type]) then
            self.sortMode[type] = false;
        else
            self.sortMode[type] = true;
        end
    end
    self:Refresh(); 
end

function AnsLedgerFrameMixin:OnShow()
    self:Refresh();
end

function AnsLedgerFrameMixin:LoadFilters()
    local this = self;
    self.filtersList = ListView:Acquire(self.Filters,
        {rowHeight = 24, childIndent = 0, template="AnsTab2Template", multiselect = false, usePushTexture = true},
        function(item)
            this.filter = item.name:lower();
            this:Refresh();
        end, nil, nil, nil);
    self.filtersList.items = filters;
    self.filtersList:Refresh();
end

function AnsLedgerFrameMixin:LoadSubFilterDropdown()
    local this = self;
    self.subfilterSelect = Dropdown:Acquire(nil, self);
    self.subfilterSelect:SetPoint("TOPRIGHT", "TOPRIGHT", -10, 0);
    self.subfilterSelect:SetSize(125, 24);
    for i,v in ipairs(subfilters) do
        self.subfilterSelect:AddItem(v, function() this:Refresh(); end);
    end
end

function AnsLedgerFrameMixin:LoadCharacterDropDown()
    local this = self;
    self.characterSelect = Dropdown:Acquire(nil, self);
    self.characterSelect:SetPoint("TOPRIGHT", "TOPRIGHT", -145, 0);
    self.characterSelect:SetSize(300, 24);

    self.characterSelect:AddItem("All Characters", function() this:Refresh(); end);
    
    for i, v in ipairs(self.characters) do
        self.characterSelect:AddItem(v, function() this:Refresh(); end);
    end
end

function AnsLedgerFrameMixin:LoadExpenseDropdown()
    local this = self;
    self.expenseSelect = Dropdown:Acquire(nil, self);
    self.expenseSelect:SetPoint("TOPLEFT", "TOPLEFT", 10, 0);
    self.expenseSelect:SetSize(150, 24);

    for i,v in ipairs(expenseFilters) do
        self.expenseSelect:AddItem(v.name, function() this:Refresh(); end);
    end

    self.expenseSelect:Hide();
end

function AnsLedgerFrameMixin:LoadSearchInput()
    local this = self;
    self.searchFilter = nil;
    self.searchInput = TextInput:Acquire(self, nil);
    self.searchInput:SetPoint("TOPRIGHT", "TOPRIGHT", -455, 0);
    self.searchInput:SetSize(135, 24);
    self.searchInput.onTextChanged = function(txt) this.searchFilter = txt; this:Refresh(); end;  
    self.searchInput:SetLabel("Search");
end

function AnsLedgerFrameMixin:Refresh()
    if (not self.characterSelect) then
        return;
    end

    local index = self.characterSelect.selected;

    if (index == 1) then
        -- load all realm character data
        self:LoadData(self.characters);
    else
        -- specific character data
        self:LoadData({self.characters[index - 1]});
    end
end

function AnsLedgerFrameMixin:LoadData(names)
    if (not self:IsShown() or not self.subfilterSelect) then
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
        DataQuery:JoinSales(names, subtype, tempTbl, self.searchFilter, {key = self.lastSortMode, reversed = self.sortMode[self.lastSortMode]});
    elseif (self.filter == "purchases") then
        DataQuery:JoinPurchases(names, subtype, tempTbl, self.searchFilter, {key = self.lastSortMode, reversed = self.sortMode[self.lastSortMode]});
        neg = "-";
    elseif (self.filter == "expenses") then
        local expenseSelected = self.expenseSelect.selected;
        DataQuery:JoinExpenses(names, expenseFilters[expenseSelected].types, subtype, tempTbl, self.searchFilter, 
            {key = self.lastSortMode, reversed = self.sortMode[self.lastSortMode]});
        self.expenseSelect:Show();
        neg = "-";
    elseif (self.filter == "income") then
        DataQuery:JoinIncome(names, subtype, tempTbl, self.searchFilter, {key = self.lastSortMode, reversed = self.sortMode[self.lastSortMode]});
    elseif (self.filter == "cancelled") then
        DataQuery:JoinCancelled(names, tempTbl, self.searchFilter, {key = self.lastSortMode, reversed = self.sortMode[self.lastSortMode]});
    elseif (self.filter == "expired") then
        DataQuery:JoinExpired(names, tempTbl, self.searchFilter, {key = self.lastSortMode, reversed = self.sortMode[self.lastSortMode]});
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
    self.totalText:SetText("Total Amount: "..neg..Utils.PriceToString(total));
    self.List:SetItems(tempTbl);
end
