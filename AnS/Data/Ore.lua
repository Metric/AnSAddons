local Ans = select(2, ...);
local Utils = Ans.Utils;
local Ore = {};

Ore.children = {
    {
        id = Utils:Guid(),
        children = {},
        name = "BFA",
        ids = "i:152513,i:152512,i:152579,i:168185",
    },
    {
        id = Utils:Guid(),
        children = {},
        name = "Legion",
        ids = "i:151564,i:123919,i:123918,i:124444",
    },
    {
        id = Utils:Guid(),
        children = {},
        name = "Warlords",
        ids = "i:109118,i:109119",
    },
    {
        id = Utils:Guid(),
        children = {},
        name = "Mists",
        ids = "i:72094,i:72103,i:72092,i:72093",
    },
    {
        id = Utils:Guid(),
        children = {},
        name = "Cata",
        ids = "i:52185,i:53038,i:52183",
    },
    {
        id = Utils:Guid(),
        children = {},
        name = "Wrath",
        ids = "i:36910,i:36912,i:36909",
    },
    {
        id = Utils:Guid(),
        children = {},
        name = "BC",
        ids = "i:23426,i:23427,i:23425,i:23424",
    },
    {
        id = Utils:Guid(),
        children = {},
        name = "Old",
        ids = "i:11370,i:3858,i:10620,i:7911,i:2772,i:2776,i:2771,i:2775,i:2770",
    }
};

Ore.name = "Ore";
Ore.ids = "";
Ore.id = Utils:Guid();

tinsert(Ans.Data, Ore);