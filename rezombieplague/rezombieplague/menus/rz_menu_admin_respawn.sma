#pragma semicolon 1

#include <amxmodx>
#include <reapi>
#include <rezp>

const ADMINMENU_FLAGS = ADMIN_MENU;

const RESPAWN_MAX_PAGE_ITEMS = 7;

new g_iMenuPage[MAX_PLAYERS + 1];
new g_iMenuPlayers[MAX_PLAYERS + 1][MAX_PLAYERS];

new const RESPAWN_MENU_ID[] = "RZ_AdminRespawn";

public plugin_init()
{
	register_plugin("[ReZP] Admin Menu: Respawn", REZP_VERSION_STR, "fl0wer");

	new const cmds[][] = { "respawnmenu", "say /respawnmenu" };

	for (new i = 0; i < sizeof(cmds); i++)
		register_clcmd(cmds[i], "@Command_RespawnMenu");

	register_menucmd(register_menuid(RESPAWN_MENU_ID), 1023, "@HandleMenu_Respawn");
}

@Command_RespawnMenu(id)
{
	RespawnMenu_Show(id);
	return PLUGIN_HANDLED;
}

RespawnMenu_Show(id, page = 0)
{
	if (page < 0)
	{
		amxclient_cmd(id, "adminmenu");
		return;
	}

	if (!(get_user_flags(id) & ADMINMENU_FLAGS))
		return;

	new playersNum;
	new playersArray[MAX_PLAYERS];

	for (new i = 1; i <= MaxClients; i++)
	{
		if (!is_user_connected(i))
			continue;

		if (is_user_alive(i))
			continue;

		if (get_member(i, m_iTeam) == TEAM_SPECTATOR)
			continue;

		playersArray[playersNum] = i;
		g_iMenuPlayers[id][playersNum] = get_user_userid(i);

		playersNum++;
	}

	new i = min(page * RESPAWN_MAX_PAGE_ITEMS, playersNum);
	new start = i - (i % RESPAWN_MAX_PAGE_ITEMS);
	new end = min(start + RESPAWN_MAX_PAGE_ITEMS, playersNum);

	g_iMenuPage[id] = start / RESPAWN_MAX_PAGE_ITEMS;

	new keys;
	new len;
	new target;
	new item;
	new text[MAX_MENU_LENGTH];

	SetGlobalTransTarget(id);

	add_formatex("\yRespawn Menu");

	if (!playersNum)
	{
		add_formatex("^n^n\r%d. \d%l^n", ++item, "RZ_EMPTY");
	}
	else
	{
		if (playersNum > RESPAWN_MAX_PAGE_ITEMS)
			add_formatex(" \r%d/%d", g_iMenuPage[id] + 1, ((playersNum - 1) / RESPAWN_MAX_PAGE_ITEMS) + 1);

		add_formatex("^n^n");

		for (i = start; i < end; i++)
		{
			target = playersArray[i];

			keys |= (1<<item);
			add_formatex("\r%d. \w%n^n", item + 1, target);
			item++;
		}
	}

	for (i = item; i < RESPAWN_MAX_PAGE_ITEMS; i++)
		add_formatex("^n");

	if (end < playersNum)
	{
		add_formatex("^n\r8. \w%l", "RZ_NEXT");
		keys |= MENU_KEY_8;
	}
	else if (g_iMenuPage[id])
		add_formatex("^n\d8. %l", "RZ_NEXT");

	add_formatex("^n\r9. \w%l", "RZ_BACK");
	keys |= MENU_KEY_9;

	add_formatex("^n\r0. \w%l", "RZ_CLOSE");
	keys |= MENU_KEY_0;

	show_menu(id, keys, text, -1, RESPAWN_MENU_ID);
}

@HandleMenu_Respawn(id, key)
{
	if (key == 9)
		return PLUGIN_HANDLED;

	switch (key)
	{
		case 7: RespawnMenu_Show(id, ++g_iMenuPage[id]);
		case 8: RespawnMenu_Show(id, --g_iMenuPage[id]);
		default:
		{
			new target = find_player("k", g_iMenuPlayers[id][g_iMenuPage[id] * RESPAWN_MAX_PAGE_ITEMS + key]);

			if (!is_user_connected(target))
			{
				// disc
				RespawnMenu_Show(id, g_iMenuPage[id]);
				return PLUGIN_HANDLED;
			}

			if (get_member(target, m_iTeam) == TEAM_SPECTATOR)
			{
				RespawnMenu_Show(id, g_iMenuPage[id]);
				return PLUGIN_HANDLED;
			}

			if (!is_user_alive(target))
				rg_round_respawn(target);

			RespawnMenu_Show(id, g_iMenuPage[id]);
		}
	}

	return PLUGIN_HANDLED;
}
