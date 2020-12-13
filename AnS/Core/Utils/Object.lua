local Ans = select(2, ...);
local Object = {};
Ans.Object = Object;

function Object.Register(name, base)
    if (not base) then
        base = Ans;
    end

    local b = {};
    b.__index = b;
    b.New = function(self, o) local c = o or {}; setmetatable(c, self); self.__index = self; return c; end;
    base[name] = b;
    return b;
end