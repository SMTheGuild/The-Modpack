-- ShapeDatabase.lua --

shapeDatabase = {}
shapeDatabaseLookup = {}

function reloadShapeDatabase()
    shapeDatabase = sm.json.open("$CONTENT_bd5c1e72-513c-40b4-b75e-db50082461e9/Scripts/Data/shapeDatabase.json")
    for k,v in pairs(shapeDatabase) do
        shapeDatabaseLookup[v.uuid] = tonumber(k)
    end
    print("ShapeDatabase.json reloaded!")
end

reloadShapeDatabase()