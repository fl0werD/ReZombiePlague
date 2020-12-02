#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <reapi>
#include <rezp>
#include <rezp_util>

const SECTION_MAX_PAGE_ITEMS = 7;

enum _:SelectWeaponsData
{
	SelectWeapon_Section,
	SelectWeapon_Reference[32],
	SelectWeapon_Name[32],
	bool:SelectWeapon_IsCustom,
	SelectWeapon_CustomId,

}; new Array:g_aSelectWeapons;

enum
{
	SECTION_PISTOL,
	SECTION_SHOTGUN,
	SECTION_SMG,
	SECTION_RIFLE,
	SECTION_MACHINEGUN,
	SECTION_EQUIPMENT,
	SECTION_MELEE,
	MAX_SECTIONS,

}; new bool:g_bSectionAvailable[MAX_SECTIONS];

new const SECTION_NAMES[MAX_SECTIONS][] =
{
	"RZ_MENU_WPN_SEC_PISTOL",
	"RZ_MENU_WPN_SEC_SHOTGUN",
	"RZ_MENU_WPN_SEC_SMG",
	"RZ_MENU_WPN_SEC_RIFLE",
	"RZ_MENU_WPN_SEC_MACHINEGUN",
	"RZ_MENU_WPN_SEC_EQUIP",
	"RZ_MENU_WPN_SEC_MELEE",
};

enum
{
	SELECT_PRIMARY,
	SELECT_SECONDARY,
	SELECT_MELEE,
	SELECT_GRENADE1,
	SELECT_GRENADE2,
	SELECT_GRENADE3,
	MAX_SELECT_WEAPONS,

}; new g_iSelectWeapon[MAX_PLAYERS + 1][MAX_SELECT_WEAPONS];

new g_bWeaponsGiven[MAX_PLAYERS + 1];

new g_iDefaultWeapons[MAX_SELECT_WEAPONS] = { -1, ... };

new g_iClass_Human;

new g_iMenuSection[MAX_PLAYERS + 1];
new g_iMenuPage[MAX_PLAYERS + 1];
new Float:g_flMenuTimer[MAX_PLAYERS + 1];
new Array:g_aMenuItems[MAX_PLAYERS + 1];

new Array:g_aDefaultEntities;

new g_iMenu_Main;
new g_iMenu_Section;

new const MAIN_MENU_ID[] = "RZ_WeaponsMain";
new const SECTION_MENU_ID[] = "RZ_WeaponsSection";

public plugin_precache()
{
	register_plugin("[ReZP] Menu: Weapons", REZP_VERSION_STR, "fl0wer");

	for (new i = 1; i <= MaxClients; i++)
		g_aMenuItems[i] = ArrayCreate(1, 0);
}

public plugin_init()
{
	new const cmds[][] = { "guns", "say /guns" };

	for (new i = 0; i < sizeof(cmds); i++)
		register_clcmd(cmds[i], "@Command_Weapons");

	g_iMenu_Main = register_menuid(MAIN_MENU_ID);
	g_iMenu_Section = register_menuid(SECTION_MENU_ID);

	register_menucmd(g_iMenu_Main, 1023, "@HandleMenu_Main");
	register_menucmd(g_iMenu_Section, 1023, "@HandleMenu_Section");

	g_iClass_Human = rz_class_find("human");

	g_aDefaultEntities = ArrayCreate(32, 0);
	g_aSelectWeapons = ArrayCreate(SelectWeaponsData);

	DefineDefaultWeapons();
	AddWeapons();
}

public client_putinserver(id)
{
	g_iSelectWeapon[id] = g_iDefaultWeapons;
}

public rz_class_change_post(id, attacker, class)
{
	if (class != g_iClass_Human)
		return;

	g_bWeaponsGiven[id] = false;

	if (get_member_game(m_bFreezePeriod) || rz_game_is_warmup())
		g_flMenuTimer[id] = get_gametime() + 90.0;
	else
		g_flMenuTimer[id] = get_gametime() + 30.0;

	MainMenu_Show(id);
}

