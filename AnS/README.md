AnS
==============

What is it?
--------------------------
It is a core library used for various things. But mainly for AuctionSnipe.

It also handles the configuration and storage of custom filters and importing of filters from TSM groups.

More to come...

TSM Server Market Data Caveat (1.0.2)
==================
If you were on version 1.0.1 of AnS, then you will need to revert the change or simply restore TradeSkillMaster_AppHelper to its defaults.

In 1.0.2 a different way has been decided, but sadly it does still require a slight modification to a TSM lua file.

If using TSM 4:
-------------------

In TradeSkillMaster/Core/Service/AuctionDB/Core.lua after the following line:
```
local AuctionDB = ...
```
Add the following global variable:
```
-- Add a global variable mod here
AnsTSMAuctionDB = AuctionDB;
```

If using TSM 3:
--------------------

In TradeSkillMaster_AuctionDB/TradeSkillMaster_AuctionDB.lua after the following line:

```
TSM = LibStub ...
```
Add the following global variable:
```
-- Add a global variable mod here
AnsTSMAuctionDB = TSM;
```


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
dbmarket, dbminbuyout, dbhistorical, dbregionmarketavg, dbregionminbuyoutavg, dbregionhistorical, dbregionsaleavg, dbregionsalerate, dbregionsoldperday
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
