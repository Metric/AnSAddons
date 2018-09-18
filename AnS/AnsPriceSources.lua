AnsPriceSources = { sources = {}};
AnsPriceSources.__index = AnsPriceSources;

local AnsPriceSource = {};
AnsPriceSource.__index = AnsPriceSource;

local NameStringCache = "";
local SourceStringCache = "";
local CustomVarStringCache = "";

local OpCodes = {
    percent = 0,
    ppu = 0,
    stacksize = 0,
    buyout = 0,
    ilevel = 0,
    vendorsell = 0,
    quality = 1,
    dbmarket = 0,
    dbminbuyout = 0, 
    dbhistorical = 0, 
    dbregionmarketavg = 0, 
    dbregionminbuyoutavg = 0, 
    dbregionhistorical = 0, 
    dbregionsaleavg = 0, 
    dbregionsalerate = 0, 
    dbregionsoldperday = 0,
    dbglobalminbuyoutavg = 0,
    dbglobalmarketavg = 0,
    dbglobalhistorical = 0,
    dbglobalsaleavg = 0,
    dbglobalsalerate = 0,
    dbglobalsoldperday = 0,
    tujmarket = 0, 
    tujrecent = 0, 
    tujglobalmedian = 0, 
    tujglobalmean = 0, 
    tujage = 0, 
    tujdays = 0, 
    tujstddev = 0, 
    tujglobalstddev = 0,
    atrvalue = 0
};

local VarCodes = {};

local OperationCache = {};

local ParseSourceTemplate = "local %s = ops.%s or 0; ";
local ParseVarsTemplate = "local %s = %s or 0; ";

local ParseTemplate = [[
    return function(ops)
        local ifgte, iflte, iflt, ifgt, ifeq, ifneq, check, avg, first, round,
            min, max, mod, 
            abs, ceil, floor, random, log, 
            log10, exp, sqrt = AnsPriceSources.ifgte, AnsPriceSources.iflte, AnsPriceSources.iflt, AnsPriceSources.ifgt, AnsPriceSources.ifeq, AnsPriceSources.ifneq, AnsPriceSources.check, AnsPriceSources.avg, AnsPriceSources.first, AnsPriceSources.round, math.min, math.max, math.fmod, math.abs, math.ceil, math.floor, math.random, math.log, math.log10, math.exp, math.sqrt;


        local percent = ops.percent;
        local ppu = ops.ppu;
        local stacksize = ops.stacksize;
        local buyout = ops.buyout;
        local ilevel = ops.ilevel;
        local quality = ops.quality;
        local vendorsell = ops.vendorsell;

        %s

        %s

        return %s;
    end
]];

function AnsPriceSource:New(name,fn,key)
    local s = {};
    setmetatable(s, AnsPriceSource);
    s.name = name;
    s.fn = fn;
    s.key = key;
    return s;
end

function AnsPriceSources:ClearCache()
    NameStringCache = "";
    SourceStringCache = "";
    CustomVarStringCache = "";
    wipe(OperationCache);
end

function AnsPriceSources:LoadCustomVars()
    wipe(VarCodes);
    local i;
    for i = 1, #ANS_CUSTOM_VARS do
        local v = ANS_CUSTOM_VARS[i];
        local value = v.value;

        if (value and value:len() > 0) then
            value = AnsUtils:ReplaceOpShortHand(value);
            value = AnsUtils:ReplaceShortHandPercent(value);
            value = AnsUtils:ReplaceMoneyShorthand(value); 

            tinsert(VarCodes, {name = v.name, value = value});
        end
    end
end

function AnsPriceSources:Register(name, fn, key)
    local source = AnsPriceSource:New(name,fn,key);
    local index = #self.sources + 1;
    self.sources[index] = source;
end

function AnsPriceSources:GetNamesAsString()
    local str = "";
    local sep = "";
    local i;

    if (NameStringCache:len() > 0) then
        return NameStringCache;
    end

    for i = 1, #self.sources do
        local s = self.sources[i];
        if (s.fn ~= nil) then
            str = str..sep..s.name:lower();
            sep = ",";
        end
    end

    -- cache for future lookups
    NameStringCache = str;

    return str;
end

function AnsPriceSources:GetCustomVarsAsString()
    local str = "";
    local i;
    local total = #VarCodes;

    if (CustomVarStringCache:len() > 0) then
        return CustomVarStringCache;
    end

    for i = 1, total do
        local cvar = VarCodes[i];

        local nstr = string.format(ParseVarsTemplate, cvar.name, cvar.value);
        str = str..nstr;
    end

    CustomVarStringCache = str;

    return str;
