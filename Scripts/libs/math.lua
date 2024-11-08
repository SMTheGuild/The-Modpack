if __MoreMath_Loaded then return end
__MoreMath_Loaded = true


function math.round(x)
  if x%2 ~= 0.5 then
    return math.floor(x+0.5)
  end
  return x-0.5
end

function math.roundby( x, by)
	-- TODO

end

-- parses user-provided number strings
-- - removes all spaces
-- - parses binary numbers with the "0b", "0B" prefixes or "b" suffix
-- - parses hexadecimal numbers with the "0x", "0X" prefixes
-- returns nil for incorrectly formatted strings
--
-- Examples:
-- math.parsestring(" 1 000    000 ") == 1000000
-- math.parsestring("0xFF") == 255
-- math.parsestring("0b1000") == 8
-- math.parsestring("1000b") == 8
-- math.parsestring("test") == nil
function math.parsenumber(input)
	normalized = string.gsub(input, "%s+", "") -- remove spaces:

	prefix = string.sub(normalized, 1, 2)
	suffix = string.sub(normalized, -1, -1)
	if suffix == "b" or suffix == "B" then
		return tonumber(string.sub(normalized, 1, -2), 2)
	elseif prefix == "0b" or prefix == "0B" then
		return tonumber(string.sub(normalized, 3, -1), 2)
	elseif prefix == "0x" or prefix == "0X" then
		return tonumber(string.sub(normalized, 3, -1), 16)
	else
		return tonumber(normalized, 10)
	end
end

function table.size(tablename)
	local i = 0
	for k, v in pairs(tablename) do
		i = i +1
	end
	return i
end
