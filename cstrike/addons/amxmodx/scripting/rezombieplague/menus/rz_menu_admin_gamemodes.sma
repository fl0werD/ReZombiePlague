#pragma semicolon 1

#include <amxmodx>
#include <reapi>
#include <rezp>

const ADMINMENU_FLAGS = ADMIN_MENU;

const GAMEMODES_MAX_PAGE_ITEMS = 7;

new g_iMenuPage[MAX_PLAYERS + 1];
new Array:g_aMenuItems[MAX_PLAYERS + 1];

new const GAMEMODES_MENU_ID[] = "RZ_AdminGameModes";

public plugin_precache()
{
	register_plugin("[ReZP] Admin Menu: Game Modes", REZP_VERSION_STR, "fl0wer");

	for (new i = 1; i <= MaxClients; i++)
		g_aMenuItems[i] = ArrayCreate(1, 0);
}

public plugin_init()
{
	new const cmds[][] = { "gamemodesmenu", "say /gamemodesmenu" };

	for (new i = 0; i < sizeof(cmds); i++)
		register_clcmd(cmds[i], "@Command_GameModesMenu");

	register_menucmd(register_menuid(GAMEMODES_MENU_ID), 1023, "@HandleMenu_GameModes");
}

@Command_GameModesMenu(id)
{
	GameModesMenu_Show(id);
	return PLUGIN_HANDLED;
}

GameModesMenu_Show(id, page = 0)
{
	if (page < 0)
	{
		amxclient_cmd(id, "adminmenu");
		return;
	}

	if (!get_member_game(m_bGameStarted) || !get_member_game(m_bFreezePeriod))
		return;

	ArrayClear(g_aMenuItems[id]);

	new gameModeStart = rz_gamemodes_start();
	new gameModeSize = rz_gamemodes_size();

	for (new i = gameModeStart; i < gameModeStart + gameModeSize; i++)
	{
		ArrayPushCell(g_aMenuItems[id], i);
	}

	new itemNum = ArraySize(g_aMenuItems[id]);
	new bool:singlePage = bool:(itemNum < 9);
	new itemPerPage = singlePage ? 8 : GAMEMODES_MAX_PAGE_ITEMS;
	new i = min(page * itemPerPage, itemNum);
	new start = i - (i % itemPerPage);
	new end = min(start + itemPerPage, itemNum);

	g_iMenuPage[id] = start / itemPerPage;

	new keys;
	new len;
	new index;
	new item;
	new text[MAX_MENU_LENGTH];
	new name[32];

	SetGlobalTransTarget(id);

	if (singlePage)
		add_formatex("\yStart Game Mode^n^n");
	else
		add_formatex("\yStart Game Mode \r%d/%d^n^n", g_iMenuPage[id] + 1, ((itemNum - 1) / itemPerPage) + 1);

	if (!itemNum)
	{
		add_formatex("\r%d. \d%l^n", ++item, "RZ_EMPTY");
	}
	else
	{
		for (i = start; i < end; i++)
		{
			index = ArrayGetCell(g_aMenuItems[id], i);

			rz_gamemode_get(index, RZ_GAMEMODE_NAME, name, charsmax(name));

			if (rz_gamemodes_get_status(index, true) == RZ_CONTINUE)
			{
				add_formatex("\r%d. \w%l^n", item + 1, name);
				keys |= (1<<item);
			}
			else
				add_formatex("\d%d. %l^n", item + 1, name);
			
			item++;
		}
	}

	if (!singlePage)
	{
		for (i = item; i < GAMEMODES_MAX_PAGE_ITEMS; i++)
			add_formatex("^n");

		if (end < itemNum)
		{
			add_formatex("^n\r8. \w%l", "RZ_NEXT");
			keys |= MENU_KEY_8;
		}
		else if (g_iMenuPage[id])
			add_formatex("^n\d8. %l", "RZ_NEXT");
	}

	add_formatex("^n\r9. \w%l", "RZ_BACK");
	keys |= MENU_KEY_9;

	add_formatex("^n\r0. \w%l", "RZ_CLOSE");
	keys |= MENU_KEY_0;

	show_menu(id, keys, text, -1, GAMEMODES_MENU_ID);
}

@HandleMenu_GameModes(id, key)
{
	if (key == 9)
		return PLUGIN_HANDLED;
	
	if (!get_member_game(m_bGameStarted) || !get_member_game(m_bFreezePeriod))
		return PLUGIN_HANDLED;

	switch (key)
	{
		case 7: GameModesMenu_Show(id, ++g_iMenuPage[id]);
		case 8: GameModesMenu_Show(id, --g_iMenuPage[id]);
		default:
		{
			new gameMode = ArrayGetCell(g_aMenuItems[id], g_iMenuPage[id] * GAMEMODES_MAX_PAGE_ITEMS + key);

			if (rz_gamemodes_get_status(gameMode, true) != RZ_CONTINUE)
				return PLUGIN_HANDLED;

			//rz_gamemodes_set(gameMode, RZ_true);
		}
	}

	return PLUGIN_HANDLED;
}
