#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <reapi>
#include <rezp>
#include <rezp_util>

new const Float:kb_weapon_power[] = 
{
	-1.0,	// ---
	2.4,	// P228
	-1.0,	// ---
	6.5,	// SCOUT
	-1.0,	// ---
	8.0,	// XM1014
	-1.0,	// ---
	2.3,	// MAC10
	5.0,	// AUG
	-1.0,	// ---
	2.4,	// ELITE
	2.0,	// FIVESEVEN
	2.4,	// UMP45
	5.3,	// SG550
	5.5,	// GALIL
	5.5,	// FAMAS
	2.2,	// USP
	2.0,	// GLOCK18
	10.0,	// AWP
	2.5,	// MP5NAVY
	5.2,	// M249
	8.0,	// M3
	5.0,	// M4A1
	2.4,	// TMP
	6.5,	// G3SG1
	-1.0,	// ---
	5.3,	// DEAGLE
	5.0,	// SG552
	6.0,	// AK47
	-1.0,	// ---
	2.0		// P90
};

enum _:PropsData
{
	Prop_Name[32],
	Float:Prop_Health,
	Float:Prop_BaseHealth,
	Prop_Armor,
	bool:Prop_Helmet,
	Float:Prop_Speed,
	Float:Prop_Gravity,
	bool:Prop_Footsteps,
	Float:Prop_VelModFlinch,
	Float:Prop_VelModLargeFlinch,
	Float:Prop_Knockback,
	Prop_BloodColor,

}; new Array:g_aProps;

new g_iProps[MAX_PLAYERS + 1];
new Float:g_flOldVelocityModifier[MAX_PLAYERS + 1];
new Float:g_vecOldVelocity[MAX_PLAYERS + 1][3];

new g_iDefaultProps;

new g_iModule;

public plugin_precache()
{
	register_plugin("[ReZP] Player: Properties", REZP_VERSION_STR, "fl0wer");

	g_aProps = ArrayCreate(PropsData, 0);
	g_iModule = rz_module_create("player_props", g_aProps);

	g_iDefaultProps = rz_props_create("default_props");
}

public plugin_init()
{
	RegisterHookChain(RG_CBasePlayer_Spawn, "@CBasePlayer_Spawn_Post", true);
	RegisterHookChain(RG_CBasePlayer_TraceAttack, "@CBasePlayer_TraceAttack_Post", true);
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "@CBasePlayer_TakeDamage_Pre", false);
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "@CBasePlayer_TakeDamage_Post", true);
	RegisterHookChain(RG_CBasePlayer_ResetMaxSpeed, "@CBasePlayer_ResetMaxSpeed_Pre", false);
}

public rz_class_change_post(id, attacker, class)
{
	ChangeProps(id);
}

@CBasePlayer_Spawn_Post(id)
{
	if (!is_user_alive(id))
		return;

	ChangeProps(id, true);
}

@CBasePlayer_TraceAttack_Post(id, attacker, Float:damage, Float:vecDir[3], tr, bitsDamageType)
{
	if (!(bitsDamageType & (DMG_NEVERGIB | DMG_BULLET)))
		return;

	if (id == attacker || !is_user_connected(attacker))
		return;

	if (!rg_is_player_can_takedamage(id, attacker))
		return;

	//if (damage <= 0.0 || GetHamReturnStatus() == HAM_SUPERCEDE)
	//	return;
	
	/*static origin1[3], origin2[3]
	get_user_origin(victim, origin1)
	get_user_origin(attacker, origin2)
	
	if (get_distance(origin1, origin2) > get_pcvar_num(cvar_knockback_distance))
		return;*/
	
	new Float:weaponPower = 1.0;
	new Float:ducking = 1.0;
	new Float:knockback = 1.0;
	new Float:vecVelocity[3];

	get_entvar(id, var_velocity, vecVelocity);
	
	new attacker_weapon = get_user_weapon(attacker);
	
	if (kb_weapon_power[attacker_weapon] > 0.0)
		weaponPower = kb_weapon_power[attacker_weapon];
	
	if (get_entvar(id, var_flags) & (FL_DUCKING | FL_ONGROUND) == (FL_DUCKING | FL_ONGROUND))
		ducking = 0.25;
	
	//if (dawdaw)
	knockback = 2.0;

	for (new i = 0; i < 3; i++)
		vecVelocity[i] += vecDir[i] * damage * weaponPower * ducking * knockback;
	
	//if (!get_pcvar_num(cvar_knockback_zvel))
	//	direction[2] = vecVelocity[2]
	
	set_entvar(id, var_velocity, vecVelocity);
}

