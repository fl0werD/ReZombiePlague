#pragma semicolon 1

#include <amxmodx>
#include <reapi>
#include <rezp>

enum _:ClassData
{
	Class_Handle[RZ_MAX_HANDLE_LENGTH],
	Class_Name[RZ_MAX_LANGKEY_LENGTH],
	TeamName:Class_Team,
	Class_HudColor[3],
	Class_PlayerProps,
	Class_PlayerModel,
	Class_PlayerSound,
	Class_Knife,
	Class_NightVision,

}; new Array:g_aClasses;

new gClassData[ClassData];

enum _:Forwards
{
	Fw_Return,
	Fw_Class_Change_Pre,
	Fw_Class_Change_Post,

}; new gForwards[Forwards];

new g_iDefaultClass[TeamName];
new g_iDefaultClassOverride[TeamName];

new g_iModule;

public plugin_precache()
{
	register_plugin("[ReZP] API: Player Class", REZP_VERSION_STR, "fl0wer");

	g_aClasses = ArrayCreate(ClassData, 0);
	g_iModule = rz_module_create("player_class", g_aClasses);
}

public plugin_init()
{
	gForwards[Fw_Class_Change_Pre] = CreateMultiForward("rz_class_change_pre", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL, FP_CELL);
	gForwards[Fw_Class_Change_Post] = CreateMultiForward("rz_class_change_post", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL, FP_CELL);
}

public plugin_cfg()
{
	if (!g_iDefaultClass[TEAM_TERRORIST] || !g_iDefaultClass[TEAM_CT])
		set_fail_state("No loaded default classes");
}

ChangeClass(id, attacker, class, bool:preSpawn = false)
{
	ExecuteForward(gForwards[Fw_Class_Change_Pre], gForwards[Fw_Return], id, attacker, class, preSpawn);

	if (gForwards[Fw_Return] >= RZ_SUPERCEDE)
		return false;

	ExecuteForward(gForwards[Fw_Class_Change_Post], gForwards[Fw_Return], id, attacker, class, preSpawn);
	return true;
}

public plugin_natives()
{
	ClassNatives();
}

ClassNatives()
{
	register_native("rz_class_create", "@native_class_create");
	register_native("rz_class_get", "@native_class_get");
	register_native("rz_class_set", "@native_class_set");
	register_native("rz_class_start", "@native_class_start");
	register_native("rz_class_find", "@native_class_find");
	register_native("rz_class_size", "@native_class_size");

	register_native("rz_class_get_default", "@native_class_get_default");
	register_native("rz_class_set_default", "@native_class_set_default");
	register_native("rz_class_override_default", "@native_class_override_default");

	register_native("rz_class_player_change", "@native_class_player_change");
}

@native_class_create(plugin, argc)
{
	enum { arg_handle = 1, arg_team };

	new data[ClassData];

	get_string(arg_handle, data[Class_Handle], charsmax(data[Class_Handle]));
	data[Class_Team] = any:get_param(arg_team);
	data[Class_HudColor] = { 255, 255, 255 };
	data[Class_PlayerProps] = rz_playerprops_create(fmt("%s_playerprops", data[Class_Handle]));
	data[Class_PlayerModel] = rz_playermodel_create(fmt("%s_playermodels", data[Class_Handle]));
	data[Class_PlayerSound] = rz_playersound_create(fmt("%s_playersounds", data[Class_Handle]));
	data[Class_NightVision] = rz_nightvision_create(fmt("%s_nightvision", data[Class_Handle]));

	new TeamName:team = data[Class_Team];

	RZ_CHECK_PLAYABLE_TEAM(team, 0)

	new id = ArrayPushArray(g_aClasses, data) + rz_module_get_offset(g_iModule);

	if (!g_iDefaultClass[team])
		g_iDefaultClass[team] = id;

	return id;
}

@native_class_get(plugin, argc)
{
	enum { arg_class = 1, arg_prop, arg_3, arg_4 };

	new class = get_param(arg_class);
	new index = rz_module_get_valid_index(g_iModule, class);

	RZ_CHECK_MODULE_VALID_INDEX(index, false)
	
	ArrayGetArray(g_aClasses, index, gClassData);

	new prop = get_param(arg_prop);

	switch (prop)
	{
		case RZ_CLASS_HANDLE:
		{
			set_string(arg_3, gClassData[Class_Handle], get_param_byref(arg_4));
		}
		case RZ_CLASS_NAME:
		{
			set_string(arg_3, gClassData[Class_Name], get_param_byref(arg_4));
		}
		case RZ_CLASS_TEAM:
		{
			return any:gClassData[Class_Team];
		}
		case RZ_CLASS_HUD_COLOR:
		{
			set_array(arg_3, gClassData[Class_HudColor], sizeof(gClassData[Class_HudColor]));
		}
		case RZ_CLASS_PROPS:
		{
			return gClassData[Class_PlayerProps];
		}
		case RZ_CLASS_MODEL:
		{
			return gClassData[Class_PlayerModel];
		}
		case RZ_CLASS_SOUND:
		{
			return gClassData[Class_PlayerSound];
		}
		case RZ_CLASS_KNIFE:
		{
			return gClassData[Class_Knife];
		}
		case RZ_CLASS_NIGHTVISION:
		{
			return gClassData[Class_NightVision];
		}
		default:
		{
			rz_log(true, "Player class property '%d' not found for '%s'", prop, gClassData[Class_Handle]);
			return false;
		}
	}

	return true;
}

