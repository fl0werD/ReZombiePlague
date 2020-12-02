#pragma semicolon 1

#include <amxmodx>
#include <reapi>
#include <rezp>

new g_iClass_Sniper;
new g_iWeapon_SniperAWP;

public plugin_precache()
{
	register_plugin("[ReZP] Class: Sniper", REZP_VERSION_STR, "fl0wer");

	new class = g_iClass_Sniper = rz_class_create("sniper", TEAM_CT);
	new props = rz_props_create("sniper_props");
	new playerModel = rz_playermodel_create("sniper_models");

	rz_class_set_name_langkey(class, "RZ_SNIPER");
	rz_class_set_hudcolor(class, { 0, 180, 225 });
	rz_class_set_props(class, props);
	rz_class_set_playermodel(class, playerModel);
	rz_class_set_nightvision(class, rz_nightvision_create(0, { 100, 100, 100 }, 63));

	rz_props_set_basehealth(props, 50);
	rz_props_set_gravity(props, 0.75);

	rz_playermodel_add(playerModel, "gign");
	rz_playermodel_add(playerModel, "leet");
}

public plugin_init()
{
	RegisterHookChain(RG_CBasePlayer_GiveDefaultItems, "@CBasePlayer_GiveDefaultItems_Post", true);
	
	g_iWeapon_SniperAWP = rz_weapon_find("weapon_sniperawp");
}

@CBasePlayer_GiveDefaultItems_Post(id)
{
	if (rz_class_player_get(id) != g_iClass_Sniper)
		return;

	if (g_iWeapon_SniperAWP)
	{
		new item = rz_weapon_player_give(id, g_iWeapon_SniperAWP, GT_APPEND);

		if (item)
		{
			new WeaponIdType:weaponId = get_member(item, m_iId);

			set_member(id, m_rgAmmo, rg_get_weapon_info(weaponId, WI_MAX_ROUNDS), rg_get_weapon_info(weaponId, WI_AMMO_TYPE));
		}
	}
}
