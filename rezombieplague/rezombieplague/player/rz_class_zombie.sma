#pragma semicolon 1

#include <amxmodx>
#include <reapi>
#include <rezp>

new const ARMOR_HIT_SOUND[] = "player/bhit_helmet-1.wav";

new g_iClass_Zombie;

public plugin_precache()
{
	register_plugin("[ReZP] Class: Zombie", REZP_VERSION_STR, "fl0wer");

	precache_sound(ARMOR_HIT_SOUND);

	new class = g_iClass_Zombie = rz_class_create("class_zombie", TEAM_TERRORIST);
	new props = rz_class_get(class, RZ_CLASS_PROPS);
	new model = rz_class_get(class, RZ_CLASS_MODEL);
	new sound = rz_class_get(class, RZ_CLASS_SOUND);
	new nightVision = rz_class_get(class, RZ_CLASS_NIGHTVISION);
	new knife = rz_knife_create("knife_zombie");

	rz_class_set(class, RZ_CLASS_NAME, "RZ_ZOMBIE");
	rz_class_set(class, RZ_CLASS_HUD_COLOR, { 250, 250, 10 });
	rz_class_set(class, RZ_CLASS_KNIFE, knife);

	rz_playerprops_set(props, RZ_PLAYER_PROPS_GRAVITY, 0.8);
	rz_playerprops_set(props, RZ_PLAYER_PROPS_SPEED, 270.0);
	rz_playerprops_set(props, RZ_PLAYER_PROPS_FOOTSTEPS, false);

	rz_playermodel_add(model, "zombie_source", false);

	rz_playersound_add(sound, RZ_PAIN_SOUND_BHIT_FLESH, "zombie_plague/zombie_pain1.wav");
	rz_playersound_add(sound, RZ_PAIN_SOUND_BHIT_FLESH, "zombie_plague/zombie_pain2.wav");
	rz_playersound_add(sound, RZ_PAIN_SOUND_BHIT_FLESH, "zombie_plague/zombie_pain3.wav");
	rz_playersound_add(sound, RZ_PAIN_SOUND_BHIT_FLESH, "zombie_plague/zombie_pain4.wav");
	rz_playersound_add(sound, RZ_PAIN_SOUND_BHIT_FLESH, "zombie_plague/zombie_pain5.wav");

	rz_playersound_add(sound, RZ_PAIN_SOUND_DEATH, "zombie_plague/zombie_die1.wav");
	rz_playersound_add(sound, RZ_PAIN_SOUND_DEATH, "zombie_plague/zombie_die2.wav");
	rz_playersound_add(sound, RZ_PAIN_SOUND_DEATH, "zombie_plague/zombie_die3.wav");
	rz_playersound_add(sound, RZ_PAIN_SOUND_DEATH, "zombie_plague/zombie_die4.wav");
	rz_playersound_add(sound, RZ_PAIN_SOUND_DEATH, "zombie_plague/zombie_die5.wav");

	rz_knife_sound_add(knife, RZ_KNIFE_SOUND_HIT, "weapons/knife_hit1.wav");
	rz_knife_sound_add(knife, RZ_KNIFE_SOUND_HIT, "weapons/knife_hit2.wav");
	rz_knife_sound_add(knife, RZ_KNIFE_SOUND_HIT, "weapons/knife_hit3.wav");
	rz_knife_sound_add(knife, RZ_KNIFE_SOUND_HIT, "weapons/knife_hit4.wav");
	rz_knife_sound_add(knife, RZ_KNIFE_SOUND_SLASH, "weapons/knife_slash1.wav");
	rz_knife_sound_add(knife, RZ_KNIFE_SOUND_SLASH, "weapons/knife_slash2.wav");
	rz_knife_sound_add(knife, RZ_KNIFE_SOUND_STAB, "weapons/knife_stab.wav");
	rz_knife_sound_add(knife, RZ_KNIFE_SOUND_HITWALL, "weapons/knife_hitwall1.wav");

	rz_nightvision_set(nightVision, RZ_NIGHTVISION_EQUIP, RZ_NVG_EQUIP_APPEND_AND_ENABLE);
	rz_nightvision_set(nightVision, RZ_NIGHTVISION_COLOR, { 0, 150, 0 });
	rz_nightvision_set(nightVision, RZ_NIGHTVISION_ALPHA, 63);

	rz_knife_set(knife, RZ_KNIFE_VIEW_MODEL, "models/zombie_plague/v_knife_zombie.mdl");
	rz_knife_set(knife, RZ_KNIFE_PLAYER_MODEL, "hide");
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

	if (rz_player_get(attacker, RZ_PLAYER_CLASS) != g_iClass_Zombie)
		return;

	new gameMode = rz_gamemodes_get(RZ_GAMEMODES_CURRENT);

	if (!gameMode)
		return;

	if (!rz_gamemode_get(gameMode, RZ_GAMEMODE_CHANGE_CLASS))
		return;

	new activeItem = get_member(attacker, m_pActiveItem);

	if (is_nullent(activeItem) || get_member(activeItem, m_iId) != WEAPON_KNIFE)
		return;
	
	new Float:armorValue = get_entvar(id, var_armorvalue);

	if (armorValue > 0.0)
	{
		armorValue = floatmax(armorValue - damage, 0.0);

		set_entvar(id, var_armorvalue, armorValue);
		SetHookChainArg(4, ATYPE_FLOAT, 0.0);
		
		rh_emit_sound2(id, 0, CHAN_BODY, ARMOR_HIT_SOUND);
	}

	if (armorValue > 0.0 || (get_member(id, m_iKevlar) == ARMOR_VESTHELM && get_member(id, m_LastHitGroup) == HITGROUP_HEAD))
		return;

	new numAliveCT;
	rg_initialize_player_counts(_, numAliveCT);

	if (numAliveCT == 1)
		return;

	if (!rz_class_player_change(id, attacker, g_iClass_Zombie))
		return;

	SetHookChainArg(4, ATYPE_FLOAT, 0.0);
}