@native_class_set(plugin, argc)
{
	enum { arg_class = 1, arg_prop, arg_3 };

	new class = get_param(arg_class);
	new index = rz_module_get_valid_index(g_iModule, class);

	RZ_CHECK_MODULE_VALID_INDEX(index, false)
	
	ArrayGetArray(g_aClasses, index, gClassData);

	new prop = get_param(arg_prop);

	switch (prop)
	{
		case RZ_CLASS_HANDLE:
		{
			get_string(arg_3, gClassData[Class_Handle], charsmax(gClassData[Class_Handle]));
		}
		case RZ_CLASS_NAME:
		{
			get_string(arg_3, gClassData[Class_Name], charsmax(gClassData[Class_Name]));
		}
		case RZ_CLASS_TEAM:
		{
			gClassData[Class_Team] = any:get_param_byref(arg_3);
		}
		case RZ_CLASS_HUD_COLOR:
		{
			get_array(arg_3, gClassData[Class_HudColor], sizeof(gClassData[Class_HudColor]));
		}
		case RZ_CLASS_PROPS:
		{
			gClassData[Class_PlayerProps] = get_param_byref(arg_3);
		}
		case RZ_CLASS_MODEL:
		{
			gClassData[Class_PlayerModel] = get_param_byref(arg_3);
		}
		case RZ_CLASS_SOUND:
		{
			gClassData[Class_PlayerSound] = get_param_byref(arg_3);
		}
		case RZ_CLASS_KNIFE:
		{
			gClassData[Class_Knife] = get_param_byref(arg_3);
		}
		case RZ_CLASS_NIGHTVISION:
		{
			gClassData[Class_NightVision] = get_param_byref(arg_3);
		}
		default:
		{
			rz_log(true, "Player class property '%d' not found for '%s'", prop, gClassData[Class_Handle]);
			return false;
		}
	}

	ArraySetArray(g_aClasses, index, gClassData);
	return true;
}

@native_class_start(plugin, argc)
{
	return rz_module_get_offset(g_iModule);
}

@native_class_find(plugin, argc)
{
	enum { arg_handle = 1 };

	new handle[RZ_MAX_HANDLE_LENGTH];
	get_string(arg_handle, handle, charsmax(handle));

	new i = ArrayFindString(g_aClasses, handle);

	if (i != -1)
		return i + rz_module_get_offset(g_iModule);

	return 0;
}

@native_class_size(plugin, argc)
{
	return ArraySize(g_aClasses);
}

@native_class_get_default(plugin, argc)
{
	enum { arg_team = 1, arg_overrided };

	new TeamName:team = any:get_param(arg_team);
	RZ_CHECK_PLAYABLE_TEAM(team, false)

	new bool:overrided = bool:get_param(arg_overrided);

	if (overrided)
	{
		if (g_iDefaultClassOverride[team])
			return g_iDefaultClassOverride[team];
	}

	return g_iDefaultClass[team];
}

@native_class_set_default(plugin, argc)
{
	enum { arg_team = 1, arg_class };

	new TeamName:team = any:get_param(arg_team);
	RZ_CHECK_PLAYABLE_TEAM(team, false)

	new class = get_param(arg_class);
	new index = rz_module_get_valid_index(g_iModule, class);

	RZ_CHECK_MODULE_VALID_INDEX(index, false)

	g_iDefaultClass[team] = class;
	return true;
}

@native_class_override_default(plugin, argc)
{
	enum { arg_team = 1, arg_class };

	new TeamName:team = any:get_param(arg_team);
	RZ_CHECK_PLAYABLE_TEAM(team, false)

	new class = get_param(arg_class);

	if (!class)
	{
		g_iDefaultClassOverride[team] = 0;
		return true;
	}

	new index = rz_module_get_valid_index(g_iModule, class);

	RZ_CHECK_MODULE_VALID_INDEX(index, false)

	g_iDefaultClassOverride[team] = class;
	return true;
}

@native_class_player_change(plugin, argc)
{
	enum { arg_player = 1, arg_attacker, arg_class, arg_pre_spawn };

	new player = get_param(arg_player);
	RZ_CHECK_CONNECTED(player, false)

	new attacker = get_param(arg_attacker);
	new class = get_param(arg_class);
	new index = rz_module_get_valid_index(g_iModule, class);

	RZ_CHECK_MODULE_VALID_INDEX(index, false)

	return ChangeClass(player, attacker, class, any:get_param(arg_pre_spawn));
}
