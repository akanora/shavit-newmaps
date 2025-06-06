
/* Header files */
#include <shavit/rankings>

/* Preprocessor directives */
#pragma semicolon 1
#pragma newdecls required

/* Globals */
ArrayList gA_NewestMaps;
ConVar gCV_MaxMapsToShow;

/* Plugin information */
public Plugin myinfo = 
{
	name = "Recently uploaded maps",
	author = "Nairda - Fixed by Nora",
	description = "Displays recently uploaded maps.",
	url = "https://steamcommunity.com/id/nairda1339/"
}

enum struct MapInfo 
{
	int TimeStamp;
	char MapName[PLATFORM_MAX_PATH];
}

public void OnPluginStart()
{
	gA_NewestMaps = new ArrayList(sizeof(MapInfo));
	RegConsoleCmd("sm_newmaps", NewestMaps, "List recently uploaded maps.");
	gCV_MaxMapsToShow = CreateConVar("max_maps_to_show", "25", "Number of maps to display", 0, true, 1.0, true, 100.0);

	AutoExecConfig(true, "recent_maps");
}

public Action NewestMaps(int client, int args)
{
	UpdateMapsList();
	NewMapsMenu(client);
	return Plugin_Handled;
}

void NewMapsMenu(int client)
{
	Menu menu = new Menu(Handler_NewestMaps);
	
	int mapsToShow = (gCV_MaxMapsToShow.IntValue < gA_NewestMaps.Length) ? gCV_MaxMapsToShow.IntValue : gA_NewestMaps.Length;
	menu.SetTitle("Newest Maps (Showing %i):", mapsToShow);

	for (int i = 0; i < mapsToShow; i++)
	{
		MapInfo map;
		gA_NewestMaps.GetArray(i, map, sizeof(map));

		char time[32], display[255];
		FormatTime(time, sizeof(time), "%Y/%m/%d %H:%M", map.TimeStamp);
		Format(display, sizeof(display), "%s | %s [T%i]", time, map.MapName, Shavit_GetMapTier(map.MapName));

		menu.AddItem(map.MapName, display);
	}

	menu.Display(client, MENU_TIME_FOREVER);
}

public int Handler_NewestMaps(Menu menu, MenuAction action, int client, int choice)
{
	if (action == MenuAction_Select)
	{
		char mapName[PLATFORM_MAX_PATH];
		menu.GetItem(choice, mapName, sizeof(mapName));
		FakeClientCommand(client, "sm_nominate %s", mapName);
		NewMapsMenu(client);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

void UpdateMapsList()
{
	gA_NewestMaps.Clear();
	DirectoryListing dir = OpenDirectory("maps/");

	if (dir == null)
	{
		PrintToServer("Failed to open maps directory.");
		return;
	}

	char mapName[PLATFORM_MAX_PATH], path[PLATFORM_MAX_PATH];
	FileType fileType;

	while (dir.GetNext(mapName, sizeof(mapName), fileType))
	{
		if (fileType == FileType_File && StrContains(mapName, ".bsp", false) != -1)
		{
			Format(path, sizeof(path), "maps/%s", mapName);
			
			MapInfo map;
			map.TimeStamp = GetFileTime(path, FileTime_LastChange);
			strcopy(map.MapName, sizeof(map.MapName), mapName);
			ReplaceString(map.MapName, sizeof(map.MapName), ".bsp", "", false);

			gA_NewestMaps.PushArray(map, sizeof(map));
		}
	}

	delete dir;
	gA_NewestMaps.SortCustom(SortByTimestamp);
}

public int SortByTimestamp(int index1, int index2, Handle array, Handle hndl)
{
	MapInfo map1, map2;
	gA_NewestMaps.GetArray(index1, map1, sizeof(map1));
	gA_NewestMaps.GetArray(index2, map2, sizeof(map2));

	if (map1.TimeStamp > map2.TimeStamp)
		return -1;
	else if (map1.TimeStamp < map2.TimeStamp)
		return 1;
	else
		return 0;
}