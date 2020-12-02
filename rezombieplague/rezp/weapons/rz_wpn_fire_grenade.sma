#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <reapi>
#include <rezp>
#include <rezp_util>
#include <util_tempentities>

new const FIRE_VIEW_MODEL[] = "models/zombie_plague/v_grenade_fire.mdl";
new const FIRE_EXPLODE_SOUND[] = "zombie_plague/grenade_explode.wav";
new const FIRE_BURN_SOUND[][] = { "zombie_plague/zombie_burn3.wav" , "zombie_plague/zombie_burn4.wav" , "zombie_plague/zombie_burn5.wav" , "zombie_plague/zombie_burn6.wav" , "zombie_plague/zombie_burn7.wav" };

new const FLAME_SPRITE[] = "sprites/flame.spr";
new const FLAME_CLASSNAME[] = "ent_flame";

new g_iFlameEntity[MAX_PLAYERS + 1];

new g_iModelIndex_Flame;
new g_iModelIndex_LaserBeam;
new g_iModelIndex_ShockWave;
new g_iModelIndex_BlackSmoke3;

new g_iWeapon_FireGrenade;

enum _:Forwards
{
	Fw_Return,
	Fw_Fire_Grenade_Burn_Pre,
	Fw_Fire_Grenade_Burn_Post,

}; new gForwards[Forwards];

public plugin_precache()
{
	register_plugin("[ReZP] Grenade: Fire", REZP_VERSION_STR, "fl0wer");

	precache_sound(FIRE_EXPLODE_SOUND);

	for (new i = 0; i < sizeof(FIRE_BURN_SOUND); i++)
		precache_sound(FIRE_BURN_SOUND[i]);

	g_iModelIndex_Flame = precache_model(FLAME_SPRITE);
	g_iModelIndex_LaserBeam = precache_model("sprites/laserbeam.spr");
	g_iModelIndex_ShockWave = precache_model("sprites/shockwave.spr");
	g_iModelIndex_BlackSmoke3 = precache_model("sprites/black_smoke3.spr");

	g_iWeapon_FireGrenade = rz_weapon_create("weapon_hegrenade", "weapon_firegrenade", "Fire Grenade", FIRE_VIEW_MODEL);
}

public plugin_init()
{
	RegisterHookChain(RG_CSGameRules_RestartRound, "@CSGameRules_RestartRound_Post", true);

	RegisterHookChain(RG_CBasePlayer_Killed, "@CBasePlayer_Killed_Pre", false);
	RegisterHookChain(RG_CBasePlayer_ResetMaxSpeed, "@CBasePlayer_ResetMaxSpeed_Post", true);

	gForwards[Fw_Fire_Grenade_Burn_Pre] = CreateMultiForward("rz_fire_grenade_burn_pre", ET_CONTINUE, FP_CELL);
	gForwards[Fw_Fire_Grenade_Burn_Post] = CreateMultiForward("rz_fire_grenade_burn_post", ET_IGNORE, FP_CELL);
}

public rz_weapon_grenade_throw_post(id, entity, weapon)
{
	if (weapon != g_iWeapon_FireGrenade)
		return;

	UTIL_SetRendering(entity, kRenderNormal, 16.0, Float:{ 200.0, 0.0, 0.0 }, kRenderFxGlowShell);

	message_begin_f(MSG_ALL, SVC_TEMPENTITY);
	TE_BeamFollow(entity, g_iModelIndex_LaserBeam, 10, 10, { 200, 0, 0 }, 200);
}

public rz_weapon_grenade_explode_pre(id, weapon)
{
	if (weapon != g_iWeapon_FireGrenade)
		return RZ_CONTINUE;

	new owner = get_entvar(id, var_owner);
	new Float:vecOrigin[3];
	new Float:vecOrigin2[3];
	new Float:vecAxis[3];

	get_entvar(id, var_origin, vecOrigin);

	vecAxis = vecOrigin;
	vecAxis[2] += 555.0;

	message_begin_f(MSG_PVS, SVC_TEMPENTITY, vecOrigin);
	TE_BeamCylinder(vecOrigin, vecAxis, g_iModelIndex_ShockWave, 0, 0, 4, 60, 0, { 200, 0, 0 }, 200, 0);

	rh_emit_sound2(id, 0, CHAN_WEAPON, FIRE_EXPLODE_SOUND, VOL_NORM, ATTN_NORM);

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

		IgnitePlayer(i, owner);
	}

	return RZ_BREAK;
}

@CSGameRules_RestartRound_Post()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		Flame_Destroy(i);
	}
}

@CBasePlayer_Killed_Pre(id, attacker, gib)
{
	// maybe spawn?
	Flame_Destroy(id);
}

