## AnS [Auction Sniper] Changes 2.2.6.4

-   Sniper window quality selection on retail is no longer just min quality. You can now select individual qualities to use or not use. Classic is still min quality based.

-   Implemented some delays for classic to try and help with the internal auction house error. Which is due to blizz adding in a hidden wait time between certain actions.

-   On classic, if the sniper does not receive a list update response after 5 seconds, it will now reset itself and try again. Previously it would get stuck and require a manual restart.

## AnS [Auction Sniper] Changes 2.2.6.3

-   Fixed a nil reference exception that could happen in certain cases when trying to start sniper.

## AnS [Auction Sniper] Changes 2.2.6

-   Fixed an issue in classic, where it became impossible to buy from a group when it was several stacks grouped together.
-   Fixed an issue in classic, where New Chat Message alert could throw a nil exception.

## AnS [Auction Sniper] Changes 2.2.5

-   Fixed an issue in Sniper where results would disappear from the list on retail when it shouldn't or not be added at all on retail. This one was a tricky one to figure out how to fix. It was several problems combined causing this issue. First, known items / groups was being cleared too early. Second, the hashing method was not taking into account the retail itemKey.itemSuffix properly. Thus, things were being overwritten in the known lookup table, because it was only looking at the itemLevel and itemID for the general grouping. Hence, items disappearing from the list for no reason, or not being included at all. It now takes into account the proper itemSuffix for general grouping.

-   Fixed an issue where if Skip Lowest Seen Group was checked for Sniping settings, it would miss groups for items that share a common itemLevel and itemID but differing itemSuffix. It now takes into account the itemSuffix as well.

-   Fixed an issue in retail for Sniper, where scanning for battle pets could cause an nil exception to be thrown.

-   Fixed an issue where there was still a memory leak on both classic and retail in Sniper. Should see a pretty big decrease in memory gain rate on both. As well as the memory properly clearing after a bit of closing the AH.

## AnS [Auction Sniper] Changes 2.2.4

-   Fixed a memory leak where tables were added to the recycler when they shouldn't be. And thus they were cached forever until a UI reload.

## AnS [Auction Sniper] Changes 2.2.1

-   Fixed an issue where an invalid variable check was happening for SnipeFirst

## AnS [Auction Sniper] Changes 2.2.0

-   Updated to work with latest AnS core changes.
-   Fixed an issue where the same tables were recycled twice.

## AnS [Auction Sniper] Changes 2.0.5

-   Fixed issue where stuff would not show up until the second scan, or not at all when it came to commodities.

## AnS [Auction Sniper] Changes 2.0.4

-   Owner / account items and commodites are now filtered out of the results properly in the sniper window.

## AnS [Auction Sniper] Changes 2.0.3

-   Fixed an issue where it would get stuck if lots of categories or subcategories were selected at once.
    -   Note: If using TUG for pricing, then it will not find all items if selecting many categories. Because, TUJ does not support looking up by just a numeric ItemID at the moment. TUJ will find some but is limited, because of how much cached item info the WoW client stores for auction item key info and item info. It seems the WoW client will only cache the last 5000 or so. So, by the next time the scan comes back around TUJ still return no data, because it uses GetItemInfo() which will have to query the server again. Since, by then it would have already been pushed out of the 5000 cache if scanning lots of items.
    -   I have put in a github issue with erorus for the TUJ addon and provided code for the fix. As to if or when he updates it, I cannot say.
    -   TSM is not affected by this issue, since TSM automatically converts numeric ItemID's to the proper TSM key string it needs to lookup the item, without using GetItemInfo().
-   Added sub sub categories for Armor.

## AnS [Auction Sniper] Changes 2.0.2

-   Fixed an issue where some items were being skipped, due to not requesting all available pages of the items / commodities.
-   Fixed an issue where trying to buy a commodity right before a new scan started would cause a weird state transition. Thus, needing a /reload to fix it.
    -   The next scan will now wait for the commodity to finish via success or failure before moving on.
-   Fixed an issue where it was trying to dress up a battle pet.
-   Added info for how many items processing in the browse query.
-   Added chat error messages for various things.
-   Added a new purchase overlay letting you know it is trying to purchase the selected commodity / item.
-   Added a new Commodity Confirm option
    -   It is off by default in the settings
    -   If you leave it off then things will work as previously where you will buy all available at the selected line item PPU and count.
    -   Turning it on will allow you to input the number you want to buy. By default it is set to total of the line item that you selected. The ppu is based on the line item selected.

## AnS [Auction Sniper] Changes 2.0.1

-   Fixed an issue where battle pets were incorrectly listing the quality or pet level in the ilvl field in some cases.

## AnS [Auction Sniper] Changes 2.0

-   A BIG shout out to u/turmixer123 on Reddit for helping test this update and giving me an idea on how to make this faster than TSM sniper for 8.3.
-   Rewrite for 8.3
-   UI Updated to match new Auction House
-   New base filters on the left using Blizzard API to speed up scanning
    -   You really want to use the base filters otherwise it will be just as slow as TSM
    -   You can select multiple at a time. The more that is selected the slower it will be.
    -   This is what makes it faster combined with CLevel Range, Min iLevel, Min Quality, and Custom Filters.
