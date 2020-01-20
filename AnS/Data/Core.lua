local Ans = select(2, ...);
local Data = {};

Ans.Data = Data;

Ans.BaseData = { path = "" };

local function AddBaseData(classID, subClassID, parent)
    local name = "";
    if classID and subClassID then
        name = GetItemSubClassInfo(classID, subClassID);
    elseif classID then
        name = GetItemClassInfo(classID);
    else
        return nil;
    end

    local item =  {
        name = name,
        classID = classID,
        subClassID = subClassID,
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
AddSubBaseData(LE_ITEM_CLASS_ARMOR, armorRoot);
AddSubBaseData(LE_ITEM_CLASS_CONTAINER, containerRoot);
AddSubBaseData(LE_ITEM_CLASS_GEM, gemRoot);
AddSubBaseData(LE_ITEM_CLASS_ITEM_ENHANCEMENT, enhanceRoot);
AddSubBaseData(LE_ITEM_CLASS_CONSUMABLE, consumableRoot);
AddSubBaseData(LE_ITEM_CLASS_TRADEGOODS, tradeRoot);
AddSubBaseData(LE_ITEM_CLASS_GLYPH, glyphRoot);
AddSubBaseData(LE_ITEM_CLASS_RECIPE, recipeRoot);
AddSubBaseData(LE_ITEM_CLASS_MISCELLANEOUS, miscRoot);
AddSubBaseData(LE_ITEM_CLASS_BATTLEPET, battlePetRoot);