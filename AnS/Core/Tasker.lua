local Ans = select(2, ...);
local EventManager = Ans.EventManager;
local Utils = Ans.Utils;
local Tasker = {};
Tasker.__index  = Tasker;

Ans.Tasker = Tasker;

local scheduled = {};

function Tasker.Schedule(fn, tag)
    Tasker.Delay(GetTime(), fn, tag);
end

function Tasker.Delay(delay, fn, tag)
    if (not tag) then
        tag = "general";
    end

    local t = Utils:GetTable();
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
            Utils:ReleaseTable(v);
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
                    tremove(v);
                    local fn = next.fn;
                    Utils:ReleaseTable(next);
                    fn();
                end
            elseif (not next.delay and next.fn) then
                tremove(v);
                local fn = next.fn;
                Utils:ReleaseTable(next);
                fn();
            else
                tremove(v);
            end
        end
    end
end

EventManager:On("UPDATE", Tasker.Update);