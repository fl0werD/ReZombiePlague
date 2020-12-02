#pragma semicolon 1

#include <amxmodx>
#include <reapi>
#include <rezp>
#include <rezp_util>

const GAMEMODE_LAUNCH_MINALIVES = 2;

enum _:GameModeData
{
	GameMode_Name[32],
	GameMode_NameLangKey[32],
	GameMode_NoticeLangKey[32],
	GameMode_HudColor[3],
	GameMode_Chance,
	GameMode_MinAlives,
	GameMode_RoundTime,

}; new Array:g_aGameModes;

enum _:Forwards
{
	Fw_Return,
	Fw_GameMode_Start_Pre,
	Fw_GameMode_Start_Post,

}; new gForwards[Forwards];

new g_iDefaultGameMode;
new g_iCurrentGameMode;
new g_iLastGameMode;
new g_iForceGameMode;

new g_iModule;

new Float:rz_gamemode_notice_hud_pos[2];

public plugin_precache()
{
	register_plugin("[ReZP] Game Mode", REZP_VERSION_STR, "fl0wer");

	g_aGameModes = ArrayCreate(GameModeData, 0);
	g_iModule = rz_module_create("game_mode", g_aGameModes);

	bind_pcvar_float(create_cvar("rz_gamemode_notice_hud_x", "-1.0", _, "", true, -1.0, true, 1.0), rz_gamemode_notice_hud_pos[0]);
	bind_pcvar_float(create_cvar("rz_gamemode_notice_hud_y", "0.17", _, "", true, -1.0, true, 1.0), rz_gamemode_notice_hud_pos[1]);
}

public plugin_init()
{
	RegisterHookChain(RG_CSGameRules_RestartRound, "@CSGameRules_RestartRound_Pre", false);
	RegisterHookChain(RG_CSGameRules_OnRoundFreezeEnd, "@CSGameRules_OnRoundFreezeEnd_Pre", false);
	
	gForwards[Fw_GameMode_Start_Pre] = CreateMultiForward("rz_gamemode_start_pre", ET_CONTINUE, FP_CELL);
	gForwards[Fw_GameMode_Start_Post] = CreateMultiForward("rz_gamemode_start_post", ET_IGNORE, FP_CELL, FP_CELL);

	rz_load_langs("gamemode");
}

public plugin_cfg()
{
	if (!ArraySize(g_aGameModes))
		rz_sys_error("No loaded game modes");
}

@CSGameRules_RestartRound_Pre()
{
	rz_main_lighting_global_reset();
	rz_main_lighting_nvg_reset();

	g_iCurrentGameMode = 0;
	g_iForceGameMode = 0;

	for (new TeamName:i = TEAM_TERRORIST; i <= TEAM_CT; i++)
		rz_class_override_default(i, 0);
}

@CSGameRules_OnRoundFreezeEnd_Pre()
{
	if (!get_member_game(m_bGameStarted))
		return;

	new Array:alivesArray = ArrayCreate(1, 0);

	for (new i = 1; i <= MaxClients; i++)
	{
		if (!is_user_alive(i))
			continue;

		ArrayPushCell(alivesArray, i);
	}

	new alivesNum = ArraySize(alivesArray);

	if (alivesNum >= GAMEMODE_LAUNCH_MINALIVES)
		LaunchGameMode(alivesArray);

	ArrayDestroy(alivesArray);
}

LaunchGameMode(Array:alivesArray)
{
	new mode;
	new gameModeData[GameModeData];

	if (g_iForceGameMode)
	{
		if (CanLaunchGameMode(g_iForceGameMode, true))
			mode = g_iForceGameMode;
	}

	if (!mode)
	{
		new gameModesNum = ArraySize(g_aGameModes);
		//new Array:gameModes = ArrayCreate(1, 0);
		new gameMode;

		for (new i = 0; i < gameModesNum; i++)
		{
			gameMode = i + rz_module_get_offset(g_iModule);

			if (!CanLaunchGameMode(gameMode))
				continue;

			//ArrayPushCell(gameModes, gameMode);
			mode = gameMode;
			break;
		}

		/*gameModesNum = ArraySize(gameModes);

		if (gameModesNum)
			mode = ArrayGetCell(gameModes, random_num(0, gameModesNum - 1));

		ArrayDestroy(gameModes);*/
	}

	if (!mode)
		mode = g_iDefaultGameMode;
	
	g_iCurrentGameMode = mode;
	g_iLastGameMode = mode;

	ArrayGetArray(g_aGameModes, mode - rz_module_get_offset(g_iModule), gameModeData);

	set_dhudmessage(gameModeData[GameMode_HudColor][0], gameModeData[GameMode_HudColor][1], gameModeData[GameMode_HudColor][2],
		rz_gamemode_notice_hud_pos[0], rz_gamemode_notice_hud_pos[1],
		0, 0.0, 5.0, 1.0, 1.0);
	show_dhudmessage(0, "%L", LANG_PLAYER, "RZ_GAMEMODE_FMT", LANG_PLAYER, gameModeData[GameMode_NoticeLangKey]);

	if (gameModeData[GameMode_RoundTime])
		set_member_game(m_iRoundTime, gameModeData[GameMode_RoundTime]);

	ExecuteForward(gForwards[Fw_GameMode_Start_Post], gForwards[Fw_Return], mode, alivesArray);
}

