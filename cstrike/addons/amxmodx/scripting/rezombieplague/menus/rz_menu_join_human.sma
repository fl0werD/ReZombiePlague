#pragma semicolon 1

#include <amxmodx>
#include <reapi>
#include <rezp>

const SUBCLASS_MAX_PAGE_ITEMS = 7;

new g_iMenuPage[MAX_PLAYERS + 1];
new Array:g_aMenuItems[MAX_PLAYERS + 1];

new g_iClass_Human;

new mp_auto_join_team;

public plugin_precache()
{
	register_plugin("[ReZP] Join Menu: Human Subclasses", REZP_VERSION_STR, "fl0wer");

	RZ_CHECK_CLASS_EXISTS(g_iClass_Human, "class_human");

	for (new i = 1; i <= MaxClients; i++)
		g_aMenuItems[i] = ArrayCreate(1, 0);
}

public plugin_init()
{
	register_clcmd("jointeam", "@Command_JoinCmd");
	register_clcmd("joinclass", "@Command_JoinCmd");
	register_clcmd("chooseteam", "@Command_ChooseTeam");

	RegisterHookChain(RG_ShowVGUIMenu, "@ShowVGUIMenu_Pre", false);
	RegisterHookChain(RG_ShowVGUIMenu, "@ShowVGUIMenu_Post", true);
	RegisterHookChain(RG_HandleMenu_ChooseTeam, "@HandleMenu_ChooseTeam_Pre", false);

	bind_pcvar_num(get_cvar_pointer("mp_auto_join_team"), mp_auto_join_team);
}

public client_putinserver(id)
{
	g_iMenuPage[id] = 0;
}

@Command_JoinCmd(id)
{
	return PLUGIN_HANDLED;
}

@Command_ChooseTeam(id)
{
	if (is_nullent(id))
		return PLUGIN_CONTINUE;
	
	if (get_member(id, m_iJoiningState) == JOINED)
		return PLUGIN_CONTINUE;

	SubclassSelectMenu_Show(id);
	return PLUGIN_HANDLED;
}

@ShowVGUIMenu_Pre(id, VGUIMenu:menuType, bitsSlots, oldMenu[])
{
	if (mp_auto_join_team)
		return HC_CONTINUE;

	switch (menuType)
	{
		case VGUI_Menu_Team:
		{
			set_member(id, m_bForceShowMenu, true);
			SubclassSelectMenu_Show(id, g_iMenuPage[id]);
			return HC_SUPERCEDE;
		}
		case VGUI_Menu_Class_T, VGUI_Menu_Class_CT:
		{
			set_member(id, m_bForceShowMenu, true);
		}
	}

	return HC_CONTINUE;
}

@ShowVGUIMenu_Post(id, VGUIMenu:menuType, bitsSlots, oldMenu[])
{
	if (mp_auto_join_team)
		return;
	
	if (menuType == VGUI_Menu_Class_T || menuType == VGUI_Menu_Class_CT)
	{
		RequestFrame("@RequestFrame_ChooseApp", id);
	}
}

@RequestFrame_ChooseApp(id)
{
	if (!is_user_connected(id))
		return;
	
	set_member(id, m_iMenu, Menu_ChooseAppearance);
	engclient_cmd(id, "menuselect", "0");
}

@HandleMenu_ChooseTeam_Pre(id, MenuChooseTeam:slot)
{
	if (mp_auto_join_team)
		return HC_CONTINUE;

	if (is_user_bot(id))
	{
		ArrayClear(g_aMenuItems[id]);

		new subclassStart = rz_subclass_start();
		new subclassSize = rz_subclass_size();

		for (new i = subclassStart; i < subclassStart + subclassSize; i++)
		{
			if (rz_subclass_get(i, RZ_SUBCLASS_CLASS) != g_iClass_Human)
				continue;

			if (rz_subclass_player_get_status(id, i) >= RZ_BREAK)
				continue;

			ArrayPushCell(g_aMenuItems[id], i);
		}
	}
	
	new itemsNum = ArraySize(g_aMenuItems[id]);
	new key = any:slot - 1;

	if (key == 9)
	{
		new subclass = ArrayGetCell(g_aMenuItems[id], random_num(0, itemsNum - 1));

		rz_player_set(id, RZ_PLAYER_SUBCLASS_CHOSEN, subclass, g_iClass_Human);
	}
	else
	{
		if (itemsNum > 9)
		{
			switch (key)
			{
				case 7:
				{
					g_iMenuPage[id]++;
					SetHookChainReturn(ATYPE_INTEGER, false);
					return HC_SUPERCEDE;
				}
				case 8:
				{
					g_iMenuPage[id]--;
					SetHookChainReturn(ATYPE_INTEGER, false);
					return HC_SUPERCEDE;
				}
			}
		}

		new subclass = ArrayGetCell(g_aMenuItems[id], g_iMenuPage[id] * SUBCLASS_MAX_PAGE_ITEMS + key);
		
		rz_player_set(id, RZ_PLAYER_SUBCLASS_CHOSEN, subclass, g_iClass_Human);
	}

	SetHookChainArg(2, ATYPE_INTEGER, MenuChoose_CT);
	return HC_CONTINUE;
}

SubclassSelectMenu_Show(id, page = 0)
{
	ArrayClear(g_aMenuItems[id]);

	new subclassStart = rz_subclass_start();
	new subclassSize = rz_subclass_size();

	for (new i = subclassStart; i < subclassStart + subclassSize; i++)
	{
		if (rz_subclass_get(i, RZ_SUBCLASS_CLASS) != g_iClass_Human)
			continue;

		if (rz_subclass_player_get_status(id, i) >= RZ_BREAK)
			continue;

		ArrayPushCell(g_aMenuItems[id], i);
	}

	new itemsNum = ArraySize(g_aMenuItems[id]);

	if (itemsNum <= 1)
		return false;

	new bool:singlePage = bool:(itemsNum < 10);
	new itemPerPage = singlePage ? 9 : SUBCLASS_MAX_PAGE_ITEMS;
	new i = min(page * itemPerPage, itemsNum);
	new start = i - (i % itemPerPage);
	new end = min(start + itemPerPage, itemsNum);

	g_iMenuPage[id] = start / itemPerPage;

	new keys;
	new len;
	new index;
	new item;
	new text[MAX_MENU_LENGTH];
	new name[32];
	new desc[64];

	SetGlobalTransTarget(id);

	rz_class_get(g_iClass_Human, RZ_CLASS_NAME, name, charsmax(name));

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
			add_formatex("\r%d. \w%l \d%l^n", item + 1, name, desc);
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

	add_formatex("^n\r0. \w%l^n", "RZ_AUTOSELECT");
	keys |= MENU_KEY_0;

	show_menu(id, keys, text);
	set_member(id, m_iMenu, Menu_ChooseTeam);
	return true;
}