-   Custom filters on right, which are applied along with the base filters
-   Removed Min Stack as it is no longer needed
-   Added CLevel Range. I highly recommend you take advantage of this to speed the scan up for equipment based searches
-   Can now blacklist item ids via Control + Left Click
-   New scan delay if items are found. Defaults to 5 seconds before starting new search.
    -   Can be changed under Interface -> Addons -> AnS
    -   This will be back ported for classic as well
-   Removed safe buy and safe buy delay as it is no longer needed with new Auction House API
-   Commodities are separated by ppu. If you double click it, be prepared to buy all at that ppu or lower.
    -   Will add in a way to select amount in another update

## AnS [Auction Sniper] CHANGES 1.0.6.4

-   Added a rewind button that starts at last page and goes to the first page and then resets.

## AnS [Auction Sniper] CHANGES 1.0.6.3

-   Fixed issue where quality dropdown was broken.

## AnS [Auction Sniper] CHANGES 1.0.6.2

-   Added in a time out to reset the sniper if it fails to receive a response from a query within 30 seconds. This is to try and fix where it gets stuck on query sent every so often.

## AnS [Auction Sniper] CHANGES 1.0.6.1

-   Fixed issue where when using AuctionSnipe:BuyFirst(), it would not go to the next item after the previous was all bought
-   Fixed error if you tried to use AuctionSnipe:BuyFirst() or AuctionSnipe:BuySelected() without opening the AH first.

## AnS [Auction Sniper] CHANGES 1.0.6

-   Filter list is now a tree view.
-   Code refactored to remove most things from global namespace

AnS [Auction Sniper] CHANGES 1.0.5.4

---

-   Big thanks to tieonlinux for submitting a pull request, which prevents purchasing the wrong item.
-   Removed recent column header as it was confusing and served no purpose at this point.
-   Stack price has been replaced with seller name, if it is known, otherwise you will see a ? instead.
    -   Please let me know, if you want this reverted.
-   Created function access for TSM macro bindings for mouse wheel etc. for the two available key bindings: AuctionSnipe:BuySelected() and AuctionSnipe:BuyFirst().

## AnS [Auction Sniper] CHANGES 1.0.5.3

-   You can disable Safe Buy in ESC -> Interface -> Addons -> AnS -> Safe Buy Toggle.
    -   Safe Buy prevents you from purchasing after a query is sent. So, you don't end up with the wrong item.
-   Added option on sniper window to turn off ding
-   Added where you can edit global filter string on sniper window
-   Fixed issue where it would sometimes get stuck on waiting for query indefinitely
-   Added option to control max value of safe query delay for spam clicking. (Only applies if Safe Buy is on)

## AnS [Auction Sniper] CHANGES 1.0.5.1

-   Added reset button for filter list to clear them all.
-   No longer auto removes a listing once all stacks are bought, in order to prevent misclicking / buying the wrong thing. Instead, it will go down to 0 and stay, until the next query goes through. It may seem like the item is still there on the next update, and that is because your purchase may just have been sent, and the query happened slightly before it. But, luckily it should show them going down as your purchases go through.
-   Changed the delay to be 1 second added everytime you click an item listing or try to purchase it, instead of 0.5s. Still up to a maximum of 4 seconds. (This only applies to the delay before a new query is sent, and not the actual clicking / purchasing of the item)
-   Whenever a new query is loaded, the selected item is now reset to nothing, in order to prevent accidental buying of the wrong item, when clicking or through button presses.
-   You can now CTRL-LEFT Click to temporarily blacklist that item type completely until the AH is closed. e.g. ctrl left click on a linen cloth listing. It will be removed and no further linen cloth listings will display until the AH is closed.
-   Left side filter selection is now saved.
-   The visual and interactive listing in the UI is now a deep copy of the query listing. Previousely they shared the same listing source.
-   With the above change, each query now has a unique id that is rolling from 0 - 99999. This id is now used to check to make sure the given item is within the current query context when trying to purchase. If it is not, then the purchase action is ignored. This should help prevent buying items that have taken the place of the item trying to be purchased, after the listing has changed. Spam clicking / buying was affected by the aformentioned problem.

## AnS [Auction Sniper] CHANGES 1.0.5

-   Added key bindings for buying selected auction, or buying the first auction listed (Available under ESC -> Bindings - > AnS)
-   Adjusted the display of how groups are shown. It now says: x stack of x item name. For example: 10 stack of 200 Tidespray Linen. Which means there are 10 stacks in the group and each stack consists of 200 Tidespray Linen.
-   Armor, weapons, pets, and other equippable items now will show the dress up window with that item or pet, when selected.
-   Now prevents buying if a new AH query has been sent. This helps prevent from buying the wrong item during the transition.
-   If you are spam buying, then a 0.5 second delay is added before sending a new AH query. Maximum up to 4 second delay on sending the new query. (Do not confuse this with purchasing, you can still spam purchase!). This is to keep the listing from changing until you are done buying for a period of time.
-   Added where SHIFT-Left Clicking an auction listing will blacklist it temporarily until the AH is closed.
