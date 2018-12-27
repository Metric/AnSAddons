AnS [Auctions] Changes 1.0.2
-----------------------------
* Updated auction posting to match the new PostAuction api changes by blizzard.
* Fixed issue where the time duration was not being retrieved properly before trying to post an auction.

AnS [Auctions] Changes 1.0.1
-----------------------------
* Fixed issue when selling items from multiple listed stacks, the list would not update properly and remove the items listed.
* Improved item grouping for auction results
* Can now adjust max number of pages to scan
* Improved buy flow. Can now spam just a buy button. However, scanning has to complete first, before a purchase can be made. Can also add the following to a Macro: /run AnsAuctions:BuyAuction() It will try to buy the selected auction.