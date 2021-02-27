#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <reapi>
#include <rezp>
#include <util_messages>
#include <util_tempentities>

new const LONGJUMP_ICON_SPRITE[] = "item_longjump";
new const LONGJUMP_ACTIVATE_SOUND[] = "zombie_plague/boss_shokwave.wav";

enum LongJumpData
{
	bool:LongJump_Enabled,
	Float:LongJump_Force,
	Float:LongJump_Height,
	Float:LongJump_Cooldown,
	Float:LongJump_NextTime,
	Float:LongJump_KillBeamTime,

}; new gLongJump[MAX_PLAYERS + 1][LongJumpData];

enum IconState
{
	ICONSTATE_HIDE,
	ICONSTATE_AVAILABLE,
	ICONSTATE_COOLDOWN,
};

new g_iModelIndex_Trail;

public plugin_precache()
{
	register_plugin("[ReZP] Addon: Long Jump", REZP_VERSION_STR, "fl0wer");

	precache_sound(LONGJUMP_ACTIVATE_SOUND);

	g_iModelIndex_Trail = precache_model("sprites/laserbeam.spr");
}

public plugin_init()
{
	RegisterHookChain(RG_CBasePlayer_Killed, "@CBasePlayer_Killed_Post", true);
	RegisterHookChain(RG_CBasePlayer_PreThink, "@CBasePlayer_PreThink_Post", true);
}

public rz_class_change_pre(id, attacker, class)
{
	ChangeLongJump(id, false);
}

@CBasePlayer_Killed_Post(id, attacker, gib)
{
	ChangeLongJump(id, false);
}

ChangeLongJump(id, bool:enabled, Float:force = 0.0, Float:height = 0.0, Float:cooldown = 0.0)
{
	gLongJump[id][LongJump_Force] = force;
	gLongJump[id][LongJump_Height] = height;
	gLongJump[id][LongJump_Cooldown] = cooldown;
	gLongJump[id][LongJump_NextTime] = 0.0;

	if (enabled)
		LongJump_UpdateIcon(id, ICONSTATE_AVAILABLE);
	else
	{
		if (gLongJump[id][LongJump_Enabled])
			LongJump_UpdateIcon(id, ICONSTATE_HIDE);
	}

	gLongJump[id][LongJump_Enabled] = enabled;
	return true;
}

@CBasePlayer_PreThink_Post(id)
{
	if (!gLongJump[id][LongJump_Enabled])
		return;

	if (!is_user_alive(id))
		return;

	static Float:time;
	time = get_gametime();

	if (gLongJump[id][LongJump_NextTime] && gLongJump[id][LongJump_NextTime] <= time)
	{
		gLongJump[id][LongJump_NextTime] = 0.0;

		LongJump_UpdateIcon(id, ICONSTATE_AVAILABLE);
	}

	if (gLongJump[id][LongJump_KillBeamTime] && gLongJump[id][LongJump_KillBeamTime] <= time)
	{
		gLongJump[id][LongJump_KillBeamTime] = 0.0;

		message_begin_f(MSG_ALL, SVC_TEMPENTITY);
		TE_KillBeam(id);
	}

	if (gLongJump[id][LongJump_NextTime])
		return;

	if (get_entvar(id, var_waterlevel) >= 2)
		return;

	new flags = get_entvar(id, var_flags);

	if (flags & FL_WATERJUMP)
		return;

	if (!(flags & FL_ONGROUND))
		return;

	if (!(get_entvar(id, var_button) & (IN_JUMP | IN_DUCK) == (IN_JUMP | IN_DUCK)))
		return;

	new Float:vecVelocity[3];
	get_entvar(id, var_velocity, vecVelocity);

	if (vector_length(vecVelocity) < 50.0)
		return;

	new Float:vecPunchAngle[3];
	new Float:vecViewForward[3];

	get_entvar(id, var_punchangle, vecPunchAngle);
	global_get(glb_v_forward, vecViewForward);

	vecPunchAngle[0] = -5.0;

	for (new i  = 0; i < 2; i++)
		vecVelocity[i] = vecViewForward[i] * gLongJump[id][LongJump_Force];

	vecVelocity[2] = gLongJump[id][LongJump_Height];

	set_entvar(id, var_velocity, vecVelocity);
	set_entvar(id, var_punchangle, vecPunchAngle);

	if (gLongJump[id][LongJump_Cooldown])
	{
		gLongJump[id][LongJump_NextTime] = time + gLongJump[id][LongJump_Cooldown];

		LongJump_UpdateIcon(id, ICONSTATE_COOLDOWN);
	}

	gLongJump[id][LongJump_KillBeamTime] = time + 1.0;

	rh_emit_sound2(id, 0, CHAN_ITEM, LONGJUMP_ACTIVATE_SOUND, VOL_NORM, ATTN_NORM);
	
	message_begin_f(MSG_ALL, SVC_TEMPENTITY);
	TE_BeamFollow(id, g_iModelIndex_Trail, 10, 10, { 255, 255, 0 }, 200);
}

LongJump_UpdateIcon(id, IconState:status)
{
	message_begin(MSG_ONE, gmsgStatusIcon, _, id);
	
	switch (status)
	{
		case ICONSTATE_HIDE: SendStatusIcon(0, LONGJUMP_ICON_SPRITE);
		case ICONSTATE_AVAILABLE: SendStatusIcon(1, LONGJUMP_ICON_SPRITE, { 255, 160, 0 });
		case ICONSTATE_COOLDOWN: SendStatusIcon(1, LONGJUMP_ICON_SPRITE, { 128, 128, 128 });
	}
}

public plugin_natives()
{
	register_native("rz_longjump_player_get", "@native_longjump_player_get");
	register_native("rz_longjump_player_give", "@native_longjump_player_give");
}

@native_longjump_player_get(plugin, argc)
{
	enum { arg_player = 1 };

	new player = get_param(arg_player);
	RZ_CHECK_ALIVE(player, false)

	return gLongJump[player][LongJump_Enabled];
}

@native_longjump_player_give(plugin, argc)
{
	enum { arg_player = 1, arg_enabled, arg_force, arg_height, arg_cooldown };

	new player = get_param(arg_player);
	RZ_CHECK_ALIVE(player, false)

	new bool:enabled = bool:get_param(arg_enabled);

	if (!enabled)
		return ChangeLongJump(player, false);

	new Float:force = get_param_f(arg_force);
	new Float:height = get_param_f(arg_height);
	new Float:cooldown = get_param_f(arg_cooldown);

	return ChangeLongJump(player, enabled, force, height, cooldown);
}
