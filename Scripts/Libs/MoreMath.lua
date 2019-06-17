dofile "Debugger.lua"

if __MoreMath_Loaded then return end
__MoreMath_Loaded = true
debug("loading Libs/MoreMath.lua")


function math.round(x)
  if x%2 ~= 0.5 then
    return math.floor(x+0.5)
  end
  return x-0.5
end

function math.roundby( x, by)
	-- TODO

end