@Command_Weapons(id)
{
	if (is_nullent(id))
		return PLUGIN_CONTINUE;
	
	if (!is_user_alive(id))
		return PLUGIN_HANDLED;

	if (rz_class_player_get(id) != g_iClass_Human)
		return PLUGIN_HANDLED;

	MainMenu_Show(id);
	return PLUGIN_HANDLED;
}

@Task_ShowMenu(id)
{
	new player = id;

	if (!is_user_connected(player))
	{
		remove_task(id);
		return;
	}

	new menu, keys;
	get_user_menu(player, menu, keys);

	if (!is_user_alive(player) || rz_class_player_get(id) != g_iClass_Human ||
		g_flMenuTimer[player] < get_gametime())
	{
		remove_task(id);

		if (menu == g_iMenu_Main || menu == g_iMenu_Section)
			MENU_CLOSE(player);

		return;
	}

	if (menu == g_iMenu_Main)
		MainMenu_Show(player);
	else if (menu == g_iMenu_Section)
		SectionMenu_Show(player, g_iMenuSection[player], g_iMenuPage[player]);
}

MainMenu_Show(id)
{
	if (g_bWeaponsGiven[id])
		return;

	if (!task_exists(id))
		set_task(1.0, "@Task_ShowMenu", id, .flags = "b");

	new keys;
	new len;
	new text[MAX_MENU_LENGTH];

	SetGlobalTransTarget(id);

	add_formatex("\y%l^n", "RZ_MENU_WPN_TITLE");
	add_formatex("\w%l: %d^n^n", "RZ_MENU_WPN_TIMER", floatround(g_flMenuTimer[id] - get_gametime()));

	new bool:empty = true;
	new weaponPack[] = { SELECT_PRIMARY, SELECT_SECONDARY };
	new equipPack[] = { SELECT_MELEE, SELECT_GRENADE1, SELECT_GRENADE2, SELECT_GRENADE3 };
	new weaponText[128];
	new equipText[128];

	if (FillField(id, "RZ_MENU_WPN_FIELD_WPN", weaponText, weaponPack, sizeof(weaponPack)))
	{
		empty = false;
		add_formatex("%s^n", weaponText);
	}

	if (FillField(id, "RZ_MENU_WPN_FIELD_EQUIP", equipText, equipPack, sizeof(equipPack)))
	{
		empty = false;
		add_formatex("%s^n", equipText);
	}

	if (!empty)
		add_formatex("^n");

	for (new i = 0; i < sizeof(SECTION_NAMES); i++)
	{
		if (g_bSectionAvailable[i])
		{
			add_formatex("\r%d. \w%l^n", i + 1, SECTION_NAMES[i]);
			keys |= (1<<i);
		}
		else
			add_formatex("\d%d. %l^n", i + 1, SECTION_NAMES[i]);

		if (i == SECTION_MACHINEGUN)
			add_formatex("^n");
	}

	add_formatex("^n");

	if (!empty)
	{
		add_formatex("\r9. \w%l^n", "RZ_MENU_WPN_BUY_SELECT");
		keys |= MENU_KEY_9;
	}
	else
		add_formatex("\d9. %l^n", "RZ_MENU_WPN_BUY_SELECT");

	add_formatex("\r0. \w%l", "RZ_CLOSE");
	keys |= MENU_KEY_0;

	show_menu(id, keys, text, -1, MAIN_MENU_ID);
}

FillField(id, field[], textDest[128], selects[], selectsNum)
{
	new select;
	new selectedNum;
	new len;
	new text[128];
	new data[SelectWeaponsData];

	for (new i = 0; i < selectsNum; i++)
	{
		select = selects[i];

		if (g_iSelectWeapon[id][select] == g_iDefaultWeapons[SELECT_MELEE])
			continue;
		
		if (g_iSelectWeapon[id][select] == -1)
			continue;

		ArrayGetArray(g_aSelectWeapons, g_iSelectWeapon[id][select], data);

		if (selectedNum == 0)
			add_formatex("\w%l: \y%s", field, data[SelectWeapon_Name]);
		else
			add_formatex(" \w+ \y%s", data[SelectWeapon_Name]);

		selectedNum++;
	}

	if (selectedNum)
	{
		textDest = text;
		return true;
	}

	return false;
}

