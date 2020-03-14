local Ans = select(2, ...);
local Utils = Ans.Utils;
local Importer = {};
Importer.__index = Importer;

Ans.Importer = Importer;

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
        else
            tmp = tmp..c;
        end
    end

    if (#tmp > 0) then
        group = self:ParseGroupItem(tmp, group, groups);
    end

    return groups;
end

function Importer:GetGroupByName(name, groups)
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
                group = self:GetGroupByName(subgroups[1], groups);

                if (not group) then
                    group = {id = Utils:Guid(), ids = "", name = subgroups[1], children = {}};
                    tinsert(groups, group);
                end

                for k = 2, #subgroups do
                    local sub = self:GetGroupByName(subgroups[k], group.children);
                    if (not sub) then
                        sub = {id = Utils:Guid(), ids = "", name = subgroups[k], children = {}};
                        tinsert(group.children, sub);
                    end
                    group = sub;
                end
            else
                group = self:GetGroupByName(id, groups);
                if (not group) then
                    group = {id = Utils:Guid(), ids = "", name = id, children = {}};
                    tinsert(groups, group);
                end
            end
        else
            if (not group) then
                local idx = #groups + 1;
                group = {id = Utils:Guid(), ids = "", name = "New Group "..idx, children = {}};
                tinsert(groups, group);
            end

            local comma = strsub(group.ids, #group.ids, #group.ids);
            local sep = ",";
            if (comma == sep or #group.ids == 0) then
                sep = "";
            end
            if (item) then
                if (not strfind(group.ids or "", item..",") and not strfind(group.ids or "", item.."$")) then
                    group.ids = group.ids..sep..item;
                end
            end
        end
    else
        if (not group) then
            local idx = #groups + 1;
            group = {id = Utils:Guid(), ids = "", name = "New Group "..idx, children = {}};
            tinsert(groups, group);
        end

        local comma = strsub(group.ids, #group.ids, #group.ids);
        local sep = ",";
        if (comma == sep or #group.ids == 0) then
            sep = "";
        end

        local tn = tonumber(_);
        if (tn) then
            local id = "i:"..tn;

            if (not strfind(group.ids or "", id..",") and not strfind(group.ids or "", id.."$")) then
                group.ids = group.ids..sep..id;
            end
        end
    end

    return group;
end