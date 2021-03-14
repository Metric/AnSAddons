local Ans = select(2, ...);
local CraftingData = Ans.Data.Crafting;
local Utils = Ans.Utils;
local Draggable = Utils.Draggable;
local Config = Ans.Config;
local Sources = Ans.Sources;
local Tasker = Ans.Tasker;
local EventManager = Ans.EventManager;
local CraftingHook = {};
local CraftIDCache = {};
local Logger = Ans.Logger;
local TASKER_TAG = "CRAFTING";
CraftingHook.__index = CraftingHook;

local ENCHANTING_VELLUM_ID = "i:38682";

local TSFrame = nil;

local CRAFT_REFERENCE = {};
local STORED_REFERENCE_CHECK = {};
local CRAFT_COST_REFERENCE = {};

local madeDraggable = false;

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

function CraftingHook.StoreReference(recipeID)
    if (Utils.IsClassic()) then
        local finalItemLink = GetTradeSkillItemLink(recipeID);

        if (not finalItemLink) then
            return;
        end
        
        if (not CraftIDCache[finalItemLink]) then
            local _, id = strsplit(":", finalItemLink);
            id = tonumber(id);
            CraftIDCache[finalItemLink] = id;
        end
    
        finalItemLink = CraftIDCache[finalItemLink];

        if (not finalItemLink) then
            return;
        end

        local craftSpecial, isEnchanting = CraftingData.Item(recipeID);

        if (craftSpecial) then
            return;
        end

        CRAFT_REFERENCE[finalItemLink] = recipeID;
    else
        local finalItemLink = C_TradeSkillUI.GetRecipeItemLink(recipeID);
        
        if (not finalItemLink) then
            return;
        end
        
        if (not CraftIDCache[finalItemLink]) then
            local _, id = strsplit(":", finalItemLink);
            id = tonumber(id);
            CraftIDCache[finalItemLink] = id;
        end
    
        finalItemLink = CraftIDCache[finalItemLink];

        if (not finalItemLink) then
            return;
        end

        local craftSpecial, isEnchanting = CraftingData.Item(recipeID);

        if (craftSpecial) then
            return;
        end

        CRAFT_REFERENCE[finalItemLink] = recipeID;
    end
end

function CraftingHook.SubCost(link)
    local _, id = strsplit(":", link);

    id = tonumber(id);

    local totalCost = 0;
    local finalWorth = 0;
    local numProduced = 1;

    local subCraft = CRAFT_REFERENCE[id];

    if (not subCraft) then
        return totalCost;
    end

    local lastReagantCount = 0;
    if (Utils.IsClassic()) then
        local min, nump = GetTradeSkillNumMade(subCraft);
        numProduced = nump;

        local numReagents = GetTradeSkillNumReagents(subCraft);
        for i=1, numReagents do
            local reagentName, reagentTexture, reagentCount, playerReagentCount = GetTradeSkillReagentInfo(subCraft, i);
            local link = GetTradeSkillReagentItemLink(subCraft, i);
    
            if (link and Config.Crafting().materialCost and Config.Crafting().materialCost:len() > 0) then
                totalCost = totalCost + (Sources:QueryID(Config.Crafting().materialCost, link) or 0) * reagentCount;
            end
            lastReagantCount = reagentCount;
        end
    else
        numProduced = C_TradeSkillUI.GetRecipeNumItemsProduced(subCraft);
        local numReagents = C_TradeSkillUI.GetRecipeNumReagents(subCraft);
        for i = 1, numReagents do
            local _, _, reagentCount = C_TradeSkillUI.GetRecipeReagentInfo(subCraft, i);
            local link = C_TradeSkillUI.GetRecipeReagentItemLink(subCraft, i);
    
            if (link and Config.Crafting().materialCost and Config.Crafting().materialCost:len() > 0) then
                totalCost = totalCost + (Sources:QueryID(Config.Crafting().materialCost, link) or 0) * reagentCount;
            end
            lastReagantCount = reagentCount;
        end 
    end

    local craftSpecial, isEnchanting = CraftingData.Item(subCraft);
    -- set to 1 for enchants
    if (craftSpecial and isEnchanting) then
        numProduced = 1;
    end

    if (numProduced <= 0) then
        numProduced = 1;
    end

    return math.floor((totalCost / numProduced) + 0.5);