@HandleMenu_Main(id, key)
{
	if (key == 9)
	{
		remove_task(id);
		return PLUGIN_HANDLED;
	}

	switch (key)
	{
		case 8:
		{
			if (!is_user_alive(id))
				return PLUGIN_HANDLED;

			if (rz_class_player_get(id) != g_iClass_Human)
				return PLUGIN_HANDLED;

			g_bWeaponsGiven[id] = true;

			remove_task(id);
			rg_remove_all_items(id);

			new item;
			new data[SelectWeaponsData];

			for (new i = 0; i < sizeof(g_iSelectWeapon[]); i++)
			{
				if (g_iSelectWeapon[id][i] == -1)
					continue;

				ArrayGetArray(g_aSelectWeapons, g_iSelectWeapon[id][i], data);

				if (data[SelectWeapon_IsCustom])
				{
					item = rz_weapon_player_give(id, data[SelectWeapon_CustomId], GT_APPEND);

					if (item)
					{
						new WeaponIdType:weaponId = get_member(item, m_iId);

						switch (weaponId)
						{
							case WEAPON_KNIFE, WEAPON_HEGRENADE, WEAPON_FLASHBANG, WEAPON_SMOKEGRENADE: { }
							default:
							{
								new ammoType = get_member(item, m_Weapon_iPrimaryAmmoType);

								if (ammoType != -1)
									set_member(id, m_rgAmmo, rg_get_iteminfo(item, ItemInfo_iMaxAmmo1), ammoType);

								ammoType = get_member(item, m_Weapon_iSecondaryAmmoType);

								if (ammoType != -1)
									set_member(id, m_rgAmmo, rg_get_iteminfo(item, ItemInfo_iMaxAmmo2), ammoType);
							}
						}
					}
				}
				else
				{
					item = rg_give_item(id, data[SelectWeapon_Reference], GT_APPEND);

					if (!is_nullent(item))
					{
						new WeaponIdType:weaponId = get_member(item, m_iId);

						switch (weaponId)
						{
							case WEAPON_KNIFE, WEAPON_HEGRENADE, WEAPON_FLASHBANG, WEAPON_SMOKEGRENADE: { }
							default:
							{
								set_member(id, m_rgAmmo, rg_get_weapon_info(weaponId, WI_MAX_ROUNDS), rg_get_weapon_info(weaponId, WI_AMMO_TYPE));
							}
						}
					}
				}
			}
		}
		default:
		{
			SectionMenu_Show(id, key);
		}
	}
	
	return PLUGIN_HANDLED;
}

