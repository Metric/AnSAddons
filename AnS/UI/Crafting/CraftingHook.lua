local Ans = select(2, ...);
local CraftingData = Ans.Data.Crafting;
local Utils = Ans.Utils;
local Config = Ans.Config;
local Sources = Ans.Sources;
local EventManager = Ans.EventManager;
local CraftingHook = {};
local CraftIDCache = {};
CraftingHook.__index = CraftingHook;

local TSFrame = nil;

function CraftingHook.MouseLeave(self)
    if self.SubSkillRankBar.currentRank and self.SubSkillRankBar.maxRank then
		self.SubSkillRankBar.Rank:SetFormattedText("%d/%d", self.SubSkillRankBar.currentRank, self.SubSkillRankBar.maxRank);
    end
end

function CraftingHook.SetUpHeader(self, textWidth, tradeSkillInfo)
    if self.SubSkillRankBar.currentRank and self.SubSkillRankBar.maxRank then
		self.SubSkillRankBar.Rank:SetFormattedText("%d/%d", self.SubSkillRankBar.currentRank, self.SubSkillRankBar.maxRank);
    end
    
    if (self.Profit) then
        self.Profit:SetText("");
    end

    self:SetSize(500, self:GetHeight());
end

function CraftingHook.SetUpRecipe(self, textWidth, tradeSkillInfo)
    local numReagents = C_TradeSkillUI.GetRecipeNumReagents(tradeSkillInfo.recipeID);

    local totalCost = 0;

    for i = 1, numReagents do
        local _, _, reagentCount = C_TradeSkillUI.GetRecipeReagentInfo(tradeSkillInfo.recipeID, i);
        local link = C_TradeSkillUI.GetRecipeReagentItemLink(tradeSkillInfo.recipeID, i);

        if (link and Config.Crafting().materialCost and Config.Crafting().materialCost:len() > 0) then
            totalCost = totalCost + ((Sources:QueryID(Config.Crafting().materialCost, link) or 0) * reagentCount);
        end
    end

    local finalItemLink = C_TradeSkillUI.GetRecipeItemLink(tradeSkillInfo.recipeID);

    if (not finalItemLink) then
        if (self.Profit) then
            self.Profit:SetText("");
        end
        return;
    end

    -- we do this to remove stupid bonus ids 
    -- that show up on the crafting items
    -- that are not really there on AH
    if (not CraftIDCache[finalItemLink]) then
        local _, id = strsplit(":", finalItemLink);
        id = tonumber(id);
        CraftIDCache[finalItemLink] = id;
    end

    finalItemLink = CraftIDCache[finalItemLink];

    -- check for special milling / enchanting lookup
    local craftSpecial, isEnchanting = CraftingData.Item(tradeSkillInfo.recipeID);
    finalItemLink = craftSpecial or finalItemLink;

    local numProduced = C_TradeSkillUI.GetRecipeNumItemsProduced(tradeSkillInfo.recipeID);

    -- set to 1 for enchants
    if (craftSpecial and isEnchanting) then
        numProduced = 1;
    -- set avg for milling results
    elseif (craftSpecial and not isEnchanting) then
        numProduced = 4; -- avg
    end

    local finalWorth = 0;
    
    if (Config.Crafting().craftValue and Config.Crafting().craftValue:len() > 0) then
        finalWorth = (Sources:QueryID(Config.Crafting().craftValue, finalItemLink) or 0) * numProduced;
    end
    
    local profit = finalWorth - totalCost;
    local prefix = "";
    local negative = false;

    if (profit < 0) then
        profit = math.abs(profit);
        prefix = "-";
        negative = true;
    end

    local txt = Utils:PriceToFormatted(prefix, profit, negative);

    if (not self.Profit) then
        self.Profit = self:CreateFontString("AnsProfit", "ARTWORK", "AnsGameFontNormalLight");
        self.Profit:ClearAllPoints();
        self.Profit:SetPoint("RIGHT", -64, 0);
    end

    self.Profit:SetText(txt);
    
    self:SetSize(500, self:GetHeight());
end

function CraftingHook.MakeDraggable()
    if (TSFrame and TSFrame:IsShown()) then
        TSFrame:SetMovable(true);
        TSFrame:RegisterForDrag("LeftButton");
        TSFrame:HookScript("OnDragStart", 
            function(self)
                self:StartMoving();
            end
        );
        TSFrame:HookScript("OnDragStop", 
            function(self)
                self:StopMovingOrSizing();
                CraftingHook.StoreWindowPosition(self);
            end
        );
        TSFrame:HookScript("OnShow", CraftingHook.RestoreWindowPosition);
    end
end

