AnsConfig = {};
AnsConfig.__index = AnsConfig;

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
    AnsCore:LoadCustomVars();
    ANS_GLOBAL_SETTINGS.characterBlacklist = { strsplit("\r\n", ANS_GLOBAL_SETTINGS.characterBlacklist) };
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
    local scanDelay = _G[f:GetName().."ScanDelay"];
    local delayText = _G[scanDelay:GetName().."Text"];
    local useCoins = _G[f:GetName().."UseCoinIcons"];
    local useCommodity = _G[f:GetName().."UseCommodityConfirm"];

    showDress:SetChecked(ANS_GLOBAL_SETTINGS.showDressing);
    percBox:SetText(ANS_GLOBAL_SETTINGS.percentFn);
    pricBox:SetText(ANS_GLOBAL_SETTINGS.pricingFn);
    rscan:SetValue(ANS_GLOBAL_SETTINGS.rescanTime);
    scanDelay:SetValue(ANS_GLOBAL_SETTINGS.scanDelayTime);

    useCoins:SetChecked(ANS_GLOBAL_SETTINGS.useCoinIcons);
    useCommodity:SetChecked(ANS_GLOBAL_SETTINGS.useCommodityConfirm);

    rscanText:SetText("Rescan Time: "..ANS_GLOBAL_SETTINGS.rescanTime.."s");
    delayText:SetText("Item Found Scan Delay: "..ANS_GLOBAL_SETTINGS.scanDelayTime.."s");
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
    elseif (type == "blacklist") then
        ANS_GLOBAL_SETTINGS.characterBlacklist = f:GetText():lower();
    elseif (type == "coins") then
        ANS_GLOBAL_SETTINGS.useCoinIcons = f:GetChecked();
    elseif (type == "scandelay") then
        local rscan = _G[f:GetName().."Text"];
        ANS_GLOBAL_SETTINGS.scanDelayTime = math.floor(f:GetValue());
        rscan:SetText("Item Found Scan Delay: "..ANS_GLOBAL_SETTINGS.scanDelayTime.."s");
    elseif (type == "commodityconfirm") then
        ANS_GLOBAL_SETTINGS.useCommodityConfirm = f:GetChecked();
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

function AnsConfig:ImportGroups(editor)
    local i;
    local text = editor:GetText();

    if (text:len() > 0) then
        local parent = nil;
        local base = ANS_FILTERS;

        if (selectedFilter and selectedFilter.filter and selectedFilter.filter.children) then
            parent = selectedFilter.filter;
            base = parent.children;
        end

        local root = self:BuildFilters(parent);

        root:ParseTSMGroups(text);

        -- clear previous to rebuild
        wipe(base);

        for i, v in ipairs(root.subfilters) do
            tinsert(base, v:ToConfigFilter());
        end

        editor:SetText("");

        -- update tree view
        self:FilterRefresh();
    end
end