--- predefined base filter for herbs, etc 

local filterArmor = AnsFilter:New("Armor");
filterArmor.types[1] = "armor";
local filterWeapon = AnsFilter:New("Weapons");
filterWeapon.types[1] = "weapon";
local filterConsumable = AnsFilter:New("Consumable");
filterConsumable.types[1] = "consumable";
local filterContainer = AnsFilter:New("Container");
filterContainer.types[1] = "container";
local filterRecipes = AnsFilter:New("Recipes");
filterRecipes.types[1] = "recipe";

local filterHerbs = AnsFilter:New("Herbs");
filterHerbs.subfilters = {};

local filterBasicHerbs = AnsFilter:New("Old");
filterBasicHerbs:ParseTSM(AnsHerb.Basic);
filterBasicHerbs.isSub = true;
local filterCrusadeHerbs = AnsFilter:New("BC");
filterCrusadeHerbs:ParseTSM(AnsHerb.BC);
filterCrusadeHerbs.isSub = true;
local filterWotlkHerbs = AnsFilter:New("Wotlk");
filterWotlkHerbs:ParseTSM(AnsHerb.Wotlk);
filterWotlkHerbs.isSub = true;
local filterCataHerbs = AnsFilter:New("Cata");
filterCataHerbs:ParseTSM(AnsHerb.Cata);
filterCataHerbs.isSub = true;
local filterMistsHerbs = AnsFilter:New("Mists");
filterMistsHerbs:ParseTSM(AnsHerb.Mists);
filterMistsHerbs.isSub = true;
local filterWarlordsHerbs = AnsFilter:New("Warlords");
filterWarlordsHerbs:ParseTSM(AnsHerb.Warlords);
filterWarlordsHerbs.isSub = true;
local filterLegionHerbs = AnsFilter:New("Legion");
filterLegionHerbs:ParseTSM(AnsHerb.Legion);
filterLegionHerbs.isSub = true;
local filterBFAHerbs = AnsFilter:New("BFA");
filterBFAHerbs:ParseTSM(AnsHerb.BFA);
filterBFAHerbs.isSub = true;

filterHerbs.subfilters[1] = filterBFAHerbs;
filterHerbs.subfilters[2] = filterLegionHerbs;
filterHerbs.subfilters[3] = filterWarlordsHerbs;
filterHerbs.subfilters[4] = filterMistsHerbs;
filterHerbs.subfilters[5] = filterCataHerbs;
filterHerbs.subfilters[6] = filterWotlkHerbs;
filterHerbs.subfilters[7] = filterCrusadeHerbs;
filterHerbs.subfilters[8] = filterBasicHerbs;

local filterOre = AnsFilter:New("Ore");
filterOre.subfilters = {};

local filterBasicOres = AnsFilter:New("Old");
filterBasicOres:ParseTSM(AnsOre.Basic);
filterBasicOres.isSub = true;
local filterCrusadeOres = AnsFilter:New("BC");
filterCrusadeOres:ParseTSM(AnsOre.BC);
filterCrusadeOres.isSub = true;
local filterWotlkOres = AnsFilter:New("Wotlk");
filterWotlkOres:ParseTSM(AnsOre.Wotlk);
filterWotlkOres.isSub = true;
local filterCataOres = AnsFilter:New("Cata");
filterCataOres:ParseTSM(AnsOre.Cata);
filterCataOres.isSub = true;
local filterMistsOres = AnsFilter:New("Mists");
filterMistsOres:ParseTSM(AnsOre.Mists);
filterMistsOres.isSub = true;
local filterWarlordsOres = AnsFilter:New("Warlords");
filterWarlordsOres:ParseTSM(AnsOre.Warlords);
filterWarlordsOres.isSub = true;
local filterLegionOres = AnsFilter:New("Legion");
filterLegionOres:ParseTSM(AnsOre.Legion);
filterLegionOres.isSub = true;
local filterBFAOres = AnsFilter:New("BFA");
filterBFAOres:ParseTSM(AnsOre.BFA);
filterBFAOres.isSub = true;

