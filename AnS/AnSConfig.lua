AnsConfig = {};
AnsConfig.__index = AnsConfig;

local selectedFilter = nil;
local rootFilter = {
    name = "Base",
    expanded = true,
    selected = false,
    children = {}
};
local filterTreeItems = { rootFilter };
local Filter = AnsCore.API.Filter;

StaticPopupDialogs["ANS_DELETE_FILTER_CONFIRM"] = {
    text = "Deleting this filter, will also delete all child filters as well.",
    button1 = "DELETE",
    button2 = "CANCEL",
    OnAccept = function() AnsConfig:DeleteFilter() end,
    timeout = 0,
    whileDead = false,
    hideOnEscape = true,
    preferredIndex = 3
};

StaticPopupDialogs["ANS_RESET_REALM_AUCTION_DATA_CONFIRM"] = {
    text = "This will remove all auction data for this realm",
    button1 = "DELETE",
    button2 = "CANCEL",
    OnAccept = function() AnsConfig:ResetAuctionData() end,
    timeout = 0,
    whileDead = false,
    hideOnEscape = true,
    preferredIndex = 3
};

local function AnsCustomVarUpdateRow(dataOffset, line)
    local row = _G["AnsCustomVarRow"..line];
    local nameBox = _G[row:GetName().."Name"];
    local valueBox = _G[row:GetName().."Value"];

    if (dataOffset <= #ANS_CUSTOM_VARS) then
        local f = ANS_CUSTOM_VARS[dataOffset];
        row:SetID(dataOffset);

        nameBox:SetText(f.name);
        valueBox:SetText(f.value);

        row:Show();
    else
        row:Hide();
    end
end

function AnsCustomVarsRefresh()
    local line;
    local fTotal = #ANS_CUSTOM_VARS;

    local dataOffset = 0;
    local offset = FauxScrollFrame_GetOffset(AnsCustomVarsScrollFrame);

    for line = 1, 13 do
        dataOffset = offset + line;
        AnsCustomVarUpdateRow(dataOffset, line);
    end

    FauxScrollFrame_Update(AnsCustomVarsScrollFrame, fTotal, 13, 32);
end

local function AnsConfigFinalize()
    AnsCore:LoadFilters();
    AnsCore:LoadCustomVars();

    ANS_GLOBAL_SETTINGS.characterBlacklist = { strsplit("\r\n", ANS_GLOBAL_SETTINGS.characterBlacklist) };

    wipe(filterTreeItems);
    AnsConfig.filterView:ReleaseView();
end

function AnsConfig:SetHelpText(f)
    f:SetFont("Fonts\\FRIZQT__.TTF", 12); 
    f:SetText("<html><body><h2>Available String Functions / Variables</h2><br /><p>Operators: All LUA operators</p><br /><p>Functions: first, check, iflte, ifgte, iflt, ifgt, ifeq, ifneq, avg, min, max, mod, abs, ceil,<br />floor, round, random, log, log10, exp, sqrt</p><br /><p>Item VARS: vendorsell, percent, ppu, stacksize, buyout, ilevel, quality</p><br /><p>TUJ VARS: tujmarket, tujrecent, tujglobalmedian, tujglobalmean,<br />tujage, tujdays, tujstddev, tujglobalstddev</p><br /><p>TSM VARS: dbmarket, dbminbuyout, dbhistorical, dbregionmarketavg, dbregionminbuyoutavg, dbregionhistorical, dbregionsaleavg, dbregionsalerate, dbregionsoldperday, dbglobalminbuyoutavg, dbglobalmarketavg, dbglobalhistorical, dbglobalsaleavg, dbglobalsalerate, dbglobalsoldperday</p><br /><p>Auctionator VARS: atrvalue</p></body></html>");
end

function AnsConfig:LoadGlobal(f)
    local percBox = _G[f:GetName().."PercentString"];
    local pricBox = _G[f:GetName().."PriceString"];
    local rscan = _G[f:GetName().."RescanTime"];
    local rscanText = _G[rscan:GetName().."Text"];
    local showDress = _G[f:GetName().."ShowDressing"];
    local safeBuy = _G[f:GetName().."SafeBuy"];
    local safeDelay = _G[f:GetName().."SafeScanDelay"];
    local safeDelayText = _G[safeDelay:GetName().."Text"];
    local useCoins = _G[f:GetName().."UseCoinIcons"];


    safeBuy:SetChecked(ANS_GLOBAL_SETTINGS.safeBuy);
    showDress:SetChecked(ANS_GLOBAL_SETTINGS.showDressing);
    percBox:SetText(ANS_GLOBAL_SETTINGS.percentFn);
    pricBox:SetText(ANS_GLOBAL_SETTINGS.pricingFn);
    rscan:SetValue(ANS_GLOBAL_SETTINGS.rescanTime);
    safeDelay:SetValue(ANS_GLOBAL_SETTINGS.safeDelay);

    useCoins:SetChecked(ANS_GLOBAL_SETTINGS.useCoinIcons);

    safeDelayText:SetText("New Query Max Safe Delay: " ..ANS_GLOBAL_SETTINGS.safeDelay.."s");
    rscanText:SetText("Rescan Time: "..ANS_GLOBAL_SETTINGS.rescanTime.."s");
end

function AnsConfig:LoadBlacklist(f)
    local box = _G[f:GetName().."Blacklist"];

    if (type(ANS_GLOBAL_SETTINGS.characterBlacklist) == "table") then
        box.EditBox:SetText(table.concat(ANS_GLOBAL_SETTINGS.characterBlacklist, "\r\n"));
    else
        box.EditBox:SetText(ANS_GLOBAL_SETTINGS.characterBlacklist);
    end
end

function AnsConfig:Edit(f, type) 
    if (type == "pricing") then
        ANS_GLOBAL_SETTINGS.pricingFn = f:GetText();
    elseif (type == "percent") then
        ANS_GLOBAL_SETTINGS.percentFn = f:GetText();
    elseif (type == "rescan") then
        local rscan = _G[f:GetName().."Text"];
        ANS_GLOBAL_SETTINGS.rescanTime = math.floor(f:GetValue());
        rscan:SetText("Rescan Time: "..ANS_GLOBAL_SETTINGS.rescanTime.."s");
    elseif (type == "dressup") then
        ANS_GLOBAL_SETTINGS.showDressing = f:GetChecked();
    elseif (type == "safebuy") then
        ANS_GLOBAL_SETTINGS.safeBuy = f:GetChecked();
    elseif (type == "safedelay") then
        local safeText = _G[f:GetName().."Text"];
        ANS_GLOBAL_SETTINGS.safeDelay = math.floor(f:GetValue());
        safeText:SetText("New Query Max Safe Delay: "..ANS_GLOBAL_SETTINGS.safeDelay.."s");
    elseif (type == "blacklist") then
        ANS_GLOBAL_SETTINGS.characterBlacklist = f:GetText():lower();
    elseif (type == "coins") then
        ANS_GLOBAL_SETTINGS.useCoinIcons = f:GetChecked();
    end
end

function AnsConfig:LoadPanel(f, parent, name, subtitle)
    f.name = name;
    f.parent = parent;
    
    f.okay = AnsConfigFinalize;
    f.cancel = AnsConfigFinalize;

    subtitle = subtitle or "";

    _G[f:GetName().."_ATitle"]:SetText(name);
    _G[f:GetName().."_BTitle"]:SetText(subtitle);
    InterfaceOptions_AddCategory (f);
end

function AnsConfig:AddFilter()
    local i;
    if (selectedFilter and selectedFilter.filter) then
        i = #selectedFilter.filter.children + 1;
        local t = {
            name = selectedFilter.filter.name.."Custom"..i,
            ids = "",
            children = {},
            useMaxPPU = false,
            useMinLevel = false,
            useQuality = false,
            useMinStack = false,
            usePercent = true,
            priceFn = "",
            types = "",
            subtypes = ""
        };
        tinsert(selectedFilter.filter.children, t);
    else
        i = #ANS_FILTERS + 1;
        local t = {
            name = "Custom"..i,
            ids = "",
            children = {},
            useMaxPPU = false,
            useMinLevel = false,
            useQuality = false,
            useMinStack = false,
            usePercent = true,
            priceFn = "",
            types = "",
            subtypes = ""
        };
        tinsert(ANS_FILTERS, t);
    end

    -- update tree view
    self:FilterRefresh();
end

function AnsConfig:FilterRefresh()
    if (not self.filterView) then
        local TreeView = AnsCore.API.UI.TreeView;
        self.filterView = TreeView:New(_G["AnsFiltersFrame"], 
            nil, 
            function(item) AnsConfig:SelectFilter(item); end,
            function(item) AnsConfig:MoveFilterUp(item); end,
            function(item) AnsConfig:MoveFilterDown(item); end);
    end
    if (not self.moveFilterView) then
        local TreeView = AnsCore.API.UI.TreeView;
        self.moveFilterView = TreeView:New(_G["AnsFiltersFrameMoveSelect"],
        nil,
        function(item) AnsConfig:MoveFilterTo(item); end,
        nil, nil,
        function(row, item) AnsConfig:RenderMoveFilterRow(row, item); end);
    end

    if (#filterTreeItems == 0) then
        tinsert(filterTreeItems, rootFilter);
    end

    self:BuildFilterTree();
    self.filterView.items = filterTreeItems;
    self.filterView:Refresh();
    self.moveFilterView.items = filterTreeItems;
    self.moveFilterView:Refresh();
end

function AnsConfig:ToggleFilterMove(frame)
    local view = _G["AnsFiltersFrameMoveSelect"];

    if (view:IsShown()) then
        view:Hide();
    else
        view:Show();
        view:ClearAllPoints();
        view:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, 0);
    end
end

function AnsConfig:MoveFilterTo(item)
    if (selectedFilter and selectedFilter.filter) then
        -- can't move it into ourself
        if (item.filter == selectedFilter.filter) then
            return;
        end

        local f = selectedFilter.filter;
        local parent = selectedFilter.parent;

        if (parent) then
            for i,v in ipairs(parent.children) do
                if (v == f) then
                    tremove(parent.children, i);
                    break;
                end
            end
        else
            for i,v in ipairs(ANS_FILTERS) do
                if (v == f) then
                    tremove(ANS_FILTERS, i);
                    break;
                end
            end
        end

        if (item.filter) then
            tinsert(item.filter.children, f);
            selectedFilter.parent = item.filter;
        else
            tinsert(ANS_FILTERS, f);
            selectedFilter.parent = nil;
        end

        _G["AnsFiltersFrameMoveSelect"]:Hide();

        self:FilterRefresh();
    end
end

function AnsConfig:RenderMoveFilterRow(row, item)
    local moveUp = _G[row:GetName().."MoveUp"];
    local moveDown = _G[row:GetName().."MoveDown"];

    if (moveUp) then
        moveUp:Hide();
    end
    if (moveDown) then
        moveDown:Hide();
    end
end

function AnsConfig:AddVarRow()
    local id = #ANS_CUSTOM_VARS + 1;
    local f = {name = "VAR"..id, value = ""};
    ANS_CUSTOM_VARS[id] = f;

    FauxScrollFrame_SetOffset(AnsCustomVarsScrollFrame, math.max(id - 13, 0));
    AnsCustomVarsRefresh();
end

function AnsConfig:SaveVarRow(row, type)
    local nameBox = _G[row:GetName().."Name"];
    local valueBox = _G[row:GetName().."Value"];

    local id = row:GetID();

    local f = ANS_CUSTOM_VARS[id];

    if (f ~= nil) then
        if (type == "name") then
            f.name = nameBox:GetText();
        end
        if (type == "value") then
            f.value = valueBox:GetText();
        end
    else
        print("unable to save custom var row");
    end
end

function AnsConfig:SaveFilter(row, type)
    local nameBox = _G[row:GetName().."Name"];
    local idsBox = _G[row:GetName().."IDs"];
    local priceBox = _G[row:GetName().."PriceString"];
    local gbuyout = _G[row:GetName().."GMaxBuyout"];
    local gstack = _G[row:GetName().."GMinStack"];
    local glevel = _G[row:GetName().."GMinLevel"];
    local gquality = _G[row:GetName().."GMinQuality"];
    local gpercent = _G[row:GetName().."GPercent"];
    local subtypes = _G[row:GetName().."SubTypes"];
    local types = _G[row:GetName().."Types"];

    if (selectedFilter and selectedFilter.filter) then
        local f = selectedFilter.filter;
        if (type == "name") then
            selectedFilter.name = nameBox:GetText();
            f.name = nameBox:GetText();
        end
        if (type == "ids") then
            f.ids = idsBox:GetText();
        end
        if (type == "filter") then
            f.priceFn = priceBox:GetText();
        end
        if (type == "buyout") then
            f.useMaxPPU = gbuyout:GetChecked();
        end
        if (type == "stack") then
            f.useMinStack = gstack:GetChecked();
        end
        if (type == "quality") then
            f.useQuality = gquality:GetChecked();
        end
        if (type == "level") then
            f.useMinLevel = glevel:GetChecked();
        end
        if (type == "percent") then
            f.usePercent = gpercent:GetChecked();
        end
        if (type == "subtypes") then
            f.subtypes = subtypes:GetText();
        elseif (type == "types") then
            f.types = types:GetText();
        end

        -- this is more efficient then doing self:FilterRefresh()
        -- as we only need to update the one
        self.filterView:UpdateByData(selectedFilter);
    end
end

function AnsConfig:DeleteVarRow(row)
    local id = row:GetID();
    table.remove(ANS_CUSTOM_VARS, id);
    FauxScrollFrame_SetOffset(AnsCustomVarsScrollFrame, math.max(#ANS_CUSTOM_VARS - 13, 0));
    AnsCustomVarsRefresh();
end

function AnsConfig:ResetAuctionData()
    if (AnsAuctionData) then
        AnsAuctionData:ResetRealm();
    end
end

function AnsConfig:DeleteFilter()
    if (selectedFilter and selectedFilter.filter) then
        local f = selectedFilter.filter;
        local parent = selectedFilter.parent;

        if (parent) then
            for i,v in ipairs(parent.children) do
                if (v == f) then
                    tremove(parent.children, i);
                    break;
                end
            end
        else
            for i,v in ipairs(ANS_FILTERS) do
                if (v == f) then
                    tremove(ANS_FILTERS, i);
                    break;
                end
            end
        end

        self:SelectFilter(nil);
        -- update tree view!
        self:FilterRefresh();
    end
end

function AnsConfig:ImportGroups(editor)
    local i;
    local text = editor:GetText();

    if (text:len() > 0) then
        local filters = Filter:ParseTSMGroups(text);
        for i = 1, #filters do
            local f = filters[i];

            local ids = f:ExportIds();
            if (ids ~= nil and ids:len() > 0) then
                local t = {
                    name = f.name,
                    ids = ids,
                    useMaxPPU = false,
                    useMinLevel = false,
                    useMinStack = false,
                    useQuality = false,
                    usePercent = true,
                    priceFn = "",
                    types = "",
                    subtypes = "",
                    children = {}
                };
                
                if (selectedFilter and selectedFilter.filter) then
                    local sf = selectedFilter.filter;
                    tinsert(sf.children, t);
                else
                    tinsert(ANS_FILTERS, t);
                end
            end
        end

        editor:SetText("");

        -- update tree view
        self:FilterRefresh();
    end
end

function AnsConfig:MoveFilterUp(s)
    local p = s.parent;

    if (not p) then
        p = ANS_FILTERS;
    else
        p = s.parent.children;
    end

    local idx = 0;

    for i,v in ipairs(p) do
        if (v == s.filter) then
            idx = i;
            break;
        end
    end

    if (idx - 1 > 0) then
        tremove(p, idx);
        tinsert(p, idx - 1, s.filter);

        self:FilterRefresh();
    end
end

function AnsConfig:MoveFilterDown(s)
    local p = s.parent;
    
    if (not p) then
        p = ANS_FILTERS;
    else
        p = s.parent.children;
    end

    local idx = 0;

    for i,v in ipairs(p) do
        if (v == s.filter) then
            idx = i;
            break;
        end
    end

    if (idx > 0 and idx + 1 <= #p) then
        tremove(p, idx);
        tinsert(p, idx + 1, s.filter);

        self:FilterRefresh();
    end
end

function AnsConfig:SelectFilter(s)
    selectedFilter = s;
    local details = _G["AnsFiltersFrameFilterDetails"];

    if (selectedFilter and selectedFilter.filter) then
        local f = selectedFilter.filter;  

        local nameBox = _G[details:GetName().."Name"];
        local idsBox = _G[details:GetName().."IDs"];
        local priceBox = _G[details:GetName().."PriceString"];
        local gbuyout = _G[details:GetName().."GMaxBuyout"];
        local gstack = _G[details:GetName().."GMinStack"];
        local glevel = _G[details:GetName().."GMinLevel"];
        local gquality = _G[details:GetName().."GMinQuality"];
        local gpercent = _G[details:GetName().."GPercent"];
        local subtypes = _G[details:GetName().."SubTypes"];
        local types = _G[details:GetName().."Types"];

        nameBox:SetText(f.name);
        idsBox:SetText(f.ids);
        priceBox:SetText(f.priceFn);
        gbuyout:SetChecked(f.useMaxPPU);
        gstack:SetChecked(f.useMinStack);
        glevel:SetChecked(f.useMinLevel);
        gquality:SetChecked(f.useQuality);
        gpercent:SetChecked(f.usePercent);
        types:SetText(f.types);
        subtypes:SetText(f.subtypes);

        details:Show();
    else
        details:Hide();
    end

    self:FilterRefresh();
end

function AnsConfig:BuildFilterTree()
    local filters = ANS_FILTERS;
    local root = rootFilter.children;

    rootFilter.selected = rootFilter == selectedFilter;

    if (#filters < #root) then
        local i;
        for i = #filters + 1, #root do
            tremove(root);
        end
    end

    self:UpdateSubTreeFilters(filters, root, nil);
end

function AnsConfig:UpdateSubTreeFilters(children, parentC, parentFilter)
    for i, v in ipairs(children) do
        local pf = parentC[i];
        local selected = false;

        if (selectedFilter) then
            selected = v == selectedFilter.filter;
        end

        if (pf) then
            pf.selected = selected;
            pf.parent = parentFilter;

            if (pf.name ~= v.name) then
                pf.expanded = false;
                pf.name = v.name;
                
                pf.filter = v;
                pf.children = {};

                if (#v.children > 0) then
                    self:BuildSubTreeFilters(v.children, pf.children, v);
                end
            else
                if(#v.children > 0) then
                    if (#v.children < #pf.children) then
                        local i;
                        for i = #v.children + 1, #pf.children do
                            tremove(pf.children);
                        end
                    end

                    self:UpdateSubTreeFilters(v.children, pf.children, v);
                else
                    pf.children = {};
                end
            end
        else
            local t = {
                name = v.name,
                selected = selected,
                expanded = false,
                parent = parentFilter,
                filter = v,
                children = {}
            };

            if (#v.children > 0) then
                self:BuildSubTreeFilters(v.children, t.children, v);
            end

            tinsert(parentC, t);
        end
    end
end

function AnsConfig:BuildSubTreeFilters(children, parentC, parentFilter)
    for i,v in ipairs(children) do
        local selected = false;

        if (selectedFilter) then
            selected = v == selectedFilter.filter;
        end

        local t = {
            name = v.name,
            selected = selected,
            expanded = false,
            parent = parentFilter,
            filter = v,
            children = {}
        };

        if (#v.children > 0) then
            self:BuildSubTreeFilters(v.children, t.children, v);
        end

        tinsert(parentC, t);
    end
end