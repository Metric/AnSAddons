AnS
==============

What is it?
--------------------------
It is a core library used for various things. But mainly for AnS [Auction Snipe].

It also handles the configuration and storage of custom filters and importing of filters from TSM groups.

Classes
--------------
* AnsCore (Handles loading of saved variables etc)
* AnsCore.API.Filter (Auction House Query Filtering)
* AnsCore.API.GroupQuery (Auction House Query Handler)
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
* Create other addon modules:
    * Analytics
