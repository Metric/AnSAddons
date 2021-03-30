local Ans = select(2, ...);
local Config = Ans.Config;
local Utils = Ans.Utils;
local TempTable = Ans.TempTable;
local Groups = Ans.Object.Register("Groups", Utils);

function Groups.ParseGroups(groups, result, noBase)
    local tempTbl = TempTable:Acquire();
    local queueTbl = TempTable:Acquire();
    local count = 0;

    for i,v in ipairs(groups) do
        tinsert(queueTbl, v);
    end

    while (#queueTbl > 0) do
        local g = tremove(queueTbl, 1);
        if (not tempTbl[g.id]) then
            tempTbl[g.id] = 1;
            count = count + Groups.ParseIds(g.ids, result, noBase);

            for i,v in ipairs(g.children) do
                if (not tempTbl[v.id]) then
                    tinsert(queueTbl, v);
                end
            end
        end
    end

    queueTbl:Release();
    tempTbl:Release();

    return count;
end

function Groups.ParseIds(ids, result, noBase)
    local tmp = "";
    local count = 0;
    for i = 1, #ids do
        local c = ids:sub(i,i);
        if (c == ",") then
            if (Groups.ParseItem(tmp, result, noBase)) then
                count = count + 1;
            end
            tmp = "";
        elseif (c == "\n" or c == "\r" or c == "\t") then
            -- ignore tabs, new lines and carriage returns
        else
            tmp = tmp..c;
        end
    end

    if (#tmp > 0) then
        if (Groups.ParseItem(tmp, result, noBase)) then
            count = count + 1;
        end
    end

    return count;
end

function Groups.ParseItem(item, result, noBase)
    local _, id = strsplit(":", item);
    if (id) then
        if (not noBase) then
            result[_..":"..id] = 1;
        end
        result[item] = 1;
        return true;
    else
        local tn = tonumber(_);
        if (tn) then
            result["i:"..tn] = 1;
            return true;
        end
    end

    return false;
end

function Groups.ContainsGroup(tbl, id)
    for i,v in ipairs(tbl) do
        if(v.id == id) then
            return true;
        end
    end

    return false;
end

function Groups.RestoreDefaultGroups()
    local groups = Config.Groups();
    local defaults = Ans.Data;

    local gtemp = TempTable:Acquire();
    local queueTbl = TempTable:Acquire();

    for i,v in ipairs(groups) do
        tinsert(queueTbl, v);
    end

    while (#queueTbl > 0) do
        local g = tremove(queueTbl, 1);
        gtemp[g.path] = g;
        if (#g.children > 0) then
            for i,v in ipairs(g.children) do
                tinsert(queueTbl, v);
            end
        end
    end

    for i,v in ipairs(defaults) do
        tinsert(queueTbl, v);
    end

    while (#queueTbl > 0) do
        local g = tremove(queueTbl, 1);
        if (gtemp[g.path]) then
            local group = gtemp[g.path];
            group.ids = g.ids;
        else
            local p = g.path;
            local found = false;
            while (p) do
                local idx = string.find(p, "%.[^%.]*$");
                if (idx > 1) then
                    p = strsub(g.path, 0, idx-1);
                    if (gtemp[p]) then
                        found = true;
                        tinsert(gtemp[p].children, 1, g);  
                        break;
                    end
                else
                    break;
                end
            end
            if (not found) then
                tinsert(groups, 1, g);
            end
        end
        if (#g.children > 0) then
            for i,v in ipairs(g.children) do
                tinsert(queueTbl, v);
            end
        end
    end

    gtemp:Release();
    queueTbl:Release();
end

function Groups.BuildGroupPaths(groups)
    local tempTbl = TempTable:Acquire();
    local queueTbl = TempTable:Acquire();

    for i,v in ipairs(groups) do
        v.path = v.name;
        tinsert(queueTbl, v);
    end

    while (#queueTbl > 0) do
        local g = tremove(queueTbl, 1);
        if (not tempTbl[g.id]) then
            tempTbl[g.id] = 1;
            for i,v in ipairs(g.children) do
                if (not tempTbl[v.id]) then
                    v.path = g.path.."."..v.name; 
                    tinsert(queueTbl, v);
                end
            end
        end
    end

    queueTbl:Release();
    tempTbl:Release();
end

function Groups.Flatten(groups, flattened)
    local tempTbl = TempTable:Acquire();

    wipe(flattened);

    for i, v in ipairs(groups) do
        tinsert(tempTbl, v);
        tinsert(flattened, v);
    end
    
    while (#tempTbl > 0) do
        local c = tremove(tempTbl, 1);
        for i,v in ipairs(c.children) do
            tinsert(tempTbl, v);
            tinsert(flattened, v);
        end
    end

    tempTbl:Release();
end

function Groups.GetGroupIdFromPath(flattened, path, results)
    for i, v in ipairs(flattened) do
        if (v.path == path) then
            tinsert(results, v.id);
        end
    end
end

function Groups.GetGroupFromId(id)
    local tempTbl = TempTable:Acquire();
    local queueTbl = TempTable:Acquire();

    for i,v in ipairs(Config.Groups()) do
        tinsert(queueTbl, v);
    end

    while (#queueTbl > 0) do
        local g = tremove(queueTbl, 1);
        if (not tempTbl[g.id]) then
            tempTbl[g.id] = 1;
            if (g.id == id) then
                queueTbl:Release();
                tempTbl:Release();
                return g;
            end

            for i,v in ipairs(g.children) do
                if (not tempTbl[v.id]) then
                    tinsert(queueTbl, v);
                end
            end
        end
    end

    queueTbl:Release();
    tempTbl:Release();
end