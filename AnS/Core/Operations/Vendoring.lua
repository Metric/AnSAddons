local Ans = select(2, ...);
local Vendoring = {};
Vendoring.__index = Vendoring;
Ans.Operations.Vendoring = Vendoring;