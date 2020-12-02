#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <reapi>
#include <rezp>

const TASK_WARMUP = 1337;

new const IMMUTABLE_CVARS[][][] =
{
	{ "mp_limitteams", "0" },
	{ "mp_autoteambalance", "0" },
	{ "mp_round_infinite", "b" },
	{ "mp_roundover", "1" },

}; new g_pImmutableCVars[sizeof(IMMUTABLE_CVARS)];

new HookChain:g_iHookChain_Player_Radio_Pre;

new Array:g_aSpawnPoints;

new g_iLastSpawnId;

new g_pCVar_FreezeTime;
new g_pCVar_RoundTime;

new bool:g_bIsWarmup;
new g_iHudSync_Warmup;

new Float:mp_round_restart_delay;
new Float:rz_game_warmup_hud_pos[2];

public plugin_precache()
{
	register_plugin("[ReZP] Game Rules", REZP_VERSION_STR, "fl0wer");

	for (new i = 0; i < sizeof(IMMUTABLE_CVARS); i++)
	{
		g_pImmutableCVars[i] = get_cvar_pointer(IMMUTABLE_CVARS[i][0]);

		set_pcvar_string(g_pImmutableCVars[i], IMMUTABLE_CVARS[i][1]);
		hook_cvar_change(g_pImmutableCVars[i], "@HandleForcingCvarChange");
	}

	g_pCVar_FreezeTime = get_cvar_pointer("mp_freezetime");
	g_pCVar_RoundTime = get_cvar_pointer("mp_roundtime");

	set_pcvar_flags(g_pCVar_FreezeTime, get_pcvar_flags(g_pCVar_FreezeTime) | FCVAR_UNLOGGED);
	set_pcvar_flags(g_pCVar_RoundTime, get_pcvar_flags(g_pCVar_RoundTime) | FCVAR_UNLOGGED);

	bind_pcvar_float(get_cvar_pointer("mp_round_restart_delay"), mp_round_restart_delay);

	bind_pcvar_float(create_cvar("rz_game_warmup_hud_x", "-1.0", _, "", true, -1.0, true, 1.0), rz_game_warmup_hud_pos[0]);
	bind_pcvar_float(create_cvar("rz_game_warmup_hud_y", "0.25", _, "", true, -1.0, true, 1.0), rz_game_warmup_hud_pos[1]);

	g_aSpawnPoints = ArrayCreate(1, 0);

	if (rz_main_warmup_enabled())
	{
		g_bIsWarmup = true;
		g_iHudSync_Warmup = CreateHudSyncObj();

		set_pcvar_num(g_pCVar_FreezeTime, 0);
		set_pcvar_float(g_pCVar_RoundTime, float(rz_main_warmup_time()) / 60.0);
		
		set_task(1.0, "@Task_WarmupNotice", TASK_WARMUP, .flags = "b");
	}
	else
	{
		set_pcvar_num(g_pCVar_FreezeTime, rz_main_prepare_time());
		set_pcvar_float(g_pCVar_RoundTime, float(rz_main_round_time()) / 60.0);
	}
}

