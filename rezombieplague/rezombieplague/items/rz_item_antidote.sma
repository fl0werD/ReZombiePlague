#pragma semicolon 1

#include <amxmodx>
#include <reapi>
#include <rezp>

new g_iItem_Antidote;

new g_iClass_Zombie;
new g_iClass_Human;
new g_iGameMode_Multi;

public plugin_precache()
{
	register_plugin("[ReZP] Item: Antidote", REZP_VERSION_STR, "fl0wer");

	new item = g_iItem_Antidote = rz_item_create("human_antidote");

	rz_item_set(item, RZ_ITEM_NAME, "RZ_ITEM_ANTIDOTE");
	rz_item_set(item, RZ_ITEM_COST, 15);
}

public plugin_init()
{
	RZ_CHECK_CLASS_EXISTS(g_iClass_Zombie, "class_zombie");
	RZ_CHECK_CLASS_EXISTS(g_iClass_Human, "class_human");

	g_iGameMode_Multi = rz_gamemodes_find("gamemode_multi");
}

public rz_items_select_pre(id, item)
{
	if (item != g_iItem_Antidote)
		return RZ_CONTINUE;

	if (rz_gamemodes_get(RZ_GAMEMODES_CURRENT) != g_iGameMode_Multi)
		return RZ_BREAK;

	if (rz_player_get(id, RZ_PLAYER_CLASS) != g_iClass_Zombie)
		return RZ_BREAK;
	
	new numAliveTR;
	rg_initialize_player_counts(numAliveTR);

	if (numAliveTR <= 1)
		return RZ_SUPERCEDE;
	
	return RZ_CONTINUE;
}

public rz_items_select_post(id, item)
{
	if (item != g_iItem_Antidote)
		return;

	rz_class_player_change(id, id, g_iClass_Human);
}
