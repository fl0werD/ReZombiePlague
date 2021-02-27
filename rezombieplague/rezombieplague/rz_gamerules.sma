#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <reapi>
#include <rezp>
#include <util_messages>

const TASK_COUNTDOWN = 1337;

new const IMMUTABLE_CVARS[][][] =
{
	{ "mp_limitteams", "0" },
	{ "mp_autoteambalance", "0" },
	{ "mp_round_infinite", "b" },
	{ "mp_roundover", "1" },

}; new g_pImmutableCVars[sizeof(IMMUTABLE_CVARS)];

new Array:g_aSpawnPoints;

new g_iLastSpawnId;

new g_pCVar_FreezeTime;
new g_pCVar_RoundTime;

new bool:g_bIsWarmup;
new g_iHudSync_Countdown;

new Float:mp_round_restart_delay;

new Float:rz_game_warmup_hud_pos[2];
new rz_game_warmup_end_timer;

new Float:rz_game_infection_hud_pos[2];
new rz_game_infection_sound_timer;

new Float:rz_game_roundend_hud_pos[2];
new rz_game_roundend_hud_timer;
new rz_game_roundend_sound_timer;

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
	bind_pcvar_num(create_cvar("rz_game_warmup_end_timer", "5", _, "", true, 0.0), rz_game_warmup_end_timer);

	bind_pcvar_float(create_cvar("rz_game_infection_hud_pos_x", "-1.0", _, "", true, -1.0, true, 1.0), rz_game_infection_hud_pos[0]);
	bind_pcvar_float(create_cvar("rz_game_infection_hud_pos_y", "0.25", _, "", true, -1.0, true, 1.0), rz_game_infection_hud_pos[1]);
	bind_pcvar_num(create_cvar("rz_game_infection_sound_timer", "10", _, "", true, 0.0, true, 10.0), rz_game_infection_sound_timer);

	bind_pcvar_float(create_cvar("rz_game_roundend_hud_pos_x", "-1.0", _, "", true, -1.0, true, 1.0), rz_game_roundend_hud_pos[0]);
	bind_pcvar_float(create_cvar("rz_game_roundend_hud_pos_y", "0.25", _, "", true, -1.0, true, 1.0), rz_game_roundend_hud_pos[1]);
	bind_pcvar_num(create_cvar("rz_game_roundend_hud_timer", "30", _, "", true, 0.0, true, 60.0), rz_game_roundend_hud_timer);
	bind_pcvar_num(create_cvar("rz_game_roundend_sound_timer", "10", _, "", true, 0.0, true, 10.0), rz_game_roundend_sound_timer);

	g_aSpawnPoints = ArrayCreate(1, 0);

	new warmupTime = rz_main_get(RZ_MAIN_WARMUP_TIME);

	if (warmupTime)
	{
		g_bIsWarmup = true;
		SetRoundCvars(0, warmupTime);
	}
	else
		SetRoundCvars(rz_main_get(RZ_MAIN_PREPARE_TIME), rz_main_get(RZ_MAIN_ROUND_TIME));
}

public plugin_init()
{
	register_message(get_user_msgid("RoundTime"), "@MSG_RoundTime");

	RegisterHookChain(RG_RoundEnd, "@RoundEnd_Pre", false);
	RegisterHookChain(RG_RoundEnd, "@RoundEnd_Post", true);

	RegisterHookChain(RG_CSGameRules_RestartRound, "@CSGameRules_RestartRound_Pre", false);
	RegisterHookChain(RG_CSGameRules_RestartRound, "@CSGameRules_RestartRound_Post", true);
	RegisterHookChain(RG_CSGameRules_OnRoundFreezeEnd, "@CSGameRules_OnRoundFreezeEnd_Post", true);
	RegisterHookChain(RG_CSGameRules_CheckWinConditions, "@CSGameRules_CheckWinConditions_Pre", false);
	RegisterHookChain(RG_CSGameRules_CheckWinConditions, "@CSGameRules_CheckWinConditions_Post", true);
	RegisterHookChain(RG_CSGameRules_FPlayerCanTakeDamage, "@CSGameRules_FPlayerCanTakeDamage_Pre", false);
	RegisterHookChain(RG_CSGameRules_FPlayerCanRespawn, "@CSGameRules_FPlayerCanRespawn_Pre", false);
	RegisterHookChain(RG_CSGameRules_GetPlayerSpawnSpot, "@CSGameRules_GetPlayerSpawnSpot_Pre", false);

	ForceLevelInitialize();

	set_task(1.0, "@Task_Countdown", TASK_COUNTDOWN, .flags = "b");

	g_iHudSync_Countdown = CreateHudSyncObj();
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
		if (get_member_game(m_iNumSpawnableTerrorist) + get_member_game(m_iNumSpawnableCT) >= 2)
		{
			SetHookChainArg(2, ATYPE_INTEGER, ROUND_GAME_COMMENCE);
			SetHookChainArg(3, ATYPE_FLOAT, 5.0);
		}

		return;
	}

	if (!get_member_game(m_bGameStarted))
		return;

	if (status == WINSTATUS_NONE)
		status = WINSTATUS_DRAW;

	if (status == WINSTATUS_DRAW)
	{
		if (rz_main_get(RZ_MAIN_ROUNDOVER_CT_WIN))
			status = WINSTATUS_CTS;
	}

	SetHookChainArg(1, ATYPE_INTEGER, status);
}

