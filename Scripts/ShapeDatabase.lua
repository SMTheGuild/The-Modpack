-- ShapeDatabase.lua --

shapeDatabase = {}
shapeDatabaseLookup = {}

local ShapeDatabasePath = {
    "$MOD_DATA/Scripts/Data/shapeDatabase.json", --$MOD_DATA finally got fixed, so i'll leave it here, i guess
    "$CONTENT_bd5c1e72-513c-40b4-b75e-db50082461e9/Scripts/Data/shapeDatabase.json", --Local Copy Path
    "$CONTENT_26ef623b-97d2-49ba-9a10-8898c1a94e9a/Scripts/Data/shapeDatabase.json" --Workshop Modpack Path
}

function reloadShapeDatabase()
    for k, v in pairs(ShapeDatabasePath) do
        local success, error = pcall(sm.json.open, v)
        if success then
            shapeDatabase = error
            for k, v in pairs(error) do
                shapeDatabaseLookup[v.uuid] = tonumber(k)
            end

            break
        end
    end

    print("ShapeDatabase.json reloaded!")
end

reloadShapeDatabase()