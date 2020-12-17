local Ans = select(2, ...);
local Utils = Ans.Utils;
local Config = Ans.Config;
local Sources = Ans.Sources;
local CraftingData = {};

Ans.Data.Crafting = CraftingData;

local SPELLS = {
	milling = 51005,
	prospect = 31252,
	disenchant = 13262,
};

CraftingData.SPELLS = SPELLS;

local DISENCHANT_INFO = {};
local PROSPECT_INFO = {};
local MILL_INFO = {};

-- From TSM so we can be consistent
if Utils.IsClassic() then
	DISENCHANT_INFO = {
		-- Dust
		["i:10940"] = { -- Strange Dust
			minLevel = 1,
			maxLevel = 20,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 5, maxItemLevel = 15, amountOfMats = 1.200},
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 16, maxItemLevel = 20, amountOfMats = 1.850},
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 21, maxItemLevel = 25, amountOfMats = 3.750},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 5, maxItemLevel = 15, amountOfMats = 0.300},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 16, maxItemLevel = 20, amountOfMats = 0.500},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 21, maxItemLevel = 25, amountOfMats = 0.750},
			},
		},
		["i:11083"] = { -- Soul Dust
			minLevel = 21,
			maxLevel = 30,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 26, maxItemLevel = 30, amountOfMats = 1.100},
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 31, maxItemLevel = 35, amountOfMats = 2.550},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 26, maxItemLevel = 30, amountOfMats = 0.300},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 31, maxItemLevel = 35, amountOfMats = 0.700},
			},
		},
		["i:11137"] = { -- Vision Dust
			minLevel = 31,
			maxLevel = 40,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 36, maxItemLevel = 40, amountOfMats = 1.100},
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 41, maxItemLevel = 45, amountOfMats = 2.550},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 36, maxItemLevel = 40, amountOfMats = 0.300},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 41, maxItemLevel = 45, amountOfMats = 0.700},
			},
		},
		["i:11176"] = { -- Dream Dust
			minLevel = 41,
			maxLevel = 50,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 46, maxItemLevel = 50, amountOfMats = 1.100},
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 51, maxItemLevel = 55, amountOfMats = 2.550},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 46, maxItemLevel = 50, amountOfMats = 0.300},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 51, maxItemLevel = 55, amountOfMats = 0.700},
			},
		},
		["i:16204"] = { -- Illusion Dust
			minLevel = 51,
			maxLevel = 60,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 56, maxItemLevel = 60, amountOfMats = 1.100},
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 61, maxItemLevel = 65, amountOfMats = 2.550},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 56, maxItemLevel = 60, amountOfMats = 0.300},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 61, maxItemLevel = 65, amountOfMats = 0.700},
			},
		},

		-- Essences
		["i:10938"] = { -- Lesser Magic Essence
			minLevel = 1,
			maxLevel = 10,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 5, maxItemLevel = 15, amountOfMats = 0.300},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 5, maxItemLevel = 15, amountOfMats = 1.200},
			},
		},
		["i:10939"] = { -- Greater Magic Essence
			minLevel = 11,
			maxLevel = 15,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 16, maxItemLevel = 20, amountOfMats = 0.300},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 16, maxItemLevel = 20, amountOfMats = 1.100},
			},
		},
		["i:10998"] = { -- Lesser Astral Essence
			minLevel = 16,
			maxLevel = 20,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 21, maxItemLevel = 25, amountOfMats = 0.200},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 21, maxItemLevel = 25, amountOfMats = 1.100},
			},
		},
		["i:11082"] = { -- Greater Astral Essence
			minLevel = 21,
			maxLevel = 25,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 26, maxItemLevel = 30, amountOfMats = 0.300},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 26, maxItemLevel = 30, amountOfMats = 1.100},
			},
		},
		["i:11134"] = { -- Lesser Mystic Essence
			minLevel = 26,
			maxLevel = 30,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 31, maxItemLevel = 35, amountOfMats = 0.300},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 31, maxItemLevel = 35, amountOfMats = 1.100},
			},
		},
		["i:11135"] = { -- Greater Mystic Essence
			minLevel = 31,
			maxLevel = 35,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 36, maxItemLevel = 40, amountOfMats = 0.300},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 36, maxItemLevel = 40, amountOfMats = 1.100},
			},
		},
		["i:11174"] = { -- Lesser Nether Essence
			minLevel = 36,
			maxLevel = 40,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 41, maxItemLevel = 45, amountOfMats = 0.300},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 41, maxItemLevel = 45, amountOfMats = 1.100},
			},
		},
		["i:11175"] = { -- Greater Nether Essence
			minLevel = 41,
			maxLevel = 45,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 46, maxItemLevel = 50, amountOfMats = 0.300},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 46, maxItemLevel = 50, amountOfMats = 1.100},
			},
		},
		["i:16202"] = { -- Lesser Eternal Essence
			minLevel = 46,
			maxLevel = 50,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 51, maxItemLevel = 55, amountOfMats = 0.300},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 51, maxItemLevel = 55, amountOfMats = 1.100},
			},
		},
		["i:16203"] = { -- Greater Eternal Essence
			minLevel = 51,
			maxLevel = 60,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 56, maxItemLevel = 60, amountOfMats = 0.300},
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 61, maxItemLevel = 65, amountOfMats = 0.500},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 56, maxItemLevel = 60, amountOfMats = 1.100},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 61, maxItemLevel = 65, amountOfMats = 1.850},
			},
		},

		-- Shards
		["i:10978"] = { -- Small Glimmering Shard
			minLevel = 1,
			maxLevel = 20,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 16, maxItemLevel = 20, amountOfMats = 0.050},
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 21, maxItemLevel = 25, amountOfMats = 0.100},
				{classId = LE_ITEM_CLASS_ARMOR, quality = 3, minItemLevel = 5, maxItemLevel = 25, amountOfMats = 1.000},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 16, maxItemLevel = 20, amountOfMats = 0.050},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 21, maxItemLevel = 25, amountOfMats = 0.100},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 3, minItemLevel = 5, maxItemLevel = 25, amountOfMats = 1.000},
			},
		},
		["i:11084"] = { -- Large Glimmering Shard
			minLevel = 21,
			maxLevel = 25,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 26, maxItemLevel = 30, amountOfMats = 0.050},
				{classId = LE_ITEM_CLASS_ARMOR, quality = 3, minItemLevel = 26, maxItemLevel = 30, amountOfMats = 1.000},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 26, maxItemLevel = 30, amountOfMats = 0.050},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 3, minItemLevel = 26, maxItemLevel = 30, amountOfMats = 1.000},
			},
		},
		["i:11138"] = { -- Small Glowing Shard
			minLevel = 26,
			maxLevel = 30,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 31, maxItemLevel = 35, amountOfMats = 0.050},
				{classId = LE_ITEM_CLASS_ARMOR, quality = 3, minItemLevel = 31, maxItemLevel = 35, amountOfMats = 1.000},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 31, maxItemLevel = 35, amountOfMats = 0.050},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 3, minItemLevel = 31, maxItemLevel = 35, amountOfMats = 1.000},
			},
		},
		["i:11139"] = { -- Large Glowing Shard
			minLevel = 31,
			maxLevel = 35,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 36, maxItemLevel = 40, amountOfMats = 0.050},
				{classId = LE_ITEM_CLASS_ARMOR, quality = 3, minItemLevel = 36, maxItemLevel = 40, amountOfMats = 1.000},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 36, maxItemLevel = 40, amountOfMats = 0.050},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 3, minItemLevel = 36, maxItemLevel = 40, amountOfMats = 1.000},
			},
		},
		["i:11177"] = { -- Small Radiant Shard
			minLevel = 36,
			maxLevel = 40,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 41, maxItemLevel = 45, amountOfMats = 0.050},
				{classId = LE_ITEM_CLASS_ARMOR, quality = 3, minItemLevel = 41, maxItemLevel = 45, amountOfMats = 1.000},
				{classId = LE_ITEM_CLASS_ARMOR, quality = 4, minItemLevel = 40, maxItemLevel = 45, amountOfMats = 3.000},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 41, maxItemLevel = 45, amountOfMats = 0.050},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 3, minItemLevel = 41, maxItemLevel = 45, amountOfMats = 1.000},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 4, minItemLevel = 40, maxItemLevel = 45, amountOfMats = 3.000},
			},
		},
		["i:11178"] = { -- Large Radiant Shard
			minLevel = 41,
			maxLevel = 45,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 46, maxItemLevel = 50, amountOfMats = 0.050},
				{classId = LE_ITEM_CLASS_ARMOR, quality = 3, minItemLevel = 46, maxItemLevel = 50, amountOfMats = 1.000},
				{classId = LE_ITEM_CLASS_ARMOR, quality = 4, minItemLevel = 46, maxItemLevel = 50, amountOfMats = 3.000},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 46, maxItemLevel = 50, amountOfMats = 0.050},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 3, minItemLevel = 46, maxItemLevel = 50, amountOfMats = 1.000},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 4, minItemLevel = 46, maxItemLevel = 50, amountOfMats = 3.000},
			},
		},
		["i:14343"] = { -- Small Brilliant Shard
			minLevel = 46,
			maxLevel = 50,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 51, maxItemLevel = 55, amountOfMats = 0.030},
				{classId = LE_ITEM_CLASS_ARMOR, quality = 3, minItemLevel = 51, maxItemLevel = 55, amountOfMats = 1.000},
				{classId = LE_ITEM_CLASS_ARMOR, quality = 4, minItemLevel = 51, maxItemLevel = 55, amountOfMats = 3.000},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 51, maxItemLevel = 55, amountOfMats = 0.030},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 3, minItemLevel = 51, maxItemLevel = 55, amountOfMats = 1.000},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 4, minItemLevel = 51, maxItemLevel = 55, amountOfMats = 3.000},
			},
		},
		["i:14344"] = { -- Large Brilliant Shard
			minLevel = 51,
			maxLevel = 60,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 56, maxItemLevel = 65, amountOfMats = 0.050},
				{classId = LE_ITEM_CLASS_ARMOR, quality = 3, minItemLevel = 56, maxItemLevel = 65, amountOfMats = 1.0},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 56, maxItemLevel = 65, amountOfMats = 0.050},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 3, minItemLevel = 56, maxItemLevel = 65, amountOfMats = 1.0},
			},
		},

		-- Crystals
		["i:20725"] = { -- Nexus Crystal
			minLevel = 51,
			maxLevel = 60,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 3, minItemLevel = 56, maxItemLevel = 65, amountOfMats = 0.005},
				{classId = LE_ITEM_CLASS_ARMOR, quality = 4, minItemLevel = 56, maxItemLevel = 60, amountOfMats = 1.000},
				{classId = LE_ITEM_CLASS_ARMOR, quality = 4, minItemLevel = 61, maxItemLevel = 95, amountOfMats = 1.666},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 3, minItemLevel = 56, maxItemLevel = 65, amountOfMats = 0.005},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 4, minItemLevel = 56, maxItemLevel = 60, amountOfMats = 1.000},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 4, minItemLevel = 61, maxItemLevel = 95, amountOfMats = 1.666},
			},
		},
	}
else
	DISENCHANT_INFO = {
		-- Dust
		["i:10940"] = { -- Strange Dust
			minLevel = 1,
			maxLevel = 12,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 1, maxItemLevel = 8, amountOfMats = 1.222},
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 9, maxItemLevel = 12, amountOfMats = 2.025},
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 13, maxItemLevel = 16, amountOfMats = 5.008},
				{classId = LE_ITEM_CLASS_ARMOR, quality = 3, minItemLevel = 5, maxItemLevel = 16, amountOfMats = 0.127},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 1, maxItemLevel = 8, amountOfMats = 0.302},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 9, maxItemLevel = 12, amountOfMats = 0.507},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 13, maxItemLevel = 16, amountOfMats = 0.753},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 3, minItemLevel = 5, maxItemLevel = 16, amountOfMats = 0.127},
			},
		},
		["i:16204"] = { -- Light Illusion Dust
			minLevel = 11,
			maxLevel = 21,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 17, maxItemLevel = 24, amountOfMats = 1.155},
				{classId = LE_ITEM_CLASS_ARMOR, quality = 3, minItemLevel = 17, maxItemLevel = 24, amountOfMats = 0.127},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 17, maxItemLevel = 24, amountOfMats = 0.344},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 3, minItemLevel = 17, maxItemLevel = 24, amountOfMats = 0.127},
			},
		},
		["i:156930"] = { -- Rich Illusion Dust
			minLevel = 20,
			maxLevel = 25,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 25, maxItemLevel = 29, amountOfMats = 1.155},
				{classId = LE_ITEM_CLASS_ARMOR, quality = 3, minItemLevel = 25, maxItemLevel = 29, amountOfMats = 0.127},
				{classId = LE_ITEM_CLASS_ARMOR, quality = 4, minItemLevel = 29, maxItemLevel = 30, amountOfMats = 0.900},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 25, maxItemLevel = 29, amountOfMats = 0.344},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 3, minItemLevel = 25, maxItemLevel = 29, amountOfMats = 0.127},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 4, minItemLevel = 29, maxItemLevel = 30, amountOfMats = 0.900},
			},
		},
		["i:22445"] = { -- Arcane Dust
			minLevel = 24,
			maxLevel = 27,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 30, maxItemLevel = 31, amountOfMats = 1.933},
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 32, maxItemLevel = 33, amountOfMats = 2.655},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 30, maxItemLevel = 31, amountOfMats = 0.750},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 32, maxItemLevel = 33, amountOfMats = 0.787},
			},
		},
		["i:34054"] = { -- Infinite Dust
			minLevel = 26,
			maxLevel = 30,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 32, maxItemLevel = 33, amountOfMats = 1.933},
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 34, maxItemLevel = 35, amountOfMats = 4.155},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 32, maxItemLevel = 33, amountOfMats = 0.562},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 34, maxItemLevel = 35, amountOfMats = 1.200},
			},
		},
		["i:52555"] = { -- Hypnotic Dust
			minLevel = 29,
			maxLevel = 32,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 36, maxItemLevel = 36, amountOfMats = 1.556},
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 37, maxItemLevel = 37, amountOfMats = 2.628},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 36, maxItemLevel = 36, amountOfMats = 0.510},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 37, maxItemLevel = 37, amountOfMats = 0.864},
			},
		},
		["i:74249"] = { -- Spirit Dust
			minLevel = 31,
			maxLevel = 35,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 38, maxItemLevel = 38, amountOfMats = 2.285},
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 39, maxItemLevel = 39, amountOfMats = 3.135},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 38, maxItemLevel = 38, amountOfMats = 2.245},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 39, maxItemLevel = 39, amountOfMats = 3.560},
			},
		},
		["i:109693"] = { -- Draenic Dust
			minLevel = 35,
			maxLevel = 40,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 40, maxItemLevel = 44, amountOfMats = 2.600},
				{classId = LE_ITEM_CLASS_ARMOR, quality = 3, minItemLevel = 40, maxItemLevel = 44, amountOfMats = 5.810},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 40, maxItemLevel = 44, amountOfMats = 2.600},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 3, minItemLevel = 40, maxItemLevel = 44, amountOfMats = 6.220},
			},
		},
		["i:124440"] = { -- Arkhana
			minLevel = 40,
			maxLevel = 45,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 45, maxItemLevel = 48, amountOfMats = 4.750},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 45, maxItemLevel = 48, amountOfMats = 4.750},
			},
		},
		["i:152875"] = { -- Gloom Dust
			minLevel = 45,
			maxLevel = 50,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 49, maxItemLevel = 52, amountOfMats = 3.600},
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 53, maxItemLevel = 58, amountOfMats = 6.500},
				{classId = LE_ITEM_CLASS_ARMOR, quality = 3, minItemLevel = 51, maxItemLevel = 84, amountOfMats = 1.425},
				{classId = LE_ITEM_CLASS_ARMOR, quality = 4, minItemLevel = 58, maxItemLevel = 100, amountOfMats = 1.000},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 49, maxItemLevel = 52, amountOfMats = 3.600},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 53, maxItemLevel = 58, amountOfMats = 6.500},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 3, minItemLevel = 51, maxItemLevel = 84, amountOfMats = 1.425},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 4, minItemLevel = 58, maxItemLevel = 100, amountOfMats = 1.000},
			},
		},
		["i:172230"] = { -- Soul Dust
			minLevel = 50,
			maxLevel = 60,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 85, maxItemLevel = 375, amountOfMats = 2.000},
				{classId = LE_ITEM_CLASS_ARMOR, quality = 3, minItemLevel = 85, maxItemLevel = 375, amountOfMats = 1.400},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 85, maxItemLevel = 375, amountOfMats = 2.500},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 3, minItemLevel = 85, maxItemLevel = 375, amountOfMats = 1.400},
			},
		},

		-- Essences
		["i:10938"] = { -- Lesser Magic Essence
			minLevel = 1,
			maxLevel = 7,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 1, maxItemLevel = 8, amountOfMats = 0.303},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 1, maxItemLevel = 8, amountOfMats = 1.218},
			},
		},
		["i:10939"] = { -- Greater Magic Essence
			minLevel = 8,
			maxLevel = 11,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 9, maxItemLevel = 16, amountOfMats = 0.307},
				{classId = LE_ITEM_CLASS_ARMOR, quality = 3, minItemLevel = 5, maxItemLevel = 16, amountOfMats = 2.000},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 9, maxItemLevel = 16, amountOfMats = 1.217},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 3, minItemLevel = 5, maxItemLevel = 16, amountOfMats = 2.000},
			},
		},
		["i:16202"] = { -- Lesser Eternal Essence
			minLevel = 12,
			maxLevel = 20,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 17, maxItemLevel = 24, amountOfMats = 0.346},
				{classId = LE_ITEM_CLASS_ARMOR, quality = 3, minItemLevel = 17, maxItemLevel = 24, amountOfMats = 0.750},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 17, maxItemLevel = 24, amountOfMats = 1.302},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 3, minItemLevel = 17, maxItemLevel = 24, amountOfMats = 0.750},
			},
		},
		["i:16203"] = { -- Greater Eternal Essence
			minLevel = 20,
			maxLevel = 25,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 25, maxItemLevel = 29, amountOfMats = 0.346},
				{classId = LE_ITEM_CLASS_ARMOR, quality = 3, minItemLevel = 25, maxItemLevel = 29, amountOfMats = 0.650},
				{classId = LE_ITEM_CLASS_ARMOR, quality = 4, minItemLevel = 29, maxItemLevel = 30, amountOfMats = 2.800},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 25, maxItemLevel = 29, amountOfMats = 1.182},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 3, minItemLevel = 25, maxItemLevel = 29, amountOfMats = 0.650},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 4, minItemLevel = 29, maxItemLevel = 30, amountOfMats = 2.800},
			},
		},
		["i:22447"] = { -- Lesser Planar Essence
			minLevel = 24,
			maxLevel = 27,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 30, maxItemLevel = 30, amountOfMats = 0.562},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 30, maxItemLevel = 30, amountOfMats = 1.932},
			},
		},
		["i:22446"] = { -- Greater Planar Essence
			minLevel = 24,
			maxLevel = 27,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 31, maxItemLevel = 31, amountOfMats = 0.346},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 31, maxItemLevel = 31, amountOfMats = 1.170},
			},
		},
		["i:34056"] = { -- Lesser Cosmic Essence
			minLevel = 26,
			maxLevel = 30,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 32, maxItemLevel = 33, amountOfMats = 0.562},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 32, maxItemLevel = 33, amountOfMats = 1.932},
			},
		},
		["i:34055"] = { -- Greater Cosmic Essence
			minLevel = 26,
			maxLevel = 30,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 34, maxItemLevel = 35, amountOfMats = 0.346},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 34, maxItemLevel = 35, amountOfMats = 1.170},
			},
		},
		["i:52718"] = { -- Lesser Celestial Essence
			minLevel = 29,
			maxLevel = 32,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 36, maxItemLevel = 36, amountOfMats = 0.655},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 36, maxItemLevel = 36, amountOfMats = 1.932},
			},
		},
		["i:52719"] = { -- Greater Celestial Essence
			minLevel = 29,
			maxLevel = 32,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 37, maxItemLevel = 37, amountOfMats = 0.412},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 37, maxItemLevel = 37, amountOfMats = 1.157},
			},
		},
		["i:74250"] = { -- Mysterious Essence
			minLevel = 31,
			maxLevel = 34,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 38, maxItemLevel = 38, amountOfMats = 0.178},
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 39, maxItemLevel = 39, amountOfMats = 0.244},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 38, maxItemLevel = 38, amountOfMats = 0.178},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 39, maxItemLevel = 39, amountOfMats = 0.333},
			},
		},

		-- Shards
		["i:14343"] = { -- Small Brilliant Shard
			minLevel = 12,
			maxLevel = 21,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 17, maxItemLevel = 24, amountOfMats = 0.050},
				{classId = LE_ITEM_CLASS_ARMOR, quality = 3, minItemLevel = 17, maxItemLevel = 24, amountOfMats = 2.000},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 17, maxItemLevel = 24, amountOfMats = 0.050},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 3, minItemLevel = 17, maxItemLevel = 24, amountOfMats = 2.000},
			},
		},
		["i:14344"] = { -- Large Brilliant Shard
			minLevel = 20,
			maxLevel = 25,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 25, maxItemLevel = 29, amountOfMats = 0.050},
				{classId = LE_ITEM_CLASS_ARMOR, quality = 3, minItemLevel = 25, maxItemLevel = 29, amountOfMats = 2.000},
				{classId = LE_ITEM_CLASS_ARMOR, quality = 4, minItemLevel = 29, maxItemLevel = 30, amountOfMats = 3.500},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 25, maxItemLevel = 29, amountOfMats = 0.050},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 3, minItemLevel = 25, maxItemLevel = 29, amountOfMats = 2.000},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 4, minItemLevel = 29, maxItemLevel = 30, amountOfMats = 3.500},
			},
		},
		["i:22448"] = { -- Small Prismatic Shard
			minLevel = 23,
			maxLevel = 27,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 30, maxItemLevel = 30, amountOfMats = 0.033},
				{classId = LE_ITEM_CLASS_ARMOR, quality = 3, minItemLevel = 30, maxItemLevel = 30, amountOfMats = 1.030},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 30, maxItemLevel = 30, amountOfMats = 0.033},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 3, minItemLevel = 30, maxItemLevel = 30, amountOfMats = 1.030},
			},
		},
		["i:22449"] = { -- Large Prismatic Shard
			minLevel = 23,
			maxLevel = 27,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 31, maxItemLevel = 31, amountOfMats = 0.033},
				{classId = LE_ITEM_CLASS_ARMOR, quality = 3, minItemLevel = 31, maxItemLevel = 31, amountOfMats = 1.03},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 31, maxItemLevel = 31, amountOfMats = 0.033},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 3, minItemLevel = 31, maxItemLevel = 31, amountOfMats = 1.03},
			},
		},
		["i:34053"] = { -- Small Dream Shard
			minLevel = 27,
			maxLevel = 30,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 32, maxItemLevel = 33, amountOfMats = 0.033},
				{classId = LE_ITEM_CLASS_ARMOR, quality = 3, minItemLevel = 32, maxItemLevel = 33, amountOfMats = 1.000},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 32, maxItemLevel = 33, amountOfMats = 0.033},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 3, minItemLevel = 32, maxItemLevel = 33, amountOfMats = 1.000},
			},
		},
		["i:34052"] = { -- Dream Shard
			minLevel = 27,
			maxLevel = 30,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 2, minItemLevel = 34, maxItemLevel = 35, amountOfMats = 0.033},
				{classId = LE_ITEM_CLASS_ARMOR, quality = 3, minItemLevel = 34, maxItemLevel = 35, amountOfMats = 1.000},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 2, minItemLevel = 34, maxItemLevel = 35, amountOfMats = 0.033},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 3, minItemLevel = 34, maxItemLevel = 35, amountOfMats = 1.000},
			},
		},
		["i:52720"] = { -- Small Heavenly Shard
			minLevel = 29,
			maxLevel = 32,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 3, minItemLevel = 36, maxItemLevel = 36, amountOfMats = 1.000},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 3, minItemLevel = 36, maxItemLevel = 36, amountOfMats = 1.000},
			},
		},
		["i:52721"] = { -- Heavenly Shard
			minLevel = 29,
			maxLevel = 32,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 3, minItemLevel = 37, maxItemLevel = 37, amountOfMats = 1.000},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 3, minItemLevel = 37, maxItemLevel = 37, amountOfMats = 1.000},
			},
		},
		["i:74252"] = { -- Small Ethereal Shard
			minLevel = 32,
			maxLevel = 35,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 3, minItemLevel = 38, maxItemLevel = 38, amountOfMats = 1.000},
				{classId = LE_ITEM_CLASS_ARMOR, quality = 3, minItemLevel = 39, maxItemLevel = 39, amountOfMats = 0.050},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 3, minItemLevel = 38, maxItemLevel = 38, amountOfMats = 1.000},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 3, minItemLevel = 39, maxItemLevel = 39, amountOfMats = 0.050},
			},
		},
		["i:74247"] = { -- Ethereal Shard
			minLevel = 32,
			maxLevel = 35,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 3, minItemLevel = 38, maxItemLevel = 38, amountOfMats = 0.050},
				{classId = LE_ITEM_CLASS_ARMOR, quality = 3, minItemLevel = 39, maxItemLevel = 39, amountOfMats = 0.950},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 3, minItemLevel = 38, maxItemLevel = 38, amountOfMats = 0.050},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 3, minItemLevel = 39, maxItemLevel = 39, amountOfMats = 0.950},
			},
		},
		["i:115502"] = { -- Small Luminous Shard
			minLevel = 35,
			maxLevel = 40,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 3, minItemLevel = 42, maxItemLevel = 44, amountOfMats = 0.430},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 3, minItemLevel = 42, maxItemLevel = 44, amountOfMats = 0.430},
			},
		},
		["i:111245"] = { -- Luminous Shard
			minLevel = 35,
			maxLevel = 40,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 3, minItemLevel = 42, maxItemLevel = 44, amountOfMats = 0.220},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 3, minItemLevel = 42, maxItemLevel = 44, amountOfMats = 0.220},
			},
		},
		["i:124441"] = { -- Leylight Shard
			minLevel = 40,
			maxLevel = 45,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 3, minItemLevel = 45, maxItemLevel = 46, amountOfMats = 1.000},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 3, minItemLevel = 45, maxItemLevel = 46, amountOfMats = 1.000},
			},
		},
		["i:152876"] = { -- Umbra Shard
			minLevel = 45,
			maxLevel = 50,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 3, minItemLevel = 51, maxItemLevel = 84, amountOfMats = 1.500},
				{classId = LE_ITEM_CLASS_ARMOR, quality = 4, minItemLevel = 58, maxItemLevel = 100, amountOfMats = 0.600},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 3, minItemLevel = 51, maxItemLevel = 84, amountOfMats = 1.500},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 4, minItemLevel = 58, maxItemLevel = 100, amountOfMats = 0.600},
			},
		},
		["i:172231"] = { -- Sacred Shard
			minLevel = 50,
			maxLevel = 60,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 3, minItemLevel = 85, maxItemLevel = 375, amountOfMats = 1.500},
				{classId = LE_ITEM_CLASS_ARMOR, quality = 4, minItemLevel = 101, maxItemLevel = 375, amountOfMats = 0.350},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 3, minItemLevel = 85, maxItemLevel = 375, amountOfMats = 1.500},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 4, minItemLevel = 101, maxItemLevel = 375, amountOfMats = 0.350},
			},
		},

		-- Crystals
		["i:22450"] = { -- Void Crystal
			minLevel = 26,
			maxLevel = 26,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 4, minItemLevel = 30, maxItemLevel = 34, amountOfMats = 1.530},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 4, minItemLevel = 30, maxItemLevel = 34, amountOfMats = 1.530},
			},
		},
		["i:34057"] = { -- Abyss Crystal
			minLevel = 30,
			maxLevel = 30,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 4, minItemLevel = 35, maxItemLevel = 36, amountOfMats = 1.000},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 4, minItemLevel = 35, maxItemLevel = 36, amountOfMats = 1.000},
			},
		},
		["i:52722"] = { -- Maelstrom Crystal
			minLevel = 32,
			maxLevel = 32,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 4, minItemLevel = 37, maxItemLevel = 38, amountOfMats = 1.000},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 4, minItemLevel = 37, maxItemLevel = 38, amountOfMats = 1.000},
			},
		},
		["i:74248"] = { -- Sha Crystal
			minLevel = 32,
			maxLevel = 35,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 4, minItemLevel = 39, maxItemLevel = 42, amountOfMats = 1.000},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 4, minItemLevel = 39, maxItemLevel = 42, amountOfMats = 1.000},
			},
		},
		["i:115504"] = { -- Fractured Temporal Crystal
			minLevel = 35,
			maxLevel = 40,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 3, minItemLevel = 40, maxItemLevel = 44, amountOfMats = 0.300},
				{classId = LE_ITEM_CLASS_ARMOR, quality = 4, minItemLevel = 43, maxItemLevel = 47, amountOfMats = 0.750},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 3, minItemLevel = 40, maxItemLevel = 44, amountOfMats = 0.150},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 4, minItemLevel = 43, maxItemLevel = 47, amountOfMats = 0.750},
			},
		},
		["i:113588"] = { -- Temporal Crystal
			minLevel = 35,
			maxLevel = 40,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 3, minItemLevel = 40, maxItemLevel = 44, amountOfMats = 0.050},
				{classId = LE_ITEM_CLASS_ARMOR, quality = 4, minItemLevel = 43, maxItemLevel = 47, amountOfMats = 0.750},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 3, minItemLevel = 40, maxItemLevel = 44, amountOfMats = 0.050},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 4, minItemLevel = 43, maxItemLevel = 47, amountOfMats = 0.750},
			},
		},
		["i:124442"] = { -- Chaos Crystal
			minLevel = 40,
			maxLevel = 45,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 4, minItemLevel = 50, maxItemLevel = 50, amountOfMats = 1.000},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 4, minItemLevel = 50, maxItemLevel = 50, amountOfMats = 1.000},
			},
		},
		["i:152877"] = { -- Veiled Crystal
			minLevel = 45,
			maxLevel = 50,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 3, minItemLevel = 51, maxItemLevel = 84, amountOfMats = 0.050},
				{classId = LE_ITEM_CLASS_ARMOR, quality = 4, minItemLevel = 58, maxItemLevel = 100, amountOfMats = 1.000},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 3, minItemLevel = 51, maxItemLevel = 84, amountOfMats = 0.050},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 4, minItemLevel = 58, maxItemLevel = 100, amountOfMats = 1.000},
			},
		},
		["i:172232"] = { -- Eternal Crystal
			minLevel = 50,
			maxLevel = 60,
			sourceInfo = {
				{classId = LE_ITEM_CLASS_ARMOR, quality = 4, minItemLevel = 101, maxItemLevel = 375, amountOfMats = 1.000},
				{classId = LE_ITEM_CLASS_WEAPON, quality = 4, minItemLevel = 101, maxItemLevel = 375, amountOfMats = 1.000},
			},
		},
	}