@CBasePlayer_TakeDamage_Pre(id, inflictor, attacker, Float:damage, bitsDamageType)
{
	if (!(bitsDamageType & (DMG_NEVERGIB | DMG_BULLET)))
		return;

	if (!rg_is_player_can_takedamage(id, attacker))
		return;

	g_flOldVelocityModifier[id] = get_member(id, m_flVelocityModifier);

	get_entvar(id, var_velocity, g_vecOldVelocity[id]);
}

@CBasePlayer_TakeDamage_Post(id, inflictor, attacker, Float:damage, bitsDamageType)
{
	if (!(bitsDamageType & (DMG_NEVERGIB | DMG_BULLET)))
		return;

	if (id == attacker || !is_user_connected(attacker))
		return;

	if (!rg_is_player_can_takedamage(id, attacker))
		return;

	if (!is_user_alive(id))
		return;

	new index = rz_module_get_valid_index(g_iModule, g_iProps[id]);

	if (index == -1)
		return;

	new data[PropsData];
	ArrayGetArray(g_aProps, index, data);

	switch (get_member(id, m_flVelocityModifier))
	{
		case 0.5:
		{
			// e floats?
			if (g_flOldVelocityModifier[id] != 0.5)
				set_member(id, m_flVelocityModifier, data[Prop_VelModFlinch]);
		}
		case 0.65:
		{
			if (g_flOldVelocityModifier[id] != 0.65)
				set_member(id, m_flVelocityModifier, data[Prop_VelModLargeFlinch]);

			new Float:vecOrigin[3];
			new Float:vecOrigin2[3];
			new Float:vecVelocity[3];
			new Float:vecAttackVelocity[3];
			new Float:vecTemp[3];

			get_entvar(id, var_origin, vecOrigin);
			get_entvar(attacker, var_origin, vecOrigin2);

			for (new i = 0; i < 3; i++)
				vecTemp[i] = vecOrigin[i] - vecOrigin2[i];

			new Float:length = floatsqroot(vecTemp[0] * vecTemp[0] + vecTemp[1] * vecTemp[1] + vecTemp[2] * vecTemp[2]);

			if (length != 0.0)
			{
				length = 1.0 / length;

				for (new i = 0; i < 3; i++)
					vecAttackVelocity[i] *= length;
			}
			else
				vecAttackVelocity = Float:{ 0.0, 0.0, 1.0 };

			for (new i = 0; i < 3; i++)
				vecVelocity[i] = g_vecOldVelocity[id][i] + vecAttackVelocity[i] * 1000.0;

			set_entvar(id, var_velocity, vecVelocity);
		}
		default:
		{
		}
	}
}

@CBasePlayer_ResetMaxSpeed_Pre(id)
{
	if (!is_user_alive(id))
		return HC_CONTINUE;

	new index;
	new props = g_iProps[id];

	if (props)
	{
		index = rz_module_get_valid_index(g_iModule, props);

		if (index == -1)
			return HC_CONTINUE;
	}
	
	new Float:speed;
	new data[PropsData];

	ArrayGetArray(g_aProps, index, data);

	if (!data[Prop_Speed])
	{
		new activeItem = get_member(id, m_pActiveItem);
		
		if (!is_nullent(activeItem))
			ExecuteHamB(Ham_CS_Item_GetMaxSpeed, activeItem, speed);
		else
			speed = 240.0;
	}
	else
		speed = data[Prop_Speed];

	set_entvar(id, var_maxspeed, speed);
	return HC_SUPERCEDE;
}

ChangeProps(id, bool:spawn = false)
{
	new index;
	new props = g_iProps[id];

	if (props)
	{
		index = rz_module_get_valid_index(g_iModule, props);

		if (index == -1)
			return false;
	}
	
	new Float:health;
	new data[PropsData];

	ArrayGetArray(g_aProps, index, data);

	if (data[Prop_BaseHealth])
		health = data[Prop_BaseHealth] * rz_game_get_alivesnum();
	else
		health = data[Prop_Health];

	set_entvar(id, var_health, health);
	set_entvar(id, var_max_health, health);
	set_entvar(id, var_gravity, data[Prop_Gravity]);
	set_member(id, m_bloodColor, data[Prop_BloodColor]);
	rg_set_user_footsteps(id, !data[Prop_Footsteps]);

	if (spawn)
	{
		new ArmorType:armorType;
		new armor = rg_get_user_armor(id, armorType);

		if (data[Prop_Armor])
			armorType = data[Prop_Helmet] ? ARMOR_VESTHELM : ARMOR_KEVLAR;

		if (armor < data[Prop_Armor] || get_member(id, m_iKevlar) < armorType)
			rg_set_user_armor(id, max(data[Prop_Armor], armor), armorType);
	}
	else
	{
		if (data[Prop_Armor])
			rg_set_user_armor(id, data[Prop_Armor], data[Prop_Helmet] ? ARMOR_VESTHELM : ARMOR_KEVLAR);
		else
			rg_set_user_armor(id, 0, ARMOR_NONE);
	}

	return true;
}

