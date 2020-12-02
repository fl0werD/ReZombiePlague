#pragma semicolon 1

#include <amxmodx>
#include <reapi>
#include <rezp>

new g_iGameMode_Swarm;
new g_iClass_Zombie;

public plugin_init()
{
	register_plugin("[ReZP] Game Mode: Swarm", REZP_VERSION_STR, "fl0wer");

	RZ_CHECK_CLASS_EXISTS(g_iClass_Zombie, "zombie");

	new gameMode = g_iGameMode_Swarm = rz_gamemode_create("swarm");

	rz_gamemode_set_name_langkey(gameMode, "RZ_GAMEMODE_SWARM");
	rz_gamemode_set_notice_langkey(gameMode, "RZ_GAMEMODE_NOTICE_SWARM");
	rz_gamemode_set_hudcolor(gameMode, { 20, 255, 20 });
	rz_gamemode_set_chance(gameMode, 20);
}

public rz_gamemode_start_post(mode, Array:alivesArray)
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

public rz_class_change_pre(id, attacker, class)
{
	if (rz_gamemode_get_current() != g_iGameMode_Swarm)
		return RZ_CONTINUE;

	if (id == attacker || !attacker)
		return RZ_CONTINUE;

	return RZ_SUPERCEDE;
}