@CBasePlayer_ResetMaxSpeed_Post(id)
{
	if (is_nullent(g_iFlameEntity[id]))
		return;

	set_entvar(id, var_maxspeed, Float:get_entvar(id, var_maxspeed) * 0.5);
}

IgnitePlayer(id, attacker)
{
	ExecuteForward(gForwards[Fw_Fire_Grenade_Burn_Pre], gForwards[Fw_Return], id);

	if (gForwards[Fw_Return] >= RZ_SUPERCEDE)
		return;
	
	new flame = g_iFlameEntity[id];

	if (is_nullent(flame))
	{
		flame = Flame_Create(id, attacker);
	}
	else
	{
		// refreeze
		Flame_Destroy(id);

		flame = Flame_Create(id, attacker);
	}

	g_iFlameEntity[id] = flame;

	rg_reset_maxspeed(id);

	ExecuteForward(gForwards[Fw_Fire_Grenade_Burn_Post], gForwards[Fw_Return], id);
}

Flame_Create(owner, attacker)
{
	new id = rg_create_entity("env_sprite");

	if (is_nullent(id))
		return 0;

	new Float:time = get_gametime();

	set_entvar(id, var_classname, FLAME_CLASSNAME);
	set_entvar(id, var_owner, owner);
	set_entvar(id, var_aiment, owner);
	set_entvar(id, var_enemy, attacker);
	set_entvar(id, var_movetype, MOVETYPE_FOLLOW);
	set_entvar(id, var_nextthink, time + 0.1);
	set_entvar(id, var_dmgtime, time + 5.0);

	set_entvar(id, var_framerate, 1.0);
	set_entvar(id, var_scale, 0.5);
	set_entvar(id, var_rendermode, kRenderTransAdd);
	set_entvar(id, var_renderamt, 255.0);

	engfunc(EngFunc_SetModel, id, FLAME_SPRITE);

	set_ent_data_float(id, "CSprite", "m_lastTime", time);
	set_ent_data_float(id, "CSprite", "m_maxFrame", float(engfunc(EngFunc_ModelFrames, g_iModelIndex_Flame) - 1));

	SetThink(id, "@Flame_Think");

	return id;
}

Flame_Destroy(owner)
{
	new id = g_iFlameEntity[owner];

	g_iFlameEntity[owner] = 0;

	if (is_nullent(id))
		return;

	new Float:vecOrigin[3];
	new Float:vecOffset[3];

	get_entvar(owner, var_origin, vecOrigin);

	vecOffset = vecOrigin;
	vecOffset[2] -= 50.0;

	message_begin_f(MSG_PVS, SVC_TEMPENTITY, vecOrigin);
	TE_Smoke(vecOffset, g_iModelIndex_BlackSmoke3, random_num(15, 20), random_num(10, 20));

	set_entvar(id, var_flags, FL_KILLME);
}

@Flame_Think(id)
{
	new owner = get_entvar(id, var_owner);
	new Float:time = get_gametime();

	if ((!is_nullent(owner) && get_entvar(owner, var_flags) & FL_INWATER) || Float:get_entvar(id, var_dmgtime) <= time)
	{
		Flame_Destroy(owner);

		if (is_user_alive(owner))
		{
			rg_reset_maxspeed(owner);
		}

		return;
	}

	if (Float:get_entvar(id, var_pain_finished) <= time)
	{
		set_entvar(id, var_pain_finished, time + 0.2);

		if (random_num(1, 20) == 1)
		{
			rh_emit_sound2(owner, 0, CHAN_VOICE, FIRE_BURN_SOUND[random_num(0, sizeof(FIRE_BURN_SOUND) - 1)], VOL_NORM, ATTN_NORM);
		}

		new attacker = get_entvar(id, var_enemy);

		if (is_nullent(attacker))
			attacker = 0;

		//ExecuteHamB(Ham_TakeDamage, owner, id, attacker, 5.0, DMG_BURN | DMG_NEVERGIB);

		new Float:health = get_entvar(owner, var_health);
		new Float:damage = 5.0;

		set_entvar(id, var_health, floatmax(health - damage, 1.0));
	}

	new Float:frame = Float:get_entvar(id, var_frame);

	frame++;
	//frame += Float:get_entvar(id, var_framerate) * (time - get_ent_data_float(id, "CSprite", "m_lastTime"));

	if (frame > get_ent_data_float(id, "CSprite", "m_maxFrame"))
		frame = 0.0;

	set_entvar(id, var_frame, frame);
	set_entvar(id, var_nextthink, time + 0.1);

	set_ent_data_float(id, "CSprite", "m_lastTime", time);
}
