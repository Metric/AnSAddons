local Ans = select(2, ...);
local Utils = Ans.Utils;
local Cloth = {};
Cloth.children = {
    {
        id = Utils:Guid(),
        children = {},
        name = "BFA",
        ids = "i:152577,i:158378,i:152576,i:167738",
    },
    {
        id = Utils:Guid(),
        children = {},
        name = "Legion",
        ids = "i:127004,i:124437,i:151567",
    },
    {
        id = Utils:Guid(),
        children = {},
        name = "Pre-Legion", 
        ids = "i:2589,i:2592,i:4306,i:4338,i:14047,i:14256,i:14342,i:21877,i:33470,i:24272,i:24271,i:21845,i:41593,i:41594,i:41595,i:53010,i:72988,i:111557",
    }
};

Cloth.name = "Cloth";
Cloth.ids = "";
Cloth.id = Utils:Guid();

tinsert(Ans.Data, Cloth);