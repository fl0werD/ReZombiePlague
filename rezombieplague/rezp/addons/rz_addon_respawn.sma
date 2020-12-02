#pragma semicolon 1

#include <amxmodx>
#include <reapi>
#include <rezp>
#include <util_messages>

new const RESPAWN_TIME = 3;

new cvar_deathmatch = 2;

public plugin_precache()
{
	register_plugin("[ReZP] Addon: Respawn", REZP_VERSION_STR, "fl0wer");
}

public plugin_init()
{
	RegisterHookChain(RG_CBasePlayer_Spawn, "@CBasePlayer_Spawn_Pre", false);
	RegisterHookChain(RG_CBasePlayer_Killed, "@CBasePlayer_Killed_Post", true);
}

@CBasePlayer_Spawn_Pre(id)
{
	if (get_member(id, m_bJustConnected))
		return;

	if (TEAM_TERRORIST > get_member(id, m_iTeam) > TEAM_CT)
		return;

	if (!get_member_game(m_bGameStarted) || get_member_game(m_bFreezePeriod))
		return;

	new newClass = rz_class_get_default(TEAM_CT);

	switch (cvar_deathmatch)
	{
		case 2: newClass = rz_class_get_default(TEAM_TERRORIST);
		case 3:
		{
			if (random_num(0, 1))
				newClass = rz_class_get_default(TEAM_TERRORIST);
		}
		case 4:
		{
			if (rz_game_get_playersnum(TEAM_TERRORIST) < rz_game_get_alivesnum() / 2)
				newClass = rz_class_get_default(TEAM_TERRORIST);
		}
	}
	
	rz_class_player_set(id, newClass);
}

@CBasePlayer_Killed_Post(id, attacker, gib)
{
	if (!rg_is_player_can_respawn(id))
		return;

	set_member(id, m_flRespawnPending, get_gametime() + float(RESPAWN_TIME));

	SendBarTime(id, RESPAWN_TIME);
	client_print(id, print_center, "Time until Respawn: %d sec", RESPAWN_TIME);
}
