local Ans = select(2, ...);
local Utils = Ans.Utils;
local ListView = Ans.UI.ListView;
local Crafting = Ans.Data.Crafting;
local EventManager = Ans.EventManager;

AnsDestroyPreviewFrameMixin = {};

local REF_CACHE = {};
local resultItems = {};
local waitingForInfo = {};

function AnsDestroyPreviewFrameMixin:ShowTip(f, link)
    if (not link) then
        return;
    end

    Utils.ShowTooltip(f, link, 1);
end

function AnsDestroyPreviewFrameMixin:Init()
    local this = self;

    self:SetScript("OnEnter", function() this:ShowTip(this, this.selected); end);
    self:SetScript("OnLeave", Utils.HideTooltip);

    self.listView = ListView:Acquire(self, 
        {rowHeight = 16, childIndent = 0, template = "AnsDestroyPreviewRowTemplate", multiselect = false, usePushTexture = true},
        nil, nil, nil,
        function(row, item)
            row:SetScript("OnEnter", function() this:ShowTip(row, item.link); end);
            row:SetScript("OnLeave", Utils.HideTooltip);

            if (not item.link) then
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

            if (row.TextRight) then
                row.TextRight:SetText("x"..string.format("%0.2f", item.amount));
            end
        end
    );
    
    EventManager:On("GET_ITEM_INFO_RECEIVED", function(id)
        if (waitingForInfo[id]) then
            waitingForInfo[id] = nil;
            if (this:IsShown()) then
                this.listView:Refresh();
            end
        end
    end)
end

function AnsDestroyPreviewFrameMixin:Set(link)
    wipe(resultItems);

    self.selected = nil;

    if (not link) then
        return;
    end

    self.selected = link;
    self.value = Crafting.DisenchantValue(link, 1, REF_CACHE);

    for k,v in pairs(REF_CACHE) do
        tinsert(resultItems, {name = k, amount = v, link = nil});
    end

    self.listView.items = resultItems;
    self.listView:Refresh();

    self.Text:SetText(link);

    local tex = select(10, GetItemInfo(link));
    if (tex) then
        self.Icon:SetTexture(tex);
    end
end