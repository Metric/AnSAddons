local Ans = select(2, ...);
local GroupsView = Ans.GroupsView;
local TextInput = Ans.UI.TextInput;
local ConfirmDialog = Ans.UI.ConfirmDialog;
local Dropdown = Ans.UI.Dropdown;
local TreeView = Ans.UI.TreeView;
local ListView = Ans.UI.ListView;
local Utils = Ans.Utils;

local rootGroup = {
    name = "Base",
    expanded = true,
    selected = false,
    children = {},
};

local operationTreeItems = { rootGroup };

local Operations = {};
Operations.__index = Operations;
Ans.OperationsView = Operations;

local SnipingOpView = Ans.SnipingOpView;