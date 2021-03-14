local Ans = select(2, ...);
local ListView = Ans.UI.ListView;
local TextInput = Ans.UI.TextInput;
local Config = Ans.Config;
local EventManager = Ans.EventManager;
local Utils = Ans.Utils;


local items = {};
local waitingForInfo = {};

AnsItemBlacklistFrameMixin = {};

function AnsItemBlacklistFrameMixin:ShowTip(row, record)
    if (record and record.link and string.find(record.link, "%|H")) then
        Utils.ShowTooltip(row, record.link, 1);
    end
end

function AnsItemBlacklistFrameMixin:Init()
    local this = self;

    self.listView = ListView:Acquire(self,
        {rowHeight = 20, childIndent = 0, template="AnsBlacklistRowTemplate", multiselect = false, usePushTexture = false},
        nil,
        function(item)
            this:Remove(item);
        end, nil,
        function(row, item)
            if (not item.link or type(item.link) == "number") then
                local link = Utils.GetLink(item.name);
                if (not link) then
                    local _,id = strsplit(":", item.name);
                    waitingForInfo[tonumber(id)] = true;
                end
                item.link = link;
            end
            if (row.Text) then
                row.Text:SetText(item.link or item.name);
            end
            row:SetScript("OnEnter", function() this:ShowTip(row, item); end);
            row:SetScript("OnLeave", Utils.HideTooltip);
        end
    );

    self.idInput = TextInput:NewFrom(self.Item); 

    self.Add:SetScript("OnClick", function() this:AddItem(); end);

    EventManager:On("GET_ITEM_INFO_RECEIVED", function(id)
        if (waitingForInfo[id]) then
            waitingForInfo[id] = nil;
            if (this:IsShown()) then
                this.listView:Refresh();
            end
        end
    end);
end

function AnsItemBlacklistFrameMixin:AddItem()
    local s = self.idInput:Get();
    if (s) then
        s = s:trim();
        if (s ~= "") then
            s = s:lower();
            local t,id = strsplit(":", s);
            if (t and id and (t == "i" or t == "p")) then
                Config.Sniper().itemBlacklist[s] = tonumber(id);
                self.idInput:Set(""); 
                self:Refresh();
            elseif (t) then
                local id = t;
                Config.Sniper().itemBlacklist["i"..id] = tonumber(id);
                self.idInput:Set("");
                self:Refresh();
            end
        end
    end
end


function AnsItemBlacklistFrameMixin:Remove(item)
    local blacklist = Config.Sniper().itemBlacklist;

    blacklist[item.name] = nil;

    for i,v in ipairs(items) do
        if (v.name == item.name) then
            tremove(items, i);
            break;
        end
    end

    self.listView.items = items;
    self.listView:Refresh();
end

function AnsItemBlacklistFrameMixin:Refresh()
    local blacklist = Config.Sniper().itemBlacklist;

    wipe(items);

    for k,v in pairs(blacklist) do
        tinsert(items, {name = k, link = v});
    end

    self.listView.items = items;
    self.listView:Refresh();
end