#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <reapi>
#include <rezp>
#include <rezp_util>
#include <util_tempentities>

new const FROST_VIEW_MODEL[] = "models/zombie_plague/v_grenade_frost.mdl";
new const FROST_EXPLODE_SOUND[]= "warcraft3/frostnova.wav";
new const FROST_FREEZE_SOUND[] = "warcraft3/impalehit.wav";
new const FROST_BREAK_SOUND[] = "warcraft3/impalelaunch1.wav";

new const ICECUBE_MODEL[] = "models/w_hegrenade.mdl";
new const ICECUBE_CLASSNAME[] = "ent_icecube";

new g_iIceCubeEntity[MAX_PLAYERS + 1];

new g_iModelIndex_GlassGibs;
new g_iModelIndex_LaserBeam;
new g_iModelIndex_ShockWave;

new g_iWeapon_FrostGrenade;

enum _:Forwards
{
	Fw_Return,
	Fw_Frost_Grenade_Freeze_Pre,
	Fw_Frost_Grenade_Freeze_Post,

}; new gForwards[Forwards];

public plugin_precache()
{
	register_plugin("[ReZP] Grenade: Frost", REZP_VERSION_STR, "fl0wer");

	precache_sound(FROST_EXPLODE_SOUND);
	precache_sound(FROST_FREEZE_SOUND);
	precache_sound(FROST_BREAK_SOUND);

	precache_model(ICECUBE_MODEL);

	g_iModelIndex_GlassGibs = precache_model("models/glassgibs.mdl");
	g_iModelIndex_LaserBeam = precache_model("sprites/laserbeam.spr");
	g_iModelIndex_ShockWave = precache_model("sprites/shockwave.spr");

	g_iWeapon_FrostGrenade = rz_weapon_create("weapon_flashbang", "weapon_frostgrenade", "Frost Grenade", FROST_VIEW_MODEL);
}

public plugin_init()
{
	RegisterHookChain(RG_CSGameRules_RestartRound, "@CSGameRules_RestartRound_Post", true);
	RegisterHookChain(RG_CSGameRules_FPlayerCanTakeDamage, "@CSGameRules_FPlayerCanTakeDamage_Pre", false);

	RegisterHookChain(RG_CBasePlayer_Killed, "@CBasePlayer_Killed_Pre", false);
	RegisterHookChain(RG_CBasePlayer_ResetMaxSpeed, "@CBasePlayer_ResetMaxSpeed_Post", true);

	gForwards[Fw_Frost_Grenade_Freeze_Pre] = CreateMultiForward("rz_frost_grenade_freeze_pre", ET_CONTINUE, FP_CELL);
	gForwards[Fw_Frost_Grenade_Freeze_Post] = CreateMultiForward("rz_frost_grenade_freeze_post", ET_IGNORE, FP_CELL);
}

public rz_weapon_grenade_throw_post(id, entity, weapon)
{
	if (weapon != g_iWeapon_FrostGrenade)
		return;

	message_begin_f(MSG_ALL, SVC_TEMPENTITY);
	TE_BeamFollow(entity, g_iModelIndex_LaserBeam, 10, 10, { 0, 100, 200 }, 200);
}

public rz_weapon_grenade_explode_pre(id, weapon)
{
	if (weapon != g_iWeapon_FrostGrenade)
		return RZ_CONTINUE;

	new Float:vecOrigin[3];
	new Float:vecOrigin2[3];
	new Float:vecAxis[3];

	get_entvar(id, var_origin, vecOrigin);

	vecAxis = vecOrigin;
	vecAxis[2] += 555.0;

	message_begin_f(MSG_PVS, SVC_TEMPENTITY, vecOrigin);
	TE_BeamCylinder(vecOrigin, vecAxis, g_iModelIndex_ShockWave, 0, 0, 4, 60, 0, { 0, 100, 200 }, 200, 0);

	rh_emit_sound2(id, 0, CHAN_WEAPON, FROST_EXPLODE_SOUND, VOL_NORM, ATTN_NORM);

	for (new i = 1; i <= MaxClients; i++)
	{
		if (!is_user_alive(i))
			continue;

		get_entvar(i, var_origin, vecOrigin2);

		if (vector_distance(vecOrigin, vecOrigin2) > 350.0)
			continue;

		if (!ExecuteHamB(Ham_FVisible, i, id))
			continue;

		if (get_member(i, m_iTeam) != TEAM_TERRORIST)
			continue;

		FreezePlayer(i);
	}

	return RZ_BREAK;
}

