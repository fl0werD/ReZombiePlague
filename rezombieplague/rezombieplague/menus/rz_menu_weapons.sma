#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <reapi>
#include <rezp>

const SECTION_MAX_PAGE_ITEMS = 7;

enum _:SelectWeaponsData
{
	SelectWeapon_Section,
	SelectWeapon_Reference[RZ_MAX_REFERENCE_LENGTH],
	SelectWeapon_Name[RZ_MAX_LANGKEY_LENGTH],
	SelectWeapon_ShortName[RZ_MAX_LANGKEY_LENGTH],
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
	SECTION_KNIFE,
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
	"RZ_MENU_WPN_SEC_KNIFE",
};

new const MAIN_MENU_ID[] = "RZ_WeaponsMain";
new const SECTION_MENU_ID[] = "RZ_WeaponsSection";

enum
{
	SLOT_PRIMARY,
	SLOT_SECONDARY,
	SLOT_KNIFE,
	SLOT_GRENADE1,
	SLOT_GRENADE2,
	SLOT_GRENADE3,
	MAX_SLOT_WEAPONS,
};

new g_iDefaultWeapons[MAX_SLOT_WEAPONS] = { -1, ... };

new bool:g_bWeaponsGiven[MAX_PLAYERS + 1];
new g_iSlotWeapon[MAX_PLAYERS + 1][MAX_SLOT_WEAPONS];

new g_iMenuSection[MAX_PLAYERS + 1];
new g_iMenuPage[MAX_PLAYERS + 1];
new g_iMenuTimer[MAX_PLAYERS + 1];
new Array:g_aMenuItems[MAX_PLAYERS + 1];

new g_iMenu_Main;
new g_iMenu_Section;

new g_iClass_Human;

public plugin_precache()
{
	register_plugin("[ReZP] Menu: Weapons", REZP_VERSION_STR, "fl0wer");

	RZ_CHECK_CLASS_EXISTS(g_iClass_Human, "class_human");

	for (new i = 1; i <= MaxClients; i++)
		g_aMenuItems[i] = ArrayCreate(1, 0);
}

public plugin_init()
{
	new const cmds[][] = { "guns", "say /guns" };

	for (new i = 0; i < sizeof(cmds); i++)
		register_clcmd(cmds[i], "@Command_Guns");

	g_iMenu_Main = register_menuid(MAIN_MENU_ID);
	g_iMenu_Section = register_menuid(SECTION_MENU_ID);

	register_menucmd(g_iMenu_Main, 1023, "@HandleMenu_Main");
	register_menucmd(g_iMenu_Section, 1023, "@HandleMenu_Section");

	RegisterHookChain(RG_CBasePlayer_Spawn, "@CBasePlayer_Spawn_Post", true);

	g_aSelectWeapons = ArrayCreate(SelectWeaponsData);
	
	AddWeapons();
}

public client_putinserver(id)
{
	g_iSlotWeapon[id] = g_iDefaultWeapons;
}

public rz_class_change_post(id, attacker, class, bool:preSpawn)
{
	if (class != g_iClass_Human)
		return;

	if (preSpawn)
		return;

	g_bWeaponsGiven[id] = false;
	g_iMenuTimer[id] = get_member_game(m_bFreezePeriod) ? 90 : 30;

	MainMenu_Show(id);
}

@Command_Guns(id)
{
	if (is_nullent(id))
		return PLUGIN_CONTINUE;
	
	if (!is_user_alive(id))
		return PLUGIN_HANDLED;

	if (rz_player_get(id, RZ_PLAYER_CLASS) != g_iClass_Human)
		return PLUGIN_HANDLED;

	MainMenu_Show(id);
	return PLUGIN_HANDLED;
}

@CBasePlayer_Spawn_Post(id)
{
	if (!is_user_alive(id))
		return;

	g_bWeaponsGiven[id] = false;
	g_iMenuTimer[id] = get_member_game(m_bFreezePeriod) ? 90 : 30;

	MainMenu_Show(id);
}

