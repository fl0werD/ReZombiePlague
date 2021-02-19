#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <reapi>
#include <rezp>
#include <json>



enum ConfigData
{
	GAME_DESC[64],
	SKY_NAME[32],
	GLOBAL_LIGHTING[2],
	NVG_LIGHTING[2],
	bool:ROUNDOVER_CT_WIN,
	bool:AWARD_NOTICE,
	CHAT_PREFIX[32],
	PREPARE_TIME,
	ROUND_TIME,
	bool:WARMUP_ENABLED,
	WARMUP_TIME,
	bool:AMMOPACKS_ENABLED,
	AMMOPACKS_JOIN_AMT,

}; new gConfigData[ConfigData];

enum _:ModuleData
{
	Module_Name[32],
	Module_Offset,
	Array:Module_Handle,

}; new Array:g_aModules;

new g_sGlobalLightingTemp[2];
new g_sNVGLightingTemp[2];

new Array:g_aUselessEntities;

new g_iForward_Spawn_Pre;

public plugin_precache()
{
	register_plugin("[ReZP] Main", REZP_VERSION_STR, "fl0wer");

	ModInfoPrint();
	LoadMainConfig();

	register_cvar("rezp_version", REZP_VERSION_STR, FCVAR_SERVER | FCVAR_SPONLY);

	g_aModules = ArrayCreate(ModuleData, konskaya1337);
}