end

function CraftingHook.SetUpRecipe(self, textWidth, tradeSkillInfo)
    local numReagents = C_TradeSkillUI.GetRecipeNumReagents(tradeSkillInfo.recipeID);

    local totalCost = 0;
    local lastReagantCount = 0;
    local lastReagantLink = nil;

    local numProduced = C_TradeSkillUI.GetRecipeNumItemsProduced(tradeSkillInfo.recipeID) or 1;
    if (numProduced <= 0) then
        numProduced = 1;
    end

    local finalItemLink = C_TradeSkillUI.GetRecipeItemLink(tradeSkillInfo.recipeID);
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
    finalItemLink = isEnchanting and craftSpecial or finalItemLink;

    if (not finalItemLink) then
        if (self.Profit) then
            self.Profit:SetText("");
        end
        return;
    end

    local vellumCost = 0;

    -- set to 1 for enchants
    if (craftSpecial and isEnchanting) then
        numProduced = 1;
        
        if (Config.Crafting().materialCost and Config.Crafting().materialCost:len() > 0) then
            vellumCost = Sources:QueryID(Config.Crafting().materialCost, ENCHANTING_VELLUM_ID) or 0;
        end
    end

    for i = 1, numReagents do
        local _, _, reagentCount = C_TradeSkillUI.GetRecipeReagentInfo(tradeSkillInfo.recipeID, i);
        local link = C_TradeSkillUI.GetRecipeReagentItemLink(tradeSkillInfo.recipeID, i);

        local subcost = 0;
        
        if (not craftSpecial and not isEnchanting) then
            subocst = CraftingHook.SubCost(link) * reagentCount;
        end

        local ahCost = 0;

        if (link and Config.Crafting().materialCost and Config.Crafting().materialCost:len() > 0) then
            ahCost = (Sources:QueryID(Config.Crafting().materialCost, link) or 0) * reagentCount;
        end

        if ((subcost > 0 and ahCost > 0 and subcost < ahCost) 
            or (subcost > 0 and ahCost == 0)) then
                totalCost = totalCost + subcost;
        else
            totalCost = totalCost + ahCost; 
        end

        lastReagantLink = link;
        lastReagantCount = reagentCount;
    end

    local finalWorth = 0;
    
    if (craftSpecial and not isEnchanting) then
        finalWorth = CraftingData.DisenchantValue(lastReagantLink, 20);
    else 
        if (Config.Crafting().craftValue and Config.Crafting().craftValue:len() > 0) then
            finalWorth = (Sources:QueryID(Config.Crafting().craftValue, finalItemLink) or 0) * numProduced;
        end
    end

    local cost = (totalCost + vellumCost);
    local profit = finalWorth - (totalCost + vellumCost);
    local prefix = "";
    local negative = false;

    CRAFT_COST_REFERENCE[tradeSkillInfo.recipeID] = cost;

    if (profit < 0) then
        profit = math.abs(profit);
        prefix = "-";
        negative = true;
    end

    local txt = "";
    
    if (not Config.Crafting().hideProfit) then
        txt = txt..Utils.PriceToFormatted(prefix, profit, negative);
    end

    if (not self.Profit) then
        self.Profit = self:CreateFontString("AnsProfit", "ARTWORK", "AnsGameFontNormalLight");
        self.Profit:ClearAllPoints();
        self.Profit:SetPoint("RIGHT", -64, 0);
    end

    self.Profit:SetText(txt);
    
    self:SetSize(500, self:GetHeight());
end

