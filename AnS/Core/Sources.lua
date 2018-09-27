local Ans = select(2, ...);
local Sources = { items = {}};
Sources.__index = Sources;
Ans.Sources = Sources;

local Utils = Ans.Utils;
local PriceSource = Ans.PriceSource;

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
    return function(sources, ops)
        local ifgte, iflte, iflt, ifgt, ifeq, ifneq, check, avg, first, round,
            min, max, mod, 
            abs, ceil, floor, random, log, 
            log10, exp, sqrt = sources.ifgte, sources.iflte, sources.iflt, sources.ifgt, sources.ifeq, sources.ifneq, sources.check, sources.avg, sources.first, sources.round, math.min, math.max, math.fmod, math.abs, math.ceil, math.floor, math.random, math.log, math.log10, math.exp, math.sqrt;


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


function Sources:ClearCache()
    NameStringCache = "";
    SourceStringCache = "";
    CustomVarStringCache = "";
    wipe(OperationCache);
end

function Sources:LoadCustomVars()
    wipe(VarCodes);
    local i;
    for i = 1, #ANS_CUSTOM_VARS do
        local v = ANS_CUSTOM_VARS[i];
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
    local source = PriceSource:New(name,fn,key);
    tinsert(self.items, source);
end

function Sources:GetNamesAsString()
    local str = "";
    local sep = "";
    local i;

    if (NameStringCache:len() > 0) then
        return NameStringCache;
    end

    for i = 1, #self.items do
        local s = self.items[i];
        if (s.fn ~= nil) then
            str = str..sep..s.name:lower();
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

function Sources:GetVarsAsString()
    local str = "";
    local i;
    local total = #self.items;

    if (SourceStringCache:len() > 0) then
        return SourceStringCache;
    end

    for i = 1, total do
        local s = self.items[i];
        if (s.fn ~= nil) then
            local name = s.name:lower();
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
    local values = "";
    local sep = "";
    local i;
    local total = #self.items;

    for i = 1, total do
        local s = self.items[i];
        if (s.fn ~= nil) then
            local _, r = pcall(s.fn, itemId, s.key, s.name:lower());
            local v = r or 0;
            ops[s.name:lower()] = v;
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
    else
        return v3;
    end
end

Sources.iflte = function(v1, v2, v3, v4)
    if (v1 <= v2) then
        return v3;
    else
        return v4;
    end
end

Sources.ifgte = function(v1, v2, v3, v4)
    if (v1 >= v2) then
        return v3;
    else
        return v4;
    end
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
    else
        return v4;
    end
end

Sources.ifeq = function(v1, v2, v3, v4)
    if (v1 == v2) then
        return v3;
    else
        return v4;
    end
end

Sources.ifneq = function(v1, v2, v3, v4)
    if (v1 ~= v2) then
        return v3;
    else
        return v4;
    end
end

function Sources:Query(q, item)
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
        q = Utils:ReplaceOpShortHand(q);
        q = Utils:ReplaceShortHandPercent(q);
        q = Utils:ReplaceMoneyShorthand(q);    

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
    _, r = pcall(fn, self, OpCodes);

    if (not _) then
        print("AnS Invalid Filter / Pricing String: "..q);
        return nil;
    end

    return r;
end