CanLaunchGameMode(gameMode, bool:force = false)
{
	new alivesNum = rz_game_get_alivesnum();
	new gameModeData[GameModeData];
	ArrayGetArray(g_aGameModes, gameMode - rz_module_get_offset(g_iModule), gameModeData);

	if (alivesNum < GAMEMODE_LAUNCH_MINALIVES)
		return false;

	if (alivesNum < gameModeData[GameMode_MinAlives])
		return false;

	if (!force)
	{
		if (g_iLastGameMode == gameMode)
			return false;

		if (gameModeData[GameMode_Chance])
		{
			if(random_num(1, gameModeData[GameMode_Chance]) != 1)
				return false;
		}
	}

	ExecuteForward(gForwards[Fw_GameMode_Start_Pre], gForwards[Fw_Return], gameMode);

	if (gForwards[Fw_Return] >= RZ_SUPERCEDE)
		return false;

	return true;
}

public plugin_natives()
{
	register_native("rz_gamemode_create", "@native_gamemode_create");
	register_native("rz_gamemode_get_name", "@native_gamemode_get_name");

	register_native("rz_gamemode_get_name_langkey", "@native_gamemode_get_name_langkey");
	register_native("rz_gamemode_set_name_langkey", "@native_gamemode_set_name_langkey");

	register_native("rz_gamemode_get_notice_langkey", "@native_gamemode_get_notice_langkey");
	register_native("rz_gamemode_set_notice_langkey", "@native_gamemode_set_notice_langkey");

	register_native("rz_gamemode_get_hudcolor", "@native_gamemode_get_hudcolor");
	register_native("rz_gamemode_set_hudcolor", "@native_gamemode_set_hudcolor");

	register_native("rz_gamemode_get_chance", "@native_gamemode_get_chance");
	register_native("rz_gamemode_set_chance", "@native_gamemode_set_chance");

	register_native("rz_gamemode_get_minalives", "@native_gamemode_get_minalives");
	register_native("rz_gamemode_set_minalives", "@native_gamemode_set_minalives");

	register_native("rz_gamemode_get_roundtime", "@native_gamemode_get_roundtime");
	register_native("rz_gamemode_set_roundtime", "@native_gamemode_set_roundtime");

	register_native("rz_gamemode_get_default", "@native_gamemode_get_default");
	register_native("rz_gamemode_set_default", "@native_gamemode_set_default");

	register_native("rz_gamemode_get_current", "@native_gamemode_get_current");
	register_native("rz_gamemode_can_launch", "@native_gamemode_can_launch");
	register_native("rz_gamemode_set_force", "@native_gamemode_set_force");

	register_native("rz_gamemode_start", "@native_gamemode_start");
	register_native("rz_gamemode_find", "@native_gamemode_find");
	register_native("rz_gamemode_size", "@native_gamemode_size");
}

@native_gamemode_create(plugin, argc)
{
	enum { arg_name = 1 };

	new data[GameModeData];

	get_string(arg_name, data[GameMode_Name], charsmax(data[GameMode_Name]));

	new id = ArrayPushArray(g_aGameModes, data) + rz_module_get_offset(g_iModule);

	if (!g_iDefaultGameMode)
		g_iDefaultGameMode = id;

	return id;
}

