if __Input_Loaded then return end
__Input_Loaded = true

-- parses user-provided number strings
-- - removes all spaces
-- - parses binary numbers with the "0b", "0B" prefixes or "b" suffix
-- - parses hexadecimal numbers with the "0x", "0X" prefixes
-- returns nil for incorrectly formatted strings
--
-- Examples:
-- mp_parseNumber(" 1 000    000 ") == 1000000
-- mp_parseNumber("0xFF") == 255
-- mp_parseNumber("0b1000") == 8
-- mp_parseNumber("1000b") == 8
-- mp_parseNumber("test") == nil
function mp_parseNumber(input)
	normalized = string.gsub(input, "%s+", "") -- remove spaces

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