public plugin_init()
{
	rz_load_langs("common");

	if (g_iForward_Spawn_Pre)
	{
		unregister_forward(FM_Spawn, g_iForward_Spawn_Pre, false);
		ArrayDestroy(g_aUselessEntities);
	}

	if (gConfigData[GAME_DESC][0])
	{
		set_member_game(m_GameDesc, gConfigData[GAME_DESC]);
	}

	if (gConfigData[SKY_NAME][0])
	{
		set_cvar_string("sv_skyname", gConfigData[SKY_NAME]);
		set_cvar_string("sv_skycolor_r", "0");
		set_cvar_string("sv_skycolor_g", "0");
		set_cvar_string("sv_skycolor_b", "0");
	}

	RegisterHookChain(RG_CGib_Spawn, "@CGib_Spawn_Post", true);
	
	set_member_game(m_bTCantBuy, true);
	set_member_game(m_bCTCantBuy, true);
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

PrecacheSkyByName(const name[])
{
	new const skySides[][] = { "bk", "dn", "ft", "lf", "rt", "up" };
	new skySideFilePath[PLATFORM_MAX_PATH];

	for (new i = 0; i < sizeof(skySides); i++)
	{
		formatex(skySideFilePath, charsmax(skySideFilePath), "gfx/env/%s%s.tga", name, skySides[i]);

		if (!file_exists(skySideFilePath))
			continue;

		precache_generic(skySideFilePath);
	}
}

LoadLangs(const name[])
{
	new langsNum = get_langsnum();
	new langName[3];
	new filePath[PLATFORM_MAX_PATH];

	get_localinfo("amxx_datadir", filePath, charsmax(filePath));
	add(filePath, charsmax(filePath), "/lang/rezp");

	for (new i = 0; i < langsNum; i++)
	{
		get_lang(i, langName);

		if (!file_exists(fmt("%s/%s/%s.txt", filePath, langName, name)))
			continue;

		register_dictionary(fmt("rezp/%s/%s.txt", langName, name));
	}
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
	new filePath[PLATFORM_MAX_PATH];
	get_localinfo("amxx_configsdir", filePath, charsmax(filePath));
	add(filePath, charsmax(filePath), "/rezp");

	if (!dir_exists(filePath))
	{
		set_fail_state("Configuration directory '%s' not found", filePath);
		return;
	}

	add(filePath, charsmax(filePath), "/main.json");

	if (!file_exists(filePath))
	{
		set_fail_state("Configuration file '%s' not found", filePath);
		return;
	}

	new JSON:config = json_parse(filePath, true);

	if (config == Invalid_JSON)
	{
		set_fail_state("Parsing file '%s' error", filePath);
		return;
	}

	new temp[32];

	json_object_get_string(config, "server_browser_info", temp, charsmax(temp));
	copy(gConfigData[GAME_DESC], charsmax(gConfigData[GAME_DESC]), temp);

	new JSON:skyNameArray = json_object_get_value(config, "custom_sky_names");

	if (json_is_array(skyNameArray))
	{
		json_array_get_string(skyNameArray, random_num(0, json_array_get_count(skyNameArray) - 1), temp, charsmax(temp));
		json_free(skyNameArray);
	}
	else
	{
		json_object_get_string(config, "custom_sky_names", temp, charsmax(temp));
	}

	if (temp[0])
	{
		PrecacheSkyByName(temp);
		copy(gConfigData[SKY_NAME], charsmax(gConfigData[SKY_NAME]), temp);
	}

	json_object_get_string(config, "global_lighting", temp, charsmax(temp));
	copy(gConfigData[GLOBAL_LIGHTING], charsmax(gConfigData[GLOBAL_LIGHTING]), temp);

	json_object_get_string(config, "nightvision_lighting", temp, charsmax(temp));
	copy(gConfigData[NVG_LIGHTING], charsmax(gConfigData[NVG_LIGHTING]), temp);

	gConfigData[ROUNDOVER_CT_WIN] = json_object_get_bool(config, "roundover_ct_win");
	gConfigData[AWARD_NOTICE] = json_object_get_bool(config, "award_notice");

	json_object_get_string(config, "chat_prefix", temp, charsmax(temp));

	if (temp[0])
		copy(gConfigData[CHAT_PREFIX], charsmax(gConfigData[CHAT_PREFIX]), fmt("^4%s ^1", temp));

	gConfigData[PREPARE_TIME] = json_object_get_number(config, "prepare_time");
	gConfigData[ROUND_TIME] = json_object_get_number(config, "round_time");

	new JSON:warmup = json_object_get_value(config, "warmup");

	if (json_is_object(warmup))
	{
		gConfigData[WARMUP_ENABLED] = json_object_get_bool(warmup, "enabled");
		gConfigData[WARMUP_TIME] = json_object_get_number(warmup, "time");
		
		json_free(warmup);
	}

	new JSON:ammoPacks = json_object_get_value(config, "ammopacks");

	if (json_is_object(ammoPacks))
	{
		gConfigData[AMMOPACKS_ENABLED] = json_object_get_bool(ammoPacks, "enabled");
		gConfigData[AMMOPACKS_JOIN_AMT] = json_object_get_number(ammoPacks, "join_amount");

		json_free(ammoPacks);
	}

	new JSON:uselessEntities = json_object_get_value(config, "useless_entities");

	if (json_is_array(uselessEntities))
	{
		g_aUselessEntities = ArrayCreate(32, 0);

		new arraySize = json_array_get_count(uselessEntities);

		for (new i = 0; i < arraySize; i++)
		{
			json_array_get_string(uselessEntities, i, temp, charsmax(temp));
			ArrayPushString(g_aUselessEntities, temp);
		}

		json_free(uselessEntities);

		if (ArraySize(g_aUselessEntities))
			g_iForward_Spawn_Pre = register_forward(FM_Spawn, "@Spawn_Pre", false);
		else
			ArrayDestroy(g_aUselessEntities);
	}
	
	json_free(config);

	server_print("ReZombiePlague Configuration File Successfully Executed");
}

public plugin_natives()
{
	ExecuteForward(CreateMultiForward("__rezp_version_check", ET_IGNORE, FP_STRING, FP_STRING), _, REZP_VERSION_MAJOR, REZP_VERSION_MINOR);

	register_native("rz_load_langs", "@native_load_langs");
	register_native("rz_print_chat", "@native_print_chat");
	register_native("rz_give_bonus", "@native_give_bonus");
	register_native("rz_sys_error", "@native_sys_error");

	register_native("rz_main_lighting_global_get", "@native_main_lighting_global_get");
	register_native("rz_main_lighting_global_set", "@native_main_lighting_global_set");
	register_native("rz_main_lighting_global_reset", "@native_main_lighting_global_reset");
	register_native("rz_main_lighting_nvg_get", "@native_main_lighting_nvg_get");
	register_native("rz_main_lighting_nvg_set", "@native_main_lighting_nvg_set");
	register_native("rz_main_lighting_nvg_reset", "@native_main_lighting_nvg_reset");
	register_native("rz_main_roundover_ct_win", "@native_main_roundover_ct_win");
	register_native("rz_main_prepare_time", "@native_main_prepare_time");
	register_native("rz_main_round_time", "@native_main_round_time");
	register_native("rz_main_warmup_enabled", "@native_main_warmup_enabled");
	register_native("rz_main_warmup_time", "@native_main_warmup_time");
	register_native("rz_main_ammopacks_enabled", "@native_main_ammopacks_enabled");
	register_native("rz_main_ammopacks_join_amount", "@native_main_ammopacks_join_amount");

	register_native("rz_module_create", "@native_module_create");
	register_native("rz_module_get_offset", "@native_module_get_offset");
	register_native("rz_module_get_valid_index", "@native_module_get_valid_index");
	register_native("rz_module_find", "@native_module_find");
}

@native_load_langs(plugin, argc)
{
	enum { arg_name = 1 };

	new name[32];
	get_string(arg_name, name, charsmax(name));

	if (!name[0])
		return false;

	LoadLangs(name);
	return true;
}

@native_print_chat(plugin, argc)
{
	enum { arg_player = 1, arg_sender, arg_text, arg_arguments };

	new player = get_param(arg_player);
	new sender = get_param(arg_sender);
	new buffer[190];

	vdformat(buffer, charsmax(buffer), arg_text, arg_arguments);
	client_print_color(player, sender, "%s%s", gConfigData[CHAT_PREFIX], buffer);
}

@native_give_bonus(plugin, argc)
{
	enum { arg_player = 1, arg_amount, arg_text, arg_arguments };

	if (!gConfigData[AWARD_NOTICE])
		return;
	
	new player = get_param(arg_player);
	new amount = get_param(arg_amount);
	new buffer[190];

	vdformat(buffer, charsmax(buffer), arg_text, arg_arguments);

	if (amount)
		rg_add_account(player, amount);

	if (!buffer[0])
		return;

	if (amount >= 0)
		client_print_color(player, print_team_default, "%s^4+%l^1: %s", gConfigData[CHAT_PREFIX], gConfigData[AMMOPACKS_ENABLED] ? "RZ_FMT_AMMOPACKS" : "RZ_FMT_DOLLARS", amount, buffer);
	else
		client_print_color(player, print_team_red, "%s^3-%l^1: %s", gConfigData[CHAT_PREFIX], gConfigData[AMMOPACKS_ENABLED] ? "RZ_FMT_AMMOPACKS" : "RZ_FMT_DOLLARS", amount, buffer);
}

@native_sys_error(plugin, argc)
{
	enum { arg_text = 1, arg_arguments };

	new buffer[256];
	vdformat(buffer, charsmax(buffer), arg_text, arg_arguments);

	dllfunc(DLLFunc_Sys_Error, fmt("ReZP: %s", buffer));
}

@native_main_lighting_global_get(plugin, argc)
{
	return (g_sGlobalLightingTemp[0] ? g_sGlobalLightingTemp[0] : gConfigData[GLOBAL_LIGHTING][0]);
}

@native_main_lighting_global_set(plugin, argc)
{
	enum { arg_lighting = 1 };

	get_string(arg_lighting, g_sGlobalLightingTemp, charsmax(g_sGlobalLightingTemp));

	rz_nightvision_player_update();
	return true;
}

@native_main_lighting_global_reset(plugin, argc)
{
	g_sGlobalLightingTemp[0] = EOS;

	rz_nightvision_player_update();
	return true;
}

@native_main_lighting_nvg_get(plugin, argc)
{
	return (g_sNVGLightingTemp[0] ? g_sNVGLightingTemp[0] : gConfigData[NVG_LIGHTING][0]);
}

@native_main_lighting_nvg_set(plugin, argc)
{
	enum { arg_lighting = 1 };

	get_string(arg_lighting, g_sNVGLightingTemp, charsmax(g_sNVGLightingTemp));

	rz_nightvision_player_update();
	return true;
}

@native_main_lighting_nvg_reset(plugin, argc)
{
	g_sNVGLightingTemp[0] = EOS;

	rz_nightvision_player_update();
	return true;
}

@native_main_roundover_ct_win(plugin, argc)
{
	return gConfigData[ROUNDOVER_CT_WIN];
}

@native_main_prepare_time(plugin, argc)
{
	return gConfigData[PREPARE_TIME];
}

@native_main_round_time(plugin, argc)
{
	return gConfigData[ROUND_TIME];
}

@native_main_warmup_enabled(plugin, argc)
{
	return gConfigData[WARMUP_ENABLED];
}

@native_main_warmup_time(plugin, argc)
{
	return gConfigData[WARMUP_TIME];
}

@native_main_ammopacks_enabled(plugin, argc)
{
	return gConfigData[AMMOPACKS_ENABLED];
}

@native_main_ammopacks_join_amount(plugin, argc)
{
	return gConfigData[AMMOPACKS_JOIN_AMT];
}

@native_module_create(plugin, argc)
{
	enum { arg_name = 1, arg_array_handle };

	new data[ModuleData];

	get_string(arg_name, data[Module_Name], charsmax(data[Module_Name]));
	data[Module_Handle] = Array:get_param(arg_array_handle);

	if (ArrayFindString(g_aModules, data[Module_Name]) != -1)
	{
		rz_sys_error("Module '%s' already defined", data[Module_Name]);
		return 0;
	}

	data[Module_Offset] = (ArraySize(g_aModules) + 1) * 1000;

	return ArrayPushArray(g_aModules, data);
}

@native_module_get_valid_index(plugin, argc)
{
	enum { arg_module = 1, arg_index };

	new module = get_param(arg_module);
	new index = get_param(arg_index);
	
	new data[ModuleData];
	ArrayGetArray(g_aModules, module, data);

	index -= data[Module_Offset];

	if (index < 0 || index >= ArraySize(data[Module_Handle]))
		return -1;

	return index;
}

@native_module_get_offset(plugin, argc)
{
	enum { arg_module = 1 };

	new module = get_param(arg_module);

	// safecheck
	
	new data[ModuleData];
	ArrayGetArray(g_aModules, module, data);

	return data[Module_Offset];
}

@native_module_find(plugin, argc)
{
	enum { arg_name = 1 };

	new data[ModuleData];
	get_string(arg_name, data[Module_Name], charsmax(data[Module_Name]));

	new index = ArrayFindString(g_aModules, data[Module_Name]);

	if (index == -1)
	{
		log_error(AMX_ERR_NATIVE, "Invalid module name (%s)", index, data[Module_Name]);
		return -1;
	}

	ArrayGetArray(g_aModules, index, data);

	return data[Module_Offset];
}
