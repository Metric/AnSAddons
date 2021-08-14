## AnS Changes 2.2.6.4

-   Fixed issue where Fonts for other languages were not taken into account properly. All provided fonts by blizz are now used as expected for the languages they support: Russian, Simplified Chinese, Traditional Chinese, Korean, and Roman based languages.

-   Fixed an issue where Expenses were not included properly in the Income tab calculation on Ledger.

-   Fixed and issue where Posting / Cancelling could get stuck in situations. It now just skips the problem item and continues on after 2 seconds.

-   Fixed issue where shorthand percent would be incorrect in some cases

-   Implemented a special check to prevent interruption of sniper if one of your auctions is sold and you are running TSM.

-   Fixed an issue where battle pets could not be posted / cancelled.

-   Sniper window quality selection on retail is no longer just min quality. You can now select individual qualities to use or not use. Classic is still min quality based.

-   Implemented some delays for classic to try and help with the internal auction house error. Which is due to blizz adding in a hidden wait time between certain actions.

-   On classic, if the sniper does not receive a list update response after 5 seconds, it will now reset itself and try again. Previously it would get stuck and require a manual restart.

-   Added in TBC vendor data

## AnS Changes 2.2.6.3

-   Fixed an issue where battle pets would not be processed properly from purchased auction mail. And thus their links would not show in the transaction log properly.

-   Reworked tooltip in AnsAuctionData to work with other tooltip addons such as TSM / TUJ better.

-   Fixed a nil reference exception that could happen in certain cases when starting sniper.

-   Fixed TBC classic keybinding not saving properly.

-   Updated Auction Operation UI Time listing for TBC classic.

-   Added in vendor buy for pet ids. The price return for them may be gold or pet token amount. Just check for vendorbuy > 0 to determine if it is a pet bought from a vendor.

## AnS Changes 2.2.6.1

-   Fixed an issue where AnsAuctionData would throw an exception on WoW Classic in some cases.
-   Fixed an issue where retail AH Search Query would skip items when messages were throttled.
    -   This also fixed the issue where items would not cancel properly in some cases

## AnS Changes 2.2.6

-   Added a new option for Auctioning operation for matching the lowest price for Max Value and Min Value
-   Tried to fix an issue on retail, where items would not cancel if same price, but not latest auction for LiFo.
    -   It may work, but not always at the moment. Hoping, to get it working always next update.
-   Fixed an issue for Auctioning operations where Max to Post was not calculated properly, due to not properly checking for exact item matching.
-   Fixed an issue for Auctioning operations where it was not filtering items properly in some cases.
-   Fixed an issue where item match was not working properly for Auctioning operations, when only iLevel was selected for Search Type.

-   Fixed an issue in sniper for classic, where it became impossible to buy from a group when it was several stacks grouped together.
-   Fixed an issue in classic, where New Chat Message alert could throw a nil exception.

-   Increased parsing speed when using bonus() in formulas
-   Improved memory rate usage when Skip Last Seen Group was active and was constantly rescanning same groups over and over on Retail.

## AnS Changes 2.2.5

-   Fixed an issue in Sniper where results would disappear from the list on retail when it shouldn't or not be added at all on retail. This one was a tricky one to figure out how to fix. It was several problems combined causing this issue. First, known items / groups was being cleared too early. Second, the hashing method was not taking into account the retail itemKey.itemSuffix properly. Thus, things were being overwritten in the known lookup table, because it was only looking at the itemLevel and itemID for the general grouping. Hence, items disappearing from the list for no reason, or not being included at all. It now takes into account the proper itemSuffix for general grouping.

-   Fixed an issue where if Skip Lowest Seen Group was checked for Sniping settings, it would miss groups for items that share a common itemLevel and itemID but differing itemSuffix. It now takes into account the itemSuffix as well.

-   Fixed an issue in retail for Sniper, where scanning for battle pets could cause an nil exception to be thrown.

-   Fixed an issue where there was still a memory leak on both classic and retail in Sniper. Should see a pretty big decrease in memory gain rate on both. As well as the memory properly clearing after a bit of closing the AH.

-   Fixed the issue where bonus() formula function would not ignore browse query groups on retail.

-   Fixed an issue from last build where bonus(), startswith(), and contains() formula functions would not return true or false if only the first argument was provided.

