AnsConfig = {};
AnsConfig.__index = AnsConfig;

local function AnsCustomFilterUpdateRow(dataOffset, line)
    local row = _G["AnsCustomFilterRow"..line];
    local nameBox = _G[row:GetName().."Name"];
    local idsBox = _G[row:GetName().."IDs"];
    local priceBox = _G[row:GetName().."PriceString"];
    --local gbuyout = _G[row:GetName().."GMaxBuyout"];
    --local gstack = _G[row:GetName().."GMinStack"];
    --local glevel = _G[row:GetName().."GMinLevel"];
    --local gquality = _G[row:GetName().."GMinQuality"];
    local types = _G[row:GetName().."Types"];
    local subtypes = _G[row:GetName().."SubTypes"];

    if (dataOffset <= #ANS_CUSTOM_FILTERS) then
        local f = ANS_CUSTOM_FILTERS[dataOffset];
        row:SetID(dataOffset);

        nameBox:SetText(f.name);
        idsBox:SetText(f.ids);
        priceBox:SetText(f.priceFn);
        --gbuyout:SetChecked(f.globalMaxBuyout);
        --gstack:SetChecked(f.globalMinStack);
        --glevel:SetChecked(f.globalMinILevel);
        --gquality:SetChecked(f.globalMinQuality);
        types:SetText(f.types or "");
        subtypes:SetText(f.subtypes or "");

        row:Show();
    else
        row:Hide();
    end
end

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

    FauxScrollFrame_Update(AnsCustomVarsScrollFrame, fTotal, 13, 32);

    local dataOffset = 0;
    local offset = FauxScrollFrame_GetOffset(AnsCustomVarsScrollFrame);

    for line = 1, 13 do
        dataOffset = offset + line;
        AnsCustomVarUpdateRow(dataOffset, line);
    end
end

function AnsCustomFilterRefresh()
    local line;
    local fTotal = #ANS_CUSTOM_FILTERS;

    FauxScrollFrame_Update(AnsCustomFilterScrollFrame, fTotal, 4, 100);

    local dataOffset = 0;
    local offset = FauxScrollFrame_GetOffset(AnsCustomFilterScrollFrame);

    for line = 1, 4 do
        dataOffset = offset + line;
        AnsCustomFilterUpdateRow(dataOffset, line);
    end
end

local function AnsConfigFinalize()
    AnsCore:LoadCustomFilters();
    AnsCore:LoadCustomVars();
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


    safeBuy:SetChecked(ANS_GLOBAL_SETTINGS.safeBuy);
    showDress:SetChecked(ANS_GLOBAL_SETTINGS.showDressing);
    percBox:SetText(ANS_GLOBAL_SETTINGS.percentFn);
    pricBox:SetText(ANS_GLOBAL_SETTINGS.pricingFn);
    rscan:SetValue(ANS_GLOBAL_SETTINGS.rescanTime);
    safeDelay:SetValue(ANS_GLOBAL_SETTINGS.safeDelay);

    safeDelayText:SetText("New Query Max Safe Delay: " ..ANS_GLOBAL_SETTINGS.safeDelay.."s");
    rscanText:SetText("Rescan Time: "..ANS_GLOBAL_SETTINGS.rescanTime.."s");
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

function AnsConfig:AddFilterRow()
    local id = #ANS_CUSTOM_FILTERS + 1;
    local f = AnsCustomFilter:New("Custom"..id, "");
    ANS_CUSTOM_FILTERS[id] = f;

    FauxScrollFrame_SetOffset(AnsCustomFilterScrollFrame, math.max(id - 4, 0));
    AnsCustomFilterRefresh();
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

function AnsConfig:SaveFilterRow(row, type)
    local nameBox = _G[row:GetName().."Name"];
    local idsBox = _G[row:GetName().."IDs"];
    local priceBox = _G[row:GetName().."PriceString"];
    local gbuyout = _G[row:GetName().."GMaxBuyout"];
    local gstack = _G[row:GetName().."GMinStack"];
    local glevel = _G[row:GetName().."GMinLevel"];
    local gquality = _G[row:GetName().."GMinQuality"];
    local subtypes = _G[row:GetName().."SubTypes"];
    local types = _G[row:GetName().."Types"];

    local id = row:GetID();

    local f = ANS_CUSTOM_FILTERS[id];
    if (f ~= nil) then
        if (type == "name") then
            f.name = nameBox:GetText();
        end
        if (type == "ids") then
            f.ids = idsBox:GetText();
        end
        if (type == "filter") then
            f.priceFn = priceBox:GetText();
        end
        if (type == "buyout") then
            f.globalMaxBuyout = gbuyout:GetChecked();
        end
        if (type == "stack") then
            f.globalMinStack = gstack:GetChecked();
        end
        if (type == "quality") then
            f.globalMinQuality = gquality:GetChecked();
        end
        if (type == "level") then
            f.globalMinILevel = glevel:GetChecked();
        end
        if (type == "subtypes") then
            f.subtypes = subtypes:GetText();
        elseif (type == "types") then
            f.types = types:GetText();
        end
    else
        print("Unable to save custom filter row...");
    end
end

function AnsConfig:DeleteVarRow(row)
    local id = row:GetID();
    table.remove(ANS_CUSTOM_VARS, id);
    FauxScrollFrame_SetOffset(AnsCustomVarsScrollFrame, math.max(#ANS_CUSTOM_VARS - 13, 0));
    AnsCustomVarsRefresh();
end

function AnsConfig:DeleteFilterRow(row)
    local id = row:GetID();
    table.remove(ANS_CUSTOM_FILTERS, id);
    FauxScrollFrame_SetOffset(AnsCustomFilterScrollFrame, math.max(#ANS_CUSTOM_FILTERS - 4, 0));
    AnsCustomFilterRefresh();
end

function AnsConfig:ImportGroups(editor)
    local i;
    local text = editor:GetText();

    if (text:len() > 0) then
        local filters = AnsFilter:ParseTSMGroups(text);

        local total = #ANS_CUSTOM_FILTERS;

        for i = 1, #filters do
            local f = filters[i];

            local ids = f:ExportIds();
            if (ids ~= nil and ids:len() > 0) then
                local cf = AnsCustomFilter:New(f.name, ids);
                total = total + 1;
                ANS_CUSTOM_FILTERS[total] = cf;
            end
        end

        editor:SetText("");

        FauxScrollFrame_SetOffset(AnsCustomFilterScrollFrame, math.max(total - 4, 0));
        AnsCustomFilterRefresh();
    end
end
