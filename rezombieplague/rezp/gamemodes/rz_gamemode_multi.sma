#pragma semicolon 1

#include <amxmodx>
#include <reapi>
#include <rezp>

new g_iGameMode_Multi;
new g_iClass_Zombie;

public plugin_init()
{
	register_plugin("[ReZP] Game Mode: Multiple Infection", REZP_VERSION_STR, "fl0wer");

	RZ_CHECK_CLASS_EXISTS(g_iClass_Zombie, "zombie");

	new gameMode = g_iGameMode_Multi = rz_gamemode_create("multi");

	rz_gamemode_set_name_langkey(gameMode, "RZ_GAMEMODE_MULTI");
	rz_gamemode_set_notice_langkey(gameMode, "RZ_GAMEMODE_NOTICE_MULTI");
	rz_gamemode_set_hudcolor(gameMode, { 200, 50, 0 });
}

public rz_gamemode_start_post(mode, Array:alivesArray)
{
	if (mode != g_iGameMode_Multi)
		return;

	new alivesNum = ArraySize(alivesArray);
	new maxZombies;

	if (alivesNum > 30)
		maxZombies = 4;
	else if (alivesNum > 20)
		maxZombies = 3;
	else if (alivesNum > 10)
		maxZombies = 2;
	else
		maxZombies = 1;

	new item;
	new player;

	maxZombies = min(maxZombies, alivesNum);
	
	for (new i = 0; i < maxZombies; i++)
	{
		item = random_num(0, ArraySize(alivesArray) - 1);
		player = ArrayGetCell(alivesArray, item);

		rz_class_player_change(player, 0, g_iClass_Zombie);

		ArrayDeleteItem(alivesArray, item);
	}
}
