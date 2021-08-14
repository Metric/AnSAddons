local Ans = select(2, ...);
local ListView = Ans.UI.ListView;
local Utils = Ans.Utils;

AnsLedgerListFrameMixin = {};

function AnsLedgerListFrameMixin:ShowTooltip(row, record)
    if (record and record.item and string.find(record.item, "%|H")) then
        Utils.ShowTooltip(row, record.item, record.quantity);
    end
end

local EXPENSE_TYPES = {"buy", "cod", "expense", "postage", "repair"};
function AnsLedgerListFrameMixin:RenderRow(row, record)
    local dash = self;
    local nameText = row.Name; --_G[row:GetName().."Name"];
    local whoText = row.Who; -- _G[row:GetName().."Who"];
    local amountText = row.Amount; --_G[row:GetName().."Amount"];
    local typeText = row.Type; --_G[row:GetName().."Type"];
    local stackText = row.Stack; --_G[row:GetName().."Stack"];
    local dateText = row.Date; --_G[row:GetName().."Date"];

    row:SetScript("OnEnter", function() dash:ShowTooltip(row, record); end);
    row:SetScript("OnLeave", Utils.HideTooltip);

    nameText:SetText(record.item);
    whoText:SetText(record.from);

    local neg = "";
    local type = "";
    if (record.subtype) then
        type = record.subtype:upper();
    else
        type = record.type:upper();
    end

    if (tContains(EXPENSE_TYPES, record.type)) then
        neg = "-";
    end

    typeText:SetText(type);
    stackText:SetText(record.quantity or record.count or "");
    amountText:SetText(neg..Utils.PriceToString(record.copper));
    dateText:SetText(date("%D", record.time));
end

function AnsLedgerListFrameMixin:Init()
    local dash = self;
    self.list = ListView:Acquire(self,
        {rowHeight = 16, childIndent = 0, template = "AnsRecordRowFullTemplate"},
        nil, nil, nil,
        function(row, record)
            dash:RenderRow(row, record);
        end
    );
end

function AnsLedgerListFrameMixin:SetItems(items)
    self.list.items = items;
    self.list:Refresh();
end

function AnsLedgerListFrameMixin:Refresh()
    self.list:Refresh();
end