AnsPriceSources = { sources = {}};
AnsPriceSources.__index = AnsPriceSources;

local AnsPriceSource = {};
AnsPriceSource.__index = AnsPriceSource;

local ValuesCaches = {};
local NameStringCache = "";

function AnsPriceSource:New(name,fn,key)
    local s = {};
    setmetatable(s, AnsPriceSource);
    s.name = name;
    s.fn = fn;
    s.key = key;
    return s;
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
        str = str..sep..s.name:lower();
        sep = ",";
    end

    -- cache for future lookups
    NameStringCache = str;

    return str;
end

function AnsPriceSources:GetValues(itemId)
    local values = "";
    local sep = "";
    local i;
    local total = #self.sources;

    for i = 1, total do
        local s = self.sources[i];
        local _, r = pcall(s.fn, itemId, s.key);
        local v = r or 0;
        values = values..sep..v;
        sep = ",";
    end

    -- cache values for faster lookup for the next time
    -- as the pricing data will not change
    -- unless you reload ui / logout or login
    ValuesCaches[itemId] = values;

    return values;
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
    if (v1 > 0) then
        return v1;
    end

    return v2;
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

    local names = self:GetNamesAsString();

    if (not names or names:len() == 0 ) then
        return nil;
    end

    if (not q or q:len() == 0) then
        return nil;
    end

    if (not ValuesCaches[itemId]) then
        values = self:GetValues(itemId);
    else
        values = ValuesCaches[itemId];
    end

    if (not values or values:len() == 0) then
        return nil;
    end

    local qstr = "local percent,ilevel,quality,stacksize,buyout,ppu = "..percent..","..ilvl..","..quality..","..stackSize..","..buyout..","..ppu..";";
          qstr = qstr.."local avg,first,min,max,mod,abs,ceil,floor,round,random,log,log10,exp,sqrt = AnsPriceSources.avg,AnsPriceSources.first,math.min,math.max,math.mod,math.abs,math.ceil,math.floor,AnsPriceSources.round,math.random,math.log,math.log10,math.exp,math.sqrt;";
          qstr = qstr.."local "..names.." = "..values.."; return "..q..";";
    local r = loadstring(qstr)();
    return r;
end
