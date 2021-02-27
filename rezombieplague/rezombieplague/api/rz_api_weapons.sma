#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <reapi>
#include <rezp>

enum _:DefaultWeaponData
{
	DefaultWeapon_Handle[RZ_MAX_HANDLE_LENGTH],
	DefaultWeapon_Name[RZ_MAX_LANGKEY_LENGTH],
	DefaultWeapon_ShortName[RZ_MAX_LANGKEY_LENGTH],
	Float:DefaultWeapon_KnockbackPower,

}; new Array:g_aDefaultWeapons;

enum _:WeaponData
{
	Weapon_Handle[RZ_MAX_HANDLE_LENGTH],
	Weapon_Reference[RZ_MAX_REFERENCE_LENGTH],
	Weapon_Name[RZ_MAX_LANGKEY_LENGTH],
	Weapon_ShortName[RZ_MAX_LANGKEY_LENGTH],
	Weapon_ViewModel[RZ_MAX_RESOURCE_PATH],
	Weapon_PlayerModel[RZ_MAX_RESOURCE_PATH],
	Weapon_WorldModel[RZ_MAX_RESOURCE_PATH],
	Weapon_WeaponList[RZ_MAX_RESOURCE_PATH],
	Float:Weapon_BaseDamage,
	Float:Weapon_BaseDamage2,
	Float:Weapon_KnockbackPower,

}; new Array:g_aWeapons;

enum _:KnifeData
{
	Knife_Handle[RZ_MAX_HANDLE_LENGTH],
	Knife_Name[RZ_MAX_LANGKEY_LENGTH],
	Knife_ShortName[RZ_MAX_LANGKEY_LENGTH],
	Knife_ViewModel[RZ_MAX_RESOURCE_PATH],
	Knife_PlayerModel[RZ_MAX_RESOURCE_PATH],
	Knife_WeaponList[RZ_MAX_RESOURCE_PATH],
	Float:Knife_StabBaseDamage,
	Float:Knife_SwingBaseDamage,
	Float:Knife_StabDistance,
	Float:Knife_SwingDistance,
	Float:Knife_KnockbackPower,
	Array:Knife_SoundsBank[RZ_MAX_KNIFE_SOUNDS],

}; new Array:g_aKnives;

enum _:GrenadeData
{
	Grenade_Handle[RZ_MAX_HANDLE_LENGTH],
	Grenade_Reference[RZ_MAX_REFERENCE_LENGTH],
	Grenade_Name[RZ_MAX_LANGKEY_LENGTH],
	Grenade_ShortName[RZ_MAX_LANGKEY_LENGTH],
	Grenade_ViewModel[RZ_MAX_RESOURCE_PATH],
	Grenade_PlayerModel[RZ_MAX_RESOURCE_PATH],
	Grenade_WorldModel[RZ_MAX_RESOURCE_PATH],
	Grenade_WeaponList[RZ_MAX_RESOURCE_PATH],

}; new Array:g_aGrenades;

new gDefaultWeaponData[DefaultWeaponData];
new gWeaponData[WeaponData];
new gKnifeData[KnifeData];
new gGrenadeData[GrenadeData];

enum _:Forwards
{
	Fw_Return,
	Fw_Grenades_Throw_Pre,
	Fw_Grenades_Throw_Post,
	Fw_Grenades_Explode_Pre,
	Fw_Grenades_Explode_Post,

}; new gForwards[Forwards];

new g_iModule_Weapons;
new g_iModule_Knives;
new g_iModule_Grenades;

public plugin_precache()
{
	register_plugin("[ReZP] API: Weapons", REZP_VERSION_STR, "fl0wer");

	g_aDefaultWeapons = ArrayCreate(DefaultWeaponData, 0);
	g_aWeapons = ArrayCreate(WeaponData, 0);
	g_aKnives = ArrayCreate(KnifeData, 0);
	g_aGrenades = ArrayCreate(GrenadeData, 0);

	g_iModule_Weapons = rz_module_create("weapons", g_aWeapons);
	g_iModule_Knives = rz_module_create("knives", g_aKnives);
	g_iModule_Grenades = rz_module_create("grenades", g_aGrenades);

	DefineDefaultWeapons();
}

