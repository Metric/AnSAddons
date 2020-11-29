local Ans = select(2, ...);
local Config = Ans.Config;
local Utils = Ans.Utils;
local BagScanner = Ans.BagScanner;
local EventManager = Ans.EventManager;
local FSM = Ans.FSM;
local FSMState = Ans.FSMState;
local Tasker = Ans.Tasker;
local TASKER_TAG = "MAIL_SEND";

local MailOp = Ans.Operations.Mailing;

local TreeView = Ans.UI.TreeView;

local SendView = {};
SendView.__index = SendView;
SendView.inited = false;

local SendFSM = nil;

Ans.Mailing = {};
Ans.Mailing.SendView = SendView;

local activeOps = {};
local ops = {};
local sendable = {};
local treeViewItems = {};
local moreToSend = false;
local SendFSM = nil;

local function BuildStateMachine()
    local fsm = FSM:New("MailingFSM");
    local none = FSMState:New("NONE");
    none:AddEvent("IDLE");
    fsm:Add(none);

    local idle = FSMState:New("IDLE");
    idle:SetOnEnter(function(self)
        Tasker.Clear(TASKER_TAG);
        SendView.sendBtn:SetText("Send Scan");
        SendView.sendBtn:Enable();

        wipe(ops);
        wipe(sendable);

        return nil;
    end);

    idle:AddEvent("SEND_SCAN");
    fsm:Add(idle);

    local sendScan = FSMState:New("SEND_SCAN");
    sendScan:SetOnEnter(function(self)
        wipe(ops);
        wipe(sendable);

        SendView.sendBtn:SetText("Scanning");
        SendView.sendBtn:Disable();

        BagScanner:Release();
        BagScanner:Scan();
        BagScanner:GetSendable(sendable);

        for k,v in pairs(activeOps) do
            local op = MailOp:FromConfig(v);
            local available = op:GetAvailableItems(sendable);
            op:Prepare(available);
            if (op.totalToSend > 0) then
                tinsert(ops, op);
            end
        end

        if (#ops > 0) then
            return "READY";
        else
            return "IDLE";
        end
    end);

    sendScan:AddEvent("IDLE");
    sendScan:AddEvent("READY");

    fsm:Add(sendScan);

    local ready = FSMState:New("READY");
    ready:SetOnEnter(function(self)
        if (not ops or #ops == 0) then
            return "IDLE";
        end
        SendView.sendBtn:SetText("Sending Mail");
        return "SEND";
    end);

    ready:AddEvent("IDLE");
    ready:AddEvent("SEND");

    fsm:Add(ready);

    local send = FSMState:New("SEND");
    send:SetOnEnter(function(self)
        if (not ops or #ops == 0) then
            return "IDLE";
        end

        local nextOp = ops[1];
        local state = nextOp:Next();
        if (state == 0) then
            tremove(ops, 1);

            if (#ops == 0) then
                fsm:Process("IDLE");
            else
                fsm:Process("READY");
            end
        end
        return "PROCESS";
    end);

    send:AddEvent("IDLE");
    send:AddEvent("READY");
    send:AddEvent("PROCESS");

    fsm:Add(send);

    local process = FSMState:New("PROCESS");
    process:AddEvent("WAIT");
    process:AddEvent("IDLE");
    process:AddEvent("READY");

    process:AddEvent("UPDATE", function(self, event)
        if (not ops or #ops == 0) then
            return "IDLE";
        end
        local op = ops[1];
        if (op:Process()) then
            if (op:ReadyToSend()) then
                Tasker.Schedule(function()
                    op:SendMail();
                end, TASKER_TAG);
                return "WAIT";
            end
            return nil;
        else
            if (op:PendingAttachments()) then
                Tasker.Schedule(function()
                    op:SendMail();
                end, TASKER_TAG);
                return "WAIT";
            else
                return "READY";
            end
        end
    end);

    fsm:Add(process);

    local wait = FSMState:New("WAIT");
    wait:SetOnEnter(function(self)
        SendView.sendBtn:SetText("Validating");
        return nil;
    end);

    wait:AddEvent("IDLE");
    wait:AddEvent("READY");

    fsm:Add(wait);

    fsm:Add(FSMState:New("UPDATE"));

    fsm:Start("NONE");
    fsm:Process("IDLE");
    return fsm;
end

function SendView:OnLoad(f)
    local this = self;

    if (self.inited) then
        return;
    end

    self.inited = true;
    self.parent = f;

    Tasker.Schedule(
        function()
            this:Init(f);
        end, TASKER_TAG);
end

function SendView:Init(f)
    local this = self;
    local filterTemplate = "AnsFilterRowTemplate";
    local frameTemplate = "AnsMailingTemplate"

    if (Utils:IsClassic()) then
        frameTemplate = "AnsMailingClassicTemplate";
        filterTemplate = "AnsFilterRowClassicTemplate";
    end

    self.frame = CreateFrame("Frame", "AnsMailSendHook", f, frameTemplate);

    self.sendBtn = self.frame.SendBtn;
    self.reset = self.frame.Reset;
    self.all = self.frame.All;

    self.filterTree = TreeView:New(self.frame, {
        rowHeight = 21,
        childIndent = 16,
        template = filterTemplate, multiselect = true
    }, function(item) 
        if (item.op and not item.group) then
            this:Toggle(item.op)
        elseif (item.op and item.group) then
            this:ToggleGroup(item.op, item.group); 
        end
    end);

    self.all:SetScript("OnClick", self.SelectAll);
    self.reset:SetScript("OnClick", self.Reset);
    self.sendBtn:SetScript("OnClick", function() this:Send() end);

    self.frame:SetScript("OnShow", function() this:OnShow() end);
    self.frame:SetScript("OnHide", function() this:OnHide() end);
    self:OnShow();
end

function SendView:Hide()
    if (self.frame) then
        self.frame:Hide();
    end
end

function SendView:Toggle(op) 
    if (activeOps[op.id]) then
        activeOps[op.id] = nil;
    else
        activeOps[op.id] = op;
    end

    self:RefreshTreeView();
end

function SendView.Reset()
    wipe(activeOps);
    SendView:RefreshTreeView();
end

function SendView.SelectAll()
    local ops = Config.Operations().Mailing;
    for i,v in ipairs(ops) do
        activeOps[v.id] = v;
    end
    SendView:RefreshTreeView();
end

function SendView:ToggleGroup(f, g)
    if (f.nonActiveGroups[g]) then
        f.nonActiveGroups[g] = nil;
    else
        f.nonActiveGroups[g] = true;
    end
end

function SendView:RefreshTreeView()
    local ops = Config.Operations().Mailing;

    wipe(treeViewItems);
    for i,v in ipairs(ops) do
        v.nonActiveGroups = v.nonActiveGroups or {};
        local t = {
            name = v.name,
            op = v,
            selected = activeOps[v.id] ~= nil,
            children = {},
            expanded = false
        };

        for i,v2 in ipairs(v.groups) do
            local g = Utils:GetGroupFromId(v2);
            if (g) then
                tinsert(t.children, {
                    name = g.path,
                    selected = (not v.nonActiveGroups[v2]),
                    expanded = false,
                    children = {},
                    group = v2,
                    op = v
                });
            end
        end

        tinsert(treeViewItems, t);
    end

    self.filterTree.items = treeViewItems;
    self.filterTree:Refresh();
end

function SendView.Process()
    if (SendFSM and SendFSM.current == "PROCESS") then
        SendFSM:Process("UPDATE");
    end
end

function SendView.Next()
    if (SendFSM and SendFSM.current == "WAIT") then
        Tasker.Schedule(function()
            SendFSM:Process("READY");
        end, TASKER_TAG);
    end
end

function SendView.Failed()
    if (SendFSM and SendFSM.current == "WAIT") then
        print("AnS - Send Mail Aborting: Failed to Send");
        SendFSM:Process("IDLE");
    end
end

function SendView:Send()
    if (not self.frame or not self.frame:IsShown()) then
        return;
    end

    if (SendFSM) then
        if (SendFSM.current == "IDLE") then
            SendFSM:Process("SEND_SCAN");
        end
    end
end

function SendView:Stop()
    self.sendBtn:SetText("Send Scan");
    self.sendBtn:Enable();
    wipe(ops);
    wipe(sendable);
end

function SendView:RegisterEvents()
    EventManager:On("MAIL_SUCCESS", SendView.Next);
    EventManager:On("MAIL_FAILED", SendView.Failed);
    EventManager:On("UPDATE", SendView.Process);
end

function SendView:UnregisterEvents()
    EventManager:RemoveListener("MAIL_SUCCESS", SendView.Next);
    EventManager:RemoveListener("MAIL_FAILED", SendView.Failed);
    EventManager:RemoveListener("UPDATE", SendView.Process);
end

function SendView:OnHide()
    if (SendFSM) then
        SendFSM:Interrupt();
    end

    Tasker.Clear(TASKER_TAG);

    self:Stop();
    self:UnregisterEvents();
end

function SendView:OnShow()
    SendFSM = BuildStateMachine();
    self:RefreshTreeView();
    self:RegisterEvents();
end