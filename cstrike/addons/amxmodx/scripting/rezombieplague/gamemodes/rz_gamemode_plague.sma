#pragma semicolon 1

#include <amxmodx>
#include <reapi>
#include <rezp>

new g_iGameMode_Plague;

new g_iClass_Zombie;
new g_iClass_Nemesis;
new g_iClass_Survivor;

public plugin_precache()
{
	register_plugin("[ReZP] Game Mode: Plague", REZP_VERSION_STR, "fl0wer");

	RZ_CHECK_CLASS_EXISTS(g_iClass_Zombie, "class_zombie");
	RZ_CHECK_CLASS_EXISTS(g_iClass_Nemesis, "class_nemesis");
	RZ_CHECK_CLASS_EXISTS(g_iClass_Survivor, "class_survivor");

	new gameMode = g_iGameMode_Plague = rz_gamemode_create("gamemode_plague");

	rz_gamemode_set(gameMode, RZ_GAMEMODE_NAME, "RZ_GAMEMODE_PLAGUE");
	rz_gamemode_set(gameMode, RZ_GAMEMODE_NOTICE, "RZ_GAMEMODE_NOTICE_PLAGUE");
	rz_gamemode_set(gameMode, RZ_GAMEMODE_HUD_COLOR, { 0, 50, 200 });
	rz_gamemode_set(gameMode, RZ_GAMEMODE_CHANCE, 20);
	rz_gamemode_set(gameMode, RZ_GAMEMODE_MIN_ALIVES, 8);
}

public rz_gamemodes_change_post(mode, Array:alivesArray)
{
	if (mode != g_iGameMode_Plague)
		return;

	new alivesNum = ArraySize(alivesArray);
	new maxNemeses = 1;
	new maxSurvivors = 1;
	new maxZombies = floatround((alivesNum - (maxNemeses + maxSurvivors)) * 0.5, floatround_ceil);
	new Float:health;
	
	new item;
	new player;
	
	for (new i = 0; i < maxNemeses; i++)
	{
		item = random_num(0, ArraySize(alivesArray) - 1);
		player = ArrayGetCell(alivesArray, item);

		rz_class_player_change(player, 0, g_iClass_Nemesis);

		health = Float:get_entvar(player, var_health) * 0.5;

		set_entvar(player, var_health, health);
		set_entvar(player, var_max_health, health);

		ArrayDeleteItem(alivesArray, item);
	}

	for (new i = 0; i < maxSurvivors; i++)
	{
		item = random_num(0, ArraySize(alivesArray) - 1);
		player = ArrayGetCell(alivesArray, item);

		rz_class_player_change(player, 0, g_iClass_Survivor);

		health = Float:get_entvar(player, var_health) * 0.5;

		set_entvar(player, var_health, health);
		set_entvar(player, var_max_health, health);

		ArrayDeleteItem(alivesArray, item);
	}

	for (new i = 0; i < maxZombies; i++)
	{
		item = random_num(0, ArraySize(alivesArray) - 1);
		player = ArrayGetCell(alivesArray, item);

		rz_class_player_change(player, 0, g_iClass_Zombie);

		ArrayDeleteItem(alivesArray, item);
	}
}