@CSGameRules_RestartRound_Post()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		IceCube_Destroy(i);
	}
}

@CSGameRules_FPlayerCanTakeDamage_Pre(id, attacker)
{
	if (is_nullent(g_iIceCubeEntity[id]))
		return HC_CONTINUE;

	SetHookChainReturn(ATYPE_INTEGER, false);
	return HC_SUPERCEDE;
}

@CBasePlayer_Killed_Pre(id, attacker, gib)
{
	IceCube_Destroy(id);
}

@CBasePlayer_ResetMaxSpeed_Post(id)
{
	if (is_nullent(g_iIceCubeEntity[id]))
		return;

	set_entvar(id, var_maxspeed, 1.0);
}

FreezePlayer(id)
{
	ExecuteForward(gForwards[Fw_Frost_Grenade_Freeze_Pre], gForwards[Fw_Return], id);

	if (gForwards[Fw_Return] >= RZ_SUPERCEDE)
		return;
	
	new iceCube = g_iIceCubeEntity[id];

	if (is_nullent(iceCube))
	{
		iceCube = IceCube_Create(id);
	}
	else
	{
		// refreeze
		IceCube_Destroy(id);

		iceCube = IceCube_Create(id);
	}

	g_iIceCubeEntity[id] = iceCube;

	set_member(id, m_bCanShoot, false);

	rg_reset_maxspeed(id);

	rh_emit_sound2(id, 0, CHAN_BODY, FROST_FREEZE_SOUND, VOL_NORM, ATTN_NORM);

	ExecuteForward(gForwards[Fw_Frost_Grenade_Freeze_Post], gForwards[Fw_Return], id);
}

IceCube_Create(owner)
{
	new id = rg_create_entity("info_target");

	if (is_nullent(id))
		return 0;

	set_entvar(id, var_classname, ICECUBE_CLASSNAME);
	set_entvar(id, var_owner, owner);
	//set_entvar(id, var_aiment, owner);
	//set_entvar(id, var_movetype, MOVETYPE_FOLLOW);
	set_entvar(id, var_nextthink, get_gametime() + 5.0);
	set_entvar(id, var_effects, EF_NODRAW);

	engfunc(EngFunc_SetModel, id, ICECUBE_MODEL);

	SetThink(id, "@IceCube_Think");

	UTIL_SetRendering(owner, kRenderNormal, 25.0, Float:{ 0.0, 100.0, 200.0 }, kRenderFxGlowShell);

	return id;
}

IceCube_Destroy(owner)
{
	new id = g_iIceCubeEntity[owner];

	g_iIceCubeEntity[owner] = 0;

	if (is_nullent(id))
		return;

	new Float:vecOrigin[3];
	new Float:vecVelocity[3];

	get_entvar(owner, var_origin, vecOrigin);

	vecOrigin[2] += 24.0;

	vecVelocity[0] = random_float(-50.0, 50.0);
	vecVelocity[1] = random_float(-50.0, 50.0);
	vecVelocity[2] = 25.0;

	message_begin_f(MSG_PVS, SVC_TEMPENTITY, vecOrigin);
	TE_BreakModel(vecOrigin, Float:{ 16.0, 16.0, 16.0 }, vecVelocity, 10, g_iModelIndex_GlassGibs, 10, 25, BREAK_GLASS);

	rh_emit_sound2(id, 0, CHAN_BODY, FROST_BREAK_SOUND, VOL_NORM, ATTN_NORM);

	set_entvar(id, var_flags, FL_KILLME);
}

@IceCube_Think(id)
{
	new owner = get_entvar(id, var_owner);

	IceCube_Destroy(owner);

	if (is_user_alive(owner))
	{
		set_member(owner, m_bCanShoot, true);
		rg_reset_maxspeed(owner);
		UTIL_SetRendering(owner);
	}
}
