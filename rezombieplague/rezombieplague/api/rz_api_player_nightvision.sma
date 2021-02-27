#pragma semicolon 1

#include <amxmodx>
#include <reapi>
#include <rezp>

enum _:NightVisionData
{
	NightVision_Handle[RZ_MAX_HANDLE_LENGTH],
	RZNightVisionEquip:NightVision_Equip,
	NightVision_Color[3],
	NightVision_Alpha,

}; new Array:g_aNightVisions;

new gNightVisionData[NightVisionData];

enum _:Forwards
{
	Fw_Return,
	Fw_NightVisions_Change_Pre,
	Fw_NightVisions_Change_Post,

}; new gForwards[Forwards];

new g_iModule;

public plugin_precache()
{
	register_plugin("[ReZP] API: Night Vision", REZP_VERSION_STR, "fl0wer");

	g_aNightVisions = ArrayCreate(NightVisionData, 0);
	g_iModule = rz_module_create("player_nvg", g_aNightVisions);
}

public plugin_init()
{
	gForwards[Fw_NightVisions_Change_Pre] = CreateMultiForward("rz_nightvisions_change_pre", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL);
	gForwards[Fw_NightVisions_Change_Post] = CreateMultiForward("rz_nightvisions_change_post", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL);
}

ChangeNightVision(id, player, bool:enabled = false)
{
	ExecuteForward(gForwards[Fw_NightVisions_Change_Pre], gForwards[Fw_Return], id, player, enabled);

	if (gForwards[Fw_Return] >= RZ_SUPERCEDE)
		return false;

	ExecuteForward(gForwards[Fw_NightVisions_Change_Post], gForwards[Fw_Return], id, player, enabled);
	return true;
}

public plugin_natives()
{
	register_native("rz_nightvision_create", "@native_nightvision_create");
	register_native("rz_nightvision_get", "@native_nightvision_get");
	register_native("rz_nightvision_set", "@native_nightvision_set");

	register_native("rz_nightvisions_find", "@native_nightvisions_find");
	register_native("rz_nightvisions_player_change", "@native_nightvisions_player_change");
}

@native_nightvision_create(plugin, argc)
{
	enum { arg_handle = 1 };

	new data[NightVisionData];

	get_string(arg_handle, data[NightVision_Handle], charsmax(data[NightVision_Handle]));
	
	return ArrayPushArray(g_aNightVisions, data) + rz_module_get_offset(g_iModule);
}

@native_nightvision_get(plugin, argc)
{
	enum { arg_night_vision = 1, arg_prop, arg_3, arg_4 };

	new nightVision = get_param(arg_night_vision);
	new index = rz_module_get_valid_index(g_iModule, nightVision);

	RZ_CHECK_MODULE_VALID_INDEX(index, false)
	
	ArrayGetArray(g_aNightVisions, index, gNightVisionData);

	new prop = get_param(arg_prop);

	switch (prop)
	{
		case RZ_NIGHTVISION_HANDLE:
		{
			set_string(arg_3, gNightVisionData[NightVision_Handle], get_param_byref(arg_4));
		}
		case RZ_NIGHTVISION_EQUIP:
		{
			return any:gNightVisionData[NightVision_Equip];
		}
		case RZ_NIGHTVISION_COLOR:
		{
			set_array(arg_3, gNightVisionData[NightVision_Color], sizeof(gNightVisionData[NightVision_Color]));
		}
		case RZ_NIGHTVISION_ALPHA:
		{
			return gNightVisionData[NightVision_Alpha];
		}
		default:
		{
			rz_log(true, "Night vision property '%d' not found for '%s'", prop, gNightVisionData[NightVision_Handle]);
			return false;
		}
	}

	return true;
}

@native_nightvision_set(plugin, argc)
{
	enum { arg_night_vision = 1, arg_prop, arg_3 };

	new nightVision = get_param(arg_night_vision);
	new index = rz_module_get_valid_index(g_iModule, nightVision);

	RZ_CHECK_MODULE_VALID_INDEX(index, false)
	
	ArrayGetArray(g_aNightVisions, index, gNightVisionData);

	new prop = get_param(arg_prop);

	switch (prop)
	{
		case RZ_NIGHTVISION_HANDLE:
		{
			get_string(arg_3, gNightVisionData[NightVision_Handle], charsmax(gNightVisionData[NightVision_Handle]));
		}
		case RZ_NIGHTVISION_EQUIP:
		{
			gNightVisionData[NightVision_Equip] = any:get_param_byref(arg_3);
		}
		case RZ_NIGHTVISION_COLOR:
		{
			get_array(arg_3, gNightVisionData[NightVision_Color], sizeof(gNightVisionData[NightVision_Color]));
		}
		case RZ_NIGHTVISION_ALPHA:
		{
			gNightVisionData[NightVision_Alpha] = get_param_byref(arg_3);
		}
		default:
		{
			rz_log(true, "Night vision property '%d' not found for '%s'", prop, gNightVisionData[NightVision_Handle]);
			return false;
		}
	}

	ArraySetArray(g_aNightVisions, index, gNightVisionData);
	return true;
}

@native_nightvisions_find(plugin, argc)
{
	enum { arg_handle = 1 };

	new handle[RZ_MAX_HANDLE_LENGTH];
	get_string(arg_handle, handle, charsmax(handle));

	new i = ArrayFindString(g_aNightVisions, handle);

	if (i != -1)
		return i + rz_module_get_offset(g_iModule);

	return 0;
}

@native_nightvisions_player_change(plugin, argc)
{
	enum { arg_player = 1, arg_night_vision, arg_enabled };

	new player = get_param(arg_player);
	RZ_CHECK_CONNECTED(player, false)

	new nightVision = get_param(arg_night_vision);
	new index = rz_module_get_valid_index(g_iModule, nightVision);

	RZ_CHECK_MODULE_VALID_INDEX(index, false)

	return ChangeNightVision(nightVision, player, any:get_param(arg_enabled));
}

/*@native_nightvision_player_update(plugin, argc)
{
	enum { arg_player = 1 };

	new player = get_param(arg_player);

	if (player)
	{
		SetNightVisionEnabled(player, g_bNightVision[player]);
	}
	else
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (!is_user_connected(i))
				continue;

			SetNightVisionEnabled(i, g_bNightVision[i]);
		}
	}

	return true;
}
*/