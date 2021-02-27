#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <reapi>
#include <rezp>
#include <json>

new const MAIN_CONFIG_FILE_NAME[] = "main";

new Array:g_aUselessEntities;

new g_iForward_Spawn_Pre;

public plugin_precache()
{
	register_plugin("[ReZP] Main", REZP_VERSION_STR, "fl0wer");

	register_cvar("rezp_version", REZP_VERSION_STR, FCVAR_SERVER | FCVAR_SPONLY);

	ModInfoPrint();
	LoadMainConfig();

	new skyName[64];
	rz_main_get(RZ_MAIN_SKY_NAME, skyName, charsmax(skyName));

	if (skyName[0])
	{
		new const sides[][] = { "bk", "dn", "ft", "lf", "rt", "up" };
		new filePath[PLATFORM_MAX_PATH];

		for (new i = 0; i < sizeof(sides); i++)
		{
			formatex(filePath, charsmax(filePath), "gfx/env/%s%s.tga", skyName, sides[i]);

			if (!file_exists(filePath))
				continue;

			precache_generic(filePath);
		}
	}
}

public plugin_init()
{
	register_srvcmd("rezp", "@Command_ReZPCommand");

	rz_load_langs("common");

	if (g_iForward_Spawn_Pre)
	{
		unregister_forward(FM_Spawn, g_iForward_Spawn_Pre, false);
		ArrayDestroy(g_aUselessEntities);
	}

	new gameDesc[64];
	rz_main_get(RZ_MAIN_GAME_DESC, gameDesc, charsmax(gameDesc));

	if (gameDesc[0])
	{
		set_member_game(m_GameDesc, gameDesc);
	}

	new skyName[32];
	rz_main_get(RZ_MAIN_SKY_NAME, skyName, charsmax(skyName));

	if (skyName[0])
	{
		set_cvar_string("sv_skyname", skyName);
		set_cvar_string("sv_skycolor_r", "0");
		set_cvar_string("sv_skycolor_g", "0");
		set_cvar_string("sv_skycolor_b", "0");
	}

	RegisterHookChain(RG_CGib_Spawn, "@CGib_Spawn_Post", true);
	
	set_member_game(m_bTCantBuy, true);
	set_member_game(m_bCTCantBuy, true);
}

@Command_ReZPCommand()
{
	new command[16];
	new argument[16];

	read_argv(1, command, charsmax(command));

	if (read_argc() > 2)
		read_argv(2, argument, charsmax(argument));

	if (equal(command, "list"))
	{
		if (equal(argument, "weapons"))
		{
			new i;
			new start = rz_weapons_start();
			new end = start + rz_weapons_size();
			new count;
			new handle[RZ_MAX_HANDLE_LENGTH];
			new reference[RZ_MAX_REFERENCE_LENGTH];

			server_print("^n   #  Index : Name (reference)^n");

			for (i = start; i < end; i++)
			{
				rz_weapon_get(i, RZ_WEAPON_HANDLE, handle, charsmax(handle));
				rz_weapon_get(i, RZ_WEAPON_REFERENCE, reference, charsmax(reference));

				server_print("%4d. %d  : %s (%s)", count + 1, i, handle, reference);
				count++;
			}

			start = rz_knifes_start();
			end = start + rz_knifes_size();

			for (i = start; i < end; i++)
			{
				rz_knife_get(i, RZ_KNIFE_HANDLE, handle, charsmax(handle));

				server_print("%4d. %d  : %s (%s)", count + 1, i, handle, "weapon_knife");
				count++;
			}

			start = rz_grenades_start();
			end = start + rz_grenades_size();

			for (i = start; i < end; i++)
			{
				rz_grenade_get(i, RZ_GRENADE_HANDLE, handle, charsmax(handle));
				rz_grenade_get(i, RZ_GRENADE_REFERENCE, reference, charsmax(reference));

				server_print("%4d. %d  : %s (%s)", count + 1, i, handle, reference);
				count++;
			}

			server_print("--------------^n%d Total %s^n", count, argument);
		}
		else
		{
			server_print("Usage: rezp list [ weapons ]");
		}
	}
	else
	{
		server_print("Usage: rezp < command > [ argument ]");
		server_print("Commands:");
		server_print("   list [ criteria ]          - list ones matching given search criteria");
	}
}

