#pragma semicolon 1

#include <amxmodx>
#include <reapi>
#include <rezp>

new g_iGameMode_Assassin;
new g_iClass_Assassin;

public plugin_precache()
{
	register_plugin("[ReZP] Game Mode: Assassin", REZP_VERSION_STR, "fl0wer");

	RZ_CHECK_CLASS_EXISTS(g_iClass_Assassin, "class_assassin");

	new gameMode = g_iGameMode_Assassin = rz_gamemode_create("gamemode_assassin");

	rz_gamemode_set(gameMode, RZ_GAMEMODE_NAME, "RZ_GAMEMODE_ASSASSIN");
	rz_gamemode_set(gameMode, RZ_GAMEMODE_NOTICE, "RZ_GAMEMODE_NOTICE_ASSASSIN");
	rz_gamemode_set(gameMode, RZ_GAMEMODE_HUD_COLOR, { 255, 150, 20 });
	rz_gamemode_set(gameMode, RZ_GAMEMODE_CHANCE, 20);
}

public rz_gamemodes_change_post(mode, Array:alivesArray)
{
	if (mode != g_iGameMode_Assassin)
		return;

	rz_main_lighting_global_set("a");
	
	new item = random_num(0, ArraySize(alivesArray) - 1);
	new player = ArrayGetCell(alivesArray, item);

	rz_class_player_change(player, 0, g_iClass_Assassin);
	rz_class_override_default(TEAM_TERRORIST, g_iClass_Assassin);
}
