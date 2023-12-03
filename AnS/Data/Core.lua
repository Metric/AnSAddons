local Ans = select(2, ...);
local Data = {};
local Utils = Ans.Utils;

Ans.Data = Data;

Ans.BaseData = { path = "" };

local RUNECARVING = 1000;
Ans.Data.RUNECARVING = RUNECARVING;

local armorBasicSubtypes = {};

local armorInventoryTypes = {};

local miscArmorInventoryTypes = {};

-- note these variables have been deprecated
-- however in order to make sure we have proper compat
-- we will add this here

if (Utils.IsRetail()) then
    -- Item class/subclass enum conversions
	LE_ITEM_CLASS_CONSUMABLE = Enum.ItemClass.Consumable;
	LE_ITEM_CLASS_CONTAINER = Enum.ItemClass.Container;
	LE_ITEM_CLASS_WEAPON = Enum.ItemClass.Weapon;
	LE_ITEM_CLASS_GEM = Enum.ItemClass.Gem;
	LE_ITEM_CLASS_ARMOR = Enum.ItemClass.Armor;
	LE_ITEM_CLASS_REAGENT = Enum.ItemClass.Reagent;
	LE_ITEM_CLASS_PROJECTILE = Enum.ItemClass.Projectile;
	LE_ITEM_CLASS_TRADEGOODS = Enum.ItemClass.Tradegoods;
	LE_ITEM_CLASS_ITEM_ENHANCEMENT = Enum.ItemClass.ItemEnhancement;
	LE_ITEM_CLASS_RECIPE = Enum.ItemClass.Recipe;
	LE_ITEM_CLASS_QUIVER = Enum.ItemClass.Quiver;
	LE_ITEM_CLASS_QUESTITEM = Enum.ItemClass.Questitem;
	LE_ITEM_CLASS_KEY = Enum.ItemClass.Key;
	LE_ITEM_CLASS_MISCELLANEOUS = Enum.ItemClass.Miscellaneous;
	LE_ITEM_CLASS_GLYPH = Enum.ItemClass.Glyph;
	LE_ITEM_CLASS_BATTLEPET = Enum.ItemClass.Battlepet;
	LE_ITEM_CLASS_WOW_TOKEN = Enum.ItemClass.WoWToken;

	LE_ITEM_WEAPON_AXE1H = Enum.ItemWeaponSubclass.Axe1H;
	LE_ITEM_WEAPON_AXE2H = Enum.ItemWeaponSubclass.Axe2H;
	LE_ITEM_WEAPON_BOWS = Enum.ItemWeaponSubclass.Bows;
	LE_ITEM_WEAPON_GUNS = Enum.ItemWeaponSubclass.Guns;
	LE_ITEM_WEAPON_MACE1H = Enum.ItemWeaponSubclass.Mace1H;
	LE_ITEM_WEAPON_MACE2H = Enum.ItemWeaponSubclass.Mace2H;
	LE_ITEM_WEAPON_POLEARM = Enum.ItemWeaponSubclass.Polearm;
	LE_ITEM_WEAPON_SWORD1H = Enum.ItemWeaponSubclass.Sword1H;
	LE_ITEM_WEAPON_SWORD2H = Enum.ItemWeaponSubclass.Sword2H;
	LE_ITEM_WEAPON_WARGLAIVE = Enum.ItemWeaponSubclass.Warglaive;
	LE_ITEM_WEAPON_STAFF = Enum.ItemWeaponSubclass.Staff;
	LE_ITEM_WEAPON_BEARCLAW = Enum.ItemWeaponSubclass.Bearclaw;
	LE_ITEM_WEAPON_CATCLAW = Enum.ItemWeaponSubclass.Catclaw;
	LE_ITEM_WEAPON_UNARMED = Enum.ItemWeaponSubclass.Unarmed;
	LE_ITEM_WEAPON_GENERIC = Enum.ItemWeaponSubclass.Generic;
	LE_ITEM_WEAPON_DAGGER = Enum.ItemWeaponSubclass.Dagger;
	LE_ITEM_WEAPON_THROWN = Enum.ItemWeaponSubclass.Thrown;
	LE_ITEM_WEAPON_OBSOLETE3 = Enum.ItemWeaponSubclass.Obsolete3;
	LE_ITEM_WEAPON_CROSSBOW = Enum.ItemWeaponSubclass.Crossbow;
	LE_ITEM_WEAPON_WAND = Enum.ItemWeaponSubclass.Wand;
	LE_ITEM_WEAPON_FISHINGPOLE = Enum.ItemWeaponSubclass.Fishingpole;

	LE_ITEM_ARMOR_GENERIC = Enum.ItemArmorSubclass.Generic;
	LE_ITEM_ARMOR_CLOTH = Enum.ItemArmorSubclass.Cloth;
	LE_ITEM_ARMOR_LEATHER = Enum.ItemArmorSubclass.Leather;
	LE_ITEM_ARMOR_MAIL = Enum.ItemArmorSubclass.Mail;
	LE_ITEM_ARMOR_PLATE = Enum.ItemArmorSubclass.Plate;
	LE_ITEM_ARMOR_COSMETIC = Enum.ItemArmorSubclass.Cosmetic;
	LE_ITEM_ARMOR_SHIELD = Enum.ItemArmorSubclass.Shield;
	LE_ITEM_ARMOR_LIBRAM = Enum.ItemArmorSubclass.Libram;
	LE_ITEM_ARMOR_IDOL = Enum.ItemArmorSubclass.Idol;
	LE_ITEM_ARMOR_TOTEM = Enum.ItemArmorSubclass.Totem;
	LE_ITEM_ARMOR_SIGIL = Enum.ItemArmorSubclass.Sigil;
	LE_ITEM_ARMOR_RELIC = Enum.ItemArmorSubclass.Relic;

	LE_ITEM_GEM_INTELLECT = Enum.ItemGemSubclass.Intellect;
	LE_ITEM_GEM_AGILITY = Enum.ItemGemSubclass.Agility;
	LE_ITEM_GEM_STRENGTH = Enum.ItemGemSubclass.Strength;
	LE_ITEM_GEM_STAMINA = Enum.ItemGemSubclass.Stamina;
	LE_ITEM_GEM_SPIRIT = Enum.ItemGemSubclass.Spirit;
	LE_ITEM_GEM_CRITICALSTRIKE = Enum.ItemGemSubclass.Criticalstrike;
	LE_ITEM_GEM_MASTERY = Enum.ItemGemSubclass.Mastery;
	LE_ITEM_GEM_HASTE = Enum.ItemGemSubclass.Haste;
	LE_ITEM_GEM_VERSATILITY = Enum.ItemGemSubclass.Versatility;
	LE_ITEM_GEM_MULTIPLESTATS = Enum.ItemGemSubclass.Multiplestats;
	LE_ITEM_GEM_ARTIFACTRELIC = Enum.ItemGemSubclass.Artifactrelic;

	LE_ITEM_RECIPE_BOOK = Enum.ItemRecipeSubclass.Book;
	LE_ITEM_RECIPE_LEATHERWORKING = Enum.ItemRecipeSubclass.Leatherworking;
	LE_ITEM_RECIPE_TAILORING = Enum.ItemRecipeSubclass.Tailoring;
	LE_ITEM_RECIPE_ENGINEERING = Enum.ItemRecipeSubclass.Engineering;
	LE_ITEM_RECIPE_BLACKSMITHING = Enum.ItemRecipeSubclass.Blacksmithing;
	LE_ITEM_RECIPE_COOKING = Enum.ItemRecipeSubclass.Cooking;
	LE_ITEM_RECIPE_ALCHEMY = Enum.ItemRecipeSubclass.Alchemy;
	LE_ITEM_RECIPE_FIRST_AID = Enum.ItemRecipeSubclass.FirstAid;
	LE_ITEM_RECIPE_ENCHANTING = Enum.ItemRecipeSubclass.Enchanting;
	LE_ITEM_RECIPE_FISHING = Enum.ItemRecipeSubclass.Fishing;
	LE_ITEM_RECIPE_JEWELCRAFTING = Enum.ItemRecipeSubclass.Jewelcrafting;
	LE_ITEM_RECIPE_INSCRIPTION = Enum.ItemRecipeSubclass.Inscription;

	LE_ITEM_MISCELLANEOUS_JUNK = Enum.ItemMiscellaneousSubclass.Junk;
	LE_ITEM_MISCELLANEOUS_REAGENT = Enum.ItemMiscellaneousSubclass.Reagent;
	LE_ITEM_MISCELLANEOUS_COMPANION_PET = Enum.ItemMiscellaneousSubclass.CompanionPet;
	LE_ITEM_MISCELLANEOUS_HOLIDAY = Enum.ItemMiscellaneousSubclass.Holiday;
	LE_ITEM_MISCELLANEOUS_OTHER = Enum.ItemMiscellaneousSubclass.Other;
	LE_ITEM_MISCELLANEOUS_MOUNT = Enum.ItemMiscellaneousSubclass.Mount;
	LE_ITEM_MISCELLANEOUS_MOUNT_EQUIPMENT = Enum.ItemMiscellaneousSubclass.MountEquipment;

    IsDressableItem = C_Item.IsDressableItemByID;
    GetAuctionItemSubClasses = C_AuctionHouse.GetAuctionItemSubClasses;
    
    -- Note: these will be deprecated in a future Dragon Expansion Patch
    -- GetContainerItemLink = C_Container.GetContainerItemLink
    -- GetContainerNumSlots = C_Container.GetContainerNumSlots
    -- GetContainerItemInfo = C_Container.GetContainerItemInfo
    -- GetContainerItemID = C_Container.GetContainerItemID
    -- GetContainerItemDurability = C_Container.GetContainerItemDurability
    -- ContainerIDToInventoryID = C_Container.ContainerIDToInventoryID