filterOre.subfilters[1] = filterBFAOres;
filterOre.subfilters[2] = filterLegionOres;
filterOre.subfilters[3] = filterWarlordsOres;
filterOre.subfilters[4] = filterMistsOres;
filterOre.subfilters[5] = filterCataOres;
filterOre.subfilters[6] = filterWotlkOres;
filterOre.subfilters[7] = filterCrusadeOres;
filterOre.subfilters[8] = filterBasicOres;

local filterCloth = AnsFilter:New("Cloth");
filterCloth.subfilters = {};

local filterClothBasic = AnsFilter:New("Pre-Legion");
filterClothBasic:ParseTSM(AnsCloth.Basic);
filterClothBasic.isSub = true;
local filterClothLegion = AnsFilter:New("Legion");
filterClothLegion:ParseTSM(AnsCloth.Legion);
filterClothLegion.isSub = true;
local filterClothBFA = AnsFilter:New("BFA");
filterClothBFA:ParseTSM(AnsCloth.BFA);
filterClothBFA.isSub = true;

filterCloth.subfilters[1] = filterClothBFA;
filterCloth.subfilters[2] = filterClothLegion;
filterCloth.subfilters[3] = filterClothBasic;

local filterLeather = AnsFilter:New("Leather");
filterLeather.subfilters = {};

local filterLeatherBasic = AnsFilter:New("Pre-Legion");
filterLeatherBasic:ParseTSM(AnsLeather.Basic);
filterLeatherBasic.isSub = true;
local filterLeatherLegion = AnsFilter:New("Legion");
filterLeatherLegion:ParseTSM(AnsLeather.Legion);
filterLeatherLegion.isSub = true;
local filterLeatherBFA = AnsFilter:New("BFA");
filterLeatherBFA:ParseTSM(AnsLeather.BFA);
filterLeatherBFA.isSub = true;

filterLeather.subfilters[1] = filterLeatherBFA;
filterLeather.subfilters[2] = filterLeatherLegion;
filterLeather.subfilters[3] = filterLeatherBasic;

local filterEnchanting = AnsFilter:New("Enchanting");
filterEnchanting.subfilters = {};
local filterEnchantingBasic = AnsFilter:New("Pre-Legion");
filterEnchantingBasic:ParseTSM(AnsEnchanting.Basic);
filterEnchantingBasic.isSub = true;
local filterEnchantingLegion = AnsFilter:New("Legion");
filterEnchantingLegion:ParseTSM(AnsEnchanting.Legion);
filterEnchantingLegion.isSub = true;
local filterEnchantingBFA = AnsFilter:New("BFA");
filterEnchantingBFA:ParseTSM(AnsEnchanting.BFA);
filterEnchantingBFA.isSub = true;

filterEnchanting.subfilters[1] = filterEnchantingBFA;
filterEnchanting.subfilters[2] = filterEnchantingLegion;
filterEnchanting.subfilters[3] = filterEnchantingBasic;

local filterPets = AnsFilter:New("Pets");
filterPets.subfilters = {};

local filterPetsBasic = AnsFilter:New("Pre-BFA");
filterPetsBasic:ParseTSM(AnsPets.Basic);
filterPetsBasic.isSub = true;
local filterPetsBFA = AnsFilter:New("BFA");
filterPetsBFA:ParseTSM(AnsPets.BFA);
filterPetsBFA.isSub = true;

filterPets.subfilters[1] = filterPetsBFA;
filterPets.subfilters[2] = filterPetsBasic;

local filterMounts = AnsFilter:New("Mounts");
filterMounts.subfilters = {};
local filterMountsBasic = AnsFilter:New("Pre-BFA");
filterMountsBasic:ParseTSM(AnsMounts.Basic);
filterMountsBasic.isSub = true;
local filterMountsBFA = AnsFilter:New("BFA");
filterMountsBFA:ParseTSM(AnsMounts.BFA);
filterMountsBFA.isSub = true;

