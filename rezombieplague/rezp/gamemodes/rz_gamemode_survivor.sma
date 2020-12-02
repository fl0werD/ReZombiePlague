#pragma semicolon 1

#include <amxmodx>
#include <reapi>
#include <rezp>

new g_iGameMode_Survivor;
new g_iClass_Survivor;

public plugin_init()
{
	register_plugin("[ReZP] Game Mode: Survivor", REZP_VERSION_STR, "fl0wer");

	RZ_CHECK_CLASS_EXISTS(g_iClass_Survivor, "survivor");

	new gameMode = g_iGameMode_Survivor = rz_gamemode_create("survivor");

	rz_gamemode_set_name_langkey(gameMode, "RZ_GAMEMODE_SURVIVOR");
	rz_gamemode_set_notice_langkey(gameMode, "RZ_GAMEMODE_NOTICE_SURVIVOR");
	rz_gamemode_set_hudcolor(gameMode, { 0, 10, 255 });
	rz_gamemode_set_chance(gameMode, 20);
}

public rz_gamemode_start_post(mode, Array:alivesArray)
{
	if (mode != g_iGameMode_Survivor)
		return;

	new item = random_num(0, ArraySize(alivesArray) - 1);
	new player = ArrayGetCell(alivesArray, item);

	rz_class_player_change(player, 0, g_iClass_Survivor);
	ArrayDeleteItem(alivesArray, item);

	new class = rz_class_get_default(TEAM_TERRORIST);
	
	for (new i = 0; i < ArraySize(alivesArray); i++)
	{
		player = ArrayGetCell(alivesArray, i);

		rz_class_player_change(player, 0, class);
		ArrayDeleteItem(alivesArray, i);
	}
}

