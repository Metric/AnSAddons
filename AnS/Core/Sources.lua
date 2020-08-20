local Ans = select(2, ...);
local Data = Ans.Data;
local VendorData = Data.Vendor;
local Config = Ans.Config;
local Sources = { items = {}};
Sources.__index = Sources;
Ans.Sources = Sources;

local Utils = Ans.Utils;
local PriceSource = Ans.PriceSource;

local NameStringCache = "";
local SourceStringCache = "";
local CustomVarStringCache = "";

local OpCodes = {};
OpCodes.__index = OpCodes;

function OpCodes:New() 
    local op = {};
    op.percent = 0;
    op.ppu = 0;
    op.stacksize = 0;
    op.buyout = 0;
    op.ilevel = 0;
    op.vendorsell = 0;
    op.vendorBuy = 0;
    op.quality = 1;
    op.dbmarket = 0;
    op.dbminbuyout = 0; 
    op.dbhistorical = 0; 
    op.dbregionmarketavg = 0;
    op.dbregionminbuyoutavg = 0; 
    op.dbregionhistorical = 0; 
    op.dbregionsaleavg = 0; 
    op.dbregionsalerate = 0; 
    op.dbregionsoldperday = 0;
    op.dbglobalminbuyoutavg = 0;
    op.dbglobalmarketavg = 0;
    op.dbglobalhistorical = 0;
    op.dbglobalsaleavg = 0;
    op.dbglobalsalerate = 0;
    op.dbglobalsoldperday = 0;
    op.tujmarket = 0; 
    op.tujrecent = 0; 
    op.tujglobalmedian = 0; 
    op.tujglobalmean = 0;
    op.tujage = 0;
    op.tujdays = 0; 
    op.tujstddev = 0; 
    op.tujglobalstddev = 0;
    op.atrvalue = 0;
    op.ansrecent = 0;
    op.ansmarket = 0;
    op.ansmin = 0;
    op.ans3day = 0;
    op.avgsell = 0;
    op.avgbuy = 0;
    op.maxsell = 0;
    op.maxbuy = 0;
    op.destroy = 0;
    return op;
end

local VarCodes = {};

local OperationCache = {};
local OpValueCache = {};

local ParseSourceTemplate = "local %s = ops.%s or 0; ";
local ParseVarsTemplate = "local %s = %s or 0; ";

local ParseTemplate = [[
    return function(sources, ops)
        local ifgte, iflte, iflt, ifgt, ifeq, ifneq, check, avg, first, round,
            min, max, mod, 
            abs, ceil, floor, random, log, 
            log10, exp, sqrt = sources.ifgte, sources.iflte, sources.iflt, sources.ifgt, sources.ifeq, sources.ifneq, sources.check, sources.avg, sources.first, sources.round, math.min, math.max, math.fmod, math.abs, math.ceil, math.floor, math.random, math.log, math.log10, math.exp, math.sqrt;

        local eq, neq, startswith, contains = sources.eq, sources.neq, sources.startswith, sources.contains;
        local bonus = function(v1,v2,v3)
            return sources.bonus(ops.tsmId, v1, v2, v3);
        end

        local percent = ops.percent;
        local ppu = ops.ppu;
        local stacksize = ops.stacksize;
        local buyout = ops.buyout;
        local avgBuy, AvgBuy, Avgbuy = ops.avgbuy, ops.avgbuy, ops.avgbuy;
        local avgSell, AvgSell, Avgsell = ops.avgsell, ops.avgsell, ops.avgsell;
        local Destroy = ops.destroy;
        local maxSell, MaxSell, Maxsell = ops.maxsell, ops.maxsell, ops.maxsell;
        local maxBuy, MaxBuy, Maxbuy = ops.maxbuy, ops.maxbuy, ops.maxbuy;
        local ilevel, itemLevel, ItemLevel, itemlevel, Itemlevel = ops.ilevel, ops.ilevel, ops.ilevel, ops.ilevel, ops.ilevel;
        local quality, itemquality, itemQuality, ItemQuality, Itemquality = ops.quality, ops.quality, ops.quality, ops.quality, ops.quality;
        local vendorsell, vendorSell, Vendorsell, VendorSell = ops.vendorsell, ops.vendorsell, ops.vendorsell, ops.vendorsell;
        local vendorbuy, vendorBuy, VendorBuy, Vendorbuy = ops.vendorbuy, ops.vendorbuy, ops.vendorbuy, ops.vendorbuy;
        local tsmId = ops.tsmId;
        local id = ops.id;

        local DBMarket, Dbmarket = ops.dbmarket, ops.dbmarket;
        local DBMinBuyout, Dbminbuyout = ops.dbminbuyout, ops.dbminbuyout;
        local DBHistorical, Dbhistorical = ops.dbhistorical, ops.dbhistorical;

        local DBRegionMinBuyoutAvg, Dbregionminbuyoutavg = ops.dbregionminbuyoutavg, ops.dbregionminbuyoutavg;
        local DBRegionMarketAvg, Dbregionmarketavg = ops.dbregionmarketavg, ops.dbregionmarketavg;
        local DBRegionHistorical, Dbregionhistorical = ops.dbregionhistorical, ops.dbregionhistorical;
        local DBRegionSaleAvg, Dbregionsaleavg = ops.dbregionsaleavg, ops.dbregionsaleavg;

        %s

        %s

        return %s;
    end
]];


