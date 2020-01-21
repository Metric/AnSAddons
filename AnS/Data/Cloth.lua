local Ans = select(2, ...);
local Cloth = {};
Cloth.children = {
    {
        name = "BFA",
        ids = "i:152577,i:158378,i:152576,i:167738",
        useMaxPPU = true,
        useMinLevel = false,
        useQuality = true,
        useMinStack = true,
        usePercent = true,
        exactMatch = true,
        priceFn = "",
        types = "",
        subtypes = ""
    },
    {
        name = "Legion",
        ids = "i:127004,i:124437,i:151567",
        useMaxPPU = true,
        useMinLevel = false,
        useQuality = true,
        useMinStack = true,
        usePercent = true,
        exactMatch = true,
        priceFn = "",
        types = "",
        subtypes = ""
    },
    {
        name = "Pre-Legion", 
        ids = "i:2589,i:2592,i:4306,i:4338,i:14047,i:14256,i:14342,i:21877,i:33470,i:24272,i:24271,i:21845,i:41593,i:41594,i:41595,i:53010,i:72988,i:111557",
        useMaxPPU = true,
        useMinLevel = false,
        useQuality = true,
        useMinStack = true,
        usePercent = true,
        exactMatch = true,
        priceFn = "",
        types = "",
        subtypes = ""
    }
};

Cloth.name = "Cloth";
Cloth.ids = "";
Cloth.useMaxPPU = true;
Cloth.useMinLevel = false;
Cloth.useQuality = true;
Cloth.useMinStack = true;
Cloth.usePercent = true;
Cloth.priceFn = "";
Cloth.types = "";
Cloth.subtypes = "";

tinsert(Ans.Data, Cloth);