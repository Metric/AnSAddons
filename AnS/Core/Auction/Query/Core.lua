local Ans = select(2, ...);
local Logger = Ans.Logger;
local Config = Ans.Config;
local Sources = Ans.Sources;
local Query = Ans.Object.Register("Query", Ans.Auctions);

Query.DEFAULT_ITEM_SORT = {
    { sortOrder = 4, reverseSort = false },
    { sortOrder = 3, reverseSort = false }
};

Query.TASKER_TAG = "QUERY";

Query.module = nil;
Query.ops = {};
Query.activeQueries = {};

local blacklist = {};

local function Truncate(str)
    if(str:len() <= 62) then
        return str;
    end

    return str:sub(1, 62);
end

local function ItemHash(item)
    if (not item) then
        return nil;
    end

    if (item.auctionId) then
        return tostring(item.auctionId);
    end

    return item.ppu.."."..item.count.."."..item.tsmId.."."..item.iLevel;
end

local function ItemKeyHash(itemKey)
    if (not itemKey) then
        return nil;
    end

    -- note: removing this temporarily and replacing with the bolow
    -- I believe this was causing an issue with caching the wrong data in some cases
    -- due to not including the itemKey.itemSuffix properly in it
    -- return ""..itemKey.itemID..itemKey.itemLevel..itemKey.battlePetSpeciesID;
    return itemKey.itemID.."."..itemKey.itemLevel.."."..itemKey.itemSuffix.."."..itemKey.battlePetSpeciesID;
end

local function GetOwners(result)
    if (#result.owners == 0) then
        return "";
    elseif (#result.owners == 1) then
        return result.owners[1];
    else
        return result.owners;
    end
end

Query.Truncate = Truncate;
Query.ItemHash = ItemHash;
Query.ItemKeyHash = ItemKeyHash;
Query.GetOwners = GetOwners;

function Query:Acquire(ilevel, buyout, quality, maxPercent)
    local mod = Query.module;
    if (not mod) then
        Logger.Log("QUERY", "No Query Module Available for WoW Client Version");
        return nil;
    end

    local q = mod:Acquire(ilevel, buyout, quality, maxPercent);
    local queries = self.activeQueries;
    tinsert(queries, q);
    return q;
end

function Query:Release(q)
    local queries = self.activeQueries;
    for i,v in ipairs(queries) do
        if (v == q) then
            tremove(queries, i);
            return;
        end
    end
end

function Query:IsActive(from)
    local queries = self.activeQueries;
    
    for i,v in ipairs(queries) do
        if (v and v ~= from 
            and v:IsActive()) then
                return true;
        end
    end

    return false;
end

function Query.TempBlacklist(auction)
    if (not auction) then
        return;
    end

    blacklist[ItemHash(auction)] = true;
end

function Query.IsTempBlacklisted(auction)
    if (not auction) then
        return false;
    end

    return blacklist[ItemHash(auction)] == true;
end

function Query.ClearTempBlacklist()
    wipe(blacklist);
end

function Query:AssignDefaults(ops)
    wipe(self.ops);

    for i,v in ipairs(ops) do
        tinsert(self.ops, v);
    end
end

function Query.IsValid(auction, ignorePercent, ilevel, buyout, percent)
    if (auction.iLevel < ilevel and ilevel > 0) then
        return false;
    end
    
    if (auction.ppu > buyout and buyout > 0) then
        return false;
    end
    
    if (auction.percent > percent and percent > 0 and not ignorePercent) then
        return false;
    end

    return true;
end

function Query.IsBlacklisted(auction)
    local isBlacklisted = Query.IsTempBlacklisted(auction);

    if (isBlacklisted) then
        return true;
    end

    local blklist = Config.Sniper().characterBlacklist;

    -- ensure the blacklist is in table
    -- format, if not make it table and cache it
    -- this won't hurt anything since
    -- the config already handles if it is in a table
    -- and will fill in the edit box appropriately
    if (type(blacklist) == "string") then
        blacklist = {};
        Config.Sniper().characterBlacklist = blacklist;
    end

    if (auction.owner and #blklist > 0) then
        if (type(auction.owner) ~= "table") then
            if (auction.owner ~= "" and auction.owner:len() > 0) then
                isBlacklisted = Utils.InTable(blklist, auction.owner:lower());
            end
        else
            for i,v in ipairs(auction.owner) do
                if (v ~= "" and v:len() > 0) then
                    local contains = Utils.InTable(blklist, v:lower());
                    if (contains) then
                        isBlacklisted = true;
                        break;
                    end
                end
            end
        end
    end

    return isBlacklisted;
end


function Query.FillAverage(auction, isgroup)
    local avg = Sources:Query(Config.Sniper().source, auction, isgroup);
    if (not avg or avg <= 0) then
        avg = auction.vendorsell or 1;
    end
    auction.avg = avg;
    auction.percent = math.floor(auction.ppu / avg * 100);
end

function Query.FilterDefault(auction, ignorePercent, isgroup, fn)
    local allowed = Sources:Query(Config.Sniper().pricing, auction, isgroup);

    if (type(allowed) == "boolean" or type(allowed) == "number") then
        if (type(allowed) == "number") then
            if (auction.ppu <= allowed and fn(auction, ignorePercent)) then
                return true;
            end
        else
            if (allowed and fn(auction, ignorePercent)) then
                return true;
            end
        end
    else
        return fn(auction, ignorePercent);
    end

    return false;
end

function Query.FilterOps(auction, ops, exact, isgroup)
    local k;
    local tf = #ops;
    local valid = false;

    for k = 1, tf do
        local op = ops[k];
        if (op:IsValid(auction, exact, isgroup)) then
            valid = true;
            break;
        end
    end

    return valid;
end