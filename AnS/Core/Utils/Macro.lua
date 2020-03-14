local Ans = select(2, ...);
local Utils = Ans.Utils;
local Logger = Ans.Logger;
local Macro = {};
Macro.__index = {};
Ans.Macro = Macro;

local MACRO_NAME = "AnSMacro";
local MACRO_ICON = Utils:IsClassic() and "INV_Misc_Flower_01" or "Achievement_Faction_GoldenLotus";
local BINDING_NAME = "MACRO "..MACRO_NAME;
local BUTTONS = {
    ["tsmCancel"] = "/click TSMCancelAuctionBtn",
    ["tsmPost"] = "/click TSMAuctioningBtn",
    ["tsmBuy"] = "/click TSMShoppingBuyoutBtn",
    ["tsmSniper"] = "/click TSMSniperBtn",
    ["tsmCrafting"] = "/click TSMCraftingBtn",
    ["tsmDestroying"] = "/click TSMDestroyBtn",
    ["tsmVendoring"] = "/click TSMVendoringSellAllButton",
    ["ansPost"] = "/click AnsPostScanBtn",
    ["ansCancel"] = "/click AnsCancelScanBtn",
    ["ansSniper"] = "/click AnsSnipeMainPanelBuyNow",
    ["ansSniperFirst"] = "/script AuctionSnipe:BuyFirst()"
};
local MODIFIERS = {
    ["ctrl"] = "CTRL-",
    ["shift"] = "SHIFT-",
    ["alt"] = "ALT-"
};

local tempTbl = {};
local CHARACTER_BINDING_SET = 2;

Macro.BUTTON_MAPPING = BUTTONS;

function Macro.ActiveModifiers()
    local up, alt, ctrl, shift = false, false, false, false;
    local bindings = Utils:GetTable(GetBindingKey(BINDING_NAME));
    for i,v in ipairs(bindings) do
        up = up or strfind(v, "MOUSEWHEELUP");
        ctrl = ctrl or strfind(v, "CTRL-");
        shift = shift or strfind(v, "SHIFT-");
        alt = alt or strfind(v, "ALT-");
    end
    Utils:ReleaseTable(bindings);
    wipe(tempTbl);
    tempTbl["up"] = up;
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

function Macro.Create(commands, modifiers, up)
    local bindings = Utils:GetTable(GetBindingKey(BINDING_NAME));
    for i,v in ipairs(bindings) do
        SetBinding(v);
    end
    DeleteMacro(MACRO_NAME);
    Utils:ReleaseTable(bindings);

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
    if (up) then
        SetBinding(modifierStr.."MOUSEWHEELUP", nil, mode);
        SetBinding(modifierStr.."MOUSEWHEELUP", BINDING_NAME, mode);
    else
        SetBinding(modifierStr.."MOUSEWHEELDOWN", nil, mode);
        SetBinding(modifierStr.."MOUSEWHEELDOWN", BINDING_NAME, mode);
    end

    if (Utils:IsClassic()) then
        AttemptToSaveBindings(CHARACTER_BINDING_SET);
    else
        SaveBindings(CHARACTER_BINDING_SET);
    end

    print("AnS - Macro created and bound");
end