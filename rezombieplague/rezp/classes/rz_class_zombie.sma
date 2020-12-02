#pragma semicolon 1

#include <amxmodx>
#include <reapi>
#include <rezp>

new g_iClass_Zombie;

public plugin_precache()
{
	register_plugin("[ReZP] Class: Zombie", REZP_VERSION_STR, "fl0wer");

	new class = g_iClass_Zombie = rz_class_create("zombie", TEAM_TERRORIST);
	new props = rz_props_create("zombie_props");
	new playerModel = rz_playermodel_create("zombie_models");
	new playerSound = rz_playersound_create("zombie_sounds");
	new melee = rz_melee_create("models/zombie_plague/v_knife_zombie.mdl", "hide");

	rz_class_set_name_langkey(class, "RZ_ZOMBIE");
	rz_class_set_hudcolor(class, { 250, 250, 10 });
	rz_class_set_props(class, props);
	rz_class_set_playermodel(class, playerModel);
	rz_class_set_playersound(class, playerSound);
	rz_class_set_melee(class, melee);
	rz_class_set_nightvision(class, rz_nightvision_create(2, { 0, 150, 0 }, 63));

	rz_props_set_gravity(props, 0.8);
	rz_props_set_speed(props, 270);
	rz_props_set_footsteps(props, false);

	rz_playermodel_add(playerModel, "zombie_source", false);

	rz_playersound_add(playerSound, PL_PAIN_SOUND_BHIT_FLESH, "zombie_plague/zombie_pain1.wav");
	rz_playersound_add(playerSound, PL_PAIN_SOUND_BHIT_FLESH, "zombie_plague/zombie_pain2.wav");
	rz_playersound_add(playerSound, PL_PAIN_SOUND_BHIT_FLESH, "zombie_plague/zombie_pain3.wav");
	rz_playersound_add(playerSound, PL_PAIN_SOUND_BHIT_FLESH, "zombie_plague/zombie_pain4.wav");
	rz_playersound_add(playerSound, PL_PAIN_SOUND_BHIT_FLESH, "zombie_plague/zombie_pain5.wav");

	rz_playersound_add(playerSound, PL_PAIN_SOUND_DEATH, "zombie_plague/zombie_die1.wav");
	rz_playersound_add(playerSound, PL_PAIN_SOUND_DEATH, "zombie_plague/zombie_die2.wav");
	rz_playersound_add(playerSound, PL_PAIN_SOUND_DEATH, "zombie_plague/zombie_die3.wav");
	rz_playersound_add(playerSound, PL_PAIN_SOUND_DEATH, "zombie_plague/zombie_die4.wav");
	rz_playersound_add(playerSound, PL_PAIN_SOUND_DEATH, "zombie_plague/zombie_die5.wav");

	rz_melee_sound_add(melee, MELEE_SOUND_HIT, "weapons/knife_hit1.wav");
	rz_melee_sound_add(melee, MELEE_SOUND_HIT, "weapons/knife_hit2.wav");
	rz_melee_sound_add(melee, MELEE_SOUND_HIT, "weapons/knife_hit3.wav");
	rz_melee_sound_add(melee, MELEE_SOUND_HIT, "weapons/knife_hit4.wav");
	rz_melee_sound_add(melee, MELEE_SOUND_SLASH, "weapons/knife_slash1.wav");
	rz_melee_sound_add(melee, MELEE_SOUND_SLASH, "weapons/knife_slash2.wav");
	rz_melee_sound_add(melee, MELEE_SOUND_STAB, "weapons/knife_stab.wav");
	rz_melee_sound_add(melee, MELEE_SOUND_HITWALL, "weapons/knife_hitwall1.wav");
}

public plugin_init()
{
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "@CBasePlayer_TakeDamage_Pre", false);
}

@CBasePlayer_TakeDamage_Pre(id, inflictor, attacker, Float:damage, bitsDamageType)
{
	if (id == attacker || !is_user_connected(attacker))
		return;
	
	if (!rg_is_player_can_takedamage(id, attacker))
		return;

	if (rz_class_player_get(attacker) != g_iClass_Zombie)
		return;

	new activeItem = get_member(attacker, m_pActiveItem);

	if (is_nullent(activeItem))
		return;

	if (get_member(activeItem, m_iId) != WEAPON_KNIFE)
		return;
	
	new Float:armorValue = get_entvar(id, var_armorvalue);

	if (armorValue > 0.0)
	{
		armorValue = floatmax(armorValue - damage, 0.0);

		set_entvar(id, var_armorvalue, armorValue);
		SetHookChainArg(4, ATYPE_FLOAT, 0.0);
	}

	if (armorValue > 0.0 || (get_member(id, m_iKevlar) == ARMOR_VESTHELM && get_member(id, m_LastHitGroup) == HITGROUP_HEAD))
		return;

	if (!rz_class_player_change(id, attacker, g_iClass_Zombie))
		return;

	SetHookChainArg(4, ATYPE_FLOAT, 0.0);
}