public plugin_init()
{
	RegisterHookChain(RG_ThrowHeGrenade, "@ThrowGrenade_Post", true);
	RegisterHookChain(RG_ThrowFlashbang, "@ThrowGrenade_Post", true);
	RegisterHookChain(RG_ThrowSmokeGrenade, "@ThrowGrenade_Post", true);
	RegisterHookChain(RG_CGrenade_ExplodeHeGrenade, "@CGrenade_ExplodeGrenade_Pre", false);
	RegisterHookChain(RG_CGrenade_ExplodeFlashbang, "@CGrenade_ExplodeGrenade_Pre", false);
	RegisterHookChain(RG_CGrenade_ExplodeSmokeGrenade, "@CGrenade_ExplodeGrenade_Pre", false);

	gForwards[Fw_Grenades_Throw_Pre] = CreateMultiForward("rz_grenades_throw_pre", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL);
	gForwards[Fw_Grenades_Throw_Post] = CreateMultiForward("rz_grenades_throw_post", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL);
	gForwards[Fw_Grenades_Explode_Pre] = CreateMultiForward("rz_grenades_explode_pre", ET_CONTINUE, FP_CELL, FP_CELL);
	gForwards[Fw_Grenades_Explode_Post] = CreateMultiForward("rz_grenades_explode_post", ET_IGNORE, FP_CELL, FP_CELL);
}

@Command_SelectWeapon(id, impulse)
{
	new index = rz_module_get_valid_index(g_iModule_Weapons, impulse);

	if (index == -1)
		return PLUGIN_CONTINUE;

	ArrayGetArray(g_aWeapons, index, gWeaponData);
	engclient_cmd(id, gWeaponData[Weapon_Reference]);
	return PLUGIN_HANDLED;
}

@Command_SelectKnife(id)
{
	engclient_cmd(id, "weapon_knife");
	return PLUGIN_HANDLED;
}

@Command_SelectGrenade(id, impulse)
{
	new index = rz_module_get_valid_index(g_iModule_Grenades, impulse);

	if (index == -1)
		return PLUGIN_CONTINUE;

	ArrayGetArray(g_aGrenades, index, gGrenadeData);
	engclient_cmd(id, gGrenadeData[Grenade_Reference]);
	return PLUGIN_HANDLED;
}

@ThrowGrenade_Post(id, Float:vecStart[3], Float:vecVelocity[3])
{
	new activeItem = get_member(id, m_pActiveItem);

	if (is_nullent(activeItem))
		return;

	new impulse = get_entvar(activeItem, var_impulse);
	new index = rz_module_get_valid_index(g_iModule_Grenades, impulse);

	if (index == -1)
		return;

	new entity = GetHookChainReturn(ATYPE_INTEGER);

	ExecuteForward(gForwards[Fw_Grenades_Throw_Pre], gForwards[Fw_Return], id, entity, impulse);

	// what i'm doing...
	//if (gForwards[Fw_Return] >= RZ_SUPERCEDE)
	//	return;

	set_entvar(entity, var_impulse, impulse);

	ArrayGetArray(g_aGrenades, index, gGrenadeData);

	if (gGrenadeData[Weapon_WorldModel][0])
		engfunc(EngFunc_SetModel, entity, gGrenadeData[Weapon_WorldModel]);

	ExecuteForward(gForwards[Fw_Grenades_Throw_Post], gForwards[Fw_Return], id, entity,  impulse);
}

@CGrenade_ExplodeGrenade_Pre(id)
{
	new impulse = get_entvar(id, var_impulse);
	new index = rz_module_get_valid_index(g_iModule_Grenades, impulse);

	if (index == -1)
		return HC_CONTINUE;

	ExecuteForward(gForwards[Fw_Grenades_Explode_Pre], gForwards[Fw_Return], id, impulse);

	switch (gForwards[Fw_Return])
	{
		case RZ_SUPERCEDE:
		{
			return HC_SUPERCEDE;
		}
		case RZ_BREAK:
		{
			set_entvar(id, var_flags, FL_KILLME);
			return HC_SUPERCEDE;
		}
	}

	ExecuteForward(gForwards[Fw_Grenades_Explode_Post], gForwards[Fw_Return], id, impulse);
	return HC_CONTINUE;
}