end

function AnsPriceSources:GetVarsAsString()
    local str = "";
    local i;
    local total = #self.sources;

    if (SourceStringCache:len() > 0) then
        return SourceStringCache;
    end

    for i = 1, total do
        local s = self.sources[i];
        if (s.fn ~= nil) then
            local name = s.name:lower();
            local nstr = string.format(ParseSourceTemplate, name, name);
            str = str..nstr;
        end
    end

    SourceStringCache = str;

    return str;
end

function AnsPriceSources:IsValidQuery(q)
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

function AnsPriceSources:GetValues(itemId, ops)
    local values = "";
    local sep = "";
    local i;
    local total = #self.sources;

    for i = 1, total do
        local s = self.sources[i];
        if (s.fn ~= nil) then
            local _, r = pcall(s.fn, itemId, s.key, s.name:lower());
            local v = r or 0;
            ops[s.name:lower()] = v;
        end
    end
end

AnsPriceSources.round = function(n)
    if (n < 0) then
        return math.floor(n - 0.5);
    end
    
    return math.floor(n + 0.5);
end

AnsPriceSources.avg = function(...)
    local table = { ... };
    local t = 0;
    local amt = 0;
    for i, v in ipairs(table) do
        amt = amt + v;
        t = t + 1;
    end

    if t == 0 then
        return amt;
    end

    return AnsPriceSources.round(amt / t);
end

AnsPriceSources.first = function(v1,v2)
    if (math.floor(v1) > 0) then
        return v1;
    end

    return v2;
end

AnsPriceSources.check = function(v1,v2,v3)
    if (math.floor(v1) > 0) then
        return v2;
    else
        return v3;
    end
end

AnsPriceSources.iflte = function(v1, v2, v3, v4)
    if (v1 <= v2) then
        return v3;
    else
        return v4;
    end
end

AnsPriceSources.ifgte = function(v1, v2, v3, v4)
    if (v1 >= v2) then
        return v3;
    else
        return v4;
    end
end

AnsPriceSources.iflt = function(v1, v2, v3, v4)
    if (v1 < v2) then
        return v3;
    else
        return v4;
    end
end

AnsPriceSources.ifgt = function(v1, v2, v3, v4)
    if (v1 > v2) then
        return v3;
    else
        return v4;
    end
end

AnsPriceSources.ifeq = function(v1, v2, v3, v4)
    if (v1 == v2) then
        return v3;
    else
        return v4;
    end
end

AnsPriceSources.ifneq = function(v1, v2, v3, v4)
    if (v1 ~= v2) then
        return v3;
    else
        return v4;
    end
end

function AnsPriceSources:Query(q, item)
    local values = "";

    local itemId = item.link;
    local buyout = item.buyoutPrice;
    local stackSize = item.count;
    local quality = item.quality;
    local ilvl = item.iLevel;
    local percent = item.percent;
    local ppu = item.ppu;

    OpCodes.buyout = buyout;
    OpCodes.stacksize = stackSize;
    OpCodes.quality = quality;
    OpCodes.percent = percent;
    OpCodes.ppu = ppu;
    OpCodes.ilevel = ilvl;
    OpCodes.vendorsell = item.vendorsell;

    local names = self:GetNamesAsString();
    if (not names or names:len() == 0 ) then
        return nil;
    end

    if (not q or q:len() == 0) then
        return nil;
    end

    self:GetValues(itemId, OpCodes);

    local _, fn = false, nil;
    local oq = q;

    if (not OperationCache[q]) then
        q = AnsUtils:ReplaceOpShortHand(q);
        q = AnsUtils:ReplaceShortHandPercent(q);
        q = AnsUtils:ReplaceMoneyShorthand(q);    

        --print(q);

        if (not self:IsValidQuery(q)) then
            print("AnS Invalid Filter / Pricing String: "..q);
            return nil;
        end

        local pstr = string.format(ParseTemplate, self:GetVarsAsString(), self:GetCustomVarsAsString(), q);

        fn, error = loadstring(pstr);

        if(not fn and error) then
            print("AnS Filter / Pricing String Error: "..error);
            return nil;
        end

        _, fn = pcall(fn);

        if (not _) then
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

    local r = nil;
    _, r = pcall(fn, OpCodes);

    if (not _) then
        print("AnS Invalid Filter / Pricing String: "..q);
        return nil;
    end

    return r;
end