@Spawn_Pre(id)
{
	new classname[32];
	get_entvar(id, var_classname, classname, charsmax(classname));

	if (ArrayFindString(g_aUselessEntities, classname) != -1)
	{
		forward_return(FMV_CELL, -1);
		return FMRES_SUPERCEDE;
	}

	return FMRES_IGNORED;
}

@CGib_Spawn_Post(id)
{
	set_member(id, m_Gib_lifeTime, 0.0);
}

ModInfoPrint()
{
	new const infoKey[] = "rezp_info_printed";

	new infoValue[2];
	get_localinfo(infoKey, infoValue, charsmax(infoValue));

	if (infoValue[0])
		return;

	set_localinfo(infoKey, "1");

	server_print("   ");
	server_print("   Re Zombie Plague version %s Copyright (c) 2020 fl0wer", REZP_VERSION_STR);
	server_print("   Re Zombie Plague comes with ABSOLUTELY NO WARRANTY; for details type `amxx gpl'.");
	server_print("   This is free software and you are welcome to redistribute it under");
	server_print("   certain conditions; type 'amxx gpl' for details.");
	server_print("   ");
}

LoadMainConfig()
{
	new baseDirPath[PLATFORM_MAX_PATH];
	rz_get_configsdir(baseDirPath, charsmax(baseDirPath));

	if (!dir_exists(baseDirPath))
	{
		if (mkdir(baseDirPath) != 0)
		{
			rz_sys_error("Cannot create configuration directory '%s'", baseDirPath);
			return;
		}

		rz_print("Configuration directory '%s' was created", baseDirPath);
	}

	new bool:creating;
	new JSON:configJson;
	new JSON:configJsonCopy;
	new filePath[PLATFORM_MAX_PATH];

	formatex(filePath, charsmax(filePath), "%s/%s.json", baseDirPath, MAIN_CONFIG_FILE_NAME);

	if (file_exists(filePath))
	{
		configJson = json_parse(filePath, true);

		if (configJson == Invalid_JSON)
		{
			rz_sys_error("Error parsing file '%s'", filePath);
			return;
		}

		creating = false;
		configJsonCopy = json_deep_copy(configJson);
	}
	else
	{
		creating = true;
		configJson = json_init_object();

		rz_print("Configuration file '%s' was created", filePath);
	}

	ConfigField_String(creating, configJson, "server_browser_info", RZ_MAIN_GAME_DESC, 64, "Re Zombie Plague");
	ConfigField_String(creating, configJson, "sky_name", RZ_MAIN_SKY_NAME, 32, "blue");
	ConfigField_String(creating, configJson, "global_lighting", RZ_MAIN_GLOBAL_LIGHTING, 2, "c");
	ConfigField_String(creating, configJson, "nightvision_lighting", RZ_MAIN_NVG_LIGHTING, 2, "z");
	ConfigField_Boolean(creating, configJson, "roundover_ct_win", RZ_MAIN_ROUNDOVER_CT_WIN, false);
	ConfigField_Boolean(creating, configJson, "award_notice", RZ_MAIN_AWARD_NOTICE, true);
	ConfigField_String(creating, configJson, "chat_prefix", RZ_MAIN_CHAT_PREFIX, 32, "[RZ]");
	ConfigField_Number(creating, configJson, "prepare_time", RZ_MAIN_PREPARE_TIME, 20);
	ConfigField_Number(creating, configJson, "round_time", RZ_MAIN_ROUND_TIME, 180);
	ConfigField_Number(creating, configJson, "warmup_time", RZ_MAIN_WARMUP_TIME, 40);
	ConfigField_AmmoPacks(creating, configJson);
	ConfigField_UselessEntities(creating, configJson);

	if (creating)
	{
		json_serial_to_file(configJson, filePath, true);
	}
	else if (!json_equals(configJson, configJsonCopy))
	{
		json_serial_to_file(configJson, filePath, true);
		json_free(configJsonCopy);
	}

	json_free(configJson);

	rz_print("Loaded configuration file");
}

