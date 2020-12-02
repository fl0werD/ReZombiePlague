#pragma semicolon 1

#include <amxmodx>
#include <reapi>
#include <rezp>

new g_iClass_Human;

new Float:g_flDamageDealt[MAX_PLAYERS + 1];

new Float:cvar_account_damaged_hp = 50.0;

public plugin_precache()
{
	register_plugin("[ReZP] Class: Human", REZP_VERSION_STR, "fl0wer");

	new class = g_iClass_Human = rz_class_create("human", TEAM_CT);
	new playerModel = rz_playermodel_create("human_models");

	rz_class_set_name_langkey(class, "RZ_HUMAN");
	rz_class_set_hudcolor(class, { 0, 180, 225 });
	rz_class_set_playermodel(class, playerModel);
	rz_class_set_nightvision(class, rz_nightvision_create(0, { 100, 100, 100 }, 63));

	rz_playermodel_add(playerModel, "urban");
	rz_playermodel_add(playerModel, "gsg9");
	rz_playermodel_add(playerModel, "sas");
	rz_playermodel_add(playerModel, "gign");
}

public plugin_init()
{
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "@CBasePlayer_TakeDamage_Post", true);
	RegisterHookChain(RG_CBasePlayer_GiveDefaultItems, "@CBasePlayer_GiveDefaultItems_Post", true);
}

public client_putinserver(id)
{
	g_flDamageDealt[id] = 0.0;
}

@CBasePlayer_TakeDamage_Post(id, inflictor, attacker, Float:damage, bitsDamageType)
{
	if (id == attacker || !is_user_connected(attacker))
		return;

	if (!rg_is_player_can_takedamage(id, attacker))
		return;

	if (rz_class_player_get(attacker) != g_iClass_Human)
		return;

	g_flDamageDealt[attacker] += damage;

	new addMoney;
	new dealtBonus = 1;
	new Float:dealt = cvar_account_damaged_hp;

	while (g_flDamageDealt[attacker] > dealt)
	{
		g_flDamageDealt[attacker] -= dealt;
		addMoney += dealtBonus;
	}

	if (addMoney)
		rg_add_account(attacker, addMoney);
}

@CBasePlayer_GiveDefaultItems_Post(id)
{
	if (rz_class_player_get(id) != g_iClass_Human)
		return;

	rg_give_item(id, "weapon_usp");
	set_member(id, m_rgAmmo, 24, rg_get_weapon_info(WEAPON_USP, WI_AMMO_TYPE));
}