@native_gamemode_get_name(plugin, argc)
{
	enum { arg_game_mode = 1, arg_name, arg_len };

	new gameMode = get_param(arg_game_mode);
	new index = rz_module_get_valid_index(g_iModule, gameMode);

	CHECK_MODULE_VALID_INDEX(index, false)
	
	new data[GameModeData];
	ArrayGetArray(g_aGameModes, index, data);

	set_string(arg_name, data[GameMode_Name], get_param(arg_len));
	return true;
}

@native_gamemode_get_name_langkey(plugin, argc)
{
	enum { arg_game_mode = 1, arg_name_lang_key, arg_len };

	new gameMode = get_param(arg_game_mode);
	new index = rz_module_get_valid_index(g_iModule, gameMode);

	CHECK_MODULE_VALID_INDEX(index, false)
	
	new data[GameModeData];
	ArrayGetArray(g_aGameModes, index, data);

	if (!data[GameMode_NameLangKey][0])
		return false;

	set_string(arg_name_lang_key, data[GameMode_NameLangKey], get_param(arg_len));
	return true;
}

@native_gamemode_set_name_langkey(plugin, argc)
{
	enum { arg_game_mode = 1, arg_name_lang_key };

	new gameMode = get_param(arg_game_mode);
	new index = rz_module_get_valid_index(g_iModule, gameMode);

	CHECK_MODULE_VALID_INDEX(index, false)
	
	new data[GameModeData];
	ArrayGetArray(g_aGameModes, index, data);
	get_string(arg_name_lang_key, data[GameMode_NameLangKey], charsmax(data[GameMode_NameLangKey]));
	ArraySetArray(g_aGameModes, index, data);

	return true;
}

@native_gamemode_get_notice_langkey(plugin, argc)
{
	enum { arg_game_mode = 1, arg_notice_lang_key, arg_len };

	new gameMode = get_param(arg_game_mode);
	new index = rz_module_get_valid_index(g_iModule, gameMode);

	CHECK_MODULE_VALID_INDEX(index, false)
	
	new data[GameModeData];
	ArrayGetArray(g_aGameModes, index, data);

	if (!data[GameMode_NoticeLangKey][0])
		return false;

	set_string(arg_notice_lang_key, data[GameMode_NoticeLangKey], get_param(arg_len));
	return true;
}

@native_gamemode_set_notice_langkey(plugin, argc)
{
	enum { arg_game_mode = 1, arg_notice_lang_key };

	new gameMode = get_param(arg_game_mode);
	new index = rz_module_get_valid_index(g_iModule, gameMode);

	CHECK_MODULE_VALID_INDEX(index, false)
	
	new data[GameModeData];
	ArrayGetArray(g_aGameModes, index, data);
	get_string(arg_notice_lang_key, data[GameMode_NoticeLangKey], charsmax(data[GameMode_NoticeLangKey]));
	ArraySetArray(g_aGameModes, index, data);

	return true;
}

@native_gamemode_get_hudcolor(plugin, argc)
{
	enum { arg_game_mode = 1, arg_hud_color };

	new gameMode = get_param(arg_game_mode);
	new index = rz_module_get_valid_index(g_iModule, gameMode);

	CHECK_MODULE_VALID_INDEX(index, false)
	
	new data[GameModeData];
	ArrayGetArray(g_aGameModes, index, data);

	set_array(arg_hud_color, data[GameMode_HudColor], sizeof(data[GameMode_HudColor]));
	return true;
}

@native_gamemode_set_hudcolor(plugin, argc)
{
	enum { arg_game_mode = 1, arg_hud_color };

	new gameMode = get_param(arg_game_mode);
	new index = rz_module_get_valid_index(g_iModule, gameMode);

	CHECK_MODULE_VALID_INDEX(index, false)
	
	new data[GameModeData];
	ArrayGetArray(g_aGameModes, index, data);
	get_array(arg_hud_color, data[GameMode_HudColor], sizeof(data[GameMode_HudColor]));
	ArraySetArray(g_aGameModes, index, data);

	return true;
}

@native_gamemode_get_chance(plugin, argc)
{
	enum { arg_game_mode = 1 };

	new gameMode = get_param(arg_game_mode);
	new index = rz_module_get_valid_index(g_iModule, gameMode);

	CHECK_MODULE_VALID_INDEX(index, 0)

	new data[GameModeData];
	ArrayGetArray(g_aGameModes, index, data);

	return data[GameMode_Chance];
}

