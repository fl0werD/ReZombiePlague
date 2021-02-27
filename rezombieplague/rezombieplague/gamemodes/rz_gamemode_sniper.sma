#pragma semicolon 1

#include <amxmodx>
#include <reapi>
#include <rezp>

new g_iGameMode_Sniper;
new g_iClass_Sniper;

public plugin_precache()
{
	register_plugin("[ReZP] Game Mode: Sniper", REZP_VERSION_STR, "fl0wer");

	RZ_CHECK_CLASS_EXISTS(g_iClass_Sniper, "class_sniper");

	new gameMode = g_iGameMode_Sniper = rz_gamemode_create("gamemode_sniper");

	rz_gamemode_set(gameMode, RZ_GAMEMODE_NAME, "RZ_GAMEMODE_SNIPER");
	rz_gamemode_set(gameMode, RZ_GAMEMODE_NOTICE, "RZ_GAMEMODE_NOTICE_SNIPER");
	rz_gamemode_set(gameMode, RZ_GAMEMODE_HUD_COLOR, { 0, 250, 250 });
	rz_gamemode_set(gameMode, RZ_GAMEMODE_CHANCE, 20);
}

public rz_gamemodes_change_post(mode, Array:alivesArray)
{
	if (mode != g_iGameMode_Sniper)
		return;

	new item = random_num(0, ArraySize(alivesArray) - 1);
	new player = ArrayGetCell(alivesArray, item);

	rz_class_player_change(player, 0, g_iClass_Sniper);
	ArrayDeleteItem(alivesArray, item);

	new class = rz_class_get_default(TEAM_TERRORIST);
	
	for (new i = 0; i < ArraySize(alivesArray); i++)
	{
		player = ArrayGetCell(alivesArray, i);

		rz_class_player_change(player, 0, class);
		ArrayDeleteItem(alivesArray, i);
	}
}