function Sources:ClearCache()
    NameStringCache = "";
    SourceStringCache = "";
    CustomVarStringCache = "";
    wipe(OpValueCache);
    wipe(OperationCache);
end

function Sources:ClearValueCache()
    wipe(OpValueCache);
end

function Sources:LoadCustomVars()
    wipe(VarCodes);
    for i,v in ipairs(Config.CustomSources()) do
        local value = v.value;

        if (value and value:len() > 0) then
            value = Utils:ReplaceOpShortHand(value);
            value = Utils:ReplaceShortHandPercent(value);
            value = Utils:ReplaceMoneyShorthand(value); 

            tinsert(VarCodes, {name = v.name, value = value});
        end
    end
end

function Sources:Register(name, fn, key)
    local source = PriceSource:New(name:lower(),fn,key);
    tinsert(self.items, source);
end

function Sources:GetNamesAsString()
    local str = "";
    local sep = "";
    local i;

    if (NameStringCache and NameStringCache:len() > 0) then
        return NameStringCache;
    end

    for i = 1, #self.items do
        local s = self.items[i];
        if (s.fn ~= nil) then
            str = str..sep..s.name;
            sep = ",";
        end
    end

    -- cache for future lookups
    NameStringCache = str;

    return str;
end

function Sources:GetCustomVarsAsString()
    local str = "";
    local i;

    if (CustomVarStringCache and CustomVarStringCache:len() > 0) then
        return CustomVarStringCache;
    else
        self:LoadCustomVars();
    end

    for i = 1, #VarCodes do
        local cvar = VarCodes[i];

        local nstr = string.format(ParseVarsTemplate, cvar.name, cvar.value);
        str = str..nstr;
    end

    CustomVarStringCache = str;

    return str;
end

function Sources:GetVarsAsString()
    local str = "";
    local i;
    local total = #self.items;

    if (SourceStringCache and SourceStringCache:len() > 0) then
        return SourceStringCache;
    end

    for i = 1, total do
        local s = self.items[i];
        if (s.fn ~= nil) then
            local name = s.name;
            local nstr = string.format(ParseSourceTemplate, name, name);
            str = str..nstr;
        end
    end

    SourceStringCache = str;

    return str;
end

