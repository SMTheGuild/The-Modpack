# The Modpack
A popular Scrap Mechanic mod that adds number logic, wheels and other parts to the game.

## Links
Maintained version: [Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=2448492759)
![Steam Downloads](https://img.shields.io/steam/downloads/2448492759)
![Steam Favorites](https://img.shields.io/steam/favorites/2448492759)

[Deprecated version](https://steamcommunity.com/sharedfiles/filedetails/?id=881254777)
![Steam Downloads](https://img.shields.io/steam/downloads/881254777)
![Steam Favorites](https://img.shields.io/steam/favorites/881254777)

## Versioning guidelines
The Modpack uses [semantic versioning](https://semver.org) to version its releases.

When a change is made to the mod that changes the behaviour of creations made in the previous version, this is a backwards compatibility break, and should be a MAJOR version update.

When a change is made that adds new behaviour/parts/features, then creations made in this new version will not be able to be used the same way by people with the older version, but it does not change anything about creations made in older versions. This is a MINOR update.

Bugfixes are PATCH updates.

## File and class naming guidelines
A Lua file should only define a maximum of one class. Classes should be named in CamelCase. If a Lua file defines a class, it should be named `<ClassName>.lua`.

If a Lua file does not define a class, it should be named in underscore_case (e.g. `math_utils.lua`).

Folder names inside `Scripts/` should be in lowercase.

Interactable class files should be located in `Scripts/interactable`.  
Tool class files should be located in `Scripts/tool`.  
Libraries and utility scripts should be located in `Scripts/libs` and `Scripts/util` respectively, and should be named in underscore_case.
Data files should be located in `Scripts/data` and be named in underscore_case (e.g. `shape_database.json`).  
