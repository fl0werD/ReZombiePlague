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

	RZ_CHECK_CLASS_EXISTS(g_iClass_Human, "class_human");

	precache_sound(ARMOR_PICKUP_SOUND);

	new item = g_iItem_Armor = rz_item_create("human_armor");

	rz_item_set(item, RZ_ITEM_NAME, "RZ_ITEM_ARMOR");
	rz_item_set(item, RZ_ITEM_COST, 7);
	rz_item_command_add(item, "say /armor");
}

public rz_items_select_pre(id, item)
{
	if (item != g_iItem_Armor)
		return RZ_CONTINUE;

	if (rz_player_get(id, RZ_PLAYER_CLASS) != g_iClass_Human)
		return RZ_BREAK;

	new ArmorType:armorType;

	if (rg_get_user_armor(id, armorType) >= GIVE_ARMOR && armorType == ARMOR_VESTHELM)
		return RZ_SUPERCEDE;

	return RZ_CONTINUE;
}

public rz_items_select_post(id, item)
{
	if (item != g_iItem_Armor)
		return;

	rg_set_user_armor(id, max(rg_get_user_armor(id), GIVE_ARMOR), ARMOR_VESTHELM);
	rh_emit_sound2(id, 0, CHAN_ITEM, ARMOR_PICKUP_SOUND, VOL_NORM, ATTN_NORM);
}
