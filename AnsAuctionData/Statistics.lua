local Ans = select(2, ...);

local Utils = AnsCore.API.Utils;
local Statistics = {};
Statistics.__index = Statistics;

Ans.Statistics = Statistics;

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
    local valid = Utils:GetTable();

    table.sort(x, SorthMethod);

    local prev = 0;
	local sum = 0;
	local mina = math.huge;
	local count = 0;

	for i = 1, half do
		if (i <= low or x[i] < prev * 1.2) then
			sum = sum + x[i];
			mina = math.min(mina, x[i]);
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
		
	local avg = sum / count;
	local std = StdDev(valid, avg);
	local minValue = avg - std * 1.5;
	local maxValue = avg + std * 1.5;
	local num = 0;

	sum = 0;
	for i = 1, count do
		local v = valid[i];
		if (v >= minValue and v <= maxValue) then
			sum = sum + v;
			num = num + 1;
		end
	end

	Utils:ReleaseTable(valid);
	avg = RoundToInt((sum + prevSum) / math.max(1, num + prevCount));
    return mina, avg, sum, num;
end