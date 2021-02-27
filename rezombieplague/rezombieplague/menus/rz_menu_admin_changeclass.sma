#pragma semicolon 1

#include <amxmodx>
#include <reapi>
#include <rezp>

const ADMINMENU_FLAGS = ADMIN_MENU;

const CHANGE_CLASS_MAX_PAGE_ITEMS = 6;

new g_iMenuPage[MAX_PLAYERS + 1];
new g_iMenuClass[MAX_PLAYERS + 1];
new g_iMenuPlayers[MAX_PLAYERS + 1][MAX_PLAYERS];

new const CHANGECLASS_MENU_ID[] = "RZ_AdminChangeClass";

public plugin_init()
{
	register_plugin("[ReZP] Admin Menu: Change Class", REZP_VERSION_STR, "fl0wer");

	new const cmds[][] = { "changeclassmenu", "say /changeclassmenu" };

	for (new i = 0; i < sizeof(cmds); i++)
		register_clcmd(cmds[i], "@Command_ChangeClassMenu");

	register_menucmd(register_menuid(CHANGECLASS_MENU_ID), 1023, "@HandleMenu_ChangeClass");
}

@Command_ChangeClassMenu(id)
{
	ChangeClassMenu_Show(id);
	return PLUGIN_HANDLED;
}

ChangeClassMenu_Show(id, page = 0, class = 0)
{
	if (page < 0)
	{
		amxclient_cmd(id, "adminmenu");
		return;
	}

	if (!get_member_game(m_bGameStarted) || get_member_game(m_bFreezePeriod))
		return;

	if (!class)
		class = rz_class_start();

	new playersNum;
	new playersArray[MAX_PLAYERS];

	for (new i = 1; i <= MaxClients; i++)
	{
		if (!is_user_connected(i))
			continue;

		if (!is_user_alive(i))
			continue;

		if (rz_player_get(i, RZ_PLAYER_CLASS) == class)
			continue;

		playersArray[playersNum] = i;
		g_iMenuPlayers[id][playersNum] = get_user_userid(i);

		playersNum++;
	}

	new i = min(page * CHANGE_CLASS_MAX_PAGE_ITEMS, playersNum);
	new start = i - (i % CHANGE_CLASS_MAX_PAGE_ITEMS);
	new end = min(start + CHANGE_CLASS_MAX_PAGE_ITEMS, playersNum);

	g_iMenuPage[id] = start / CHANGE_CLASS_MAX_PAGE_ITEMS;
	g_iMenuClass[id] = class;

	new keys;
	new len;
	new target;
	new item;
	new text[MAX_MENU_LENGTH];
	new name[RZ_MAX_LANGKEY_LENGTH];

	SetGlobalTransTarget(id);

	add_formatex("\yChange Player Class");

	if (!playersNum)
	{
		add_formatex("^n^n\r%d. \d%l^n", ++item, "RZ_EMPTY");
	}
	else
	{
		if (playersNum > CHANGE_CLASS_MAX_PAGE_ITEMS)
			add_formatex(" \r%d/%d", g_iMenuPage[id] + 1, ((playersNum - 1) / CHANGE_CLASS_MAX_PAGE_ITEMS) + 1);

		add_formatex("^n^n");

		new playerClass;

		for (i = start; i < end; i++)
		{
			target = playersArray[i];

			add_formatex("\r%d. \w%n", item + 1, target);

			if (is_user_alive(target))
			{
				playerClass = rz_player_get(target, RZ_PLAYER_CLASS);

				rz_class_get(playerClass, RZ_CLASS_NAME, name, charsmax(name));
				add_formatex(" %s[%l]^n", rz_class_get(playerClass, RZ_CLASS_TEAM) == TEAM_CT ? "\y" : "\r", name);
			}
			else
				add_formatex(" \r%l^n", "RZ_DEAD");

			keys |= (1<<item);
			item++;
		}
	}

	for (i = item; i < CHANGE_CLASS_MAX_PAGE_ITEMS; i++)
		add_formatex("^n");

	rz_class_get(class, RZ_CLASS_NAME, name, charsmax(name));

	add_formatex("^n\r7. \w%l (%d/%d): %s%l^n", "RZ_TURN_INTO", (g_iMenuClass[id] - rz_class_start()) + 1, rz_class_size(), rz_class_get(class, RZ_CLASS_TEAM) == TEAM_CT ? "\y" : "\r", name);
	keys |= MENU_KEY_7;

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

	show_menu(id, keys, text, -1, CHANGECLASS_MENU_ID);
}

@HandleMenu_ChangeClass(id, key)
{
	if (key == 9)
		return PLUGIN_HANDLED;
	
	if (!get_member_game(m_bGameStarted) || get_member_game(m_bFreezePeriod))
		return PLUGIN_HANDLED;

	switch (key)
	{
		case 6:
		{
			new start = rz_class_start();

			if (++g_iMenuClass[id] >= start + rz_class_size())
				g_iMenuClass[id] = start;

			ChangeClassMenu_Show(id, _, g_iMenuClass[id]);
		}
		case 7: ChangeClassMenu_Show(id, ++g_iMenuPage[id], g_iMenuClass[id]);
		case 8: ChangeClassMenu_Show(id, --g_iMenuPage[id], g_iMenuClass[id]);
		default:
		{
			new target = find_player("k", g_iMenuPlayers[id][g_iMenuPage[id] * CHANGE_CLASS_MAX_PAGE_ITEMS + key]);

			if (!is_user_connected(target))
			{
				// disconnected
				ChangeClassMenu_Show(id, _, g_iMenuClass[id]);
				return PLUGIN_HANDLED;
			}

			if (rz_player_get(target, RZ_PLAYER_CLASS) == g_iMenuClass[id])
			{
				//already
				ChangeClassMenu_Show(id, _, g_iMenuClass[id]);
				return PLUGIN_HANDLED;
			}

			if (is_user_alive(target))
				rz_class_player_change(target, 0, g_iMenuClass[id]);

			ChangeClassMenu_Show(id, _, g_iMenuClass[id]);
		}
	}
	
	return PLUGIN_HANDLED;
}