@native_gamemode_set_chance(plugin, argc)
{
	enum { arg_game_mode = 1, arg_chance };

	new gameMode = get_param(arg_game_mode);
	new index = rz_module_get_valid_index(g_iModule, gameMode);

	CHECK_MODULE_VALID_INDEX(index, 0)

	new data[GameModeData];
	ArrayGetArray(g_aGameModes, index, data);
	data[GameMode_Chance] = get_param(arg_chance);
	ArraySetArray(g_aGameModes, index, data);

	return true;
}

@native_gamemode_get_minalives(plugin, argc)
{
	enum { arg_game_mode = 1 };

	new gameMode = get_param(arg_game_mode);
	new index = rz_module_get_valid_index(g_iModule, gameMode);

	CHECK_MODULE_VALID_INDEX(index, 0)

	new data[GameModeData];
	ArrayGetArray(g_aGameModes, index, data);

	return data[GameMode_MinAlives];
}

@native_gamemode_set_minalives(plugin, argc)
{
	enum { arg_game_mode = 1, arg_players_num };

	new gameMode = get_param(arg_game_mode);
	new index = rz_module_get_valid_index(g_iModule, gameMode);

	CHECK_MODULE_VALID_INDEX(index, 0)

	new data[GameModeData];
	ArrayGetArray(g_aGameModes, index, data);
	data[GameMode_MinAlives] = get_param(arg_players_num);
	ArraySetArray(g_aGameModes, index, data);

	return true;
}

@native_gamemode_get_roundtime(plugin, argc)
{
	enum { arg_game_mode = 1 };

	new gameMode = get_param(arg_game_mode);
	new index = rz_module_get_valid_index(g_iModule, gameMode);

	CHECK_MODULE_VALID_INDEX(index, 0)

	new data[GameModeData];
	ArrayGetArray(g_aGameModes, index, data);

	return data[GameMode_RoundTime];
}

@native_gamemode_set_roundtime(plugin, argc)
{
	enum { arg_game_mode = 1, arg_seconds };

	new gameMode = get_param(arg_game_mode);
	new index = rz_module_get_valid_index(g_iModule, gameMode);

	CHECK_MODULE_VALID_INDEX(index, 0)

	new data[GameModeData];
	ArrayGetArray(g_aGameModes, index, data);
	data[GameMode_RoundTime] = get_param(arg_seconds);
	ArraySetArray(g_aGameModes, index, data);

	return true;
}

@native_gamemode_get_default(plugin, argc)
{
	return g_iDefaultGameMode;
}

@native_gamemode_set_default(plugin, argc)
{
	enum { arg_game_mode = 1 };

	new gameMode = get_param(arg_game_mode);
	new index = rz_module_get_valid_index(g_iModule, gameMode);

	CHECK_MODULE_VALID_INDEX(index, false)

	g_iDefaultGameMode = gameMode;
	return true;
}

@native_gamemode_get_current(plugin, argc)
{
	return g_iCurrentGameMode;
}

@native_gamemode_can_launch(plugin, argc)
{
	enum { arg_game_mode = 1 };

	new gameMode = get_param(arg_game_mode);
	new index = rz_module_get_valid_index(g_iModule, gameMode);

	CHECK_MODULE_VALID_INDEX(index, false)

	if (!CanLaunchGameMode(gameMode, true))
		return false;

	return true;
}

@native_gamemode_set_force(plugin, argc)
{
	enum { arg_game_mode = 1, arg_force };

	new gameMode = get_param(arg_game_mode);
	new index = rz_module_get_valid_index(g_iModule, gameMode);

	CHECK_MODULE_VALID_INDEX(index, false)

	if (!get_member_game(m_bGameStarted))
		return false;

	if (!get_member_game(m_bFreezePeriod))
		return false;
	
	new bool:force = bool:get_param(arg_force);

	g_iForceGameMode = gameMode;

	if (force)
		set_member_game(m_iRoundTimeSecs, 0);

	return true;
}

@native_gamemode_start(plugin, argc)
{
	return rz_module_get_offset(g_iModule);
}

@native_gamemode_find(plugin, argc)
{
	enum { arg_name = 1 };

	new name[32];
	get_string(arg_name, name, charsmax(name));

	new i = ArrayFindString(g_aGameModes, name);

	if (i != -1)
		return i + rz_module_get_offset(g_iModule);

	return 0;
}

@native_gamemode_size(plugin, argc)
{
	return ArraySize(g_aGameModes);
}
