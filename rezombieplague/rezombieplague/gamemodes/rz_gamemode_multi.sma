#pragma semicolon 1

#include <amxmodx>
#include <reapi>
#include <rezp>
#include <util_messages>

new const MOTHER_ICON_SPRITE[] = "dmg_bio";

new bool:g_bMotherZombie[MAX_PLAYERS + 1];

new g_iGameMode_Multi;
new g_iClass_Zombie;

new rz_multi_mother_zombie;

public plugin_precache()
{
	register_plugin("[ReZP] Game Mode: Multiple Infection", REZP_VERSION_STR, "fl0wer");

	RZ_CHECK_CLASS_EXISTS(g_iClass_Zombie, "class_zombie");

	new gameMode = g_iGameMode_Multi = rz_gamemode_create("gamemode_multi");

	rz_gamemode_set(gameMode, RZ_GAMEMODE_NAME, "RZ_GAMEMODE_MULTI");
	rz_gamemode_set(gameMode, RZ_GAMEMODE_NOTICE, "RZ_GAMEMODE_NOTICE_MULTI");
	rz_gamemode_set(gameMode, RZ_GAMEMODE_HUD_COLOR,  { 200, 50, 0 });
	rz_gamemode_set(gameMode, RZ_GAMEMODE_CHANGE_CLASS, true);
	rz_gamemode_set(gameMode, RZ_GAMEMODE_DEATHMATCH, RZ_GM_DEATHMATCH_ONLY_TR);

	RegisterHookChain(RG_CBasePlayer_Killed, "@CBasePlayer_Killed_Post", true);

	bind_pcvar_num(create_cvar("rz_multi_mother_zombie", "1", _, "", true, 0.0, true, 1.0), rz_multi_mother_zombie);
}

public rz_gamemodes_change_post(mode, Array:alivesArray)
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
	new bool:motherSetted;

	maxZombies = min(maxZombies, alivesNum);
	
	for (new i = 0; i < maxZombies; i++)
	{
		item = random_num(0, ArraySize(alivesArray) - 1);
		player = ArrayGetCell(alivesArray, item);

		rz_class_player_change(player, 0, g_iClass_Zombie);

		if (rz_multi_mother_zombie && !motherSetted)
		{
			motherSetted = true;
			SetMotherZombie(player, true);
		}

		ArrayDeleteItem(alivesArray, item);
	}
}

public rz_class_change_pre(id, attacker, class)
{
	SetMotherZombie(id, false);
}

public rz_subclass_change_post(id, subclass)
{
	if (!g_bMotherZombie[id])
		return;

	SetMotherZombie(id, true);
}

@CBasePlayer_Killed_Post(id, attacker, gib)
{
	SetMotherZombie(id, false);
}

SetMotherZombie(id, bool:enabled)
{
	if (enabled)
	{
		new props = rz_player_get(id, RZ_PLAYER_PROPS);
		new Float:health;

		if (props)
			health = Float:rz_playerprops_get(props, RZ_PLAYER_PROPS_HEALTH);
		else
			health = get_entvar(id, var_health);

		health *= 2.0;

		set_entvar(id, var_health, health);
		set_entvar(id, var_max_health, health);

		if (!g_bMotherZombie[id])
		{
			message_begin(MSG_ONE, gmsgStatusIcon, _, id);
			SendStatusIcon(1, MOTHER_ICON_SPRITE, { 0, 160, 0 });

			rz_longjump_player_give(id, true, 560.0, 300.0, 10.0);
		}
	}
	else
	{
		if (g_bMotherZombie[id])
		{
			message_begin(MSG_ONE, gmsgStatusIcon, _, id);
			SendStatusIcon(0, MOTHER_ICON_SPRITE);
		}
	}

	g_bMotherZombie[id] = enabled;
}

public plugin_natives()
{
	register_native("rz_multi_mother_player_get", "@native_multi_mother_player_get");
}

@native_multi_mother_player_get(plugin, argc)
{
	enum { arg_player = 1 };

	new player = get_param(arg_player);
	RZ_CHECK_ALIVE(player, false)

	return g_bMotherZombie[player];
}
