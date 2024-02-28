if __MoreMath_Loaded then return end
__MoreMath_Loaded = true


--- Rounds a given number to the closest whole number.
---@param x number The number to round.
---@return number rounded The rounded value of `x`
function math.round(x)
	if x % 2 ~= 0.5 then
		return math.floor(x + 0.5)
	end
	return x - 0.5
end

function math.roundby(x, by)
	-- TODO
end

--- Returns the size of `table`
---@param tablename table The table
---@return integer The size of `table`
function table.size(tablename)
	local i = 0
	for k, v in pairs(tablename) do
		i = i + 1
	end
	return i
end