@RoundEnd_Post(WinStatus:status, ScenarioEventEndRound:event, Float:delay)
{
	if (event == ROUND_GAME_COMMENCE)
	{
		engfunc(EngFunc_AlertMessage, at_logged, "World triggered ^"Game_Commencing^"^n");

		set_member_game(m_bFreezePeriod, false);
		set_member_game(m_bCompleteReset, true);
		set_member_game(m_bGameStarted, true);
	}
}

@CSGameRules_RestartRound_Pre()
{
	g_bIsWarmup = false;

	SetRoundCvars(rz_main_get(RZ_MAIN_PREPARE_TIME), rz_main_get(RZ_MAIN_ROUND_TIME));
}

@CSGameRules_RestartRound_Post()
{
	ForceLevelInitialize();
}

@CSGameRules_OnRoundFreezeEnd_Post()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!is_user_alive(i))
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
	rg_initialize_player_counts();

	set_member_game(m_bNeededPlayers, false);

	if (get_member_game(m_iNumSpawnableTerrorist) + get_member_game(m_iNumSpawnableCT) < 2)
	{
		message_begin(MSG_ALL, gmsgTextMsg);
		SendTextMsg(print_console, "#Game_scoring");

		set_member_game(m_bNeededPlayers, true);
		set_member_game(m_bGameStarted, false);
		return;
	}
	else
	{
		if (g_bIsWarmup)
		{
			if (get_member_game(m_bRoundTerminating))
				set_member_game(m_bGameStarted, true);
			
			return;
		}
	}

	if (get_member_game(m_bGameStarted))
		return;
	
	rg_round_end(3.0, WINSTATUS_DRAW, ROUND_GAME_COMMENCE, .trigger = true);
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

	if (get_member(id, m_iMenu) == Menu_ChooseAppearance)
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

	SetHookChainReturn(ATYPE_INTEGER, true);
	return HC_SUPERCEDE;
}

@CSGameRules_GetPlayerSpawnSpot_Pre(id)
{
	//if (!get_member_game(m_bFreezePeriod))
	//	return HC_CONTINUE;

	new TeamName:team = get_member(id, m_iTeam);

	if (team != TEAM_TERRORIST && team != TEAM_CT)
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

@Task_Countdown(id)
{
	if (g_bIsWarmup)
	{
		if (!get_member_game(m_bRoundTerminating))
		{
			new timeLeft = floatround(GetRoundRemainingTimeReal());

			set_hudmessage(255, 255, 255, rz_game_warmup_hud_pos[0], rz_game_warmup_hud_pos[1], 0, 0.0, 1.1, 0.0, 0.0);

			if (timeLeft > rz_game_warmup_end_timer)
				ShowSyncHudMsg(0, g_iHudSync_Countdown, "%L", LANG_PLAYER, "RZ_WARMUP", timeLeft / 60, timeLeft % 60);
			else
				ShowSyncHudMsg(0, g_iHudSync_Countdown, "%L", LANG_PLAYER, "RZ_WARMUP_END", timeLeft / 60, timeLeft % 60);
		}
		else
		{
			set_dhudmessage(255, 0, 0, rz_game_warmup_hud_pos[0], rz_game_warmup_hud_pos[1], 0, 0.0, 1.1, 0.0, 0.0);
			ShowSyncHudMsg(0, g_iHudSync_Countdown, "%L", LANG_PLAYER, "RZ_WARMUP_START", floatround(Float:get_member_game(m_flRestartRoundTime) - get_gametime()));
		}
	}
	else
	{
		if (!get_member_game(m_bGameStarted) || get_member_game(m_bRoundTerminating))
			return;

		new timeLeft = floatround(GetRoundRemainingTimeReal());

		if (timeLeft <= 0)
		{
			ClearSyncHud(0, g_iHudSync_Countdown);
			return;
		}

		if (get_member_game(m_bFreezePeriod))
		{
			if (rz_game_infection_sound_timer > 0 && timeLeft <= rz_game_infection_sound_timer)
				PlayTimeLeftSound(timeLeft);

			set_dhudmessage(255, 255, 0, rz_game_infection_hud_pos[0], rz_game_infection_hud_pos[1], 0, 0.0, 1.1, 0.0, 0.0);
			ShowSyncHudMsg(0, g_iHudSync_Countdown, "%L", LANG_PLAYER, "RZ_INFECTION_START", timeLeft);
		}
		else
		{
			if (rz_game_roundend_hud_timer > 0 && timeLeft <= rz_game_roundend_hud_timer)
			{
				if (rz_game_roundend_sound_timer > 0 && timeLeft <= rz_game_roundend_sound_timer)
					PlayTimeLeftSound(timeLeft);

				set_dhudmessage(255, 0, 0, rz_game_roundend_hud_pos[0], rz_game_roundend_hud_pos[1], 0, 0.0, 1.1, 0.0, 0.0);
				ShowSyncHudMsg(0, g_iHudSync_Countdown, "%L", LANG_PLAYER, "RZ_ROUND_END", timeLeft);
			}
		}
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

Float:GetRoundRemainingTimeReal()
{
	return (float(get_member_game(m_iRoundTimeSecs)) - get_gametime() + Float:get_member_game(m_fRoundStartTimeReal));
}

SetRoundCvars(freezeTime, roundTime)
{
	set_pcvar_num(g_pCVar_FreezeTime, freezeTime);
	set_pcvar_float(g_pCVar_RoundTime, float(roundTime) / 60.0);
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

PlayTimeLeftSound(number)
{
	new numWord[64];
	num_to_word(number, numWord, charsmax(numWord));

	client_cmd(0, "spk fvox/%s", numWord);
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
