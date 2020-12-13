local Ans = select(2, ...);
local EventManager = Ans.Object.Register("EventManager");
EventManager.listeners = {};

function EventManager:Emit(event, ...)
    local listeners = self.listeners[event];

    if (listeners) then
        for _, v in ipairs(listeners) do
            v(...);
        end
    end
end

function EventManager:On(event, fn)
    local listeners = self.listeners[event] or {};
    
    if (type(fn) == 'function') then
        tinsert(listeners, fn);
    end

    self.listeners[event] = listeners;
end

function EventManager:Off(event, fn)
    local listeners = self.listeners[event];

    if (listeners) then
        for i, v in ipairs(listeners) do
            if (v == fn) then
                tremove(listeners, i);
                break;
            end
        end
    end
end