ConfigField_String(bool:creating, JSON:object, value[], RZMainProp:prop, length, defValue[])
{
	new tempValue[PLATFORM_MAX_PATH];
	copy(tempValue, length - 1, defValue);

	if (!creating && json_object_has_value(object, value, JSONString))
	{
		json_object_get_string(object, value, tempValue, length - 1);
		rz_main_set(prop, tempValue);
	}
	else
	{
		json_object_set_string(object, value, tempValue);
		rz_main_set(prop, tempValue);
	}

	switch (prop)
	{
		case RZ_MAIN_CHAT_PREFIX:
		{
			if (tempValue[0])
				rz_main_set(prop, fmt("^4%s ^1", tempValue));
		}
	}
}

ConfigField_Number(bool:creating, JSON:object, value[], RZMainProp:prop, defValue)
{
	if (!creating && json_object_has_value(object, value, JSONNumber))
	{
		rz_main_set(prop, json_object_get_number(object, value));
	}
	else
	{
		json_object_set_number(object, value, defValue);
		rz_main_set(prop, defValue);
	}
}

ConfigField_Boolean(bool:creating, JSON:object, value[], RZMainProp:prop, bool:defValue)
{
	if (!creating && json_object_has_value(object, value, JSONBoolean))
	{
		rz_main_set(prop, json_object_get_bool(object, value));
	}
	else
	{
		json_object_set_bool(object, value, defValue);
		rz_main_set(prop, defValue);
	}
}

ConfigField_AmmoPacks(creating, JSON:configJson, value[] = "ammopacks")
{
	new const enabledField[] = "enabled";
	new const joinAmountField[] = "join_amount";

	new joinAmount = 100;
	new bool:enabled = true;
	new JSON:jsonHandle;

	if (!creating && json_object_has_value(configJson, value, JSONObject))
	{
		jsonHandle = json_object_get_value(configJson, value);

		if (json_object_has_value(jsonHandle, enabledField, JSONBoolean))
			enabled = json_object_get_bool(jsonHandle, enabledField);
		else
			json_object_set_bool(jsonHandle, enabledField, enabled);

		if (json_object_has_value(jsonHandle, joinAmountField, JSONNumber))
			joinAmount = json_object_get_number(jsonHandle, joinAmountField);
		else
			json_object_set_number(jsonHandle, joinAmountField, joinAmount);
	}
	else
	{
		jsonHandle = json_init_object();

		json_object_set_bool(jsonHandle, enabledField, enabled);
		json_object_set_number(jsonHandle, joinAmountField, joinAmount);
	}

	rz_main_set(RZ_MAIN_AMMOPACKS_ENABLED, enabled);
	rz_main_set(RZ_MAIN_AMMOPACKS_JOIN_AMOUNT, joinAmount);

	json_object_set_value(configJson, value, jsonHandle);
	json_free(jsonHandle);
}

ConfigField_UselessEntities(creating, JSON:configJson, value[] = "useless_entities")
{
	new JSON:jsonHandle;
	new tempValue[32];

	g_aUselessEntities = ArrayCreate(32, 0);

	if (!creating && json_object_has_value(configJson, value, JSONArray))
	{
		jsonHandle = json_object_get_value(configJson, value);

		new arraySize = json_array_get_count(jsonHandle);

		for (new i = 0; i < arraySize; i++)
		{
			json_array_get_string(jsonHandle, i, tempValue, charsmax(tempValue));
			ArrayPushString(g_aUselessEntities, tempValue);
		}
	}
	else
	{
		jsonHandle = json_init_array();

		new const uselessEntities[][] =
		{
			"func_bomb_target",
			"info_bomb_target",
			"info_vip_start",
			"func_vip_safetyzone",
			"func_escapezone",
			"func_hostage_rescue",
			"info_hostage_rescue",
			"hostage_entity",
			"armoury_entity",
			"player_weaponstrip",
			"game_player_equip",
			"env_fog",
			"env_rain",
			"env_snow",
			"monster_scientist",
		};

		for (new i = 0; i < sizeof(uselessEntities); i++)
		{
			json_array_append_string(jsonHandle, uselessEntities[i]);
			ArrayPushString(g_aUselessEntities, uselessEntities[i]);
		}

		json_object_set_value(configJson, value, jsonHandle);
	}

	if (ArraySize(g_aUselessEntities))
		g_iForward_Spawn_Pre = register_forward(FM_Spawn, "@Spawn_Pre", false);
	else
		ArrayDestroy(g_aUselessEntities);

	json_free(jsonHandle);
}