DefineDefaultWeapons()
{
	DefineDefaultWeapon("", "", ""); // WEAPON_NONE
	DefineDefaultWeapon("weapon_p228", "RZ_WPN_P228", "", 2.4);
	DefineDefaultWeapon("", "", ""); // WEAPON_GLOCK
	DefineDefaultWeapon("weapon_scout", "RZ_WPN_SCOUT", "", 6.5);
	DefineDefaultWeapon("weapon_hegrenade", "RZ_WPN_HEGRENADE", "RZ_WPN_HE_SHORT");
	DefineDefaultWeapon("weapon_xm1014", "RZ_WPN_XM1014", "", 8.0);
	DefineDefaultWeapon("", "", ""); // WEAPON_C4
	DefineDefaultWeapon("weapon_mac10", "RZ_WPN_MAC10", "", 2.3);
	DefineDefaultWeapon("weapon_aug", "RZ_WPN_AUG", "", 5.0);
	DefineDefaultWeapon("weapon_smokegrenade", "RZ_WPN_SMOKEGRENADE", "RZ_WPN_SMOKE_SHORT");
	DefineDefaultWeapon("weapon_elite", "RZ_WPN_ELITE", "", 2.4);
	DefineDefaultWeapon("weapon_fiveseven", "RZ_WPN_FIVESEVEN", "", 2.0);
	DefineDefaultWeapon("weapon_ump45", "RZ_WPN_UMP45", "", 2.4);
	DefineDefaultWeapon("weapon_sg550", "RZ_WPN_SG550", "", 5.3);
	DefineDefaultWeapon("weapon_galil", "RZ_WPN_GALIL", "", 5.5);
	DefineDefaultWeapon("weapon_famas", "RZ_WPN_FAMAS", "", 5.5);
	DefineDefaultWeapon("weapon_usp", "RZ_WPN_USP", "", 2.2);
	DefineDefaultWeapon("weapon_glock18", "RZ_WPN_GLOCK18", "", 2.0);
	DefineDefaultWeapon("weapon_awp", "RZ_WPN_AWP", "", 10.0);
	DefineDefaultWeapon("weapon_mp5navy", "RZ_WPN_MP5NAVY", "", 2.5);
	DefineDefaultWeapon("weapon_m249", "RZ_WPN_M249", "", 5.2);
	DefineDefaultWeapon("weapon_m3", "RZ_WPN_M3", "", 8.0);
	DefineDefaultWeapon("weapon_m4a1", "RZ_WPN_M4A1", "", 5.0);
	DefineDefaultWeapon("weapon_tmp", "RZ_WPN_TMP", "", 2.4);
	DefineDefaultWeapon("weapon_g3sg1", "RZ_WPN_G3SG1", "", 6.5);
	DefineDefaultWeapon("weapon_flashbang", "RZ_WPN_FLASHBANG", "RZ_WPN_FB_SHORT");
	DefineDefaultWeapon("weapon_deagle", "RZ_WPN_DEAGLE", "", 5.3);
	DefineDefaultWeapon("weapon_sg552", "RZ_WPN_SG552", "", 5.0);
	DefineDefaultWeapon("weapon_ak47", "RZ_WPN_AK47", "", 6.0);
	DefineDefaultWeapon("weapon_knife", "RZ_WPN_KNIFE", "");
	DefineDefaultWeapon("weapon_p90", "RZ_WPN_P90", "", 2.0);
}

DefineDefaultWeapon(handle[RZ_MAX_HANDLE_LENGTH], name[RZ_MAX_LANGKEY_LENGTH], shortName[RZ_MAX_LANGKEY_LENGTH], Float:knockbackPower = -1.0)
{
	gDefaultWeaponData[DefaultWeapon_Handle] = handle;
	gDefaultWeaponData[DefaultWeapon_Name] = name;
	gDefaultWeaponData[DefaultWeapon_ShortName] = shortName;
	gDefaultWeaponData[DefaultWeapon_KnockbackPower] = knockbackPower;

	ArrayPushArray(g_aDefaultWeapons, gDefaultWeaponData);
}

public plugin_natives()
{
	register_native("rz_weapon_default_get", "@native_weapon_default_get");
	register_native("rz_weapon_default_set", "@native_weapon_default_set");

	register_native("rz_weapons_default_find", "@native_weapons_default_find");

	register_native("rz_weapon_create", "@native_weapon_create");
	register_native("rz_weapon_get", "@native_weapon_get");
	register_native("rz_weapon_set", "@native_weapon_set");

	register_native("rz_weapons_start", "@native_weapons_start");
	register_native("rz_weapons_find", "@native_weapons_find");
	register_native("rz_weapons_size", "@native_weapons_size");
	register_native("rz_weapons_valid", "@native_weapons_valid");

	register_native("rz_knife_create", "@native_knife_create");
	register_native("rz_knife_get", "@native_knife_get");
	register_native("rz_knife_set", "@native_knife_set");
	register_native("rz_knife_sound_add", "@native_knife_sound_add");

	register_native("rz_knifes_start", "@native_knifes_start");
	register_native("rz_knifes_find", "@native_knifes_find");
	register_native("rz_knifes_size", "@native_knifes_size");
	register_native("rz_knifes_valid", "@native_knifes_valid");

	register_native("rz_grenade_create", "@native_grenade_create");
	register_native("rz_grenade_get", "@native_grenade_get");
	register_native("rz_grenade_set", "@native_grenade_set");

	register_native("rz_grenades_start", "@native_grenades_start");
	register_native("rz_grenades_find", "@native_grenades_find");
	register_native("rz_grenades_size", "@native_grenades_size");
	register_native("rz_grenades_valid", "@native_grenades_valid");
}

