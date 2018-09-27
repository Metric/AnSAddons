local Ans = select(2, ...);
local Armor = {};

Armor.name = "Armor"
Armor.children = {};
Armor.ids = "";
Armor.useMaxPPU = true;
Armor.useMinLevel = true;
Armor.useQuality = true;
Armor.useMinStack = true;
Armor.usePercent = true;
Armor.priceFn = "";
Armor.types = "armor";
Armor.subtypes = "";

tinsert(Ans.Data, Armor);