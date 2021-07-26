#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <reapi>
#include <rezp>
#include <util_tempentities>

new const SNIPER_AWP_REFERENCE[] = "weapon_awp";

new const Float:SNIPER_AWP_BASE_DAMAGE = 1150.0;

new g_iWeapon_SniperAWP;

public plugin_precache()
{
	register_plugin("[ReZP] Weapon: Sniper AWP", REZP_VERSION_STR, "fl0wer");

	g_iWeapon_SniperAWP = rz_weapon_create("weapon_sniperawp", SNIPER_AWP_REFERENCE);
}

public plugin_init()
{
	RegisterHookChain(RG_CBasePlayer_Killed, "@CBasePlayer_Killed_Pre", false);
	
	RegisterHam(Ham_Spawn, SNIPER_AWP_REFERENCE, "@CSniperAWP_Spawn_Post", true);
}

@CBasePlayer_Killed_Pre(id, attacker, gib)
{
	if (!rg_is_player_can_takedamage(id, attacker))
		return;

	if (!ExecuteHam(Ham_IsPlayer, attacker))
		return;

	new activeItem = get_member(attacker, m_pActiveItem);

	if (is_nullent(activeItem))
		return;

	if (get_entvar(activeItem, var_impulse) != g_iWeapon_SniperAWP)
		return;

	new Float:vecOrigin[3];
	get_entvar(id, var_origin, vecOrigin);

	vecOrigin[2] -= 26.0;
	
	message_begin_f(MSG_PVS, SVC_TEMPENTITY, vecOrigin);
	TE_LavaSplash(vecOrigin);

	SetHookChainArg(3, ATYPE_INTEGER, GIB_ALWAYS);
}

@CSniperAWP_Spawn_Post(id)
{
	if (get_entvar(id, var_impulse) != g_iWeapon_SniperAWP)
		return;

	set_member(id, m_Weapon_flBaseDamage, SNIPER_AWP_BASE_DAMAGE);
}