@native_weapon_default_get(plugin, argc)
{
	enum { arg_weapon_id = 1, arg_prop, arg_3, arg_4 };

	new weaponId = get_param(arg_weapon_id);
	/*new index = rz_module_get_valid_index(g_iModule_Def, weapon);

	RZ_CHECK_MODULE_VALID_INDEX(index, false)*/
	
	ArrayGetArray(g_aDefaultWeapons, weaponId, gDefaultWeaponData);

	new prop = get_param(arg_prop);

	switch (prop)
	{
		case RZ_DEFAULT_WEAPON_HANDLE:
		{
			set_string(arg_3, gDefaultWeaponData[DefaultWeapon_Handle], get_param_byref(arg_4));
		}
		case RZ_DEFAULT_WEAPON_NAME:
		{
			set_string(arg_3, gDefaultWeaponData[DefaultWeapon_Name], get_param_byref(arg_4));
		}
		case RZ_DEFAULT_WEAPON_SHORT_NAME:
		{
			set_string(arg_3, gDefaultWeaponData[DefaultWeapon_ShortName], get_param_byref(arg_4));
		}
		case RZ_DEFAULT_WEAPON_KNOCKBACK_POWER:
		{
			return any:gDefaultWeaponData[DefaultWeapon_KnockbackPower];
		}
		default:
		{
			rz_log(true, "Default weapon property '%d' not found for '%s'", prop, gDefaultWeaponData[DefaultWeapon_Handle]);
			return false;
		}
	}

	return true;
}

@native_weapon_default_set(plugin, argc)
{
	enum { arg_weapon_id = 1, arg_prop, arg_3 };

	new weaponId = get_param(arg_weapon_id);
	/*new index = rz_module_get_valid_index(g_iModule_Weapons, weapon);

	RZ_CHECK_MODULE_VALID_INDEX(index, false)*/
	
	ArrayGetArray(g_aDefaultWeapons, weaponId, gDefaultWeaponData);

	new prop = get_param(arg_prop);

	switch (prop)
	{
		case RZ_DEFAULT_WEAPON_HANDLE:
		{
			get_string(arg_3, gDefaultWeaponData[DefaultWeapon_Handle], charsmax(gDefaultWeaponData[DefaultWeapon_Handle]));
		}
		case RZ_DEFAULT_WEAPON_NAME:
		{
			get_string(arg_3, gDefaultWeaponData[DefaultWeapon_Name], charsmax(gDefaultWeaponData[DefaultWeapon_Name]));
		}
		case RZ_DEFAULT_WEAPON_SHORT_NAME:
		{
			get_string(arg_3, gDefaultWeaponData[DefaultWeapon_ShortName], charsmax(gDefaultWeaponData[DefaultWeapon_ShortName]));
		}
		case RZ_DEFAULT_WEAPON_KNOCKBACK_POWER:
		{
			gDefaultWeaponData[DefaultWeapon_KnockbackPower] = get_float_byref(arg_3);
		}
		default:
		{
			rz_log(true, "Default weapon property '%d' not found for '%s'", prop, gDefaultWeaponData[DefaultWeapon_Handle]);
			return false;
		}
	}

	ArraySetArray(g_aDefaultWeapons, weaponId, gDefaultWeaponData);
	return true;
}

@native_weapons_default_find(plugin, argc)
{
	enum { arg_handle = 1 };

	new handle[RZ_MAX_HANDLE_LENGTH];
	get_string(arg_handle, handle, charsmax(handle));

	new i = ArrayFindString(g_aDefaultWeapons, handle);

	if (i != -1)
		return i;
	
	return 0;
}

@native_weapon_create(plugin, argc)
{
	enum { arg_handle = 1, arg_reference };

	new data[WeaponData];

	// check handle available
	// check ref valid

	get_string(arg_handle, data[Weapon_Handle], charsmax(data[Weapon_Handle]));
	get_string(arg_reference, data[Weapon_Reference], charsmax(data[Weapon_Reference]));
	data[Weapon_KnockbackPower] = -1.0;

	return ArrayPushArray(g_aWeapons, data) + rz_module_get_offset(g_iModule_Weapons);
}

