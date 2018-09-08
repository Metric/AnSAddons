AnS Changes 1.0.5
-----------

* More memory optimizations (Missed some last time)
* Now supports TSM bonus ids in the format of i:itemid::numbonus:bonus1:bonus2...
* Fixed an issue in pricing/percent/filter string where if you were using dbmarket, tujmarket, etc. without the addons, would throw a lua error. Now all the pricing sources have a default value of 0 and are included, even without the addons.