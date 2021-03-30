local Ans = select(2, ...);
local EventManager = Ans.EventManager;
local Utils = Ans.Utils;
local TempTable = Ans.TempTable;
local Tasker = Ans.Object.Register("Tasker");

local scheduled = {};

function Tasker.Schedule(fn, tag)
    Tasker.Delay(GetTime(), fn, tag);
end

function Tasker.Delay(delay, fn, tag)
    if (not tag) then
        tag = "general";
    end

    local t = TempTable:Acquire();
    t.delay = delay;
    t.fn = fn;

    local tagTable = scheduled[tag];

    if (not tagTable) then
        tagTable = {};
    end

    tinsert(tagTable, t);
    scheduled[tag] = tagTable;
end

function Tasker.Clear(tag)
    if (not tag) then
        tag = "general";
    end

    if (scheduled[tag]) then
        local t = scheduled[tag];
        for i,v in ipairs(t) do
            v:Release();
        end
        wipe(scheduled[tag]);
    end
end

function Tasker.Update()
    for k,v in pairs(scheduled) do
        if (#v > 0) then
            local next = v[1];

            if (next.delay and next.fn) then
                if (GetTime() - next.delay >= 0) then
                    tremove(v, 1);
                    local fn = next.fn;
                    next:Release();
                    fn();
                end
            elseif (not next.delay and next.fn) then
                tremove(v, 1);
                local fn = next.fn;
                next:Release();
                fn();
            elseif (next) then
                next:Release();
                tremove(v, 1);
            else
                tremove(v, 1);
            end
        end
    end
end

EventManager:On("UPDATE", Tasker.Update);