@native_weapon_get(plugin, argc)
{
	enum { arg_weapon = 1, arg_prop, arg_3, arg_4 };

	new weapon = get_param(arg_weapon);
	new index = rz_module_get_valid_index(g_iModule_Weapons, weapon);

	RZ_CHECK_MODULE_VALID_INDEX(index, false)
	
	ArrayGetArray(g_aWeapons, index, gWeaponData);

	new prop = get_param(arg_prop);

	switch (prop)
	{
		case RZ_WEAPON_HANDLE:
		{
			set_string(arg_3, gWeaponData[Weapon_Handle], get_param_byref(arg_4));
		}
		case RZ_WEAPON_REFERENCE:
		{
			set_string(arg_3, gWeaponData[Weapon_Reference], get_param_byref(arg_4));
		}
		case RZ_WEAPON_NAME:
		{
			set_string(arg_3, gWeaponData[Weapon_Name], get_param_byref(arg_4));
		}
		case RZ_WEAPON_SHORT_NAME:
		{
			set_string(arg_3, gWeaponData[Weapon_ShortName], get_param_byref(arg_4));
		}
		case RZ_WEAPON_VIEW_MODEL:
		{
			set_string(arg_3, gWeaponData[Weapon_ViewModel], get_param_byref(arg_4));
		}
		case RZ_WEAPON_PLAYER_MODEL:
		{
			set_string(arg_3, gWeaponData[Weapon_PlayerModel], get_param_byref(arg_4));
		}
		case RZ_WEAPON_WORLD_MODEL:
		{
			set_string(arg_3, gWeaponData[Weapon_WorldModel], get_param_byref(arg_4));
		}
		case RZ_WEAPON_WEAPONLIST:
		{
			set_string(arg_3, gWeaponData[Weapon_WeaponList], get_param_byref(arg_4));
		}
		case RZ_WEAPON_BASE_DAMAGE:
		{
			return any:gWeaponData[Weapon_BaseDamage];
		}
		case RZ_WEAPON_BASE_DAMAGE2:
		{
			return any:gWeaponData[Weapon_BaseDamage2];
		}
		case RZ_WEAPON_KNOCKBACK_POWER:
		{
			return any:gWeaponData[Weapon_KnockbackPower];
		}
		default:
		{
			rz_log(true, "Weapon property '%d' not found for '%s'", prop, gWeaponData[Weapon_Handle]);
			return false;
		}
	}

	return true;
}

@native_weapon_set(plugin, argc)
{
	enum { arg_weapon = 1, arg_prop, arg_3 };

	new weapon = get_param(arg_weapon);
	new index = rz_module_get_valid_index(g_iModule_Weapons, weapon);

	RZ_CHECK_MODULE_VALID_INDEX(index, false)
	
	ArrayGetArray(g_aWeapons, index, gWeaponData);

	new prop = get_param(arg_prop);

	switch (prop)
	{
		case RZ_WEAPON_HANDLE:
		{
			get_string(arg_3, gWeaponData[Weapon_Handle], charsmax(gWeaponData[Weapon_Handle]));
		}
		case RZ_WEAPON_REFERENCE:
		{
			get_string(arg_3, gWeaponData[Weapon_Reference], charsmax(gWeaponData[Weapon_Reference]));
		}
		case RZ_WEAPON_NAME:
		{
			get_string(arg_3, gWeaponData[Weapon_Name], charsmax(gWeaponData[Weapon_Name]));
		}
		case RZ_WEAPON_SHORT_NAME:
		{
			get_string(arg_3, gWeaponData[Weapon_ShortName], charsmax(gWeaponData[Weapon_ShortName]));
		}
		case RZ_WEAPON_VIEW_MODEL:
		{
			get_string(arg_3, gWeaponData[Weapon_ViewModel], charsmax(gWeaponData[Weapon_ViewModel]));
		}
		case RZ_WEAPON_PLAYER_MODEL:
		{
			get_string(arg_3, gWeaponData[Weapon_PlayerModel], charsmax(gWeaponData[Weapon_PlayerModel]));
		}
		case RZ_WEAPON_WORLD_MODEL:
		{
			get_string(arg_3, gWeaponData[Weapon_WorldModel], charsmax(gWeaponData[Weapon_WorldModel]));
		}
		case RZ_WEAPON_WEAPONLIST:
		{
			get_string(arg_3, gWeaponData[Weapon_WeaponList], charsmax(gWeaponData[Weapon_WeaponList]));
 
			if (gWeaponData[Weapon_WeaponList][0])
				register_clcmd(gWeaponData[Weapon_WeaponList], "@Command_SelectWeapon", index);
		}
		case RZ_WEAPON_BASE_DAMAGE:
		{
			gWeaponData[Weapon_BaseDamage] = get_float_byref(arg_3);
		}
		case RZ_WEAPON_BASE_DAMAGE2:
		{
			gWeaponData[Weapon_BaseDamage2] = get_float_byref(arg_3);
		}
		case RZ_WEAPON_KNOCKBACK_POWER:
		{
			gWeaponData[Weapon_KnockbackPower] = get_float_byref(arg_3);
		}
		default:
		{
			rz_log(true, "Weapon property '%d' not found for '%s'", prop, gWeaponData[Weapon_Handle]);
			return false;
		}
	}

	ArraySetArray(g_aWeapons, index, gWeaponData);
	return true;
}

@native_weapons_start(plugin, argc)
{
	return rz_module_get_offset(g_iModule_Weapons);
}

@native_weapons_find(plugin, argc)
{
	enum { arg_handle = 1 };

	new handle[RZ_MAX_HANDLE_LENGTH];
	get_string(arg_handle, handle, charsmax(handle));

	new i = ArrayFindString(g_aWeapons, handle);

	if (i != -1)
		return i + rz_module_get_offset(g_iModule_Weapons);

	return 0;
}

