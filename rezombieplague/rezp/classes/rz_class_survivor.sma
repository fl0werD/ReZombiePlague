#pragma semicolon 1

#include <amxmodx>
#include <reapi>
#include <rezp>

new g_iClass_Survivor;

public plugin_precache()
{
	register_plugin("[ReZP] Class: Survivor", REZP_VERSION_STR, "fl0wer");

	new class = g_iClass_Survivor = rz_class_create("survivor", TEAM_CT);
	new props = rz_props_create("survivor_props");
	new playerModel = rz_playermodel_create("survivor_models");

	rz_class_set_name_langkey(class, "RZ_SURVIVOR");
	rz_class_set_hudcolor(class, { 0, 180, 225 });
	rz_class_set_props(class, props);
	rz_class_set_playermodel(class, playerModel);
	rz_class_set_melee(class, rz_melee_create(.damageMulti = 2.0));
	rz_class_set_nightvision(class, rz_nightvision_create(1, { 100, 100, 100 }, 63));

	rz_props_set_basehealth(props, 200);
	rz_props_set_gravity(props, 1.25);

	rz_playermodel_add(playerModel, "leet");
}

public plugin_init()
{
	RegisterHookChain(RG_CBasePlayer_GiveDefaultItems, "@CBasePlayer_GiveDefaultItems_Post", true);
}

@CBasePlayer_GiveDefaultItems_Post(id)
{
	if (rz_class_player_get(id) != g_iClass_Survivor)
		return;

	new item = rg_give_item(id, "weapon_m249", GT_APPEND);

	if (!is_nullent(item))
	{
		new WeaponIdType:weaponId = get_member(item, m_iId);

		set_member(id, m_rgAmmo, rg_get_weapon_info(weaponId, WI_MAX_ROUNDS), rg_get_weapon_info(weaponId, WI_AMMO_TYPE));
	}
}
