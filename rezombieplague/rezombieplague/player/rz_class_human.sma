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

	new class = g_iClass_Human = rz_class_create("class_human", TEAM_CT);
	new model = rz_class_get(class, RZ_CLASS_MODEL);
	new nightVision = rz_class_get(class, RZ_CLASS_NIGHTVISION);

	rz_class_set(class, RZ_CLASS_NAME, "RZ_HUMAN");
	rz_class_set(class, RZ_CLASS_HUD_COLOR, { 0, 180, 225 });

	rz_playermodel_add(model, "urban");
	rz_playermodel_add(model, "gsg9");
	rz_playermodel_add(model, "sas");
	rz_playermodel_add(model, "gign");

	rz_nightvision_set(nightVision, RZ_NIGHTVISION_COLOR, { 100, 100, 100 });
	rz_nightvision_set(nightVision, RZ_NIGHTVISION_ALPHA, 63);
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

	if (rz_player_get(attacker, RZ_PLAYER_CLASS) != g_iClass_Human)
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
	if (rz_player_get(id, RZ_PLAYER_CLASS) != g_iClass_Human)
		return;

	rg_give_item(id, "weapon_usp");
	set_member(id, m_rgAmmo, 24, rg_get_weapon_info(WEAPON_USP, WI_AMMO_TYPE));
}
