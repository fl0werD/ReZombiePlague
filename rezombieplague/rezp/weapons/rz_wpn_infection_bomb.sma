#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <reapi>
#include <rezp>
#include <rezp_util>
#include <util_tempentities>

new const INFECTION_VIEW_MODEL[] = "models/zombie_plague/v_grenade_infect.mdl";
new const INFECTION_EXPLODE_SOUND[] = "zombie_plague/grenade_infect.wav";

new g_iModelIndex_LaserBeam;
new g_iModelIndex_ShockWave;

new g_iWeapon_InfectionBomb;

new g_iClass_Zombie;
new g_iClass_Human;

public plugin_precache()
{
	register_plugin("[ReZP] Grenade: Infection", REZP_VERSION_STR, "fl0wer");

	precache_sound(INFECTION_EXPLODE_SOUND);

	g_iModelIndex_LaserBeam = precache_model("sprites/laserbeam.spr");
	g_iModelIndex_ShockWave = precache_model("sprites/shockwave.spr");

	g_iWeapon_InfectionBomb = rz_weapon_create("weapon_hegrenade", "weapon_infectionbomb", "Infection Bomb", INFECTION_VIEW_MODEL);
}

public plugin_init()
{
	g_iClass_Zombie = rz_class_find("zombie");
	g_iClass_Human = rz_class_find("human");
}

public rz_weapon_grenade_throw_post(id, entity, weapon)
{
	if (weapon != g_iWeapon_InfectionBomb)
		return;

	UTIL_SetRendering(entity, kRenderNormal, 16.0, Float:{ 0.0, 200.0, 0.0 }, kRenderFxGlowShell);

	message_begin_f(MSG_ALL, SVC_TEMPENTITY);
	TE_BeamFollow(entity, g_iModelIndex_LaserBeam, 10, 10, { 0, 200, 0 }, 200);
}

public rz_weapon_grenade_explode_pre(id, weapon)
{
	if (weapon != g_iWeapon_InfectionBomb)
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

	if (!is_user_connected(owner) && rz_class_player_get(owner) != g_iClass_Zombie)
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

		if (rz_class_player_get(i) != g_iClass_Human)
			continue;

		rz_class_player_change(i, owner, g_iClass_Zombie);
	}

	return RZ_BREAK;
}