filterMounts.subfilters[1] = filterMountsBFA;
filterMounts.subfilters[2] = filterMountsBasic;

local allFilterTotal = 6;

--- keep track of selections
AnsFilterSelected[1] = false;
AnsFilterSelected[2] = false;
AnsFilterSelected[3] = false;
AnsFilterSelected[4] = false;
AnsFilterSelected[5] = false;
AnsFilterSelected[6] = false;
AnsFilterSelected[7] = false;
AnsFilterSelected[8] = false;

--- set predefined filters
AnsFilterList[1] = filterArmor;
AnsFilterList[2] = filterWeapon;
AnsFilterList[3] = filterConsumable;
AnsFilterList[4] = filterContainer;
AnsFilterList[5] = filterRecipes;

AnsFilterList[6] = filterHerbs;

local i;
local ftotal = #filterHerbs.subfilters;

for i = 1, ftotal do
    allFilterTotal = allFilterTotal + 1;
    AnsFilterList[allFilterTotal] = filterHerbs.subfilters[i]; 
    AnsFilterSelected[allFilterTotal] = false;
end

allFilterTotal = allFilterTotal + 1;
AnsFilterList[allFilterTotal] = filterOre;
AnsFilterSelected[allFilterTotal] = false;

ftotal = #filterOre.subfilters;

for i = 1, ftotal do
    allFilterTotal = allFilterTotal + 1;
    AnsFilterList[allFilterTotal] = filterOre.subfilters[i];
    AnsFilterSelected[allFilterTotal] = false;
end

allFilterTotal = allFilterTotal + 1;
AnsFilterList[allFilterTotal] = filterEnchanting;
AnsFilterSelected[allFilterTotal] = false;

ftotal = #filterEnchanting.subfilters;

for i = 1, ftotal do
    allFilterTotal = allFilterTotal + 1;
    AnsFilterList[allFilterTotal] = filterEnchanting.subfilters[i];
    AnsFilterSelected[allFilterTotal] = false;
end

allFilterTotal = allFilterTotal + 1;
AnsFilterList[allFilterTotal] = filterCloth;
AnsFilterSelected[allFilterTotal] = false;

ftotal = #filterCloth.subfilters;

for i = 1, ftotal do
    allFilterTotal = allFilterTotal + 1;
    AnsFilterList[allFilterTotal] = filterCloth.subfilters[i];
    AnsFilterSelected[allFilterTotal] = false;
end

allFilterTotal = allFilterTotal + 1;
AnsFilterList[allFilterTotal] = filterLeather;
AnsFilterSelected[allFilterTotal] = false;

ftotal = #filterLeather.subfilters;

for i = 1, ftotal do
    allFilterTotal = allFilterTotal + 1;
    AnsFilterList[allFilterTotal] = filterLeather.subfilters[i];
    AnsFilterSelected[allFilterTotal] = false;
end

allFilterTotal = allFilterTotal + 1;
AnsFilterList[allFilterTotal] = filterPets;
AnsFilterSelected[allFilterTotal] = false;

ftotal = #filterPets.subfilters;

for i = 1, ftotal do
    allFilterTotal = allFilterTotal + 1;
    AnsFilterList[allFilterTotal] = filterPets.subfilters[i];
    AnsFilterSelected[allFilterTotal] = false;
end

allFilterTotal = allFilterTotal + 1;
AnsFilterList[allFilterTotal] = filterMounts;
AnsFilterSelected[allFilterTotal] = false;

ftotal = #filterMounts.subfilters;

for i = 1, ftotal do
    allFilterTotal = allFilterTotal + 1;
    AnsFilterList[allFilterTotal] = filterMounts.subfilters[i];
    AnsFilterSelected[allFilterTotal] = false;
end