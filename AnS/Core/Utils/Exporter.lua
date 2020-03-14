local Ans = select(2, ...);
local Exporter = {};
Exporter.__index = Exporter;

Ans.Exporter = Exporter;

function Exporter:ExportGroups(groups)
    local str = "";
    local sep = "";

    for i,v in ipairs(groups) do
        str = str..sep..self:GetGroup(v);

        sep = ",";
        if (strsub(str, #str, #str) == ",") then
            sep = "";
        end
    end

    if (strsub(str, #str, #str) == ",") then
        return strsub(str, 1, #str - 1);
    end

    return str;
end

function Exporter:GetGroup(group, path)
    local str = "";

    if (not path) then
        path = group.name;
    else
        path = path.."`"..group.name;
    end

    str = "group:"..path..","..group.ids;

    local sep = ",";
    if (strsub(str, #str, #str) == ",") then
        sep = "";
    end

    for i,v in ipairs(group.children) do
        str = str..sep..self:GetGroup(v, path);

        sep = ",";
        if (strsub(str, #str, #str) == ",") then
            sep = "";
        end
    end

    return str;
end