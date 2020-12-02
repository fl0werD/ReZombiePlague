#pragma semicolon 1

#include <amxmodx>
#include <reapi>
#include <rezp>

new g_iClass_Assassin;

public plugin_precache()
{
	register_plugin("[ReZP] Class: Assassin", REZP_VERSION_STR, "fl0wer");

	new class = g_iClass_Assassin = rz_class_create("assassin", TEAM_TERRORIST);
	new props = rz_props_create("assassin_props");
	new playerModel = rz_playermodel_create("assassin_models");

	rz_class_set_name_langkey(class, "RZ_ASSASSIN");
	rz_class_set_hudcolor(class, { 250, 250, 10 });
	rz_class_set_props(class, props);
	rz_class_set_playermodel(class, playerModel);
	rz_class_set_playersound(class, rz_playersound_find("zombie_sounds"));
	rz_class_set_melee(class, rz_melee_create("models/zombie_plague/v_knife_zombie.mdl", "hide", _, 10.0));
	rz_class_set_nightvision(class, rz_nightvision_create(2, { 150, 150, 0 }, 63));

	rz_props_set_basehealth(props, 100);
	rz_props_set_gravity(props, 0.4);
	rz_props_set_speed(props, 600);
	rz_props_set_bloodcolor(props, 195);

	rz_playermodel_add(playerModel, "zombie_source");
}

public plugin_init()
{
	RegisterHookChain(RG_CBasePlayer_Killed, "@CBasePlayer_Killed_Pre", false);
}

public rz_fire_grenade_burn_pre(id)
{
	if (rz_class_player_get(id) != g_iClass_Assassin)
		return RZ_CONTINUE;

	return RZ_SUPERCEDE;
}

public rz_frost_grenade_freeze_pre(id)
{
	if (rz_class_player_get(id) != g_iClass_Assassin)
		return RZ_CONTINUE;

	return RZ_SUPERCEDE;
}

@CBasePlayer_Killed_Pre(id, attacker, gib)
{
	if (rz_class_player_get(id) == g_iClass_Assassin)
	{
		SetHookChainArg(3, ATYPE_INTEGER, GIB_ALWAYS);
		return;
	}

	if (id == attacker || !is_user_connected(attacker))
		return;

	if (rz_class_player_get(attacker) != g_iClass_Assassin)
		return;

	SetHookChainArg(3, ATYPE_INTEGER, GIB_ALWAYS);
}
