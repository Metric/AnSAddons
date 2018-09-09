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