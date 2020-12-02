#pragma semicolon 1

#include <amxmodx>
#include <reapi>
#include <rezp>

new g_iGameMode_Plague;

new g_iClass_Zombie;
new g_iClass_Nemesis;
new g_iClass_Survivor;

public plugin_init()
{
	register_plugin("[ReZP] Game Mode: Plague", REZP_VERSION_STR, "fl0wer");

	RZ_CHECK_CLASS_EXISTS(g_iClass_Zombie, "zombie");
	RZ_CHECK_CLASS_EXISTS(g_iClass_Nemesis, "nemesis");
	RZ_CHECK_CLASS_EXISTS(g_iClass_Survivor, "survivor");

	new gameMode = g_iGameMode_Plague = rz_gamemode_create("plague");

	rz_gamemode_set_name_langkey(gameMode, "RZ_GAMEMODE_PLAGUE");
	rz_gamemode_set_notice_langkey(gameMode, "RZ_GAMEMODE_NOTICE_PLAGUE");
	rz_gamemode_set_hudcolor(gameMode, { 0, 50, 200 });
	rz_gamemode_set_chance(gameMode, 20);
	rz_gamemode_set_minalives(gameMode, 8);
}

public rz_gamemode_start_post(mode, Array:alivesArray)
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

public rz_class_change_pre(id, attacker, class)
{
	if (rz_gamemode_get_current() != g_iGameMode_Plague)
		return RZ_CONTINUE;

	if (id == attacker || !attacker)
		return RZ_CONTINUE;

	return RZ_SUPERCEDE;
}