MainMenu_Show(id)
{
	if (g_bWeaponsGiven[id])
		return;

	new bool:isWarmup = rz_game_is_warmup();

	if (!isWarmup && !task_exists(id))
		set_task(1.0, "@Task_ShowMenu", id, .flags = "b");

	new keys;
	new len;
	new text[MAX_MENU_LENGTH];

	SetGlobalTransTarget(id);

	add_formatex("\y%l", "RZ_MENU_WPN_TITLE");

	if (!isWarmup)
		add_formatex("^n\w%l: %d", "RZ_MENU_WPN_TIMER", g_iMenuTimer[id]);

	add_formatex("^n^n");

	new bool:empty = true;
	new weaponPack[] = { SLOT_PRIMARY, SLOT_SECONDARY };
	new equipPack[] = { SLOT_KNIFE, SLOT_GRENADE1, SLOT_GRENADE2, SLOT_GRENADE3 };
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

		if (g_iSlotWeapon[id][select] == g_iDefaultWeapons[SLOT_KNIFE])
			continue;
		
		if (g_iSlotWeapon[id][select] == -1)
			continue;

		ArrayGetArray(g_aSelectWeapons, g_iSlotWeapon[id][select], data);

		if (selectedNum == 0)
		{
			if (data[SelectWeapon_ShortName][0])
				add_formatex("\w%l: \y%l", field, data[SelectWeapon_ShortName]);
			else
				add_formatex("\w%l: \y%l", field, data[SelectWeapon_Name]);
		}
		else
		{
			if (data[SelectWeapon_ShortName][0])
				add_formatex(" \w+ \y%l", data[SelectWeapon_ShortName]);
			else
				add_formatex(" \w+ \y%l", data[SelectWeapon_Name]);
		}

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

			if (rz_player_get(id, RZ_PLAYER_CLASS) != g_iClass_Human)
				return PLUGIN_HANDLED;

			g_bWeaponsGiven[id] = true;

			remove_task(id);
			rg_remove_all_items(id);

			new item;
			new data[SelectWeaponsData];

			for (new i = 0; i < sizeof(g_iSlotWeapon[]); i++)
			{
				if (g_iSlotWeapon[id][i] == -1)
					continue;

				ArrayGetArray(g_aSelectWeapons, g_iSlotWeapon[id][i], data);

				switch (i)
				{
					case SLOT_PRIMARY, SLOT_SECONDARY:
					{
						if (data[SelectWeapon_IsCustom])
						{
							item = rg_give_custom_item(id, data[SelectWeapon_Reference], GT_APPEND, data[SelectWeapon_CustomId]);

							if (!is_nullent(item))
							{
								new maxAmmo1 = rg_get_iteminfo(item, ItemInfo_iMaxAmmo1);

								if (maxAmmo1 != -1)
								{
									new ammoType = get_member(item, m_Weapon_iPrimaryAmmoType);

									if (ammoType != -1)
										set_member(id, m_rgAmmo, maxAmmo1, ammoType);
								}

								new maxAmmo2 = rg_get_iteminfo(item, ItemInfo_iMaxAmmo2);

								if (maxAmmo2 != -1)
								{
									new ammoType = get_member(item, m_Weapon_iSecondaryAmmoType);

									if (ammoType != -1)
										set_member(id, m_rgAmmo, maxAmmo2, ammoType);
								}
							}
						}
						else
						{
							item = rg_give_item(id, data[SelectWeapon_Reference], GT_APPEND);

							if (!is_nullent(item))
							{
								if (rg_get_iteminfo(item, ItemInfo_iMaxClip) != -1)
								{
									new WeaponIdType:weaponId = get_member(item, m_iId);

									set_member(id, m_rgAmmo, rg_get_weapon_info(weaponId, WI_MAX_ROUNDS), rg_get_weapon_info(weaponId, WI_AMMO_TYPE));
								}
							}
						}
					}
					case SLOT_KNIFE, SLOT_GRENADE1, SLOT_GRENADE2, SLOT_GRENADE3:
					{
						if (data[SelectWeapon_IsCustom])
							rg_give_custom_item(id, data[SelectWeapon_Reference], GT_APPEND, data[SelectWeapon_CustomId]);
						else
							rg_give_item(id, data[SelectWeapon_Reference], GT_APPEND);
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
	new grenadeNum;
	new text[MAX_MENU_LENGTH];

	SetGlobalTransTarget(id);

	if (singlePage)
		add_formatex("\y%l %l", "RZ_MENU_WPN_SEC_TITLE", SECTION_NAMES[section]);
	else
		add_formatex("\y%l %l \r%d/%d", "RZ_MENU_WPN_SEC_TITLE", SECTION_NAMES[section], g_iMenuPage[id] + 1, ((itemNum - 1) / itemPerPage) + 1);

	if (!rz_game_is_warmup())
		add_formatex("^n\w%l: %d", "RZ_MENU_WPN_TIMER", g_iMenuTimer[id]);

	add_formatex("^n^n");

	for (i = start; i < end; i++)
	{
		index = ArrayGetCell(g_aMenuItems[id], i);
		ArrayGetArray(g_aSelectWeapons, index, data);

		select = MapSectionToSelect(section, index);

		switch (select)
		{
			case SLOT_KNIFE:
			{
				if (g_iSlotWeapon[id][select] != index)
				{
					add_formatex("\r%d. \w%l^n", item + 1, data[SelectWeapon_Name]);
					keys |= (1<<item);
				}
				else
					add_formatex("\r%d. \d%l \y*^n", item + 1, data[SelectWeapon_Name]);
			}
			case SLOT_GRENADE1, SLOT_GRENADE2, SLOT_GRENADE3:
			{
				if (g_iSlotWeapon[id][select] != index)
					add_formatex("\r%d. \w%l^n", item + 1, data[SelectWeapon_Name]);
				else
				{
					if (select == SLOT_GRENADE1)
						grenadeNum = 1;
					else if (select == SLOT_GRENADE2)
						grenadeNum = 2;
					else if (select == SLOT_GRENADE3)
						grenadeNum = 3;

					add_formatex("\r%d. \w%l \y(%d)^n", item + 1, data[SelectWeapon_Name], grenadeNum);
				}

				keys |= (1<<item);
			}
			default:
			{
				if (g_iSlotWeapon[id][select] != index)
					add_formatex("\r%d. \w%l^n", item + 1, data[SelectWeapon_Name]);
				else
					add_formatex("\r%d. \w%l \y*^n", item + 1, data[SelectWeapon_Name]);

				keys |= (1<<item);
			}
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

	if (itemNum > 8)
	{
		if (key == 7)
		{
			SectionMenu_Show(id, section, ++g_iMenuPage[id]);
			return PLUGIN_HANDLED;
		}
	}

	if (key == 8)
	{
		SectionMenu_Show(id, section, --g_iMenuPage[id]);
		return PLUGIN_HANDLED;
	}

	new item = ArrayGetCell(g_aMenuItems[id], g_iMenuPage[id] * SECTION_MAX_PAGE_ITEMS + key);
	new select = MapSectionToSelect(g_iMenuSection[id], item);

	if (select == -1)
		return PLUGIN_HANDLED;

	if (select == SLOT_KNIFE)
		g_iSlotWeapon[id][select] = item;
	else
		g_iSlotWeapon[id][select] = (g_iSlotWeapon[id][select] == item) ? -1 : item;

	if (section == SECTION_EQUIPMENT)
		SectionMenu_Show(id, section, g_iMenuPage[id]);
	else
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

	if (!rz_game_is_warmup())
	{
		g_iMenuTimer[player]--;
	}

	new menu, keys;
	get_user_menu(player, menu, keys);

	if (!is_user_alive(player) || rz_player_get(player, RZ_PLAYER_CLASS) != g_iClass_Human ||
		g_bWeaponsGiven[player] || g_iMenuTimer[player] <= 0)
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

MapSectionToSelect(section, item)
{
	new select;

	switch (section)
	{
		case SECTION_PISTOL: return SLOT_SECONDARY;
		case SECTION_SHOTGUN: return SLOT_PRIMARY;
		case SECTION_SMG: return SLOT_PRIMARY;
		case SECTION_RIFLE: return SLOT_PRIMARY;
		case SECTION_MACHINEGUN: return SLOT_PRIMARY;
		case SECTION_EQUIPMENT:
		{
			new data[SelectWeaponsData];
			ArrayGetArray(g_aSelectWeapons, item, data);

			if (equal(data[SelectWeapon_Reference][7], "hegrenade"))
				select = SLOT_GRENADE1;
			else if (equal(data[SelectWeapon_Reference][7], "flashbang"))
				select = SLOT_GRENADE2;
			else if (equal(data[SelectWeapon_Reference][7], "smokegrenade"))
				select = SLOT_GRENADE3;
		}
		case SECTION_KNIFE: return SLOT_KNIFE;
	}

	return select;
}

AddWeapons()
{
	AddWeapon(SECTION_PISTOL, "weapon_glock18");
	AddWeapon(SECTION_PISTOL, "weapon_usp");
	AddWeapon(SECTION_PISTOL, "weapon_p228");
	g_iDefaultWeapons[SLOT_SECONDARY] = AddWeapon(SECTION_PISTOL, "weapon_deagle");
	AddWeapon(SECTION_PISTOL, "weapon_elite");
	AddWeapon(SECTION_PISTOL, "weapon_fiveseven");

	AddWeapon(SECTION_SHOTGUN, "weapon_m3");
	AddWeapon(SECTION_SHOTGUN, "weapon_xm1014");

	AddWeapon(SECTION_SMG, "weapon_mac10");
	AddWeapon(SECTION_SMG, "weapon_tmp");
	AddWeapon(SECTION_SMG, "weapon_mp5navy");
	AddWeapon(SECTION_SMG, "weapon_ump45");
	AddWeapon(SECTION_SMG, "weapon_p90");

	AddWeapon(SECTION_RIFLE, "weapon_galil");
	AddWeapon(SECTION_RIFLE, "weapon_famas");
	AddWeapon(SECTION_RIFLE, "weapon_ak47");
	g_iDefaultWeapons[SLOT_PRIMARY] = AddWeapon(SECTION_RIFLE, "weapon_m4a1");
	AddWeapon(SECTION_RIFLE, "weapon_sg552");
	AddWeapon(SECTION_RIFLE, "weapon_aug");
	AddWeapon(SECTION_RIFLE, "weapon_scout");
	//AddWeapon(SECTION_RIFLE, "weapon_sniperawp");

	//AddWeapon(SECTION_MACHINEGUN, "weapon_m249", "M249");

	AddWeapon(SECTION_EQUIPMENT, "weapon_hegrenade");
	g_iDefaultWeapons[SLOT_GRENADE1] = AddWeapon(SECTION_EQUIPMENT, "grenade_fire");
	g_iDefaultWeapons[SLOT_GRENADE2] = AddWeapon(SECTION_EQUIPMENT, "grenade_frost");
	g_iDefaultWeapons[SLOT_GRENADE3] = AddWeapon(SECTION_EQUIPMENT, "grenade_flare");

	g_iDefaultWeapons[SLOT_KNIFE] = AddWeapon(SECTION_KNIFE, "weapon_knife");
}

AddWeapon(section, const handle[])
{
	new WeaponIdType:weaponId = any:rz_weapons_default_find(handle);
	new bool:found;
	new data[SelectWeaponsData];

	if (weaponId)
	{
		copy(data[SelectWeapon_Reference], charsmax(data[SelectWeapon_Reference]), handle);
		rz_weapon_default_get(weaponId, RZ_DEFAULT_WEAPON_NAME, data[SelectWeapon_Name], charsmax(data[SelectWeapon_Name]));
		rz_weapon_default_get(weaponId, RZ_DEFAULT_WEAPON_SHORT_NAME, data[SelectWeapon_ShortName], charsmax(data[SelectWeapon_ShortName]));

		found = true;
	}

	if (!found)
	{
		new weapon;

		switch (section)
		{
			case SECTION_EQUIPMENT:
			{
				weapon = rz_grenades_find(handle);

				if (weapon)
				{
					rz_grenade_get(weapon, RZ_GRENADE_REFERENCE, data[SelectWeapon_Reference], charsmax(data[SelectWeapon_Reference]));
					rz_grenade_get(weapon, RZ_GRENADE_NAME, data[SelectWeapon_Name], charsmax(data[SelectWeapon_Name]));
					rz_grenade_get(weapon, RZ_GRENADE_SHORT_NAME, data[SelectWeapon_ShortName], charsmax(data[SelectWeapon_ShortName]));

					found = true;
				}
			}
			case SECTION_KNIFE:
			{
				weapon = rz_knifes_find(handle);

				if (weapon)
				{
					copy(data[SelectWeapon_Reference], charsmax(data[SelectWeapon_Reference]), "weapon_knife");
					rz_knife_get(weapon, RZ_KNIFE_NAME, data[SelectWeapon_Name], charsmax(data[SelectWeapon_Name]));
					rz_knife_get(weapon, RZ_KNIFE_SHORT_NAME, data[SelectWeapon_ShortName], charsmax(data[SelectWeapon_ShortName]));

					found = true;
				}
			}
			default:
			{
				weapon = rz_weapons_find(handle);

				if (weapon)
				{
					rz_weapon_get(weapon, RZ_WEAPON_REFERENCE, data[SelectWeapon_Reference], charsmax(data[SelectWeapon_Reference]));
					rz_weapon_get(weapon, RZ_WEAPON_NAME, data[SelectWeapon_Name], charsmax(data[SelectWeapon_Name]));
					rz_weapon_get(weapon, RZ_WEAPON_SHORT_NAME, data[SelectWeapon_ShortName], charsmax(data[SelectWeapon_ShortName]));

					found = true;
				}
			}
		}

		data[SelectWeapon_IsCustom] = true;
		data[SelectWeapon_CustomId] = weapon;
	}

	if (!found)
	{
		log_amx("Weapon, knife or grenade '%s' not found", handle);
		return -1;
	}

	data[SelectWeapon_Section] = section;
	g_bSectionAvailable[section] = true;

	return ArrayPushArray(g_aSelectWeapons, data);
}