-   Added a new formula variable called: isgroup. isgroup = true if it is a browse group query calling the formula on retail. Otherwise it is false.

## AnS Changes 2.2.4

-   Updated TOC number for latest Retail patch

-   Fixed an issue where avg, check, and other formula functions did not properly ignore 0 or did not return 0 incase of nil value.

-   Updated default Auctioning Operation formulas for TSM to be nearer to TSM default.

-   Updated default Auctioning Operation formulas for AnS to be slightly more accurate

-   Fixed a memory leak in Sniper where tables were added to recycler when they shouldn't be. Thus, causing the table to remain in memory until a UI reload.

-   Added new toggle for global Sniper Settings and Sniper Operations to ignore group percent validation check for Retail. By enabling this, it will ignore the percent check on the browse group, but still check the individual search results percent value. Thus, allowing better BOE / Legendary sniping in retail, where in you can now target by min iLevel, percent, and groups / basic formulas again.

-   Added a new Craft Cost in the crafting window. It is only visible when you select the specified craft. It is displayed in the detail area near the top right beneath the item name.

-   Add toggles in Crafting Settings to hide the showing of Craft Profit and Craft Cost in the crafting window.

-   You can now add items directly to the item blacklist in settings by item id strings such as: i:13456 or p:134 (battle pet). You can also just specify the item base number raw: 13456. The battlepet p: is still required for pets.

-   Verified crafting formulas were being filled in properly for AnsAuctionData, if TSM and TUJ was not initially active and only AnsAuctionData was.

-   Fixed an issue where Auctionator support was incomplete.

## AnS Changes 2.2.3

-   Fixed issue with Modifiers not being correct for item ids
-   Fixed issue where vendorbuy was no longer working due to item ids with modifiers
-   Fixed issue where runecarving replaced finger slot under misc on sniper filter view
-   Fixed an issue where AnsAuctionData pricing statistics was miscalculated on classic.
-   Added in Option to Auction Operations to scan pricing by iLevel or iLevel+Mods
-   Added back in tooltip toggles for Region Min / Region Market
-   Added back in support for new version of Auctionator
-   Optimized AnsAuctionData for new AnS auction pricing for retail via the new AnS app.
-   Ledger now features an Inventory view that includes inventory + bank at the momemnt
    -   Will add in Owned Auctions later.
    -   It also shows the total gold worth of the inventory + bank
    -   You can also filter by individual characters
    -   Shows how many of each item you have as well
    -   Works with legendary / crafted items and knows the difference between the item levels / mods
    -   Total gold may be incorrect for TSM pricing for legendary / crafted item with mods until they solve their issue with ilvl / mods
    -   Total gold pricing is correct with new AnsAuctionData from AnS app

## AnS Changes 2.2.2

-   Added in missing Runecarver filter on retail

## AnS Changes 2.2.1

-   Made min() and max() formula functions work similar to tsm, instead of using the default math.min and math.max functions.
    -   This should allow proper calculations for crafting profits that line up with TSM crafting profits etc.
    -   It will also eliminate weird errors that others may have been having when trying to use min and max etc.
-   Added in vellum calculation into enchanting profits for retail
-   Optimized the lookup for prospect / mill values and results

## AnS Changes 2.2.0 (Includes fixes from 2.1.2.2 - 2.1.4)

## 2.1.2.2 - 2.1.2.6

-   Fixes for classic ppu decimal issue, and fix for where in character blacklist entry was not converting to lower case before converting to list
-   Added in support for changing the orientation of the minimap icon via /ansminimap (degrees). Replace (degrees) with actual degrees to be rotated around the minimap center. Can also hide / show minimap icon with just /ansminimap. As a reminder, you can show / hide ans settings window with /ans.
-   Fixes issue where blizz replaced old LE\_ Inventory Types with new Enum.InventoryTypes accessor in latest patch for retail.

### 2.1.3 - 2.1.4

