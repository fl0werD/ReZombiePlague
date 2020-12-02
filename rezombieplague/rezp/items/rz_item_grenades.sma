#pragma semicolon 1

#include <amxmodx>
#include <reapi>
#include <rezp>

new g_iItem_Infection;
new g_iItem_Fire;
new g_iItem_Frost;
new g_iItem_Flare;

new g_iWeapon_InfectionBomb;
new g_iWeapon_FireGrenade;
new g_iWeapon_FrostGrenade;
new g_iWeapon_FlareGrenade;

new g_iClass_Zombie;
new g_iClass_Human;

public plugin_precache()
{
	register_plugin("[ReZP] Item: Grenades", REZP_VERSION_STR, "fl0wer");

	g_iWeapon_InfectionBomb = rz_weapon_find("weapon_infectionbomb");

	if (g_iWeapon_InfectionBomb)
	{
		new item = g_iItem_Infection = rz_item_create("zombie_infectionbomb");

		rz_item_set_name_langkey(item, "RZ_ITEM_NADE_INFECTION");
		rz_item_set_cost(item, 20);
	}

	g_iWeapon_FireGrenade = rz_weapon_find("weapon_firegrenade");

	if (g_iWeapon_FireGrenade)
	{
		new item = g_iItem_Fire = rz_item_create("human_firegrenade");

		rz_item_set_name_langkey(item, "RZ_ITEM_NADE_FIRE");
		rz_item_set_cost(item, 6);
	}

	g_iWeapon_FrostGrenade = rz_weapon_find("weapon_frostgrenade");

	if (g_iWeapon_FrostGrenade)
	{
		new item = g_iItem_Frost = rz_item_create("human_frostgrenade");

		rz_item_set_name_langkey(item, "RZ_ITEM_NADE_FROST");
		rz_item_set_cost(item, 6);
	}

	g_iWeapon_FlareGrenade = rz_weapon_find("weapon_flaregrenade");

	if (g_iWeapon_FlareGrenade)
	{
		new item = g_iItem_Flare = rz_item_create("human_flaregrenade");

		rz_item_set_name_langkey(item, "RZ_ITEM_NADE_FLARE");
		rz_item_set_cost(item, 6);
	}
}

public plugin_init()
{
	g_iClass_Zombie = rz_class_find("zombie");
	g_iClass_Human = rz_class_find("human");
}

public rz_item_select_pre(id, item)
{
	if (item == g_iItem_Infection)
	{
		if (rz_class_player_get(id) != g_iClass_Zombie)
			return RZ_BREAK;
	}
	else if (item == g_iItem_Fire || item == g_iItem_Frost || item == g_iItem_Flare)
	{
		if (rz_class_player_get(id) != g_iClass_Human)
			return RZ_BREAK;
	}

	return RZ_CONTINUE;
}

public rz_item_select_post(id, item)
{
	if (item == g_iItem_Infection)
	{
		rz_weapon_player_give(id, g_iWeapon_InfectionBomb, GT_APPEND);
	}
	else if (item == g_iItem_Fire)
	{
		rz_weapon_player_give(id, g_iWeapon_FireGrenade, GT_APPEND);
	}
	else if (item == g_iItem_Frost)
	{
		rz_weapon_player_give(id, g_iWeapon_FrostGrenade, GT_APPEND);
	}
	else if (item == g_iItem_Flare)
	{
		rz_weapon_player_give(id, g_iWeapon_FlareGrenade, GT_APPEND);
	}
}
