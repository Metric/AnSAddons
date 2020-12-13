local Ans = select(2, ...);

local ListView = Ans.UI.ListView;
local listItems = {
    { name = "General", view = "GeneralEdit", selected = true},
    { name = "Crafting", view = "CraftingEdit", selected = false},
    { name = "Sniper", view = "SniperEdit", selected = false},
    { name = "Custom Sources", view = "CustomSourcesEdit", selected = false},
    { name = "Macro", view = "MacroEdit", selected = false},
    { name = "Blacklists", view = "BlacklistsEdit", selected = false},
};

local selectedItem = listItems[1];

AnsSettingsFrameMixin = {};

function AnsSettingsFrameMixin:Init()
    local this = self;

    self.listView = ListView:Acquire(self.Items,
        {rowHeight = 24, childIndent = 0, template="AnsTab2Template", multiselect = false, usePushTexture = false},
        function(item, index)
            if (selectedItem) then
                selectedItem.selected = false;
                this[selectedItem.view]:Hide();
            end

            this[item.view]:Show();
            selectedItem = item;
            selectedItem.selected = true;
            this.listView:Refresh();
        end, nil, nil, nil
    );

    self.listView.items = listItems;
    self.listView:SetSelected(1);
end