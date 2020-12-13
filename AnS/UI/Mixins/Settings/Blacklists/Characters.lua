local Ans = select(2, ...);
local TextInput = Ans.UI.TextInput;
local ListView = Ans.UI.ListView;
local Config = Ans.Config;

local items = {};

AnsCharacterBlacklistFrameMixin = {};

function AnsCharacterBlacklistFrameMixin:Init()
    local this = self;
    self.Add:SetScript("OnClick", function() this:AddCharacter(); end);

    self.character = TextInput:NewFrom(self.Character);

    self.listView = ListView:Acquire(self, 
        {rowHeight = 20, childIndent = 0, template="AnsBlacklistRowTemplate", multiselect = false, usePushTexture = false},
        nil,
        function(item)
            this:Remove(item);
        end, nil, nil);
end

function AnsCharacterBlacklistFrameMixin:AddCharacter()
    if (type(Config.Sniper().characterBlacklist) == "string") then
        Config.Sniper().characterBlacklist = {};
    end

    local blacklist = Config.Sniper().characterBlacklist;

    local c = self.character:Get();

    if (c == "" or c == "\r\n" or c == "\t" or c:len() == 0) then
        self.character:Set("");
        return;
    end

    tinsert(blacklist, c:lower());
    tinsert(items, {name = c:lower()}); -- exact same index

    self.character:Set("");

    self.listView.items = items;
    self.listView:Refresh();
end

function AnsCharacterBlacklistFrameMixin:Remove(item)
    local blacklist = Config.Sniper().characterBlacklist;

    if (type(blacklist) == "string") then
        return;
    end

    for i,v in ipairs(blacklist) do
        if (v == item.name) then
            tremove(blacklist, i);
            tremove(items, i); -- should be the same index as above
            break;
        end
    end

    self.listView.items = items;
    self.listView:Refresh();
end

function AnsCharacterBlacklistFrameMixin:Refresh()
    if (type(Config.Sniper().characterBlacklist) == "string") then
        Config.Sniper().characterBlacklist = {};
    end

    local blacklist = Config.Sniper().characterBlacklist;

    wipe(items);

    for i,v in ipairs(blacklist) do
        tinsert(items, {name = v:lower()});
    end

    self.listView.items = items;
    self.listView:Refresh();
end