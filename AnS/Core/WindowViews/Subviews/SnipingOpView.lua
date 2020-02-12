local Ans = select(2, ...);
local GroupsView = Ans.GroupsView;
local TextInput = Ans.UI.TextInput;
local ConfirmDialog = Ans.UI.ConfirmDialog;
local Dropdown = Ans.UI.Dropdown;
local TreeView = Ans.UI.TreeView;
local ListView = Ans.UI.ListView;
local Utils = Ans.Utils;
local BaseData = Ans.BaseData;

local AnsQualityToText = {};
AnsQualityToText[1] = "Common";
AnsQualityToText[2] = "Uncommon";
AnsQualityToText[3] = "Rare";
AnsQualityToText[4] = "Epic";
AnsQualityToText[5] = "Legendary";

local SnipingView = {}
SnipingView.__index = SnipingView;
SnipingView.onDelete = nil;
SnipingView.onEdit = nil;

Ans.SnipingOpView = SnipingView;

function SnipingView:OnLoad(f)
    local this = self;
    self.selected = nil;
    self.parent = f;
    self.frame = CreateFrame("Frame", "AnsSnipingEditor", f, "AnsSnipeOpEditorTemplate");

    self.name = TextInput:NewFrom(self.frame.OpName);
    self.price = TextInput:NewFrom(self.frame.Price.Text);
    self.price:EnableMultiLine();

    self.maxPercent = TextInput:NewFrom(self.frame.MaxPercent);
    self.minILevel = TextInput:NewFrom(self.frame.MinLevel);
    self.maxPPU = TextInput:NewFrom(self.frame.MaxPPU);
    self.search = TextInput:NewFrom(self.frame.Search);

    self.exactMatch = self.frame.ExactMatch;
    self.exactMatch:SetScript("OnClick", function(f) this:ValuesChanged(); end);

    self.name.onTextChanged = function() this:ValuesChanged(); end;
    self.maxPercent.onTextChanged = function() this:ValuesChanged(); end;
    self.price.onTextChanged = function() this:ValuesChanged(); end;
    self.minILevel.onTextChanged = function() this:ValuesChanged(); end;
    self.maxPPU.onTextChanged = function() this:ValuesChanged(); end;
    self.search.onTextChanged = function() this:ValuesChanged(); end;

    self.classIDSelected = 0;
    self.subClassIDSelected = 0;
    self.inventoryTypeSelected = 0;

    self.removeGroup = self.frame.RemoveGroup;
    self.confirmDelete = self.frame.ConfirmDelete;

    if(self.removeGroup) then
        self.removeGroup:SetScript("OnClick", 
            function()
                if (not this.selected) then
                    return;
                end
                ConfirmDialog:Show(this.confirmDelete, "Delete Operation: "..this.selected.name.."?", "DELETE",
                    function(data)
                        this:Delete(data);
                    end,
                    this.selected
                );
            end 
        );
    end

    self:LoadDropdowns();
end

function SnipingView:Delete(data)
    if (not data) then
        return;
    end

    local tbl = ANS_OPERATIONS.Sniping;
    for i,v in ipairs(tbl) do
        if (v.id == data.id) then
            tremove(tbl, i);
            if (self.onDelete) then
                self.onDelete();
            end
            return;
        end
    end
end

function SnipingView:Hide()
    self.selected = nil;
    if (self.frame) then
        self.frame:Hide();
    end
end

function SnipingView:Set(snipeOp)
    self.selected = snipeOp;

    self.name:Set(snipeOp.name);
    self.price:Set(snipeOp.price);
    self.maxPercent:Set(snipeOp.maxPercent.."");
    self.minILevel:Set(snipeOp.minILevel.."");
    self.maxPPU:Set(Utils:PriceToString(snipeOp.maxPPU, true, true));
    self.search:Set(snipeOp.search);
    self.exactMatch:SetChecked(snipeOp.exactMatch);
    self.minQualityDropdown:SetSelected(snipeOp.minQuality + 1);

    self.frame:Show();
end

function SnipingView:ValuesChanged()
    if (not self.selected) then
        return;
    end

    self.selected.name = self.name:Get() or "";
    self.selected.price = self.price:Get() or "";
    
    self.selected.maxPercent = tonumber(self.maxPercent:Get()) or 0;
    self.selected.minILevel = tonumber(self.minILevel:Get()) or 0;

    local txt, ppu = Utils:MoneyStringToCopper(self.maxPPU:Get());

    if (not ppu) then
        ppu = 0;
    end

    self.selected.maxPPU = ppu;

    self.selected.search = self.search:Get();
    self.selected.exactMatch = self.exactMatch:GetChecked();

    self.selected.minQuality = self.minQualityDropdown.selected - 1;

    if (self.onEdit) then
        self.onEdit();
    end
end


function SnipingView:LoadDropdowns()
    local this = self;

    -- add min quality drop down
    self.minQualityDropdown = Dropdown:New("MinQuality", self.frame);
    self.minQualityDropdown:SetPoint("TOPLEFT", "TOPLEFT", 110, -224);
    self.minQualityDropdown:SetSize(125, 20);
    self.minQualityDropdown:AddItem("No Min Quality", function() this:ValuesChanged(); end);

    for i,v in ipairs(AnsQualityToText) do
        self.minQualityDropdown:AddItem(v, function() this:ValuesChanged(); end);
    end
end