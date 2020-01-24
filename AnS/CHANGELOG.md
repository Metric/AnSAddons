AnS Changes 2.0.2
-------------------
* Added an option to turn on Commodity Purchase Confirm. The confirmation allows you to set the number of items to buy before purchasing.

AnS Changes 2.0.1
-----------------
* Added support for toggling Exact ID Matching for bonus ids, pet levels and pet breed quality in custom filters. Turn off Exact ID Matching if you want to just use a base item / pet id in the custom filter that does not include bonus ids, or pet level and pet breed quality.
    - This will be back ported to classic as well

AnS Changes 2.0
----------------
* A BIG shout out to u/turmixer123 on Reddit for helping test this update and giving me an idea on how to make this faster than TSM sniper for 8.3.
* Complete rewrite for 8.3 Query Handling etc
* Removed unneeded settings
* Filters do not require item ids anymore.
    - Thus you can use just the filter string in them now for quicker access to different types of filters without relying on global
    - this will be back ported for classic as well


AnS Changes 1.0.6.7
--------------------
* Fixed some bugs in bag scanner, where non auctionable items would be added to the GetAuctionable() list.
* Updated query.lua to support new features for AnsAuctionData tracking and scanning.
* Added a button to clear realm auction data for AnsAuctionData to Global Settings

AnS Changes 1.0.6.6
--------------------
* Fixed a small bug when no valid auction link provided.
* Implemented a few new functions available for filters etc: eq, neq, contains, startswith
    * eq: simply checks to see if two values equal each other and returns either true or false
    * neq: checks to see if two values do not equal eath other and returns either true or false
    * contains: checks to see if a string contains the provided substring
    * startswith: checks to see if a string starts with the provided substring
* You can now use tsmId and id in filters. tsmId is a string and starts with i: for items and p: for pets. id is the numeric form of the id provided straight from the auction house listing.
    * Example of matching every item except the given with tsmId: tsmId ~= "i:12456"
    * Example of matching every item except the given with id: id ~= 12456
    * Example of matching every item except the given with tsmId and new neq function: neq(tsmId, "i:12456")
    * Example of matching every item except the given with id and new neq function: neq(id, 12456)
    * Example of seeing if tsmId starts with "i:123": startswith(tsmId, "i:123")



AnS Changes 1.0.6.5
--------------------
* Fixed issue where bag scanner was not properly handling pet links. Resulting in an error being thrown in AnSAuctions Sell Module.

AnS Changes 1.0.6.4
--------------------
* Fixed a bug, where if you use just the base id for an equipment, it would be ignored. As it would be trying to only find the equipment with bonus ids. This was a regression, as previously this was taken into account, but during optimizing for stuttering, I forgot to add it back in.

AnS Changes 1.0.6.2
--------------------
* Made the font size larger for most things, until I can implement a font scaling option.
* Fixed bug where an invalid variable name was used to check for auction owner vs your character name. In order to not display your auctions etc.
* Added a character blacklist (1 name per line)
* Can now pick between g.s.c or coin icons for money display.
* Money display now has separators for gold: 1,000,000g ...
* Optimized certain function calls for lower memory usage
* Fixed issue with frame stuttering when quite a few filters were active at once, with lots of ids. May see slight memory usage increase over time, as caching is used. To clear the cache, just close the AH window.


AnS Changes 1.0.6.1
--------------------
* Fixed misspelled variable when trying to access dbregionhistorical
* Filters can now be moved from group to group via the move button
* Child filters that have blank types, subtypes, or a filter string, will now inherit the parents when sniping

AnS Changes 1.0.6
--------------------
* Code refactored to remove most things from global namespace
    * Can be accessed from AnsCore.API instead
    * If you find any issues please post them on reddit post or message me on reddit
* Custom Filters in ESC -> Interface -> Addons -> AnS is now called Filters
* Filters can now have sub filters and the default filters are now fully editable
    * Try to keep the child sub depth reasonable to about 4.
    * Try to keep the parent root name unique as it is used as path for keeping track of currently selected filters in the sniping window now.
    * When pressing the New button, the filter will be added to the selected filter as a sub filter.
