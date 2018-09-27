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

You can buy while it is still scanning all the pages. It will pause the scan to try and find the auction and then show a confirmation to click buy. After buying or canceling, the previous scanning will resume.

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
* Add a config option for how many pages you want scanned for buying and selling (right now it is hard coded to 4)
* Add an option for setting default stack size to sell
* Add an undercut by ... amount