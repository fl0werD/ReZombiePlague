#pragma semicolon 1

#include <amxmodx>
#include <reapi>
#include <rezp>

new const BLOCKED_TEXTMSG[][] = { "#Cstrike_Tutor_Round_Over", "#Round_Draw", "#Terrorists_Win", "#CTs_Win", "#Game_Commencing" };
new const BLOCKED_SENDAUDIO[][] = { "%!MRAD_rounddraw", "%!MRAD_terwin", "%!MRAD_ctwin" };

/*new const SOUND_WIN_ZOMBIES[][] = { "ambience/the_horror1.wav", "ambience/the_horror3.wav", "ambience/the_horror4.wav" };
new const SOUND_WIN_HUMANS[][] = { "zombie_plague/win_humans1.wav", "zombie_plague/win_humans2.wav" };
new const SOUND_WIN_NO_ONE[][] = { "ambience/3dmstart.wav" };*/

new Trie:g_tBlockedTextMsg;
new Trie:g_tBlockedSendAudio;

new Float:roundstart_notice_pos[2];
new Float:roundend_notice_pos[2];

public plugin_precache()
{
	register_plugin("[ReZP] Addon: Round Notice", REZP_VERSION_STR, "fl0wer");

	/*new i;

	for (i = 0; i < sizeof(SOUND_WIN_ZOMBIES); i++)
		precache_sound(SOUND_WIN_ZOMBIES[i]);

	for (i = 0; i < sizeof(SOUND_WIN_HUMANS); i++)
		precache_sound(SOUND_WIN_HUMANS[i]);

	for (i = 0; i < sizeof(SOUND_WIN_NO_ONE); i++)
		precache_sound(SOUND_WIN_NO_ONE[i]);*/
}

public plugin_init()
{
	register_message(get_user_msgid("TextMsg"), "@MSG_TextMsg");
	register_message(get_user_msgid("SendAudio"), "@MSG_SendAudio");

	register_event("HLTV", "@EV_RoundStart", "a", "1=0", "2=0");
	
	RegisterHookChain(RG_RoundEnd, "@RoundEnd_Post", true);
	RegisterHookChain(RG_CBasePlayer_Spawn, "@CBasePlayer_Spawn_Post", true);

	g_tBlockedTextMsg = TrieCreate();
	g_tBlockedSendAudio = TrieCreate();

	for (new i = 0; i < sizeof(BLOCKED_TEXTMSG); i++)
		TrieSetCell(g_tBlockedTextMsg, BLOCKED_TEXTMSG[i], 0);

	for (new i = 0; i < sizeof(BLOCKED_SENDAUDIO); i++)
		TrieSetCell(g_tBlockedSendAudio, BLOCKED_SENDAUDIO[i], 0);

	bind_pcvar_float(create_cvar("rz_roundstart_notice_x", "-1.0", FCVAR_NONE, "", true, -1.0, true, 1.0), roundstart_notice_pos[0]);
	bind_pcvar_float(create_cvar("rz_roundstart_notice_y", "0.12", FCVAR_NONE, "", true, -1.0, true, 1.0), roundstart_notice_pos[1]);

	bind_pcvar_float(create_cvar("rz_roundend_notice_x", "-1.0", FCVAR_NONE, "", true, -1.0, true, 1.0), roundend_notice_pos[0]);
	bind_pcvar_float(create_cvar("rz_roundend_notice_y", "0.17", FCVAR_NONE, "", true, -1.0, true, 1.0), roundend_notice_pos[1]);
}

@MSG_TextMsg(id, dest, player)
{
	new value;
	new text[32];

	get_msg_arg_string(2, text, charsmax(text));

	if (TrieGetCell(g_tBlockedTextMsg, text, value))
		return PLUGIN_HANDLED;

	return PLUGIN_CONTINUE;
}

@MSG_SendAudio(id, dest, player)
{
	new value;
	new text[32];

	get_msg_arg_string(2, text, charsmax(text));

	if (TrieGetCell(g_tBlockedSendAudio, text, value))
		return PLUGIN_HANDLED;

	return PLUGIN_CONTINUE;
}

@EV_RoundStart()
{
	if (!get_member_game(m_bGameStarted))
		return;

	set_dhudmessage(0, 125, 200, roundstart_notice_pos[0], roundstart_notice_pos[1], 0, 0.0, 3.0, 2.0, 1.0);
	show_dhudmessage(0, "%L", LANG_PLAYER, "RZ_NOTICE_VIRUS_FREE");
}

@RoundEnd_Post(WinStatus:status, ScenarioEventEndRound:event, Float:delay)
{
	if (rz_game_is_warmup())
		return;

	switch (status)
	{
		case WINSTATUS_CTS:
		{
			set_dhudmessage(0, 0, 200, roundend_notice_pos[0], roundend_notice_pos[1], 0, 0.0, 3.0, 2.0, 1.0);
			show_dhudmessage(0, "%L", LANG_PLAYER, "RZ_WIN_HUMAN");

			//client_cmd(0, "stopsound; spk ^"%s^"", SOUND_WIN_HUMANS[random_num(0, sizeof(SOUND_WIN_HUMANS) - 1)]);
		}
		case WINSTATUS_TERRORISTS:
		{
			set_dhudmessage(200, 0, 0, roundend_notice_pos[0], roundend_notice_pos[1], 0, 0.0, 3.0, 2.0, 1.0);
			show_dhudmessage(0, "%L", LANG_PLAYER, "RZ_WIN_ZOMBIE");

			//client_cmd(0, "stopsound; spk ^"%s^"", SOUND_WIN_ZOMBIES[random_num(0, sizeof(SOUND_WIN_ZOMBIES) - 1)]);
		}
		case WINSTATUS_DRAW:
		{
			set_dhudmessage(0, 200, 0, roundend_notice_pos[0], roundend_notice_pos[1], 0, 0.0, 3.0, 2.0, 1.0);
			show_dhudmessage(0, "%L", LANG_PLAYER, "RZ_WIN_NO_ONE");

			//client_cmd(0, "stopsound; spk ^"%s^"", SOUND_WIN_NO_ONE[random_num(0, sizeof(SOUND_WIN_NO_ONE) - 1)]);
		}
	}
}

@CBasePlayer_Spawn_Post(id)
{
	if (!is_user_alive(id))
		return;

	if (get_member(id, m_iNumSpawns) != 1)
		return;

	client_print_color(id, print_team_default, "^1• • • ^4Re Zombie Plague %s^1 • • •", REZP_VERSION_STR);
	rz_print_chat(id, print_team_default, "%L", LANG_PLAYER, "RZ_PRESS_GAME_MENU");
}
