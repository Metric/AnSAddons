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
local Vendor = Utils.IsRetail() and {
    -- common --
    ["i:190452"] = 150000,  -- Primal Flux
    ["i:191474"] = 50000,  -- Draconic Vial
    ["i:192153"] = 11230,  -- Frigidfish
    ["i:192833"] = 20000,  -- Misshapen Filigree
    ["i:193890"] = 5,  -- Diced Meat
    ["i:194510"] = 20,  -- Iskaaran Harpoon
    ["i:194680"] = 37500,  -- Jerky Surprise
    ["i:194681"] = 37500,  -- Sugarwing Cupcake
    ["i:194683"] = 25000,  -- Buttermilk
    ["i:194684"] = 25000,  -- Azure Leywine
    ["i:194685"] = 25000,  -- Dragonspring Water
    ["i:194688"] = 37500,  -- Vorquin Filet
    ["i:194689"] = 37500,  -- Anchovy Crisps
    ["i:194690"] = 25000,  -- Horn o' Mead
    ["i:194691"] = 25000,  -- Artisanal Berry Juice
    ["i:194692"] = 25000,  -- Distilled Fish Juice
    ["i:194693"] = 25000,  -- Improvised Sushi
    ["i:194694"] = 25000,  -- Seasoned Hornswog Steak
    ["i:194695"] = 25000,  -- Ramloaf
    ["i:194784"] = 10000,  -- Glittering Parchment
    ["i:195455"] = 25000,  -- Argali Cheese
    ["i:195456"] = 25000,  -- Plains Flatbread
    ["i:195457"] = 25000,  -- Mammoth Jerky
    ["i:195459"] = 25000,  -- Argali Milk
    ["i:195462"] = 37500,  -- Fried Hornstrider Wings
    ["i:195463"] = 37500,  -- Seasoned Mudstomper Belly
    ["i:195466"] = 37500,  -- Frenzy and Chips
    ["i:196440"] = 32400,  -- Dragon Flight
    ["i:196540"] = 37500,  -- Broadhoof Tail Poutine
    ["i:196582"] = 37500,  -- Syrup-Drenched Toast
    ["i:196583"] = 37500,  -- Greenberry Toast
    ["i:196584"] = 25000,  -- Acorn Milk
    ["i:196585"] = 25000,  -- Plainswheat Pretzel
    ["i:197749"] = 1000,  -- Ohn'ahran Potato
    ["i:197750"] = 3000,  -- Three-Cheese Blend
    ["i:197751"] = 5000,  -- Pastry Packets
    ["i:197752"] = 12500,  -- Conveniently Packaged Ingredients
    ["i:197753"] = 30000,  -- Thaldraszian Cocoa Powder
    ["i:197847"] = 37500,  -- Gorloc Fin Soup
    ["i:197848"] = 37500,  -- Hearty Squash Stew
    ["i:197849"] = 25000,  -- Ancient Firewine
    ["i:197850"] = 37500,  -- Mammoth Dumpling
    ["i:197851"] = 25000,  -- Extra Crispy Mutton
    ["i:197852"] = 25000,  -- Goat Brisket
    ["i:197853"] = 37500,  -- Critter Kebab
    ["i:197854"] = 37500,  -- Enchanted Argali Tenderloin
    ["i:197855"] = 37500,  -- Explorer's Mix
    ["i:197856"] = 25000,  -- Cup o' Wakeup
    ["i:197857"] = 25000,  -- Swog Slurp
    ["i:197858"] = 25000,  -- Salt-Baked Scalebelly
    ["i:198043"] = 52500,  -- Stealthy Elven Port
    ["i:198047"] = 1500,  -- Kul Tiran Red
    ["i:198356"] = 37500,  -- Honey Snack
    ["i:198441"] = 37500,  -- Thunderspine Tenders
    ["i:198487"] = 10000,  -- Iridescent Water
    ["i:199918"] = 53529,  -- Honey Plum Tart
    ["i:199919"] = 43953,  -- Yak Milk Pudding
    ["i:200099"] = 37500,  -- M.R.E.
    ["i:200265"] = 53084,  -- Lucky Dragon's Claw
    ["i:200268"] = 93084,  -- Crumbling Elemental Stone
    ["i:200269"] = 350000,  -- Talisman of the Dragon Hoard
    ["i:200271"] = 380000,  -- Infallible Hornswog Ward
    ["i:200304"] = 25000,  -- Stored Dracthyr Rations
    ["i:200305"] = 25000,  -- Dracthyr Water Rations
    ["i:200619"] = 25000,  -- Scaralesh's Special
    ["i:200680"] = 32400,  -- Maruukai Mule
    ["i:200681"] = 32400,  -- Ohn Lite
    ["i:200855"] = 32400,  -- Tuskarr Port Wine
    ["i:200856"] = 32400,  -- Sideboat
    ["i:200860"] = 50000,  -- Draconic Stopper
    ["i:200871"] = 37500,  -- Steamed Scarab Steak
    ["i:201045"] = 37500,  -- Icecrown Bleu
    ["i:201046"] = 25000,  -- Dreamwarding Dripbrew
    ["i:201047"] = 37500,  -- Arcanostabilized Provisions
    ["i:201327"] = 500000,  -- Emerald Dreamtime
    ["i:201398"] = 37500,  -- Mogu Mozzarella
    ["i:201413"] = 37500,  -- Eternity-Infused Burrata
    ["i:201415"] = 37500,  -- Temporal Parmesan
    ["i:201416"] = 37500,  -- Black Empire Brunost
    ["i:201417"] = 37500,  -- Curding of Stratholme
    ["i:201419"] = 37500,  -- Apexis Asiago
    ["i:201428"] = 54800,  -- Quicksilver Sands
    ["i:201584"] = 50000,  -- Serevite Rod
    ["i:201697"] = 25000,  -- Coldarra Coldbrew
    ["i:201698"] = 25000,  -- Black Dragon Red Eye
    ["i:201721"] = 25000,  -- Life Fire Latte
    ["i:201725"] = 50000,  -- Flappuccino
    ["i:201813"] = 25000,  -- Spoiled Firewine
    ["i:201820"] = 37500,  -- Silithus Swiss
    ["i:201832"] = 325000,  -- Smudged Lens
    ["i:202265"] = 10000,  -- Wheel of Whelpwhisper Brie
    ["i:202266"] = 10000,  -- Bag of Spicy Pet Snacks
    ["i:202399"] = 10000,  -- Stuffed Doll
    ["i:202400"] = 10000,  -- Soothing Incense
    ["i:202644"] = 100000,  -- Whelp's First Hourglass
    ["i:203386"] = 10000,  -- Box of Leapmaize Crackers
    ["i:203432"] = 10000,  -- Bag of Spicy Pet Snacks
    ["i:203433"] = 10000,  -- Wheel of Whelpwhisper Brie
    ["i:203443"] = 10000,  -- Box of Leapmaize Crackers
    ["i:203445"] = 10000,  -- Stuffed Doll
    ["i:203446"] = 10000,  -- Soothing Incense
    ["i:203652"] = 500000,  -- Griftah's All-Purpose Embellishing Powder
    ["i:204729"] = 25000,  -- Freshly Squeezed Mosswater
    ["i:204730"] = 37500,  -- Grub Grub
    ["i:204790"] = 37500,  -- Strong Sniffin' Soup for Niffen
    ["i:204791"] = 1000,  -- Squishy Snack
    ["i:204868"] = 100000,  -- Pre-Made Pie Crust
    ["i:205417"] = 25000,  -- Fungishine
    ["i:205692"] = 37500,  -- Stellaviatori Soup
    ["i:205693"] = 37500,  -- Latticed Stinkhorn
    ["i:205793"] = 37500,  -- Skitter Souf-fly
    ["i:205794"] = 37500,  -- Beetle Juice
    ["i:206521"] = 10,  -- Single Black Coffee
    ["i:206523"] = 10,  -- Five-Eon Energy
    ["i:206524"] = 10,  -- Eonized Latte

    -- uncommon --
    ["i:202027"] = 1000,  -- Fresh Talbuk Steak
    ["i:202028"] = 2000,  -- Southfury Salmon
    ["i:202029"] = 300,  -- Isle Lemon
    ["i:202030"] = 3000,  -- Ground Gorgrond Pepper
    ["i:202706"] = 500,  -- Zandali Piri Piri
    ["i:202707"] = 500,  -- Un'goro Coconut
    ["i:204793"] = 500,  -- Suja's Sweet Salt

    -- rare --
    ["i:201330"] = 1,  -- Set Keystone Map: Shadowmoon Burial Grounds
    ["i:201334"] = 1,  -- Set Keystone Map: Temple of the Jade Serpent
    ["i:201344"] = 1,  -- Set Keystone Map: Algeth'ar Academy
    ["i:201345"] = 1,  -- Set Keystone Map: Halls of Infusion
    ["i:201346"] = 1,  -- Set Keystone Map: Brackenhide Hollow
    ["i:201347"] = 1,  -- Set Keystone Map: The Azure Vault
    ["i:201348"] = 1,  -- Set Keystone Map: The Nokhud Offensive
    ["i:201349"] = 1,  -- Set Keystone Map: Neltharus
    ["i:201350"] = 1,  -- Set Keystone Map: Ruby Life Pools
    ["i:201351"] = 1,  -- Set Keystone Map: Uldaman: Legacy of Tyr
    ["i:201834"] = 1,  -- Add Keystone Affix: Thundering
    ["i:202031"] = 10000,  -- Farahlon Fenugreek
    ["i:202046"] = 503084,  -- Lucky Tortollan Charm
    ["i:205933"] = 1,  -- Add Keystone Affix: Entangling
    ["i:205934"] = 1,  -- Add Keystone Affix: Afflicted
    ["i:205935"] = 1,  -- Add Keystone Affix: Incorporeal
    ["i:205993"] = 1,  -- Set Keystone Map: The Vortex Pinnacle

    -- epic --
    ["i:201410"] = 1200000,  -- Powerful Purple Thing

    --

} or nil;

Ans.Data.Vendor.Dragon = Vendor;