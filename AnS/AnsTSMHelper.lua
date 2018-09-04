AnsTSMHelper = {};
AnsTSMHelper.__index = AnsTSMHelper;

local private = {
    realmData = nil,
    regionData = nil
};
private.__index = private;
ANS_DB_TEMP = nil;

AnsTSMHelper.GetRealmItemData = function(id, key)
    return private:GetRealmItemData(id, key);
end

AnsTSMHelper.GetRegionItemData = function(id, key)
    return private:GetRegionItemData(id, key);
end
AnsTSMHelper.GetRegionSaleInfo = function(id, key)
    return private:GetRegionSaleInfo(id, key);
end

function AnsTSMHelper:GrabData()
    local cregion = GetCVar("portal");
    if (TSMAPI.AppHelper) then
        local i;
        local data = TSMAPI.AppHelper:FetchData("AUCTIONDB_MARKET_DATA");
        if (data) then
            for i = 1, #data do
                local realm, dstr = unpack(data[i]);

                --if (realm == cregion and dstr) then
                --    print("TSM REGION SIZE: "..dstr:len());
                --    private.regionData = private:ProcessData(dstr);
                --end
                if (TSMAPI.AppHelper:IsCurrentRealm(realm)) then
                    private.realmData = private:ProcessData(dstr);
                end
            end

            if (private.realmData) then
                private:ParseFields(private.realmData);
            else
                private.realmData = {};
            end

            --if (private.regionData) then
            --    private:ParseFields(private.regionData);
            --else
            --    private.regionData = {};
            --end

            return true;
        end
    end

    return false;
end

function private:ParseFields(tbl)
    local fields = tbl.fields;
    local data = tbl.data;
    local k;
    for i = 1, #data do
        local section = data[i];
        local id;
        for k = 1, #fields do
            local key = fields[k];
            if (k == 1) then
                if (type(section[k]) == "number") then
                    id = "i:"..section[k];
                else
                    local _, itemId = strsplit(":", section[k]);
                    id = _..":"..itemId;
                end
                tbl[id] = {};
            else
                tbl[id][key] = section[k];
            end
        end
    end
end

function private:GetRegionSaleInfo(id, key)
    local result = self:GetRegionItemData(id, key);
    
    if (result) then
        return result / 100;
    end

    return 0;
end

function private:GetRegionItemData(id, key)
    if (type(id) == "number") then
        id = "i:"..id;
    else
        id = AnsUtils:GetTSMID(id);
    end

    if (self.regionData) then
        if (self.regionData[id]) then
            return self.regionData[id][key];
        end
    end

    return 0;
end

function private:GetRealmItemData(id, key)
    if (type(id) == "number") then
        id = "i:"..id;
    else
        id = AnsUtils:GetTSMID(id);
    end

    if (self.realmData) then
        if (self.realmData[id]) then
            return self.realmData[id][key];
        end
    end

    return 0;
end

function private:ProcessData(str)
    local endIndex, startIndex = strfind(str, ",data={");
    local itemList = strsub(str, startIndex+1, str:len()-2);
    local metaStr = strsub(str, 1, endIndex - 1).."}";
    local metaData = loadstring(metaStr)();
    local itemData = {};
    local len = itemList:len();

    local cstart, cend, cnext = 1, nil, nil;
    while cstart do
        cend, cnext = strfind(itemList, "},{", cstart);
        local s = strsub(itemList, cstart, cend or len);
        local chunk = loadstring("return "..s)();
        tinsert(itemData, chunk);
        cstart = cnext;
    end

    local result = {};
    result.fields = metaData.fields;
    result.data = itemData;
    return result;
end