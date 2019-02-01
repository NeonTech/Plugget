/*
 * This file is part of Plugget.
 *
 * Plugget is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Plugget is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Plugget.  If not, see <https://www.gnu.org/licenses/>.
 */
#include <sourcemod>

public Plugin myinfo =
{
    name = "Plugget",
    description = "Map Dependent Plugin Loader/Unloader",
    author = "danthonywalker#5512",
    version = "1.0.0",
    url = "https://github.com/NeonTech/Plugget"
};

public void OnPluginStart()
{
    KeyValues maps = new KeyValues("Maps"); // Import the file, export on failure
    if (!maps.ImportFromFile("plugget.cfg") && !maps.ExportToFile("plugget.cfg"))
    {
        SetFailState("Failed to export to plugget.cfg file!");
    }

    maps.Close();
    OnMapStart();
}

public void OnMapStart()
{
    char map[PLATFORM_MAX_PATH];
    GetCurrentMap(map, sizeof(map));
    LoadMapPlugins(map);
}

public void OnMapEnd()
{
    char map[PLATFORM_MAX_PATH];
    GetCurrentMap(map, sizeof(map));
    UnloadMapPlugins(map);
}

static void LoadMapPlugins(const char[] map)
{
    DataPack mapPlugins = GetMapPlugins(map);
    char folder[PLATFORM_MAX_PATH];
    char plugin[PLATFORM_MAX_PATH];
    
    mapPlugins.ReadString(folder, sizeof(folder));
    ArrayList plugins = mapPlugins.ReadCell();
    mapPlugins.Close();

    for (int index = 0; index < plugins.Length; index++)
    {
        plugins.GetString(index, plugin, sizeof(plugin));
        LogMessage("Loading %s/%s for %s", folder, plugin, map);
        ServerCommand("sm plugins load disabled/%s/%s", folder, plugin);
    }

    char command[PLATFORM_MAX_PATH];
    Format(command, sizeof(command), "exec %s.cfg", folder);
    ServerCommand(command);
    ServerCommand("exec server.cfg");

    plugins.Close();
}

static void UnloadMapPlugins(const char[] map)
{
    DataPack mapPlugins = GetMapPlugins(map);
    char folder[PLATFORM_MAX_PATH];
    char plugin[PLATFORM_MAX_PATH];

    mapPlugins.ReadString(folder, sizeof(folder));
    ArrayList plugins = mapPlugins.ReadCell();
    mapPlugins.Close();

    for (int index = 0; index < plugins.Length; index++)
    {
        plugins.GetString(index, plugin, sizeof(plugin));
        LogMessage("Unloading %s/%s for %s", folder, plugin, map);
        ServerCommand("sm plugins unload disabled/%s/%s", folder, plugin);
    }

    plugins.Close();
}

static DataPack GetMapPlugins(const char[] map)
{
    KeyValues maps = new KeyValues("Maps");
    if (!maps.ImportFromFile("plugget.cfg"))
    {
        SetFailState("Failed to import from plugget.cfg file!");
    }

    ArrayList plugins = new ArrayList(PLATFORM_MAX_PATH, 0);
    char directory[PLATFORM_MAX_PATH];
    char value[PLATFORM_MAX_PATH];

    maps.GetString(map, value, sizeof(value), "default");
    Format(directory, sizeof(directory), "addons/sourcemod/plugins/disabled/%s", value);

    if (DirExists(directory))
    {
        DirectoryListing files = OpenDirectory(directory);
        char fileName[PLATFORM_MAX_PATH];
        FileType fileType;
        int fileNameLength;

        while (files.GetNext(fileName, sizeof(fileName), fileType))
        {
            fileNameLength = strlen(fileName) - 4; // Removes .smx suffix to use as plugin's name
            if ((fileType == FileType_File) && (StrContains(fileName, ".smx") == fileNameLength))
            {
                strcopy(fileName, fileNameLength + 1, fileName);
                plugins.PushString(fileName);
            }
        }

        files.Close();
    }
    maps.Close();

    DataPack mapPlugins = new DataPack();
    mapPlugins.WriteString(value);
    mapPlugins.WriteCell(plugins);
    mapPlugins.Reset();
    return mapPlugins;
}
