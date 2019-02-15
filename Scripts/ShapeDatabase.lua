-- ShapeDatabase.lua --

shapeDatabase = {}
shapeDatabaseLookup = {}

function reloadShapeDatabase()
    shapeDatabase = sm.json.open("$MOD_DATA/Scripts/Data/shapeDatabase.json")
    for k,v in pairs(shapeDatabase) do
        shapeDatabaseLookup[v.uuid] = tonumber(k)
    end
    print("ShapeDatabase.json reloaded!")
end

reloadShapeDatabase()