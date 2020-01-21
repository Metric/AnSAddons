local Ans = select(2, ...);
local Leather = {};

Leather.children = {
    {
        name = "BFA",
        ids = "i:152541,i:154164,i:154165,i:153050,i:153051,i:154722,i:152542,i:168649",
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
        ids = "i:124116,i:136533,i:136534,i:110609,i:110611,i:124113,i:124115",
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
        ids = "i:110610,i:72163,i:112157,i:79101,i:72120,i:72162,i:52982,i:112155,i:112156,i:52979,i:52976,i:52977,i:38557,i:38561,i:112158,i:44128,i:33567,i:33568,i:38558,i:112182,i:25707,i:15410,i:15414,i:17012,i:21887,i:25649,i:25699,i:25700,i:25708,i:29539,i:29547,i:29548,i:112185,i:15408,i:15416,i:8171,i:15412,i:15415,i:15417,i:8170,i:15419,i:8154,i:8165,i:4304,i:8169,i:8167,i:4234,i:4235,i:2319,i:4232,i:783,i:2318,i:2934,i:6470,i:6471,i:7286,i:7392",
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

Leather.name = "Leather";
Leather.ids = "";
Leather.useMaxPPU = true;
Leather.useMinLevel = false;
Leather.useQuality = true;
Leather.useMinStack = true;
Leather.usePercent = true;
Leather.priceFn = "";
Leather.types = "";
Leather.subtypes = "";

tinsert(Ans.Data, Leather);