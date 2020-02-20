local Ans = select(2, ...);
local GroupsView = Ans.GroupsView;
local TextInput = Ans.UI.TextInput;
local ConfirmDialog = Ans.UI.ConfirmDialog;
local Dropdown = Ans.UI.Dropdown;
local TreeView = Ans.UI.TreeView;
local ListView = Ans.UI.ListView;
local Utils = Ans.Utils;

local retailDurations = {
    "12 Hours",
    "24 Hours",
    "48 Hours"
};

local classicDurations = {
    "8 Hours",
    "12 Hours",
    "24 Hours"
};

local AuctionView = {}
AuctionView.__index = AuctionView;
AuctionView.onEdit = nil;

Ans.AuctionOpView = AuctionView;

function AuctionView:OnLoad(f)
    local this = self;
    self.selected = nil;
    self.parent = f;
    self.frame = CreateFrame("Frame", "AnsAuctioningEditor", f, "AnsAuctionOpEditorTemplate");

    self.name = TextInput:NewFrom(self.frame.OpName);
    self.keepInBags = TextInput:NewFrom(self.frame.KeepInBags);

    self.maxToPost = TextInput:NewFrom(self.frame.MaxToPost);
    self.stackSize = TextInput:NewFrom(self.frame.StackSize);
    self.bidPercent = TextInput:NewFrom(self.frame.BidPercent);
    self.undercut = TextInput:NewFrom(self.frame.Undercut);

    self.minPrice = TextInput:NewFrom(self.frame.MinPrice);
    self.maxPrice = TextInput:NewFrom(self.frame.MaxPrice);
    self.normalPrice = TextInput:NewFrom(self.frame.NormalPrice);

    self.commodityLow = self.frame.CommodityLow;
    self.applyAll = self.frame.ApplyAll;

    self.commodityLow:SetScript("OnClick", function(f) this:ValuesChanged(); end);
    self.applyAll:SetScript("OnClick", function(f) this:ValuesChanged(); end);

    self.name.onTextChanged = function() this:ValuesChanged(); end;
    self.keepInBags.onTextChanged = function() this:ValuesChanged(); end;
    self.maxToPost.onTextChanged = function() this:ValuesChanged(); end;
    self.stackSize.onTextChanged = function() this:ValuesChanged(); end;
    self.bidPercent.onTextChanged = function() this:ValuesChanged(); end;
    self.undercut.onTextChanged = function() this:ValuesChanged(); end;

    self.minPrice.onTextChanged = function() this:ValuesChanged(); end;
    self.maxPrice.onTextChanged = function() this:ValuesChanged(); end;
    self.normalPrice.onTextChanged = function() this:ValuesChanged(); end;

    self:LoadDropdowns();
end

function AuctionView:Hide()
    self.selected = nil;
    if (self.frame) then
        self.frame:Hide();
    end
end

function AuctionView:Set(op)
    self.selected = op;

    self.name:Set(op.name);
    
    self.keepInBags:Set(op.keepInBags.."");
    self.maxToPost:Set(op.maxToPost.."");
    self.stackSize:Set(op.stackSize.."");
    
    self.bidPercent:Set(math.floor((op.bidPercent or 1) * 100).."");
    self.undercut:Set(op.undercut);
    
    self.minPrice:Set(op.minPrice);
    self.maxPrice:Set(op.maxPrice);
    self.normalPrice:Set(op.normalPrice);

    self.commodityLow:SetChecked(op.commodityLow);
    self.applyAll:SetChecked(op.applyAll);


    self.duration:SetSelected(op.duration);

    self.frame:Show();
end

function AuctionView:ValuesChanged()
    if (not self.selected) then
        return;
    end

    self.selected.name = self.name:Get() or "";
    self.selected.keepInBags = tonumber(self.keepInBags:Get()) or 0;
    
    self.selected.maxToPost = tonumber(self.maxToPost:Get()) or 0;
    self.selected.stackSize = tonumber(self.stackSize:Get()) or 0;

    self.selected.bidPercent = (tonumber(self.bidPercent:Get()) or 0) / 100;
    self.selected.undercut = self.undercut:Get();

    self.selected.minPrice = self.minPrice:Get();
    self.selected.maxPrice = self.maxPrice:Get();
    self.selected.normalPrice = self.normalPrice:Get();

    self.selected.commodityLow = self.commodityLow:GetChecked();
    self.selected.applyAll = self.applyAll:GetChecked();

    self.selected.duration = self.duration.selected;

    if (self.onEdit) then
        self.onEdit();
    end
end


function AuctionView:LoadDropdowns()
    local this = self;

    -- add min quality drop down
    self.duration = Dropdown:New("Duration", self.frame);
    self.duration:SetPoint("TOPLEFT", "TOPLEFT", 0, 32);
    self.duration:SetSize(125, 20);

    local items = retailDurations;

    if (Utils:IsClassic()) then
        items = classicDurations;
    end

    for i,v in ipairs(items) do
        self.duration:AddItem(v, function() this:ValuesChanged(); end);
    end
end