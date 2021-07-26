#pragma semicolon 1

#include <amxmodx>
#include <json>
#include <rezp>

new const GAMEMODES_DIRECTORY[] = "gamemodes";

new bool:g_bCreating;
new JSON:g_iJsonHandle;
new JSON:g_iJsonHandleCopy;

new g_iTemp;
new g_sTemp[RZ_MAX_RESOURCE_PATH];

public plugin_precache()
{
	register_plugin("[ReZP] Config: Game Modes", REZP_VERSION_STR, "fl0wer");

	GameModeConfigs();
}

GameModeConfigs()
{
	new size = rz_gamemodes_size();

	if (!size)
		return;

	new baseDirPath[PLATFORM_MAX_PATH];
	new gameModesDirPath[PLATFORM_MAX_PATH];

	rz_get_configsdir(baseDirPath, charsmax(baseDirPath));
	formatex(gameModesDirPath, charsmax(gameModesDirPath), "%s/%s", baseDirPath, GAMEMODES_DIRECTORY);

	if (!dir_exists(gameModesDirPath))
	{
		if (mkdir(gameModesDirPath) != 0)
		{
			rz_log(true, "Cannot create game modes directory '%s'", gameModesDirPath);
			return;
		}

		rz_print("Game modes directory '%s' was created", gameModesDirPath);
	}

	new start = rz_gamemodes_start();
	new end = start + size;
	new failedCount;
	new handle[RZ_MAX_HANDLE_LENGTH];
	new filePath[PLATFORM_MAX_PATH];

	for (new i = start; i < end; i++)
	{
		rz_gamemode_get(i, RZ_GAMEMODE_HANDLE, handle, charsmax(handle));
		formatex(filePath, charsmax(filePath), "%s/%s.json", gameModesDirPath, handle);

		if (file_exists(filePath))
		{
			g_iJsonHandle = json_parse(filePath, true);

			if (g_iJsonHandle == Invalid_JSON)
			{
				failedCount++;
				rz_log(true, "Error parsing game mode file '%s/%s.json'", GAMEMODES_DIRECTORY, handle);
				continue;
			}

			g_bCreating = false;
			g_iJsonHandleCopy = json_deep_copy(g_iJsonHandle);
		}
		else
		{
			g_bCreating = true;
			g_iJsonHandle = json_init_object();

			rz_print("Game mode file '%s/%s.json' was created", GAMEMODES_DIRECTORY, handle);
		}

		GameModePropField("name", i, RZ_GAMEMODE_NAME, RZ_MAX_LANGKEY_LENGTH);
		GameModePropField("notice", i, RZ_GAMEMODE_NOTICE, RZ_MAX_LANGKEY_LENGTH);
		GameModePropField("hud_color", i, RZ_GAMEMODE_HUD_COLOR, 16);
		GameModePropField("chance", i, RZ_GAMEMODE_CHANCE);
		GameModePropField("min_alives", i, RZ_GAMEMODE_MIN_ALIVES);
		GameModePropField("round_time", i, RZ_GAMEMODE_ROUND_TIME);
		GameModePropField("change_class", i, RZ_GAMEMODE_CHANGE_CLASS);
		GameModePropField("deathmatch", i, RZ_GAMEMODE_DEATHMATCH, 16);

		if (g_bCreating)
		{
			json_serial_to_file(g_iJsonHandle, filePath, true);
		}
		else if (!json_equals(g_iJsonHandle, g_iJsonHandleCopy))
		{
			json_serial_to_file(g_iJsonHandle, filePath, true);
			json_free(g_iJsonHandleCopy);
		}

		json_free(g_iJsonHandle);
	}

	if (failedCount)
		rz_print("Loaded %d game modes (%d failed)", size, failedCount);
	else
		rz_print("Loaded %d game modes", size);
}

