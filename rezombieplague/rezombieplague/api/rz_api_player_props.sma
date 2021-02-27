#pragma semicolon 1

#include <amxmodx>
#include <reapi>
#include <rezp>

enum _:PlayerPropData
{
	PlayerProp_Handle[RZ_MAX_HANDLE_LENGTH],
	Float:PlayerProp_Health,
	Float:PlayerProp_BaseHealth,
	Float:PlayerProp_Armor,
	bool:PlayerProp_Helmet,
	Float:PlayerProp_Speed,
	Float:PlayerProp_Gravity,
	bool:PlayerProp_Footsteps,
	Float:PlayerProp_VelMod,
	Float:PlayerProp_VelModHead,
	Float:PlayerProp_Knockback,
	PlayerProp_BloodColor,
	/*bool:PlayerProp_SelfGib,
	bool:PlayerProp_EnemyGib,
	bool:PlayerProp_CanBurn,
	bool:PlayerProp_CanFreeze,*/

}; new Array:g_aPlayerProps;

new gPlayerPropsData[PlayerPropData];

new g_iModule;

public plugin_precache()
{
	register_plugin("[ReZP] API: Player Properties", REZP_VERSION_STR, "fl0wer");

	g_aPlayerProps = ArrayCreate(PlayerPropData, 0);
	g_iModule = rz_module_create("player_props", g_aPlayerProps);
}

public plugin_natives()
{
	register_native("rz_playerprops_create", "@native_playerprops_create");
	register_native("rz_playerprops_get", "@native_playerprops_get");
	register_native("rz_playerprops_set", "@native_playerprops_set");
	register_native("rz_playerprops_valid", "@native_playerprops_valid");
	register_native("rz_playerprops_player_change", "@native_playerprops_player_change");
}

@native_playerprops_create(plugin, argc)
{
	enum { arg_handle = 1 };

	new data[PlayerPropData];

	get_string(arg_handle, data[PlayerProp_Handle], charsmax(data[PlayerProp_Handle]));
	data[PlayerProp_Health] = 100.0;
	data[PlayerProp_BaseHealth] = 0.0;
	data[PlayerProp_Armor] = 0.0;
	data[PlayerProp_Helmet] = false;
	data[PlayerProp_Gravity] = 1.0;
	data[PlayerProp_Speed] = 0.0;
	data[PlayerProp_Footsteps] = true;
	data[PlayerProp_VelMod] = 0.65;
	data[PlayerProp_VelModHead] = 0.5;
	data[PlayerProp_Knockback] = 0.0;
	data[PlayerProp_BloodColor] = 247;

	return ArrayPushArray(g_aPlayerProps, data) + rz_module_get_offset(g_iModule);
}

@native_playerprops_get(plugin, argc)
{
	enum { arg_player_props = 1, arg_prop, arg_3, arg_4 };

	new playerProps = get_param(arg_player_props);
	new index = rz_module_get_valid_index(g_iModule, playerProps);

	RZ_CHECK_MODULE_VALID_INDEX(index, 0)

	ArrayGetArray(g_aPlayerProps, index, gPlayerPropsData);

	new prop = get_param(arg_prop);

	switch (prop)
	{
		case RZ_PLAYER_PROPS_HANDLE:
		{
			set_string(arg_3, gPlayerPropsData[PlayerProp_Handle], get_param_byref(arg_4));
		}
		case RZ_PLAYER_PROPS_HEALTH:
		{
			return any:gPlayerPropsData[PlayerProp_Health];
		}
		case RZ_PLAYER_PROPS_BASE_HEALTH:
		{
			return any:gPlayerPropsData[PlayerProp_BaseHealth];
		}
		case RZ_PLAYER_PROPS_ARMOR:
		{
			return any:gPlayerPropsData[PlayerProp_Armor];
		}
		case RZ_PLAYER_PROPS_HELMET:
		{
			return gPlayerPropsData[PlayerProp_Helmet];
		}
		case RZ_PLAYER_PROPS_GRAVITY:
		{
			return any:gPlayerPropsData[PlayerProp_Gravity];
		}
		case RZ_PLAYER_PROPS_SPEED:
		{
			return any:gPlayerPropsData[PlayerProp_Speed];
		}
		case RZ_PLAYER_PROPS_FOOTSTEPS:
		{
			return gPlayerPropsData[PlayerProp_Footsteps];
		}
		case RZ_PLAYER_PROPS_VELMOD:
		{
			return any:gPlayerPropsData[PlayerProp_VelMod];
		}
		case RZ_PLAYER_PROPS_VELMOD_HEAD:
		{
			return any:gPlayerPropsData[PlayerProp_VelModHead];
		}
		case RZ_PLAYER_PROPS_KNOCKBACK:
		{
			return any:gPlayerPropsData[PlayerProp_Knockback];
		}
		case RZ_PLAYER_PROPS_BLOOD_COLOR:
		{
			return gPlayerPropsData[PlayerProp_BloodColor];
		}
		default:
		{
			rz_log(true, "Player props property '%d' not found for '%s'", prop, gPlayerPropsData[PlayerProp_Handle]);
			return false;
		}
	}

	return true;
}