function Sources:IsValidQuery(q)
    -- check for matching ()

    local sindex = 1;
    sindex = string.find(q, "%s?%(%s?", sindex);

    -- since no start (  was found
    -- check for straggling )
    if (not sindex) then
        sindex = string.find(q, "%s?%)%s?", 1);

        if (sindex) then
            return false;
        end
    end

    while (sindex) do
        sindex = sindex + 1;
        sindex = string.find(q, "%s?%)%s?", sindex);
        if (not sindex) then
            return false;
        end
        sindex = sindex + 1;
        sindex = string.find(q, "%s?%(%s?", sindex);
    end

    return true;
end

function Sources:GetValues(itemId, ops)
    local i;
    local total = #self.items;

    for i = 1, total do
        local s = self.items[i];
        if (s.fn ~= nil) then
            local r = s.fn(itemId, s.key, s.name);
            local v = r or 0;
            ops[s.name] = v;
        end
    end
end

Sources.round = function(n)
    if (n < 0) then
        return math.floor(n - 0.5);
    end
    
    return math.floor(n + 0.5);
end

Sources.avg = function(...)
    local totalItems = select("#", ...);

    local i;
    local t = 0;
    local amt = 0;

    for i = 1, totalItems do
        amt = amt + select(i, ...);
        t = t + 1;
    end

    if t == 0 then
        return amt;
    end

    return Sources.round(amt / t);
end

Sources.first = function(v1,v2)
    if (math.floor(v1) > 0) then
        return v1;
    end

    return v2;
end

Sources.check = function(v1,v2,v3)
    if (math.floor(v1) > 0) then
        return v2;
    end
    
    return v3;
end

Sources.iflte = function(v1, v2, v3, v4)
    if (v1 <= v2) then
        return v3;
    end
    
    return v4;
end

Sources.ifgte = function(v1, v2, v3, v4)
    if (v1 >= v2) then
        return v3;
    end
    
    return v4;
end

Sources.iflt = function(v1, v2, v3, v4)
    if (v1 < v2) then
        return v3;
    else
        return v4;
    end
end

Sources.ifgt = function(v1, v2, v3, v4)
    if (v1 > v2) then
        return v3;
    end
    
    return v4;
end

Sources.ifeq = function(v1, v2, v3, v4)
    if (v1 == v2) then
        return v3;
    end
    
    return v4;
end

Sources.ifneq = function(v1, v2, v3, v4)
    if (v1 ~= v2) then
        return v3;
    end
    
    return v4;
end

Sources.neq = function(v1,v2,v3,v4) 
    if (v1 ~= v2) then
        return v3 or true;
    end

    return v4 or false;
end

Sources.eq = function(v1,v2,v3,v4)
    if (v1 == v2) then
        return v3 or true;
    end

    return v4 or false;
end

