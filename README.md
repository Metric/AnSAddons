
AnS [Auctions]
=======

What is it? A lightweight set of auction buying and selling modules for AnS.

All auctions are sorted based on Price Per Unit from low to high. For efficiency, it uses blizzard built in AH sorting and thus results are always returned low to high.

The scanning of auctions will only go 4 pages deep for two reasons: One efficiency and two to get a good peek at low to average pricing. There really is no need to scan all pages for buying, because as goblins we are always looking for the cheapest prices.

Buy Features
=============
Use your filter groups as way to quickly search for buying. The filter group must have ids in it, otherwise it will not be visible in the list.

You can also put in a search string to find what you want.
* Search string overrides selected filters currently (may change based on feedback)

Scanning must finish before you can buy. You can always stop the scan and restart.

Selling Features
=================
It will auto scan your bags for items and list them.

Clicking on an item will scan for auctions, and also populate with pricing provided by the global percent string.
* Clicking on an auction listing for an item, will set the price to that listing.
* Double clicking an auction listing will instantly sell based on that listing price.
* Use the left side to set a custom price and number of items to sell from the stack. 
    * By default, it will set it to max stack size.
* You can queue up the scanning of each item by going through and clicking on each one right after the other

Dragging an item into the auction sell slot will have no effect and will not be posted. Please use the list instead.

TODO
==========
* Add config option for a different percent string for selling and buying auctions.
* Add an option for setting default stack size to sell
* Add an undercut by ... amount


AnS [Auction Snipe] 
===========================
A lightweight addon for WoW auction sniping

Dependecies
=============
Requires AnS

(Optional) Undermine Journal addon for percentage calculations.

(Optional) TSM for percentage calculations.

(Optional) Auctionator addon for percentage calculations.

(Optional) AnsAuctionData for percentage calculations.

Features
===============
* Only ever loads the last page of the auction house for sniping and is refreshed as soon as possible.
* Due to the above, there is no need to perform another search to purchase.

* To filter out vendor items with unlimited quantities, will require a filter string of: tujdays ~= 252

* Filters must be set before starting a sniping session
* Changes to filters during a running sniping session has no effect.
* To update filters stop and restart the session.

* Pre-built filters for:
    * Herbs
    * Ores
    * Fish
    * Cloth
    * Leather
    * Enchanting
    * Armor
    * Weapons
    * Pets
    * Mounts
    * Recipes
    * Consumable
    * Containers

 * Allows for quick settings of:
    * Max Percent
    * Max Buyout
    * Min iLevel
    * Min Quality
    * Min Stack Size
    * Name filter for further refinement

 * Take it to the next level with custom filters, pricing strings, and filter strings
 * For a list of item types and sub-types to use in your custom filters, instead of item ids see: http://wowwiki.wikia.com/wiki/ItemType


How to Buy & Other Controls
==============
Double click an auction list item, and ba da bing, ba da boom. It will purchase it if it can.

Or set a key binding under ESC -&gt; Bindings -&gt; AnS to buy selected auctions via another button.

(For Advanced Users) There is now a keybinding option to buy the first listed auction item.

Shift + Left Click allows you to temporarily blacklist a listing until the AH window is closed.

CTRL + Left Click allows you to temporarily blacklist the item type until the AH window is closed.

Selecting armor, weapons, or pets, will now display the dress up window with that item.

* Want to use the key bindings through TSM macros instead? Use the following functions: /run AuctionSnipe:BuySelected() and /run AuctionSnipe:BuyFirst()


Filter and Percent/Pricing Strings
=========================
A percent/pricing string must end up as a single numerical value

A filter string must end up as a boolean value

Lua operators can be used on strings

```
 &gt;=, ~=, ==, &lt;=, &lt;, &gt;, not, and, or, -, +, *, \
```

Predefined functions for use in strings:

```
first, check, iflte, iflt, ifgte, ifgt, ifeq, ifneq, avg, min, max, mod, abs, ceil, floor, round, random, log, log10, exp, sqrt
```

Predefined Item Variables:

```
vendorsell, percent, ppu, stacksize, buyout, ilevel, quality
```

Predefined TUJ Variables:

