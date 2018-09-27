local Ans = select(2, ...);
local Enchanting = {};

Enchanting.children = {
    {
        name = "BFA",
        ids = "i:152877,i:152876,i:152875",
        useMaxPPU = true,
        useMinLevel = false,
        useQuality = true,
        useMinStack = true,
        usePercent = true,
        priceFn = "",
        types = "",
        subtypes = ""
    },
    {
        name = "Legion",
        ids = "i:124442,i:124441,i:124440",
        useMaxPPU = true,
        useMinLevel = false,
        useQuality = true,
        useMinStack = true,
        usePercent = true,
        priceFn = "",
        types = "",
        subtypes = ""
    },
    {
        name = "Pre-Legion",
        ids = "i:109693,i:115502,i:80433,i:102218,i:94289,i:74252,i:52722,i:52720,i:105718,i:52719,i:52718,i:52555,i:34057,i:34052,i:34053,i:34055,i:34056,i:34054,i:22450,i:22446,i:22447,i:22445,i:14344,i:16203,i:14343,i:16202,i:16204,i:10939,i:10938,i:10940",
        useMaxPPU = true,
        useMinLevel = false,
        useQuality = true,
        useMinStack = true,
        usePercent = true,
        priceFn = "",
        types = "",
        subtypes = ""
    }
};

Enchanting.name = "Enchanting";
Enchanting.ids = "";
Enchanting.useMaxPPU = true;
Enchanting.useMinLevel = false;
Enchanting.useQuality = true;
Enchanting.useMinStack = true;
Enchanting.usePercent = true;
Enchanting.priceFn = "";
Enchanting.types = "";
Enchanting.subtypes = "";

tinsert(Ans.Data, Enchanting);