@native_weapons_size(plugin, argc)
{
	return ArraySize(g_aWeapons);
}

@native_weapons_valid(plugin, argc)
{
	enum { arg_weapon = 1 };

	new weapon = get_param(arg_weapon);

	if (!weapon)
		return false;

	return (rz_module_get_valid_index(g_iModule_Weapons, weapon) != -1);
}

@native_knife_create(plugin, argc)
{
	enum { arg_handle = 1 };

	new data[KnifeData];

	get_string(arg_handle, data[Knife_Handle], charsmax(data[Knife_Handle]));
	data[Knife_StabBaseDamage] = 65.0;
	data[Knife_SwingBaseDamage] = 15.0;
	data[Knife_StabDistance] = 32.0;
	data[Knife_SwingDistance] = 48.0;
	data[Knife_KnockbackPower] = -1.0;

	for (new RZKnifeSound:i = any:0; i < RZ_MAX_KNIFE_SOUNDS; i++)
		data[Knife_SoundsBank][i] = ArrayCreate(RZ_MAX_RESOURCE_PATH, 0);

	return ArrayPushArray(g_aKnives, data) + rz_module_get_offset(g_iModule_Knives);
}

@native_knife_get(plugin, argc)
{
	enum { arg_knife = 1, arg_prop, arg_3, arg_4 };

	new weapon = get_param(arg_knife);
	new index = rz_module_get_valid_index(g_iModule_Knives, weapon);

	RZ_CHECK_MODULE_VALID_INDEX(index, false)
	
	ArrayGetArray(g_aKnives, index, gKnifeData);

	new prop = get_param(arg_prop);

	switch (prop)
	{
		case RZ_KNIFE_HANDLE:
		{
			set_string(arg_3, gKnifeData[Knife_Handle], get_param_byref(arg_4));
		}
		case RZ_KNIFE_NAME:
		{
			set_string(arg_3, gKnifeData[Knife_Name], get_param_byref(arg_4));
		}
		case RZ_KNIFE_SHORT_NAME:
		{
			set_string(arg_3, gKnifeData[Knife_ShortName], get_param_byref(arg_4));
		}
		case RZ_KNIFE_VIEW_MODEL:
		{
			set_string(arg_3, gKnifeData[Knife_ViewModel], get_param_byref(arg_4));
		}
		case RZ_KNIFE_PLAYER_MODEL:
		{
			set_string(arg_3, gKnifeData[Knife_PlayerModel], get_param_byref(arg_4));
		}
		case RZ_KNIFE_WEAPONLIST:
		{
			set_string(arg_3, gKnifeData[Knife_WeaponList], get_param_byref(arg_4));
		}
		case RZ_KNIFE_STAB_BASE_DAMAGE:
		{
			return any:gKnifeData[Knife_StabBaseDamage];
		}
		case RZ_KNIFE_SWING_BASE_DAMAGE:
		{
			return any:gKnifeData[Knife_SwingBaseDamage];
		}
		case RZ_KNIFE_STAB_DISTANCE:
		{
			return any:gKnifeData[Knife_StabDistance];
		}
		case RZ_KNIFE_SWING_DISTANCE:
		{
			return any:gKnifeData[Knife_SwingDistance];
		}
		case RZ_KNIFE_KNOCKBACK_POWER:
		{
			return any:gKnifeData[Knife_KnockbackPower];
		}
		case RZ_KNIFE_SOUNDS_BANK:
		{
			new RZKnifeSound:knifeSound = any:get_param_byref(arg_3);
			
			return any:gKnifeData[Knife_SoundsBank][knifeSound];
		}
		default:
		{
			rz_log(true, "Knife property '%d' not found for '%s'", prop, gKnifeData[Knife_Handle]);
			return false;
		}
	}

	return true;
}

