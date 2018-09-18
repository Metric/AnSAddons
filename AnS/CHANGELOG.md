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