SectionMenu_Show(id, section, page = 0)
{
	if (g_bWeaponsGiven[id])
		return;
	
	if (page < 0)
	{
		MainMenu_Show(id);
		return;
	}

	ArrayClear(g_aMenuItems[id]);

	new weaponsNum = ArraySize(g_aSelectWeapons);
	new data[SelectWeaponsData];

	for (new i = 0; i < weaponsNum; i++)
	{
		ArrayGetArray(g_aSelectWeapons, i, data);

		if (data[SelectWeapon_Section] != section)
			continue;

		ArrayPushCell(g_aMenuItems[id], i);
	}

	new itemNum = ArraySize(g_aMenuItems[id]);
	new bool:singlePage = bool:(itemNum < 9);
	new itemPerPage = singlePage ? 8 : SECTION_MAX_PAGE_ITEMS;
	new i = min(page * itemPerPage, itemNum);
	new start = i - (i % itemPerPage);
	new end = min(start + itemPerPage, itemNum);

	g_iMenuSection[id] = section;
	g_iMenuPage[id] = start / itemPerPage;

	new keys;
	new len;
	new index;
	new select;
	new item;
	new text[MAX_MENU_LENGTH];

	SetGlobalTransTarget(id);

	if (singlePage)
		add_formatex("\y%l %l^n", "RZ_MENU_WPN_SEC_TITLE", SECTION_NAMES[section]);
	else
		add_formatex("\y%l %l \r%d/%d^n", "RZ_MENU_WPN_SEC_TITLE", SECTION_NAMES[section], g_iMenuPage[id] + 1, ((itemNum - 1) / itemPerPage) + 1);

	add_formatex("\w%l: %d^n^n", "RZ_MENU_WPN_TIMER", floatround(g_flMenuTimer[id] - get_gametime()));

	for (i = start; i < end; i++)
	{
		index = ArrayGetCell(g_aMenuItems[id], i);
		ArrayGetArray(g_aSelectWeapons, index, data);

		select = MapSectionToSelect(section, index);

		if (select != SELECT_MELEE)
		{
			if (g_iSelectWeapon[id][select] != index)
				add_formatex("\r%d. \w%s^n", item + 1, data[SelectWeapon_Name]);
			else
				add_formatex("\r%d. \w%s \y*^n", item + 1, data[SelectWeapon_Name]);

			keys |= (1<<item);
		}
		else
		{
			if (g_iSelectWeapon[id][select] != index)
			{
				add_formatex("\r%d. \w%s^n", item + 1, data[SelectWeapon_Name]);
				keys |= (1<<item);
			}
			else
				add_formatex("\r%d. \d%s \y*^n", item + 1, data[SelectWeapon_Name]);
		}

		item++;
	}

	if (!singlePage)
	{
		for (i = item; i < SECTION_MAX_PAGE_ITEMS; i++)
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

	show_menu(id, keys, text, -1, SECTION_MENU_ID);
}

@HandleMenu_Section(id, key)
{
	if (key == 9)
	{
		remove_task(id);
		return PLUGIN_HANDLED;
	}

	new section = g_iMenuSection[id];
	new itemNum = ArraySize(g_aMenuItems[id]);

	if (itemNum < 9)
	{
		if (key != 8)
		{
			new item = ArrayGetCell(g_aMenuItems[id], key);
			new select = MapSectionToSelect(g_iMenuSection[id], item);

			if (select == -1)
				return PLUGIN_HANDLED;

			if (select == SELECT_MELEE)
			{
				g_iSelectWeapon[id][select] = item;
			}
			else
			{
				if (g_iSelectWeapon[id][select] == item)
					g_iSelectWeapon[id][select] = -1;
				else
					g_iSelectWeapon[id][select] = item;
			}
		}

		MainMenu_Show(id);
	}
	else
	{
		switch (key)
		{
			case 7: SectionMenu_Show(id, section, ++g_iMenuPage[id]);
			case 8: SectionMenu_Show(id, section, --g_iMenuPage[id]);
			default:
			{
				new item = ArrayGetCell(g_aMenuItems[id], g_iMenuPage[id] * SECTION_MAX_PAGE_ITEMS + key);
				new select = MapSectionToSelect(g_iMenuSection[id], item);

				if (select == -1)
					return PLUGIN_HANDLED;

				if (g_iSelectWeapon[id][select] == item)
					g_iSelectWeapon[id][select] = -1;
				else
					g_iSelectWeapon[id][select] = item;

				MainMenu_Show(id);
			}
		}
	}

	return PLUGIN_HANDLED;
}

MapSectionToSelect(section, item)
{
	new select;

	switch (section)
	{
		case SECTION_PISTOL: return SELECT_SECONDARY;
		case SECTION_SHOTGUN: return SELECT_PRIMARY;
		case SECTION_SMG: return SELECT_PRIMARY;
		case SECTION_RIFLE: return SELECT_PRIMARY;
		case SECTION_MACHINEGUN: return SELECT_PRIMARY;
		case SECTION_EQUIPMENT:
		{
			new data[SelectWeaponsData];
			ArrayGetArray(g_aSelectWeapons, item, data);

			if (equal(data[SelectWeapon_Reference][7], "hegrenade"))
				select = SELECT_GRENADE1;
			else if (equal(data[SelectWeapon_Reference][7], "flashbang"))
				select = SELECT_GRENADE2;
			else if (equal(data[SelectWeapon_Reference][7], "smokegrenade"))
				select = SELECT_GRENADE3;
		}
		case SECTION_MELEE: return SELECT_MELEE;
	}

	return select;
}

AddWeapons()
{
	AddWeapon(SECTION_PISTOL, "weapon_glock18", "Glock-18");
	AddWeapon(SECTION_PISTOL, "weapon_usp", "USP");
	AddWeapon(SECTION_PISTOL, "weapon_p228", "228 Compact");
	g_iDefaultWeapons[SELECT_SECONDARY] = AddWeapon(SECTION_PISTOL, "weapon_deagle", "Desert Eagle");
	AddWeapon(SECTION_PISTOL, "weapon_elite", "Dual Berettas");
	AddWeapon(SECTION_PISTOL, "weapon_fiveseven", "Five-SeveN");

	AddWeapon(SECTION_SHOTGUN, "weapon_m3", "M3");
	AddWeapon(SECTION_SHOTGUN, "weapon_xm1014", "XM1014");

	AddWeapon(SECTION_SMG, "weapon_mac10", "MAC-10");
	AddWeapon(SECTION_SMG, "weapon_tmp", "TMP");
	AddWeapon(SECTION_SMG, "weapon_mp5navy", "MP5");
	AddWeapon(SECTION_SMG, "weapon_ump45", "UMP-45");
	AddWeapon(SECTION_SMG, "weapon_p90", "P90");

	AddWeapon(SECTION_RIFLE, "weapon_galil", "Galil");
	AddWeapon(SECTION_RIFLE, "weapon_famas", "FAMAS");
	AddWeapon(SECTION_RIFLE, "weapon_ak47", "AK-47");
	g_iDefaultWeapons[SELECT_PRIMARY] = AddWeapon(SECTION_RIFLE, "weapon_m4a1", "M4A1");
	AddWeapon(SECTION_RIFLE, "weapon_sg552", "SG 552");
	AddWeapon(SECTION_RIFLE, "weapon_aug", "AUG");
	AddWeapon(SECTION_RIFLE, "weapon_scout", "SSG 08");
	//AddWeapon(SECTION_RIFLE, "weapon_sniperawp");

	//AddWeapon(SECTION_MACHINEGUN, "weapon_m249", "M249");

	//AddWeapon(SECTION_EQUIPMENT, "weapon_hegrenade", "HE Grenade");
	AddWeapon(SECTION_EQUIPMENT, "weapon_firegrenade");
	AddWeapon(SECTION_EQUIPMENT, "weapon_frostgrenade");
	AddWeapon(SECTION_EQUIPMENT, "weapon_flaregrenade");

	g_iDefaultWeapons[SELECT_MELEE] = AddWeapon(SECTION_MELEE, "weapon_knife", "Default Knife");
}

AddWeapon(section, const reference[], const name[] = "")
{
	new data[SelectWeaponsData];

	data[SelectWeapon_Section] = section;
	copy(data[SelectWeapon_Reference], charsmax(data[SelectWeapon_Reference]), reference);
	copy(data[SelectWeapon_Name], charsmax(data[SelectWeapon_Name]), name);

	if (ArrayFindString(g_aDefaultEntities, reference) != -1)
	{
		g_bSectionAvailable[section] = true;
		return ArrayPushArray(g_aSelectWeapons, data);
	}

	new weapon = rz_weapon_find(reference);

	if (weapon)
	{
		rz_weapon_get_reference(weapon, data[SelectWeapon_Reference], charsmax(data[SelectWeapon_Reference]));

		if (!data[SelectWeapon_Name][0])
			rz_weapon_get_name(weapon, data[SelectWeapon_Name], charsmax(data[SelectWeapon_Name]));

		data[SelectWeapon_IsCustom] = true;
		data[SelectWeapon_CustomId] = weapon;
		g_bSectionAvailable[section] = true;

		return ArrayPushArray(g_aSelectWeapons, data);
	}

	log_amx("Weapon '%s' not found", reference);
	return -1;
}

DefineDefaultWeapons()
{
	new const weaponEntities[][] = { "p228", "scout", "hegrenade", "xm1014", "c4",
		"mac10", "aug", "smokegrenade", "elite", "fiveseven", "ump45", "sg550",
		"galil", "famas", "usp", "glock18", "awp", "mp5navy", "m249", "m3", "m4a1",
		"tmp", "g3sg1", "flashbang", "deagle", "sg552", "ak47", "knife", "p90" };

	for (new i = 0; i < sizeof(weaponEntities); i++)
	{
		ArrayPushString(g_aDefaultEntities, fmt("weapon_%s", weaponEntities[i]));
	}
}
