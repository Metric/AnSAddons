local Ans = select(2, ...);
local Utils = Ans.Utils;
local Enchanting = {};

Enchanting.children = {
    {
        --gathered from wowhead with:
        -- var s = []; for (i=0; i<listviewitems.length; i++) if (listviewitems[i].bonustrees) listviewitems[i].bonustrees.sort(); for (i=0; i<listviewitems.length; i++) s.push("i:"+listviewitems[i].id); console.log(s.join(","));
        id = Utils.Guid(),
        children = {},
        name = "SL",
        ids = "i:172232,i:172230,i:172231",
    },
    {
        id = Utils.Guid(),
        children = {},
        name = "BFA",
        ids = "i:152877,i:152876,i:152875",
    },
    {
        id = Utils.Guid(),
        children = {},
        name = "Legion",
        ids = "i:124442,i:124441,i:124440",
    },
    {
        id = Utils.Guid(),
        children = {},
        name = "Pre-Legion",
        ids = "i:109693,i:115502,i:80433,i:102218,i:94289,i:74252,i:52722,i:52720,i:105718,i:52719,i:52718,i:52555,i:34057,i:34052,i:34053,i:34055,i:34056,i:34054,i:22450,i:22446,i:22447,i:22445,i:14344,i:16203,i:14343,i:16202,i:16204,i:10939,i:10938,i:10940",
    },
};

Enchanting.name = "Enchanting";
Enchanting.ids = "";
Enchanting.id = Utils.Guid();

tinsert(Ans.Data, Enchanting);