#pragma semicolon 1

#include <amxmodx>
#include <reapi>
#include <rezp>

new const EQUIP_NVG_SOUND[] = "items/equip_nvg.wav";

new g_iItem_Nightvision;
new g_iClass_Human;
new g_iHumanNVG;

public plugin_precache()
{
	register_plugin("[ReZP] Item: Nightvision", REZP_VERSION_STR, "fl0wer");

	precache_sound(EQUIP_NVG_SOUND);

	new item = g_iItem_Nightvision = rz_item_create("human_nightvision");

	rz_item_set_name_langkey(item, "RZ_ITEM_NIGHTVISION");
	rz_item_set_cost(item, 15);

	g_iHumanNVG = rz_nightvision_create(2, { 0, 0, 0 }, 63);
}

public plugin_init()
{
	g_iClass_Human = rz_class_find("human");
}

public rz_item_select_pre(id, item)
{
	if (item != g_iItem_Nightvision)
		return RZ_CONTINUE;

	if (rz_class_player_get(id) != g_iClass_Human)
		return RZ_BREAK;

	if (rz_nightvision_player_get(id) == g_iHumanNVG)
		return RZ_SUPERCEDE;

	return RZ_CONTINUE;
}

public rz_item_select_post(id, item)
{
	if (item != g_iItem_Nightvision)
		return;

	rz_nightvision_player_set(id, g_iHumanNVG);
	rz_nightvision_player_change(id);

	rh_emit_sound2(id, 0, CHAN_ITEM, EQUIP_NVG_SOUND, VOL_NORM, ATTN_NORM);
}
