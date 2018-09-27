local Ans = select(2, ...);
local Weapons = {};

Weapons.name = "Weapons";
Weapons.ids = "";
Weapons.children = {};
Weapons.useMaxPPU = true;
Weapons.useMinLevel = true;
Weapons.useQuality = true;
Weapons.useMinStack = true;
Weapons.usePercent = true;
Weapons.priceFn = "";
Weapons.types = "weapon";
Weapons.subtypes = "";

tinsert(Ans.Data, Weapons);