#pragma semicolon 1

#include <amxmodx>
#include <reapi>
#include <rezp>

const ADMINMENU_FLAGS = ADMIN_MENU;

new const MAIN_MENU_ID[] = "RZ_AdminMenu";

public plugin_init()
{
	register_plugin("[ReZP] Menu: Admin", REZP_VERSION_STR, "fl0wer");

	new const cmds[][] = { "adminmenu", "say /adminmenu" };

	for (new i = 0; i < sizeof(cmds); i++)
		register_clcmd(cmds[i], "@Command_AdminMenu");

	register_menucmd(register_menuid(MAIN_MENU_ID), 1023, "@HandleMenu_Main");
}

@Command_AdminMenu(id)
{
	MainMenu_Show(id);
	return PLUGIN_HANDLED;
}

MainMenu_Show(id)
{
	if (!(get_user_flags(id) & ADMINMENU_FLAGS))
		return;

	new bool:warmup = rz_game_is_warmup();
	new bool:gameStarted = get_member_game(m_bGameStarted);
	new bool:freezePeriod = get_member_game(m_bFreezePeriod);
	new keys;
	new len;
	new text[MAX_MENU_LENGTH];

	SetGlobalTransTarget(id);

	add_formatex("\yAdmin Menu^n^n");

	add_formatex("\r1. \wRespawn Player^n");
	keys |= MENU_KEY_1;

	if (!warmup && gameStarted && freezePeriod)
	{
		add_formatex("\r2. \wStart Game Mode^n");
		keys |= MENU_KEY_2;
	}
	else
		add_formatex("\d2. Start Game Mode^n");

	if (!warmup && gameStarted && !freezePeriod)
	{
		add_formatex("\r3. \wChange Player Class^n");
		keys |= MENU_KEY_3;
	}
	else
		add_formatex("\d3. Change Player Class^n");

	if (warmup && !get_member_game(m_bRoundTerminating))
	{
		add_formatex("\r4. \wFinish Warmup^n");
		keys |= MENU_KEY_4;
	}
	else
		add_formatex("\d4. Finish Warmup^n");

	add_formatex("^n");
	add_formatex("^n");
	add_formatex("^n");
	add_formatex("^n");

	add_formatex("^n\r9. \w%l", "RZ_BACK");
	keys |= MENU_KEY_9;

	add_formatex("^n\r0. \w%l", "RZ_CLOSE");
	keys |= MENU_KEY_0;

	show_menu(id, keys, text, -1, MAIN_MENU_ID);
}

@HandleMenu_Main(id, key)
{
	if (key == 9)
		return PLUGIN_HANDLED;
	
	if (!(get_user_flags(id) & ADMINMENU_FLAGS))
		return PLUGIN_HANDLED;

	switch (key)
	{
		case 0:
		{
			amxclient_cmd(id, "respawnmenu");
		}
		case 1:
		{
			amxclient_cmd(id, "gamemodesmenu");
		}
		case 2:
		{
			amxclient_cmd(id, "changeclassmenu");
		}
		case 3:
		{
			if (rz_game_is_warmup() && !get_member_game(m_bRoundTerminating))
				server_cmd("endround");
		}
		case 8:
		{
			amxclient_cmd(id, "gamemenu");
		}
	}
	
	return PLUGIN_HANDLED;
}