@native_knife_set(plugin, argc)
{
	enum { arg_knife = 1, arg_prop, arg_3, arg_element };

	new weapon = get_param(arg_knife);
	new index = rz_module_get_valid_index(g_iModule_Knives, weapon);

	RZ_CHECK_MODULE_VALID_INDEX(index, false)
	
	ArrayGetArray(g_aKnives, index, gKnifeData);

	new prop = get_param(arg_prop);

	switch (prop)
	{
		case RZ_KNIFE_HANDLE:
		{
			get_string(arg_3, gKnifeData[Knife_Handle], charsmax(gKnifeData[Knife_Handle]));
		}
		case RZ_KNIFE_NAME:
		{
			get_string(arg_3, gKnifeData[Knife_Name], charsmax(gKnifeData[Knife_Name]));
		}
		case RZ_KNIFE_SHORT_NAME:
		{
			get_string(arg_3, gKnifeData[Knife_ShortName], charsmax(gKnifeData[Knife_ShortName]));
		}
		case RZ_KNIFE_VIEW_MODEL:
		{
			get_string(arg_3, gKnifeData[Knife_ViewModel], charsmax(gKnifeData[Knife_ViewModel]));
		}
		case RZ_KNIFE_PLAYER_MODEL:
		{
			get_string(arg_3, gKnifeData[Knife_PlayerModel], charsmax(gKnifeData[Knife_PlayerModel]));
		}
		case RZ_KNIFE_WEAPONLIST:
		{
			get_string(arg_3, gKnifeData[Knife_WeaponList], charsmax(gKnifeData[Knife_WeaponList]));
 
			if (gKnifeData[Knife_WeaponList][0])
				register_clcmd(gKnifeData[Knife_WeaponList], "@Command_SelectKnife", index);
		}
		case RZ_KNIFE_STAB_BASE_DAMAGE:
		{
			gKnifeData[Knife_StabBaseDamage] = get_float_byref(arg_3);
		}
		case RZ_KNIFE_SWING_BASE_DAMAGE:
		{
			gKnifeData[Knife_SwingBaseDamage] = get_float_byref(arg_3);
		}
		case RZ_KNIFE_STAB_DISTANCE:
		{
			gKnifeData[Knife_StabDistance] = get_float_byref(arg_3);
		}
		case RZ_KNIFE_SWING_DISTANCE:
		{
			gKnifeData[Knife_SwingDistance] = get_float_byref(arg_3);
		}
		case RZ_KNIFE_KNOCKBACK_POWER:
		{
			gKnifeData[Knife_KnockbackPower] = get_float_byref(arg_3);
		}
		case RZ_KNIFE_SOUNDS_BANK:
		{
			new RZKnifeSound:knifeSound = any:get_param_byref(arg_element);

			gKnifeData[Knife_SoundsBank][knifeSound] = any:get_param_byref(arg_3);
		}
		default:
		{
			rz_log(true, "Knife property '%d' not found for '%s'", prop, gKnifeData[Knife_Handle]);
			return false;
		}
	}

	ArraySetArray(g_aKnives, index, gKnifeData);
	return true;
}

@native_knife_sound_add(plugin, argc)
{
	enum { arg_knife = 1, arg_knife_sound, arg_sample };

	new knife = get_param(arg_knife);
	new index = rz_module_get_valid_index(g_iModule_Knives, knife);

	RZ_CHECK_MODULE_VALID_INDEX(index, false)

	new RZKnifeSound:knifeSound = any:get_param(arg_knife_sound);
	new sample[RZ_MAX_RESOURCE_PATH];
	get_string(arg_sample, sample, charsmax(sample));

	precache_sound(sample);

	ArrayGetArray(g_aKnives, index, gKnifeData);
	ArrayPushString(gKnifeData[Knife_SoundsBank][knifeSound], sample);
	return true;
}

@native_knifes_start(plugin, argc)
{
	return rz_module_get_offset(g_iModule_Knives);
}

@native_knifes_find(plugin, argc)
{
	enum { arg_handle = 1 };

	new handle[RZ_MAX_HANDLE_LENGTH];
	get_string(arg_handle, handle, charsmax(handle));

	new i = ArrayFindString(g_aKnives, handle);

	if (i != -1)
		return i + rz_module_get_offset(g_iModule_Knives);

	return 0;
}

@native_knifes_size(plugin, argc)
{
	return ArraySize(g_aKnives);
}

@native_knifes_valid(plugin, argc)
{
	enum { arg_knife = 1 };

	new knife = get_param(arg_knife);

	if (!knife)
		return false;

	return (rz_module_get_valid_index(g_iModule_Knives, knife) != -1);
}

@native_grenade_create(plugin, argc)
{
	enum { arg_handle = 1, arg_reference };

	new data[GrenadeData];

	// check handle available
	// check ref valid

	get_string(arg_handle, data[Grenade_Handle], charsmax(data[Grenade_Handle]));
	get_string(arg_reference, data[Grenade_Reference], charsmax(data[Grenade_Reference]));

	return ArrayPushArray(g_aGrenades, data) + rz_module_get_offset(g_iModule_Grenades);
}

