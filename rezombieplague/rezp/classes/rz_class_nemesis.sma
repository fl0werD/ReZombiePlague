#pragma semicolon 1

#include <amxmodx>
#include <reapi>
#include <rezp>

new g_iClass_Nemesis;

public plugin_precache()
{
	register_plugin("[ReZP] Class: Nemesis", REZP_VERSION_STR, "fl0wer");

	new class = g_iClass_Nemesis = rz_class_create("nemesis", TEAM_TERRORIST);
	new props = rz_props_create("nemesis_props");
	new playerModel = rz_playermodel_create("nemesis_models");
	new playerSound = rz_playersound_create("nemesis_sounds");

	rz_class_set_name_langkey(class, "RZ_NEMESIS");
	rz_class_set_hudcolor(class, { 250, 250, 10 });
	rz_class_set_props(class, props);
	rz_class_set_playermodel(class, playerModel);
	rz_class_set_playersound(class, playerSound);
	rz_class_set_melee(class, rz_melee_create("models/zombie_plague/v_knife_zombie.mdl", "hide"));
	rz_class_set_nightvision(class, rz_nightvision_create(2, { 150, 0, 0 }, 63));

	rz_props_set_basehealth(props, 2000);
	rz_props_set_gravity(props, 0.5);
	rz_props_set_speed(props, 265);
	rz_props_set_footsteps(props, false);

	rz_playermodel_add(playerModel, "zombie_source", false);

	rz_playersound_add(playerSound, PL_PAIN_SOUND_BHIT_FLESH, "zombie_plague/nemesis_pain1.wav");
	rz_playersound_add(playerSound, PL_PAIN_SOUND_BHIT_FLESH, "zombie_plague/nemesis_pain2.wav");
	rz_playersound_add(playerSound, PL_PAIN_SOUND_BHIT_FLESH, "zombie_plague/nemesis_pain3.wav");
}

public plugin_init()
{
	RegisterHookChain(RG_CBasePlayer_Killed, "@CBasePlayer_Killed_Pre", false);
}

public rz_frost_grenade_freeze_pre(id)
{
	if (rz_class_player_get(id) != g_iClass_Nemesis)
		return RZ_CONTINUE;

	return RZ_SUPERCEDE;
}

@CBasePlayer_Killed_Pre(id, attacker, gib)
{
	if (rz_class_player_get(id) == g_iClass_Nemesis)
	{
		SetHookChainArg(3, ATYPE_INTEGER, GIB_ALWAYS);
		return;
	}

	if (id == attacker || !is_user_connected(attacker))
		return;

	if (rz_class_player_get(attacker) != g_iClass_Nemesis)
		return;

	SetHookChainArg(3, ATYPE_INTEGER, GIB_ALWAYS);
}
