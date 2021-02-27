#pragma semicolon 1

#include <amxmodx>
#include <rezp>
/*
	if (!get_member_game(m_bGameStarted))
		return false;

	if (!get_member_game(m_bFreezePeriod))
		return false;
	
	new bool:force = bool:get_param(arg_force);

	g_iForceGameMode = gameMode;

	if (force)
		set_member_game(m_iRoundTimeSecs, 0);
*/

enum _:GameModeData
{
	GameMode_Handle[RZ_MAX_HANDLE_LENGTH],
	GameMode_Name[RZ_MAX_LANGKEY_LENGTH],
	GameMode_Notice[RZ_MAX_LANGKEY_LENGTH],
	GameMode_HudColor[3],
	GameMode_Chance,
	GameMode_MinAlives,
	GameMode_RoundTime,
	bool:GameMode_ChangeClass,
	RZGameModeDeathmatch:GameMode_Deathmatch,

}; new Array:g_aGameModes;

new gGameModeData[GameModeData];

enum _:Forwards
{
	Fw_Return,
	Fw_GameModes_Change_Pre,
	Fw_GameModes_Change_Post,

}; new gForwards[Forwards];

new gGameModes[RZGameModesProp];

new g_iModule;

public plugin_precache()
{
	register_plugin("[ReZP] API: Game Modes", REZP_VERSION_STR, "fl0wer");

	g_aGameModes = ArrayCreate(GameModeData, 0);
	g_iModule = rz_module_create("game_mode", g_aGameModes);
}

public plugin_init()
{
	gForwards[Fw_GameModes_Change_Pre] = CreateMultiForward("rz_gamemodes_change_pre", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL);
	gForwards[Fw_GameModes_Change_Post] = CreateMultiForward("rz_gamemodes_change_post", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL);
}

ChangeGameMode(gameMode, bool:force = false)
{
	new Array:alivesArray = ArrayCreate(1, 0);

	for (new i = 1; i <= MaxClients; i++)
	{
		if (!is_user_alive(i))
			continue;

		ArrayPushCell(alivesArray, i);
	}

	ExecuteForward(gForwards[Fw_GameModes_Change_Pre], gForwards[Fw_Return], gameMode, ArraySize(alivesArray), force);

	if (gForwards[Fw_Return] >= RZ_SUPERCEDE)
	{
		ArrayDestroy(alivesArray);
		return false;
	}

	ExecuteForward(gForwards[Fw_GameModes_Change_Post], gForwards[Fw_Return], gameMode, alivesArray, force);
	ArrayDestroy(alivesArray);

	return true;
}

public plugin_natives()
{
	register_native("rz_gamemode_create", "@native_gamemode_create");
	register_native("rz_gamemode_get", "@native_gamemode_get");
	register_native("rz_gamemode_set", "@native_gamemode_set");

	register_native("rz_gamemodes_get", "@native_gamemodes_get");
	register_native("rz_gamemodes_set", "@native_gamemodes_set");
	register_native("rz_gamemodes_start", "@native_gamemodes_start");
	register_native("rz_gamemodes_find", "@native_gamemodes_find");
	register_native("rz_gamemodes_size", "@native_gamemodes_size");
	register_native("rz_gamemodes_change", "@native_gamemodes_change");
	register_native("rz_gamemodes_get_status", "@native_gamemodes_get_status");
}

@native_gamemode_create(plugin, argc)
{
	enum { arg_handle = 1 };

	new data[GameModeData];

	get_string(arg_handle, data[GameMode_Handle], charsmax(data[GameMode_Handle]));

	new id = ArrayPushArray(g_aGameModes, data) + rz_module_get_offset(g_iModule);

	if (!gGameModes[RZ_GAMEMODES_DEFAULT])
		gGameModes[RZ_GAMEMODES_DEFAULT] = id;

	return id;
}

@native_gamemode_get(plugin, argc)
{
	enum { arg_game_mode = 1, arg_prop, arg_3, arg_4 };

	new gameMode = get_param(arg_game_mode);
	new index = rz_module_get_valid_index(g_iModule, gameMode);

	RZ_CHECK_MODULE_VALID_INDEX(index, false)
	
	ArrayGetArray(g_aGameModes, index, gGameModeData);

	new prop = get_param(arg_prop);

	switch (prop)
	{
		case RZ_GAMEMODE_HANDLE:
		{
			set_string(arg_3, gGameModeData[GameMode_Handle], get_param_byref(arg_4));
		}
		case RZ_GAMEMODE_NAME:
		{
			set_string(arg_3, gGameModeData[GameMode_Name], get_param_byref(arg_4));
		}
		case RZ_GAMEMODE_NOTICE:
		{
			set_string(arg_3, gGameModeData[GameMode_Notice], get_param_byref(arg_4));
		}
		case RZ_GAMEMODE_HUD_COLOR:
		{
			set_array(arg_3, gGameModeData[GameMode_HudColor], sizeof(gGameModeData[GameMode_HudColor]));
		}
		case RZ_GAMEMODE_CHANCE:
		{
			return gGameModeData[GameMode_Chance];
		}
		case RZ_GAMEMODE_MIN_ALIVES:
		{
			return gGameModeData[GameMode_MinAlives];
		}
		case RZ_GAMEMODE_ROUND_TIME:
		{
			return gGameModeData[GameMode_RoundTime];
		}
		case RZ_GAMEMODE_CHANGE_CLASS:
		{
			return gGameModeData[GameMode_ChangeClass];
		}
		case RZ_GAMEMODE_DEATHMATCH:
		{
			return any:gGameModeData[GameMode_Deathmatch];
		}
		default:
		{
			rz_log(true, "Game mode property '%d' not found for '%s'", prop, gGameModeData[GameMode_Handle]);
			return false;
		}
	}

	return true;
}

