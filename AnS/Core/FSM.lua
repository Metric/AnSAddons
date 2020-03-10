local Ans = select(2, ...);
local EventManager = Ans.EventManager;
local Logger = Ans.Logger;
local Utils = Ans.Utils;
local FSM = {};
local FSMState = {};
FSMState.__index = FSMState;
FSM.__index = FSM;

Ans.FSM = FSM;
Ans.FSMState = FSMState;

local function DefaultHandler(self, ...)
    return ...;
end

function FSMState:New(name)
    local a = {};
    setmetatable(a, FSMState);
    a:Init(name);
    return a;
end

function FSMState:Init(name)
    self.name = name;
    self.exitHandler = nil;
    self.enterHandler = nil;
    self.transitionValid = {};
    self.events = {};
    self.previous = nil;
    self.current = nil;
end

function FSMState:SetOnEnter(handler)
    self.enterHandler = handler;
    return self;
end

function FSMState:SetOnExit(handler)
    self.exitHandler = handler;
    return self;
end

function FSMState:AddEvent(event, handler)
    if (self.events[event]) then
        return self;
    end

    if (not handler) then
        handler = DefaultHandler;
    end

    self.events[event] = handler;
    self.transitionValid[event] = true;
    return self;
end

function FSMState:RemoveEvent(event)
    self.events[event] = nil;
    self.transitionValid[event] = false;
    return self;
end


function FSMState:IsTransitionValid(to)
    return self.transitionValid[to];
end

function FSMState:HasHandler(event)
    return self.events[event];
end

function FSMState:Enter(...)
    if (not self.enterHandler) then
        return nil;
    end

    return self.enterHandler(self, ...);
end

function FSMState:Exit(...)
    if (not self.exitHandler) then
        return nil;
    end

    return self.exitHandler(self, ...);
end

function FSMState:Process(event, ...)
    if (not self.events[event]) then
        return nil;
    end
    return self.events[event](self, event, ...);
end


function FSM:New(name)
    local a = {};
    setmetatable(a, FSM);
    a:Init(name);
    return a;
end

function FSM:Init(name)
    self.name = name;
    self.current = nil;
    self.states = {};
end

function FSM:Add(state)
    self.states[state.name] = state;
    return self;
end

function FSM:Start(initial)
    self.current = initial;
    self.previous = initial;

    for k,v in pairs(self.states) do
        for state, _ in pairs(v.transitionValid) do
            assert(self.states[state], format("state does not exist %s -> %s", k, state));
        end
    end

    return self;
end

function FSM:Interrupt()
    Logger.Log("FSM", self.name.." interrupted");

    if (self.current) then
        local current = self.states[self.current];
        if (current) then
            current:Exit();
        end
    end

    self.current = nil;
    
    self.handlingEvent = false;
    self.inTransition = false;
    return self;
end

function FSM:GetCurrent()
    if (not self.current) then
        return nil;
    end

    return self.states[self.current];
end

function FSM:Process(event, ...)
    if (not self.current) then
        return false;
    end

    if (self.handlingEvent) then
        return false;
    elseif (self.inTransition) then
        return false;
    end

    self.handlingEvent = true;
    local state = self.states[self.current];
    if (state:HasHandler(event)) then
        self:Transition(Utils:GetTable(state:Process(event, ...)));
    end
    self.handlingEvent = false;

    return true;
end

function FSM:Transition(results)
    while (results and self.current and results[1]) do
        local to  = tremove(results, 1);
        local current = self.states[self.current];
        local next = self.states[to];

        assert(to and next);

        if (current:IsTransitionValid(to)) then
            self.previous = self.current;
            self.inTransition = true;
            current:Exit(to, unpack(results));
            self.current = to;
            results = Utils:GetTable(next:Enter(Utils:UnpackAndReleaseTable(results)));
            self.inTransition = false;
        else
            results = nil;
        end
    end
end
