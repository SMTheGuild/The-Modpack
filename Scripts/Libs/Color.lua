if __Color_Loaded then return end
__Color_Loaded = true
print("Colors library loading...")

--[[Matches any color with a group
function sm.color.match( color )
	local r = sm.color.getR(color) * 255
	local g = sm.color.getG(color) * 255
	local b = sm.color.getB(color) * 255
	if((r == b)and(r == g)) then return "grey"
	elseif((g > r - 9)and(g > b)) then return "green"
	elseif((b - 4 > r)and(b > g - 1)) then return "blue"
	else return "red" end
end
sm.color.new(0,0,0).match = sm.color.match

--RGB to HSV converter
function sm.color.toHSV( in_rgb )
	local rgb = { r = in_rgb.r, g = in_rgb.g, b = in_rgb.b }
	local max = math.max(rgb)
	local min = math.min(rgb)
	local delta = rgb[max] - rgb[min]
	local hsv = { h, s, v }
	--Hue
	if(delta == 0) then hsv.h = 0 else
	local hue = {}
	hue["r"] = function( rgb, delta ) return 60 * (((rgb.g - rgb.b) / delta) % 6) end
	hue["g"] = function( rgb, delta ) return 60 * (((rgb.b - rgb.r) / delta) + 2) end
	hue["b"] = function( rgb, delta ) return 60 * (((rgb.r - rgb.g) / delta) + 4) end
	hsv.h = hue[max](rgb, delta) end
	--Saturation
	if(rgb[max] == 0) then hsv.s = 0 else
	hsv.s = (delta / rgb[max]) end
	--Value
	hsv.v = rgb[max]
	return hsv
end
--]]

--HSV to RGB converter
function sm.color.toRGB( hsv )
	local C = hsv.v * hsv.s
	local X = C * ( 1 - math.abs( ((hsv.h / 60) % 2) - 1 ) )
	local M = hsv.v - C
	local H = math.floor( hsv.h % 360 / 60 )
	local out_rgb
	local rgb = {}
	rgb[0] = function( C, X ) return { r = C, g = X, b = 0 } end
	rgb[1] = function( C, X ) return { r = X, g = C, b = 0 } end
	rgb[2] = function( C, X ) return { r = 0, g = C, b = X } end
	rgb[3] = function( C, X ) return { r = 0, g = X, b = C } end
	rgb[4] = function( C, X ) return { r = X, g = 0, b = C } end
	rgb[5] = function( C, X ) return { r = C, g = 0, b = X } end
	out_rgb = rgb[H]( C, X )
	return sm.color.new( out_rgb.r + M, out_rgb.g + M, out_rgb.b + M)
end
