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
    ["i:172056"] = 50000,  -- Medley of Transplanar Spices
    ["i:172057"] = 37500,  -- Inconceivably Aged Vinegar
    ["i:172058"] = 45000,  -- Smuggled Azerothian Produce
    ["i:172059"] = 42500,  -- Rich Grazer Milk
    ["i:173038"] = 22000,  -- Lost Sole Bait
    ["i:173039"] = 22000,  -- Iridescent Amberjack Bait
    ["i:173040"] = 22000,  -- Silvergill Pike Bait
    ["i:173041"] = 22000,  -- Pocked Bonefish Bait
    ["i:173042"] = 22000,  -- Spinefin Piranha Bait
    ["i:173043"] = 22000,  -- Elysian Thade Bait
    ["i:173060"] = 5000,  -- Aerated Water
    ["i:173759"] = 25000,  -- Candied Brightbark
    ["i:173760"] = 37500,  -- Sylberry Snowcake
    ["i:173761"] = 25000,  -- Glazed Glowberries
    ["i:173762"] = 25000,  -- Flask of Ardendew
    ["i:173859"] = 37500,  -- Ethereal Pomegranate
    ["i:174281"] = 25000,  -- Purified Skyspring Water
    ["i:174282"] = 25000,  -- Airy Ciabatta
    ["i:174283"] = 37500,  -- Stygian Stew
    ["i:174284"] = 37500,  -- Empyrean Fruit Salad
    ["i:174285"] = 25000,  -- Candied Walnuts
    ["i:175069"] = 200,  -- Theater Ticket
    ["i:175095"] = 4000,  -- Book of Tickets
    ["i:175886"] = 5000,  -- Dark Parchment
    ["i:177040"] = 37500,  -- Ambroria Dew
    ["i:177043"] = 25000,  -- Reaped Larion Flank
    ["i:177061"] = 5000,  -- Twilight Bark
    ["i:177062"] = 110000,  -- Penumbra Thread
    ["i:178216"] = 25000,  -- Grilled Slumbershrooms
    ["i:178217"] = 37500,  -- Azurebloom Tea
    ["i:178218"] = 32400,  -- Wintermelon Brandy
    ["i:178219"] = 32400,  -- Mulled Faewine
    ["i:178220"] = 32400,  -- Dewdrop Ale
    ["i:178221"] = 32400,  -- Torchberry Wine
    ["i:178222"] = 37500,  -- Honeyplum Pie
    ["i:178223"] = 25000,  -- Poached Strider Egg
    ["i:178224"] = 37500,  -- Steamed Gorm Tail
    ["i:178225"] = 37500,  -- Wild Hunter's Stew
    ["i:178226"] = 25000,  -- Charred Runeflank
    ["i:178227"] = 37500,  -- Midnight Starpepper
    ["i:178228"] = 25000,  -- Glittersnap Snowpeas
    ["i:178247"] = 37500,  -- Ripe Wintermelon
    ["i:178252"] = 25000,  -- Torchberry Bundle
    ["i:178518"] = 340,  -- Crypt-Aged Ale
    ["i:178526"] = 100000,  -- Lost Cryptkeeper's Ring
    ["i:178534"] = 25000,  -- Corpini Slurry
    ["i:178535"] = 37500,  -- Suspicious Slime Shot
    ["i:178536"] = 37500,  -- Tauralus Bone Marrow
    ["i:178537"] = 25000,  -- Hair-Trussed Fungi
    ["i:178538"] = 25000,  -- Beetle Juice
    ["i:178539"] = 37500,  -- Lukewarm Tauralus Milk
    ["i:178540"] = 37500,  -- Delectable Dirt Dessert
    ["i:178541"] = 25000,  -- Roasted Marrow Bones
    ["i:178542"] = 25000,  -- Cranial Concoction
    ["i:178544"] = 25000,  -- Dubious Cheese Platter
    ["i:178545"] = 37500,  -- Bone Apple Tea
    ["i:178546"] = 37500,  -- Questionable Meat Product
    ["i:178547"] = 25000,  -- Questionable Fried Poultry
    ["i:178548"] = 37500,  -- Tea Bones
    ["i:178549"] = 25000,  -- Boiled Meat
    ["i:178550"] = 37500,  -- Tenebrous Truffle
    ["i:178552"] = 37500,  -- Blood Oranges
    ["i:178786"] = 35000,  -- Lusterwheat Flour
    ["i:178891"] = 50000,  -- Elysian Thread
    ["i:178900"] = 50000,  -- Death Pepper Decay
    ["i:179011"] = 37500,  -- Batloaf
    ["i:179012"] = 37500,  -- Mirecrawler Goulash
    ["i:179013"] = 37500,  -- Smoked Muckfish
    ["i:179014"] = 37500,  -- Marbled Gorger Steak
    ["i:179015"] = 37500,  -- Garlic Spider Legs
    ["i:179016"] = 37500,  -- Cottage Cheese
    ["i:179017"] = 37500,  -- Telemea
    ["i:179018"] = 37500,  -- Skullboar Chop
    ["i:179019"] = 37500,  -- Barbequed Dredwing
    ["i:179020"] = 37500,  -- Garlic Clove
    ["i:179021"] = 25000,  -- Rosy Sweet Pepper
    ["i:179022"] = 25000,  -- Clearleaf Cabbage
    ["i:179023"] = 37500,  -- Rhubarb Stalks
    ["i:179025"] = 25000,  -- Odorous Rice
    ["i:179026"] = 25000,  -- Evernight Porridge
    ["i:179166"] = 25000,  -- Night Harvest Rolls
    ["i:179267"] = 25000,  -- Endmire Glowcap
    ["i:179268"] = 37500,  -- Banewood Penny Bun
    ["i:179269"] = 37500,  -- Dusk Almond Mousse
    ["i:179270"] = 37500,  -- Shadeskin Plum
    ["i:179271"] = 25000,  -- Dredhollow Apple
    ["i:179272"] = 25000,  -- Fearstalker's Delight
    ["i:179273"] = 25000,  -- Darkhound Tenderloin
    ["i:179274"] = 25000,  -- Mutton Drob
    ["i:179275"] = 25000,  -- Cabbage Wrapped Minced Mite
    ["i:179276"] = 25000,  -- Chimaera Tripe Soup
    ["i:179277"] = 32400,  -- Shadeberry Shandy
    ["i:179278"] = 32400,  -- Shadeskin Brandy
    ["i:179279"] = 32400,  -- Jug of Tuica Moonshine
    ["i:179281"] = 37500,  -- Pridefall Borscht
    ["i:179283"] = 37500,  -- Millet Wafers
    ["i:179307"] = 32400,  -- Drab of Tuica Moonshine
    ["i:179992"] = 37500,  -- Shadespring Water
    ["i:179993"] = 25000,  -- Infused Muck Water
    ["i:180409"] = 32400,  -- Crimson Altar Wine
    ["i:180411"] = 32400,  -- Darkhaven Stout
    ["i:180429"] = 25000,  -- Hand-Formed Fleshbread
    ["i:180430"] = 25000,  -- Finger Food
    ["i:180732"] = 10000,  -- Rune Etched Vial
    ["i:180733"] = 90000,  -- Luminous Flux
    ["i:182118"] = 32400,  -- Sour Nightcap
    ["i:182119"] = 32400,  -- Bloody Marileth
    ["i:182120"] = 32400,  -- The Lich's Heart
    ["i:182121"] = 32400,  -- Corpse Reanimator
    ["i:182122"] = 32400,  -- Ardenwood Vermouth
    ["i:182123"] = 32400,  -- Aged Agrave Tequila
    ["i:182363"] = 200000,  -- Enchanted Trickster Dust
    ["i:183597"] = 25000,  -- Fleshstitched Cookie
    ["i:183950"] = 90000,  -- Distilled Death Extract
    ["i:183951"] = 90000,  -- Immortal Shard
    ["i:183952"] = 90000,  -- Machinist's Oil
    ["i:183953"] = 90000,  -- Sealing Wax
    ["i:183954"] = 90000,  -- Malleable Wire
    ["i:183955"] = 90000,  -- Curing Salt
    ["i:184049"] = 100000,  -- Counterfeit Luckydo
    ["i:184050"] = 52500,  -- Malleable Mesh
    ["i:184051"] = 155000,  -- Stitched Lich Effigy
    ["i:184201"] = 25000,  -- Slushy Water
    ["i:184202"] = 25000,  -- Freeze-Dried Salted Meat
    ["i:184281"] = 37500,  -- Muckfrosty
    ["i:184283"] = 32400,  -- Dusk No. 1
    ["i:186684"] = 8713,  -- Memories of Brighter Times
    ["i:187712"] = 25000,  -- Precursor Placoderm Bait
    ["i:187812"] = 2500000,  -- Empty Kettle
    ["i:187911"] = 25000,  -- Sable "Soup"
    ["i:190880"] = 37500,  -- Catalyzed Apple Pie
    ["i:190881"] = 37500,  -- Circle of Subsistence
    ["i:190936"] = 37500,  -- Restorative Flow

    -- uncommon --
    ["i:173168"] = 10000,  -- Laestrite Setting
    ["i:180377"] = 1052400,  -- Red Rum
    ["i:182653"] = 11187,  -- Larion Treats
    ["i:184341"] = 50000,  -- Nibbled Portalbello
    ["i:184342"] = 50000,  -- Large Portalbello
    ["i:184343"] = 50000,  -- Healthy Portalbello
    ["i:184344"] = 50000,  -- Withered Portalbello
    ["i:184345"] = 50000,  -- Glowing Portalbello
    ["i:184346"] = 50000,  -- Damp Portalbello
    ["i:184347"] = 50000,  -- Slender Portalbello

    -- rare --
    ["i:178787"] = 1250000,  -- Orboreal Shard
    ["i:183803"] = 1,  -- Add Keystone Affix: Prideful
    ["i:183947"] = 1,  -- Add Keystone Affix: Storming
    ["i:183948"] = 1,  -- Add Keystone Affix: Spiteful
    ["i:183949"] = 1,  -- Add Keystone Affix: Inspiring
    ["i:184340"] = 50000,  -- Root Cellar VIP Pass
    ["i:187524"] = 1,  -- Add Keystone Affix: Tormented
    ["i:188152"] = 1500000,  -- Gateway Control Shard
    ["i:189524"] = 1,  -- Set Keystone Level: 31
    ["i:189525"] = 1,  -- Set Keystone Level: 32
    ["i:189526"] = 1,  -- Set Keystone Level: 33
    ["i:189527"] = 1,  -- Set Keystone Level: 34
    ["i:189528"] = 1,  -- Set Keystone Level: 35
    ["i:189534"] = 1,  -- Add Keystone Affix: Infernal
    ["i:189545"] = 1,  -- Set Keystone Map: Tazavesh: Streets of Wonder
    ["i:189546"] = 1,  -- Set Keystone Map: Tazavesh: So'leah's Gambit
    ["i:190938"] = 1,  -- Add Keystone Affix: Encrypted
    ["i:193263"] = 1,  -- Add Keystone Affix: Shrouded
    ["i:193264"] = 1,  -- Set Keystone Map: Iron Docks
    ["i:193265"] = 1,  -- Set Keystone Map: Grimrail Depot
    ["i:200655"] = 1,  -- Set Keystone Level: 36
    ["i:200656"] = 1,  -- Set Keystone Level: 37
    ["i:200657"] = 1,  -- Set Keystone Level: 38
    ["i:200658"] = 1,  -- Set Keystone Level: 39
    ["i:200659"] = 1,  -- Set Keystone Level: 40

} or nil;

Ans.Data.Vendor.Shadow = Vendor;