public plugin_init()
{
	register_message(get_user_msgid("RoundTime"), "@MSG_RoundTime");

	RegisterHookChain(RG_RoundEnd, "@RoundEnd_Pre", false);
	RegisterHookChain(RG_RoundEnd, "@RoundEnd_Post", true);

	RegisterHookChain(RG_CSGameRules_RestartRound, "@CSGameRules_RestartRound_Pre", false);
	RegisterHookChain(RG_CSGameRules_RestartRound, "@CSGameRules_RestartRound_Post", true);
	RegisterHookChain(RG_CSGameRules_OnRoundFreezeEnd, "@CSGameRules_OnRoundFreezeEnd_Pre", false);
	RegisterHookChain(RG_CSGameRules_OnRoundFreezeEnd, "@CSGameRules_OnRoundFreezeEnd_Post", true);
	RegisterHookChain(RG_CSGameRules_CheckWinConditions, "@CSGameRules_CheckWinConditions_Pre", false);
	RegisterHookChain(RG_CSGameRules_CheckWinConditions, "@CSGameRules_CheckWinConditions_Post", true);
	RegisterHookChain(RG_CSGameRules_FPlayerCanTakeDamage, "@CSGameRules_FPlayerCanTakeDamage_Pre", false);
	RegisterHookChain(RG_CSGameRules_FPlayerCanRespawn, "@CSGameRules_FPlayerCanRespawn_Pre", false);
	RegisterHookChain(RG_CSGameRules_GetPlayerSpawnSpot, "@CSGameRules_GetPlayerSpawnSpot_Pre", false);

	DisableHookChain((g_iHookChain_Player_Radio_Pre = RegisterHookChain(RG_CBasePlayer_Radio, "@CBasePlayer_Radio_Pre", false)));

	ForceLevelInitialize();
}

@MSG_RoundTime(id, dest, player)
{
	if (!g_bIsWarmup && !(get_member_game(m_bGameStarted) && get_member_game(m_bFreezePeriod)))
		return PLUGIN_CONTINUE;

	if (!is_entity(player))
		return PLUGIN_CONTINUE;

	set_member(player, m_iHideHUD, get_member(player, m_iHideHUD) | HIDEHUD_TIMER);
	return PLUGIN_HANDLED;
}

@RoundEnd_Pre(WinStatus:status, ScenarioEventEndRound:event, Float:delay)
{
	if (g_bIsWarmup)
	{
		SetHookChainArg(2, ATYPE_INTEGER, ROUND_GAME_COMMENCE);
		SetHookChainArg(3, ATYPE_FLOAT, mp_round_restart_delay);
		return;
	}

	if (!get_member_game(m_bGameStarted))
		return;

	if (status == WINSTATUS_NONE)
		status = WINSTATUS_DRAW;

	if (status == WINSTATUS_DRAW)
	{
		if (rz_main_roundover_ct_win())
			status = WINSTATUS_CTS;
	}

	SetHookChainArg(1, ATYPE_INTEGER, status);
}

@RoundEnd_Post(WinStatus:status, ScenarioEventEndRound:event, Float:delay)
{
	if (event == ROUND_GAME_COMMENCE)
	{
		set_member_game(m_bFreezePeriod, false);
		set_member_game(m_bCompleteReset, true);

		if (get_member_game(m_iNumSpawnableTerrorist) != 0 || get_member_game(m_iNumSpawnableCT) != 0)
			set_member_game(m_bGameStarted, true);
	}
}

@CSGameRules_RestartRound_Pre()
{
	if (g_bIsWarmup)
	{
		g_bIsWarmup = false;
		remove_task(TASK_WARMUP);
	}

	set_pcvar_num(g_pCVar_FreezeTime, rz_main_prepare_time());
	set_pcvar_float(g_pCVar_RoundTime, float(rz_main_round_time()) / 60.0);
}

@CSGameRules_RestartRound_Post()
{
	ForceLevelInitialize();
}

@CSGameRules_OnRoundFreezeEnd_Pre()
{
	EnableHookChain(g_iHookChain_Player_Radio_Pre);
}

@CSGameRules_OnRoundFreezeEnd_Post()
{
	DisableHookChain(g_iHookChain_Player_Radio_Pre);

	for (new i = 1; i <= MaxClients; i++)
	{
		if (is_nullent(i))
			continue;

		set_member(i, m_bCanShootOverride, false);
	}
}

@CSGameRules_CheckWinConditions_Pre()
{
	if (g_bIsWarmup)
		return HC_SUPERCEDE;

	return HC_CONTINUE;
}

