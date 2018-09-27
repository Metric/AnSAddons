local Ans = select(2, ...);
local Mounts = {};

Ans.Data.Mounts = Mounts;

Mounts.children = {
    {
        name = "BFA",
        ids = "i:163576,i:163574,i:163575,i:163573,i:163131",
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
        name = "Pre-BFA",
        ids = "i:45067,i:137686,i:82453,i:83088,i:83089,i:83090,i:83087,i:65891,i:95416,i:41508,i:44413,i:67151,i:34061,i:49286,i:54069,i:68008,i:68825,i:72582,i:79771,i:93671,i:34060,i:44554,i:49285,i:87250,i:87251,i:49282,i:49290,i:54068,i:116794,i:128311,i:128671,i:128670,i:49284,i:52200,i:69228,i:71718,i:72145,i:72146,i:72575,i:143752,i:49283,i:129139",
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

Mounts.name = "Mounts";
Mounts.ids  = "";
Mounts.useMaxPPU = true;
Mounts.useMinLevel = false;
Mounts.useQuality = true;
Mounts.useMinStack = true;
Mounts.usePercent = true;
Mounts.priceFn = "";
Mounts.types = "";
Mounts.subtypes = "";

tinsert(Ans.Data, Mounts);