Sources.startswith = function(v1, v2, v3, v4)
    if (strsub(v1, 1, #v2) == v2) then
        return v3 or true;
    end

    return v4 or false;
end

Sources.contains = function(v1, v2, v3, v4)
    if (strfind(v1, v2)) then
        return v3 or true;
    end

    return v4 or false;
end

Sources.bonus = function(v1,v2,v3,v4)
    if (not v1) then
        return v4 or false;
    end
    
    local s,e = strfind(v1, ":"..v2..":");
    if (not s) then
        s,e = strfind(v1, ":"..v2.."$");
    end

    if (s) then
        return v3 or true; 
    end

    return v4 or false;
end

-- This accepts an item id in tsm format, numeric, or an item link
function Sources:QueryID(q, itemId)
    if (not itemId) then
        return nil;
    end
    
    local codes = nil;

    local names = self:GetNamesAsString();
    if (not names or names:len() == 0 ) then
        return nil;
    end

    if (not q or q:len() == 0) then
        return nil;
    end

    if (OpValueCache[itemId]) then
        codes = OpValueCache[itemId];
    else 
        codes = OpCodes:New();
        OpValueCache[itemId] = codes;
        self:GetValues(itemId, codes);
    end

    codes.buyout = 0;
    codes.stacksize = 0;
    codes.quality = 99;
    codes.percent = 0;
    codes.ppu = 0;
    codes.ilevel = 0;
    codes.vendorsell = 0;
    codes.tsmId = Utils:GetTSMID(itemId);
    codes.vendorbuy = Config.Vendor()[codes.tsmId] or VendorData[codes.tsmId] or 0;

    local _, id = strsplit(":", codes.tsmId); 

    codes.id = tonumber(id);

    local _, fn, err = false, nil, nil;
    local oq = q;

    if (not OperationCache[q]) then
        q = Utils:ReplaceOpShortHand(q);
        q = Utils:ReplaceShortHandPercent(q);
        q = Utils:ReplaceMoneyShorthand(q);    
        q = Utils:ReplaceTabReturns(q);

        --print(q);

        if (not self:IsValidQuery(q)) then
            print("AnS Invalid Filter / Pricing String: "..q);
            return nil;
        end

        local pstr = string.format(ParseTemplate, self:GetVarsAsString(), self:GetCustomVarsAsString(), q);

        fn, err = loadstring(pstr);

        if(not fn or err) then
            print("AnS Filter / Pricing String Error: "..err);
            return nil;
        end

        _, fn = pcall(fn);

        if (not _ or not fn) then
            print("AnS Invalid Filter / Pricing String: "..q);
            return nil;
        end

        OperationCache[oq] = fn;
    else
        fn = OperationCache[oq];
    end

    if (not fn) then
        return nil;
    end

    r = fn(self, codes);
    return r;
end

function Sources:Query(q, item, groupId)
    local itemId = groupId or item.link or item.id;
    local buyout = item.buyoutPrice;
    local stackSize = item.count;
    local quality = item.quality;
    local ilvl = item.iLevel;
    local percent = item.percent;
    local ppu = item.ppu;

    if (not itemId) then
        return nil;
    end
    
    local codes = nil;

    local names = self:GetNamesAsString();
    if (not names or names:len() == 0 ) then
        return nil;
    end

    if (not q or q:len() == 0) then
        return nil;
    end

    if (OpValueCache[itemId]) then
        codes = OpValueCache[itemId];
    else 
        codes = OpCodes:New();
        OpValueCache[itemId] = codes;
        self:GetValues(itemId, codes);
    end


    codes.buyout = buyout;
    codes.stacksize = stackSize;
    codes.quality = quality;
    codes.percent = percent;
    codes.ppu = ppu;
    codes.ilevel = ilvl;
    codes.vendorsell = item.vendorsell;
    codes.tsmId = item.tsmId;
    codes.id = item.id;
    codes.vendorbuy = Config.Vendor()[item.tsmId] or VendorData[item.tsmId] or 0;

    local _, fn, err = false, nil, nil;
    local oq = q;

    if (not OperationCache[q]) then
        q = Utils:ReplaceOpShortHand(q);
        q = Utils:ReplaceShortHandPercent(q);
        q = Utils:ReplaceMoneyShorthand(q);    
        q = Utils:ReplaceTabReturns(q);

        --print(q);

        if (not self:IsValidQuery(q)) then
            print("AnS Invalid Filter / Pricing String: "..q);
            return nil;
        end

        local pstr = string.format(ParseTemplate, self:GetVarsAsString(), self:GetCustomVarsAsString(), q);

        fn, err = loadstring(pstr);

        if(not fn or err) then
            print("AnS Filter / Pricing String Error: "..err);
            return nil;
        end

        _, fn = pcall(fn);

        if (not _ or not fn) then
            print("AnS Invalid Filter / Pricing String: "..q);
            return nil;
        end

        OperationCache[oq] = fn;
    else
        fn = OperationCache[oq];
    end

    if (not fn) then
        return nil;
    end

    r = fn(self, codes);
    return r;
end