@CSGameRules_CheckWinConditions_Post()
{
	if (g_bIsWarmup)
		return;

	if (get_member_game(m_bRoundTerminating))
		return;

	new numSpawnableTerrorist = get_member_game(m_iNumSpawnableTerrorist);
	new numSpawnableCT = get_member_game(m_iNumSpawnableCT);

	if (!numSpawnableTerrorist || !numSpawnableCT)
	{
		set_member_game(m_bNeededPlayers, true);
		set_member_game(m_bGameStarted, false);
	}

	if (!get_member_game(m_bGameStarted) && (numSpawnableTerrorist != 0 || numSpawnableCT != 0))
		rg_round_end(mp_round_restart_delay, WINSTATUS_DRAW, ROUND_GAME_COMMENCE, .trigger = true);
}

@CSGameRules_FPlayerCanTakeDamage_Pre(id, attacker)
{
	if (get_member_game(m_bRoundTerminating))
	{
		SetHookChainReturn(ATYPE_INTEGER, false);
		return HC_SUPERCEDE;
	}

	if (g_bIsWarmup)
	{
		SetHookChainReturn(ATYPE_INTEGER, false);
		return HC_SUPERCEDE;
	}
	
	return HC_CONTINUE;
}

@CSGameRules_FPlayerCanRespawn_Pre(id)
{
	if (get_member_game(m_bRoundTerminating))
	{
		SetHookChainReturn(ATYPE_INTEGER, false);
		return HC_SUPERCEDE;
	}

	if (g_bIsWarmup)
	{
		if (get_member(id, m_iJoiningState) != JOINED)
		{
			SetHookChainReturn(ATYPE_INTEGER, false);
			return HC_SUPERCEDE;
		}

		SetHookChainReturn(ATYPE_INTEGER, true);
		return HC_SUPERCEDE;
	}
	
	return HC_CONTINUE;
}

@CSGameRules_GetPlayerSpawnSpot_Pre(id)
{
	//if (!get_member_game(m_bFreezePeriod))
	//	return HC_CONTINUE;

	if (TEAM_TERRORIST > get_member(id, m_iTeam) > TEAM_CT)
		return HC_CONTINUE;

	new spot = EntSelectSpawnPoint(id);

	if (is_nullent(spot))
		return HC_CONTINUE;

	new Float:vecOrigin[3];
	new Float:vecAngles[3];

	get_entvar(spot, var_origin, vecOrigin);
	get_entvar(spot, var_angles, vecAngles);

	vecOrigin[2] += 1.0;

	set_entvar(id, var_origin, vecOrigin);
	set_entvar(id, var_v_angle, NULL_VECTOR);
	set_entvar(id, var_velocity, NULL_VECTOR);
	set_entvar(id, var_angles, vecAngles);
	set_entvar(id, var_punchangle, NULL_VECTOR);
	set_entvar(id, var_fixangle, 1);

	SetHookChainReturn(ATYPE_INTEGER, spot);
	return HC_SUPERCEDE;
}

@CBasePlayer_Radio_Pre(id, msgId[], msgVerbose[], pitch, bool:showIcon)
{
	return HC_SUPERCEDE;
}

@Task_WarmupNotice(id)
{
	if (!get_member_game(m_bRoundTerminating))
	{
		new timeleft = floatround((float(get_member_game(m_iRoundTimeSecs)) - get_gametime() + Float:get_member_game(m_fRoundStartTimeReal)));

		set_hudmessage(255, 255, 255, rz_game_warmup_hud_pos[0], rz_game_warmup_hud_pos[1], 0, 0.0, 5.0, 2.0, 0.0);

		if (timeleft > 5)
			ShowSyncHudMsg(0, g_iHudSync_Warmup, "%L", LANG_PLAYER, "RZ_WARMUP", timeleft / 60, timeleft % 60);
		else
			ShowSyncHudMsg(0, g_iHudSync_Warmup, "%L", LANG_PLAYER, "RZ_WARMUP_END", timeleft / 60, timeleft % 60);
	}
	else
	{
		set_dhudmessage(255, 0, 0, rz_game_warmup_hud_pos[0], rz_game_warmup_hud_pos[1], 0, 0.0, 5.0, 2.0, 0.0);
		ShowSyncHudMsg(0, g_iHudSync_Warmup, "%L", LANG_PLAYER, "RZ_WARMUP_START", floatround(Float:get_member_game(m_flRestartRoundTime) - get_gametime()));
	}
}

