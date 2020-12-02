#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <reapi>
#include <rezp>

const AWARD_PLAYER_KILLED = 3;
const AWARD_PLAYER_INFECT = 2;
const AWARD_TEAM_WIN = 5;
const AWARD_TEAM_LOSER = 3;
const AWARD_TEAM_DRAW = 0;

public plugin_init()
{
	register_plugin("[ReZP] Addon: Awards", REZP_VERSION_STR, "fl0wer");

	RegisterHookChain(RG_RoundEnd, "@RoundEnd_Post", true);

	RegisterHookChain(RG_CBasePlayer_AddAccount, "@CBasePlayer_AddAccount_Pre", false);
	RegisterHookChain(RG_CBasePlayer_AddAccount, "@CBasePlayer_AddAccount_Post", true);

	rz_load_langs("awards");
}

public rz_class_change_post(id, attacker)
{
	if (id == attacker || !attacker)
		return;

	new bonus = AWARD_PLAYER_INFECT;

	if (!bonus)
		return;

	rz_give_bonus(attacker, bonus, "%L", LANG_PLAYER, "RZ_AWARD_PLAYER_INFECT");
}

@RoundEnd_Post(WinStatus:status, ScenarioEventEndRound:event, Float:delay)
{
	if (status == WINSTATUS_NONE)
		return;

	if (rz_game_is_warmup())
		return;

	new TeamName:winTeam = TEAM_UNASSIGNED;
	new TeamName:team;

	switch (status)
	{
		case WINSTATUS_TERRORISTS: winTeam = TEAM_TERRORIST;
		case WINSTATUS_CTS: winTeam = TEAM_CT;
	}

	for (new i = 1; i <= MaxClients; i++)
	{
		if (!is_user_connected(i))
			continue;

		team = get_member(i, m_iTeam);

		if (team != TEAM_TERRORIST && team != TEAM_CT)
			continue;

		if (winTeam == TEAM_UNASSIGNED)
			rz_give_bonus(i, AWARD_TEAM_DRAW, "%L", LANG_PLAYER, "RZ_AWARD_TEAM_DRAW");
		else if (winTeam == team)
			rz_give_bonus(i, AWARD_TEAM_WIN, "%L", LANG_PLAYER, "RZ_AWARD_TEAM_WIN");
		else
			rz_give_bonus(i, AWARD_TEAM_LOSER, "%L", LANG_PLAYER, "RZ_AWARD_TEAM_LOSER");
	}
}

@CBasePlayer_AddAccount_Pre(id, amount, RewardType:type, bool:trackChange)
{
	if (type != RT_ENEMY_KILLED)
		return;

	SetHookChainArg(2, ATYPE_INTEGER, AWARD_PLAYER_KILLED);
}

@CBasePlayer_AddAccount_Post(id, amount, RewardType:type, bool:trackChange)
{
	if (type != RT_ENEMY_KILLED)
		return;

	if (!amount)
		return;

	rz_give_bonus(id, amount, "%L", LANG_PLAYER, "RZ_AWARD_PLAYER_KILLED");
}
