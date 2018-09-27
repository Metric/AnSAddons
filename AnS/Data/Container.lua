local Ans = select(2, ...);
local Container = {};

Container.name = "Container";
Container.ids = "";
Container.children = {};
Container.useMaxPPU = true;
Container.useMinLevel = false;
Container.useQuality = true;
Container.useMinStack = true;
Container.usePercent = true;
Container.priceFn = "";
Container.types = "container";
Container.subtypes = "";

tinsert(Ans.Data, Container);