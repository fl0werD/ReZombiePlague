#pragma semicolon 1

#include <amxmodx>
#include <reapi>
#include <rezp>

const SUBCLASS_MAX_PAGE_ITEMS = 7;

new g_iClass_Zombie;

new g_iMenuPage[MAX_PLAYERS + 1];
new Array:g_aMenuItems[MAX_PLAYERS + 1];

new const SUBCLASS_MENU_ID[] = "RZ_ChooseZombieSubclass";

public plugin_precache()
{
	register_plugin("[ReZP] Menu: Choose Zombie Subclass", REZP_VERSION_STR, "fl0wer");

	RZ_CHECK_CLASS_EXISTS(g_iClass_Zombie, "class_zombie");

	for (new i = 1; i <= MaxClients; i++)
		g_aMenuItems[i] = ArrayCreate(1, 0);
}

public plugin_init()
{
	register_menucmd(register_menuid(SUBCLASS_MENU_ID), 1023, "@HandleMenu_Subclass");	

	new const cmds[][] = { "zombie", "say /zombie" };

	for (new i = 0; i < sizeof(cmds); i++)
		register_clcmd(cmds[i], "@Command_ChooseSubclass");
}

@Command_ChooseSubclass(id)
{
	if (is_nullent(id))
		return PLUGIN_CONTINUE;
	
	if (get_member(id, m_iJoiningState) != JOINED)
		return PLUGIN_CONTINUE;

	SubclassSelectMenu_Show(id);
	return PLUGIN_HANDLED;
}

SubclassSelectMenu_Show(id, page = 0)
{
	if (page < 0)
		return;

	ArrayClear(g_aMenuItems[id]);

	new subclassStart = rz_subclass_start();
	new subclassSize = rz_subclass_size();

	for (new i = subclassStart; i < subclassStart + subclassSize; i++)
	{
		if (rz_subclass_get(i, RZ_SUBCLASS_CLASS) != g_iClass_Zombie)
			continue;

		if (rz_subclass_player_get_status(id, i) >= RZ_BREAK)
			continue;

		ArrayPushCell(g_aMenuItems[id], i);
	}

	new itemsNum = ArraySize(g_aMenuItems[id]);

	if (!itemsNum)
		return;

	new bool:singlePage = bool:(itemsNum < 10);
	new itemPerPage = singlePage ? 9 : SUBCLASS_MAX_PAGE_ITEMS;
	new i = min(page * itemPerPage, itemsNum);
	new start = i - (i % itemPerPage);
	new end = min(start + itemPerPage, itemsNum);

	g_iMenuPage[id] = start / itemPerPage;

	new chosenSubclass = rz_player_get(id, RZ_PLAYER_SUBCLASS_CHOSEN, g_iClass_Zombie);
	new keys;
	new len;
	new index;
	new item;
	new text[MAX_MENU_LENGTH];
	new name[32];
	new desc[64];

	SetGlobalTransTarget(id);

	rz_class_get(g_iClass_Zombie, RZ_CLASS_NAME, name, charsmax(name));

	if (singlePage)
		add_formatex("\y%l^n^n", "RZ_SELECT_SUBCLASS", name);
	else
		add_formatex("\y%l \r%d/%d^n^n", "RZ_SELECT_SUBCLASS", name, g_iMenuPage[id] + 1, ((itemsNum - 1) / itemPerPage) + 1);

	for (i = start; i < end; i++)
	{
		index = ArrayGetCell(g_aMenuItems[id], i);

		rz_subclass_get(index, RZ_SUBCLASS_NAME, name, charsmax(name));
		rz_subclass_get(index, RZ_SUBCLASS_DESC, desc, charsmax(desc));

		if (rz_subclass_player_get_status(id, index) == RZ_CONTINUE)
		{
			if (chosenSubclass != index)
				add_formatex("\r%d. \w%l \d%l^n", item + 1, name, desc);
			else
				add_formatex("\r%d. \w%l \y*^n", item + 1, name);

			keys |= (1<<item);
		}
		else
			add_formatex("\d%d. %l %l^n", item + 1, name, desc);

		item++;
	}

	if (!singlePage)
	{
		for (i = item; i < SUBCLASS_MAX_PAGE_ITEMS; i++)
			add_formatex("^n");

		if (end < itemsNum)
		{
			add_formatex("^n\r8. \w%l", "RZ_NEXT");
			keys |= MENU_KEY_8;
		}
		else
			add_formatex("^n\d8. %l", "RZ_NEXT");

		if (g_iMenuPage[id])
		{
			add_formatex("^n\r9. \w%l", "RZ_BACK");
			keys |= MENU_KEY_9;
		}
		else
			add_formatex("^n\d9. %l", "RZ_BACK");
	}

	add_formatex("^n\r0. \w%l", "RZ_CLOSE");
	keys |= MENU_KEY_0;

	show_menu(id, keys, text, -1, SUBCLASS_MENU_ID);
}

@HandleMenu_Subclass(id, key)
{
	if (key == 9)
		return PLUGIN_HANDLED;

	if (!is_user_alive(id))
		return PLUGIN_HANDLED;

	if (ArraySize(g_aMenuItems[id]) > 9)
	{
		switch (key)
		{
			case 7:
			{
				SubclassSelectMenu_Show(id, ++g_iMenuPage[id]);
				return PLUGIN_HANDLED;
			}
			case 8:
			{
				SubclassSelectMenu_Show(id, --g_iMenuPage[id]);
				return PLUGIN_HANDLED;
			}
		}
	}

	new subclass = ArrayGetCell(g_aMenuItems[id], g_iMenuPage[id] * SUBCLASS_MAX_PAGE_ITEMS + key);

	if (rz_player_get(id, RZ_PLAYER_SUBCLASS_CHOSEN, g_iClass_Zombie) == subclass)
		rz_player_set(id, RZ_PLAYER_SUBCLASS_CHOSEN, 0, g_iClass_Zombie);
	else
		rz_player_set(id, RZ_PLAYER_SUBCLASS_CHOSEN, subclass, g_iClass_Zombie);

	return PLUGIN_HANDLED;
}
