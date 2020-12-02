#pragma semicolon 1

#include <amxmodx>
#include <reapi>
#include <rezp>
#include <util_tempentities>

new const MADNESS_SOUND[] = "zombie_plague/zombie_madness1.wav";

new g_iItem_Madness;
new g_iClass_Zombie;

new Float:g_flMadnessTime[MAX_PLAYERS + 1];

public plugin_precache()
{
	register_plugin("[ReZP] Item: Madness", REZP_VERSION_STR, "fl0wer");

	precache_sound(MADNESS_SOUND);

	new item = g_iItem_Madness = rz_item_create("zombie_madness");

	rz_item_set_name_langkey(item, "RZ_ITEM_MADNESS");
	rz_item_set_cost(item, 15);
}

public plugin_init()
{
	RegisterHookChain(RG_CSGameRules_FPlayerCanTakeDamage, "@CSGameRules_FPlayerCanTakeDamage_Pre", false);

	g_iClass_Zombie = rz_class_find("zombie");
}

public client_putinserver(id)
{
	g_flMadnessTime[id] = 0.0;
}

public rz_item_select_pre(id, item)
{
	if (item != g_iItem_Madness)
		return RZ_CONTINUE;

	if (rz_class_player_get(id) != g_iClass_Zombie)
		return RZ_BREAK;

	if (g_flMadnessTime[id])
		return RZ_SUPERCEDE;
	
	return RZ_CONTINUE;
}

public rz_item_select_post(id, item)
{
	if (item != g_iItem_Madness)
		return;

	g_flMadnessTime[id] = get_gametime() + 5.0;
	
	set_task(0.1, "@Task_Madness", id, .flags = "b");

	rh_emit_sound2(id, 0, CHAN_VOICE, MADNESS_SOUND, VOL_NORM, ATTN_NORM);
}

public rz_fire_grenade_burn_pre(id)
{
	if (!g_flMadnessTime[id])
		return RZ_CONTINUE;

	return RZ_SUPERCEDE;
}

public rz_frost_grenade_freeze_pre(id)
{
	if (!g_flMadnessTime[id])
		return RZ_CONTINUE;

	return RZ_SUPERCEDE;
}

@CSGameRules_FPlayerCanTakeDamage_Pre(id, attacker)
{
	if (!g_flMadnessTime[id])
		return HC_CONTINUE;

	SetHookChainReturn(ATYPE_INTEGER, false);
	return HC_SUPERCEDE;
}

@Task_Madness(id)
{
	new player = id;

	if (!is_user_alive(player) || rz_class_player_get(player) != g_iClass_Zombie || g_flMadnessTime[player] <= get_gametime())
	{
		g_flMadnessTime[player] = 0.0;
		remove_task(id);
		return;
	}

	new Float:vecOrigin[3];
	get_entvar(player, var_origin, vecOrigin);

	message_begin_f(MSG_PVS, SVC_TEMPENTITY, vecOrigin);
	TE_DLight(vecOrigin, 20, { 150, 0, 0 }, 2, 0);
}
