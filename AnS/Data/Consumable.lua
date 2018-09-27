local Ans = select(2, ...);
local Consumable = {};

Consumable.name = "Consumable";
Consumable.ids = "";
Consumable.children = {};
Consumable.useMaxPPU = true;
Consumable.useMinLevel = false;
Consumable.useQuality = true;
Consumable.useMinStack = true;
Consumable.usePercent = true;
Consumable.priceFn = "";
Consumable.types = "consumable";
Consumable.subtypes = "";

tinsert(Ans.Data, Consumable);