```
tujmarket, tujrecent, tujglobalmedian, tujglobalmean, tujage, tujdays, tujstddev, tujglobalstddev
```

Predefined TSM Variables:

```
dbmarket, dbminbuyout, dbhistorical, dbregionmarketavg, dbregionminbuyoutavg, dbregionhistorical, dbregionsaleavg, dbregionsalerate, dbregionsoldperday, dbglobalminbuyoutavg, dbglobalmarketavg, dbglobalhistorical, dbglobalsaleavg, dbglobalsalerate, dbglobalsoldperday
```

Predefined Auctionator Variables:

```
atrvalue
```

Predefined AnsAuctionData Variables:

```
ansmin, ansrecent, ansmarket, ans3day
```

Custom VARS
========
Custom variables can now be defined in ESC -&gt; Interface -&gt; Addons -&gt; AnS -&gt; Custom VARS

All the same info regarding filter and percent strings apply to these as well.

Percent Shorthand Now Supported
================================
You can do the following just like TSM:

```
10% dbmarketvalue
```
```
20% dbminbuyout
```

etc..


Filter and Percent/Pricing Strings Update:
========================================
As of version 1.0.4 you can use the following short hand operators: 

lt (less than), gt (greater than), gte (greater than equal), lte (less than equal), eq (equals), neq (not equals).

Quality shorthand: common, uncommon, rare, epic, legendary

As of version 1.0.4 short hand for money is available as such:

```
25g5s10c
```
```
25g10c
```
```
25g
```
```
5s10c
```
```
5s
```
```
10c
```


Using Percent Strings
===========================

Percent strings should always return 1 numerical value.


Example of Percent Strings
================================
avg of tujmarket and tujrecent

```
avg(tujmarket,tujrecent)
```

min of tujmarket and tujrecent

```
min(tujmarket,tujrecent)
```

min of dbmarket, tujmarket, tujrecent, dbregionmarketavg

```
min(dbmarket,tujmarket,tujrecent,dbregionmarketavg)
```

Using custom math in strings
===========
You can use any of the standard lua operators for math such as: * (multiply), \ (divide), + (add), - (subtract)

```
0.25 * min(tujmarket,tujrecent);
```

Using Filter Strings
====================
Filter strings should return a boolean value of true or false.

True means the item is valid and will be displayed.

False the item will not display.

Common Filter String Examples
=====================================
(Shorthand operators are only available in 1.0.4 and above)

Only show auctions less than 50%
------------------------------------
```
percent lt 50
```

Without shorthand
```
percent &lt; 50
```

Only show auctions with a ppu less than equal to 5g
------------------------------------------
```
ppu lte 5g
```

Without shorthand
```
ppu &lt;= 5 * 10000
```

Only show items with ilevel greater than 350
------------------------------------------
```
ilevel gt 350
```

Without shorthand
```
ilevel &gt; 350
```

Only show items with a stacksize of greater than equal to 20
----------------------------------------
```
stacksize gte 20
```

Without shorthand
```
stacksize &gt;= 20
```

Only show items that are rare and above
-----------------------------------------
```
quality gte rare
```

Without shorthand
```
quality &gt;= 4
```

Combining More Than One Examples
===================================
quality common or better and ppu less than equal to 10g
--------------------------------------------
```
quality gte common and ppu lte 10g
```

Without shorthand
```
quality &gt;= 1 and ppu &lt;= 10 * 10000
```

iLevel greater than 350 and percent less than 50
----------------------------------------
```
ilevel gt 350 and percent lt 50
```

Without shorthand
```
ilevel &gt; 350 and percent &lt; 50
```

One or the Other Examples
============================
Only accept items that are less than 1000g or above 5000g ppu
------------------------------------------
```
ppu lt 1000g or ppu gt 5000g
```

Without shorthand
```
ppu &lt; 1000 * 10000 or ppu &gt; 5000 * 10000
```

Only accept items with stacksize 200 or ppu gt 200g and ppu lt 250g
-------------------------------------------------------
```
(stacksize eq 200) or (ppu gt 200g and ppu lt 250g)
```

Without shorthand
```
(stacksize == 200) or (ppu &gt; 200 * 10000 and ppu &lt; 250 * 10000)
```


AnS Core Library
=========================

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