@native_playerprops_set(plugin, argc)
{
	enum { arg_player_props = 1, arg_prop, arg_3 };

	new playerProps = get_param(arg_player_props);
	new index = rz_module_get_valid_index(g_iModule, playerProps);

	RZ_CHECK_MODULE_VALID_INDEX(index, 0)

	ArrayGetArray(g_aPlayerProps, index, gPlayerPropsData);

	new prop = get_param(arg_prop);

	switch (prop)
	{
		case RZ_PLAYER_PROPS_HANDLE:
		{
			get_string(arg_3, gPlayerPropsData[PlayerProp_Handle], charsmax(gPlayerPropsData[PlayerProp_Handle]));
		}
		case RZ_PLAYER_PROPS_HEALTH:
		{
			gPlayerPropsData[PlayerProp_Health] = get_float_byref(arg_3);
		}
		case RZ_PLAYER_PROPS_BASE_HEALTH:
		{
			gPlayerPropsData[PlayerProp_BaseHealth] = get_float_byref(arg_3);
		}
		case RZ_PLAYER_PROPS_ARMOR:
		{
			gPlayerPropsData[PlayerProp_Armor] = get_float_byref(arg_3);
		}
		case RZ_PLAYER_PROPS_HELMET:
		{
			gPlayerPropsData[PlayerProp_Helmet] = bool:get_param_byref(arg_3);
		}
		case RZ_PLAYER_PROPS_GRAVITY:
		{
			gPlayerPropsData[PlayerProp_Gravity] = get_float_byref(arg_3);
		}
		case RZ_PLAYER_PROPS_SPEED:
		{
			gPlayerPropsData[PlayerProp_Speed] = get_float_byref(arg_3);
		}
		case RZ_PLAYER_PROPS_FOOTSTEPS:
		{
			gPlayerPropsData[PlayerProp_Footsteps] = bool:get_param_byref(arg_3);
		}
		case RZ_PLAYER_PROPS_VELMOD:
		{
			gPlayerPropsData[PlayerProp_VelMod] = get_float_byref(arg_3);
		}
		case RZ_PLAYER_PROPS_VELMOD_HEAD:
		{
			gPlayerPropsData[PlayerProp_VelModHead] = get_float_byref(arg_3);
		}
		case RZ_PLAYER_PROPS_KNOCKBACK:
		{
			gPlayerPropsData[PlayerProp_Knockback] = get_float_byref(arg_3);
		}
		case RZ_PLAYER_PROPS_BLOOD_COLOR:
		{
			gPlayerPropsData[PlayerProp_BloodColor] = get_param_byref(arg_3);
		}
		default:
		{
			rz_log(true, "Player props property '%d' not found for '%s'", prop, gPlayerPropsData[PlayerProp_Handle]);
			return false;
		}
	}

	ArraySetArray(g_aPlayerProps, index, gPlayerPropsData);
	return true;
}

@native_playerprops_valid(plugin, argc)
{
	enum { arg_player_props = 1 };

	new playerProps = get_param(arg_player_props);

	if (!playerProps)
		return false;

	return (rz_module_get_valid_index(g_iModule, playerProps) != -1);
}

@native_playerprops_player_change(plugin, argc)
{
	enum { arg_player = 1, arg_player_props, arg_spawn };

	new player = get_param(arg_player);
	RZ_CHECK_ALIVE(player, false)

	new playerProps = get_param(arg_player_props);
	new index = rz_module_get_valid_index(g_iModule, playerProps);

	RZ_CHECK_MODULE_VALID_INDEX(index, false)
	
	new Float:health;

	ArrayGetArray(g_aPlayerProps, index, gPlayerPropsData);

	if (gPlayerPropsData[PlayerProp_BaseHealth])
		health = gPlayerPropsData[PlayerProp_BaseHealth] * rz_game_get_alivesnum();
	else
		health = gPlayerPropsData[PlayerProp_Health];

	set_entvar(player, var_health, health);
	set_entvar(player, var_max_health, health);
	set_entvar(player, var_gravity, gPlayerPropsData[PlayerProp_Gravity]);
	set_member(player, m_bloodColor, gPlayerPropsData[PlayerProp_BloodColor]);
	rg_set_user_footsteps(player, !gPlayerPropsData[PlayerProp_Footsteps]);

	new bool:spawn = any:get_param(arg_spawn);
	new giveArmor = floatround(gPlayerPropsData[PlayerProp_Armor]);

	if (spawn)
	{
		new ArmorType:armorType;
		new armor = rg_get_user_armor(player, armorType);

		if (giveArmor)
			armorType = gPlayerPropsData[PlayerProp_Helmet] ? ARMOR_VESTHELM : ARMOR_KEVLAR;

		if (armor < giveArmor || get_member(player, m_iKevlar) < armorType)
			rg_set_user_armor(player, max(giveArmor, armor), armorType);
	}
	else
	{
		if (giveArmor)
			rg_set_user_armor(player, giveArmor, gPlayerPropsData[PlayerProp_Helmet] ? ARMOR_VESTHELM : ARMOR_KEVLAR);
		else
			rg_set_user_armor(player, 0, ARMOR_NONE);
	}

	return true;
}
