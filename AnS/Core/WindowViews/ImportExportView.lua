local Ans = select(2, ...);

local Config = Ans.Config;
local Importer = Ans.Importer;
local Exporter = Ans.Exporter;
local TextInput = Ans.UI.TextInput;

local ImportExport = {};
ImportExport.__index = ImportExport;
ImportExport.selected = false;
ImportExport.loaded = false;
ImportExport.index = 6;

Ans.ImportExportView = ImportExport;

function ImportExport:OnLoad(f)
    self.loaded = true;
    local this = self;
    local tab = _G[f:GetName().."TabView"..self.index];
    self.tab = tab;

    self.text = TextInput:NewFrom(self.tab.Input.Text);
    self.text:EnableMultiLine();

    self.importGroups = self.tab.ImportGroups;
    self.exportGroups = self.tab.ExportGroups;

    self.importGroups:SetScript("OnClick", 
        function()
            this:ImportGroups();
        end
    );

    self.exportGroups:SetScript("OnClick", 
        function()
            this:ExportGroups();
        end
    );
end

function ImportExport:ExportGroups()
    local groups = Config.Groups();
    local txt = Exporter:ExportGroups(groups);
    self.text:Set(txt or "");
end

function ImportExport:ImportGroups()
    local txt = self.text:Get();
    if (not txt or #txt == 0) then
        return;
    end

    local groups = Config.Groups();
    Importer:ImportGroups(txt, groups);
    self.text:Set("");
end

function ImportExport:Show()
    if (self.tab) then
        self.selected = true;
        self.text:Set("");
        self.tab:Show();
    end
end

function ImportExport:Hide()
    if (self.tab) then
        self.selected = false;
        self.tab:Hide();
        self.text:Set("");
    end
end