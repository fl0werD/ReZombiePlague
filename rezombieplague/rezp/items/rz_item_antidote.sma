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

	rz_item_set_name_langkey(item, "RZ_ITEM_ANTIDOTE");
	rz_item_set_cost(item, 15);
}

public plugin_init()
{
	g_iClass_Zombie = rz_class_find("zombie");
	g_iClass_Human = rz_class_find("human");
	g_iGameMode_Multi = rz_gamemode_find("multi");
}

public rz_item_select_pre(id, item)
{
	if (item != g_iItem_Antidote)
		return RZ_CONTINUE;

	if (rz_gamemode_get_current() != g_iGameMode_Multi)
		return RZ_BREAK;

	if (rz_class_player_get(id) != g_iClass_Zombie)
		return RZ_BREAK;
	
	new numAliveTR;
	rg_initialize_player_counts(numAliveTR);

	if (numAliveTR <= 1)
		return RZ_SUPERCEDE;
	
	return RZ_CONTINUE;
}

public rz_item_select_post(id, item)
{
	if (item != g_iItem_Antidote)
		return;

	rz_class_player_change(id, id, g_iClass_Human);
}
