#pragma semicolon 1

#include <amxmodx>
#include <reapi>
#include <rezp>

new g_iGameMode_Nemesis;
new g_iClass_Nemesis;

public plugin_precache()
{
	register_plugin("[ReZP] Game Mode: Nemesis", REZP_VERSION_STR, "fl0wer");

	RZ_CHECK_CLASS_EXISTS(g_iClass_Nemesis, "class_nemesis");

	new gameMode = g_iGameMode_Nemesis = rz_gamemode_create("gamemode_nemesis");

	rz_gamemode_set(gameMode, RZ_GAMEMODE_NAME, "RZ_GAMEMODE_NEMESIS");
	rz_gamemode_set(gameMode, RZ_GAMEMODE_NOTICE, "RZ_GAMEMODE_NOTICE_NEMESIS");
	rz_gamemode_set(gameMode, RZ_GAMEMODE_HUD_COLOR, { 255, 20, 20 });
	rz_gamemode_set(gameMode, RZ_GAMEMODE_CHANCE, 20);
}

public rz_gamemodes_change_post(mode, Array:alivesArray)
{
	if (mode != g_iGameMode_Nemesis)
		return;
	
	new item = random_num(0, ArraySize(alivesArray) - 1);
	new player = ArrayGetCell(alivesArray, item);

	rz_class_player_change(player, 0, g_iClass_Nemesis);
}
