#pragma semicolon 1

#include <amxmodx>
#include <reapi>
#include <rezp>

new const EQUIP_NVG_SOUND[] = "items/equip_nvg.wav";

new g_iItem_NightVision;
new g_iClass_Human;
new g_iHumanNVG;

public plugin_precache()
{
	register_plugin("[ReZP] Item: Nightvision", REZP_VERSION_STR, "fl0wer");

	RZ_CHECK_CLASS_EXISTS(g_iClass_Human, "class_human");

	precache_sound(EQUIP_NVG_SOUND);

	new item = g_iItem_NightVision = rz_item_create("human_nvg");

	rz_item_set(item, RZ_ITEM_NAME, "RZ_ITEM_NIGHTVISION");
	rz_item_set(item, RZ_ITEM_COST, 15);

	new nightVision = g_iHumanNVG = rz_nightvision_create("item_nvg");

	rz_nightvision_set(nightVision, RZ_NIGHTVISION_EQUIP, RZ_NVG_EQUIP_APPEND_AND_ENABLE);
	rz_nightvision_set(nightVision, RZ_NIGHTVISION_ALPHA, 63);
}

public rz_items_select_pre(id, item)
{
	if (item != g_iItem_NightVision)
		return RZ_CONTINUE;

	if (rz_player_get(id, RZ_PLAYER_CLASS) != g_iClass_Human)
		return RZ_BREAK;

	if (rz_player_get(id, RZ_PLAYER_NIGHTVISION) == g_iHumanNVG)
		return RZ_SUPERCEDE;

	return RZ_CONTINUE;
}

public rz_items_select_post(id, item)
{
	if (item != g_iItem_NightVision)
		return;

	rz_player_set(id, RZ_PLAYER_HAS_NIGHTVISION, true);
	rz_nightvisions_player_change(id, g_iHumanNVG, true);
	
	rh_emit_sound2(id, 0, CHAN_ITEM, EQUIP_NVG_SOUND, VOL_NORM, ATTN_NORM);
}
