-- ShapeDatabase.lua --

shapeDatabase = {}
shapeDatabaseLookup = {}

local shapeDatabasePaths = {
    "$MOD_DATA", --$MOD_DATA finally got fixed, so i'll leave it here, i guess
    "$CONTENT_bd5c1e72-513c-40b4-b75e-db50082461e9", --Local Copy Path
    "$CONTENT_b7443f95-67b7-4f1e-82f4-9bef0c62c4b3" --Workshop Modpack Continuation Path
}

function reloadShapeDatabase()
    for k, v in pairs(shapeDatabasePaths) do
        local fullPath = v.."/Scripts/data/shape_database.json"

        local success, error = pcall(sm.json.open, fullPath)
        if success then
            shapeDatabase = error
            for k, v in pairs(error) do
                shapeDatabaseLookup[v.uuid] = tonumber(k)
            end

            break
        end
    end

    print("Shape Database reloaded!")
end

reloadShapeDatabase()