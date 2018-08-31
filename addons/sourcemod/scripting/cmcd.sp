/*
 * This file is part of CMCD.
 *
 * CMCD is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * CMCD is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with CMCD.  If not, see <https://www.gnu.org/licenses/>.
 */
#include <sourcemod>

#include "include/mapchooser_extended"

public Plugin myinfo =
{
    name = "CMCD",
    description = "Custom Map Change Detector",
    author = "danthonywalker#5512",
    version = "1.0.0",
    url = "https://github.com/danthonywalker"
};

public void OnPluginStart()
{
    ConVar cmcd_nextmap = FindConVar("sm_nextmap");
    cmcd_nextmap.AddChangeHook(OnCmcdNextMapChange);

    RegAdminCmd("sm_map", OnMapCommand, ADMFLAG_CHANGEMAP);
}

public void OnCmcdNextMapChange(ConVar convar, const char[] oldValue, const char[] newValue)
{ // When a normal vote completes with at least 1 vote then OnMapVoteEnd will execute twice
    OnMapVoteEnd(newValue);
}

public Action OnMapCommand(int client, int argc)
{ // Replicates behavior of map.sp before saving
    if (argc < 1)
    {
        return Plugin_Continue;
    }

    char arg[PLATFORM_MAX_PATH];
    char map[PLATFORM_MAX_PATH];
    GetCmdArg(1, arg, sizeof(arg));

    if (FindMap(arg, map, sizeof(map)) == FindMap_NotFound)
    {
        return Plugin_Continue;
    }

    OnMapVoteEnd(map);
    return Plugin_Continue;
}

public int OnMapVoteEnd(const char[] map)
{
    LogMessage("Writing map to cmcd file - %s", map);
    File cmcd_file = OpenFile("cmcd", "w");
    WriteFileLine(cmcd_file, map);
    CloseHandle(cmcd_file);
}
