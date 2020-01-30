local Ans = select(2, ...);
local Data = {};

Ans.Data = Data;

Ans.BaseData = { path = "" };

local armorBasicSubtypes = {
    LE_ITEM_ARMOR_PLATE,
    LE_ITEM_ARMOR_MAIL,
    LE_ITEM_ARMOR_LEATHER,
    LE_ITEM_ARMOR_CLOTH
};

local armorInventoryTypes = {
    LE_INVENTORY_TYPE_HEAD_TYPE,
    LE_INVENTORY_TYPE_SHOULDER_TYPE,
    LE_INVENTORY_TYPE_CHEST_TYPE,
    LE_INVENTORY_TYPE_WAIST_TYPE,
    LE_INVENTORY_TYPE_LEGS_TYPE,
    LE_INVENTORY_TYPE_FEET_TYPE,
    LE_INVENTORY_TYPE_WRIST_TYPE,
    LE_INVENTORY_TYPE_HAND_TYPE,
};

local miscArmorInventoryTypes = {
    LE_INVENTORY_TYPE_NECK_TYPE,
    LE_INVENTORY_TYPE_CLOAK_TYPE,
    LE_INVENTORY_TYPE_FINGER_TYPE,
    LE_INVENTORY_TYPE_TRINKET_TYPE,
    LE_INVENTORY_TYPE_HOLDABLE_TYPE,
    LE_INVENTORY_TYPE_BODY_TYPE,
    LE_INVENTORY_TYPE_HEAD_TYPE
};

local function AddBaseData(classID, subClassID, parent, inventoryType)
    local name = "";
    if (inventoryType) then
        name = GetItemInventorySlotInfo(inventoryType);
    elseif (classID and subClassID) then
        name = GetItemSubClassInfo(classID, subClassID);
    elseif (classID) then
        name = GetItemClassInfo(classID);
    else
        return nil;
    end

    local item =  {
        name = name,
        classID = classID,
        subClassID = subClassID,
        inventoryType = inventoryType,
        children = {},
        path = ""
    };

    if (parent and parent.path) then
        item.path = parent.path.."."..item.name;
    end

    if (parent.children) then
        tinsert(parent.children, item);
    else
        tinsert(parent, item);
    end

    return item;
end

local function AddSubBaseData(classID, parent)
    local subclasses = C_AuctionHouse.GetAuctionItemSubClasses(classID);
    for i = 1, #subclasses do
        local subClassID = subclasses[i];
        AddBaseData(classID, subClassID, parent);
    end
end

local function BulkAddSubBaseData(classID, subclasses, parent, itemTypes)
    local items = {};
    for i = 1, #subclasses do
        local subClassID = subclasses[i];
        local item = AddBaseData(classID, subClassID, parent);
        tinsert(items, item);
        if (itemTypes and item) then
            for k = 1, #itemTypes do
                AddBaseData(classID, subClassID, item, itemTypes[k]);
            end
        end
    end
    return items;
end

local weaponsRoot = AddBaseData(LE_ITEM_CLASS_WEAPON, nil, Ans.BaseData);
local armorRoot = AddBaseData(LE_ITEM_CLASS_ARMOR, nil, Ans.BaseData);
local containerRoot = AddBaseData(LE_ITEM_CLASS_CONTAINER, nil, Ans.BaseData);
local gemRoot = AddBaseData(LE_ITEM_CLASS_GEM, nil, Ans.BaseData);
local enhanceRoot = AddBaseData(LE_ITEM_CLASS_ITEM_ENHANCEMENT, nil, Ans.BaseData);
local consumableRoot = AddBaseData(LE_ITEM_CLASS_CONSUMABLE, nil, Ans.BaseData);
local tradeRoot = AddBaseData(LE_ITEM_CLASS_TRADEGOODS, nil, Ans.BaseData);
local glyphRoot = AddBaseData(LE_ITEM_CLASS_GLYPH, nil, Ans.BaseData);
local recipeRoot = AddBaseData(LE_ITEM_CLASS_RECIPE, nil, Ans.BaseData);

local battlePetRoot = AddBaseData(LE_ITEM_CLASS_BATTLEPET, nil, Ans.BaseData);

AddBaseData(LE_ITEM_CLASS_QUESTITEM, nil, Ans.BaseData);

local miscRoot = AddBaseData(LE_ITEM_CLASS_MISCELLANEOUS, nil, Ans.BaseData);

AddSubBaseData(LE_ITEM_CLASS_WEAPON, weaponsRoot);

-- basic armor
BulkAddSubBaseData(LE_ITEM_CLASS_ARMOR, armorBasicSubtypes, armorRoot, armorInventoryTypes);
-- misc armor
local miscArmorRoots = BulkAddSubBaseData(LE_ITEM_CLASS_ARMOR, {LE_ITEM_ARMOR_GENERIC}, armorRoot, miscArmorInventoryTypes);
AddBaseData(LE_ITEM_CLASS_ARMOR, LE_ITEM_ARMOR_SHIELD, miscArmorRoots[1]);

AddSubBaseData(LE_ITEM_CLASS_CONTAINER, containerRoot);
AddSubBaseData(LE_ITEM_CLASS_GEM, gemRoot);
AddSubBaseData(LE_ITEM_CLASS_ITEM_ENHANCEMENT, enhanceRoot);
AddSubBaseData(LE_ITEM_CLASS_CONSUMABLE, consumableRoot);
AddSubBaseData(LE_ITEM_CLASS_TRADEGOODS, tradeRoot);
AddSubBaseData(LE_ITEM_CLASS_GLYPH, glyphRoot);
AddSubBaseData(LE_ITEM_CLASS_RECIPE, recipeRoot);
AddSubBaseData(LE_ITEM_CLASS_MISCELLANEOUS, miscRoot);
AddSubBaseData(LE_ITEM_CLASS_BATTLEPET, battlePetRoot);