public plugin_natives()
{
	register_native("rz_props_create", "@native_props_create");

	register_native("rz_props_get_health", "@native_props_get_health");
	register_native("rz_props_set_health", "@native_props_set_health");

	register_native("rz_props_get_basehealth", "@native_props_get_basehealth");
	register_native("rz_props_set_basehealth", "@native_props_set_basehealth");

	register_native("rz_props_get_armor", "@native_props_get_armor");
	register_native("rz_props_set_armor", "@native_props_set_armor");

	register_native("rz_props_get_helmet", "@native_props_get_helmet");
	register_native("rz_props_set_helmet", "@native_props_set_helmet");

	register_native("rz_props_get_gravity", "@native_props_get_gravity");
	register_native("rz_props_set_gravity", "@native_props_set_gravity");

	register_native("rz_props_get_speed", "@native_props_get_speed");
	register_native("rz_props_set_speed", "@native_props_set_speed");

	register_native("rz_props_get_footsteps", "@native_props_get_footsteps");
	register_native("rz_props_set_footsteps", "@native_props_set_footsteps");

	register_native("rz_props_get_velmod_flinch", "@native_props_get_velmod_flinch");
	register_native("rz_props_set_velmod_flinch", "@native_props_set_velmod_flinch");

	register_native("rz_props_get_velmod_largeflinch", "@native_props_get_velmod_largeflinch");
	register_native("rz_props_set_velmod_largeflinch", "@native_props_set_velmod_largeflinch");

	register_native("rz_props_get_knockback", "@native_props_get_knockback");
	register_native("rz_props_set_knockback", "@native_props_set_knockback");

	register_native("rz_props_get_bloodcolor", "@native_props_get_bloodcolor");
	register_native("rz_props_set_bloodcolor", "@native_props_set_bloodcolor");

	register_native("rz_props_player_get", "@native_props_player_get");
	register_native("rz_props_player_set", "@native_props_player_set");
	register_native("rz_props_player_change", "@native_props_player_change");
}

@native_props_create(plugin, argc)
{
	enum { arg_name };

	new data[PropsData];

	get_string(arg_name, data[Prop_Name], charsmax(data[Prop_Name]));
	data[Prop_Health] = 100.0;
	data[Prop_BaseHealth] = 0.0;
	data[Prop_Armor] = 0;
	data[Prop_Helmet] = false;
	data[Prop_Gravity] = 1.0;
	data[Prop_Speed] = 0.0;
	data[Prop_Footsteps] = true;
	data[Prop_VelModFlinch] = 0.5;
	data[Prop_VelModLargeFlinch] = 0.65;
	data[Prop_Knockback] = 0.0;
	data[Prop_BloodColor] = 247;

	return ArrayPushArray(g_aProps, data) + rz_module_get_offset(g_iModule);
}

@native_props_get_health(plugin, argc)
{
	enum { arg_props = 1 };

	new props = get_param(arg_props);
	new index = rz_module_get_valid_index(g_iModule, props);

	CHECK_MODULE_VALID_INDEX(index, 0)

	new data[PropsData];
	ArrayGetArray(g_aProps, index, data);

	return floatround(data[Prop_Health]);
}

@native_props_set_health(plugin, argc)
{
	enum { arg_props = 1, arg_health };

	new props = get_param(arg_props);
	new index = rz_module_get_valid_index(g_iModule, props);

	CHECK_MODULE_VALID_INDEX(index, 0)

	new data[PropsData];
	ArrayGetArray(g_aProps, index, data);
	data[Prop_Health] = float(get_param(arg_health));
	ArraySetArray(g_aProps, index, data);

	return true;
}

@native_props_get_basehealth(plugin, argc)
{
	enum { arg_props = 1 };

	new props = get_param(arg_props);
	new index = rz_module_get_valid_index(g_iModule, props);

	CHECK_MODULE_VALID_INDEX(index, 0)

	new data[PropsData];
	ArrayGetArray(g_aProps, index, data);

	return floatround(data[Prop_BaseHealth]);
}

