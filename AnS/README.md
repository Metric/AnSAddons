AnS
==============

What is it?
--------------------------
It is a core library used for various things. But mainly for AnS [Auction Snipe].

It also handles the configuration and storage of custom filters and importing of filters from TSM groups.

More to come...

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

Data
---------
* AnsCloth
* AnsFish
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
    * Meat
    * Consumables Sub Filters

* Create other addon modules:
    * Analytics
    * Auctioning (Regular purchasing etc)
    * Crafting (Profits / Loss per Craft)

* Even Bigger Goals:
    * Use my AWS server to pull down and cache real time 1-hour auction house snapshots (Currently just running an Unreal Engine Game Server).
    * Keep track of current avg and 3-day avg.
    * Integrate into custom MIT licensed electron app to get realtime updates from server via websockets.
        * Write to WoW saved variables. 