function CraftingHook.StoreRetailReferences()
    if (not TSFrame) then
        return;
    end

    if (Config.Crafting().hideProfit and Config.Crafting().hideCost) then
        return;
    end
    
    local title = TradeSkillFrameTitleText:GetText();
    if (STORED_REFERENCE_CHECK[title]) then
        return;
    end
    -- store references for subcrafts 
    local ids = C_TradeSkillUI.GetAllRecipeIDs();
    Logger.Log(TASKER_TAG, title.." num recipes: "..#ids);
    for i,v in ipairs(ids) do
        CraftingHook.StoreReference(v);
    end
    STORED_REFERENCE_CHECK[title] = true;
end

function CraftingHook.ShowRetailCost(self, id)
    local ansCost = TSFrame.DetailsFrame.Contents.AnsCost;
    if (not ansCost) then
        return;
    end

    ansCost:SetText("");

    local cost = CRAFT_COST_REFERENCE[id];

    if (not Config.Crafting().hideCost and cost) then
        ansCost:SetText("Cost: "..Utils.PriceToFormatted("", cost, false));
    end
end

function CraftingHook.HookRetail()
    if (Config.Crafting().hideProfit and Config.Crafting().hideCost) then
        return false;
    end

    TSFrame:SetSize(870, TSFrame:GetHeight());
    TSFrame.RecipeList:SetSize(500, TSFrame.RecipeList:GetHeight());
    TSFrame.RecipeInset:SetSize(525, TSFrame.RecipeInset:GetHeight());
    
    -- add in fontstring for cost in the details view of the tradeskill frame
    local ansCost = TSFrame.DetailsFrame.Contents:CreateFontString("AnsCost", "BACKGROUND", "AnsGameFontNormalLight");
    ansCost:ClearAllPoints();
    ansCost:SetPoint("TOPRIGHT", -5, -60);
    TSFrame.DetailsFrame.Contents.AnsCost = ansCost;

    -- hook the details frame SetSelectedRecipeID
    hooksecurefunc(TSFrame.DetailsFrame, "SetSelectedRecipeID", CraftingHook.ShowRetailCost);

    for i,b in ipairs(TSFrame.RecipeList.buttons) do
        -- hooksecurefunc(b, "SetUpRecipe", CraftingHook.StoreReference);
        hooksecurefunc(b, "SetUpRecipe", CraftingHook.SetUpRecipe);
        hooksecurefunc(b, "SetUpHeader", CraftingHook.SetUpHeader);
        b:HookScript("OnLeave", CraftingHook.MouseLeave);
    end

    return true;
end

function CraftingHook.SetProfit(self, id)
    local totalCost = 0;

    local finalItemLink = GetTradeSkillItemLink(id);
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
    local craftSpecial, isEnchanting = CraftingData.Item(id);
    finalItemLink = isEnchanting and craftSpecial or finalItemLink;

    if (not finalItemLink) then
        if (self.Profit) then
            self.Profit:SetText("");
        end
        return;
    end

    local min, numProduced = GetTradeSkillNumMade(id);

    if (numProduced <= 0) then
        numProduced = 1;
    end

    -- set to 1 for enchants
    if (craftSpecial and isEnchanting) then
        numProduced = 1;
    end

    local numReagents = GetTradeSkillNumReagents(id);
    for i=1, numReagents do
        local reagentName, reagentTexture, reagentCount, playerReagentCount = GetTradeSkillReagentInfo(id, i);
        local link = GetTradeSkillReagentItemLink(id, i);
        
        local subcost = 0;
        
        if (not craftSpecial and not isEnchanting) then
            subocst = CraftingHook.SubCost(link) * reagentCount;
        end

        local ahCost = 0;

        if (link and Config.Crafting().materialCost and Config.Crafting().materialCost:len() > 0) then
            ahCost = (Sources:QueryID(Config.Crafting().materialCost, link) or 0) * reagentCount;
        end

        if ((subcost > 0 and ahCost > 0 and subcost < ahCost) 
            or (subcost > 0 and ahCost == 0)) then
                totalCost = totalCost + subcost;
        else
            totalCost = totalCost + ahCost; 
        end
    end

    local finalWorth = 0;
    
    if (Config.Crafting().craftValue and Config.Crafting().craftValue:len() > 0) then
        finalWorth = (Sources:QueryID(Config.Crafting().craftValue, finalItemLink) or 0) * numProduced;
    end
    
    local profit = finalWorth - totalCost;
    local prefix = "";
    local negative = false;

    CRAFT_COST_REFERENCE[id] = totalCost;

    if (profit < 0) then
        profit = math.abs(profit);
        prefix = "-";
        negative = true;
    end

    local txt = "";
    
    if (not Config.Crafting().hideProfit) then
        txt = txt..Utils.PriceToFormatted(prefix, profit, negative);
    end

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

function CraftingHook.ShowClassicCost(id)
    local detailFrame = _G["TradeSkillDetailScrollChildFrame"];

    if (not detailFrame) then
        return;
    end

    local ansCost = detailFrame.AnsCost;

    if (not ansCost) then
        return;
    end

    ansCost:SetText("");

    local cost = CRAFT_COST_REFERENCE[id];

    if (not Config.Crafting().hideCost and cost) then
        ansCost:SetText("Cost: "..Utils.PriceToFormatted("", cost, false));
    end
end

function CraftingHook.StoreClassicReferences()
    if (not TSFrame) then
        return;
    end
    
    if (Config.Crafting().hideProfit and Config.Crafting().hideCost) then
        return;
    end

    local title = TradeSkillFrameTitleText:GetText();
    if (STORED_REFERENCE_CHECK[title]) then
        return;
    end
    -- store references
    local totalSkills = GetNumTradeSkills();
    Logger.Log(TASKER_TAG, title.." num recipes: "..totalSkills);
    for i = 1, totalSkills do
        local _, type = GetTradeSkillInfo(i);
        if (type:lower() ~= "header" and type:lower() ~= "subheader") then
            CraftingHook.StoreReference(i);
        end
    end

    STORED_REFERENCE_CHECK[title] = true;
end

function CraftingHook.HookClassic()
    local scrollFrame = _G["TradeSkillListScrollFrame"];

    if (Config.Crafting().hideProfit and Config.Crafting().hideCost) then
        return false;
    end

    local detailFrame = _G["TradeSkillDetailScrollChildFrame"];

    if (detailFrame) then
        local ansCost = detailFrame:CreateFontString("AnsCost", "BACKGROUND", "AnsGameFontNormalLight");
        ansCost:ClearAllPoints();
        ansCost:SetPoint("TOPRIGHT", -5, -32);
        detailFrame.AnsCost = ansCost;
    end

    -- hook the classic TradeSkillFrame_SetSelection
    hooksecurefunc("TradeSkillFrame_SetSelection", CraftingHook.ShowClassicCost);

    for i = 1, 8 do
        local button = _G["TradeSkillSkill"..i];

        if (button) then
            -- hooksecurefunc(button, "SetID", CraftingHook.StoreReference);
            hooksecurefunc(button, "SetID", CraftingHook.SetID);
        end
    end

    return true;
end

local didHook = false;

EventManager:On("TRADE_SKILL_DATA_SOURCE_CHANGED", 
    function()
        Tasker.Schedule(CraftingHook.StoreRetailReferences, TASKER_TAG);
    end
);

EventManager:On("TRADE_SKILL_UPDATE",
    function()
        Tasker.Schedule(CraftingHook.StoreClassicReferences, TASKER_TAG);
    end
);

EventManager:On("TRADE_SKILL_SHOW", 
    function()
        CraftingHook.shown = true;

        TSFrame = TradeSkillFrame;

        if (not TSFrame) then
            return;
        end

        if (not didHook) then
            if (Utils.IsClassic()) then
                didHook = CraftingHook.HookClassic();
            else
                didHook = CraftingHook.HookRetail();
            end
        end

        if (not madeDraggable) then
            madeDraggable = true;
            Draggable:Acquire(TSFrame, "craftWindow");
        end
    end);

EventManager:On("TRADE_SKILL_CLOSE",
    function()
        CraftingHook.shown = false;
    end
);