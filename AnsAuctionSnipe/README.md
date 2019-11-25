AnS [Auction Snipe] 
===========================
A lightweight addon for WoW auction sniping; Relies on Undermine Journal for pricing.

Dependecies
=============
Requires AnS

(Optional) Undermine Journal addon for percentage calculations.

(Optional) TSM for percentage calculations.

(Optional) Auctionator addon for percentage calculations.


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

Or set a key binding under ESC -> Bindings -> AnS to buy selected auctions via another button.

(For Advanced Users) There is now a keybinding option to buy the first listed auction item.

Shift + Left Click allows you to temporarily blacklist a listing until the AH window is closed.

CTRL + Left Click allows you to temporarily blacklist the item type until the AH window is closed.

Selecting armor, weapons, or pets, will now display the dress up window with that item.

* Want to use the key bindings through TSM macros instead? Use the following functions: /run AuctionSnipe:BuySelected() or /run AuctionSnipe:BuyFirst()


The Billis Formula for AnS Sniper
==============================================
this is for wow classic

tsm only supports dbminprice and dbmarket on classic currently

create a new varable with the name of minprice

and this as the data for that variable

```
max(dbmarket, vendorsell)
```

or if using ans auction data

```
max(ansmarket, vendorsell)
```

create a new variable with this in it

this variable must come after minprice variable in the variables list

give it the name billisformula

```
ifgte(quality, 1, ifgte(minprice, 250g, 80, ifgte(minprice, 100g, 70, ifgte(minprice, 50g, 60, ifgte(minprice, 10g, 40, ifgte(minprice, 5g, 30, ifgte(minprice, 1g, 10, 0)))))), 0)
```

in the global filter string or in the filter string for a filter itself

```
percent lte billisformula and billisformula gt 0
```

Filter and Percent/Pricing Strings
=========================
A percent/pricing string must end up as a single numerical value

A filter string must end up as a boolean value

Lua operators can be used on strings

```
 >=, ~=, ==, <=, <, >, not, and, or, -, +, *, \
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

Custom VARS
========
Custom variables can now be defined in ESC -> Interface -> Addons -> AnS -> Custom VARS

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
percent < 50
```

Only show auctions with a ppu less than equal to 5g
------------------------------------------
```
ppu lte 5g
```

Without shorthand
```
ppu <= 5 * 10000
```

Only show items with ilevel greater than 350
------------------------------------------
```
ilevel gt 350
```

Without shorthand
```
ilevel > 350
```

Only show items with a stacksize of greater than equal to 20
----------------------------------------
```
stacksize gte 20
```

Without shorthand
```
stacksize >= 20
```

Only show items that are rare and above
-----------------------------------------
```
quality gte rare
```

Without shorthand
```
quality >= 4
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
quality >= 1 and ppu <= 10 * 10000
```

iLevel greater than 350 and percent less than 50
----------------------------------------
```
ilevel gt 350 and percent lt 50
```

Without shorthand
```
ilevel > 350 and percent < 50
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
ppu < 1000 * 10000 or ppu > 5000 * 10000
```

Only accept items with stacksize 200 or ppu gt 200g and ppu lt 250g
-------------------------------------------------------
```
(stacksize eq 200) or (ppu gt 200g and ppu lt 250g)
```

Without shorthand
```
(stacksize == 200) or (ppu > 200 * 10000 and ppu < 250 * 10000)
```