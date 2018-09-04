AnS
==============

What is it?
--------------------------
It is a core library used for various things. But mainly for AuctionSnipe.

It also handles the configuration and storage of custom filters and importing of filters from TSM groups.

More to come...

TSM Server Market Data Caveat
==================
Due to how TSM has everything privately cached except for TradeSkillMaster_AppHelper. There needs to be a slight modification to TradeSkillMaster_AppHelper in order to allow TSM to continue to work. Otherwise, AnS will absorb all the data and TSM will not have access to it.

TradeSkillMaster_AppHelper/TradeSkillMaster_AppHelper.lua Modifications:

Line 1 add:

```
local pulled = 0;
```

Line 23 (Before line 1 add) or Line 24 (After line 1 add) - (private.data[tag] = nil) replace with:

```
	pulled = pulled + 1;
	if (pulled > 1) then
		private.data[tag] = nil;
	end
```

This is done to one, allow TSM to grab the data but also to help free memory. Sure you could just remove (private.data[tag] = nil) but then there will be duplicate data in memory.


Filter and Percent Strings
=========================
A percent string must end up as a single numerical value

A filter string must end up as a boolean value

Lua operators can be used on strings
```
 >=, ~=, ==, <=, <, >, not, -, +, *, \
```

Predefined functions for use in strings:
```
avg, first, min, max, mod, abs, ceil, floor, round, random, log, log10, exp, sqrt
```

Predefined Item Variables:
```
percent, ppu, stacksize, buyout, ilevel, quality
```

Predefined TUJ Variables:
```
tujmarket, tujrecent, tujglobalmedian, tuglobalmean, tujage, tujdays, tujstddev, tujglobalstddev
```

Predfined TSM Variables:
```
dbmarket, dbminbuyout, dbhistorical
```


Classes
--------------
* AnsCore (Handles loading of saved variables etc)
* AnsFilter (Auction House Query Filtering)
* AnsFilterView (Helper for rendering filters for selecting etc.)
* AnsCustomFilter (Data storage for custom filters)
* AnsQuery (Auction House Query)
* AnsUtils (Show pet battle tip, parse pet item link etc.)
* AnsConfig (Handles config options etc, adding new custom filters, importing tsm groups)
* AnsSettings (Default Settings)
* AnsPriceSources (Allows registering multiple price sources for filter / percent strings)
* AnsTSMHelper
    * AnsTSMHelper.GetRealmItemData ((number or itemLink), key)
    * possible keys: marketValue, minBuyout, historical

Data
---------
* AnsCloth
* AnsHerb
* AnsEnchanting
* AnsLeather
* AnsMounts
* AnsOre
* AnsPets
* AnsFilterDefault (Default Filter Setup for Queries)

UI Templates
--------------
* AnsFilterRowTemplate (For filters listing)
* AnsResultRowTemplate (For auction listings)
* AnsHeaderTemplate (For auction sort etc)
* AnsDialogTemplate (Default dialog template)
* SmallButtonTemplate

Font Templates
----------
* AnsFontOrange
* NumberFontNormalRightBlue
* GameFontLightGraySmall

TODO
===========
* Add more predefined filters for:
    * Ingots / Bars
    * Gems
    * Fish
    * Meat

* Create other addon modules:
    * Analytics
    * Auctioning (Regular purchasing etc)
    * Crafting (Profits / Loss per Craft)

* Even Bigger Goals:
    * Use my AWS server to pull down and cache real time 1-hour auction house snapshots (Currently just running an Unreal Engine Game Server).
    * Keep track of current avg and 3-day avg.
    * Integrate into custom MIT licensed electron app to get realtime updates from server via websockets.
        * Write to WoW saved variables. 
