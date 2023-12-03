local Ans = select(2, ...);
local Utils = Ans.Utils;

-- Classic Era --
local Classic = Ans.Data.Vendor.Classic;
local TBC = Ans.Data.Vendor.TBC;
local Wrath = Ans.Data.Vendor.Wrath;
local Cata = Ans.Data.Vendor.Cata;

-- Retail --
local Retail = Ans.Data.Vendor.Retail;
local Shadow = Ans.Data.Vendor.Shadow;
local Dragon = Ans.Data.Vendor.Dragon;

-- Pets --
local Pets = Ans.Data.Vendor.Pets;

local Vendor = {};

function Vendor.Get(id)

    -- check reverse order starting with pets first
    -- this way we get the latest based on expansion
    -- incase one of the newer expansions has a new price point
    if (Pets and Pets[id]) then
        return Pets[id];
    elseif (Dragon and Dragon[id]) then
        return Dragon[id];
    elseif (Shadow and Shadow[id]) then
        return Shadow[id];
    elseif (Retail and Retail[id]) then
        return Retail[id];
    elseif (Cata and Cata[id]) then
        return Cata[id];
    elseif (Wrath and Wrath[id]) then
        return Wrath[id];
    elseif (TBC and TBC[id]) then
        return TBC[id];
    elseif (Classic and Classic[id]) then
        return Classic[id];
    end

    return 0;
end

Ans.Data.Vendor = Vendor;