end

-- From TSM so we can be consistent
-- added in SL prospect rate so far
if (not Utils.IsClassic()) then
	-- PROSPECT_INFO = { 	
	-- 	-- ======================================== Uncommon Gems ======================================
	-- 	["i:774"] = { -- Malachite
	-- 		["i:2770"] = {matRate = 0.5000, minAmount = 1, maxAmount = 1, amountOfMats = 0.1000}, -- Copper Ore
	-- 	},
	-- 	["i:818"] = { -- Tigerseye
	-- 		["i:2770"] = {matRate = 0.5000, minAmount = 1, maxAmount = 1, amountOfMats = 0.1000}, -- Copper Ore
	-- 	},
	-- 	["i:1210"] = {  -- Shadowgem
	-- 		["i:2771"] = {matRate = 0.3800, minAmount = 1, maxAmount = 2, amountOfMats = 0.0800}, -- Tin Ore
	-- 		["i:2770"] = {matRate = 0.1000, minAmount = 1, maxAmount = 1, amountOfMats = 0.0200}, -- Copper Ore
	-- 	},
	-- 	["i:1206"] = { -- Moss Agate
	-- 		["i:2771"] = {matRate = 0.3800, minAmount = 1, maxAmount = 2, amountOfMats = 0.0800}, -- Tin Ore
	-- 	},
	-- 	["i:1705"] = { -- Lesser Moonstone
	-- 		["i:2771"] = {matRate = 0.3800, minAmount = 1, maxAmount = 2, amountOfMats = 0.0800}, -- Tin Ore
	-- 		["i:2772"] = {matRate = 0.3500, minAmount = 1, maxAmount = 2, amountOfMats = 0.0700}, -- Iron Ore
	-- 	},
	-- 	["i:1529"] = { -- Jade
	-- 		["i:2772"] = {matRate = 0.3500, minAmount = 1, maxAmount = 2, amountOfMats = 0.0700}, -- Iron Ore
	-- 		["i:2771"] = {matRate = 0.0325, minAmount = 1, maxAmount = 1, amountOfMats = 0.0065}, -- Tin Ore
	-- 	},
	-- 	["i:3864"] = { -- Citrine
	-- 		["i:2772"] = {matRate = 0.3800, minAmount = 1, maxAmount = 2, amountOfMats = 0.0785}, -- Iron Ore
	-- 		["i:3858"] = {matRate = 0.3500, minAmount = 1, maxAmount = 2, amountOfMats = 0.0725}, -- Mithril Ore
	-- 		["i:2771"] = {matRate = 0.0325, minAmount = 1, maxAmount = 1, amountOfMats = 0.0065}, -- Tin Ore
	-- 	},
	-- 	["i:7909"] = { -- Aquamarine
	-- 		["i:3858"] = {matRate = 0.3500, minAmount = 1, maxAmount = 2, amountOfMats = 0.0725}, -- Mithril Ore
	-- 		["i:2772"] = {matRate = 0.0500, minAmount = 1, maxAmount = 1, amountOfMats = 0.0100}, -- Iron Ore
	-- 		["i:2771"] = {matRate = 0.0325, minAmount = 1, maxAmount = 1, amountOfMats = 0.0065}, -- Tin Ore
	-- 	},
	-- 	["i:7910"] = { -- Star Ruby
	-- 		[ "i:3858"] = {matRate = 0.3500, minAmount = 1, maxAmount = 2, amountOfMats = 0.0725}, -- Mithril Ore
	-- 		["i:10620"] = {matRate = 0.1550, minAmount = 1, maxAmount = 2, amountOfMats = 0.0320}, -- Thorium Ore
	-- 		[ "i:2772"] = {matRate = 0.0500, minAmount = 1, maxAmount = 1, amountOfMats = 0.0100}, -- Iron Ore
	-- 	},
	-- 	["i:12361"] = { -- Blue Sapphire
	-- 		["i:10620"] = {matRate = 0.3100, minAmount = 1, maxAmount = 2, amountOfMats = 0.0660}, -- Thorium Ore
	-- 		[ "i:3858"] = {matRate = 0.0225, minAmount = 1, maxAmount = 1, amountOfMats = 0.0050}, -- Mithril Ore
	-- 	},
	-- 	["i:12799"] = { -- Large Opal
	-- 		["i:10620"] = {matRate = 0.3100, minAmount = 1, maxAmount = 2, amountOfMats = 0.0660}, -- Thorium Ore
	-- 		[ "i:3858"] = {matRate = 0.0225, minAmount = 1, maxAmount = 1, amountOfMats = 0.0050}, -- Mithril Ore
	-- 	},
	-- 	["i:12800"] = { -- Azerothian Diamond
	-- 		["i:10620"] = {matRate = 0.3100, minAmount = 1, maxAmount = 2, amountOfMats = 0.0660}, -- Thorium Ore
	-- 		[ "i:3858"] = {matRate = 0.0225, minAmount = 1, maxAmount = 1, amountOfMats = 0.0050}, -- Mithril Ore
	-- 	},
	-- 	["i:12364"] = { -- Huge Emerald
	-- 		["i:10620"] = {matRate = 0.3100, minAmount = 1, maxAmount = 2, amountOfMats = 0.0660}, -- Thorium Ore
	-- 		[ "i:3858"] = {matRate = 0.0225, minAmount = 1, maxAmount = 1, amountOfMats = 0.0050}, -- Mithril Ore
	-- 	},
	-- 	["i:23117"] = { -- Azure Moonstone
	-- 		["i:23424"] = {matRate = 0.1800, minAmount = 1, maxAmount = 2, amountOfMats = 0.0365}, -- Fel Iron Ore
	-- 		["i:23425"] = {matRate = 0.5000, minAmount = 1, maxAmount = 2, amountOfMats = 0.0365}, -- Adamantite Ore
	-- 	},
	-- 	["i:23077"] = { -- Blood Garnet
	-- 		["i:23424"] = {matRate = 0.1800, minAmount = 1, maxAmount = 2, amountOfMats = 0.0365}, -- Fel Iron Ore
	-- 		["i:23425"] = {matRate = 0.1800, minAmount = 1, maxAmount = 2, amountOfMats = 0.0365}, -- Adamantite Ore
	-- 	},
	-- 	["i:23079"] = { -- Deep Peridot
	-- 		["i:23424"] = {matRate = 0.1800, minAmount = 1, maxAmount = 2, amountOfMats = 0.0365}, -- Fel Iron Ore
	-- 		["i:23425"] = {matRate = 0.1800, minAmount = 1, maxAmount = 2, amountOfMats = 0.0365}, -- Adamantite Ore
	-- 	},
	-- 	["i:21929"] = { -- Flame Spessarite
	-- 		["i:23424"] = {matRate = 0.1800, minAmount = 1, maxAmount = 2, amountOfMats = 0.0365}, -- Fel Iron Ore
	-- 		["i:23425"] = {matRate = 0.1800, minAmount = 1, maxAmount = 2, amountOfMats = 0.0365}, -- Adamantite Ore
	-- 	},
	-- 	["i:23112"] = { -- Golden Draenite
	-- 		["i:23424"] = {matRate = 0.1800, minAmount = 1, maxAmount = 2, amountOfMats = 0.0365}, -- Fel Iron Ore
	-- 		["i:23425"] = {matRate = 0.1800, minAmount = 1, maxAmount = 2, amountOfMats = 0.0365}, -- Adamantite Ore
	-- 	},
	-- 	["i:23107"] = { -- Shadow Draenite
	-- 		["i:23424"] = {matRate = 0.1800, minAmount = 1, maxAmount = 2, amountOfMats = 0.0365}, -- Fel Iron Ore
	-- 		["i:23425"] = {matRate = 0.1800, minAmount = 1, maxAmount = 2, amountOfMats = 0.0365}, -- Adamantite Ore
	-- 	},
	-- 	["i:36917"] = { -- Bloodstone
	-- 		["i:36909"] = {matRate = 0.2400, minAmount = 1, maxAmount = 2, amountOfMats = 0.0495}, -- Cobalt Ore
	-- 		["i:36912"] = {matRate = 0.1800, minAmount = 1, maxAmount = 2, amountOfMats = 0.0365}, -- Saronite Ore
	-- 		["i:36910"] = {matRate = 0.2500, minAmount = 1, maxAmount = 2, amountOfMats = 0.0525}, -- Titanium Ore
	-- 	},
	-- 	["i:36923"] = { -- Chalcedony
	-- 		["i:36909"] = {matRate = 0.2400, minAmount = 1, maxAmount = 2, amountOfMats = 0.0495}, -- Cobalt Ore
	-- 		["i:36912"] = {matRate = 0.1800, minAmount = 1, maxAmount = 2, amountOfMats = 0.0365}, -- Saronite Ore
	-- 		["i:36910"] = {matRate = 0.2500, minAmount = 1, maxAmount = 2, amountOfMats = 0.0525}, -- Titanium Ore
	-- 	},
	-- 	["i:36932"] = { -- Dark Jade
	-- 		["i:36909"] = {matRate = 0.2400, minAmount = 1, maxAmount = 2, amountOfMats = 0.0495}, -- Cobalt Ore
	-- 		["i:36912"] = {matRate = 0.1800, minAmount = 1, maxAmount = 2, amountOfMats = 0.0365}, -- Saronite Ore
	-- 		["i:36910"] = {matRate = 0.2500, minAmount = 1, maxAmount = 2, amountOfMats = 0.0525}, -- Titanium Ore
	-- 	},
	-- 	["i:36929"] = { -- Huge Citrine
	-- 		["i:36909"] = {matRate = 0.2400, minAmount = 1, maxAmount = 2, amountOfMats = 0.0495}, -- Cobalt Ore
	-- 		["i:36912"] = {matRate = 0.1800, minAmount = 1, maxAmount = 2, amountOfMats = 0.0365}, -- Saronite Ore
	-- 		["i:36910"] = {matRate = 0.2500, minAmount = 1, maxAmount = 2, amountOfMats = 0.0525}, -- Titanium Ore
	-- 	},
	-- 	["i:36926"] = { -- Shadow Crystal
	-- 		["i:36909"] = {matRate = 0.2400, minAmount = 1, maxAmount = 2, amountOfMats = 0.0495}, -- Cobalt Ore
	-- 		["i:36912"] = {matRate = 0.1800, minAmount = 1, maxAmount = 2, amountOfMats = 0.0365}, -- Saronite Ore
	-- 		["i:36910"] = {matRate = 0.2500, minAmount = 1, maxAmount = 2, amountOfMats = 0.0525}, -- Titanium Ore
	-- 	},
	-- 	["i:36920"] = { -- Sun Crystal
	-- 		["i:36909"] = {matRate = 0.2400, minAmount = 1, maxAmount = 2, amountOfMats = 0.0495}, -- Cobalt Ore
	-- 		["i:36912"] = {matRate = 0.1800, minAmount = 1, maxAmount = 2, amountOfMats = 0.0365}, -- Saronite Ore
	-- 		["i:36910"] = {matRate = 0.2500, minAmount = 1, maxAmount = 2, amountOfMats = 0.0525}, -- Titanium Ore
	-- 	},
	-- 	["i:52182"] = { -- Jasper
	-- 		["i:53038"] = {matRate = 0.2350, minAmount = 1, maxAmount = 2, amountOfMats = 0.0500}, -- Obsidium Ore
	-- 		["i:52185"] = {matRate = 0.1800, minAmount = 1, maxAmount = 2, amountOfMats = 0.0365}, -- Elementium Ore
	-- 		["i:52183"] = {matRate = 0.1650, minAmount = 1, maxAmount = 1, amountOfMats = 0.0330}, -- Pyrite Ore
	-- 	},
	-- 	["i:52180"] = { -- Nightstone
	-- 		["i:53038"] = {matRate = 0.2350, minAmount = 1, maxAmount = 2, amountOfMats = 0.0500}, -- Obsidium Ore
	-- 		["i:52185"] = {matRate = 0.1800, minAmount = 1, maxAmount = 2, amountOfMats = 0.0365}, -- Elementium Ore
	-- 		["i:52183"] = {matRate = 0.1650, minAmount = 1, maxAmount = 1, amountOfMats = 0.0330}, -- Pyrite Ore
	-- 	},
	-- 	["i:52178"] = { -- Zephyrite
	-- 		["i:53038"] = {matRate = 0.2350, minAmount = 1, maxAmount = 2, amountOfMats = 0.0500}, -- Obsidium Ore
	-- 		["i:52185"] = {matRate = 0.1800, minAmount = 1, maxAmount = 2, amountOfMats = 0.0365}, -- Elementium Ore
	-- 		["i:52183"] = {matRate = 0.1650, minAmount = 1, maxAmount = 1, amountOfMats = 0.0330}, -- Pyrite Ore
	-- 	},
	-- 	["i:52179"] = { -- Alicite
	-- 		["i:53038"] = {matRate = 0.2350, minAmount = 1, maxAmount = 2, amountOfMats = 0.0500}, -- Obsidium Ore
	-- 		["i:52185"] = {matRate = 0.1800, minAmount = 1, maxAmount = 2, amountOfMats = 0.0365}, -- Elementium Ore
	-- 		["i:52183"] = {matRate = 0.1650, minAmount = 1, maxAmount = 1, amountOfMats = 0.0330}, -- Pyrite Ore
	-- 	},
	-- 	["i:52177"] = { -- Carnelian
	-- 		["i:53038"] = {matRate = 0.2350, minAmount = 1, maxAmount = 2, amountOfMats = 0.0500}, -- Obsidium Ore
	-- 		["i:52185"] = {matRate = 0.1800, minAmount = 1, maxAmount = 2, amountOfMats = 0.0365}, -- Elementium Ore
	-- 		["i:52183"] = {matRate = 0.1650, minAmount = 1, maxAmount = 1, amountOfMats = 0.0330}, -- Pyrite Ore
	-- 	},
	-- 	["i:52181"] = { -- Hessonite
	-- 		["i:53038"] = {matRate = 0.2350, minAmount = 1, maxAmount = 2, amountOfMats = 0.0500}, -- Obsidium Ore
	-- 		["i:52185"] = {matRate = 0.1800, minAmount = 1, maxAmount = 2, amountOfMats = 0.0365}, -- Elementium Ore
	-- 		["i:52183"] = {matRate = 0.1650, minAmount = 1, maxAmount = 1, amountOfMats = 0.0330}, -- Pyrite Ore
	-- 	},
	-- 	["i:76130"] = { -- Tiger Opal
	-- 		["i:72092"] = {matRate = 0.2350, minAmount = 1, maxAmount = 2, amountOfMats = 0.0497}, -- Ghost Iron Ore
	-- 		["i:72093"] = {matRate = 0.2300, minAmount = 1, maxAmount = 2, amountOfMats = 0.0487}, -- Kyparite
	-- 		["i:72103"] = {matRate = 0.1600, minAmount = 1, maxAmount = 1, amountOfMats = 0.0341}, -- White Trillium Ore
	-- 		["i:72094"] = {matRate = 0.1600, minAmount = 1, maxAmount = 1, amountOfMats = 0.0341}, -- Black Trillium Ore
	-- 	},
	-- 	["i:76133"] = { -- Lapis Lazuli
	-- 		["i:72092"] = {matRate = 0.2350, minAmount = 1, maxAmount = 2, amountOfMats = 0.0497}, -- Ghost Iron Ore
	-- 		["i:72093"] = {matRate = 0.2300, minAmount = 1, maxAmount = 2, amountOfMats = 0.0487}, -- Kyparite
	-- 		["i:72103"] = {matRate = 0.1600, minAmount = 1, maxAmount = 1, amountOfMats = 0.0341}, -- White Trillium Ore
	-- 		["i:72094"] = {matRate = 0.1600, minAmount = 1, maxAmount = 1, amountOfMats = 0.0341}, -- Black Trillium Ore
	-- 	},
	-- 	["i:76134"] = { -- Sunstone
	-- 		["i:72092"] = {matRate = 0.2350, minAmount = 1, maxAmount = 2, amountOfMats = 0.0497}, -- Ghost Iron Ore
	-- 		["i:72093"] = {matRate = 0.2300, minAmount = 1, maxAmount = 2, amountOfMats = 0.0487}, -- Kyparite
	-- 		["i:72103"] = {matRate = 0.1600, minAmount = 1, maxAmount = 1, amountOfMats = 0.0341}, -- White Trillium Ore
	-- 		["i:72094"] = {matRate = 0.1600, minAmount = 1, maxAmount = 1, amountOfMats = 0.0341}, -- Black Trillium Ore
	-- 	},
	-- 	["i:76135"] = { -- Roguestone
	-- 		["i:72092"] = {matRate = 0.2350, minAmount = 1, maxAmount = 2, amountOfMats = 0.0497}, -- Ghost Iron Ore
	-- 		["i:72093"] = {matRate = 0.2300, minAmount = 1, maxAmount = 2, amountOfMats = 0.0487}, -- Kyparite
	-- 		["i:72103"] = {matRate = 0.1600, minAmount = 1, maxAmount = 1, amountOfMats = 0.0341}, -- White Trillium Ore
	-- 		["i:72094"] = {matRate = 0.1600, minAmount = 1, maxAmount = 1, amountOfMats = 0.0341}, -- Black Trillium Ore
	-- 	},
	-- 	["i:76136"] = { -- Pandarian Garnet
	-- 		["i:72092"] = {matRate = 0.2350, minAmount = 1, maxAmount = 2, amountOfMats = 0.0497}, -- Ghost Iron Ore
	-- 		["i:72093"] = {matRate = 0.2300, minAmount = 1, maxAmount = 2, amountOfMats = 0.0487}, -- Kyparite
	-- 		["i:72103"] = {matRate = 0.1600, minAmount = 1, maxAmount = 1, amountOfMats = 0.0341}, -- White Trillium Ore
	-- 		["i:72094"] = {matRate = 0.1600, minAmount = 1, maxAmount = 1, amountOfMats = 0.0341}, -- Black Trillium Ore
	-- 	},
	-- 	["i:76137"] = { -- Alexandrite
	-- 		["i:72092"] = {matRate = 0.2350, minAmount = 1, maxAmount = 2, amountOfMats = 0.0497}, -- Ghost Iron Ore
	-- 		["i:72093"] = {matRate = 0.2300, minAmount = 1, maxAmount = 2, amountOfMats = 0.0487}, -- Kyparite
	-- 		["i:72103"] = {matRate = 0.1600, minAmount = 1, maxAmount = 1, amountOfMats = 0.0341}, -- White Trillium Ore
	-- 		["i:72094"] = {matRate = 0.1600, minAmount = 1, maxAmount = 1, amountOfMats = 0.0341}, -- Black Trillium Ore
	-- 	},
	-- 	["i:130173"] = { -- Deep Amber
	-- 		["i:123918"] = {matRate = 0.0450, minAmount = 1, maxAmount = 2, amountOfMats = 0.0100}, -- Leystone Ore
	-- 		["i:123919"] = {matRate = 0.0550, minAmount = 2, maxAmount = 5, amountOfMats = 0.0385}, -- Felslate
	-- 	},
	-- 	["i:130174"] = { -- Azsunite
	-- 		["i:123918"] = {matRate = 0.0450, minAmount = 1, maxAmount = 2, amountOfMats = 0.0100}, -- Leystone Ore
	-- 		["i:123919"] = {matRate = 0.0550, minAmount = 2, maxAmount = 5, amountOfMats = 0.0385}, -- Felslate
	-- 	},
	-- 	["i:130176"] = { -- Skystone
	-- 		["i:123918"] = {matRate = 0.0450, minAmount = 1, maxAmount = 2, amountOfMats = 0.0100}, -- Leystone Ore
	-- 		["i:123919"] = {matRate = 0.0550, minAmount = 2, maxAmount = 5, amountOfMats = 0.0385}, -- Felslate
	-- 	},
	-- 	["i:130177"] = { -- Queen's Opal
	-- 		["i:123918"] = {matRate = 0.0450, minAmount = 1, maxAmount = 2, amountOfMats = 0.0100}, -- Leystone Ore
	-- 		["i:123919"] = {matRate = 0.0550, minAmount = 2, maxAmount = 5, amountOfMats = 0.0385}, -- Felslate
	-- 	},
	-- 	["i:130175"] = { -- Chaotic Spinel
	-- 		["i:123918"] = {matRate = 0.0450, minAmount = 1, maxAmount = 2, amountOfMats = 0.0100}, -- Leystone Ore
	-- 		["i:123919"] = {matRate = 0.0550, minAmount = 2, maxAmount = 5, amountOfMats = 0.0385}, -- Felslate
	-- 	},
	-- 	["i:130172"] = { -- Sangrite
	-- 		["i:123918"] = {matRate = 0.0450, minAmount = 1, maxAmount = 2, amountOfMats = 0.0100}, -- Leystone Ore
	-- 		["i:123919"] = {matRate = 0.0550, minAmount = 2, maxAmount = 5, amountOfMats = 0.0385}, -- Felslate
	-- 	},
	-- 	["i:153700"] = { -- Golden Beryl
	-- 		["i:152512"] = {matRate = 0.1800, minAmount = 1, maxAmount = 4, amountOfMats = 0.0551}, -- Monelite Ore
	-- 		["i:152579"] = {matRate = 0.1950, minAmount = 1, maxAmount = 4, amountOfMats = 0.0603}, -- Storm Silver Ore
	-- 		["i:152513"] = {matRate = 0.2100, minAmount = 1, maxAmount = 4, amountOfMats = 0.0660}, -- Platinum Ore
	-- 	},
	-- 	["i:153701"] = { -- Rubellite
	-- 		["i:152512"] = {matRate = 0.1800, minAmount = 1, maxAmount = 4, amountOfMats = 0.0551}, -- Monelite Ore
	-- 		["i:152579"] = {matRate = 0.1950, minAmount = 1, maxAmount = 4, amountOfMats = 0.0603}, -- Storm Silver Ore
	-- 		["i:152513"] = {matRate = 0.2100, minAmount = 1, maxAmount = 4, amountOfMats = 0.0660}, -- Platinum Ore
	-- 	},
	-- 	["i:153702"] = { -- Kubiline
	-- 		["i:152512"] = {matRate = 0.1800, minAmount = 1, maxAmount = 4, amountOfMats = 0.0551}, -- Monelite Ore
	-- 		["i:152579"] = {matRate = 0.1950, minAmount = 1, maxAmount = 4, amountOfMats = 0.0603}, -- Storm Silver Ore
	-- 		["i:152513"] = {matRate = 0.2100, minAmount = 1, maxAmount = 4, amountOfMats = 0.0660}, -- Platinum Ore
	-- 	},
	-- 	["i:153703"] = { -- Solstone
	-- 		["i:152512"] = {matRate = 0.1800, minAmount = 1, maxAmount = 4, amountOfMats = 0.0551}, -- Monelite Ore
	-- 		["i:152579"] = {matRate = 0.1950, minAmount = 1, maxAmount = 4, amountOfMats = 0.0603}, -- Storm Silver Ore
	-- 		["i:152513"] = {matRate = 0.2100, minAmount = 1, maxAmount = 4, amountOfMats = 0.0660}, -- Platinum Ore
	-- 	},
	-- 	["i:153704"] = { -- Viridium
	-- 		["i:152512"] = {matRate = 0.1800, minAmount = 1, maxAmount = 4, amountOfMats = 0.0551}, -- Monelite Ore
	-- 		["i:152579"] = {matRate = 0.1950, minAmount = 1, maxAmount = 4, amountOfMats = 0.0603}, -- Storm Silver Ore
	-- 		["i:152513"] = {matRate = 0.2100, minAmount = 1, maxAmount = 4, amountOfMats = 0.0660}, -- Platinum Ore
	-- 	},
	-- 	["i:153705"] = { -- Kyanite
	-- 		["i:152512"] = {matRate = 0.1800, minAmount = 1, maxAmount = 4, amountOfMats = 0.0551}, -- Monelite Ore
	-- 		["i:152579"] = {matRate = 0.1950, minAmount = 1, maxAmount = 4, amountOfMats = 0.0603}, -- Storm Silver Ore
	-- 		["i:152513"] = {matRate = 0.2100, minAmount = 1, maxAmount = 4, amountOfMats = 0.0660}, -- Platinum Ore
	-- 	},
	-- 	-- ========================================== Rare Gems ========================================
	-- 	["i:23440"] = { -- Dawnstone
	-- 		["i:23424"] = {matRate = 0.0150, minAmount = 1, maxAmount = 1, amountOfMats = 0.0030}, -- Fel Iron Ore
	-- 		["i:23425"] = {matRate = 0.0400, minAmount = 1, maxAmount = 1, amountOfMats = 0.0080}, -- Adamantite Ore
	-- 	},
	-- 	["i:23436"] = { -- Living Ruby
	-- 		["i:23424"] = {matRate = 0.0150, minAmount = 1, maxAmount = 1, amountOfMats = 0.0030}, -- Fel Iron Ore
	-- 		["i:23425"] = {matRate = 0.0400, minAmount = 1, maxAmount = 1, amountOfMats = 0.0080}, -- Adamantite Ore
	-- 	},
	-- 	["i:23441"] = { -- Nightseye
	-- 		["i:23424"] = {matRate = 0.0150, minAmount = 1, maxAmount = 1, amountOfMats = 0.0030}, -- Fel Iron Ore
	-- 		["i:23425"] = {matRate = 0.0400, minAmount = 1, maxAmount = 1, amountOfMats = 0.0080}, -- Adamantite Ore
	-- 	},
	-- 	["i:23439"] = { -- Noble Topaz
	-- 		["i:23424"] = {matRate = 0.0150, minAmount = 1, maxAmount = 1, amountOfMats = 0.0030}, -- Fel Iron Ore
	-- 		["i:23425"] = {matRate = 0.0400, minAmount = 1, maxAmount = 1, amountOfMats = 0.0080}, -- Adamantite Ore
	-- 	},
	-- 	["i:23438"] = { -- Star of Elune
	-- 		["i:23424"] = {matRate = 0.0150, minAmount = 1, maxAmount = 1, amountOfMats = 0.0030}, -- Fel Iron Ore
	-- 		["i:23425"] = {matRate = 0.0400, minAmount = 1, maxAmount = 1, amountOfMats = 0.0080}, -- Adamantite Ore
	-- 	},
	-- 	["i:23437"] = { -- Talasite
	-- 		["i:23424"] = {matRate = 0.0150, minAmount = 1, maxAmount = 1, amountOfMats = 0.0030}, -- Fel Iron Ore
	-- 		["i:23425"] = {matRate = 0.0400, minAmount = 1, maxAmount = 1, amountOfMats = 0.0080}, -- Adamantite Ore
	-- 	},
	-- 	["i:36921"] = { -- Autumn's Glow
	-- 		["i:36909"] = {matRate = 0.0150, minAmount = 1, maxAmount = 2, amountOfMats = 0.0030}, -- Cobalt Ore
	-- 		["i:36912"] = {matRate = 0.0400, minAmount = 1, maxAmount = 2, amountOfMats = 0.0083}, -- Saronite Ore
	-- 		["i:36910"] = {matRate = 0.0450, minAmount = 1, maxAmount = 2, amountOfMats = 0.0093}, -- Titanium Ore
	-- 	},
	-- 	["i:36933"] = { -- Forest Emerald
	-- 		["i:36909"] = {matRate = 0.0150, minAmount = 1, maxAmount = 2, amountOfMats = 0.0030}, -- Cobalt Ore
	-- 		["i:36912"] = {matRate = 0.0400, minAmount = 1, maxAmount = 2, amountOfMats = 0.0083}, -- Saronite Ore
	-- 		["i:36910"] = {matRate = 0.0450, minAmount = 1, maxAmount = 2, amountOfMats = 0.0093}, -- Titanium Ore
	-- 	},
	-- 	["i:36930"] = { -- Monarch Topaz
	-- 		["i:36909"] = {matRate = 0.0150, minAmount = 1, maxAmount = 2, amountOfMats = 0.0030}, -- Cobalt Ore
	-- 		["i:36912"] = {matRate = 0.0400, minAmount = 1, maxAmount = 2, amountOfMats = 0.0083}, -- Saronite Ore
	-- 		["i:36910"] = {matRate = 0.0450, minAmount = 1, maxAmount = 2, amountOfMats = 0.0093}, -- Titanium Ore
	-- 	},
	-- 	["i:36918"] = { -- Scarlet Ruby
	-- 		["i:36909"] = {matRate = 0.0150, minAmount = 1, maxAmount = 2, amountOfMats = 0.0030}, -- Cobalt Ore
	-- 		["i:36912"] = {matRate = 0.0400, minAmount = 1, maxAmount = 2, amountOfMats = 0.0083}, -- Saronite Ore
	-- 		["i:36910"] = {matRate = 0.0450, minAmount = 1, maxAmount = 2, amountOfMats = 0.0093}, -- Titanium Ore
	-- 	},
	-- 	["i:36924"] = { -- Sky Sapphire
	-- 		["i:36909"] = {matRate = 0.0150, minAmount = 1, maxAmount = 2, amountOfMats = 0.0030}, -- Cobalt Ore
	-- 		["i:36912"] = {matRate = 0.0400, minAmount = 1, maxAmount = 2, amountOfMats = 0.0083}, -- Saronite Ore
	-- 		["i:36910"] = {matRate = 0.0450, minAmount = 1, maxAmount = 2, amountOfMats = 0.0093}, -- Titanium Ore
	-- 	},
	-- 	["i:36927"] = { -- Twilight Opal
	-- 		["i:36909"] = {matRate = 0.0150, minAmount = 1, maxAmount = 2, amountOfMats = 0.0030}, -- Cobalt Ore
	-- 		["i:36912"] = {matRate = 0.0400, minAmount = 1, maxAmount = 2, amountOfMats = 0.0083}, -- Saronite Ore
	-- 		["i:36910"] = {matRate = 0.0450, minAmount = 1, maxAmount = 2, amountOfMats = 0.0093}, -- Titanium Ore
	-- 	},
	-- 	["i:52192"] = { -- Dream Emerald
	-- 		["i:53038"] = {matRate = 0.0125, minAmount = 1, maxAmount = 1, amountOfMats = 0.0025}, -- Obsidium Ore
	-- 		["i:52185"] = {matRate = 0.0450, minAmount = 1, maxAmount = 2, amountOfMats = 0.0091}, -- Elementium Ore
	-- 		["i:52183"] = {matRate = 0.0750, minAmount = 1, maxAmount = 2, amountOfMats = 0.0152}, -- Pyrite Ore
	-- 	},
	-- 	["i:52193"] = { -- Ember Topaz
	-- 		["i:53038"] = {matRate = 0.0125, minAmount = 1, maxAmount = 1, amountOfMats = 0.0025}, -- Obsidium Ore
	-- 		["i:52185"] = {matRate = 0.0450, minAmount = 1, maxAmount = 2, amountOfMats = 0.0091}, -- Elementium Ore
	-- 		["i:52183"] = {matRate = 0.0750, minAmount = 1, maxAmount = 2, amountOfMats = 0.0152}, -- Pyrite Ore
	-- 	},
	-- 	["i:52190"] = { -- Inferno Ruby
	-- 		["i:53038"] = {matRate = 0.0125, minAmount = 1, maxAmount = 1, amountOfMats = 0.0025}, -- Obsidium Ore
	-- 		["i:52185"] = {matRate = 0.0450, minAmount = 1, maxAmount = 2, amountOfMats = 0.0091}, -- Elementium Ore
	-- 		["i:52183"] = {matRate = 0.0750, minAmount = 1, maxAmount = 2, amountOfMats = 0.0152}, -- Pyrite Ore
	-- 	},
	-- 	["i:52195"] = { -- Amberjewel
	-- 		["i:53038"] = {matRate = 0.0125, minAmount = 1, maxAmount = 1, amountOfMats = 0.0025}, -- Obsidium Ore
	-- 		["i:52185"] = {matRate = 0.0450, minAmount = 1, maxAmount = 2, amountOfMats = 0.0091}, -- Elementium Ore
	-- 		["i:52183"] = {matRate = 0.0750, minAmount = 1, maxAmount = 2, amountOfMats = 0.0152}, -- Pyrite Ore
	-- 	},
	-- 	["i:52194"] = { -- Demonseye
	-- 		["i:53038"] = {matRate = 0.0125, minAmount = 1, maxAmount = 1, amountOfMats = 0.0025}, -- Obsidium Ore
	-- 		["i:52185"] = {matRate = 0.0450, minAmount = 1, maxAmount = 2, amountOfMats = 0.0091}, -- Elementium Ore
	-- 		["i:52183"] = {matRate = 0.0750, minAmount = 1, maxAmount = 2, amountOfMats = 0.0152}, -- Pyrite Ore
	-- 	},
	-- 	["i:52191"] = { -- Ocean Sapphire
	-- 		["i:53038"] = {matRate = 0.0125, minAmount = 1, maxAmount = 1, amountOfMats = 0.0025}, -- Obsidium Ore
	-- 		["i:52185"] = {matRate = 0.0450, minAmount = 1, maxAmount = 2, amountOfMats = 0.0091}, -- Elementium Ore
	-- 		["i:52183"] = {matRate = 0.0750, minAmount = 1, maxAmount = 2, amountOfMats = 0.0152}, -- Pyrite Ore
	-- 	},
	-- 	["i:76131"] = { -- Primordial Ruby
	-- 		["i:72092"] = {matRate = 0.0450, minAmount = 1, maxAmount = 2, amountOfMats = 0.0091}, -- Ghost Iron Ore
	-- 		["i:72093"] = {matRate = 0.0450, minAmount = 1, maxAmount = 2, amountOfMats = 0.0091}, -- Kyparite
	-- 		["i:72103"] = {matRate = 0.1600, minAmount = 1, maxAmount = 3, amountOfMats = 0.0341}, -- White Trillium Ore
	-- 		["i:72094"] = {matRate = 0.1650, minAmount = 1, maxAmount = 3, amountOfMats = 0.0340}, -- Black Trillium Ore
	-- 	},
	-- 	["i:76138"] = { -- River's Heart
	-- 		["i:72092"] = {matRate = 0.0450, minAmount = 1, maxAmount = 2, amountOfMats = 0.0091}, -- Ghost Iron Ore
	-- 		["i:72093"] = {matRate = 0.0450, minAmount = 1, maxAmount = 2, amountOfMats = 0.0091}, -- Kyparite
	-- 		["i:72103"] = {matRate = 0.1600, minAmount = 1, maxAmount = 3, amountOfMats = 0.0341}, -- White Trillium Ore
	-- 		["i:72094"] = {matRate = 0.1600, minAmount = 1, maxAmount = 3, amountOfMats = 0.0341}, -- Black Trillium Ore
	-- 	},
	-- 	["i:76139"] = { -- Wild Jade
	-- 		["i:72092"] = {matRate = 0.0450, minAmount = 1, maxAmount = 2, amountOfMats = 0.0091}, -- Ghost Iron Ore
	-- 		["i:72093"] = {matRate = 0.0450, minAmount = 1, maxAmount = 2, amountOfMats = 0.0091}, -- Kyparite
	-- 		["i:72103"] = {matRate = 0.1600, minAmount = 1, maxAmount = 3, amountOfMats = 0.0341}, -- White Trillium Ore
	-- 		["i:72094"] = {matRate = 0.1600, minAmount = 1, maxAmount = 3, amountOfMats = 0.0341}, -- Black Trillium Ore
	-- 	},
	-- 	["i:76140"] = { -- Vermillion Onyx
	-- 		["i:72092"] = {matRate = 0.0450, minAmount = 1, maxAmount = 2, amountOfMats = 0.0091}, -- Ghost Iron Ore
	-- 		["i:72093"] = {matRate = 0.0450, minAmount = 1, maxAmount = 2, amountOfMats = 0.0091}, -- Kyparite
	-- 		["i:72103"] = {matRate = 0.1600, minAmount = 1, maxAmount = 3, amountOfMats = 0.0341}, -- White Trillium Ore
	-- 		["i:72094"] = {matRate = 0.1600, minAmount = 1, maxAmount = 3, amountOfMats = 0.0341}, -- Black Trillium Ore
	-- 	},
	-- 	["i:76141"] = { -- Imperial Amethyst
	-- 		["i:72092"] = {matRate = 0.0450, minAmount = 1, maxAmount = 2, amountOfMats = 0.0091}, -- Ghost Iron Ore
	-- 		["i:72093"] = {matRate = 0.0450, minAmount = 1, maxAmount = 2, amountOfMats = 0.0091}, -- Kyparite
	-- 		["i:72103"] = {matRate = 0.1600, minAmount = 1, maxAmount = 3, amountOfMats = 0.0341}, -- White Trillium Ore
	-- 		["i:72094"] = {matRate = 0.1600, minAmount = 1, maxAmount = 3, amountOfMats = 0.0341}, -- Black Trillium Ore
	-- 	},
	-- 	["i:76142"] = { -- Sun's Radiance
	-- 		["i:72092"] = {matRate = 0.0450, minAmount = 1, maxAmount = 2, amountOfMats = 0.0091}, -- Ghost Iron Ore
	-- 		["i:72093"] = {matRate = 0.0450, minAmount = 1, maxAmount = 2, amountOfMats = 0.0091}, -- Kyparite
	-- 		["i:72103"] = {matRate = 0.1600, minAmount = 1, maxAmount = 3, amountOfMats = 0.0341}, -- White Trillium Ore
	-- 		["i:72094"] = {matRate = 0.1600, minAmount = 1, maxAmount = 3, amountOfMats = 0.0341}, -- Black Trillium Ore
	-- 	},
	-- 	["i:130179"] = { -- Eye of Prophecy
	-- 		["i:123918"] = {matRate = 0.0100, minAmount = 1, maxAmount = 1, amountOfMats = 0.0020}, -- Leystone Ore
	-- 		["i:123919"] = {matRate = 0.0100, minAmount = 2, maxAmount = 5, amountOfMats = 0.0020}, -- Felslate
	-- 	},
	-- 	["i:130180"] = { -- Dawnlight
	-- 		["i:123918"] = {matRate = 0.0100, minAmount = 1, maxAmount = 1, amountOfMats = 0.0020}, -- Leystone Ore
	-- 		["i:123919"] = {matRate = 0.0100, minAmount = 2, maxAmount = 5, amountOfMats = 0.0020}, -- Felslate
	-- 	},
	-- 	["i:130182"] = { -- Maelstrom Sapphire
	-- 		["i:123918"] = {matRate = 0.0100, minAmount = 1, maxAmount = 1, amountOfMats = 0.0020}, -- Leystone Ore
	-- 		["i:123919"] = {matRate = 0.0100, minAmount = 2, maxAmount = 5, amountOfMats = 0.0020}, -- Felslate
	-- 	},
	-- 	["i:130183"] = { -- Shadowruby
	-- 		["i:123918"] = {matRate = 0.0100, minAmount = 1, maxAmount = 1, amountOfMats = 0.0020}, -- Leystone Ore
	-- 		["i:123919"] = {matRate = 0.0100, minAmount = 2, maxAmount = 5, amountOfMats = 0.0020}, -- Felslate
	-- 	},
	-- 	["i:130178"] = { -- FuryStone
	-- 		["i:123918"] = {matRate = 0.0100, minAmount = 1, maxAmount = 1, amountOfMats = 0.0020}, -- Leystone Ore
	-- 		["i:123919"] = {matRate = 0.0100, minAmount = 2, maxAmount = 5, amountOfMats = 0.0020}, -- Felslate
	-- 	},
	-- 	["i:130181"] = { -- Pandemonite
	-- 		["i:123918"] = {matRate = 0.0100, minAmount = 1, maxAmount = 1, amountOfMats = 0.0020}, -- Leystone Ore
	-- 		["i:123919"] = {matRate = 0.0100, minAmount = 2, maxAmount = 5, amountOfMats = 0.0020}, -- Felslate
	-- 	},
	-- 	["i:154120"] = { -- Owlseye
	-- 		["i:152512"] = {matRate = 0.0425, minAmount = 1, maxAmount = 2, amountOfMats = 0.0086}, -- Monelite Ore
	-- 		["i:152579"] = {matRate = 0.0750, minAmount = 1, maxAmount = 2, amountOfMats = 0.0153}, -- Storm Silver Ore
	-- 		["i:152513"] = {matRate = 0.1150, minAmount = 1, maxAmount = 2, amountOfMats = 0.0237}, -- Platinum Ore
	-- 	},
	-- 	["i:154121"] = { -- Scarlet Diamond
	-- 		["i:152512"] = {matRate = 0.0425, minAmount = 1, maxAmount = 2, amountOfMats = 0.0086}, -- Monelite Ore
	-- 		["i:152579"] = {matRate = 0.0750, minAmount = 1, maxAmount = 2, amountOfMats = 0.0153}, -- Storm Silver Ore
	-- 		["i:152513"] = {matRate = 0.1150, minAmount = 1, maxAmount = 2, amountOfMats = 0.0237}, -- Platinum Ore
	-- 	},
	-- 	["i:154122"] = { -- Tidal Amethyst
	-- 		["i:152512"] = {matRate = 0.0425, minAmount = 1, maxAmount = 2, amountOfMats = 0.0086}, -- Monelite Ore
	-- 		["i:152579"] = {matRate = 0.0750, minAmount = 1, maxAmount = 2, amountOfMats = 0.0153}, -- Storm Silver Ore
	-- 		["i:152513"] = {matRate = 0.1150, minAmount = 1, maxAmount = 2, amountOfMats = 0.0237}, -- Platinum Ore
	-- 	},
	-- 	["i:154123"] = { -- Amberblaze
	-- 		["i:152512"] = {matRate = 0.0425, minAmount = 1, maxAmount = 2, amountOfMats = 0.0086}, -- Monelite Ore
	-- 		["i:152579"] = {matRate = 0.0750, minAmount = 1, maxAmount = 2, amountOfMats = 0.0153}, -- Storm Silver Ore
	-- 		["i:152513"] = {matRate = 0.1150, minAmount = 1, maxAmount = 2, amountOfMats = 0.0237}, -- Platinum Ore
	-- 	},
	-- 	["i:154124"] = { -- Laribole
	-- 		["i:152512"] = {matRate = 0.0425, minAmount = 1, maxAmount = 2, amountOfMats = 0.0086}, -- Monelite Ore
	-- 		["i:152579"] = {matRate = 0.0750, minAmount = 1, maxAmount = 2, amountOfMats = 0.0153}, -- Storm Silver Ore
	-- 		["i:152513"] = {matRate = 0.1150, minAmount = 1, maxAmount = 2, amountOfMats = 0.0237}, -- Platinum Ore
	-- 	},
	-- 	["i:154125"] = { -- Royal Quartz
	-- 		["i:152512"] = {matRate = 0.0425, minAmount = 1, maxAmount = 2, amountOfMats = 0.0086}, -- Monelite Ore
	-- 		["i:152579"] = {matRate = 0.0750, minAmount = 1, maxAmount = 2, amountOfMats = 0.0153}, -- Storm Silver Ore
	-- 		["i:152513"] = {matRate = 0.1150, minAmount = 1, maxAmount = 2, amountOfMats = 0.0237}, -- Platinum Ore
	-- 	},
	-- 	-- ========================================== Epic Gems ========================================
	-- 	["i:36931"] = { -- Ametrine
	-- 		["i:36910"] = {matRate = 0.0450, minAmount = 1, maxAmount = 2, amountOfMats = 0.0093}, -- Titanium Ore
	-- 	},
	-- 	["i:36919"] = { -- Cardinal Ruby
	-- 		["i:36910"] = {matRate = 0.0450, minAmount = 1, maxAmount = 2, amountOfMats = 0.0093}, -- Titanium Ore
	-- 	},
	-- 	["i:36928"] = { -- Dreadstone
	-- 		["i:36910"] = {matRate = 0.0450, minAmount = 1, maxAmount = 2, amountOfMats = 0.0093}, -- Titanium Ore
	-- 	},
	-- 	["i:36934"] = { -- Eye of Zul
	-- 		["i:36910"] = {matRate = 0.0450, minAmount = 1, maxAmount = 2, amountOfMats = 0.0093}, -- Titanium Ore
	-- 	},
	-- 	["i:36922"] = { -- King's Amber
	-- 		["i:36910"] = {matRate = 0.0450, minAmount = 1, maxAmount = 2, amountOfMats = 0.0093}, -- Titanium Ore
	-- 	},
	-- 	["i:36925"] = { -- Majestic Zircon
	-- 		["i:36910"] = {matRate = 0.0450, minAmount = 1, maxAmount = 2, amountOfMats = 0.0093}, -- Titanium Ore
	-- 	},
	-- 	["i:151719"] = { -- Lightsphene
	-- 		["i:151564"] = {matRate = 0.0300, minAmount = 1, maxAmount = 1, amountOfMats = 0.0060}, -- Empyrium
	-- 	},
	-- 	["i:151720"] = { -- Chemirine
	-- 		["i:151564"] = {matRate = 0.0300, minAmount = 1, maxAmount = 1, amountOfMats = 0.0060}, -- Empyrium
	-- 	},
	-- 	["i:151722"] = { -- Florid Malachite
	-- 		["i:151564"] = {matRate = 0.0300, minAmount = 1, maxAmount = 1, amountOfMats = 0.0060}, -- Empyrium
	-- 	},
	-- 	["i:151721"] = { -- Hesselian
	-- 		["i:151564"] = {matRate = 0.0300, minAmount = 1, maxAmount = 1, amountOfMats = 0.0060}, -- Empyrium
	-- 	},
	-- 	["i:151718"] = { -- Argulite
	-- 		["i:151564"] = {matRate = 0.0300, minAmount = 1, maxAmount = 1, amountOfMats = 0.0060}, -- Empyrium
	-- 	},
	-- 	["i:151579"] = { -- Labradorite
	-- 		["i:151564"] = {matRate = 0.0300, minAmount = 1, maxAmount = 1, amountOfMats = 0.0060}, -- Empyrium
	-- 	},
	-- 	["i:153706"] = { -- Kraken's Eye
	-- 		["i:152512"] = {matRate = 0.0425, minAmount = 1, maxAmount = 1, amountOfMats = 0.0085}, -- Monelite Ore
	-- 		["i:152579"] = {matRate = 0.0425, minAmount = 1, maxAmount = 1, amountOfMats = 0.0085}, -- Storm Silver Ore
	-- 		["i:152513"] = {matRate = 0.0450, minAmount = 1, maxAmount = 1, amountOfMats = 0.0090}, -- Platinum Ore
	-- 	},
	-- 	["i:168188"] = { -- Sage Agate
	-- 		["i:168185"] = {matRate = 0.1650, minAmount = 1, maxAmount = 1, amountOfMats = 0.0330}, -- Osmenite Ore
	-- 	},
	-- 	["i:168193"] = { -- Azsharine
	-- 		["i:168185"] = {matRate = 0.1650, minAmount = 1, maxAmount = 1, amountOfMats = 0.0330}, -- Osmenite Ore
	-- 	},
	-- 	["i:168189"] = { -- Dark Opal
	-- 		["i:168185"] = {matRate = 0.1650, minAmount = 1, maxAmount = 1, amountOfMats = 0.0330}, -- Osmenite Ore
	-- 	},
	-- 	["i:168190"] = { -- Lava Lazuli
	-- 		["i:168185"] = {matRate = 0.1650, minAmount = 1, maxAmount = 1, amountOfMats = 0.0330}, -- Osmenite Ore
	-- 	},
	-- 	["i:168191"] = { -- Sea Currant
	-- 		["i:168185"] = {matRate = 0.1650, minAmount = 1, maxAmount = 1, amountOfMats = 0.0330}, -- Osmenite Ore
	-- 	},
	-- 	["i:168192"] = { -- Sand Spinel
	-- 		["i:168185"] = {matRate = 0.1650, minAmount = 1, maxAmount = 1, amountOfMats = 0.0330}, -- Osmenite Ore
	-- 	},
	-- 	["i:168635"] = { -- Leviathan's Eye
	-- 		["i:168185"] = {matRate = 0.1200, minAmount = 1, maxAmount = 1, amountOfMats = 0.0240}, -- Osmenite Ore
	-- 	},
	-- 	-- ============== SL prospects ========================
	-- 	["i:173108"] = { -- oriblase
	-- 		["i:171833"] = {matRate = 0.35, minAmount = 2, maxAmount = 4, amountOfMats = 0.05}, -- elethium
	-- 		["i:171831"] = {matRate = 0.35, minAmount = 1, maxAmount = 2, amountOfMats = 0.0875}, -- phaedrum
	-- 		["i:171830"] = {matRate = 0.36, minAmount = 1, maxAmount = 2, amountOfMats = 0.0875}, -- oxxein
	-- 		["i:171829"] = {matRate = 0.36, minAmount = 1, maxAmount = 2, amountOfMats = 0.0875}, -- solenium
	-- 		["i:171828"] = {matRate = 0.33, minAmount = 1, maxAmount = 2, amountOfMats = 0.05}, -- laestrite
	-- 		["i:171832"] = {matRate = 0.36, minAmount = 1, maxAmount = 2, amountOfMats = 0.0875}, -- sinvyr
	-- 	},
	-- 	["i:173109"] = { -- angers eye
	-- 		["i:171833"] = {matRate = 0.28, minAmount = 2, maxAmount = 4, amountOfMats = 0.05}, -- elethium
	-- 		["i:171831"] = {matRate = 0.36, minAmount = 1, maxAmount = 2, amountOfMats = 0.0875}, -- phaedrum
	-- 		["i:171830"] = {matRate = 0.36, minAmount = 1, maxAmount = 2, amountOfMats = 0.0875}, -- oxxein
	-- 		["i:171829"] = {matRate = 0.33, minAmount = 1, maxAmount = 2, amountOfMats = 0.0875}, -- solenium
	-- 		["i:171828"] = {matRate = 0.34, minAmount = 1, maxAmount = 2, amountOfMats = 0.05}, -- laestrite
	-- 		["i:171832"] = {matRate = 0.31, minAmount = 1, maxAmount = 2, amountOfMats = 0.0875}, -- sinvyr
	-- 	},
	-- 	["i:173110"] = { -- umbryl
	-- 		["i:171833"] = {matRate = 0.35, minAmount = 2, maxAmount = 4, amountOfMats = 0.05}, -- elethium
	-- 		["i:171831"] = {matRate = 0.28, minAmount = 1, maxAmount = 2, amountOfMats = 0.0875}, -- phaedrum
	-- 		["i:171830"] = {matRate = 0.28, minAmount = 1, maxAmount = 2, amountOfMats = 0.0875}, -- oxxein
	-- 		["i:171829"] = {matRate = 0.31, minAmount = 1, maxAmount = 2, amountOfMats = 0.0875}, -- solenium
	-- 		["i:171828"] = {matRate = 0.33, minAmount = 1, maxAmount = 2, amountOfMats = 0.05}, -- laestrite
	-- 		["i:171832"] = {matRate = 0.33, minAmount = 1, maxAmount = 2, amountOfMats = 0.0875}, -- sinvyr
	-- 	},
	-- 	["i:173170"] = { -- essence of rebirth
	-- 		["i:171833"] = {matRate = 0.17, minAmount = 1, maxAmount = 2, amountOfMats = 0.05}, -- elethium
	-- 		["i:171831"] = {matRate = 0.18, minAmount = 1, maxAmount = 2, amountOfMats = 0.0875}, -- phaedrum
	-- 		["i:171828"] = {matRate = 0.03, minAmount = 1, maxAmount = 2, amountOfMats = 0.05}, -- laestrite
	-- 	},
	-- 	["i:173171"] = { -- essence of torment
	-- 		["i:171833"] = {matRate = 0.27, minAmount = 1, maxAmount = 2, amountOfMats = 0.05}, -- elethium
	-- 		["i:171832"] = {matRate = 0.19, minAmount = 1, maxAmount = 2, amountOfMats = 0.0875}, -- sinvyr
	-- 		["i:171828"] = {matRate = 0.03, minAmount = 1, maxAmount = 2, amountOfMats = 0.05}, -- laestrite
	-- 	},
	-- 	["i:173172"] = { -- essence of servitude
	-- 		["i:171833"] = {matRate = 0.31, minAmount = 1, maxAmount = 2, amountOfMats = 0.05}, -- elethium
	-- 		["i:171830"] = {matRate = 0.20, minAmount = 1, maxAmount = 2, amountOfMats = 0.0875}, -- oxxein
	-- 		["i:171828"] = {matRate = 0.02, minAmount = 1, maxAmount = 2, amountOfMats = 0.05}, -- laestrite
	-- 	},
	-- 	["i:173173"] = { -- essence of valor
	-- 		["i:171833"] = {matRate = 0.23, minAmount = 1, maxAmount = 2, amountOfMats = 0.05}, -- elethium
	-- 		["i:171829"] = {matRate = 0.18, minAmount = 1, maxAmount = 2, amountOfMats = 0.0875}, -- solenium
	-- 		["i:171828"] = {matRate = 0.019, minAmount = 1, maxAmount = 2, amountOfMats = 0.05}, -- laestrite
	-- 	},
	-- }

	-- this is an optimization of the above
	-- aka reversed where it is actual ore -> produced results
	-- this allows for faster lookups instead of having
	-- to loop through eached produced result to find the ore
	-- vs produced result -> ore
	PROSPECT_INFO = {
		["i:171830"] =     {
			["i:173172"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.2,
				["amountOfMats"] = 0.0875,
			  },
			["i:173109"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.36,
				["amountOfMats"] = 0.0875,
			  },
			["i:173108"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.36,
				["amountOfMats"] = 0.0875,
			  },
			["i:173110"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.28,
				["amountOfMats"] = 0.0875,
			  },
		  },
		["i:36912"] =     {
			["i:36932"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.18,
				["amountOfMats"] = 0.0365,
			  },
			["i:36930"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.04,
				["amountOfMats"] = 0.0083,
			  },
			["i:36917"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.18,
				["amountOfMats"] = 0.0365,
			  },
			["i:36921"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.04,
				["amountOfMats"] = 0.0083,
			  },
			["i:36926"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.18,
				["amountOfMats"] = 0.0365,
			  },
			["i:36920"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.18,
				["amountOfMats"] = 0.0365,
			  },
			["i:36929"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.18,
				["amountOfMats"] = 0.0365,
			  },
			["i:36933"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.04,
				["amountOfMats"] = 0.0083,
			  },
			["i:36923"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.18,
				["amountOfMats"] = 0.0365,
			  },
			["i:36927"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.04,
				["amountOfMats"] = 0.0083,
			  },
			["i:36918"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.04,
				["amountOfMats"] = 0.0083,
			  },
			["i:36924"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.04,
				["amountOfMats"] = 0.0083,
			  },
		  },
		["i:52185"] =     {
			["i:52190"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.045,
				["amountOfMats"] = 0.0091,
			  },
			["i:52191"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.045,
				["amountOfMats"] = 0.0091,
			  },
			["i:52177"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.18,
				["amountOfMats"] = 0.0365,
			  },
			["i:52179"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.18,
				["amountOfMats"] = 0.0365,
			  },
			["i:52181"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.18,
				["amountOfMats"] = 0.0365,
			  },
			["i:52180"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.18,
				["amountOfMats"] = 0.0365,
			  },
			["i:52192"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.045,
				["amountOfMats"] = 0.0091,
			  },
			["i:52193"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.045,
				["amountOfMats"] = 0.0091,
			  },
			["i:52194"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.045,
				["amountOfMats"] = 0.0091,
			  },
			["i:52178"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.18,
				["amountOfMats"] = 0.0365,
			  },
			["i:52182"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.18,
				["amountOfMats"] = 0.0365,
			  },
			["i:52195"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.045,
				["amountOfMats"] = 0.0091,
			  },
		  },
		["i:151564"] =     {
			["i:151719"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.03,
				["amountOfMats"] = 0.006,
			  },
			["i:151579"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.03,
				["amountOfMats"] = 0.006,
			  },
			["i:151722"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.03,
				["amountOfMats"] = 0.006,
			  },
			["i:151721"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.03,
				["amountOfMats"] = 0.006,
			  },
			["i:151720"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.03,
				["amountOfMats"] = 0.006,
			  },
			["i:151718"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.03,
				["amountOfMats"] = 0.006,
			  },
		  },
		["i:171832"] =     {
			["i:173110"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.33,
				["amountOfMats"] = 0.0875,
			  },
			["i:173109"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.31,
				["amountOfMats"] = 0.0875,
			  },
			["i:173108"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.36,
				["amountOfMats"] = 0.0875,
			  },
			["i:173171"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.19,
				["amountOfMats"] = 0.0875,
			  },
		  },
		["i:2770"] =     {
			["i:1210"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.1,
				["amountOfMats"] = 0.02,
			  },
			["i:818"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.5,
				["amountOfMats"] = 0.1,
			  },
			["i:774"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.5,
				["amountOfMats"] = 0.1,
			  },
		  },
		["i:72092"] =     {
			["i:76141"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.045,
				["amountOfMats"] = 0.0091,
			  },
			["i:76138"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.045,
				["amountOfMats"] = 0.0091,
			  },
			["i:76137"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.235,
				["amountOfMats"] = 0.0497,
			  },
			["i:76136"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.235,
				["amountOfMats"] = 0.0497,
			  },
			["i:76131"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.045,
				["amountOfMats"] = 0.0091,
			  },
			["i:76140"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.045,
				["amountOfMats"] = 0.0091,
			  },
			["i:76139"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.045,
				["amountOfMats"] = 0.0091,
			  },
			["i:76134"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.235,
				["amountOfMats"] = 0.0497,
			  },
			["i:76142"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.045,
				["amountOfMats"] = 0.0091,
			  },
			["i:76130"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.235,
				["amountOfMats"] = 0.0497,
			  },
			["i:76135"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.235,
				["amountOfMats"] = 0.0497,
			  },
			["i:76133"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.235,
				["amountOfMats"] = 0.0497,
			  },
		  },
		["i:171828"] =     {
			["i:173172"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.02,
				["amountOfMats"] = 0.05,
			  },
			["i:173109"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.34,
				["amountOfMats"] = 0.05,
			  },
			["i:173171"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.03,
				["amountOfMats"] = 0.05,
			  },
			["i:173173"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.019,
				["amountOfMats"] = 0.05,
			  },
			["i:173110"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.33,
				["amountOfMats"] = 0.05,
			  },
			["i:173108"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.33,
				["amountOfMats"] = 0.05,
			  },
			["i:173170"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.03,
				["amountOfMats"] = 0.05,
			  },
		  },
		["i:152513"] =     {
			["i:154125"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.115,
				["amountOfMats"] = 0.0237,
			  },
			["i:153705"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 4,
				["matRate"] = 0.21,
				["amountOfMats"] = 0.066,
			  },
			["i:154121"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.115,
				["amountOfMats"] = 0.0237,
			  },
			["i:153703"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 4,
				["matRate"] = 0.21,
				["amountOfMats"] = 0.066,
			  },
			["i:154123"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.115,
				["amountOfMats"] = 0.0237,
			  },
			["i:154124"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.115,
				["amountOfMats"] = 0.0237,
			  },
			["i:153704"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 4,
				["matRate"] = 0.21,
				["amountOfMats"] = 0.066,
			  },
			["i:153701"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 4,
				["matRate"] = 0.21,
				["amountOfMats"] = 0.066,
			  },
			["i:153706"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.045,
				["amountOfMats"] = 0.009,
			  },
			["i:154122"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.115,
				["amountOfMats"] = 0.0237,
			  },
			["i:153702"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 4,
				["matRate"] = 0.21,
				["amountOfMats"] = 0.066,
			  },
			["i:153700"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 4,
				["matRate"] = 0.21,
				["amountOfMats"] = 0.066,
			  },
			["i:154120"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.115,
				["amountOfMats"] = 0.0237,
			  },
		  },
		["i:36909"] =     {
			["i:36932"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.24,
				["amountOfMats"] = 0.0495,
			  },
			["i:36930"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.015,
				["amountOfMats"] = 0.003,
			  },
			["i:36917"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.24,
				["amountOfMats"] = 0.0495,
			  },
			["i:36921"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.015,
				["amountOfMats"] = 0.003,
			  },
			["i:36926"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.24,
				["amountOfMats"] = 0.0495,
			  },
			["i:36920"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.24,
				["amountOfMats"] = 0.0495,
			  },
			["i:36929"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.24,
				["amountOfMats"] = 0.0495,
			  },
			["i:36933"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.015,
				["amountOfMats"] = 0.003,
			  },
			["i:36923"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.24,
				["amountOfMats"] = 0.0495,
			  },
			["i:36927"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.015,
				["amountOfMats"] = 0.003,
			  },
			["i:36918"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.015,
				["amountOfMats"] = 0.003,
			  },
			["i:36924"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.015,
				["amountOfMats"] = 0.003,
			  },
		  },
		["i:152579"] =     {
			["i:154125"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.075,
				["amountOfMats"] = 0.0153,
			  },
			["i:153705"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 4,
				["matRate"] = 0.195,
				["amountOfMats"] = 0.0603,
			  },
			["i:154121"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.075,
				["amountOfMats"] = 0.0153,
			  },
			["i:153703"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 4,
				["matRate"] = 0.195,
				["amountOfMats"] = 0.0603,
			  },
			["i:154123"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.075,
				["amountOfMats"] = 0.0153,
			  },
			["i:154124"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.075,
				["amountOfMats"] = 0.0153,
			  },
			["i:153704"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 4,
				["matRate"] = 0.195,
				["amountOfMats"] = 0.0603,
			  },
			["i:153701"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 4,
				["matRate"] = 0.195,
				["amountOfMats"] = 0.0603,
			  },
			["i:153706"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.0425,
				["amountOfMats"] = 0.0085,
			  },
			["i:154122"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.075,
				["amountOfMats"] = 0.0153,
			  },
			["i:153702"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 4,
				["matRate"] = 0.195,
				["amountOfMats"] = 0.0603,
			  },
			["i:153700"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 4,
				["matRate"] = 0.195,
				["amountOfMats"] = 0.0603,
			  },
			["i:154120"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.075,
				["amountOfMats"] = 0.0153,
			  },
		  },
		["i:72094"] =     {
			["i:76141"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 3,
				["matRate"] = 0.16,
				["amountOfMats"] = 0.0341,
			  },
			["i:76138"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 3,
				["matRate"] = 0.16,
				["amountOfMats"] = 0.0341,
			  },
			["i:76137"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.16,
				["amountOfMats"] = 0.0341,
			  },
			["i:76136"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.16,
				["amountOfMats"] = 0.0341,
			  },
			["i:76131"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 3,
				["matRate"] = 0.165,
				["amountOfMats"] = 0.034,
			  },
			["i:76140"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 3,
				["matRate"] = 0.16,
				["amountOfMats"] = 0.0341,
			  },
			["i:76139"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 3,
				["matRate"] = 0.16,
				["amountOfMats"] = 0.0341,
			  },
			["i:76134"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.16,
				["amountOfMats"] = 0.0341,
			  },
			["i:76142"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 3,
				["matRate"] = 0.16,
				["amountOfMats"] = 0.0341,
			  },
			["i:76130"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.16,
				["amountOfMats"] = 0.0341,
			  },
			["i:76135"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.16,
				["amountOfMats"] = 0.0341,
			  },
			["i:76133"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.16,
				["amountOfMats"] = 0.0341,
			  },
		  },
		["i:123919"] =     {
			["i:130183"] =         {
				["minAmount"] = 2,
				["maxAmount"] = 5,
				["matRate"] = 0.01,
				["amountOfMats"] = 0.002,
			  },
			["i:130180"] =         {
				["minAmount"] = 2,
				["maxAmount"] = 5,
				["matRate"] = 0.01,
				["amountOfMats"] = 0.002,
			  },
			["i:130172"] =         {
				["minAmount"] = 2,
				["maxAmount"] = 5,
				["matRate"] = 0.055,
				["amountOfMats"] = 0.0385,
			  },
			["i:130175"] =         {
				["minAmount"] = 2,
				["maxAmount"] = 5,
				["matRate"] = 0.055,
				["amountOfMats"] = 0.0385,
			  },
			["i:130177"] =         {
				["minAmount"] = 2,
				["maxAmount"] = 5,
				["matRate"] = 0.055,
				["amountOfMats"] = 0.0385,
			  },
			["i:130178"] =         {
				["minAmount"] = 2,
				["maxAmount"] = 5,
				["matRate"] = 0.01,
				["amountOfMats"] = 0.002,
			  },
			["i:130176"] =         {
				["minAmount"] = 2,
				["maxAmount"] = 5,
				["matRate"] = 0.055,
				["amountOfMats"] = 0.0385,
			  },
			["i:130174"] =         {
				["minAmount"] = 2,
				["maxAmount"] = 5,
				["matRate"] = 0.055,
				["amountOfMats"] = 0.0385,
			  },
			["i:130173"] =         {
				["minAmount"] = 2,
				["maxAmount"] = 5,
				["matRate"] = 0.055,
				["amountOfMats"] = 0.0385,
			  },
			["i:130181"] =         {
				["minAmount"] = 2,
				["maxAmount"] = 5,
				["matRate"] = 0.01,
				["amountOfMats"] = 0.002,
			  },
			["i:130182"] =         {
				["minAmount"] = 2,
				["maxAmount"] = 5,
				["matRate"] = 0.01,
				["amountOfMats"] = 0.002,
			  },
			["i:130179"] =         {
				["minAmount"] = 2,
				["maxAmount"] = 5,
				["matRate"] = 0.01,
				["amountOfMats"] = 0.002,
			  },
		  },
		["i:123918"] =     {
			["i:130183"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.01,
				["amountOfMats"] = 0.002,
			  },
			["i:130180"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.01,
				["amountOfMats"] = 0.002,
			  },
			["i:130172"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.045,
				["amountOfMats"] = 0.01,
			  },
			["i:130175"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.045,
				["amountOfMats"] = 0.01,
			  },
			["i:130177"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.045,
				["amountOfMats"] = 0.01,
			  },
			["i:130178"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.01,
				["amountOfMats"] = 0.002,
			  },
			["i:130176"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.045,
				["amountOfMats"] = 0.01,
			  },
			["i:130174"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.045,
				["amountOfMats"] = 0.01,
			  },
			["i:130173"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.045,
				["amountOfMats"] = 0.01,
			  },
			["i:130181"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.01,
				["amountOfMats"] = 0.002,
			  },
			["i:130182"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.01,
				["amountOfMats"] = 0.002,
			  },
			["i:130179"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.01,
				["amountOfMats"] = 0.002,
			  },
		  },
		["i:72093"] =     {
			["i:76141"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.045,
				["amountOfMats"] = 0.0091,
			  },
			["i:76138"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.045,
				["amountOfMats"] = 0.0091,
			  },
			["i:76137"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.23,
				["amountOfMats"] = 0.0487,
			  },
			["i:76136"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.23,
				["amountOfMats"] = 0.0487,
			  },
			["i:76131"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.045,
				["amountOfMats"] = 0.0091,
			  },
			["i:76140"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.045,
				["amountOfMats"] = 0.0091,
			  },
			["i:76139"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.045,
				["amountOfMats"] = 0.0091,
			  },
			["i:76134"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.23,
				["amountOfMats"] = 0.0487,
			  },
			["i:76142"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.045,
				["amountOfMats"] = 0.0091,
			  },
			["i:76130"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.23,
				["amountOfMats"] = 0.0487,
			  },
			["i:76135"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.23,
				["amountOfMats"] = 0.0487,
			  },
			["i:76133"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.23,
				["amountOfMats"] = 0.0487,
			  },
		  },
		["i:23425"] =     {
			["i:23438"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.04,
				["amountOfMats"] = 0.008,
			  },
			["i:23112"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.18,
				["amountOfMats"] = 0.0365,
			  },
			["i:23441"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.04,
				["amountOfMats"] = 0.008,
			  },
			["i:23117"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.5,
				["amountOfMats"] = 0.0365,
			  },
			["i:23437"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.04,
				["amountOfMats"] = 0.008,
			  },
			["i:23436"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.04,
				["amountOfMats"] = 0.008,
			  },
			["i:23077"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.18,
				["amountOfMats"] = 0.0365,
			  },
			["i:23079"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.18,
				["amountOfMats"] = 0.0365,
			  },
			["i:23107"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.18,
				["amountOfMats"] = 0.0365,
			  },
			["i:21929"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.18,
				["amountOfMats"] = 0.0365,
			  },
			["i:23439"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.04,
				["amountOfMats"] = 0.008,
			  },
			["i:23440"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.04,
				["amountOfMats"] = 0.008,
			  },
		  },
		["i:53038"] =     {
			["i:52190"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.0125,
				["amountOfMats"] = 0.0025,
			  },
			["i:52191"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.0125,
				["amountOfMats"] = 0.0025,
			  },
			["i:52177"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.235,
				["amountOfMats"] = 0.05,
			  },
			["i:52179"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.235,
				["amountOfMats"] = 0.05,
			  },
			["i:52181"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.235,
				["amountOfMats"] = 0.05,
			  },
			["i:52180"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.235,
				["amountOfMats"] = 0.05,
			  },
			["i:52192"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.0125,
				["amountOfMats"] = 0.0025,
			  },
			["i:52193"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.0125,
				["amountOfMats"] = 0.0025,
			  },
			["i:52194"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.0125,
				["amountOfMats"] = 0.0025,
			  },
			["i:52178"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.235,
				["amountOfMats"] = 0.05,
			  },
			["i:52182"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.235,
				["amountOfMats"] = 0.05,
			  },
			["i:52195"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.0125,
				["amountOfMats"] = 0.0025,
			  },
		  },
		["i:72103"] =     {
			["i:76141"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 3,
				["matRate"] = 0.16,
				["amountOfMats"] = 0.0341,
			  },
			["i:76138"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 3,
				["matRate"] = 0.16,
				["amountOfMats"] = 0.0341,
			  },
			["i:76137"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.16,
				["amountOfMats"] = 0.0341,
			  },
			["i:76136"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.16,
				["amountOfMats"] = 0.0341,
			  },
			["i:76131"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 3,
				["matRate"] = 0.16,
				["amountOfMats"] = 0.0341,
			  },
			["i:76140"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 3,
				["matRate"] = 0.16,
				["amountOfMats"] = 0.0341,
			  },
			["i:76139"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 3,
				["matRate"] = 0.16,
				["amountOfMats"] = 0.0341,
			  },
			["i:76134"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.16,
				["amountOfMats"] = 0.0341,
			  },
			["i:76142"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 3,
				["matRate"] = 0.16,
				["amountOfMats"] = 0.0341,
			  },
			["i:76130"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.16,
				["amountOfMats"] = 0.0341,
			  },
			["i:76135"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.16,
				["amountOfMats"] = 0.0341,
			  },
			["i:76133"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.16,
				["amountOfMats"] = 0.0341,
			  },
		  },
		["i:3858"] =     {
			["i:12361"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.0225,
				["amountOfMats"] = 0.005,
			  },
			["i:12799"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.0225,
				["amountOfMats"] = 0.005,
			  },
			["i:7909"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.35,
				["amountOfMats"] = 0.0725,
			  },
			["i:12364"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.0225,
				["amountOfMats"] = 0.005,
			  },
			["i:12800"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.0225,
				["amountOfMats"] = 0.005,
			  },
			["i:3864"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.35,
				["amountOfMats"] = 0.0725,
			  },
			["i:7910"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.35,
				["amountOfMats"] = 0.0725,
			  },
		  },
		["i:2771"] =     {
			["i:1529"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.0325,
				["amountOfMats"] = 0.0065,
			  },
			["i:1210"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.38,
				["amountOfMats"] = 0.08,
			  },
			["i:1705"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.38,
				["amountOfMats"] = 0.08,
			  },
			["i:1206"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.38,
				["amountOfMats"] = 0.08,
			  },
			["i:3864"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.0325,
				["amountOfMats"] = 0.0065,
			  },
			["i:7909"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.0325,
				["amountOfMats"] = 0.0065,
			  },
		  },
		["i:10620"] =     {
			["i:12361"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.31,
				["amountOfMats"] = 0.066,
			  },
			["i:12799"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.31,
				["amountOfMats"] = 0.066,
			  },
			["i:12364"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.31,
				["amountOfMats"] = 0.066,
			  },
			["i:12800"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.31,
				["amountOfMats"] = 0.066,
			  },
			["i:7910"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.155,
				["amountOfMats"] = 0.032,
			  },
		  },
		["i:36910"] =     {
			["i:36932"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.25,
				["amountOfMats"] = 0.0525,
			  },
			["i:36928"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.045,
				["amountOfMats"] = 0.0093,
			  },
			["i:36917"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.25,
				["amountOfMats"] = 0.0525,
			  },
			["i:36921"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.045,
				["amountOfMats"] = 0.0093,
			  },
			["i:36934"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.045,
				["amountOfMats"] = 0.0093,
			  },
			["i:36920"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.25,
				["amountOfMats"] = 0.0525,
			  },
			["i:36929"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.25,
				["amountOfMats"] = 0.0525,
			  },
			["i:36923"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.25,
				["amountOfMats"] = 0.0525,
			  },
			["i:36918"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.045,
				["amountOfMats"] = 0.0093,
			  },
			["i:36924"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.045,
				["amountOfMats"] = 0.0093,
			  },
			["i:36919"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.045,
				["amountOfMats"] = 0.0093,
			  },
			["i:36931"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.045,
				["amountOfMats"] = 0.0093,
			  },
			["i:36926"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.25,
				["amountOfMats"] = 0.0525,
			  },
			["i:36933"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.045,
				["amountOfMats"] = 0.0093,
			  },
			["i:36930"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.045,
				["amountOfMats"] = 0.0093,
			  },
			["i:36922"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.045,
				["amountOfMats"] = 0.0093,
			  },
			["i:36925"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.045,
				["amountOfMats"] = 0.0093,
			  },
			["i:36927"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.045,
				["amountOfMats"] = 0.0093,
			  },
		  },
		["i:152512"] =     {
			["i:154125"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.0425,
				["amountOfMats"] = 0.0086,
			  },
			["i:153705"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 4,
				["matRate"] = 0.18,
				["amountOfMats"] = 0.0551,
			  },
			["i:154121"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.0425,
				["amountOfMats"] = 0.0086,
			  },
			["i:153703"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 4,
				["matRate"] = 0.18,
				["amountOfMats"] = 0.0551,
			  },
			["i:154123"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.0425,
				["amountOfMats"] = 0.0086,
			  },
			["i:154124"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.0425,
				["amountOfMats"] = 0.0086,
			  },
			["i:153704"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 4,
				["matRate"] = 0.18,
				["amountOfMats"] = 0.0551,
			  },
			["i:153701"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 4,
				["matRate"] = 0.18,
				["amountOfMats"] = 0.0551,
			  },
			["i:153706"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.0425,
				["amountOfMats"] = 0.0085,
			  },
			["i:154122"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.0425,
				["amountOfMats"] = 0.0086,
			  },
			["i:153702"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 4,
				["matRate"] = 0.18,
				["amountOfMats"] = 0.0551,
			  },
			["i:153700"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 4,
				["matRate"] = 0.18,
				["amountOfMats"] = 0.0551,
			  },
			["i:154120"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.0425,
				["amountOfMats"] = 0.0086,
			  },
		  },
		["i:52183"] =     {
			["i:52190"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.075,
				["amountOfMats"] = 0.0152,
			  },
			["i:52191"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.075,
				["amountOfMats"] = 0.0152,
			  },
			["i:52177"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.165,
				["amountOfMats"] = 0.033,
			  },
			["i:52179"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.165,
				["amountOfMats"] = 0.033,
			  },
			["i:52181"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.165,
				["amountOfMats"] = 0.033,
			  },
			["i:52180"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.165,
				["amountOfMats"] = 0.033,
			  },
			["i:52192"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.075,
				["amountOfMats"] = 0.0152,
			  },
			["i:52193"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.075,
				["amountOfMats"] = 0.0152,
			  },
			["i:52194"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.075,
				["amountOfMats"] = 0.0152,
			  },
			["i:52178"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.165,
				["amountOfMats"] = 0.033,
			  },
			["i:52182"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.165,
				["amountOfMats"] = 0.033,
			  },
			["i:52195"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.075,
				["amountOfMats"] = 0.0152,
			  },
		  },
		["i:168185"] =     {
			["i:168635"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.12,
				["amountOfMats"] = 0.024,
			  },
			["i:168189"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.165,
				["amountOfMats"] = 0.033,
			  },
			["i:168191"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.165,
				["amountOfMats"] = 0.033,
			  },
			["i:168192"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.165,
				["amountOfMats"] = 0.033,
			  },
			["i:168193"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.165,
				["amountOfMats"] = 0.033,
			  },
			["i:168188"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.165,
				["amountOfMats"] = 0.033,
			  },
			["i:168190"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.165,
				["amountOfMats"] = 0.033,
			  },
		  },
		["i:171829"] =     {
			["i:173173"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.18,
				["amountOfMats"] = 0.0875,
			  },
			["i:173109"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.33,
				["amountOfMats"] = 0.0875,
			  },
			["i:173108"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.36,
				["amountOfMats"] = 0.0875,
			  },
			["i:173110"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.31,
				["amountOfMats"] = 0.0875,
			  },
		  },
		["i:171833"] =     {
			["i:173172"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.31,
				["amountOfMats"] = 0.05,
			  },
			["i:173109"] =         {
				["minAmount"] = 2,
				["maxAmount"] = 4,
				["matRate"] = 0.28,
				["amountOfMats"] = 0.05,
			  },
			["i:173171"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.27,
				["amountOfMats"] = 0.05,
			  },
			["i:173173"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.23,
				["amountOfMats"] = 0.05,
			  },
			["i:173110"] =         {
				["minAmount"] = 2,
				["maxAmount"] = 4,
				["matRate"] = 0.35,
				["amountOfMats"] = 0.05,
			  },
			["i:173108"] =         {
				["minAmount"] = 2,
				["maxAmount"] = 4,
				["matRate"] = 0.35,
				["amountOfMats"] = 0.05,
			  },
			["i:173170"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.17,
				["amountOfMats"] = 0.05,
			  },
		  },
		["i:171831"] =     {
			["i:173110"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.28,
				["amountOfMats"] = 0.0875,
			  },
			["i:173109"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.36,
				["amountOfMats"] = 0.0875,
			  },
			["i:173108"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.35,
				["amountOfMats"] = 0.0875,
			  },
			["i:173170"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.18,
				["amountOfMats"] = 0.0875,
			  },
		  },
		["i:23424"] =     {
			["i:23438"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.015,
				["amountOfMats"] = 0.003,
			  },
			["i:23112"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.18,
				["amountOfMats"] = 0.0365,
			  },
			["i:23441"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.015,
				["amountOfMats"] = 0.003,
			  },
			["i:23117"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.18,
				["amountOfMats"] = 0.0365,
			  },
			["i:23437"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.015,
				["amountOfMats"] = 0.003,
			  },
			["i:23436"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.015,
				["amountOfMats"] = 0.003,
			  },
			["i:23077"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.18,
				["amountOfMats"] = 0.0365,
			  },
			["i:23079"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.18,
				["amountOfMats"] = 0.0365,
			  },
			["i:23107"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.18,
				["amountOfMats"] = 0.0365,
			  },
			["i:21929"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.18,
				["amountOfMats"] = 0.0365,
			  },
			["i:23439"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.015,
				["amountOfMats"] = 0.003,
			  },
			["i:23440"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.015,
				["amountOfMats"] = 0.003,
			  },
		  },
		["i:2772"] =     {
			["i:1529"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.35,
				["amountOfMats"] = 0.07,
			  },
			["i:7909"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.05,
				["amountOfMats"] = 0.01,
			  },
			["i:1705"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.35,
				["amountOfMats"] = 0.07,
			  },
			["i:3864"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 2,
				["matRate"] = 0.38,
				["amountOfMats"] = 0.0785,
			  },
			["i:7910"] =         {
				["minAmount"] = 1,
				["maxAmount"] = 1,
				["matRate"] = 0.05,
				["amountOfMats"] = 0.01,
			  },
		  },
	  };
