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
* AnsCore.API.Filter (Auction House Query Filtering)
* AnsCore.API.Query (Auction House Query)
* AnsCore.API.Utils (Show pet battle tip, parse pet item link etc.)
* AnsConfig (Handles config options etc, adding new custom filters, importing tsm groups)
* AnsCore.API.Sources (Allows registering multiple price sources for filter / percent strings)
* AnsCore.API.BagScanner (Scanning items in bags)
* AnsCore.API.UI.Dropdown
* AnsCore.API.UI.TreeView
* AnsCore.API.UI.Graph

Data
---------
* Cloth
* Fish
* Herbs
* Enchanting
* Leather
* Mounts
* Ore
* Pets
* Consumable
* Armor
* Weapons
* Recipes
* Container

UI Templates
--------------
* AnsFilterRowTemplate (For filters listing)
* AnsAuctionRowTemplate (For auction listings)
* AnsAuctionHeadingTemplate (For auction sort etc)
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
    * Consumables

* Create other addon modules:
    * Analytics
    * Crafting (Profits / Loss per Craft)

* Even Bigger Goals:
    * Use my AWS server to pull down and cache real time 1-hour auction house snapshots (Currently just running an Unreal Engine Game Server).
    * Keep track of current avg and 3-day avg.
    * Integrate into custom MIT licensed electron app to get realtime updates from server via websockets.
        * Write to WoW saved variables. 
