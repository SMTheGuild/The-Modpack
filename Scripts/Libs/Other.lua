if __Other_Loaded then return end
__Other_Loaded = true
dofile "Debugger.lua"
mpPrint("loading Libs/Other.lua")


function getGlobal(shape, vec)
    return shape.right* vec.x + shape.at * vec.y + shape.up * vec.z
end
function getLocal(shape, vec)
    return sm.vec3.new(shape.right:dot(vec), shape.at:dot(vec), shape.up:dot(vec))
end