@native_props_set_basehealth(plugin, argc)
{
	enum { arg_props = 1, arg_base_health };

	new props = get_param(arg_props);
	new index = rz_module_get_valid_index(g_iModule, props);

	CHECK_MODULE_VALID_INDEX(index, 0)

	new data[PropsData];
	ArrayGetArray(g_aProps, index, data);
	data[Prop_BaseHealth] = float(get_param(arg_base_health));
	ArraySetArray(g_aProps, index, data);

	return true;
}

@native_props_get_armor(plugin, argc)
{
	enum { arg_props = 1 };

	new props = get_param(arg_props);
	new index = rz_module_get_valid_index(g_iModule, props);

	CHECK_MODULE_VALID_INDEX(index, 0)

	new data[PropsData];
	ArrayGetArray(g_aProps, index, data);

	return data[Prop_Armor];
}

@native_props_set_armor(plugin, argc)
{
	enum { arg_props = 1, arg_armor };

	new props = get_param(arg_props);
	new index = rz_module_get_valid_index(g_iModule, props);

	CHECK_MODULE_VALID_INDEX(index, 0)

	new data[PropsData];
	ArrayGetArray(g_aProps, index, data);
	data[Prop_Armor] = get_param(arg_armor);
	ArraySetArray(g_aProps, index, data);

	return true;
}

@native_props_get_helmet(plugin, argc)
{
	enum { arg_props = 1 };

	new props = get_param(arg_props);
	new index = rz_module_get_valid_index(g_iModule, props);

	CHECK_MODULE_VALID_INDEX(index, 0)

	new data[PropsData];
	ArrayGetArray(g_aProps, index, data);

	return any:data[Prop_Helmet];
}

@native_props_set_helmet(plugin, argc)
{
	enum { arg_props = 1, arg_enabled };

	new props = get_param(arg_props);
	new index = rz_module_get_valid_index(g_iModule, props);

	CHECK_MODULE_VALID_INDEX(index, 0)

	new data[PropsData];
	ArrayGetArray(g_aProps, index, data);
	data[Prop_Helmet] = bool:get_param(arg_enabled);
	ArraySetArray(g_aProps, index, data);

	return true;
}

@native_props_get_gravity(plugin, argc)
{
	enum { arg_props = 1 };

	new props = get_param(arg_props);
	new index = rz_module_get_valid_index(g_iModule, props);

	CHECK_MODULE_VALID_INDEX(index, 0)

	new data[PropsData];
	ArrayGetArray(g_aProps, index, data);

	return any:data[Prop_Gravity];
}

@native_props_set_gravity(plugin, argc)
{
	enum { arg_props = 1, arg_gravity };

	new props = get_param(arg_props);
	new index = rz_module_get_valid_index(g_iModule, props);

	CHECK_MODULE_VALID_INDEX(index, 0)

	new data[PropsData];
	ArrayGetArray(g_aProps, index, data);
	data[Prop_Gravity] = get_param_f(arg_gravity);
	ArraySetArray(g_aProps, index, data);

	return true;
}

@native_props_get_speed(plugin, argc)
{
	enum { arg_props = 1 };

	new props = get_param(arg_props);
	new index = rz_module_get_valid_index(g_iModule, props);

	CHECK_MODULE_VALID_INDEX(index, 0)

	new data[PropsData];
	ArrayGetArray(g_aProps, index, data);

	return any:data[Prop_Speed];
}

@native_props_set_speed(plugin, argc)
{
	enum { arg_props = 1, arg_speed };

	new props = get_param(arg_props);
	new index = rz_module_get_valid_index(g_iModule, props);

	CHECK_MODULE_VALID_INDEX(index, 0)

	new data[PropsData];
	ArrayGetArray(g_aProps, index, data);
	data[Prop_Speed] = float(get_param(arg_speed));
	ArraySetArray(g_aProps, index, data);

	return true;
}

@native_props_get_footsteps(plugin, argc)
{
	enum { arg_props = 1 };

	new props = get_param(arg_props);
	new index = rz_module_get_valid_index(g_iModule, props);

	CHECK_MODULE_VALID_INDEX(index, 0)

	new data[PropsData];
	ArrayGetArray(g_aProps, index, data);

	return any:data[Prop_Footsteps];
}

@native_props_set_footsteps(plugin, argc)
{
	enum { arg_props = 1, arg_enabled };

	new props = get_param(arg_props);
	new index = rz_module_get_valid_index(g_iModule, props);

	CHECK_MODULE_VALID_INDEX(index, 0)

	new data[PropsData];
	ArrayGetArray(g_aProps, index, data);
	data[Prop_Footsteps] = bool:get_param(arg_enabled);
	ArraySetArray(g_aProps, index, data);

	return true;
}

