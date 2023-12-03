-- we will list these by the following criteria
    -- common
    -- uncommon
    -- rare
    -- epic
    -- legendary

-- this is all gathered from https://classic.wowhead.com/items/quality:1?filter=92:166:186;1:8:2;0:0:0
    -- Adjust the filter as needed based on the above critera
-- then run the following scrape code
-- the wowhead listviewitems has a maximum of 1000 entries
-- so you must filter down below 1000 total found
-- for (i=0; i<listviewitems.length; i++) if (listviewitems[i].bonustrees) listviewitems[i].bonustrees.sort(); for (i=0; i<listviewitems.length; i++) if (listviewitems[i].buyprice) console.log("[\"i:"+listviewitems[i].id+(listviewitems[i].bonustrees ? ":" + listviewitems[i].bonustrees.length + ":" + listviewitems[i].bonustrees.join(":") : "") +"\"] = " + listviewitems[i].buyprice + ",  -- "+listviewitems[i].name);


local Ans = select(2, ...);
local Utils = Ans.Utils;
local Vendor = Utils.IsClassicEra() and {

} or nil;

Ans.Data.Vendor.Cata = Vendor;