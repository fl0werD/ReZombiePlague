#pragma semicolon 1

#include <amxmodx>
#include <reapi>
#include <rezp>

const GIVE_ARMOR = 100;

new const ARMOR_PICKUP_SOUND[] = "items/ammopickup2.wav";

new g_iItem_Armor;
new g_iClass_Human;

public plugin_precache()
{
	register_plugin("[ReZP] Item: Armor", REZP_VERSION_STR, "fl0wer");

	precache_sound(ARMOR_PICKUP_SOUND);

	new item = g_iItem_Armor = rz_item_create("human_armor");

	rz_item_set_name_langkey(item, "RZ_ITEM_ARMOR");
	rz_item_set_cost(item, 7);
}

public plugin_init()
{
	g_iClass_Human = rz_class_find("human");
}

public rz_item_select_pre(id, item)
{
	if (item != g_iItem_Armor)
		return RZ_CONTINUE;

	if (rz_class_player_get(id) != g_iClass_Human)
		return RZ_BREAK;

	if (rg_get_user_armor(id) >= GIVE_ARMOR)
		return RZ_SUPERCEDE;

	return RZ_CONTINUE;
}

public rz_item_select_post(id, item)
{
	if (item != g_iItem_Armor)
		return;

	new ArmorType:armorType;
	rg_get_user_armor(id, armorType);

	if (armorType < ARMOR_KEVLAR)
		armorType = ARMOR_KEVLAR;

	rg_set_user_armor(id, GIVE_ARMOR, armorType);
	rh_emit_sound2(id, 0, CHAN_ITEM, ARMOR_PICKUP_SOUND, VOL_NORM, ATTN_NORM);
}