-   Added default data for SL for herbs etc groups. To add the data to your groups, click the new Restore Default in the groups view in the top left. It will restore just the default groups predefined in AnS. It will not touch your custom made groups.
-   Fixed a divide by zero bug in Analytics Query when Gold Tracking was turned off.
-   Can now toggle item id tooltip display.
-   Fixed bug where in macro would not be generated properly if both Up and Down were both selected.
-   Macro no longer requires script access for using AnsBuyFirst. I have now added a hidden button that is clickable with /click AnsSnipeFirst.
-   Added a play button to Sniper Settings to preview the ding sound for when an auction is found.
-   Added in proper Classic Vendor Buy data.
-   Added in new SL Vendor Buy data.
-   Added in a short description about where the macro is created below the Create Macro Button.
-   Fixed bug with minQuality not saving in some cases properly and not properly updating the UI.
-   Crafting profit in crafting UI for Enchanting updated for SL.
-   Added operations for sending items through mail. Will add send gold / send with cod later.
-   Fixed issues where trying to access AHFrame or Craft Frame would cause a nil exception, when TSM was auto switching to the TSM UI before the original blizz frame could be instantiated.
-   Fixed an issue where itemKey from blizz scan update event would come back with iLevel 0 in some cases, even though the expected iLevel from inventory or owned auctions would not be 0. Thus causing the query state machine to not continue on properly. Thanks Blixtmen for helping figure this one out.
-   Fixed an issue where iLevel was not being properly filled in with incoming auction data.
-   Added log messages for throttle events for future debugging purposes if needed.

### 2.2.0

-   Underlying Folder Structure Cleanup / Code Cleanup
-   Moved to using Mixins for primary UI elements, except for posting, mailing, auction data scan, and sniper UI.
-   Slight UI rework in some areas for better usability.
-   Crafting profit for Mass Mills and Mass Prospect now works properly
-   Crafting profit now takes into account all sub crafts, but only after scrolling through all your crafts and loading them at the moment.
-   New settings tab for Blacklist, where in you can find a better character blacklist entry and permanent item blacklist removal.
-   Sniper global settings now has a checkbox to ignore stacks of 1 for commodities
-   Can now hide mailing send / post cancel windows
-   Users can now define how many storage rows per character are allowed for tracking analytics for gold etc.
-   Formulas will now have a green background when they are valid.
-   Fixed issue where item id was trying to be listed twice in some cases.
-   Fixed a memory leak when running lots of AH searchs on retail.
-   Custom sources can now be reordered.
-   Custom sources now have a confirmation window for deletion.
-   Group editor now features item links when possible
-   Group editor has new import / export dialogs.
-   Operations can now be imported / exported - (Not compatible with TSM)
-   Updated SL vendor buy items with latest patch data
-   Can now ctrl + click minimap icon to reset all window positions to center
-   New destroy window and destroy features for macro
-   Can now right click minimap icon to open destroy window
-   New settings for destroy window can be found under Settings -> Crafting
-   Known Issue: Destroy window text overlaps for individual results of a selected item in some cases.

## AnS Changes 2.1.2

-   Can now select from all possible sound kit sounds for Ding for sniper
-   Item ID now displayed in tooltips
-   Can now toggle WoW Icon Flash on or off for sniper found
-   Query count now back in place for classic and should provide more user friendly ui updates for it
    -   It only goes up to 9,999 then resets back to 1
-   Multiline text areas now easier to focus
-   Fixed an issue where tabs or newlines in algorithm strings would cause incorrect results
-   Fixed an issue for retail where in sniper would get stuck in purchase mode if the item was not found
-   Can now toggle minimap icon with /ansminimap
-   Can now toggle main ans window with /ans
-   Macro generator no longer binds directly to mouse down, you must now select mouse down, mouse up, or both
-   Can now toggle whether Ans will remember the position of the Auction House window or Craft window.

## AnS Changes 2.1.1

-   Can now select active / inactive groups per operation in sniping window / post / cancel.
-   Max to post is now character based and properly limits total based on amount already on AH.
-   Custom sources for TSM: avgBuy, avgSell, Destroy, maxBuy, maxSell now available.
-   Snipe operations can now inherit global snipe window settings and global snipe settings for Max Price / Boolean filter.
-   Corrected miscalculated Y Graph gold values UI text.
-   Fixed issue where MoneyStringToCopper was producing invalid return results for money string with spaces.

## AnS Changes 2.0.6

-   Fixed issue where stuff would not show up until the second scan, or not at all when it came to commodities.
-   Will now only check global max percent and global ilevel if they are greater than 0.
-   Fixed a formatting issue in Utils for PriceToString.
-   Fixed an issue where MoneyStringToCopper would not return the proper results due to spaces.