* Fixed issue with Pet filters not working properly because ids were not correct
    * Pet filters now uses muffins list of level 1s and 25s
* Due to filter changes and editing of default filters, the previous changes on custom filters of no longer using global has been reverted. Filters now use global unless specifically checked off on its settings. 
* Your custom filters should be moved over to the new format automatically, if not let me know.
* Due to the new filter format, your previously saved selected filters on the sniping window will be cleared in order to support the new format. 
* Fixed issue where if only selecting a parent filter, the global settings were not passed down to the subfilters properly.
* Properly adds a default percent string if using Auctionator and nothing else.

AnS Changes 1.0.5.5
----------
* Fixed issue where other items were showing when using a item id not associated to it.
* Fixed issue where you couldn't use any words with a space in it, in the new filter types and subtypes on custom filters.
* No longer automatically focuses the name filter box on the sniper window

AnS Changes 1.0.5.4
-----------
* Can now define your own custom variables under ESC -> Interface -> Addons -> AnS -> Custom VARS. Anything related to filter strings or percent strings applies to these as well.
    * they can be used in both filter or percent strings
* Added the following functions to filter / price strings: check(v1,v2,v3), iflte(v1,v2,v3,v4), ifgte(v1,v2,v3,v4), iflt(v1,v2,v3,v4) ifgt(v1,v2,v3,v4), ifeq(v1,v2,v3,v4), ifneq(v1,v2,v3,v4)
    * Understanding the check function: If v1 is greater than 0 then v2 is returned otherwise v3 is returned.
    * Understanding if functions: v1 and v2 are compared, if true v3 is returned; if false v4 is returned.
* vendorsell predefined variable is now available for items in strings
* Can now use percent shorthand like TSM such as: 15% dbmarket
* Custom filters now completely ignore global settings.
* Removed the the checkboxes for global settings on custom filters (no longer needed and they were confusing).
* Custom filters can now specify item type and item subtypes, if you don't want to use item ids
    * E.g Item Types: armor,weapon Subtypes: leather,plate,bows,crossbows
    * The item types and subtypes are comma separated.
    * For a complete list of item types and subtypes see: http://wowwiki.wikia.com/wiki/ItemType
* Fixed a UI bug in Custom Filters Config screen, where deleting a custom filter would not properly reset the scroll view offset.
* Bonus ids from auction links are now sorted from lowest to highest, to be consistent with TSM. This should fix the issue of not seeing BOE from Uldir if using muffins id lists.
* You may notice several extra UI template files / UI component lua files that are not currently used by any AnS addons. These are for the analytics addon and its UI that is in developement (It is getting there).


AnS Changes 1.0.5.3
-----------
* Added full support for TSM pet ids of p:speciesId:petLevel:petQuality. E.g. p:123:1:2 or p:123:1
* Added support for TSM variables: dbglobalminbuyoutavg, dbglobalmarketavg, dbglobalhistorical, dbglobalsaleavg, dbglobalsalerate, dbglobalsoldperday.
* No longer requires AnsTSMAuctionDB variable modification in TSM LUA files.


AnS Changes 1.0.5.1
-----------
* Queries now have a rolling query id from 0 - 99999. To help detect if the item is within the current query context.
* You can now disable the DressUp window in AnS global settings. ESC -> Interface -> Addons -> AnS -> Show DressUp Toggle
* Filter selection for predefined and custom filters is now saved.
* Fixed possible bug of config settings getting erased during trying to load into text boxes etc.


AnS Changes 1.0.5
-----------

* More memory optimizations (Missed some last time)
* Now supports TSM bonus ids in the format of i:itemid::numbonus:bonus1:bonus2...
* Fixed an issue in pricing/percent/filter string where if you were using dbmarket, tujmarket, etc. without the addons, would throw a lua error. Now all the pricing sources have a default value of 0 and are included, even without the addons.