@HandleForcingCvarChange(pCvar, oldValue[], newValue[])
{
	for (new i = 0; i < sizeof(IMMUTABLE_CVARS); i++)
	{
		if (g_pImmutableCVars[i] != pCvar)
			continue;

		if (equal(newValue, IMMUTABLE_CVARS[i][1]))
			continue;

		set_pcvar_string(pCvar, IMMUTABLE_CVARS[i][1]);
		break;
	}
}

ForceLevelInitialize()
{
	if (!ArraySize(g_aSpawnPoints))
	{
		new entity = NULLENT;

		while ((entity = rg_find_ent_by_class(entity, "info_player_start", true)))
			ArrayPushCell(g_aSpawnPoints, entity);

		while ((entity = rg_find_ent_by_class(entity, "info_player_deathmatch", true)))
			ArrayPushCell(g_aSpawnPoints, entity);
	}

	new spawnPontsNum = ArraySize(g_aSpawnPoints);

	set_member_game(m_iSpawnPointCount_Terrorist, spawnPontsNum);
	set_member_game(m_iSpawnPointCount_CT, spawnPontsNum);

	set_member_game(m_bLevelInitialized, true);
}

EntSelectSpawnPoint(id)
{
	new spotId = g_iLastSpawnId;
	new spawnPontsNum = ArraySize(g_aSpawnPoints);
	new spot;
	new Float:vecOrigin[3];

	do
	{
		if (++spotId >= spawnPontsNum)
			spotId = 0;

		spot = ArrayGetCell(g_aSpawnPoints, spotId);

		if (is_nullent(spot))
			continue;

		get_entvar(spot, var_origin, vecOrigin);

		if (!IsHullVacant(id, vecOrigin, HULL_HUMAN))
			continue;

		break;
	}
	while (spotId != g_iLastSpawnId);

	if (is_nullent(spot))
		return 0;

	g_iLastSpawnId = spotId;

	return spot;
}

bool:IsHullVacant(id, Float:vecOrigin[3], hull)
{
	engfunc(EngFunc_TraceHull, vecOrigin, vecOrigin, 0, hull, id, 0);

	if (get_tr2(0, TR_StartSolid) || get_tr2(0, TR_AllSolid) || !get_tr2(0, TR_InOpen))
		return false;

	return true;
}

public plugin_natives()
{
	register_native("rz_game_is_warmup", "@native_game_is_warmup");
	register_native("rz_game_get_playersnum", "@native_game_get_playersnum");
	register_native("rz_game_get_alivesnum", "@native_game_get_alivesnum");
}

@native_game_is_warmup(plugin, argc)
{
	return g_bIsWarmup;
}

@native_game_get_playersnum(plugin, argc)
{
	enum { arg_team = 1 };

	new TeamName:team = any:get_param(arg_team);
	new playersNum;

	for (new i = 1; i <= MaxClients; i++)
	{
		if (!is_user_connected(i))
			continue;

		if (get_member(i, m_iTeam) != team)
			continue;

		playersNum++;
	}

	return playersNum;
}

@native_game_get_alivesnum(plugin, argc)
{
	static cachedAlivesNum;
	static Float:lastAlivesCalcTime;

	new Float:time = get_gametime();

	if (lastAlivesCalcTime != time)
	{
		lastAlivesCalcTime = time;
		cachedAlivesNum = 0;

		for (new i = 1; i <= MaxClients; i++)
		{
			if (!is_user_alive(i))
				continue;

			cachedAlivesNum++;
		}
	}
	
	return cachedAlivesNum;
}
