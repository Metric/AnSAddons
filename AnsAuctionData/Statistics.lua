local Core = select(2, ...);

local Utils = Ans.API.Utils;
local TempTable = Ans.API.TempTable;
local Statistics = {};
Statistics.__index = Statistics;

Core.Statistics = Statistics;

local function RoundToInt(num)
    return math.floor(num + 0.5);
end

local function SorthMethod(a,b)
	return a < b;
end

local function Sum(x)
    local n = #x;
    local sum = 0;
    for i = 1, n do
        sum = sum + x[i];
    end
    return sum;
end

local function StdDev(x, avg)
	local count = #x;
	local stdev = 0;

	if (count <= 1) then return 0; end

	for i = 1, count do
		stdev = stdev + (x[i] - avg) ^ 2;
	end
	return math.sqrt(stdev / (count - 1));
end

function Statistics:RoundToInt(x)
    return RoundToInt(x);
end

function Statistics:Sum(x) 
    return Sum(x);
end

function Statistics:Calculate(x, prevSum, prevCount)
	local half = ceil(#x * 0.25);
	local low = ceil(#x * 0.15);
    local valid = TempTable:Acquire();

    table.sort(x, SorthMethod);

    local prev = 0;
	local sum = 0;
	local mina = x[1];
	local count = 0;

	for i = 1, half do
		if (i <= low or x[i] < prev * 1.2) then
			sum = sum + x[i];
			tinsert(valid, x[i]);
		end
		prev = x[i];
	end 
	
	count = #valid;
	
	-- exit early if nothing
	-- though we should have atleast one
	if (count == 0) then
		return 0, 0, 0, 0;
	end
		
	local avg = RoundToInt(sum / count);
	local std = RoundToInt(StdDev(valid, avg));
	local minValue = RoundToInt(avg - std * 1.5);
	local maxValue = RoundToInt(avg + std * 1.5);
	local num = 0;
	local lastSum = sum;

	sum = 0;
	for i = 1, count do
		local v = valid[i];
		if (v >= minValue and v <= maxValue) then
			sum = sum + v;
			num = num + 1;
		end
	end

	if (num == 0) then
		sum = lastSum;
		num = count;
	end

	valid:Release();
	avg = RoundToInt((sum + prevSum) / math.max(1, num + prevCount));
    return mina, avg, sum, num;
end