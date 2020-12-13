local Ans = select(2, ...);
local Utils = Ans.Utils;
local Importer = Ans.Object.Register("Importer");

function Importer:ImportGroups(str, groups)
    local group = nil;
    local tmp = "";

    if (not groups) then
        groups = {};
    end

    for i = 1, #str do
        local c = str:sub(i,i);
        if (c == ",") then
            group = self:ParseGroupItem(tmp, group, groups);
            tmp = "";
        elseif (c == "\r" or c == "\n" or c == "\t") then
            -- ignore
        else
            tmp = tmp..c;
        end
    end

    if (#tmp > 0) then
        group = self:ParseGroupItem(tmp, group, groups);
    end

    return groups;
end

function Importer:Import(str, group)
    local tmp = "";
    if (self.ContainsSubGroups(str)) then
        return self:ImportGroups(str, group.children);
    end

    for i = 1, #str do
        local c = str:sub(i,i);
        if (c == ",") then
            self.ParseItem(nil, nil, tmp, group);
            tmp = "";
        elseif (c == "\r" or c == "\n" or c == "\t") then
            -- ignore
        else
            tmp = tmp..c;
        end
    end

    if (#tmp > 0) then
        self.ParseItem(nil, nil, tmp, group);
    end

    return group;
end

function Importer.ParseItem(_, id, item, group)
    if (not _ and not id) then
        _, id = strsplit(":", item);
    end

    local comma = strsub(group.ids, #group.ids, #group.ids);
    local sep = ",";
    if (comma == sep or #group.ids == 0) then
        sep = "";
    end

    if (not id) then
        local tn = tonumber(_);
        if (tn) then
            local id = "i:"..tn;

            if (not strfind(group.ids or "", id..",") and not strfind(group.ids or "", id.."$")) then
                group.ids = group.ids..sep..id;
            end
        end
    elseif (item) then
        if (not strfind(group.ids or "", item..",") and not strfind(group.ids or "", item.."$")) then
            group.ids = group.ids..sep..item;
        end
    end
end

function Importer.ContainsSubGroups(str)
    return strfind(str, "group:");
end

function Importer.GetGroupByName(name, groups)
    for i,v in ipairs(groups) do
        if (v.name == name) then
            return v;
        end
    end

    return nil;
end

function Importer:ParseGroupItem(item, group, groups)
    local _, id = strsplit(":", item);
    if (id ~= nil) then
        if (_ == "group") then
            local subgroups = { strsplit("`", id) };

            if (#subgroups > 0) then
                group = self.GetGroupByName(subgroups[1], groups);

                if (not group) then
                    group = {id = Utils.Guid(), ids = "", name = subgroups[1], children = {}};
                    tinsert(groups, group);
                end

                for k = 2, #subgroups do
                    local sub = self.GetGroupByName(subgroups[k], group.children);
                    if (not sub) then
                        sub = {id = Utils.Guid(), ids = "", name = subgroups[k], children = {}};
                        tinsert(group.children, sub);
                    end
                    group = sub;
                end
            else
                group = self.GetGroupByName(id, groups);
                if (not group) then
                    group = {id = Utils.Guid(), ids = "", name = id, children = {}};
                    tinsert(groups, group);
                end
            end
        else
            if (not group) then
                local idx = #groups + 1;
                group = {id = Utils.Guid(), ids = "", name = "New Group "..idx, children = {}};
                tinsert(groups, group);
            end

            self.ParseItem(_, id, item, group);
        end
    else
        if (not group) then
            local idx = #groups + 1;
            group = {id = Utils.Guid(), ids = "", name = "New Group "..idx, children = {}};
            tinsert(groups, group);
        end

        self.ParseItem(_, id, item, group);
    end

    return group;
end