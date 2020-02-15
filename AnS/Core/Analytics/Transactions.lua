local Ans = select(2, ...);
local Transactions = { log = {}, name = nil };
Transactions.__index = Transactions;
Ans.Analytics.Transactions = Transactions;

local EventManager = Ans.EventManager;
local Data = Ans.Analytics.Data;
local TRANSACTION_TAG = "TRANSACTIONS_";

Transactions.MAX_COPPER = 9999999999;
Transactions.SECONDS_PER_DAY = 60 * 60 * 24;

local MAX_TIME_LIMIT = 60 * 60 * 24 * 11;
local MAX_DATA_LIMIT = 10000;

function Transactions:GetLog(name)
    if (self.name and not name) then
        return self.log[self.name];
    else
        return self.log[name];
    end
end

function Transactions:GetNames(tbl)
    wipe(tbl);

    for k,v in pairs(self.log) do
        tinsert(tbl, k);
    end
end

function Transactions:OnLoad()
    TRANSACTION_TAG = TRANSACTION_TAG..GetRealmName();
    self.log = Data:Get(TRANSACTION_TAG) or {};
    self.name = UnitName("player").." - "..UnitFactionGroup("player");
    if (not self.log[self.name]) then self.log[self.name] = {}; end;
    self:Compact();
end

function Transactions:InsertRepair(copper, time)
    local record = {type = "repair", subtype = nil, copper = copper, item = nil, quantity = 0, from = "MERCHANT", time = time};
    if (self:IsDupe(record)) then
        return;
    end
    self:Insert(record);
end

function Transactions:InsertSale(type, quantity, copper, item, from, time)
    local record = {type = "sale", quantity = quantity, subtype = type, copper = copper, item = item, from = from, time = time};
    if (self:IsDupe(record)) then
        return;
    end
    self:Insert(record);
end

function Transactions:InsertBuy(type, quantity, copper, item, from, time)
    local record = {type = "buy", quantity = quantity, subtype = type, copper = copper, item = item, from = from, time = time};
    if (self:IsDupe(record)) then
        return;
    end
    self:Insert(record);
end

function Transactions:InsertCOD(quantity, copper, item, from, time)
    local record = {type = "cod", subtype = nil, quantity = quantity, copper = copper, item = item, from = from, time = time};
    if (self:IsDupe(record)) then
        return;
    end
    self:Insert();
end

function Transactions:InsertIncome(copper, from, time)
    local record = {type = "income", subtype = nil, quantity = 0, copper = copper, item = nil, from = sender, time = time};
    if (self:IsDupe(record)) then
        return;
    end
    self:Insert(record);
end

function Transactions:InsertExpense(copper, from, time)
    local record = {type = "expense", subtype = nil, copper = copper, from = from, item = nil, quantity = 0, time = time};
    if (self:IsDupe(record)) then
        return;
    end
    self:Insert(record);
end

function Transactions:InsertExpire(quantity, item, time)
    local record = {type = "expire", subtype = nil, copper = 0, quantity = quantity, item = item, from = "AH", time = time};
    if (self:IsDupe(record)) then
        return;
    end
    self:Insert(record);
end

function Transactions:InsertCancel(quantity, item, time)
    local record = {type = "cancel", subtype = nil, copper = 0, item = item, quantity = quantity, from = "AH", time = time};
    if (self:IsDupe(record)) then
        return;
    end
    self:Insert(record);
end

function Transactions:InsertPostage(copper, from, time)
    local record = {type = "postage", subtype = nil, copper = copper, from = from, item = nil, quantity = 0, time = time};
    if (self:IsDupe(record)) then
        return;
    end
    self:Insert(record);
end

function Transactions:IsDupe(record)
    local log = self.log[self.name];

    if (#log == 0) then
        return false;
    end

    -- we only check back the previous item
    -- as that is where it can possibly be duplicated
    local r = log[#log];

    if (r) then
        if (r.item == record.item and r.time == record.time
            and r.quantity == record.quantity and r.copper == record.copper
            and r.from == record.from and r.type == record.type
            and r.subtype == record.subtype) then
                
            return true;
        end
    end

    return false;
end

function Transactions:Insert(record)
    local log = self.log[self.name];
    tinsert(log, record);

    if (#log > MAX_DATA_LIMIT) then
        tremove(log, 1);
    end

    Data:Set(TRANSACTION_TAG, self.log);
    EventManager:Emit("LOG_UPDATE");
end

function Transactions:Compact()
    local lt = time() - MAX_TIME_LIMIT;
    local log = self.log[self.name];
    local i;

    for i = 1, #log do
        local record = log[i];
        if (not record or record.time < lt) then
            tremove(log, i);
            i = i - 1;
        end
    end

    Data:Set(TRANSACTION_TAG, self.log);
end

EventManager:On("ANS_DATA_READY", 
    function()
        Transactions:OnLoad();
    end
);