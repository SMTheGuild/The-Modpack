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

function table.size(tablename)
	local i = 0
	for k, v in pairs(tablename) do
		i = i +1
	end
	return i
end