#pragma semicolon 1

#include <amxmodx>
#include <reapi>
#include <rezp>

new g_iClass_Assassin;

public plugin_precache()
{
	register_plugin("[ReZP] Class: Assassin", REZP_VERSION_STR, "fl0wer");

	new class = g_iClass_Assassin = rz_class_create("class_assassin", TEAM_TERRORIST);
	new props = rz_class_get(class, RZ_CLASS_PROPS);
	new model = rz_class_get(class, RZ_CLASS_MODEL);
	new nightVision = rz_class_get(class, RZ_CLASS_NIGHTVISION);
	new knife = rz_knife_create("knife_assassin");

	rz_class_set(class, RZ_CLASS_NAME, "RZ_ASSASSIN");
	rz_class_set(class, RZ_CLASS_HUD_COLOR, { 250, 250, 10 });
	rz_class_set(class, RZ_CLASS_SOUND, rz_playersound_find("zombie_sounds"));
	rz_class_set(class, RZ_CLASS_KNIFE, knife);

	rz_playerprops_set(props, RZ_PLAYER_PROPS_BASE_HEALTH, 100.0);
	rz_playerprops_set(props, RZ_PLAYER_PROPS_GRAVITY, 0.4);
	rz_playerprops_set(props, RZ_PLAYER_PROPS_SPEED, 600.0);
	rz_playerprops_set(props, RZ_PLAYER_PROPS_BLOOD_COLOR, 195);

	rz_playermodel_add(model, "zombie_source");

	rz_nightvision_set(nightVision, RZ_NIGHTVISION_EQUIP, RZ_NVG_EQUIP_APPEND_AND_ENABLE);
	rz_nightvision_set(nightVision, RZ_NIGHTVISION_COLOR, { 150, 150, 0 });
	rz_nightvision_set(nightVision, RZ_NIGHTVISION_ALPHA, 63);

	rz_knife_set(knife, RZ_KNIFE_VIEW_MODEL, "models/zombie_plague/v_knife_zombie.mdl");
	rz_knife_set(knife, RZ_KNIFE_PLAYER_MODEL, "hide");
	rz_knife_set(knife, RZ_KNIFE_STAB_BASE_DAMAGE, 200.0);
	rz_knife_set(knife, RZ_KNIFE_SWING_BASE_DAMAGE, 200.0);
}

public plugin_init()
{
	RegisterHookChain(RG_CBasePlayer_Killed, "@CBasePlayer_Killed_Pre", false);
}

public rz_fire_grenade_burn_pre(id)
{
	if (rz_player_get(id, RZ_PLAYER_CLASS) != g_iClass_Assassin)
		return RZ_CONTINUE;

	return RZ_SUPERCEDE;
}

public rz_frost_grenade_freeze_pre(id)
{
	if (rz_player_get(id, RZ_PLAYER_CLASS) != g_iClass_Assassin)
		return RZ_CONTINUE;

	return RZ_SUPERCEDE;
}

@CBasePlayer_Killed_Pre(id, attacker, gib)
{
	if (rz_player_get(id, RZ_PLAYER_CLASS) == g_iClass_Assassin)
	{
		SetHookChainArg(3, ATYPE_INTEGER, GIB_ALWAYS);
		return;
	}

	if (id == attacker || !is_user_connected(attacker))
		return;

	if (rz_player_get(attacker, RZ_PLAYER_CLASS) != g_iClass_Assassin)
		return;

	SetHookChainArg(3, ATYPE_INTEGER, GIB_ALWAYS);
}
