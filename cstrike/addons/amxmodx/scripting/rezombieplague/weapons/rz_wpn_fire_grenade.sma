#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <reapi>
#include <rezp>
#include <util_tempentities>

new const FIRE_VIEW_MODEL[] = "models/zombie_plague/v_grenade_fire.mdl";
new const FIRE_EXPLODE_SOUND[] = "zombie_plague/grenade_explode.wav";
new const FIRE_BURN_SOUND[][] = { "zombie_plague/zombie_burn3.wav" , "zombie_plague/zombie_burn4.wav" , "zombie_plague/zombie_burn5.wav" , "zombie_plague/zombie_burn6.wav" , "zombie_plague/zombie_burn7.wav" };

new const FLAME_SPRITE[] = "sprites/flame.spr";
new const FLAME_CLASSNAME[] = "ent_flame";

new g_iFlameEntity[MAX_PLAYERS + 1];
new bool:g_bFireDamage;

new g_iModelIndex_Flame;
new g_iModelIndex_LaserBeam;
new g_iModelIndex_ShockWave;
new g_iModelIndex_BlackSmoke3;

new g_iGrenade_Fire;

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

	new grenade = g_iGrenade_Fire = rz_grenade_create("grenade_fire", "weapon_hegrenade");

	rz_grenade_set(grenade, RZ_GRENADE_NAME, "RZ_WPN_FIRE_GRENADE");
	rz_grenade_set(grenade, RZ_GRENADE_SHORT_NAME, "RZ_WPN_FIRE_SHORT");
	rz_grenade_set(grenade, RZ_GRENADE_VIEW_MODEL, FIRE_VIEW_MODEL);
}

public plugin_init()
{
	RegisterHookChain(RH_SV_StartSound, "@SV_StartSound_Pre", false);
	
	RegisterHookChain(RG_CSGameRules_RestartRound, "@CSGameRules_RestartRound_Post", true);

	RegisterHookChain(RG_CBasePlayer_Killed, "@CBasePlayer_Killed_Pre", false);
	RegisterHookChain(RG_CBasePlayer_ResetMaxSpeed, "@CBasePlayer_ResetMaxSpeed_Post", true);
	RegisterHookChain(RG_CBasePlayer_SetAnimation, "@CBasePlayer_SetAnimation_Pre", false);

	gForwards[Fw_Fire_Grenade_Burn_Pre] = CreateMultiForward("rz_fire_grenade_burn_pre", ET_CONTINUE, FP_CELL);
	gForwards[Fw_Fire_Grenade_Burn_Post] = CreateMultiForward("rz_fire_grenade_burn_post", ET_IGNORE, FP_CELL);
}

public rz_grenades_throw_post(id, entity, grenade)
{
	if (grenade != g_iGrenade_Fire)
		return;

	rz_util_set_rendering(entity, kRenderNormal, 16.0, Float:{ 200.0, 0.0, 0.0 }, kRenderFxGlowShell);

	message_begin_f(MSG_ALL, SVC_TEMPENTITY);
	TE_BeamFollow(entity, g_iModelIndex_LaserBeam, 10, 10, { 200, 0, 0 }, 200);
}

public rz_grenades_explode_pre(id, grenade)
{
	if (grenade != g_iGrenade_Fire)
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

public rz_class_change_post(id, attacker, class)
{
	Flame_Destroy(id, true);
}

@SV_StartSound_Pre(recipients, entity, channel, sample[], volume, Float:attenuation, flags, pitch)	
{
	if (!g_bFireDamage)
		return HC_CONTINUE;

	return HC_SUPERCEDE;
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
	Flame_Destroy(id, true);
}

@CBasePlayer_ResetMaxSpeed_Post(id)
{
	if (is_nullent(g_iFlameEntity[id]))
		return;

	new Float:burnSpeed = 200.0;
	new Float:maxSpeed = get_entvar(id, var_maxspeed) * 0.75;

	set_entvar(id, var_maxspeed, floatmax(maxSpeed, burnSpeed));
}

@CBasePlayer_SetAnimation_Pre(id, PLAYER_ANIM:playerAnim)
{
	if (!g_bFireDamage)
		return HC_CONTINUE;

	return HC_SUPERCEDE;
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
		Flame_Destroy(id, true);

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
	set_entvar(id, var_nextthink, time);
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

Flame_Destroy(owner, bool:smoke = false)
{
	new id = g_iFlameEntity[owner];

	g_iFlameEntity[owner] = 0;

	if (is_nullent(id))
		return;

	if (smoke)
	{
		new Float:vecOrigin[3];
		new Float:vecOffset[3];

		get_entvar(owner, var_origin, vecOrigin);

		vecOffset = vecOrigin;
		vecOffset[2] -= 50.0;

		message_begin_f(MSG_PVS, SVC_TEMPENTITY, vecOrigin);
		TE_Smoke(vecOffset, g_iModelIndex_BlackSmoke3, random_num(15, 20), random_num(10, 20));
	}

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
		set_entvar(id, var_pain_finished, time + 1.0);

		if (random_num(0, 1))
			rh_emit_sound2(owner, 0, CHAN_VOICE, FIRE_BURN_SOUND[random_num(0, sizeof(FIRE_BURN_SOUND) - 1)], VOL_NORM, ATTN_NORM);

		new attacker = get_entvar(id, var_enemy);

		if (attacker && !is_user_connected(attacker))
		{
			attacker = 0;
			set_entvar(id, var_enemy, 0);
		}

		if (rg_is_player_can_takedamage(owner, attacker))
		{
			new Float:damage = 100.0;

			new Float:velocityModifier = get_member(owner, m_flVelocityModifier);
			new Float:vecVelocity[3];

			get_entvar(owner, var_velocity, vecVelocity);

			g_bFireDamage = true;
			set_member(owner, m_LastHitGroup, HITGROUP_GENERIC);
			ExecuteHamB(Ham_TakeDamage, owner, id, attacker, damage, DMG_BURN | DMG_NEVERGIB);
			g_bFireDamage = false;

			if (is_user_alive(owner))
			{
				set_entvar(owner, var_velocity, vecVelocity);
				set_member(owner, m_flVelocityModifier, velocityModifier);
			}
		}
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
