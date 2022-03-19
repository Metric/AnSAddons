local Ans = select(2, ...);
local Utils = Ans.Utils;
local Importer = Ans.Object.Register("Importer");

local GROUP_SEP = "`";
local ITEM_SEP = ",";
local LibDeflate = LibStub("LibDeflate")
local LibSerialize = LibStub("LibSerialize")


function Importer:TryImportTSMGroups(str, groups, group)
    str = LibDeflate:DecodeForPrint(str)
    if (not str) then
        return false, nil;
    end
    local extraBytes = nil;
    str, extraBytes = LibDeflate:DecompressDeflate(str)
    if (not str) then
        return false, nil;
    elseif (extraBytes and extraBytes > 0) then
        return false, nil;
    end

    local success, magic, version, groupName, items = LibSerialize:Deserialize(str);
    if (not success) then
        return false, nil;
    elseif (type(groupName) ~= "string" or groupName == "") then
        return false, nil;
    elseif (type(items) ~= "table") then
        return false, nil;
    end

    if (not groups) then
        groups = {};
    end

    if (not group) then
        group = Importer.GetGroupByName(groupName, groups);
    end

    local idsByPath = {};
    local pathCount = 0;

    for itemString, subGroupPath in pairs(items) do
        local gPath = groupName;

        if (subGroupPath and subGroupPath ~= "") then
            gPath = subGroupPath
        end

        local ids = idsByPath[gPath] or "";
        if (ids == "") then
            pathCount = pathCount + 1;
            ids = itemString;
        else
            ids = ids..ITEM_SEP..itemString;
        end
        idsByPath[gPath] = ids;
    end

    if (not group or group.name ~= groupName) then
        group = {id = Utils.Guid(), ids = idsByPath[groupName], name = groupName, children = {}};
        tinsert(groups, group);
    else
        -- else parse and add to it
        Importer.ParseItems(idsByPath[groupName], group);
    end

    -- quick termination here
    -- as if we only ever have <= 1 path count
    -- then we have already taken care of the group
    -- which was the primary group exported via groupName
    if (pathCount <= 1) then
        return true, groups;
    end

    local subgroups = group.children;

    for gPath, ids in pairs(idsByPath) do
        -- skip if just base group name
        -- as we have already taken care of this one
        if (gPath ~= groupName) then
            local subs = { strsplit(GROUP_SEP, gPath) };
            local sgroups = subgroups;
            local tail = nil;
            for i = 1, #subs do
                local name = subs[i];
                local sub = Importer.GetGroupByName(name, sgroups);
                if (not sub) then
                    sub = {id = Utils.Guid(), ids = "", name = name, children = {}};
                    tinsert(sgroups, sub);
                end
                sgroups = sub.children;
                tail = sub;
            end
            if (tail) then
                Importer.ParseItems(ids, tail);
            end
        end
    end

    return true, groups;
end

function Importer:ImportGroups(str, groups)
    local tsmSuccess, groups = Importer:TryImportTSMGroups(str, groups, nil);
    if (tsmSuccess or groups) then
        return groups;
    end

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
    local tsmSuccess, groups = Importer:TryImportTSMGroups(str, group.children, group);
    if (tsmSuccess or groups) then
        return group;
    end

    local rootGroup = group;
    local tmp = "";
    for i = 1, #str do
        local c = str:sub(i,i);
        if (c == ",") then
            group = self.ParseGroupItem(tmp, group, rootGroup.children, group == rootGroup);
            tmp = "";
        elseif (c == "\r" or c == "\n" or c == "\t") then
            -- ignore
        else
            tmp = tmp..c;
        end
    end

    if (#tmp > 0) then
        group = self.ParseGroupItem(tmp, group, rootGroup.children, group == rootGroup);
    end

    return group;
end

function Importer.ParseItems(str, group)
    local tmp = "";
    for i = 1, #str do
        local c = str:sub(i,i);
        if (c == ITEM_SEP) then
            Importer.ParseItemString(tmp, group);
            tmp = "";
        elseif (c == "\r" or c == "\n" or c == "\t") then
            -- ignore
        else
            tmp = tmp..c;
        end
    end
end

function Importer.ParseItemString(item, group)
    local _, id = strsplit(":", item);
    Importer.ParseItem(_, id, item, group);
end

function Importer.ParseItem(_, id, item, group)
    if (not _ and not id) then
        _, id = strsplit(":", item);
    end

    local comma = strsub(group.ids, #group.ids, #group.ids);
    local sep = ITEM_SEP;
    if (comma == sep or #group.ids == 0) then
        sep = "";
    end

    if (not id) then
        local tn = tonumber(_);
        if (tn) then
            local id = "i:"..tn;

            if (not strfind(group.ids or "", id..ITEM_SEP) and not strfind(group.ids or "", id.."$")) then
                group.ids = group.ids..sep..id;
            end
        end
    elseif (item) then
        if (not strfind(group.ids or "", item..ITEM_SEP) and not strfind(group.ids or "", item.."$")) then
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

function Importer:ParseGroupItem(item, group, groups, validateParent)
    local _, id = strsplit(":", item);
    if (id ~= nil) then
        if (_ == "group") then
            local subgroups = { strsplit(GROUP_SEP, id) };

            if (#subgroups > 0) then
                if (validateParent) then
                    if (not group or subgroups[1] ~= group.name) then
                        group = self.GetGroupByName(subgroups[1], groups);
                    end
                else
                    group = self.GetGroupByName(subgroups[1], groups);
                end

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