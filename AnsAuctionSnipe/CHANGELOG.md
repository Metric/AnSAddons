AnS [Auction Sniper] CHANGES 1.0.6.4
----------------------------
* Added a rewind button that starts at last page and goes to the first page and then resets.

AnS [Auction Sniper] CHANGES 1.0.6.3
------------------------
* Fixed issue where quality dropdown was broken.

AnS [Auction Sniper] CHANGES 1.0.6.2
---------------------
* Added in a time out to reset the sniper if it fails to receive a response from a query within 30 seconds. This is to try and fix where it gets stuck on query sent every so often.

AnS [Auction Sniper] CHANGES 1.0.6.1
---------------------
* Fixed issue where when using AuctionSnipe:BuyFirst(), it would not go to the next item after the previous was all bought
* Fixed error if you tried to use AuctionSnipe:BuyFirst() or AuctionSnipe:BuySelected() without opening the AH first.


AnS [Auction Sniper] CHANGES 1.0.6
---------------------
* Filter list is now a tree view.
* Code refactored to remove most things from global namespace


AnS [Auction Sniper] CHANGES 1.0.5.4
--------------------- 
* Big thanks to tieonlinux for submitting a pull request, which prevents purchasing the wrong item.
* Removed recent column header as it was confusing and served no purpose at this point.
* Stack price has been replaced with seller name, if it is known, otherwise you will see a ? instead.
    * Please let me know, if you want this reverted.
* Created function access for TSM macro bindings for mouse wheel etc. for the two available key bindings: AuctionSnipe:BuySelected() and AuctionSnipe:BuyFirst(). 

AnS [Auction Sniper] CHANGES 1.0.5.3
---------------------
* You can disable Safe Buy in ESC -> Interface -> Addons -> AnS -> Safe Buy Toggle.
    * Safe Buy prevents you from purchasing after a query is sent. So, you don't end up with the wrong item.
* Added option on sniper window to turn off ding
* Added where you can edit global filter string on sniper window
* Fixed issue where it would sometimes get stuck on waiting for query indefinitely
* Added option to control max value of safe query delay for spam clicking. (Only applies if Safe Buy is on)


AnS [Auction Sniper] CHANGES 1.0.5.1
-------------------

* Added reset button for filter list to clear them all.
* No longer auto removes a listing once all stacks are bought, in order to prevent misclicking / buying the wrong thing. Instead, it will go down to 0 and stay, until the next query goes through. It may seem like the item is still there on the next update, and that is because your purchase may just have been sent, and the query happened slightly before it. But, luckily it should show them going down as your purchases go through.
* Changed the delay to be 1 second added everytime you click an item listing or try to purchase it, instead of 0.5s. Still up to a maximum of 4 seconds. (This only applies to the delay before a new query is sent, and not the actual clicking / purchasing of the item)
* Whenever a new query is loaded, the selected item is now reset to nothing, in order to prevent accidental buying of the wrong item, when clicking or through button presses. 
* You can now CTRL-LEFT Click to temporarily blacklist that item type completely until the AH is closed. e.g. ctrl left click on a linen cloth listing. It will be removed and no further linen cloth listings will display until the AH is closed.
* Left side filter selection is now saved.
* The visual and interactive listing in the UI is now a deep copy of the query listing. Previousely they shared the same listing source.
* With the above change, each query now has a unique id that is rolling from 0 - 99999. This id is now used to check to make sure the given item is within the current query context when trying to purchase. If it is not, then the purchase action is ignored. This should help prevent buying items that have taken the place of the item trying to be purchased, after the listing has changed. Spam clicking / buying was affected by the aformentioned problem.  


AnS [Auction Sniper] CHANGES 1.0.5
-------------------

* Added key bindings for buying selected auction, or buying the first auction listed (Available under ESC -> Bindings - > AnS)
* Adjusted the display of how groups are shown. It now says: x stack of x item name. For example: 10 stack of 200 Tidespray Linen. Which means there are 10 stacks in the group and each stack consists of 200 Tidespray Linen.
* Armor, weapons, pets, and other equippable items now will show the dress up window with that item or pet, when selected.
* Now prevents buying if a new AH query has been sent. This helps prevent from buying the wrong item during the transition.
* If you are spam buying, then a 0.5 second delay is added before sending a new AH query. Maximum up to 4 second delay on sending the new query. (Do not confuse this with purchasing, you can still spam purchase!). This is to keep the listing from changing until you are done buying for a period of time.
* Added where SHIFT-Left Clicking an auction listing will blacklist it temporarily until the AH is closed.