end

armorBasicSubtypes = {
    LE_ITEM_ARMOR_PLATE,
    LE_ITEM_ARMOR_MAIL,
    LE_ITEM_ARMOR_LEATHER,
    LE_ITEM_ARMOR_CLOTH
};

if (Utils.IsRetail()) then
    armorInventoryTypes = {
        RUNECARVING,
        Enum.InventoryType.IndexHeadType,
        Enum.InventoryType.IndexShoulderType,
        Enum.InventoryType.IndexChestType,
        Enum.InventoryType.IndexWaistType,
        Enum.InventoryType.IndexLegsType,
        Enum.InventoryType.IndexFeetType,
        Enum.InventoryType.IndexWristType,
        Enum.InventoryType.IndexHandType,
    };
    
    miscArmorInventoryTypes = {
        RUNECARVING,
        Enum.InventoryType.IndexNeckType,
        Enum.InventoryType.IndexCloakType,
        Enum.InventoryType.IndexFingerType,
        Enum.InventoryType.IndexTrinketType,
        Enum.InventoryType.IndexHoldableType,
        Enum.InventoryType.IndexBodyType,
        Enum.InventoryType.IndexHeadType
    };
else 
    armorInventoryTypes = {
        LE_INVENTORY_TYPE_HEAD_TYPE,
        LE_INVENTORY_TYPE_SHOULDER_TYPE,
        LE_INVENTORY_TYPE_CHEST_TYPE,
        LE_INVENTORY_TYPE_WAIST_TYPE,
        LE_INVENTORY_TYPE_LEGS_TYPE,
        LE_INVENTORY_TYPE_FEET_TYPE,
        LE_INVENTORY_TYPE_WRIST_TYPE,
        LE_INVENTORY_TYPE_HAND_TYPE,
    };
    miscArmorInventoryTypes = {
        LE_INVENTORY_TYPE_NECK_TYPE,
        LE_INVENTORY_TYPE_CLOAK_TYPE,
        LE_INVENTORY_TYPE_FINGER_TYPE,
        LE_INVENTORY_TYPE_TRINKET_TYPE,
        LE_INVENTORY_TYPE_HOLDABLE_TYPE,
        LE_INVENTORY_TYPE_BODY_TYPE,
        LE_INVENTORY_TYPE_HEAD_TYPE
    }
