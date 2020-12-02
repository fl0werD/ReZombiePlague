#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <reapi>
#include <rezp>
#include <rezp_util>

const ADMINMENU_FLAGS = ADMIN_MENU;

new g_iMenu_Game;

new const GAME_MENU_ID[] = "RZ_GameMenu";

public plugin_init()
{
	register_plugin("[ReZP] Menu: Game", REZP_VERSION_STR, "fl0wer");

	new const cmds[][] = { "chooseteam", "gamemenu", "say /menu" };

	for (new i = 0; i < sizeof(cmds); i++)
		register_clcmd(cmds[i], "@Command_GameMenu");

	g_iMenu_Game = register_menuid(GAME_MENU_ID);
	register_menucmd(g_iMenu_Game, 1023, "@HandleMenu_Game");
}

@Command_GameMenu(id)
{
	if (is_nullent(id))
		return PLUGIN_CONTINUE;
	
	if (get_member(id, m_iJoiningState) != JOINED)
		return PLUGIN_CONTINUE;

	new menu, keys;
	get_user_menu(id, menu, keys);

	if (menu != g_iMenu_Game)
		GameMenu_Show(id);
	else
		MENU_CLOSE(id);

	return PLUGIN_HANDLED;
}

GameMenu_Show(id)
{
	new bool:warmup = rz_game_is_warmup();
	new isAlive = is_user_alive(id);
	new keys;
	new len;
	new text[MAX_MENU_LENGTH];

	SetGlobalTransTarget(id);

	add_formatex("\yRe Zombie Plague^n");
	add_formatex("\y%l^n^n", "RZ_MENU_GAME_TITLE");

	add_formatex("\r1. \w%l^n", "RZ_MENU_GAME_SELECT_WPNS");
	keys |= MENU_KEY_1;

	if (!warmup && isAlive)
	{
		add_formatex("\r2. \w%l^n", "RZ_MENU_GAME_BUY_EXTRA");
		keys |= MENU_KEY_2;
	}
	else
		add_formatex("\d2. %l^n", "RZ_MENU_GAME_BUY_EXTRA");

	add_formatex("\r3. \wChoose Zombie Sub-Class^n");
	keys |= MENU_KEY_3;

	// check last
	if (get_member(id, m_iTeam) == TEAM_SPECTATOR)
		add_formatex("\r4. \w%l^n", "RZ_MENU_GAME_JOIN_GAME");
	else
		add_formatex("\r4. \w%l^n", "RZ_MENU_GAME_JOIN_SPECS");

	keys |= MENU_KEY_4;

	add_formatex("^n");
	add_formatex("^n");
	add_formatex("^n");
	add_formatex("^n");

	if (get_user_flags(id) & ADMINMENU_FLAGS)
	{
		add_formatex("\r9. \w%l^n", "RZ_MENU_GAME_ADMIN");
		keys |= MENU_KEY_9;
	}
	else
		add_formatex("\d9. %l^n", "RZ_MENU_GAME_ADMIN");

	add_formatex("\r0. \w%l", "RZ_CLOSE");
	keys |= MENU_KEY_0;

	show_menu(id, keys, text, -1, GAME_MENU_ID);
}

@HandleMenu_Game(id, key)
{
	if (key == 9)
		return PLUGIN_HANDLED;
	
	switch (key)
	{
		case 0:
		{
			amxclient_cmd(id, "guns");
		}
		case 1:
		{
			amxclient_cmd(id, "items");
		}
		case 2:
		{
			amxclient_cmd(id, "zombie");
		}
		case 3:
		{
			if (get_member(id, m_iTeam) == TEAM_SPECTATOR)
			{
				rg_set_user_team(id, TEAM_CT);
			}
			else
			{
				if (is_user_alive(id))
				{
					new Float:frags = get_entvar(id, var_frags);
					
					ExecuteHamB(Ham_Killed, id, id, GIB_NEVER);
					set_entvar(id, var_frags, frags);
				}

				rg_set_user_team(id, TEAM_SPECTATOR);
			}
		}
		case 8:
		{
			amxclient_cmd(id, "adminmenu");
		}
	}
	
	return PLUGIN_HANDLED;
}