## AnS Changes 2.0.5

-   Fixed an issue where blacklist would not work properly if you had just edited it.
-   Added blacklist checking for multiple owners on commodities

## AnS Changes 2.0.4

-   Fixed an issue where group quality level default was set incorrectly in 2.0.3. Thus, preventing proper filtering and returning no results in some cases.

## AnS Changes 2.0.3

-   Added base data support for sub sub base filters
-   Added a new method for the group filtering part, so the sniper will not get stuck.
-   Fixed an issue where a parent custom filter would still return true if it only had a filter string and no ids, but it had children with ids.

## AnS Changes 2.0.2

-   Added an option to turn on Commodity Purchase Confirm. The confirmation allows you to set the number of items to buy before purchasing.

## AnS Changes 2.0.1

-   Added support for toggling Exact ID Matching for bonus ids, pet levels and pet breed quality in custom filters. Turn off Exact ID Matching if you want to just use a base item / pet id in the custom filter that does not include bonus ids, or pet level and pet breed quality.
    -   This will be back ported to classic as well

## AnS Changes 2.0

-   A BIG shout out to u/turmixer123 on Reddit for helping test this update and giving me an idea on how to make this faster than TSM sniper for 8.3.
-   Complete rewrite for 8.3 Query Handling etc
-   Removed unneeded settings
-   Filters do not require item ids anymore.
    -   Thus you can use just the filter string in them now for quicker access to different types of filters without relying on global
    -   this will be back ported for classic as well

## AnS Changes 1.0.6.7

-   Fixed some bugs in bag scanner, where non auctionable items would be added to the GetAuctionable() list.
-   Updated query.lua to support new features for AnsAuctionData tracking and scanning.
-   Added a button to clear realm auction data for AnsAuctionData to Global Settings

## AnS Changes 1.0.6.6

-   Fixed a small bug when no valid auction link provided.
-   Implemented a few new functions available for filters etc: eq, neq, contains, startswith
    -   eq: simply checks to see if two values equal each other and returns either true or false
    -   neq: checks to see if two values do not equal eath other and returns either true or false
    -   contains: checks to see if a string contains the provided substring
    -   startswith: checks to see if a string starts with the provided substring
-   You can now use tsmId and id in filters. tsmId is a string and starts with i: for items and p: for pets. id is the numeric form of the id provided straight from the auction house listing.
    -   Example of matching every item except the given with tsmId: tsmId ~= "i:12456"
    -   Example of matching every item except the given with id: id ~= 12456
    -   Example of matching every item except the given with tsmId and new neq function: neq(tsmId, "i:12456")
    -   Example of matching every item except the given with id and new neq function: neq(id, 12456)
    -   Example of seeing if tsmId starts with "i:123": startswith(tsmId, "i:123")

## AnS Changes 1.0.6.5

-   Fixed issue where bag scanner was not properly handling pet links. Resulting in an error being thrown in AnSAuctions Sell Module.

## AnS Changes 1.0.6.4

-   Fixed a bug, where if you use just the base id for an equipment, it would be ignored. As it would be trying to only find the equipment with bonus ids. This was a regression, as previously this was taken into account, but during optimizing for stuttering, I forgot to add it back in.

## AnS Changes 1.0.6.2

-   Made the font size larger for most things, until I can implement a font scaling option.
-   Fixed bug where an invalid variable name was used to check for auction owner vs your character name. In order to not display your auctions etc.
-   Added a character blacklist (1 name per line)
-   Can now pick between g.s.c or coin icons for money display.
-   Money display now has separators for gold: 1,000,000g ...
-   Optimized certain function calls for lower memory usage
-   Fixed issue with frame stuttering when quite a few filters were active at once, with lots of ids. May see slight memory usage increase over time, as caching is used. To clear the cache, just close the AH window.

## AnS Changes 1.0.6.1

-   Fixed misspelled variable when trying to access dbregionhistorical
-   Filters can now be moved from group to group via the move button
-   Child filters that have blank types, subtypes, or a filter string, will now inherit the parents when sniping

## AnS Changes 1.0.6

-   Code refactored to remove most things from global namespace
    -   Can be accessed from AnsCore.API instead
    -   If you find any issues please post them on reddit post or message me on reddit