@native_gamemode_set(plugin, argc)
{
	enum { arg_game_mode = 1, arg_prop, arg_3 };

	new gameMode = get_param(arg_game_mode);
	new index = rz_module_get_valid_index(g_iModule, gameMode);

	RZ_CHECK_MODULE_VALID_INDEX(index, false)
	
	ArrayGetArray(g_aGameModes, index, gGameModeData);

	new prop = get_param(arg_prop);

	switch (prop)
	{
		case RZ_GAMEMODE_HANDLE:
		{
			get_string(arg_3, gGameModeData[GameMode_Handle], charsmax(gGameModeData[GameMode_Handle]));
		}
		case RZ_GAMEMODE_NAME:
		{
			get_string(arg_3, gGameModeData[GameMode_Name], charsmax(gGameModeData[GameMode_Name]));
		}
		case RZ_GAMEMODE_NOTICE:
		{
			get_string(arg_3, gGameModeData[GameMode_Notice], charsmax(gGameModeData[GameMode_Notice]));
		}
		case RZ_GAMEMODE_HUD_COLOR:
		{
			get_array(arg_3, gGameModeData[GameMode_HudColor], sizeof(gGameModeData[GameMode_HudColor]));
		}
		case RZ_GAMEMODE_CHANCE:
		{
			gGameModeData[GameMode_Chance] = get_param_byref(arg_3);
		}
		case RZ_GAMEMODE_MIN_ALIVES:
		{
			gGameModeData[GameMode_MinAlives] = get_param_byref(arg_3);
		}
		case RZ_GAMEMODE_ROUND_TIME:
		{
			gGameModeData[GameMode_RoundTime] = get_param_byref(arg_3);
		}
		case RZ_GAMEMODE_CHANGE_CLASS:
		{
			gGameModeData[GameMode_ChangeClass] = bool:get_param_byref(arg_3);
		}
		case RZ_GAMEMODE_DEATHMATCH:
		{
			gGameModeData[GameMode_Deathmatch] = any:get_param_byref(arg_3);
		}
		default:
		{
			rz_log(true, "Game mode property '%d' not found for '%s'", prop, gGameModeData[GameMode_Handle]);
			return false;
		}
	}

	ArraySetArray(g_aGameModes, index, gGameModeData);
	return true;
}

@native_gamemodes_get(plugin, argc)
{
	enum { arg_prop = 1 };

	new RZGameModesProp:prop = any:get_param(arg_prop);

	switch (prop)
	{
		case RZ_GAMEMODES_DEFAULT, RZ_GAMEMODES_CURRENT, RZ_GAMEMODES_LAST, RZ_GAMEMODES_FORCE:
		{
			return gGameModes[prop];
		}
		default:
		{
			rz_log(true, "Game modes property '%d'", prop);
			return false;
		}
	}

	return true;
}

@native_gamemodes_set(plugin, argc)
{
	enum { arg_prop = 1, arg_2 };

	new RZGameModesProp:prop = any:get_param(arg_prop);

	switch (prop)
	{
		case RZ_GAMEMODES_DEFAULT, RZ_GAMEMODES_CURRENT, RZ_GAMEMODES_LAST, RZ_GAMEMODES_FORCE:
		{
			gGameModes[prop] = get_param_byref(arg_2);
		}
		default:
		{
			rz_log(true, "Game modes property '%d'", prop);
			return false;
		}
	}

	return true;
}

@native_gamemodes_start(plugin, argc)
{
	return rz_module_get_offset(g_iModule);
}

@native_gamemodes_find(plugin, argc)
{
	enum { arg_handle = 1 };

	new handle[RZ_MAX_HANDLE_LENGTH];
	get_string(arg_handle, handle, charsmax(handle));

	new i = ArrayFindString(g_aGameModes, handle);

	if (i != -1)
		return i + rz_module_get_offset(g_iModule);

	return 0;
}

@native_gamemodes_size(plugin, argc)
{
	return ArraySize(g_aGameModes);
}

@native_gamemodes_change(plugin, argc)
{
	enum { arg_game_mode = 1 };

	new gameMode = get_param(arg_game_mode);
	new index = rz_module_get_valid_index(g_iModule, gameMode);

	RZ_CHECK_MODULE_VALID_INDEX(index, false)

	return ChangeGameMode(gameMode);
}

@native_gamemodes_get_status(plugin, argc)
{
	enum { arg_game_mode = 1, arg_force };

	new gameMode = get_param(arg_game_mode);
	new index = rz_module_get_valid_index(g_iModule, gameMode);

	RZ_CHECK_MODULE_VALID_INDEX(index, RZ_BREAK)

	ExecuteForward(gForwards[Fw_GameModes_Change_Pre], gForwards[Fw_Return], gameMode, rz_game_get_alivesnum(), any:get_param(arg_force));
	return gForwards[Fw_Return];
}
