local Ans = select(2, ...);
local BagScanner = Ans.BagScanner;
local Crafting = Ans.Data.Crafting;
local EventManager = Ans.EventManager;
local Utils = Ans.Utils;

local ListView = Ans.UI.ListView;
local selectedItem = nil;
local listItems = {};
local groups = {};
local ignored = {};
local currentSpellId = 0;
local autoPopped = false;
local lastSelected = 1;

AnsDestroyWindowFrameMixin = {};

function AnsDestroyWindowFrameMixin:Init()
    local this = self;

    self:SetScript("OnHide", function() this:OnHide(); end);
    self:SetScript("OnShow", function() this:OnShow(); end);
    self.Destroy:SetScript("PreClick", function() this:PrepareDestroy(); end);
    self.listView = ListView:Acquire(self,
        {rowHeight = 24, childIndent = 0, template="AnsDestroyRowTemplate", multiselect = false, usePushTexture = false},
        function(item, index)
            lastSelected = index or 1;
            this.selected = item;

            if (item) then
                this.SelectedPreview:Set(item.name);
            end

            this:RefreshButton();
        end,
        function(item)
            ignored[item.id] = true;
            groups[item.id] = nil;
            this:Refresh();
            if (#listItems == 0) then
                this:Hide();
            end
        end, nil, 
        function(row, item)
            row:SetScript("OnEnter", function(f) Utils.ShowTooltip(f, item.name, item.count); end);
            row:SetScript("OnLeave", Utils.HideTooltip);

            if (row.TextRight) then
                row.TextRight:SetText("x"..item.count);
            end
        end);
    self.listView.items = listItems;

    self.failureHandler = function(id, b, spell)
        if (id == "player" and spell == currentSpellId) then
            this:Failure();
        end
    end;
    self.lootHandler = function()
        this:Success();
    end
    self.started = function(id, b, spell)
        if (id == "player" and spell == currentSpellId) then
            EventManager:On("LOOT_CLOSED", this.lootHandler);
        end
    end
end

function AnsDestroyWindowFrameMixin:OnShow()
    if (#listItems == 0 and autoPopped) then
        self:Hide();
    end
end

function AnsDestroyWindowFrameMixin:Populate(auto)
    wipe(groups);

    autoPopped = auto;

    BagScanner.Release();
    BagScanner.Scan();

    BagScanner.GetDestroyable(groups, Crafting);

    self:Refresh();
    self.listView:SetSelected(lastSelected);
end

local function Sum(tbl)
    local s = 0;
    for i,v in ipairs(tbl) do
        s = s + v.count;
    end
    return s;
end

function AnsDestroyWindowFrameMixin:Refresh()
    wipe(listItems);

    for k,v in pairs(groups) do
        if (not ignored[k] or not autoPopped) then
            local count = Sum(v);
            if (Crafting.IsProspectable(v[1].tsmId) or Crafting.IsMillable(v[1].tsmId)) then
                count = math.floor(count / 5);
            end
            tinsert(listItems, {id = k, name = v[1].link, count = count, data = v, selected = self.selected and self.selected.id == k}) 
        end
    end

    self.listView:Refresh();
    
    self:RefreshButton();
end

function AnsDestroyWindowFrameMixin:RefreshButton()
    if (#listItems == 0 or self.destroy or not self.selected) then
        self.Destroy:Disable();
        if (self.destroy) then
            self.Destroy:SetText("Destroying...");
        else
            self.Destroy:SetText("Nothing to Destroy");
        end
    elseif (#listItems > 0 and not self.destroy) then
        self.Destroy:Enable();
        self.Destroy:SetText("Destroy");
    end
end

function AnsDestroyWindowFrameMixin:PrepareDestroy()
    if (not self:IsShown()) then
        return;
    end

    if (self.destroy) then
        return;
    end

    if (not self.selected or #self.selected.data == 0) then
        return;
    end

    self.destroy = self.selected.data[1];
    local spellId = Crafting.GetDestroySpell(self.destroy.tsmId);

    if (not spellId) then
        self:Success();
        return;
    end

    currentSpellId = spellId;

    local spellName = GetSpellInfo(spellId);

    if (not spellName) then
        self:Success();
        return;
    end

    if (not self.destroy:Exists() or self.destroy:IsLocked()) then
        self:Success();
        return;
    end

    self:Listen();
    self.Destroy:SetAttribute("macrotext", format("/cast %s;\n/use %d %d", spellName, self.destroy.bag, self.destroy.slot));
    self:RefreshButton();
end

function AnsDestroyWindowFrameMixin:Failure()
    ClearCursor();
    self.destroy = nil;
    self.Destroy:SetAttribute("macrotext", "");
    self:Refresh();
    self:Stop();
end

function AnsDestroyWindowFrameMixin:Success()
    local removed = false;
    if (self.selected) then
        if (#self.selected.data > 0) then
            if (Crafting.IsProspectable(self.destroy.tsmId) or Crafting.IsMillable(self.destroy.tsmId)) then
                self.selected.data[1].count = self.selected.data[1].count - 5;
                if (self.selected.data[1].count < 5) then
                    tremove(self.selected.data, 1);
                end
            else
                tremove(self.selected.data, 1);
            end
        end
        if (#self.selected.data == 0) then
            groups[self.selected.id] = nil;
            self.selected = nil;
            removed = true;
        end
    end
    self.destroy = nil;
    self.Destroy:SetAttribute("macrotext", "");
    self:Refresh();
    if (removed) then
        self.listView:SetSelected(self.listView.selected);
    end
    self:Stop();
    if (#listItems == 0) then
        self:Hide();
    end
end

function AnsDestroyWindowFrameMixin:ClearIgnored()
    wipe(ignored);
end

function AnsDestroyWindowFrameMixin:OnHide()
    self:Failure();
    
    self.SelectedPreview:Set(nil);

    for k,v in pairs(groups) do
        ignored[k] = true;
    end
end

function AnsDestroyWindowFrameMixin:Listen()
    EventManager:On("UNIT_SPELLCAST_START", self.started);
    EventManager:On("UNIT_SPELLCAST_FAILED", self.failureHandler);
    EventManager:On("UNIT_SPELLCAST_FAILED_QUIET", self.failureHandler);
    EventManager:On("UNIT_SPELLCAST_INTERRUPTED", self.failureHandler);
end

function AnsDestroyWindowFrameMixin:Stop()
    EventManager:Off("UNIT_SPELLCAST_START", self.started);
    EventManager:Off("UNIT_SPELLCAST_FAILED", self.failureHandler);
    EventManager:Off("UNIT_SPELLCAST_FAILED_QUIET", self.failureHandler);
    EventManager:Off("UNIT_SPELLCAST_INTERRUPTED", self.failureHandler);
    EventManager:Off("LOOT_CLOSED", self.lootHandler);
end