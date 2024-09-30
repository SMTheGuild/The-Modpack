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

--- Returns a stateful iterator function that returns the indexes
--- of the bits of x, from least significant to most significant.
---
--- The iterator returns no bits if x is negative.
--- If x is not an integer, it will be rounded to the nearest integer
--- using math.round().
---
--- Generator complexity: O(log2 x)
function math.bitsiter(x)
	x = math.round(x)

	if x < 0 then
		return function ()
			return nil
		end
	end

	local i = 0
	return function()
		while x % 2 == 0 do
			x = math.floor(x / 2)
			i = i + 1
			if x <= 0 then
				return nil
			end
		end

		x = math.floor(x / 2)
		i = i + 1
		return i-1
	end
end

function table.size(tablename)
	local i = 0
	for k, v in pairs(tablename) do
		i = i +1
	end
	return i
end
