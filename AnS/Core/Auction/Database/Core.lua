local Ans = select(2, ...);
local Database = {};
Database.__index = Database;

Ans.Database = Database;