end

local function AddBaseData(classID, subClassID, parent, inventoryType)
    local name = "";
    if (inventoryType and inventoryType == RUNECARVING) then
        name = "Runecarving" --AUCTION_HOUSE_FILTER_STRINGS[inventoryType];
    elseif (inventoryType) then
        name = GetItemInventorySlotInfo(inventoryType);
    elseif (classID and subClassID) then
        name = GetItemSubClassInfo(classID, subClassID);
    elseif (classID) then
        name = GetItemClassInfo(classID);
    else
        return nil;
    end

    if (not name) then
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
    local subclasses = nil;

    if (Utils.IsRetail()) then
        subclasses = GetAuctionItemSubClasses(classID);
    else
        subclasses = {GetAuctionItemSubClasses(classID)};
    end

    if (not subclasses) then 
        return;
    end

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
        if (item) then
            tinsert(items, item);
        end
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

if (Utils.GemsAvailable()) then
    local gemRoot = AddBaseData(LE_ITEM_CLASS_GEM, nil, Ans.BaseData);
    AddSubBaseData(LE_ITEM_CLASS_GEM, gemRoot);
end

local enhanceRoot = AddBaseData(LE_ITEM_CLASS_ITEM_ENHANCEMENT, nil, Ans.BaseData);
local consumableRoot = AddBaseData(LE_ITEM_CLASS_CONSUMABLE, nil, Ans.BaseData);
local tradeRoot = AddBaseData(LE_ITEM_CLASS_TRADEGOODS, nil, Ans.BaseData);

