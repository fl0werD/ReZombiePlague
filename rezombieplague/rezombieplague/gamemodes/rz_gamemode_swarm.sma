#pragma semicolon 1

#include <amxmodx>
#include <reapi>
#include <rezp>

new g_iGameMode_Swarm;
new g_iClass_Zombie;

public plugin_precache()
{
	register_plugin("[ReZP] Game Mode: Swarm", REZP_VERSION_STR, "fl0wer");

	RZ_CHECK_CLASS_EXISTS(g_iClass_Zombie, "class_zombie");

	new gameMode = g_iGameMode_Swarm = rz_gamemode_create("gamemode_swarm");

	rz_gamemode_set(gameMode, RZ_GAMEMODE_NAME, "RZ_GAMEMODE_SWARM");
	rz_gamemode_set(gameMode, RZ_GAMEMODE_NOTICE, "RZ_GAMEMODE_NOTICE_SWARM");
	rz_gamemode_set(gameMode, RZ_GAMEMODE_HUD_COLOR, { 20, 255, 20 });
	rz_gamemode_set(gameMode, RZ_GAMEMODE_CHANCE, 20);
}

public rz_gamemodes_change_post(mode, Array:alivesArray)
{
	if (mode != g_iGameMode_Swarm)
		return;

	new alivesNum = ArraySize(alivesArray);
	new maxZombies = alivesNum / 2;

	new item;
	new player;
	
	for (new i = 0; i < maxZombies; i++)
	{
		item = random_num(0, ArraySize(alivesArray) - 1);
		player = ArrayGetCell(alivesArray, item);

		rz_class_player_change(player, 0, g_iClass_Zombie);

		ArrayDeleteItem(alivesArray, item);
	}
}
