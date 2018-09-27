local Ans = select(2, ...);
local Recipes = {};

Recipes.name = "Recipes";
Recipes.ids = "";
Recipes.children = {};
Recipes.useMaxPPU = true;
Recipes.useMinLevel = false;
Recipes.useQuality = true;
Recipes.useMinStack = true;
Recipes.usePercent = true;
Recipes.priceFn = "";
Recipes.types = "recipe";
Recipes.subtypes = "";

tinsert(Ans.Data, Recipes);