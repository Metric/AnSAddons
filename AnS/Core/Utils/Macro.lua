local Ans = select(2, ...);
local Utils = Ans.Utils;
local Logger = Ans.Logger;
local TempTable = Ans.TempTable;
local Macro = Ans.Object.Register("Macro");

local MACRO_NAME = "AnSMacro";
local MACRO_ICON = Utils.IsClassicEra() and "INV_Misc_Flower_01" or "Achievement_Faction_GoldenLotus";
local BINDING_NAME = "MACRO "..MACRO_NAME;
local BUTTONS = {
    ["tsmCancel"] = "/click TSMCancelAuctionBtn",
    ["tsmPost"] = "/click TSMAuctioningBtn",
    ["tsmBuy"] = "/click TSMShoppingBuyoutBtn",
    ["tsmSniper"] = "/click TSMSniperBtn",
    ["tsmCrafting"] = "/click TSMCraftingBtn",
    ["tsmDestroying"] = "/click TSMDestroyBtn",
    ["tsmVendoring"] = "/click TSMVendoringSellAllButton",
    ["ansPost"] = "/click AnsPostScan",
    ["ansCancel"] = "/click AnsCancelScan",
    ["ansSniper"] = "/click AnsSnipeBuy",
    ["ansSniperFirst"] = "/click AnsSnipeFirst",
    ["ansDestroy"] = "/click AnsDestroy",
    ["ansIgnore"] = "/click AnsSnipeIgnore",
    ["ansIgnoreFirst"] = "/click AnsSnipeIgnore1",
};
local MODIFIERS = {
    ["ctrl"] = "CTRL-",
    ["shift"] = "SHIFT-",
    ["alt"] = "ALT-"
};

local MAX_MACRO_LENGTH = 255;

local tempTbl = {};
local CHARACTER_BINDING_SET = 2;

Macro.BUTTON_MAPPING = BUTTONS;
Macro.MODIFIER_MAPPING = MODIFIERS;

function Macro.ActiveModifiers()
    local up, down, alt, ctrl, shift = false, false, false, false, false;
    local bindings = TempTable:Acquire(GetBindingKey(BINDING_NAME));
    for i,v in ipairs(bindings) do
        up = up or strfind(v, "MOUSEWHEELUP");
        down = down or strfind(v, "MOUSEWHEELDOWN");
        ctrl = ctrl or strfind(v, "CTRL-");
        shift = shift or strfind(v, "SHIFT-");
        alt = alt or strfind(v, "ALT-");
    end
    bindings:Release();
    wipe(tempTbl);
    tempTbl["up"] = up;
    tempTbl["down"] = down;
    tempTbl["ctrl"] = ctrl;
    tempTbl["shift"] = shift;
    tempTbl["alt"] = alt;
    return tempTbl;
end

function Macro.ActiveButtons()
    local body = GetMacroBody(MACRO_NAME) or "";
    wipe(tempTbl);
    for k,v in pairs(BUTTONS) do
        if (strfind(body, v)) then
            tempTbl[k] = true;
        else
            tempTbl[k] = false;
        end
    end
    return tempTbl;
end

function Macro.Create(commands, modifiers, up, down)
    local bindings = TempTable:Acquire(GetBindingKey(BINDING_NAME));
    for i,v in ipairs(bindings) do
        SetBinding(v);
    end
    DeleteMacro(MACRO_NAME);
    bindings:Release();

    if (GetNumMacros() >= MAX_ACCOUNT_MACROS) then
        local helpText = "Could not create a new macro. Delete one of your existing macros and try again.";
        Logger.Log("MACRO", helpText);
        print("AnS - "..helpText);
        return;
    end

    local text = table.concat(commands, "\n");
    CreateMacro(MACRO_NAME, MACRO_ICON, text);

    local modifierStr = "";
    for i,v in ipairs(modifiers) do
        modifierStr = modifierStr..(MODIFIERS[v] and MODIFIERS[v] or "");
    end

    local mode = (GetCurrentBindingSet() == CHARACTER_BINDING_SET) and 1 or 2;
    if (up and not down) then
        SetBinding(modifierStr.."MOUSEWHEELUP", nil, mode);
        SetBinding(modifierStr.."MOUSEWHEELUP", BINDING_NAME, mode);
    elseif (down and not up) then
        SetBinding(modifierStr.."MOUSEWHEELDOWN", nil, mode);
        SetBinding(modifierStr.."MOUSEWHEELDOWN", BINDING_NAME, mode);
    elseif (up and down) then
        SetBinding(modifierStr.."MOUSEWHEELDOWN", nil, mode);
        SetBinding(modifierStr.."MOUSEWHEELDOWN", BINDING_NAME, mode);
        SetBinding(modifierStr.."MOUSEWHEELUP", nil, mode);
        SetBinding(modifierStr.."MOUSEWHEELUP", BINDING_NAME, mode);
    end

    SaveBindings(CHARACTER_BINDING_SET);

    if (#text > MAX_MACRO_LENGTH) then
        print("AnS - Macro truncated. Not all actions will be available.");
    end

    print("AnS - Macro created and bound");
end