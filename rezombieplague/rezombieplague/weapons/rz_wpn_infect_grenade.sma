#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <reapi>
#include <rezp>
#include <util_tempentities>

new const INFECTION_VIEW_MODEL[] = "models/zombie_plague/v_grenade_infect.mdl";
new const INFECTION_EXPLODE_SOUND[] = "zombie_plague/grenade_infect.wav";

new g_iModelIndex_LaserBeam;
new g_iModelIndex_ShockWave;

new g_iGrenade_Infect;

new g_iClass_Zombie;
new g_iClass_Human;

public plugin_precache()
{
	register_plugin("[ReZP] Grenade: Infection", REZP_VERSION_STR, "fl0wer");

	RZ_CHECK_CLASS_EXISTS(g_iClass_Zombie, "class_zombie");
	RZ_CHECK_CLASS_EXISTS(g_iClass_Human, "class_human");

	precache_sound(INFECTION_EXPLODE_SOUND);

	g_iModelIndex_LaserBeam = precache_model("sprites/laserbeam.spr");
	g_iModelIndex_ShockWave = precache_model("sprites/shockwave.spr");

	new grenade = g_iGrenade_Infect = rz_grenade_create("grenade_infect", "weapon_hegrenade");

	rz_grenade_set(grenade, RZ_GRENADE_NAME, "RZ_WPN_INFECT_GRENADE");
	rz_grenade_set(grenade, RZ_GRENADE_VIEW_MODEL, INFECTION_VIEW_MODEL);
}

public rz_grenades_throw_post(id, entity, grenade)
{
	if (grenade != g_iGrenade_Infect)
		return;

	rz_util_set_rendering(entity, kRenderNormal, 16.0, Float:{ 0.0, 200.0, 0.0 }, kRenderFxGlowShell);

	message_begin_f(MSG_ALL, SVC_TEMPENTITY);
	TE_BeamFollow(entity, g_iModelIndex_LaserBeam, 10, 10, { 0, 200, 0 }, 200);
}

public rz_grenades_explode_pre(id, grenade)
{
	if (grenade != g_iGrenade_Infect)
		return RZ_CONTINUE;

	new owner = get_entvar(id, var_owner);

	new Float:vecOrigin[3];
	new Float:vecOrigin2[3];
	new Float:vecAxis[3];

	get_entvar(id, var_origin, vecOrigin);

	vecAxis = vecOrigin;
	vecAxis[2] += 555.0;

	message_begin_f(MSG_PVS, SVC_TEMPENTITY, vecOrigin);
	TE_BeamCylinder(vecOrigin, vecAxis, g_iModelIndex_ShockWave, 0, 0, 4, 60, 0, { 0, 200, 0 }, 200, 0);

	rh_emit_sound2(id, 0, CHAN_WEAPON, INFECTION_EXPLODE_SOUND, VOL_NORM, ATTN_NORM);

	if (!is_user_connected(owner) && rz_player_get(owner, RZ_PLAYER_CLASS) != g_iClass_Zombie)
		owner = 0;

	for (new i = 1; i <= MaxClients; i++)
	{
		if (!is_user_alive(i))
			continue;

		get_entvar(i, var_origin, vecOrigin2);

		if (vector_distance(vecOrigin, vecOrigin2) > 350.0)
			continue;

		if (!ExecuteHamB(Ham_FVisible, i, id))
			continue;

		if (rz_player_get(i, RZ_PLAYER_CLASS) != g_iClass_Human)
			continue;

		rz_class_player_change(i, owner, g_iClass_Zombie);
	}

	return RZ_BREAK;
}