end

-- From TSM so we can be conistent
-- added in SL mill rate so far
if (not Utils.IsClassic()) then
	--MILL_INFO =	{
		-- ======================================= Common Pigments =======================================
	--	["i:39151"] = { -- Alabaster Pigment (Ivory / Moonglow Ink)
	--		["i:765"] = 0.5,
	--		["i:2447"] = 0.5,
	--		["i:2449"] = 0.6,
	--	},
	--	["i:39343"] = { -- Azure Pigment (Ink of the Sea)
	--		["i:39969"] = 0.5,
	--		["i:36904"] = 0.5,
	--		["i:36907"] = 0.5,
	--		["i:36901"] = 0.5,
	--		["i:39970"] = 0.5,
	--		["i:37921"] = 0.5,
	--		["i:36905"] = 0.6,
	--		["i:36906"] = 0.6,
	--		["i:36903"] = 0.6,
	--	},
	--	["i:61979"] = { -- Ashen Pigment (Blackfallow Ink)
	--		["i:52983"] = 0.5,
	--		["i:52984"] = 0.5,
	--		["i:52985"] = 0.5,
	--		["i:52986"] = 0.5,
	--		["i:52987"] = 0.6,
	--		["i:52988"] = 0.6,
	--	},
	--	["i:39334"] = { -- Dusky Pigment (Midnight Ink)
	--		["i:785"] = 0.5,
	--		["i:2450"] = 0.5,
	--		["i:2452"] = 0.5,
	--		["i:2453"] = 0.6,
	--		["i:3820"] = 0.6,
	--	},
	--	["i:39339"] = { -- Emerald Pigment (Jadefire Ink)
	--		["i:3818"] = 0.5,
	--		["i:3821"] = 0.5,
	--		["i:3358"] = 0.6,
	--		["i:3819"] = 0.6,
	--	},
	--	["i:39338"] = { -- Golden Pigment (Lion's Ink)
	--		["i:3355"] = 0.5,
	--		["i:3369"] = 0.5,
	--		["i:3356"] = 0.6,
	--		["i:3357"] = 0.6,
	--	},
	--	["i:39342"] = { -- Nether Pigment (Ethereal Ink)
	--		["i:22785"] = 0.5,
	--		["i:22786"] = 0.5,
	--		["i:22787"] = 0.5,
	--		["i:22789"] = 0.5,
	--		["i:22790"] = 0.6,
	--		["i:22791"] = 0.6,
	--		["i:22792"] = 0.6,
	--		["i:22793"] = 0.6,
	--	},
	--	["i:79251"] = { -- Shadow Pigment (Ink of Dreams)
	--		["i:72237"] = 0.5,
	--		["i:72234"] = 0.5,
	--		["i:79010"] = 0.5,
	--		["i:72235"] = 0.5,
	--		["i:89639"] = 0.5,
	--		["i:79011"] = 0.6,
	--	},
	--	["i:39341"] = { -- Silvery Pigment (Shimmering Ink)
	--		["i:13463"] = 0.5,
	--		["i:13464"] = 0.5,
	--		["i:13465"] = 0.6,
	--		["i:13466"] = 0.6,
	--		["i:13467"] = 0.6,
	--	},
	--	["i:39340"] = { -- Violet Pigment (Celestial Ink)
	--		["i:4625"] = 0.5,
	--		["i:8831"] = 0.5,
	--		["i:8838"] = 0.5,
	--		["i:8839"] = 0.6,
	--		["i:8845"] = 0.6,
	--		["i:8846"] = 0.6,
	--	},
	--	["i:114931"] = { -- Cerulean Pigment (Warbinder's Ink)
	--		["i:109124"] = 0.42,
	--		["i:109125"] = 0.42,
	--		["i:109126"] = 0.42,
	--		["i:109127"] = 0.42,
	--		["i:109128"] = 0.42,
	--		["i:109129"] = 0.42,
	--	},
	--	["i:129032"] = { -- Roseate Pigment (No Legion Ink)
	--		["i:124101"] = 0.42,
	--		["i:124102"] = 0.42,
	--		["i:124103"] = 0.42,
	--		["i:124104"] = 0.47,
	--		["i:124105"] = 1.22,
	--		["i:124106"] = 0.42,
	--		["i:128304"] = 0.2,
	--		["i:151565"] = 0.43,
	--	},
		-- ======================================= Rare Pigments =======================================
	--	["i:43109"] = { -- Icy Pigment (Snowfall Ink)
	--		["i:39969"] = 0.05,
	--		["i:36904"] = 0.05,
	--		["i:36907"] = 0.05,
	--		["i:36901"] = 0.05,
	--		["i:39970"] = 0.05,
	--		["i:37921"] = 0.05,
	--		["i:36905"] = 0.1,
	--		["i:36906"] = 0.1,
	--		["i:36903"] = 0.1,
	--	},
	--	["i:61980"] = { -- Burning Embers (Inferno Ink)
	--		["i:52983"] = 0.05,
	--		["i:52984"] = 0.05,
	--		["i:52985"] = 0.05,
	--		["i:52986"] = 0.05,
	--		["i:52987"] = 0.1,
	--		["i:52988"] = 0.1,
	--	},
	--	["i:43104"] = { -- Burnt Pigment (Dawnstar Ink)
	--		["i:3356"] = 0.1,
	--		["i:3357"] = 0.1,
	--		["i:3369"] = 0.05,
	--		["i:3355"] = 0.05,
	--	},
	--	["i:43108"] = { -- Ebon Pigment (Darkflame Ink)
	--		["i:22792"] = 0.1,
	--		["i:22790"] = 0.1,
	--		["i:22791"] = 0.1,
	--		["i:22793"] = 0.1,
	--		["i:22786"] = 0.05,
	--		["i:22785"] = 0.05,
	--		["i:22787"] = 0.05,
	--		["i:22789"] = 0.05,
	--	},
	--	["i:43105"] = { -- Indigo Pigment (Royal Ink)
	--		["i:3358"] = 0.1,
	--		["i:3819"] = 0.1,
	--		["i:3821"] = 0.05,
	--		["i:3818"] = 0.05,
	--	},
	--	["i:79253"] = { -- Misty Pigment (Starlight Ink)
	--		["i:72237"] = 0.05,
	--		["i:72234"] = 0.05,
	--		["i:79010"] = 0.05,
	--		["i:72235"] = 0.05,
	--		["i:79011"] = 0.1,
	--		["i:89639"] = 0.05,
	--	},
	--	["i:43106"] = { -- Ruby Pigment (Fiery Ink)
	--		["i:4625"] = 0.05,
	--		["i:8838"] = 0.05,
	--		["i:8831"] = 0.05,
	--		["i:8845"] = 0.1,
	--		["i:8846"] = 0.1,
	--		["i:8839"] = 0.1,
	--	},
	--	["i:43107"] = { -- Sapphire Pigment (Ink of the Sky)
	--		["i:13463"] = 0.05,
	--		["i:13464"] = 0.05,
	--		["i:13465"] = 0.1,
	--		["i:13466"] = 0.1,
	--		["i:13467"] = 0.1,
	--	},
	--	["i:43103"] = { -- Verdant Pigment (Hunter's Ink)
	--		["i:2453"] = 0.1,
	--		["i:3820"] = 0.1,
	--		["i:2450"] = 0.05,
	--		["i:785"] = 0.05,
	--		["i:2452"] = 0.05,
	--	},
	--	["i:129034"] = { -- Sallow Pigment (No Legion Ink)
	--		["i:124101"] = 0.04,
	--		["i:124102"] = 0.04,
	--		["i:124103"] = 0.05,
	--		["i:124104"] = 0.05,
	--		["i:124105"] = 0.04,
	--		["i:124106"] = 2.14,
	--		["i:128304"] = 0.0018,
	--		["i:151565"] = 0.048,
	--	},
		-- ======================================= BFA Pigments ========================================
	--	["i:153669"] = { -- Viridescent Pigment
	--		["i:152505"] = 0.1325,
	--		["i:152506"] = 0.1325,
	--		["i:152507"] = 0.1325,
	--		["i:152508"] = 0.1325,
	--		["i:152509"] = 0.1325,
	--		["i:152511"] = 0.1325,
	--		["i:152510"] = 0.325,
	--	},
	--	["i:153636"] = { -- Crimson Pigment
	--		["i:152505"] = 0.315,
	--		["i:152506"] = 0.315,
	--		["i:152507"] = 0.315,
	--		["i:152508"] = 0.315,
	--		["i:152509"] = 0.315,
	--		["i:152511"] = 0.315,
	--		["i:152510"] = 0.315,
	--	},
	--	["i:153635"] = { -- Ultramarine Pigment
	--		["i:152505"] = 0.825,
	--		["i:152506"] = 0.825,
	--		["i:152507"] = 0.825,
	--		["i:152508"] = 0.825,
	--		["i:152509"] = 0.825,
	--		["i:152511"] = 0.825,
	--		["i:152510"] = 0.825,
	--	},
	--	["i:168662"] = { -- Maroon Pigment
	--		["i:168487"] = 0.6,
	--	},
		-- ====================== SL Pigments =========================
	--	["i:173057"] = { -- Luminous Pigment
	--		["i:170554"] = 0.202, -- vigil
	--		["i:168586"] = 0.202, -- rising glory
	--		["i:168589"] = 0.15, -- marrow root
	--		["i:168583"] = 0.096, -- widow
	--		["i:169701"] = 0.091, -- death
	--		["i:171315"] = 0.232, -- night shade
	--	},
	--	["i:173056"] = { -- Umbral Pigment
	--		["i:170554"] = 0.092, -- vigil
	--		["i:168586"] = 0.092, -- rising glory
	--		["i:168589"] = 0.140, -- marrow root
	--		["i:168583"] = 0.194, -- widow
	--		["i:169701"] = 0.204, -- death
	--		["i:171315"] = 0.263, -- night shade
	--	},
	--	["i:175788"] = {
	--		["i:170554"] = 0.004, -- vigil
	--		["i:168586"] = 0.004, -- rising glory
	--		["i:168589"] = 0.005, -- marrow root
	--		["i:168583"] = 0.005, -- widow
	--		["i:169701"] = 0.004, -- death
	--		["i:171315"] = 0.305, -- night shade
	--	}
	--}

	-- this is an optimization of the above
	-- aka reversed where it is actual herb -> produced results
	-- this allows for faster lookups instead of having
	-- to loop through eached produced result to find the herb
	-- vs produced result -> herbs
	MILL_INFO = {
		["i:765"] =     {
			["i:39151"] = 0.5,
		  },
		["i:152510"] =     {
			["i:153636"] = 0.315,
			["i:153635"] = 0.825,
			["i:153669"] = 0.325,
		  },
		["i:168487"] =     {
			["i:168662"] = 0.6,
		  },
		["i:170554"] =     {
			["i:173056"] = 0.092,
			["i:173057"] = 0.202,
			["i:175788"] = 0.004,
		  },
		["i:124103"] =     {
			["i:129034"] = 0.05,
			["i:129032"] = 0.42,
		  },
		["i:152508"] =     {
			["i:153636"] = 0.315,
			["i:153635"] = 0.825,
			["i:153669"] = 0.1325,
		  },
		["i:169701"] =     {
			["i:173056"] = 0.204,
			["i:173057"] = 0.091,
			["i:175788"] = 0.004,
		  },
		["i:109129"] =     {
			["i:114931"] = 0.42,
		  },
		["i:36904"] =     {
			["i:43109"] = 0.05,
			["i:39343"] = 0.5,
		  },
		["i:2452"] =     {
			["i:39334"] = 0.5,
			["i:43103"] = 0.05,
		  },
		["i:171315"] =     {
			["i:173056"] = 0.263,
			["i:173057"] = 0.232,
			["i:175788"] = 0.305,
		  },
		["i:72234"] =     {
			["i:79253"] = 0.05,
			["i:79251"] = 0.5,
		  },
		["i:79010"] =     {
			["i:79253"] = 0.05,
			["i:79251"] = 0.5,
		  },
		["i:109128"] =     {
			["i:114931"] = 0.42,
		  },
		["i:22786"] =     {
			["i:39342"] = 0.5,
			["i:43108"] = 0.05,
		  },
		["i:36907"] =     {
			["i:43109"] = 0.05,
			["i:39343"] = 0.5,
		  },
		["i:72237"] =     {
			["i:79253"] = 0.05,
			["i:79251"] = 0.5,
		  },
		["i:52984"] =     {
			["i:61980"] = 0.05,
			["i:61979"] = 0.5,
		  },
		["i:37921"] =     {
			["i:43109"] = 0.05,
			["i:39343"] = 0.5,
		  },
		["i:152509"] =     {
			["i:153636"] = 0.315,
			["i:153635"] = 0.825,
			["i:153669"] = 0.1325,
		  },
		["i:3357"] =     {
			["i:43104"] = 0.1,
			["i:39338"] = 0.6,
		  },
		["i:4625"] =     {
			["i:43106"] = 0.05,
			["i:39340"] = 0.5,
		  },
		["i:152505"] =     {
			["i:153636"] = 0.315,
			["i:153635"] = 0.825,
			["i:153669"] = 0.1325,
		  },
		["i:22785"] =     {
			["i:39342"] = 0.5,
			["i:43108"] = 0.05,
		  },
		["i:3820"] =     {
			["i:39334"] = 0.6,
			["i:43103"] = 0.1,
		  },
		["i:22787"] =     {
			["i:39342"] = 0.5,
			["i:43108"] = 0.05,
		  },
		["i:36905"] =     {
			["i:43109"] = 0.1,
			["i:39343"] = 0.6,
		  },
		["i:3818"] =     {
			["i:39339"] = 0.5,
			["i:43105"] = 0.05,
		  },
		["i:124104"] =     {
			["i:129034"] = 0.05,
			["i:129032"] = 0.47,
		  },
		["i:152511"] =     {
			["i:153636"] = 0.315,
			["i:153635"] = 0.825,
			["i:153669"] = 0.1325,
		  },
		["i:52988"] =     {
			["i:61980"] = 0.1,
			["i:61979"] = 0.6,
		  },
		["i:8839"] =     {
			["i:43106"] = 0.1,
			["i:39340"] = 0.6,
		  },
		["i:109127"] =     {
			["i:114931"] = 0.42,
		  },
		["i:36901"] =     {
			["i:43109"] = 0.05,
			["i:39343"] = 0.5,
		  },
		["i:109126"] =     {
			["i:114931"] = 0.42,
		  },
		["i:22790"] =     {
			["i:39342"] = 0.6,
			["i:43108"] = 0.1,
		  },
		["i:3819"] =     {
			["i:39339"] = 0.6,
			["i:43105"] = 0.1,
		  },
		["i:3358"] =     {
			["i:39339"] = 0.6,
			["i:43105"] = 0.1,
		  },
		["i:2450"] =     {
			["i:39334"] = 0.5,
			["i:43103"] = 0.05,
		  },
		["i:785"] =     {
			["i:39334"] = 0.5,
			["i:43103"] = 0.05,
		  },
		["i:13463"] =     {
			["i:39341"] = 0.5,
			["i:43107"] = 0.05,
		  },
		["i:72235"] =     {
			["i:79253"] = 0.05,
			["i:79251"] = 0.5,
		  },
		["i:124101"] =     {
			["i:129034"] = 0.04,
			["i:129032"] = 0.42,
		  },
		["i:79011"] =     {
			["i:79253"] = 0.1,
			["i:79251"] = 0.6,
		  },
		["i:2449"] =     {
			["i:39151"] = 0.6,
		  },
		["i:89639"] =     {
			["i:79253"] = 0.05,
			["i:79251"] = 0.5,
		  },
		["i:13465"] =     {
			["i:39341"] = 0.6,
			["i:43107"] = 0.1,
		  },
		["i:151565"] =     {
			["i:129034"] = 0.048,
			["i:129032"] = 0.43,
		  },
		["i:124105"] =     {
			["i:129034"] = 0.04,
			["i:129032"] = 1.22,
		  },
		["i:36906"] =     {
			["i:43109"] = 0.1,
			["i:39343"] = 0.6,
		  },
		["i:128304"] =     {
			["i:129034"] = 0.0018,
			["i:129032"] = 0.2,
		  },
		["i:39970"] =     {
			["i:43109"] = 0.05,
			["i:39343"] = 0.5,
		  },
		["i:22793"] =     {
			["i:39342"] = 0.6,
			["i:43108"] = 0.1,
		  },
		["i:2453"] =     {
			["i:39334"] = 0.6,
			["i:43103"] = 0.1,
		  },
		["i:109124"] =     {
			["i:114931"] = 0.42,
		  },
		["i:109125"] =     {
			["i:114931"] = 0.42,
		  },
		["i:8831"] =     {
			["i:43106"] = 0.05,
			["i:39340"] = 0.5,
		  },
		["i:52985"] =     {
			["i:61980"] = 0.05,
			["i:61979"] = 0.5,
		  },
		["i:13466"] =     {
			["i:39341"] = 0.6,
			["i:43107"] = 0.1,
		  },
		["i:152506"] =     {
			["i:153636"] = 0.315,
			["i:153635"] = 0.825,
			["i:153669"] = 0.1325,
		  },
		["i:22791"] =     {
			["i:39342"] = 0.6,
			["i:43108"] = 0.1,
		  },
		["i:152507"] =     {
			["i:153636"] = 0.315,
			["i:153635"] = 0.825,
			["i:153669"] = 0.1325,
		  },
		["i:22789"] =     {
			["i:39342"] = 0.5,
			["i:43108"] = 0.05,
		  },
		["i:13464"] =     {
			["i:39341"] = 0.5,
			["i:43107"] = 0.05,
		  },
		["i:8838"] =     {
			["i:43106"] = 0.05,
			["i:39340"] = 0.5,
		  },
		["i:3821"] =     {
			["i:39339"] = 0.5,
			["i:43105"] = 0.05,
		  },
		["i:13467"] =     {
			["i:39341"] = 0.6,
			["i:43107"] = 0.1,
		  },
		["i:124106"] =     {
			["i:129034"] = 2.14,
			["i:129032"] = 0.42,
		  },
		["i:52987"] =     {
			["i:61980"] = 0.1,
			["i:61979"] = 0.6,
		  },
		["i:3355"] =     {
			["i:43104"] = 0.05,
			["i:39338"] = 0.5,
		  },
		["i:8845"] =     {
			["i:43106"] = 0.1,
			["i:39340"] = 0.6,
		  },
		["i:36903"] =     {
			["i:43109"] = 0.1,
			["i:39343"] = 0.6,
		  },
		["i:168583"] =     {
			["i:173056"] = 0.194,
			["i:173057"] = 0.096,
			["i:175788"] = 0.005,
		  },
		["i:168586"] =     {
			["i:173056"] = 0.092,
			["i:173057"] = 0.202,
			["i:175788"] = 0.004,
		  },
		["i:168589"] =     {
			["i:173056"] = 0.14,
			["i:173057"] = 0.15,
			["i:175788"] = 0.005,
		  },
		["i:22792"] =     {
			["i:39342"] = 0.6,
			["i:43108"] = 0.1,
		  },
		["i:124102"] =     {
			["i:129034"] = 0.04,
			["i:129032"] = 0.42,
		  },
		["i:39969"] =     {
			["i:43109"] = 0.05,
			["i:39343"] = 0.5,
		  },
		["i:8846"] =     {
			["i:43106"] = 0.1,
			["i:39340"] = 0.6,
		  },
		["i:3369"] =     {
			["i:43104"] = 0.05,
			["i:39338"] = 0.5,
		  },
		["i:52983"] =     {
			["i:61980"] = 0.05,
			["i:61979"] = 0.5,
		  },
		["i:52986"] =     {
			["i:61980"] = 0.05,
			["i:61979"] = 0.5,
		  },
		["i:2447"] =     {
			["i:39151"] = 0.5,
		  },
		["i:3356"] =     {
			["i:43104"] = 0.1,
			["i:39338"] = 0.6,
		  },
	  }
end

-- URLs for non-disenchantable items:
-- 	http://www.wowhead.com/items=2?filter=qu=2%3A3%3A4%3Bcr=8%3A2%3Bcrs=2%3A2%3Bcrv=0%3A0
-- 	http://www.wowhead.com/items=4?filter=qu=2%3A3%3A4%3Bcr=8%3A2%3Bcrs=2%3A2%3Bcrv=0%3A0
-- also includes all tabards
local NON_DISENCHANTABLE_ITEMS = {
	["i:11290"] = true,
	["i:11289"] = true,
	["i:11288"] = true,
	["i:11287"] = true,
	["i:60223"] = true,
	["i:52252"] = true,
	["i:20406"] = true,
	["i:20407"] = true,
	["i:20408"] = true,
	["i:21766"] = true,
	["i:52485"] = true,
	["i:52486"] = true,
	["i:52487"] = true,
	["i:52488"] = true,
	["i:75274"] = true,
	["i:84661"] = true,
	["i:97826"] = true,
	["i:97827"] = true,
	["i:97828"] = true,
	["i:97829"] = true,
	["i:97830"] = true,
	["i:97831"] = true,
	["i:97832"] = true,
	["i:109262"] = true,
	["i:178991"] = true,
	["i:52252"] = true,
	["i:178336"] = true,
	["i:179282"] = true,
	["i:43155"] = true,
	["i:46874"] = true,
	["i:45585"] = true,
	["i:23705"] = true,
	["i:25549"] = true,
	["i:45574"] = true,
	["i:45581"] = true,
	["i:43154"] = true,
	["i:23192"] = true,
	["i:38311"] = true,
	["i:180431"] = true,
	["i:140575"] = true,
	["i:23709"] = true,
	["i:20131"] = true,
	["i:64882"] = true,
	["i:38312"] = true,
	["i:38314"] = true,
	["i:45584"] = true,
	["i:28788"] = true,
	["i:22999"] = true,
	["i:43157"] = true,
	["i:43349"] = true,
	["i:40643"] = true,
	["i:35221"] = true,
	["i:160546"] = true,
	["i:38310"] = true,
	["i:45579"] = true,
	["i:5976"] = true,
	["i:45583"] = true,
	["i:31404"] = true,
	["i:31405"] = true,
	["i:38313"] = true,
	["i:38309"] = true,
	["i:152399"] = true,
	["i:95592"] = true,
	["i:31780"] = true,
	["i:45577"] = true,
	["i:46818"] = true,
	["i:65909"] = true,
	["i:69210"] = true,
	["i:36941"] = true,
	["i:20132"] = true,
	["i:163055"] = true,
	["i:178120"] = true,
	["i:174069"] = true,
	["i:63378"] = true,
	["i:138429"] = true,
	["i:152669"] = true,
	["i:165010"] = true,
	["i:51534"] = true,
	["i:43156"] = true,
	["i:24344"] = true,
	["i:165001"] = true,
	["i:19505"] = true,
	["i:115517"] = true,
	["i:65905"] = true,
	["i:157758"] = true,
	["i:43348"] = true,
	["i:46817"] = true,
	["i:45582"] = true,
	["i:180434"] = true,
	["i:65908"] = true,
	["i:89796"] = true,
	["i:49052"] = true,
	["i:31776"] = true,
	["i:118365"] = true,
	["i:180432"] = true,
	["i:45578"] = true,
	["i:89799"] = true,
	["i:45580"] = true,
	["i:64884"] = true,
	["i:83079"] = true,
	["i:160540"] = true,
	["i:140580"] = true,
	["i:119138"] = true,
	["i:160548"] = true,
	["i:160545"] = true,
	["i:49054"] = true,
	["i:63379"] = true,
	["i:89795"] = true,
	["i:49086"] = true,
	["i:168100"] = true,
	["i:160539"] = true,
	["i:31804"] = true,
	["i:168610"] = true,
	["i:19506"] = true,
	["i:31779"] = true,
	["i:161329"] = true,
	["i:98162"] = true,
	["i:19031"] = true,
	["i:167811"] = true,
	["i:103636"] = true,
	["i:171361"] = true,
	["i:133670"] = true,
	["i:31775"] = true,
	["i:89800"] = true,
	["i:19160"] = true,
	["i:35280"] = true,
	["i:161328"] = true,
	["i:89196"] = true,
	["i:35279"] = true,
	["i:157759"] = true,
	["i:31773"] = true,
	["i:19032"] = true,
	["i:24004"] = true,
	["i:65904"] = true,
	["i:180435"] = true,
	["i:89797"] = true,
	["i:69209"] = true,
	["i:160543"] = true,
	["i:31778"] = true,
	["i:167812"] = true,
	["i:119133"] = true,
	["i:65906"] = true,
	["i:65907"] = true,
	["i:160544"] = true,
	["i:23999"] = true,
	["i:15196"] = true,
	["i:31774"] = true,
	["i:31777"] = true,
	["i:115972"] = true,
	["i:174068"] = true,
	["i:160542"] = true,
	["i:168619"] = true,
	["i:169274"] = true,
	["i:45983"] = true,
	["i:164909"] = true,
	["i:95591"] = true,
	["i:128450"] = true,
	["i:31781"] = true,
	["i:140579"] = true,
	["i:140576"] = true,
	["i:115518"] = true,
	["i:142504"] = true,
	["i:147205"] = true,
	["i:157757"] = true,
	["i:118372"] = true,
	["i:83080"] = true,
	["i:168915"] = true,
	["i:140578"] = true,
	["i:156666"] = true,
	["i:97131"] = true,
	["i:157756"] = true,
	["i:89784"] = true,
	["i:119135"] = true,
	["i:127371"] = true,
	["i:140577"] = true,
	["i:164572"] = true,
	["i:160547"] = true,
	["i:32828"] = true,
	["i:119136"] = true,
	["i:89401"] = true,
	["i:140667"] = true,
	["i:172651"] = true,
	["i:180433"] = true,
	["i:174647"] = true,
	["i:160541"] = true,
	["i:128449"] = true,
	["i:15197"] = true,
	["i:149450"] = true,
	["i:32445"] = true,
	["i:127365"] = true,
	["i:89798"] = true,
	["i:127366"] = true,
	["i:119140"] = true,
	["i:19722"] = true,
	["i:174648"] = true,
	["i:31279"] = true,
	["i:147336"] = true,
	["i:119137"] = true,
	["i:172652"] = true,
	["i:147337"] = true,
	["i:147338"] = true,
	["i:101697"] = true,
	["i:167362"] = true,
	["i:44789"] = true,
	["i:49648"] = true,
	["i:167363"] = true,
	["i:164573"] = true,
	["i:149442"] = true,
	["i:147339"] = true,
	["i:149446"] = true,
	["i:31278"] = true,
	["i:107897"] = true,
	["i:127369"] = true,
	["i:147342"] = true,
	["i:164910"] = true,
	["i:149451"] = true,
	["i:64310"] = true,
	["i:147343"] = true,
	["i:147345"] = true,
	["i:149447"] = true,
	["i:149443"] = true,
	["i:147344"] = true,
	["i:49913"] = true,
	["i:147340"] = true,
	["i:147341"] = true,
	["i:49680"] = true,
}

-- scraped from wow head with: 
-- listviewitems.sort((a,b) => a.name < b.name); console.log(listviewitems.map(k => { if (k.name.indexOf("Nugget") == -1) { return "[\"i:" + k.id + "\"] = true"; }}).join(",\r\n"));
local PROSPECTABLE_ORES = {
	["i:171833"] = true,
	["i:171830"] = true,
	["i:171829"] = true,
	["i:171828"] = true,
	["i:171831"] = true,
	["i:171832"] = true,
	["i:109119"] = true,
	["i:123918"] = true,
	["i:152512"] = true,
	["i:168185"] = true,
	["i:36910"] = true,
	["i:52185"] = true,
	["i:72092"] = true,
	["i:23427"] = true,
	["i:36909"] = true,
	["i:53038"] = true,
	["i:23426"] = true,
	["i:10620"] = true,
	["i:152579"] = true,
	["i:36912"] = true,
	["i:152513"] = true,
	["i:23425"] = true,
	["i:23424"] = true,
	["i:2775"] = true,
	["i:3858"] = true,
	["i:109118"] = true,
	["i:2772"] = true,
	["i:72094"] = true,
	["i:72103"] = true,
	["i:2770"] = true,
	["i:52183"] = true,
	["i:2771"] = true,
	["i:11370"] = true,
	["i:7911"] = true, 
	["i:2776"] = true
};

-- scraped from wow head with: 
-- listviewitems.sort((a,b) => a.name < b.name); console.log(listviewitems.map(k => { if (k.name.indexOf("Seed") == -1 && k.name.indexOf("Petal") == -1 && k.name.indexOf("Spores") == -1 && (k.name.indexOf("Stem") == -1 || k.name == 'Sea Stalk') && k.name.indexOf("Pod") == -1 && k.name.indexOf("Stalk") == -1 && k.name.indexOf("Ichor") == -1 && k.name.indexOf("Blade") == -1 && (k.name.indexOf("Leaf") == -1 || k.name == "Green Tea Leaf") && (k.name.indexOf("Cap") == -1 || k.name == "Fool's Cap") && k.name != "Bloodthistle") { return "[\"i:" + k.id + "\"] = true"; }}).join(",\r\n"));
local MILLABLE_HERBS = {
	["i:170554"] = true,
	["i:168589"] = true,
	["i:168583"] = true,
	["i:169701"] = true,
	["i:168586"] = true,
	["i:171315"] = true,
	["i:152510"] = true,
	["i:124106"] = true,
	["i:168487"] = true,
	["i:52985"] = true,
	["i:72238"] = true,
	["i:52983"] = true,
	["i:2447"] = true,
	["i:22790"] = true,
	["i:8153"] = true,
	["i:22794"] = true,
	["i:765"] = true,
	["i:124101"] = true,
	["i:3820"] = true,
	["i:152509"] = true,
	["i:8831"] = true,
	["i:152506"] = true,
	["i:52988"] = true,
	["i:2449"] = true,
	["i:124103"] = true,
	["i:3821"] = true,
	["i:36903"] = true,
	["i:152508"] = true,
	["i:36908"] = true,
	["i:2450"] = true,
	["i:13466"] = true,
	["i:22792"] = true,
	["i:13468"] = true,
	["i:8836"] = true,
	["i:8845"] = true,
	["i:4625"] = true,
	["i:8838"] = true,
	["i:3818"] = true,
	["i:124105"] = true,
	["i:152507"] = true,
	["i:8839"] = true,
	["i:22791"] = true,
	["i:152505"] = true,
	["i:2452"] = true,
	["i:52984"] = true,
	["i:52986"] = true,
	["i:124102"] = true,
	["i:151565"] = true,
	["i:2453"] = true,
	["i:8846"] = true,
	["i:36905"] = true,
	["i:13464"] = true,
	["i:3355"] = true,
	["i:36901"] = true,
	["i:36907"] = true,
	["i:3369"] = true,
	["i:3356"] = true,
	["i:22786"] = true,
	["i:785"] = true,
	["i:109124"] = true,
	["i:13463"] = true,
	["i:36906"] = true,
	["i:22793"] = true,
	["i:13465"] = true,
	["i:22785"] = true,
	["i:22789"] = true,
	["i:22787"] = true,
	["i:79011"] = true,
	["i:109126"] = true,
	["i:3357"] = true,
	["i:3358"] = true,
	["i:13467"] = true,
	["i:3819"] = true,
	["i:72237"] = true,
	["i:37921"] = true,
	["i:109127"] = true,
	["i:109125"] = true,
	["i:52987"] = true,
	["i:72234"] = true,
	["i:109128"] = true,
	["i:79010"] = true,
	["i:124104"] = true,
	["i:109129"] = true,
	["i:36904"] = true,
	["i:72235"] = true,
	["i:108331"] = true,
};

local MASS_MILLING_RECIPIES = {

	-- Draenor
	[190381] = true;
	[190382] = true;
	[190383] = true;
	[190384] = true;
	[190385] = true;
	[190386] = true;

	-- Legion
	[209658] = true;
	[209659] = true;
	[209660] = true;
	[209661] = true;
	[209662] = true;
	[209664] = true;
	[247861] = true;

	-- BFA
    [256218] = true;
	[256217] = true;
	[298927] = true;
	[256221] = true;
	[256308] = true;
	[256219] = true;
	[256223] = true;
	[256220] = true;

	-- Shadowlands
	[311413] = true;
	
	[311418] = true;
	[311414] = true;
	[311417] = true;
	[311416] = true;
	[311415] = true;
};

local MASS_PROSPECT_RECIPIES = {
	[311948] = true,
	[311953] = true,
	[311951] = true,
	[311949] = true,
	[311952] = true,
	[311950] = true,
	[300619] = true,
	[225904] = true,
	[256622] = true,
	[256611] = true,
	[247761] = true,
	[225902] = true,
	[256613] = true,
};

local ENCHANTING_RECIPIES = {
	-- Scraped from Wowhead (http://www.wowhead.com/items/consumables/item-enhancements-permanent?filter=86;4;0) using the following javascript:
	-- for (i=0; i<listviewitems.length; i++) if (listviewitems[i].sourcemore) console.log("["+listviewitems[i].sourcemore[0].ti+"] = \"i:"+listviewitems[i].id+"\",  -- "+listviewitems[i].name);
	[7418] = "i:38679", -- Enchant Bracer - Minor Health
	[7420] = "i:38766", -- Enchant Chest - Minor Health
	[7426] = "i:38767", -- Enchant Chest - Minor Absorption
	[7428] = "i:38768", -- Enchant Bracer - Minor Dodge
	[7443] = "i:38769", -- Enchant Chest - Minor Mana
	[7457] = "i:38771", -- Enchant Bracer - Minor Stamina
	[7745] = "i:38772", -- Enchant 2H Weapon - Minor Impact
	[7748] = "i:38773", -- Enchant Chest - Lesser Health
	[7766] = "i:38774", -- Enchant Bracer - Minor Versatility
	[7771] = "i:38775", -- Enchant Cloak - Minor Protection
	[7776] = "i:38776", -- Enchant Chest - Lesser Mana
	[7779] = "i:38777", -- Enchant Bracer - Minor Agility
	[7782] = "i:38778", -- Enchant Bracer - Minor Strength
	[7786] = "i:38779", -- Enchant Weapon - Minor Beastslayer
	[7788] = "i:38780", -- Enchant Weapon - Minor Striking
	[7793] = "i:38781", -- Enchant 2H Weapon - Lesser Intellect
	[7857] = "i:38782", -- Enchant Chest - Health
	[7859] = "i:38783", -- Enchant Bracer - Lesser Versatility
	[7863] = "i:38785", -- Enchant Boots - Minor Stamina
	[7867] = "i:38786", -- Enchant Boots - Minor Agility
	[13378] = "i:38787", -- Enchant Shield - Minor Stamina
	[13380] = "i:38788", -- Enchant 2H Weapon - Lesser Versatility
	[13419] = "i:38789", -- Enchant Cloak - Minor Agility
	[13421] = "i:38790", -- Enchant Cloak - Lesser Protection
	[13464] = "i:38791", -- Enchant Shield - Lesser Protection
	[13485] = "i:38792", -- Enchant Shield - Lesser Versatility
	[13501] = "i:38793", -- Enchant Bracer - Lesser Stamina
	[13503] = "i:38794", -- Enchant Weapon - Lesser Striking
	[13529] = "i:38796", -- Enchant 2H Weapon - Lesser Impact
	[13536] = "i:38797", -- Enchant Bracer - Lesser Strength
	[13538] = "i:38798", -- Enchant Chest - Lesser Absorption
	[13607] = "i:38799", -- Enchant Chest - Mana
	[13612] = "i:38800", -- Enchant Gloves - Mining
	[13617] = "i:38801", -- Enchant Gloves - Herbalism
	[13620] = "i:38802", -- Enchant Gloves - Fishing
	[13622] = "i:38803", -- Enchant Bracer - Lesser Intellect
	[13626] = "i:38804", -- Enchant Chest - Minor Stats
	[13631] = "i:38805", -- Enchant Shield - Lesser Stamina
	[13635] = "i:38806", -- Enchant Cloak - Defense
	[13637] = "i:38807", -- Enchant Boots - Lesser Agility
	[13640] = "i:38808", -- Enchant Chest - Greater Health
	[13642] = "i:38809", -- Enchant Bracer - Versatility
	[13644] = "i:38810", -- Enchant Boots - Lesser Stamina
	[13646] = "i:38811", -- Enchant Bracer - Lesser Dodge
	[13648] = "i:38812", -- Enchant Bracer - Stamina
	[13653] = "i:38813", -- Enchant Weapon - Lesser Beastslayer
	[13655] = "i:38814", -- Enchant Weapon - Lesser Elemental Slayer
	[13659] = "i:38816", -- Enchant Shield - Versatility
	[13661] = "i:38817", -- Enchant Bracer - Strength
	[13663] = "i:38818", -- Enchant Chest - Greater Mana
	[13687] = "i:38819", -- Enchant Boots - Lesser Versatility
	[13689] = "i:38820", -- Enchant Shield - Lesser Parry
	[13693] = "i:38821", -- Enchant Weapon - Striking
	[13695] = "i:38822", -- Enchant 2H Weapon - Impact
	[13698] = "i:38823", -- Enchant Gloves - Skinning
	[13700] = "i:38824", -- Enchant Chest - Lesser Stats
	[13746] = "i:38825", -- Enchant Cloak - Greater Defense
	[13815] = "i:38827", -- Enchant Gloves - Agility
	[13817] = "i:38828", -- Enchant Shield - Stamina
	[13822] = "i:38829", -- Enchant Bracer - Intellect
	[13836] = "i:38830", -- Enchant Boots - Stamina
	[13841] = "i:38831", -- Enchant Gloves - Advanced Mining
	[13846] = "i:38832", -- Enchant Bracer - Greater Versatility
	[13858] = "i:38833", -- Enchant Chest - Superior Health
	[13868] = "i:38834", -- Enchant Gloves - Advanced Herbalism
	[13882] = "i:38835", -- Enchant Cloak - Lesser Agility
	[13887] = "i:38836", -- Enchant Gloves - Strength
	[13890] = "i:38837", -- Enchant Boots - Minor Speed
	[13898] = "i:38838", -- Enchant Weapon - Fiery Weapon
	[13905] = "i:38839", -- Enchant Shield - Greater Versatility
	[13915] = "i:38840", -- Enchant Weapon - Demonslaying
	[13917] = "i:38841", -- Enchant Chest - Superior Mana
	[13931] = "i:38842", -- Enchant Bracer - Dodge
	[13935] = "i:38844", -- Enchant Boots - Agility
	[13937] = "i:38845", -- Enchant 2H Weapon - Greater Impact
	[13939] = "i:38846", -- Enchant Bracer - Greater Strength
	[13941] = "i:38847", -- Enchant Chest - Stats
	[13943] = "i:38848", -- Enchant Weapon - Greater Striking
	[13945] = "i:38849", -- Enchant Bracer - Greater Stamina
	[13947] = "i:38850", -- Enchant Gloves - Riding Skill
	[13948] = "i:38851", -- Enchant Gloves - Minor Haste
	[20008] = "i:38852", -- Enchant Bracer - Greater Intellect
	[20009] = "i:38853", -- Enchant Bracer - Superior Versatility
	[20010] = "i:38854", -- Enchant Bracer - Superior Strength
	[20011] = "i:38855", -- Enchant Bracer - Superior Stamina
	[20012] = "i:38856", -- Enchant Gloves - Greater Agility
	[20013] = "i:38857", -- Enchant Gloves - Greater Strength
	[20015] = "i:38859", -- Enchant Cloak - Superior Defense
	[20016] = "i:38860", -- Enchant Shield - Vitality
	[20017] = "i:38861", -- Enchant Shield - Greater Stamina
	[20020] = "i:38862", -- Enchant Boots - Greater Stamina
	[20023] = "i:38863", -- Enchant Boots - Greater Agility
	[20024] = "i:38864", -- Enchant Boots - Versatility
	[20025] = "i:38865", -- Enchant Chest - Greater Stats
	[20026] = "i:38866", -- Enchant Chest - Major Health
	[20028] = "i:38867", -- Enchant Chest - Major Mana
	[20029] = "i:38868", -- Enchant Weapon - Icy Chill
	[20030] = "i:38869", -- Enchant 2H Weapon - Superior Impact
	[20031] = "i:38870", -- Enchant Weapon - Superior Striking
	[20032] = "i:38871", -- Enchant Weapon - Lifestealing
	[20033] = "i:38872", -- Enchant Weapon - Unholy Weapon
	[20034] = "i:38873", -- Enchant Weapon - Crusader
	[20035] = "i:38874", -- Enchant 2H Weapon - Major Versatility
	[20036] = "i:38875", -- Enchant 2H Weapon - Major Intellect
	[21931] = "i:38876", -- Enchant Weapon - Winter's Might
	[22749] = "i:38877", -- Enchant Weapon - Spellpower
	[22750] = "i:38878", -- Enchant Weapon - Healing Power
	[23799] = "i:38879", -- Enchant Weapon - Strength
	[23800] = "i:38880", -- Enchant Weapon - Agility
	[23801] = "i:38881", -- Enchant Bracer - Argent Versatility
	[23802] = "i:38882", -- Enchant Bracer - Healing Power
	[23803] = "i:38883", -- Enchant Weapon - Mighty Versatility
	[23804] = "i:38884", -- Enchant Weapon - Mighty Intellect
	[25072] = "i:38885", -- Enchant Gloves - Threat
	[25073] = "i:38886", -- Enchant Gloves - Shadow Power
	[25074] = "i:38887", -- Enchant Gloves - Frost Power
	[25078] = "i:38888", -- Enchant Gloves - Fire Power
	[25079] = "i:38889", -- Enchant Gloves - Healing Power
	[25080] = "i:38890", -- Enchant Gloves - Superior Agility
	[25083] = "i:38893", -- Enchant Cloak - Stealth
	[25084] = "i:38894", -- Enchant Cloak - Subtlety
	[25086] = "i:38895", -- Enchant Cloak - Dodge
	[27837] = "i:38896", -- Enchant 2H Weapon - Agility
	[27899] = "i:38897", -- Enchant Bracer - Brawn
	[27905] = "i:38898", -- Enchant Bracer - Stats
	[27906] = "i:38899", -- Enchant Bracer - Greater Dodge
	[27911] = "i:38900", -- Enchant Bracer - Superior Healing
	[27913] = "i:38901", -- Enchant Bracer - Versatility Prime
	[27914] = "i:38902", -- Enchant Bracer - Fortitude
	[27917] = "i:38903", -- Enchant Bracer - Spellpower
	[27944] = "i:38904", -- Enchant Shield - Lesser Dodge
	[27945] = "i:38905", -- Enchant Shield - Intellect
	[27946] = "i:38906", -- Enchant Shield - Parry
	[27948] = "i:38908", -- Enchant Boots - Vitality
	[27950] = "i:38909", -- Enchant Boots - Fortitude
	[27951] = "i:37603", -- Enchant Boots - Dexterity
	[27954] = "i:38910", -- Enchant Boots - Surefooted
	[27957] = "i:38911", -- Enchant Chest - Exceptional Health
	[27958] = "i:38912", -- Enchant Chest - Exceptional Mana
	[27960] = "i:38913", -- Enchant Chest - Exceptional Stats
	[27961] = "i:38914", -- Enchant Cloak - Major Armor
	[27967] = "i:38917", -- Enchant Weapon - Major Striking
	[27968] = "i:38918", -- Enchant Weapon - Major Intellect
	[27971] = "i:38919", -- Enchant 2H Weapon - Savagery
	[27972] = "i:38920", -- Enchant Weapon - Potency
	[27975] = "i:38921", -- Enchant Weapon - Major Spellpower
	[27977] = "i:38922", -- Enchant 2H Weapon - Major Agility
	[27981] = "i:38923", -- Enchant Weapon - Sunfire
	[27982] = "i:38924", -- Enchant Weapon - Soulfrost
	[27984] = "i:38925", -- Enchant Weapon - Mongoose
	[28003] = "i:38926", -- Enchant Weapon - Spellsurge
	[28004] = "i:38927", -- Enchant Weapon - Battlemaster
	[33990] = "i:38928", -- Enchant Chest - Major Versatility
	[33991] = "i:38929", -- Enchant Chest - Versatility Prime
	[33992] = "i:38930", -- Enchant Chest - Major Resilience
	[33993] = "i:38931", -- Enchant Gloves - Blasting
	[33994] = "i:38932", -- Enchant Gloves - Precise Strikes
	[33995] = "i:38933", -- Enchant Gloves - Major Strength
	[33996] = "i:38934", -- Enchant Gloves - Assault
	[33997] = "i:38935", -- Enchant Gloves - Major Spellpower
	[33999] = "i:38936", -- Enchant Gloves - Major Healing
	[34001] = "i:38937", -- Enchant Bracer - Major Intellect
	[34002] = "i:38938", -- Enchant Bracer - Lesser Assault
	[34003] = "i:38939", -- Enchant Cloak - PvP Power
	[34004] = "i:38940", -- Enchant Cloak - Greater Agility
	[34007] = "i:38943", -- Enchant Boots - Cat's Swiftness
	[34008] = "i:38944", -- Enchant Boots - Boar's Speed
	[34009] = "i:38945", -- Enchant Shield - Major Stamina
	[34010] = "i:38946", -- Enchant Weapon - Major Healing
	[42620] = "i:38947", -- Enchant Weapon - Greater Agility
	[42974] = "i:38948", -- Enchant Weapon - Executioner
	[44383] = "i:38949", -- Enchant Shield - Resilience
	[44484] = "i:38951", -- Enchant Gloves - Haste
	[44488] = "i:38953", -- Enchant Gloves - Precision
	[44489] = "i:38954", -- Enchant Shield - Dodge
	[44492] = "i:38955", -- Enchant Chest - Mighty Health
	[44500] = "i:38959", -- Enchant Cloak - Superior Agility
	[44506] = "i:38960", -- Enchant Gloves - Gatherer
	[44508] = "i:38961", -- Enchant Boots - Greater Versatility
	[44509] = "i:38962", -- Enchant Chest - Greater Versatility
	[44510] = "i:38963", -- Enchant Weapon - Exceptional Versatility
	[44513] = "i:38964", -- Enchant Gloves - Greater Assault
	[44524] = "i:38965", -- Enchant Weapon - Icebreaker
	[44528] = "i:38966", -- Enchant Boots - Greater Fortitude
	[44529] = "i:38967", -- Enchant Gloves - Major Agility
	[44555] = "i:38968", -- Enchant Bracer - Exceptional Intellect
	[44575] = "i:44815", -- Enchant Bracer - Greater Assault
	[44576] = "i:38972", -- Enchant Weapon - Lifeward
	[44582] = "i:38973", -- Enchant Cloak - Minor Power
	[44584] = "i:38974", -- Enchant Boots - Greater Vitality
	[44588] = "i:38975", -- Enchant Chest - Exceptional Resilience
	[44589] = "i:38976", -- Enchant Boots - Superior Agility
	[44591] = "i:38978", -- Enchant Cloak - Superior Dodge
	[44592] = "i:38979", -- Enchant Gloves - Exceptional Spellpower
	[44593] = "i:38980", -- Enchant Bracer - Major Versatility
	[44595] = "i:38981", -- Enchant 2H Weapon - Scourgebane
	[44598] = "i:38984", -- Enchant Bracer - Haste
	[44616] = "i:38987", -- Enchant Bracer - Greater Stats
	[44621] = "i:38988", -- Enchant Weapon - Giant Slayer
	[44623] = "i:38989", -- Enchant Chest - Super Stats
	[44625] = "i:38990", -- Enchant Gloves - Armsman
	[44629] = "i:38991", -- Enchant Weapon - Exceptional Spellpower
	[44630] = "i:38992", -- Enchant 2H Weapon - Greater Savagery
	[44631] = "i:38993", -- Enchant Cloak - Shadow Armor
	[44633] = "i:38995", -- Enchant Weapon - Exceptional Agility
	[44635] = "i:38997", -- Enchant Bracer - Greater Spellpower
	[46578] = "i:38998", -- Enchant Weapon - Deathfrost
	[46594] = "i:38999", -- Enchant Chest - Dodge
	[47051] = "i:39000", -- Enchant Cloak - Greater Dodge
	[47672] = "i:39001", -- Enchant Cloak - Mighty Stamina
	[47766] = "i:39002", -- Enchant Chest - Greater Dodge
	[47898] = "i:39003", -- Enchant Cloak - Greater Speed
	[47899] = "i:39004", -- Enchant Cloak - Wisdom
	[47900] = "i:39005", -- Enchant Chest - Super Health
	[47901] = "i:39006", -- Enchant Boots - Tuskarr's Vitality
	[59619] = "i:44497", -- Enchant Weapon - Accuracy
	[59621] = "i:44493", -- Enchant Weapon - Berserking
	[59625] = "i:43987", -- Enchant Weapon - Black Magic
	[60606] = "i:44449", -- Enchant Boots - Assault
	[60609] = "i:44456", -- Enchant Cloak - Speed
	[60616] = "i:38971", -- Enchant Bracer - Assault
	[60621] = "i:44453", -- Enchant Weapon - Greater Potency
	[60623] = "i:38986", -- Enchant Boots - Icewalker
	[60653] = "i:44455", -- Shield Enchant - Greater Intellect
	[60663] = "i:44457", -- Enchant Cloak - Major Agility
	[60668] = "i:44458", -- Enchant Gloves - Crusher
	[60691] = "i:44463", -- Enchant 2H Weapon - Massacre
	[60692] = "i:44465", -- Enchant Chest - Powerful Stats
	[60707] = "i:44466", -- Enchant Weapon - Superior Potency
	[60714] = "i:44467", -- Enchant Weapon - Mighty Spellpower
	[60763] = "i:44469", -- Enchant Boots - Greater Assault
	[60767] = "i:44470", -- Enchant Bracer - Superior Spellpower
	[62256] = "i:44947", -- Enchant Bracer - Major Stamina
	[62948] = "i:45056", -- Enchant Staff - Greater Spellpower
	[62959] = "i:45060", -- Enchant Staff - Spellpower
	[63746] = "i:45628", -- Enchant Boots - Lesser Accuracy
	[64441] = "i:46026", -- Enchant Weapon - Blade Ward
	[64579] = "i:46098", -- Enchant Weapon - Blood Draining
	[71692] = "i:50816", -- Enchant Gloves - Angler
	[74132] = "i:52687", -- Enchant Gloves - Mastery
	[74189] = "i:52743", -- Enchant Boots - Earthen Vitality
	[74191] = "i:52744", -- Enchant Chest - Mighty Stats
	[74192] = "i:52745", -- Enchant Cloak - Lesser Power
	[74193] = "i:52746", -- Enchant Bracer - Speed
	[74195] = "i:52747", -- Enchant Weapon - Mending
	[74197] = "i:52748", -- Enchant Weapon - Avalanche
	[74198] = "i:52749", -- Enchant Gloves - Haste
	[74199] = "i:52750", -- Enchant Boots - Haste
	[74200] = "i:52751", -- Enchant Chest - Stamina
	[74201] = "i:52752", -- Enchant Bracer - Critical Strike
	[74202] = "i:52753", -- Enchant Cloak - Intellect
	[74207] = "i:52754", -- Enchant Shield - Protection
	[74211] = "i:52755", -- Enchant Weapon - Elemental Slayer
	[74212] = "i:52756", -- Enchant Gloves - Exceptional Strength
	[74213] = "i:52757", -- Enchant Boots - Major Agility
	[74214] = "i:52758", -- Enchant Chest - Mighty Resilience
	[74220] = "i:52759", -- Enchant Gloves - Greater Haste
	[74223] = "i:52760", -- Enchant Weapon - Hurricane
	[74225] = "i:52761", -- Enchant Weapon - Heartsong
	[74226] = "i:52762", -- Enchant Shield - Mastery
	[74229] = "i:52763", -- Enchant Bracer - Superior Dodge
	[74230] = "i:52764", -- Enchant Cloak - Critical Strike
	[74231] = "i:52765", -- Enchant Chest - Exceptional Versatility
	[74232] = "i:52766", -- Enchant Bracer - Precision
	[74234] = "i:52767", -- Enchant Cloak - Protection
	[74235] = "i:52768", -- Enchant Off-Hand - Superior Intellect
	[74236] = "i:52769", -- Enchant Boots - Precision
	[74237] = "i:52770", -- Enchant Bracer - Exceptional Versatility
	[74238] = "i:52771", -- Enchant Boots - Mastery
	[74239] = "i:52772", -- Enchant Bracer - Greater Haste
	[74240] = "i:52773", -- Enchant Cloak - Greater Intellect
	[74242] = "i:52774", -- Enchant Weapon - Power Torrent
	[74244] = "i:52775", -- Enchant Weapon - Windwalk
	[74246] = "i:52776", -- Enchant Weapon - Landslide
	[74247] = "i:52777", -- Enchant Cloak - Greater Critical Strike
	[74248] = "i:52778", -- Enchant Bracer - Greater Critical Strike
	[74250] = "i:52779", -- Enchant Chest - Peerless Stats
	[74251] = "i:52780", -- Enchant Chest - Greater Stamina
	[74252] = "i:52781", -- Enchant Boots - Assassin's Step
	[74253] = "i:52782", -- Enchant Boots - Lavawalker
	[74254] = "i:52783", -- Enchant Gloves - Mighty Strength
	[74255] = "i:52784", -- Enchant Gloves - Greater Mastery
	[74256] = "i:52785", -- Enchant Bracer - Greater Speed
	[95471] = "i:68134", -- Enchant 2H Weapon - Mighty Agility
	[96261] = "i:68785", -- Enchant Bracer - Major Strength
	[96262] = "i:68786", -- Enchant Bracer - Mighty Intellect
	[96264] = "i:68784", -- Enchant Bracer - Agility
	[104338] = "i:74700", -- Enchant Bracer - Mastery
	[104385] = "i:74701", -- Enchant Bracer - Major Dodge
	[104389] = "i:74703", -- Enchant Bracer - Super Intellect
	[104390] = "i:74704", -- Enchant Bracer - Exceptional Strength
	[104391] = "i:74705", -- Enchant Bracer - Greater Agility
	[104392] = "i:74706", -- Enchant Chest - Super Resilience
	[104393] = "i:74707", -- Enchant Chest - Mighty Versatility
	[104395] = "i:74708", -- Enchant Chest - Glorious Stats
	[104397] = "i:74709", -- Enchant Chest - Superior Stamina
	[104398] = "i:74710", -- Enchant Cloak - Accuracy
	[104401] = "i:74711", -- Enchant Cloak - Greater Protection
	[104403] = "i:74712", -- Enchant Cloak - Superior Intellect
	[104404] = "i:74713", -- Enchant Cloak - Superior Critical Strike
	[104407] = "i:74715", -- Enchant Boots - Greater Haste
	[104408] = "i:74716", -- Enchant Boots - Greater Precision
	[104409] = "i:74717", -- Enchant Boots - Blurred Speed
	[104414] = "i:74718", -- Enchant Boots - Pandaren's Step
	[104416] = "i:74719", -- Enchant Gloves - Greater Haste
	[104417] = "i:74720", -- Enchant Gloves - Superior Haste
	[104419] = "i:74721", -- Enchant Gloves - Super Strength
	[104420] = "i:74722", -- Enchant Gloves - Superior Mastery
	[104425] = "i:74723", -- Enchant Weapon - Windsong
	[104427] = "i:74724", -- Enchant Weapon - Jade Spirit
	[104430] = "i:74725", -- Enchant Weapon - Elemental Force
	[104434] = "i:74726", -- Enchant Weapon - Dancing Steel
	[104440] = "i:74727", -- Enchant Weapon - Colossus
	[104442] = "i:74728", -- Enchant Weapon - River's Song
	[104445] = "i:74729", -- Enchant Off-Hand - Major Intellect
	[123125] = "i:141910", -- Enchant Neck - Mark of the Ancient Priestess
	[130758] = "i:89737", -- Enchant Shield - Greater Parry
	[158877] = "i:110631", -- Enchant Cloak - Breath of Critical Strike
	[158878] = "i:110632", -- Enchant Cloak - Breath of Haste
	[158879] = "i:110633", -- Enchant Cloak - Breath of Mastery
	[158881] = "i:110635", -- Enchant Cloak - Breath of Versatility
	[158884] = "i:110652", -- Enchant Cloak - Gift of Critical Strike
	[158885] = "i:110653", -- Enchant Cloak - Gift of Haste
	[158886] = "i:110654", -- Enchant Cloak - Gift of Mastery
	[158889] = "i:110656", -- Enchant Cloak - Gift of Versatility
	[158892] = "i:110624", -- Enchant Neck - Breath of Critical Strike
	[158893] = "i:110625", -- Enchant Neck - Breath of Haste
	[158894] = "i:110626", -- Enchant Neck - Breath of Mastery
	[158896] = "i:110628", -- Enchant Neck - Breath of Versatility
	[158899] = "i:110645", -- Enchant Neck - Gift of Critical Strike
	[158900] = "i:110646", -- Enchant Neck - Gift of Haste
	[158901] = "i:110647", -- Enchant Neck - Gift of Mastery
	[158903] = "i:110649", -- Enchant Neck - Gift of Versatility
	[158907] = "i:110617", -- Enchant Ring - Breath of Critical Strike
	[158908] = "i:110618", -- Enchant Ring - Breath of Haste
	[158909] = "i:110619", -- Enchant Ring - Breath of Mastery
	[158911] = "i:110621", -- Enchant Ring - Breath of Versatility
	[158914] = "i:110638", -- Enchant Ring - Gift of Critical Strike
	[158915] = "i:110639", -- Enchant Ring - Gift of Haste
	[158916] = "i:110640", -- Enchant Ring - Gift of Mastery
	[158918] = "i:110642", -- Enchant Ring - Gift of Versatility
	[159235] = "i:110682", -- Enchant Weapon - Mark of the Thunderlord
	[159236] = "i:112093", -- Enchant Weapon - Mark of the Shattered Hand
	[159671] = "i:112164", -- Enchant Weapon - Mark of Warsong
	[159672] = "i:112165", -- Enchant Weapon - Mark of the Frostwolf
	[159673] = "i:112115", -- Enchant Weapon - Mark of Shadowmoon
	[159674] = "i:112160", -- Enchant Weapon - Mark of Blackrock
	[173323] = "i:118015", -- Enchant Weapon - Mark of Bleeding Hollow
	[190954] = "i:128554", -- Enchant Shoulder - Boon of the Scavenger
	[190866] = "i:128537", -- Enchant Ring - Word of Critical Strike Rank 1
	[190867] = "i:128538", -- Enchant Ring - Word of Haste Rank 1
	[190868] = "i:128539", -- Enchant Ring - Word of Mastery Rank 1
	[190869] = "i:128540", -- Enchant Ring - Word of Versatility Rank 1
	[190870] = "i:128541", -- Enchant Ring - Binding Of Critical Strike Rank 1
	[190871] = "i:128542", -- Enchant Ring - Binding Of Haste Rank 1
	[190872] = "i:128543", -- Enchant Ring - Binding Of Mastery Rank 1
	[190873] = "i:128544", -- Enchant Ring - Binding Of Versatility Rank 1
	[190874] = "i:128545", -- Enchant Cloak - Word of Strength Rank 1
	[190875] = "i:128546", -- Enchant Cloak - Word of Agility Rank 1
	[190876] = "i:128547", -- Enchant Cloak - Word of Intellect Rank 1
	[190877] = "i:128548", -- Enchant Cloak - Binding Of Strength Rank 1
	[190878] = "i:128549", -- Enchant Cloak - Binding Of Agility Rank 1
	[190879] = "i:128550", -- Enchant Cloak - Binding Of Intellect Rank 1
	[190892] = "i:128551", -- Enchant Neck - Mark Of The Claw Rank 1
	[190893] = "i:128552", -- Enchant Neck - Mark Of The Distant Army Rank 1
	[190894] = "i:128553", -- Enchant Neck - Mark of the Hidden Satyr Rank 1
	[190988] = "i:128558", -- Enchant Gloves - Legion Herbalism
	[190989] = "i:128559", -- Enchant Gloves - Legion Mining
	[190990] = "i:128560", -- Enchant Gloves - Legion Skinning
	[190991] = "i:128561", -- Enchant Gloves - Legion Surveying
	[190992] = "i:128537", -- Enchant Ring - Word of Critical Strike Rank 2
	[190993] = "i:128538", -- Enchant Ring - Word of Haste Rank 2
	[190994] = "i:128539", -- Enchant Ring - Word of Mastery Rank 2
	[190995] = "i:128540", -- Enchant Ring - Word of Versatility Rank 2
	[190996] = "i:128541", -- Enchant Ring - Binding Of Critical Strike Rank 2
	[190997] = "i:128542", -- Enchant Ring - Binding Of Haste Rank 2
	[190998] = "i:128543", -- Enchant Ring - Binding Of Mastery Rank 2
	[190999] = "i:128544", -- Enchant Ring - Binding Of Versatility Rank 2
	[191000] = "i:128545", -- Enchant Cloak - Word of Strength Rank 2
	[191001] = "i:128546", -- Enchant Cloak - Word of Agility Rank 2
	[191002] = "i:128547", -- Enchant Cloak - Word of Intellect Rank 2
	[191003] = "i:128548", -- Enchant Cloak - Binding Of Strength Rank 2
	[191004] = "i:128549", -- Enchant Cloak - Binding Of Agility Rank 2
	[191005] = "i:128550", -- Enchant Cloak - Binding Of Intellect Rank 2
	[191006] = "i:128551", -- Enchant Neck - Mark Of The Claw Rank 2
	[191007] = "i:128552", -- Enchant Neck - Mark Of The Distant Army Rank 2
	[191008] = "i:128553", -- Enchant Neck - Mark of the Hidden Satyr Rank 2
	[191009] = "i:128537", -- Enchant Ring - Word of Critical Strike Rank 3
	[191010] = "i:128538", -- Enchant Ring - Word of Haste Rank 3
	[191011] = "i:128539", -- Enchant Ring - Word of Mastery Rank 3
	[191012] = "i:128540", -- Enchant Ring - Word of Versatility Rank 3
	[191013] = "i:128541", -- Enchant Ring - Binding Of Critical Strike Rank 3
	[191014] = "i:128542", -- Enchant Ring - Binding Of Haste Rank 3
	[191015] = "i:128543", -- Enchant Ring - Binding Of Mastery Rank 3
	[191016] = "i:128544", -- Enchant Ring - Binding Of Versatility Rank 3
	[191017] = "i:128545", -- Enchant Cloak - Word of Strength Rank 3
	[191018] = "i:128546", -- Enchant Cloak - Word of Agility Rank 3
	[191019] = "i:128547", -- Enchant Cloak - Word of Intellect Rank 3
	[191020] = "i:128548", -- Enchant Cloak - Binding Of Strength Rank 3
	[191021] = "i:128549", -- Enchant Cloak - Binding Of Agility Rank 3
	[191022] = "i:128550", -- Enchant Cloak - Binding Of Intellect Rank 3
	[191023] = "i:128551", -- Enchant Neck - Mark Of The Claw Rank 3
	[191024] = "i:128552", -- Enchant Neck - Mark Of The Distant Army Rank 3
	[191025] = "i:128553", -- Enchant Neck - Mark of the Hidden Satyr Rank 3
	[228402] = "i:141908", -- Enchant Neck - Mark Of The Heavy Hide Rank 1
	[228403] = "i:141908", -- Enchant Neck - Mark Of The Heavy Hide Rank 2
	[228404] = "i:141908", -- Enchant Neck - Mark Of The Heavy Hide Rank 3
	[228405] = "i:141909", -- Enchant Neck - Mark of the Trained Soldier Rank 1
	[228406] = "i:141909", -- Enchant Neck - Mark of the Trained Soldier Rank 2
	[228407] = "i:141909", -- Enchant Neck - Mark of the Trained Soldier Rank 3
	[228408] = "i:141910", -- Enchant Neck - Mark Of The Ancient Priestess Rank 1
	[228409] = "i:141910", -- Enchant Neck - Mark Of The Ancient Priestess Rank 2
	[228410] = "i:141910", -- Enchant Neck - Mark Of The Ancient Priestess Rank 3
	[235695] = "i:144304", -- Enchant Neck - Mark of the Master Rank 1
	[235696] = "i:144305", -- Enchant Neck - Mark of the Versatile Rank 1
	[235697] = "i:144306", -- Enchant Neck - Mark of the Quick Rank 1
	[235698] = "i:144307", -- Enchant Neck - Mark of the Deadly Rank 1
	[235699] = "i:144304", -- Enchant Neck - Mark of the Master Rank 2
	[235700] = "i:144305", -- Enchant Neck - Mark of the Versatile Rank 3
	[235701] = "i:144306", -- Enchant Neck - Mark of the Quick Rank 2
	[235702] = "i:144307", -- Enchant Neck - Mark of the Deadly Rank 2
	[235703] = "i:144304", -- Enchant Neck - Mark of the Master Rank 3
	[235704] = "i:144305", -- Enchant Neck - Mark of the Versatile Rank 2
	[235705] = "i:144306", -- Enchant Neck - Mark of the Quick Rank 3
	[235706] = "i:144307", -- Enchant Neck - Mark of the Deadly Rank 3
	[255035] = "i:153430", -- Enchant Gloves - Kul Tiran Herbalism
	[255040] = "i:153431", -- Enchant Gloves - Kul Tiran Mining
	[255065] = "i:153434", -- Enchant Gloves - Kul Tiran Skinning
	[255066] = "i:153435", -- Enchant Gloves - Kul Tiran Surveying
	[255070] = "i:153437", -- Enchant Gloves - Kul Tiran Crafting
	[255071] = "i:153438", -- Enchant Ring - Seal of Critical Strike Rank 1
	[255072] = "i:153439", -- Enchant Ring - Seal of Haste Rank 1
	[255073] = "i:153440", -- Enchant Ring - Seal of Mastery Rank 1
	[255074] = "i:153441", -- Enchant Ring - Seal of Versatility Rank 1
	[255075] = "i:153442", -- Enchant Ring - Pact of Critical Strike Rank 1
	[255076] = "i:153443", -- Enchant Ring - Pact of Haste Rank 1
	[255077] = "i:153444", -- Enchant Ring - Pact of Mastery Rank 1
	[255078] = "i:153445", -- Enchant Ring - Pact of Versatility Rank 1
	[255086] = "i:153438", -- Enchant Ring - Seal of Critical Strike Rank 2
	[255087] = "i:153439", -- Enchant Ring - Seal of Haste Rank 2
	[255088] = "i:153440", -- Enchant Ring - Seal of Mastery Rank 2
	[255089] = "i:153441", -- Enchant Ring - Seal of Versatility Rank 2
	[255090] = "i:153442", -- Enchant Ring - Pact of Critical Strike Rank 2
	[255091] = "i:153443", -- Enchant Ring - Pact of Haste Rank 2
	[255092] = "i:153444", -- Enchant Ring - Pact of Mastery Rank 2
	[255093] = "i:153445", -- Enchant Ring - Pact of Versatility Rank 2
	[255094] = "i:153438", -- Enchant Ring - Seal of Critical Strike Rank 3
	[255095] = "i:153439", -- Enchant Ring - Seal of Haste Rank 3
	[255096] = "i:153440", -- Enchant Ring - Seal of Mastery Rank 3
	[255097] = "i:153441", -- Enchant Ring - Seal of Versatility Rank 3
	[255098] = "i:153442", -- Enchant Ring - Pact of Critical Strike Rank 3
	[255099] = "i:153443", -- Enchant Ring - Pact of Haste Rank 3
	[255100] = "i:153444", -- Enchant Ring - Pact of Mastery Rank 3
	[255101] = "i:153445", -- Enchant Ring - Pact of Versatility Rank 3
	[255103] = "i:153476", -- Enchant Weapon - Coastal Surge Rank 1
	[255104] = "i:153476", -- Enchant Weapon - Coastal Surge Rank 2
	[255105] = "i:153476", -- Enchant Weapon - Coastal Surge Rank 3
	[255110] = "i:153478", -- Enchant Weapon - Siphoning Rank 1
	[255111] = "i:153478", -- Enchant Weapon - Siphoning Rank 2
	[255112] = "i:153478", -- Enchant Weapon - Siphoning Rank 3
	[255129] = "i:153479", -- Enchant Weapon - Torrent of Elements Rank 1
	[255130] = "i:153479", -- Enchant Weapon - Torrent of Elements Rank 2
	[255131] = "i:153479", -- Enchant Weapon - Torrent of Elements Rank 3
	[255141] = "i:153480", -- Enchant Weapon - Gale-Force Striking Rank 1
	[255142] = "i:153480", -- Enchant Weapon - Gale-Force Striking Rank 2
	[255143] = "i:153480", -- Enchant Weapon - Gale-Force Striking Rank 3
	[267490] = "i:159468", -- Enchant Gloves - Zandalari Surveying
	[267482] = "i:159466", -- Enchant Gloves - Zandalari Mining
	[267458] = "i:159464", -- Enchant Gloves - Zandalari Herbalism
	[267486] = "i:159467", -- Enchant Gloves - Zandalari Skinning
	[267498] = "i:159471", -- Enchant Gloves - Zandalari Crafting
	[268852] = "i:159788", -- Enchant Weapon - Versatile Navigation Rank 1
	[268878] = "i:159788", -- Enchant Weapon - Versatile Navigation Rank 2
	[268879] = "i:159788", -- Enchant Weapon - Versatile Navigation Rank 3
	[268894] = "i:159786", -- Enchant Weapon - Quick Navigation Rank 1
	[268895] = "i:159786", -- Enchant Weapon - Quick Navigation Rank 2
	[268897] = "i:159786", -- Enchant Weapon - Quick Navigation Rank 3
	[268901] = "i:159787", -- Enchant Weapon - Masterful Navigation Rank 1
	[268902] = "i:159787", -- Enchant Weapon - Masterful Navigation Rank 2
	[268903] = "i:159787", -- Enchant Weapon - Masterful Navigation Rank 3
	[268907] = "i:159785", -- Enchant Weapon - Deadly Navigation Rank 1
	[268908] = "i:159785", -- Enchant Weapon - Deadly Navigation Rank 2
	[268909] = "i:159785", -- Enchant Weapon - Deadly Navigation Rank 3
	[268913] = "i:159789", -- Enchant Weapon - Stalwart Navigation Rank 1
	[268914] = "i:159789", -- Enchant Weapon - Stalwart Navigation Rank 2
	[268915] = "i:159789", -- Enchant Weapon - Stalwart Navigation Rank 3
	[297989] = "i:168447", -- Enchant Ring - Accord of Haste Rank 1
	[297991] = "i:168449", -- Enchant Ring - Accord of Versatility Rank 2
	[297993] = "i:168449", -- Enchant Ring - Accord of Versatility Rank 1
	[297994] = "i:168447", -- Enchant Ring - Accord of Haste Rank 2
	[297995] = "i:168448", -- Enchant Ring - Accord of Mastery Rank 1
	[297999] = "i:168449", -- Enchant Ring - Accord of Versatility Rank 3
	[298001] = "i:168448", -- Enchant Ring - Accord of Mastery Rank 2
	[298002] = "i:168448", -- Enchant Ring - Accord of Mastery Rank 3
	[298009] = "i:168446", -- Enchant Ring - Accord of Critical Strike Rank 1
	[298010] = "i:168446", -- Enchant Ring - Accord of Critical Strike Rank 2
	[298011] = "i:168446", -- Enchant Ring - Accord of Critical Strike Rank 3
	[298016] = "i:168447", -- Enchant Ring - Accord of Haste Rank 3
	[298433] = "i:168593", -- Enchant Weapon - Machinist's Brilliance Rank 1
	[298437] = "i:168592", -- Enchant Weapon - Oceanic Restoration Rank 2
	[298438] = "i:168592", -- Enchant Weapon - Oceanic Restoration Rank 1
	[298439] = "i:168596", -- Enchant Weapon - Force Multiplier Rank 2
	[298440] = "i:168596", -- Enchant Weapon - Force Multiplier Rank 1
	[298441] = "i:168598", -- Enchant Weapon - Naga Hide Rank 2
	[298442] = "i:168598", -- Enchant Weapon - Naga Hide Rank 1
	[298515] = "i:168592", -- Enchant Weapon - Oceanic Restoration Rank 3
	[300769] = "i:168593", -- Enchant Weapon - Machinist's Brilliance Rank 2
	[300770] = "i:168593", -- Enchant Weapon - Machinist's Brilliance Rank 3
	[300788] = "i:168596", -- Enchant Weapon - Force Multiplier Rank 3
	[300789] = "i:168598", -- Enchant Weapon - Naga Hide Rank 3
	[309612] = "i:172357", -- Enchant Ring - Bargain of Critical Strike
	[309613] = "i:172358", -- Enchant Ring - Bargain of Haste
	[309614] = "i:172359", -- Enchant Ring - Bargain of Mastery
	[309615] = "i:172360", -- Enchant Ring - Bargain of Versatility
	[309616] = "i:172361", -- Enchant Ring - Tenet of Critical Strike
	[309617] = "i:172362", -- Enchant Ring - Tenet of Haste
	[309618] = "i:172363", -- Enchant Ring - Tenet of Mastery
	[309619] = "i:172364", -- Enchant Ring - Tenet of Versatility
	[309622] = "i:172365", -- Enchant Weapon - Ascended Vigor
	[309627] = "i:172366", -- Enchant Weapon - Celestial Guidance
	[309621] = "i:172367", -- Enchant Weapon - Eternal Grace
	[309623] = "i:172368", -- Enchant Weapon - Sinful Revelation
	[309620] = "i:172370", -- Enchant Weapon - Lightless Force
	[309524] = "i:172406", -- Enchant Gloves - Shadowlands Gathering
	[309525] = "i:172407", -- Enchant Gloves - Strength of Soul
	[309526] = "i:172408", -- Enchant Gloves - Eternal Strength
	[309528] = "i:172410", -- Enchant Cloak - Fortified Speed
	[309530] = "i:172411", -- Enchant Cloak - Fortified Avoidance
	[309531] = "i:172412", -- Enchant Cloak - Fortified Leech
	[309532] = "i:172413", -- Enchant Boots - Agile Soulwalker
	[309608] = "i:172414", -- Enchant Bracers - Illuminated Soul
	[309609] = "i:172415", -- Enchant Bracers - Eternal Intellect
	[309610] = "i:172416", -- Enchant Bracers - Shaded Hearthing
	[309535] = "i:172418", -- Enchant Chest - Eternal Bulwark
	[309534] = "i:172419", -- Enchant Boots - Eternal Agility
	[323760] = "i:177659", -- Enchant Chest - Eternal Skirmish
	[323755] = "i:177660", -- Enchant Cloak - Soul Vitality
	[323609] = "i:177661", -- Enchant Boots - Speed of Soul
	[323761] = "i:177715", -- Enchant Chest - Eternal Bounds
	[323762] = "i:177716", -- Enchant Chest - Sacred Stats
	[324773] = "i:177962", -- Enchant Chest - Eternal Stats
	[342316] = "i:183738", -- Enchant Chest - Eternal Insight
}

function CraftingData.IsProspectable(id)
	if (not id) then
		return false;
	end

	return PROSPECTABLE_ORES[id];
end

function CraftingData.IsMillable(id)
	if (not id) then
		return false;
	end

	return MILLABLE_HERBS[id];
end

function CraftingData.IsDisenchantable(id, link)
	if (not id) then
		return false;
	end

	local _, i = strsplit(":", id);

	if (not i) then
		return false;
	end

	local inum = tonumber(i);
	if (NON_DISENCHANTABLE_ITEMS[_..":"..i]) then
		return false;
	end

	if (not inum) then
		return false;
	end

	local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, _, _, _, _, classId, subClassId = GetItemInfo(inum);

	if (classId) then
		if (classId ~= LE_ITEM_CLASS_ARMOR and classId ~= LE_ITEM_CLASS_WEAPON) then
			return false;
		end
	end

	if (link) then
		local minValue = Config.Crafting().disenchantMinValue;
		if (minValue and minValue:len() > 0) then
			local _, copper = Utils.MoneyStringToCopper(minValue);
			if (copper and copper > 0) then
				if (CraftingData.DisenchantValue(link, 1) < copper) then
					return false;
				end
			end
		end
	end

	return itemRarity >= (Utils.IsClassic() and LE_ITEM_QUALITY_UNCOMMON or Enum.ItemQuality.Uncommon);
end

function CraftingData.HasMinimumCount(item)
	if (CraftingData.IsProspectable(item.tsmId) or CraftingData.IsMillable(item.tsmId)) then
		return item.count >= 5;
	end

	return true;
end

function CraftingData.IsDestroyable(id,link)
	if (link) then
		local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, _, _, _, _, classId, subClassId = GetItemInfo(link);
		local maxQuality = Config.Crafting().destroyMaxQuality;
		if (maxQuality and maxQuality > 0) then
			if (itemRarity > maxQuality) then
				return false;
			end
		end
	end

	if (not CraftingData.IsProspectable(id) 
		and not CraftingData.IsMillable(id) 
		and not CraftingData.IsDisenchantable(id, link)) then
			return false;
	end

	local spellId = CraftingData.GetDestroySpell(id);

	if (not spellId) then
		return false;
	end

	return IsSpellKnown(spellId);
end

function CraftingData.GetDestroySpell(id)
	if (CraftingData.IsProspectable(id)) then
		return SPELLS.prospect;
	elseif (CraftingData.IsMillable(id)) then
		return SPELLS.milling;
	elseif (CraftingData.IsDisenchantable(id)) then
		return SPELLS.disenchant;
	end

	return nil;
end

-- Secondary boolean indicates it was
-- a enchanting special item
-- otherwise it was a mass milling item
function CraftingData.Item(recipeID)
    if (ENCHANTING_RECIPIES[recipeID]) then
		return ENCHANTING_RECIPIES[recipeID], true;
	end

	return (MASS_MILLING_RECIPIES[recipeID] or MASS_PROSPECT_RECIPIES[recipeID]), false;
end

function CraftingData.DisenchantValue(link, quantity, ref)
	if (not link) then
		return 0;
	end

	local id = Utils.GetID(link);

	if (CraftingData.IsProspectable(id)) then
		return CraftingData.GetProspectValue(id, quantity == 1 and 5 or quantity, ref);
	elseif (CraftingData.IsMillable(id)) then
		return CraftingData.GetMillValue(id, quantity == 1 and 5 or quantity, ref);
	end

	local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, _, _, _, _, classId, subClassId = GetItemInfo(link);
	if (_G["GetDetailedItemLevelInfo"]) then
		local eff, preview, base = GetDetailedItemLevelInfo(link);
		if (not preview and eff) then
			itemLevel = eff;
		end
	end

	return CraftingData.GetDisenchantValue(classId, itemMinLevel, itemLevel, itemRarity, quantity, ref);
end

function CraftingData.GetValue(tbl, id, quantity, ref)
	local worth = 0;

	if (not quantity or quantity < 1) then
		quantity = 1;
	end

	if (ref) then
		wipe(ref);
	end

	local s = tbl[id];

	if (not s) then
		return worth;
	end

	for k,v in pairs(s) do
		local rate = type(v) == "number" and v or v.matRate;
		local amt = type(v) == "number" and 1 or (v.maxAmount * v.amountOfMats);
		if (ref) then
			if (not ref[k]) then
				ref[k] = 0;
			end
			ref[k] = ref[k] + rate * amt;
		end
		if (Config.Crafting().materialCost and Config.Crafting().materialCost:len() > 0) then
			worth = worth + math.floor(((Sources:QueryID(Config.Crafting().materialCost, k) or 0) * rate * amt) + 0.5);
		end 
	end

	-- for k,v in pairs(tbl) do
	-- 	local s = v[id];
	-- 	if (s) then
	-- 		local rate = type(s) == "number" and s or s.matRate;
	-- 		local amt = type(s) == "number" and 1 or (s.maxAmount * s.amountOfMats);
	-- 		if (ref) then
	-- 			if (not ref[k]) then
	-- 				ref[k] = 0;
	-- 			end
	-- 			ref[k] = ref[k] + rate * amt;
	-- 		end
	-- 		if (Config.Crafting().materialCost and Config.Crafting().materialCost:len() > 0) then
	-- 			worth = worth + math.floor(((Sources:QueryID(Config.Crafting().materialCost, k) or 0) * rate * amt) + 0.5);
	-- 		end 
	-- 	end
	-- end
	return worth * quantity;
end

function CraftingData.GetMillValue(id, quantity, ref)
	return CraftingData.GetValue(MILL_INFO, id, quantity, ref);
end

function CraftingData.GetProspectValue(id, quantity, ref)
	return CraftingData.GetValue(PROSPECT_INFO, id, quantity, ref);
end

function CraftingData.GetDisenchantValue(classId, minLevel, ilevel, quality, quantity, ref)
	local worth = 0;
	
	if (not quantity or quantity < 1) then
		quantity = 1;
	end

	if (quality <= 1) then
		return worth;
	end

	if (classId ~= LE_ITEM_CLASS_ARMOR and classId ~= LE_ITEM_CLASS_WEAPON) then
		return worth;
	end

	if (ref) then
		wipe(ref);
	end

	for k,v in pairs(DISENCHANT_INFO) do
		local source = v.sourceInfo;
		if (minLevel >= v.minLevel and minLevel <= v.maxLevel) then
			for i,s in ipairs(source) do
				if (s.classId == classId and quality == s.quality and ilevel >= s.minItemLevel and ilevel <= s.maxItemLevel) then
					if (ref) then
						ref[k] = s.amountOfMats;
					end
					if (Config.Crafting().materialCost and Config.Crafting().materialCost:len() > 0) then
						worth = worth + math.floor(((Sources:QueryID(Config.Crafting().materialCost, k) or 0) * s.amountOfMats) + 0.5);
					end
				end
			end
		end
	end
	return worth * quantity;
end