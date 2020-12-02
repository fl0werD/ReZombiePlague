#pragma semicolon 1

#include <amxmodx>
#include <reapi>
#include <rezp>
#include <rezp_util>

const ITEMS_MAX_PAGE_ITEMS = 7;

new g_iMenuPage[MAX_PLAYERS + 1];
new Array:g_aMenuItems[MAX_PLAYERS + 1];

new const ITEMS_MENU_ID[] = "RZ_ExtraItems";

public plugin_precache()
{
	register_plugin("[ReZP] Menu: Extra Items", REZP_VERSION_STR, "fl0wer");

	for (new i = 1; i <= MaxClients; i++)
		g_aMenuItems[i] = ArrayCreate(1, 0);
}

public plugin_init()
{
	new const cmds[][] = { "items", "say /items" };

	for (new i = 0; i < sizeof(cmds); i++)
		register_clcmd(cmds[i], "@Command_Items");

	register_menucmd(register_menuid(ITEMS_MENU_ID), 1023, "@HandleMenu_Items");
}

@Command_Items(id)
{
	Items_Show(id);
	return PLUGIN_HANDLED;
}

Items_Show(id, page = 0)
{
	if (page < 0)
	{
		amxclient_cmd(id, "gamemenu");
		return;
	}

	if (rz_game_is_warmup())
		return;

	if (get_member_game(m_bRoundTerminating))
		return;

	ArrayClear(g_aMenuItems[id]);

	new itemStart = rz_item_start();
	new itemSize = rz_item_size();

	for (new i = itemStart; i < itemStart + itemSize; i++)
	{
		if (rz_item_player_get_status(id, i) >= RZ_BREAK)
			continue;

		ArrayPushCell(g_aMenuItems[id], i);
	}

	new itemNum = ArraySize(g_aMenuItems[id]);
	new bool:singlePage = bool:(itemNum < 9);
	new itemPerPage = singlePage ? 8 : ITEMS_MAX_PAGE_ITEMS;
	new i = min(page * itemPerPage, itemNum);
	new start = i - (i % itemPerPage);
	new end = min(start + itemPerPage, itemNum);

	g_iMenuPage[id] = start / itemPerPage;

	new account = get_member(id, m_iAccount);
	new bool:isAmmoPacks = rz_main_ammopacks_enabled();
	new keys;
	new len;
	new index;
	new item;
	new text[MAX_MENU_LENGTH];
	new name[32];
	new cost;

	SetGlobalTransTarget(id);

	if (singlePage)
		add_formatex("\y%l^n^n", "RZ_ITEMS_TITLE");
	else
		add_formatex("\y%l \r%d/%d^n^n", "RZ_ITEMS_TITLE", g_iMenuPage[id] + 1, ((itemNum - 1) / itemPerPage) + 1);

	if (!itemNum)
	{
		add_formatex("\r%d. \d%l^n", ++item, "RZ_EMPTY");
	}
	else
	{
		for (i = start; i < end; i++)
		{
			index = ArrayGetCell(g_aMenuItems[id], i);

			rz_item_get_name_langkey(index, name, charsmax(name));
			cost = rz_item_get_cost(index);

			if (account >= cost && rz_item_player_get_status(id, index) == RZ_CONTINUE)
			{
				add_formatex("\r%d. \w%l \y%l^n", item + 1, name, isAmmoPacks ? "RZ_FMT_AMMOPACKS" : "RZ_FMT_DOLLARS", cost);
				keys |= (1<<item);
			}
			else
			{
				add_formatex("\r%d. \d%l \y%l^n", item + 1, name, isAmmoPacks ? "RZ_FMT_AMMOPACKS" : "RZ_FMT_DOLLARS", cost);
			}

			item++;
		}
	}

	if (!singlePage)
	{
		for (i = item; i < ITEMS_MAX_PAGE_ITEMS; i++)
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

	show_menu(id, keys, text, -1, ITEMS_MENU_ID);
}

@HandleMenu_Items(id, key)
{
	if (key == 9)
		return PLUGIN_HANDLED;

	if (rz_game_is_warmup())
		return PLUGIN_HANDLED;

	if (get_member_game(m_bRoundTerminating))
		return PLUGIN_HANDLED;

	switch (key)
	{
		case 7: Items_Show(id, ++g_iMenuPage[id]);
		case 8: Items_Show(id, --g_iMenuPage[id]);
		default:
		{
			new item = ArrayGetCell(g_aMenuItems[id], g_iMenuPage[id] * ITEMS_MAX_PAGE_ITEMS + key);

			if (rz_item_player_get_status(id, item) >= RZ_SUPERCEDE)
				return PLUGIN_HANDLED;

			new cost = rz_item_get_cost(item);

			if (get_member(id, m_iAccount) < cost)
				return PLUGIN_HANDLED;

			if (!rz_item_player_give(id, item))
				return PLUGIN_HANDLED;

			rg_add_account(id, -cost);
		}
	}
	
	return PLUGIN_HANDLED;
}