if (Utils.GlyphsAvailable()) then
    local glyphRoot = AddBaseData(LE_ITEM_CLASS_GLYPH, nil, Ans.BaseData);
    AddSubBaseData(LE_ITEM_CLASS_GLYPH, glyphRoot);
end

local recipeRoot = AddBaseData(LE_ITEM_CLASS_RECIPE, nil, Ans.BaseData);

if (Utils.BattlePetsAvailable()) then
    local battlePetRoot = AddBaseData(LE_ITEM_CLASS_BATTLEPET, nil, Ans.BaseData);
    AddSubBaseData(LE_ITEM_CLASS_BATTLEPET, battlePetRoot);
end

AddBaseData(LE_ITEM_CLASS_QUESTITEM, nil, Ans.BaseData);

local miscRoot = AddBaseData(LE_ITEM_CLASS_MISCELLANEOUS, nil, Ans.BaseData);

AddSubBaseData(LE_ITEM_CLASS_WEAPON, weaponsRoot);

-- basic armor
BulkAddSubBaseData(LE_ITEM_CLASS_ARMOR, armorBasicSubtypes, armorRoot, armorInventoryTypes);
-- misc armor
local miscArmorRoots = BulkAddSubBaseData(LE_ITEM_CLASS_ARMOR, {LE_ITEM_ARMOR_GENERIC}, armorRoot, miscArmorInventoryTypes);
AddBaseData(LE_ITEM_CLASS_ARMOR, LE_ITEM_ARMOR_SHIELD, miscArmorRoots[1]);

AddSubBaseData(LE_ITEM_CLASS_CONTAINER, containerRoot);

AddSubBaseData(LE_ITEM_CLASS_ITEM_ENHANCEMENT, enhanceRoot);
AddSubBaseData(LE_ITEM_CLASS_CONSUMABLE, consumableRoot);
AddSubBaseData(LE_ITEM_CLASS_TRADEGOODS, tradeRoot);

AddSubBaseData(LE_ITEM_CLASS_RECIPE, recipeRoot);
AddSubBaseData(LE_ITEM_CLASS_MISCELLANEOUS, miscRoot);
