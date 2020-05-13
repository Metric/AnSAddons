Discord
===================
Need help, have questions, suggestions or just found a bug?

https://discord.gg/DZueXS7

I just updated to 2.1 and stuff is broken
==============================================
If you just updated through curse or twitch, then please restart your WoW Client first. As quite a bit has changed.

AnS [Auction Snipe] 
===========================
A lightweight addon for WoW auction sniping

Dependecies
=============
Requires AnS

Must have at least one of the below for retail:
* Undermine Journal
* TSM

In 2.1 Settings Have Moved!
======================
Settings are no longer under Esc -> Interface -> Addons -> AnS

Instead use the new Minimap button to access all stuff AnS related.


Note for 2.x Regarding Retail Max Percent
==================================================
Max percent may need to be adjusted higher than necessary if looking for equipment with the same id and varying levels of iLevels. Since, the initial browse query filtering is based on the base item id in pricing in TSM / TUJ / Auctionator. However, the final filtering is based on the item id + bonus ids, but only if the initial browse group is considered. You can combat cases of this by using a operation that will override the percent check in the final case and filter out the lower ilevels that are not really deals.


Features
===============
* Sniper Operations must be set before starting a sniping session
* Changes to sniper operations during a running sniping session has no effect.
* To update sniper operations stop and restart the session.

* Pre-built Groups for:
    * Herbs
    * Ores
    * Fish
    * Cloth
    * Leather
    * Enchanting
    * Pets
    * Mounts

 * Allows for quick settings of:
    * Max Percent
    * Max Buyout
    * Min iLevel
    * Min Quality
    * CLevel Range
    * Name filter for further refinement


How to Buy & Other Controls
==============
Double click an auction list item, and ba da bing, ba da boom. It will purchase it if it can.

Or use the new mouse wheel macro creation under Ans Mini Map Button -> Settings -> Macro

Settings -> Sniper -> Price Source
======================
The sniper price source must return a numerical value and can use Custom Sources as well in it.

The sniper price source is used for the default percentage calculations.

Settings -> Sniper -> Max Price or Boolean Filter
======================================
The max price or boolean filter here is the global version. Sniper operations ignore this value and use their own instead.

You can either return a numerical value here and it will work as a max price cut off, or return a boolean value such as: ppu lte 20g

Predefined Variables
=========================
Lua operators can be used

```
 >=, ~=, ==, <=, <, >, not, and, or, -, +, *, \
```

Predefined functions for use in strings:

```
first, check, iflte, iflt, ifgte, ifgt, ifeq, ifneq, avg, min, max, mod, abs, ceil, floor, round, random, log, log10, exp, sqrt, eq, neq, bonus, startswith, contains,
```

Predefined Item Variables:

```
vendorsell, vendorbuy, percent, ppu, stacksize, buyout, ilevel, quality, tsmId, id
```

Predefined TUJ Variables:

```
tujmarket, tujrecent, tujglobalmedian, tujglobalmean, tujage, tujdays, tujstddev, tujglobalstddev
```

Predefined TSM Variables:

```
dbmarket, dbminbuyout, dbhistorical, dbregionmarketavg, dbregionminbuyoutavg, dbregionhistorical, dbregionsaleavg, dbregionsalerate, dbregionsoldperday
```

Most variants on TSM variables are also available such as DBRegionMarketAvg, ItemLevel, etc. in 2.1


Predefined AnsAuctionData Variables:

```
ansmin, ansrecent, ansmarket, ans3day
```

Using Predefined bonus function in 2.1
=================================
The bonus function will check to see if an item has a specified bonus id

You can pass it the following as an example:
```
bonus(100,110g,0)
```

If the above has the bonus 100 then it will return the first value of 110g, otherwise it will return the secondary value of 0. If only a bonus id is provided and no values are passed, then it will return just true or false.


The function parameters:
```
bonus(id,value1,value2)
```


Settings -> Custom Sources (Previously called Custom VARS)
=================================
Custom sources can be anything you want them to be and are case sensitive.

They can be referenced in any other area of AnS from operations to global settings.


Percent Shorthand
================================
You can do the following just like TSM:

```
10% dbmarketvalue
```
```
20% dbminbuyout
```

etc..


Gold Shorthand
========================================

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


Example of Price Source
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


Boolean Filtering Examples
=====================================

Only show auctions less than 50%
------------------------------------
```
percent lt 50
```

Only show auctions with a ppu less than equal to 5g
------------------------------------------
```
ppu lte 5g
```


Only show items with ilevel greater than 350
------------------------------------------
```
ilevel gt 350
```

Only show items with a stacksize of greater than equal to 20
----------------------------------------
```
stacksize gte 20
```

Only show items that are rare and above
-----------------------------------------
```
quality gte 4
```

Combining More Than One Boolean Examples
===================================
quality common or better and ppu less than equal to 10g
--------------------------------------------
```
quality gte 1 and ppu lte 10g
```

iLevel greater than 350 and percent less than 50
----------------------------------------
```
ilevel gt 350 and percent lt 50
```

One or the Other Boolean Examples
============================
Only accept items that are less than 1000g or above 5000g ppu
------------------------------------------
```
ppu lt 1000g or ppu gt 5000g
```

Only accept items with stacksize 200 or ppu gt 200g and ppu lt 250g
-------------------------------------------------------
```
(stacksize eq 200) or (ppu gt 200g and ppu lt 250g)
```


AnS
==============

What is it?
--------------------------
It is a core library used for various things. But mainly for AnS [Auction Snipe].

It also handles the configuration of all AnS related addons.