@native_props_get_velmod_flinch(plugin, argc)
{
	enum { arg_props = 1 };

	new props = get_param(arg_props);
	new index = rz_module_get_valid_index(g_iModule, props);

	CHECK_MODULE_VALID_INDEX(index, 0)

	new data[PropsData];
	ArrayGetArray(g_aProps, index, data);

	return any:data[Prop_VelModFlinch];
}

@native_props_set_velmod_flinch(plugin, argc)
{
	enum { arg_props = 1, arg_vel_mod_flinch };

	new props = get_param(arg_props);
	new index = rz_module_get_valid_index(g_iModule, props);

	CHECK_MODULE_VALID_INDEX(index, 0)

	new data[PropsData];
	ArrayGetArray(g_aProps, index, data);
	data[Prop_VelModFlinch] = get_param_f(arg_vel_mod_flinch);
	ArraySetArray(g_aProps, index, data);

	return true;
}

@native_props_get_velmod_largeflinch(plugin, argc)
{
	enum { arg_props = 1 };

	new props = get_param(arg_props);
	new index = rz_module_get_valid_index(g_iModule, props);

	CHECK_MODULE_VALID_INDEX(index, 0)

	new data[PropsData];
	ArrayGetArray(g_aProps, index, data);

	return any:data[Prop_VelModLargeFlinch];
}

@native_props_set_velmod_largeflinch(plugin, argc)
{
	enum { arg_props = 1, arg_vel_mod_large_flinch };

	new props = get_param(arg_props);
	new index = rz_module_get_valid_index(g_iModule, props);

	CHECK_MODULE_VALID_INDEX(index, 0)

	new data[PropsData];
	ArrayGetArray(g_aProps, index, data);
	data[Prop_VelModLargeFlinch] = get_param_f(arg_vel_mod_large_flinch);
	ArraySetArray(g_aProps, index, data);

	return true;
}

@native_props_get_knockback(plugin, argc)
{
	enum { arg_props = 1 };

	new props = get_param(arg_props);
	new index = rz_module_get_valid_index(g_iModule, props);

	CHECK_MODULE_VALID_INDEX(index, 0)

	new data[PropsData];
	ArrayGetArray(g_aProps, index, data);

	return any:data[Prop_Knockback];
}

@native_props_set_knockback(plugin, argc)
{
	enum { arg_props = 1, arg_knockback };

	new props = get_param(arg_props);
	new index = rz_module_get_valid_index(g_iModule, props);

	CHECK_MODULE_VALID_INDEX(index, 0)

	new data[PropsData];
	ArrayGetArray(g_aProps, index, data);
	data[Prop_Knockback] = get_param_f(arg_knockback);
	ArraySetArray(g_aProps, index, data);

	return true;
}

@native_props_get_bloodcolor(plugin, argc)
{
	enum { arg_props = 1 };

	new props = get_param(arg_props);
	new index = rz_module_get_valid_index(g_iModule, props);

	CHECK_MODULE_VALID_INDEX(index, 0)

	new data[PropsData];
	ArrayGetArray(g_aProps, index, data);

	return data[Prop_BloodColor];
}

@native_props_set_bloodcolor(plugin, argc)
{
	enum { arg_props = 1, arg_blood_color };

	new props = get_param(arg_props);
	new index = rz_module_get_valid_index(g_iModule, props);

	CHECK_MODULE_VALID_INDEX(index, 0)

	new data[PropsData];
	ArrayGetArray(g_aProps, index, data);
	data[Prop_BloodColor] = bool:get_param(arg_blood_color);
	ArraySetArray(g_aProps, index, data);

	return true;
}

@native_props_player_get(plugin, argc)
{
	enum { arg_player = 1 };

	new player = get_param(arg_player);
	new props = g_iProps[player];
	new index = rz_module_get_valid_index(g_iModule, props);

	CHECK_MODULE_VALID_INDEX(index, 0)

	return props;
}

@native_props_player_set(plugin, argc)
{
	enum { arg_player = 1, arg_props };

	new player = get_param(arg_player);
	new props = get_param(arg_props);

	if (props)
	{
		new index = rz_module_get_valid_index(g_iModule, props);

		CHECK_MODULE_VALID_INDEX(index, false)
	}
	else
		props = g_iDefaultProps;

	g_iProps[player] = props;
	return true;
}

@native_props_player_change(plugin, argc)
{
	enum { arg_player = 1 };

	new player = get_param(arg_player);
	CHECK_ALIVE(player, false)

	/*new attacker = get_param(arg_attacker);
	new class = get_param(arg_class);
	new index = rz_module_get_valid_index(g_iModule, class);

	CHECK_MODULE_VALID_INDEX(index, false)*/

	return ChangeProps(player);
}
