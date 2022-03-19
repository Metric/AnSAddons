local Ans = select(2, ...);
local EventManager = Ans.EventManager;
local TempTable = Ans.TempTable;
local EventState = Ans.Object.Register("EventState");

function EventState:Acquire(fn, ...)
    local n = EventState:New();
    n.cb = fn;
    n.processing = true;
    n.complete = false;
    n.released = false;

    n.fn = function(name, ...) 
        local success = fn.event(fn, self, name, ...);
        if (success) then
            n.complete = true;
            n:Release();
        end
    end
    n.functions = TempTable:Acquire();
    n.events = TempTable:Acquire(...);
    n:Register();
    return n;
end

function EventState:Process()
    local cb = self.cb;
    local complete = not self.processing;

    if (not cb or complete) then
        return;
    end

    self.processing = cb.process(cb, self);
end

function EventState:Register()
    for i,v in ipairs(self.events) do
        local fn = function(...) 
            self.fn(v, ...);
        end
        self.functions[i] = fn;
        EventManager:On(v, fn);
    end
end

function EventState:GetVar(name)
    local cb = self.cb;
    if (not cb) then
        return nil;
    end
    return cb[name];
end

function EventState:SetVar(name, val)
    local cb = self.cb;
    if (not cb) then
        return;
    end
    cb[name] = val;
end

function EventState:Result()
    local cb = self.cb;
    if (not cb) then
        return nil;
    end

    return cb.result(cb, self);
end

function EventState:IsActive()
    return not self.complete or self.processing;
end

function EventState:Release()
    local released = self.released;
    if (released) then
        return;
    end

    for i,v in ipairs(self.events) do
        local fn = self.functions[i];
        EventManager:Off(v, fn);
    end
    self.events:Release();
    self.functions:Release();
    self.released = true;
end