function CraftingHook.RestoreWindowPosition(self)
    if (not self) then
        return;
    end

    local pos = Config.Crafting().tradeWindowPosition;

    if (pos) then
        self:ClearAllPoints();
        self:SetPoint("BOTTOMLEFT", self:GetParent(), "BOTTOMLEFT", pos.x, pos.y);
    else
        self:ClearAllPoints();
        self:SetPoint("CENTER", self:GetParent(), "CENTER", 0, 0);
    end
end

function CraftingHook.StoreWindowPosition(self)
    local left, bottom, width, height = self:GetRect();
    Config.Crafting().tradeWindowPosition = {x = left, y = bottom};
end

function CraftingHook.HookRetail()
    CraftingHook.RestoreWindowPosition(TSFrame);
    CraftingHook.MakeDraggable();

    TSFrame:SetSize(870, TSFrame:GetHeight());
    TSFrame.RecipeList:SetSize(500, TSFrame.RecipeList:GetHeight());
    TSFrame.RecipeInset:SetSize(525, TSFrame.RecipeInset:GetHeight());

    for i,b in ipairs(TSFrame.RecipeList.buttons) do
        hooksecurefunc(b, "SetUpRecipe", CraftingHook.SetUpRecipe);
        hooksecurefunc(b, "SetUpHeader", CraftingHook.SetUpHeader);
        b:HookScript("OnLeave", CraftingHook.MouseLeave);
    end
end

function CraftingHook.SetProfit(self, id)
    local totalCost = 0;

    local numReagents = GetTradeSkillNumReagents(id);
    for i=1, numReagents do
        local reagentName, reagentTexture, reagentCount, playerReagentCount = GetTradeSkillReagentInfo(id, i);
        local link = GetTradeSkillReagentItemLink(id, i);

        if (link and Config.Crafting().materialCost and Config.Crafting().materialCost:len() > 0) then
            totalCost = totalCost + ((Sources:QueryID(Config.Crafting().materialCost, link) or 0) * reagentCount);
        end
    end

    local finalItemLink = GetTradeSkillItemLink(id);

    if (not finalItemLink) then
        if (self.Profit) then
            self.Profit:SetText("");
        end
        return;
    end

    -- we do this to remove stupid bonus ids 
    -- that show up on the crafting items
    -- that are not really there on AH
    if (not CraftIDCache[finalItemLink]) then
        local _, id = strsplit(":", finalItemLink);
        id = tonumber(id);
        CraftIDCache[finalItemLink] = id;
    end

    finalItemLink = CraftIDCache[finalItemLink];

    local min, numProduced = GetTradeSkillNumMade(id);

    local finalWorth = 0;
    
    if (Config.Crafting().craftValue and Config.Crafting().craftValue:len() > 0) then
        finalWorth = (Sources:QueryID(Config.Crafting().craftValue, finalItemLink) or 0) * numProduced;
    end
    
    local profit = finalWorth - totalCost;
    local prefix = "";
    local negative = false;

    if (profit < 0) then
        profit = math.abs(profit);
        prefix = "-";
        negative = true;
    end

    local txt = Utils:PriceToFormatted(prefix, profit, negative);

    if (not self.Profit) then
        self.Profit = self:CreateFontString("AnsProfit", "ARTWORK", "AnsGameFontNormalLight");
        self.Profit:ClearAllPoints();
        self.Profit:SetPoint("RIGHT", -5, 0);
    end

    self.Profit:SetText(txt);
end

function CraftingHook.SetID(self, id)
    local index = self:GetID();
    local skillName, skillType, numAvailable, isExpanded = GetTradeSkillInfo(index);

    if (skillType == "header") then
        if (self.Profit) then
            self.Profit:SetText("");
        end
    else
        CraftingHook.SetProfit(self, id);
    end
end

function CraftingHook.HookClassic()
    CraftingHook.RestoreWindowPosition(TSFrame);
    CraftingHook.MakeDraggable();

    local scrollFrame = _G["TradeSkillListScrollFrame"];

    for i = 1, 8 do
        local button = _G["TradeSkillSkill"..i];

        if (button) then
            hooksecurefunc(button, "SetID", CraftingHook.SetID);
        end
    end
end

local didHook = false;

EventManager:On("TRADE_SKILL_SHOW", 
    function()
        CraftingHook.TradeSkillShown = true;

        TSFrame = TradeSkillFrame;

        if (not didHook) then
            didHook = true;

            if (Utils:IsClassic()) then
                CraftingHook.HookClassic();
            else
                CraftingHook.HookRetail();
            end
        end
    end);

EventManager:On("TRADE_SKILL_CLOSE",
    function()
        CraftingHook.TradeSkillShown = false;
    end
);