@native_grenade_get(plugin, argc)
{
	enum { arg_grenade = 1, arg_prop, arg_3, arg_4 };

	new grenade = get_param(arg_grenade);
	new index = rz_module_get_valid_index(g_iModule_Grenades, grenade);

	RZ_CHECK_MODULE_VALID_INDEX(index, false)
	
	ArrayGetArray(g_aGrenades, index, gGrenadeData);

	new prop = get_param(arg_prop);

	switch (prop)
	{
		case RZ_WEAPON_HANDLE:
		{
			set_string(arg_3, gGrenadeData[Grenade_Handle], get_param_byref(arg_4));
		}
		case RZ_WEAPON_REFERENCE:
		{
			set_string(arg_3, gGrenadeData[Grenade_Reference], get_param_byref(arg_4));
		}
		case RZ_WEAPON_NAME:
		{
			set_string(arg_3, gGrenadeData[Grenade_Name], get_param_byref(arg_4));
		}
		case RZ_WEAPON_SHORT_NAME:
		{
			set_string(arg_3, gGrenadeData[Grenade_ShortName], get_param_byref(arg_4));
		}
		case RZ_WEAPON_VIEW_MODEL:
		{
			set_string(arg_3, gGrenadeData[Grenade_ViewModel], get_param_byref(arg_4));
		}
		case RZ_WEAPON_PLAYER_MODEL:
		{
			set_string(arg_3, gGrenadeData[Grenade_PlayerModel], get_param_byref(arg_4));
		}
		case RZ_WEAPON_WORLD_MODEL:
		{
			set_string(arg_3, gGrenadeData[Grenade_WorldModel], get_param_byref(arg_4));
		}
		case RZ_WEAPON_WEAPONLIST:
		{
			set_string(arg_3, gGrenadeData[Grenade_WeaponList], get_param_byref(arg_4));
		}
		default:
		{
			rz_log(true, "Grenade property '%d' not found for '%s'", prop, gGrenadeData[Grenade_Handle]);
			return false;
		}
	}

	return true;
}

@native_grenade_set(plugin, argc)
{
	enum { arg_grenade = 1, arg_prop, arg_3 };

	new grenade = get_param(arg_grenade);
	new index = rz_module_get_valid_index(g_iModule_Grenades, grenade);

	RZ_CHECK_MODULE_VALID_INDEX(index, false)
	
	ArrayGetArray(g_aGrenades, index, gGrenadeData);

	new prop = get_param(arg_prop);

	switch (prop)
	{
		case RZ_WEAPON_HANDLE:
		{
			get_string(arg_3, gGrenadeData[Grenade_Handle], charsmax(gGrenadeData[Grenade_Handle]));
		}
		case RZ_WEAPON_REFERENCE:
		{
			get_string(arg_3, gGrenadeData[Grenade_Reference], charsmax(gGrenadeData[Grenade_Reference]));
		}
		case RZ_WEAPON_NAME:
		{
			get_string(arg_3, gGrenadeData[Grenade_Name], charsmax(gGrenadeData[Grenade_Name]));
		}
		case RZ_WEAPON_SHORT_NAME:
		{
			get_string(arg_3, gGrenadeData[Grenade_ShortName], charsmax(gGrenadeData[Grenade_ShortName]));
		}
		case RZ_WEAPON_VIEW_MODEL:
		{
			get_string(arg_3, gGrenadeData[Grenade_ViewModel], charsmax(gGrenadeData[Grenade_ViewModel]));
		}
		case RZ_WEAPON_PLAYER_MODEL:
		{
			get_string(arg_3, gGrenadeData[Grenade_PlayerModel], charsmax(gGrenadeData[Grenade_PlayerModel]));
		}
		case RZ_WEAPON_WORLD_MODEL:
		{
			get_string(arg_3, gGrenadeData[Grenade_WorldModel], charsmax(gGrenadeData[Grenade_WorldModel]));
		}
		case RZ_WEAPON_WEAPONLIST:
		{
			get_string(arg_3, gGrenadeData[Grenade_WeaponList], charsmax(gGrenadeData[Grenade_WeaponList]));
 
			if (gGrenadeData[Grenade_WeaponList][0])
				register_clcmd(gGrenadeData[Grenade_WeaponList], "@Command_SelectGrenade", index);
		}
		default:
		{
			rz_log(true, "Grenade property '%d' not found for '%s'", prop, gGrenadeData[Grenade_Handle]);
			return false;
		}
	}

	ArraySetArray(g_aGrenades, index, gGrenadeData);
	return true;
}

@native_grenades_start(plugin, argc)
{
	return rz_module_get_offset(g_iModule_Grenades);
}

@native_grenades_find(plugin, argc)
{
	enum { arg_handle = 1 };

	new handle[RZ_MAX_HANDLE_LENGTH];
	get_string(arg_handle, handle, charsmax(handle));

	new i = ArrayFindString(g_aGrenades, handle);

	if (i != -1)
		return i + rz_module_get_offset(g_iModule_Grenades);

	return 0;
}

@native_grenades_size(plugin, argc)
{
	return ArraySize(g_aGrenades);
}

@native_grenades_valid(plugin, argc)
{
	enum { arg_grenade = 1 };

	new grenade = get_param(arg_grenade);

	if (!grenade)
		return false;

	return (rz_module_get_valid_index(g_iModule_Grenades, grenade) != -1);
}
