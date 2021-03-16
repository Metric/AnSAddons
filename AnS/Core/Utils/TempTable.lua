local Ans = select(2, ...);
local TempTable = Ans.Object.Register("TempTable");
local tbls = {};

function TempTable.Reset()
    wipe(tbls);
end

function TempTable:Acquire(...)
    local t = nil;
    
    -- free up memory
    if (#tbls > 800) then
        wipe(tbls);
    end

    if (#tbls == 0) then
        t = TempTable:New({});
    else
        t = tremove(tbls, 1);
        wipe(t);
        t = TempTable:New(t);
    end

    local total = select("#", ...);
    for i = 1, total do
        local v = select(i, ...);
        tinsert(t, v);
    end
    return t;
end

function TempTable:Release()
    wipe(self); 
    tinsert(tbls, self);
end

function TempTable:UnpackAndRelease()
    tinsert(tbls, self);
    return unpack(self);
end