-   Custom Filters in ESC -> Interface -> Addons -> AnS is now called Filters
-   Filters can now have sub filters and the default filters are now fully editable
    -   Try to keep the child sub depth reasonable to about 4.
    -   Try to keep the parent root name unique as it is used as path for keeping track of currently selected filters in the sniping window now.
    -   When pressing the New button, the filter will be added to the selected filter as a sub filter.
-   Fixed issue with Pet filters not working properly because ids were not correct
    -   Pet filters now uses muffins list of level 1s and 25s
-   Due to filter changes and editing of default filters, the previous changes on custom filters of no longer using global has been reverted. Filters now use global unless specifically checked off on its settings.
-   Your custom filters should be moved over to the new format automatically, if not let me know.
-   Due to the new filter format, your previously saved selected filters on the sniping window will be cleared in order to support the new format.
-   Fixed issue where if only selecting a parent filter, the global settings were not passed down to the subfilters properly.
-   Properly adds a default percent string if using Auctionator and nothing else.

## AnS Changes 1.0.5.5

-   Fixed issue where other items were showing when using a item id not associated to it.
-   Fixed issue where you couldn't use any words with a space in it, in the new filter types and subtypes on custom filters.
-   No longer automatically focuses the name filter box on the sniper window

## AnS Changes 1.0.5.4

-   Can now define your own custom variables under ESC -> Interface -> Addons -> AnS -> Custom VARS. Anything related to filter strings or percent strings applies to these as well.
    -   they can be used in both filter or percent strings
-   Added the following functions to filter / price strings: check(v1,v2,v3), iflte(v1,v2,v3,v4), ifgte(v1,v2,v3,v4), iflt(v1,v2,v3,v4) ifgt(v1,v2,v3,v4), ifeq(v1,v2,v3,v4), ifneq(v1,v2,v3,v4)
    -   Understanding the check function: If v1 is greater than 0 then v2 is returned otherwise v3 is returned.
    -   Understanding if functions: v1 and v2 are compared, if true v3 is returned; if false v4 is returned.
-   vendorsell predefined variable is now available for items in strings
-   Can now use percent shorthand like TSM such as: 15% dbmarket
-   Custom filters now completely ignore global settings.
-   Removed the the checkboxes for global settings on custom filters (no longer needed and they were confusing).
-   Custom filters can now specify item type and item subtypes, if you don't want to use item ids
    -   E.g Item Types: armor,weapon Subtypes: leather,plate,bows,crossbows
    -   The item types and subtypes are comma separated.
    -   For a complete list of item types and subtypes see: http://wowwiki.wikia.com/wiki/ItemType
-   Fixed a UI bug in Custom Filters Config screen, where deleting a custom filter would not properly reset the scroll view offset.
-   Bonus ids from auction links are now sorted from lowest to highest, to be consistent with TSM. This should fix the issue of not seeing BOE from Uldir if using muffins id lists.
-   You may notice several extra UI template files / UI component lua files that are not currently used by any AnS addons. These are for the analytics addon and its UI that is in developement (It is getting there).

## AnS Changes 1.0.5.3

-   Added full support for TSM pet ids of p:speciesId:petLevel:petQuality. E.g. p:123:1:2 or p:123:1
-   Added support for TSM variables: dbglobalminbuyoutavg, dbglobalmarketavg, dbglobalhistorical, dbglobalsaleavg, dbglobalsalerate, dbglobalsoldperday.
-   No longer requires AnsTSMAuctionDB variable modification in TSM LUA files.

## AnS Changes 1.0.5.1

-   Queries now have a rolling query id from 0 - 99999. To help detect if the item is within the current query context.
-   You can now disable the DressUp window in AnS global settings. ESC -> Interface -> Addons -> AnS -> Show DressUp Toggle
-   Filter selection for predefined and custom filters is now saved.
-   Fixed possible bug of config settings getting erased during trying to load into text boxes etc.

## AnS Changes 1.0.5

-   More memory optimizations (Missed some last time)
-   Now supports TSM bonus ids in the format of i:itemid::numbonus:bonus1:bonus2...
-   Fixed an issue in pricing/percent/filter string where if you were using dbmarket, tujmarket, etc. without the addons, would throw a lua error. Now all the pricing sources have a default value of 0 and are included, even without the addons.
