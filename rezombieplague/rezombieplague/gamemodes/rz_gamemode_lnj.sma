#pragma semicolon 1

#include <amxmodx>
#include <reapi>
#include <rezp>

new g_iGameMode_LNJ;

new g_iClass_Nemesis;
new g_iClass_Survivor;

public plugin_precache()
{
	register_plugin("[ReZP] Game Mode: Armageddon", REZP_VERSION_STR, "fl0wer");

	RZ_CHECK_CLASS_EXISTS(g_iClass_Nemesis, "class_nemesis");
	RZ_CHECK_CLASS_EXISTS(g_iClass_Survivor, "class_survivor");

	new gameMode = g_iGameMode_LNJ = rz_gamemode_create("gamemode_armageddon");

	rz_gamemode_set(gameMode, RZ_GAMEMODE_NAME, "RZ_GAMEMODE_LNJ");
	rz_gamemode_set(gameMode, RZ_GAMEMODE_NOTICE, "RZ_GAMEMODE_NOTICE_LNJ");
	rz_gamemode_set(gameMode, RZ_GAMEMODE_HUD_COLOR, { 181, 62, 244 });
	rz_gamemode_set(gameMode, RZ_GAMEMODE_CHANCE, 20);
	rz_gamemode_set(gameMode, RZ_GAMEMODE_MIN_ALIVES, 16);
	rz_gamemode_set(gameMode, RZ_GAMEMODE_DEATHMATCH, RZ_GM_DEATHMATCH_ONLY_CT);
}

public rz_gamemodes_change_post(mode, Array:alivesArray)
{
	if (mode != g_iGameMode_LNJ)
		return;

	new alivesNum = ArraySize(alivesArray);
	new maxNemeses = floatround(alivesNum * 0.5, floatround_ceil);
	new Float:health;
	
	new item;
	new player;
	
	for (new i = 0; i < maxNemeses; i++)
	{
		item = random_num(0, ArraySize(alivesArray) - 1);
		player = ArrayGetCell(alivesArray, item);

		rz_class_player_change(player, 0, g_iClass_Nemesis);

		health = Float:get_entvar(player, var_health) * 0.25;

		set_entvar(player, var_health, health);
		set_entvar(player, var_max_health, health);

		ArrayDeleteItem(alivesArray, item);
	}

	alivesNum = ArraySize(alivesArray);

	for (new i = 0; i < alivesNum; i++)
	{
		player = ArrayGetCell(alivesArray, i);

		rz_class_player_change(player, 0, g_iClass_Survivor);

		health = Float:get_entvar(player, var_health) * 0.25;

		set_entvar(player, var_health, health);
		set_entvar(player, var_max_health, health);
	}

	rz_class_override_default(TEAM_TERRORIST, g_iClass_Nemesis);
	rz_class_override_default(TEAM_CT, g_iClass_Survivor);
}