GameModePropField(value[], gameMode, RZGameModeProp:prop, length = 0)
{
	switch (prop)
	{
		case RZ_GAMEMODE_NAME, RZ_GAMEMODE_NOTICE:
		{
			if (!g_bCreating && json_object_has_value(g_iJsonHandle, value, JSONString))
			{
				json_object_get_string(g_iJsonHandle, value, g_sTemp, length - 1);
				rz_gamemode_set(gameMode, prop, g_sTemp);
			}
			else
			{
				rz_gamemode_get(gameMode, prop, g_sTemp, length - 1);
				json_object_set_string(g_iJsonHandle, value, g_sTemp);
			}
		}
		case RZ_GAMEMODE_HUD_COLOR:
		{
			new colorInt[3];

			if (!g_bCreating && json_object_has_value(g_iJsonHandle, value, JSONString))
			{
				new color[3][4];

				json_object_get_string(g_iJsonHandle, value, g_sTemp, length - 1);

				if (parse(g_sTemp, color[0], charsmax(color[]), color[1], charsmax(color[]), color[2], charsmax(color[])) == 3)
				{
					colorInt[0] = str_to_num(color[0]);
					colorInt[1] = str_to_num(color[1]);
					colorInt[2] = str_to_num(color[2]);

					rz_gamemode_set(gameMode, prop, colorInt);
				}
				else
				{
					new handle[RZ_MAX_HANDLE_LENGTH];
					rz_gamemode_get(gameMode, RZ_GAMEMODE_HANDLE, handle, charsmax(handle));

					rz_log(true, "Error parsing property '%s' for game mode '%s'", value, handle);
				}
			}
			else
			{
				rz_gamemode_get(gameMode, prop, colorInt);
				json_object_set_string(g_iJsonHandle, value, fmt("%d %d %d", colorInt[0], colorInt[1], colorInt[2]));
			}
		}
		case RZ_GAMEMODE_CHANCE, RZ_GAMEMODE_MIN_ALIVES, RZ_GAMEMODE_ROUND_TIME:
		{
			if (!g_bCreating && json_object_has_value(g_iJsonHandle, value, JSONNumber))
			{
				g_iTemp = json_object_get_number(g_iJsonHandle, value);
				rz_gamemode_set(gameMode, prop, g_iTemp);
			}
			else
			{
				g_iTemp = rz_gamemode_get(gameMode, prop);
				json_object_set_number(g_iJsonHandle, value, g_iTemp);
			}
		}
		case RZ_GAMEMODE_CHANGE_CLASS:
		{
			if (!g_bCreating && json_object_has_value(g_iJsonHandle, value, JSONBoolean))
			{
				g_iTemp = json_object_get_bool(g_iJsonHandle, value);
				rz_gamemode_set(gameMode, prop, g_iTemp);
			}
			else
			{
				g_iTemp = rz_gamemode_get(gameMode, prop);
				json_object_set_bool(g_iJsonHandle, value, bool:g_iTemp);
			}
		}
		case RZ_GAMEMODE_DEATHMATCH:
		{
			if (!g_bCreating && json_object_has_value(g_iJsonHandle, value, JSONString))
			{
				json_object_get_string(g_iJsonHandle, value, g_sTemp, length - 1);
				rz_gamemode_set(gameMode, prop, getDeathMatchByStr(g_sTemp));
			}
			else
			{
				g_iTemp = rz_gamemode_get(gameMode, prop);
				json_object_set_string(g_iJsonHandle, value, getDeathMatchById(any:g_iTemp));
			}
		}
	}
}

getDeathMatchById(RZGameModeDeathmatch:i)
{
	new type[16];

	switch (i)
	{
		case RZ_GM_DEATHMATCH_DISABLED: type = "disabled";
		case RZ_GM_DEATHMATCH_ONLY_TR: type = "only_tr";
		case RZ_GM_DEATHMATCH_ONLY_CT: type = "only_ct";
		case RZ_GM_DEATHMATCH_RANDOM: type = "random";
		case RZ_GM_DEATHMATCH_BALANCE: type = "balance";
	}

	return type;
}

RZGameModeDeathmatch:getDeathMatchByStr(typeStr[])
{
	new RZGameModeDeathmatch:type;

	if (equal(typeStr, "only_tr"))
		type = RZ_GM_DEATHMATCH_ONLY_TR;
	else if (equal(typeStr, "only_ct"))
		type = RZ_GM_DEATHMATCH_ONLY_CT;
	else if (equal(typeStr, "random"))
		type = RZ_GM_DEATHMATCH_RANDOM;
	else if (equal(typeStr, "balance"))
		type = RZ_GM_DEATHMATCH_BALANCE;
	else
		type = RZ_GM_DEATHMATCH_DISABLED;

	return type;
}
