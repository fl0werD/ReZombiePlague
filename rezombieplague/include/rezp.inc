#if defined _rezp_included
	#endinput
#endif

#define _rezp_included

const MAX_QPATH = 64;

#define REZP_VERSION			"0"
#define REZP_VERSION_MAJOR		"1"
#define REZP_VERSION_MINOR		"0"
#define REZP_VERSION_STR		REZP_VERSION_MAJOR + "." + REZP_VERSION_MINOR + "." + REZP_VERSION

enum
{
	RZ_CONTINUE, // available
	RZ_SUPERCEDE, // not available
	RZ_BREAK, // don't show
};

enum PlayerPainSound
{
	PL_PAIN_SOUND_BHIT_HELMET,
	PL_PAIN_SOUND_HEADSHOT,
	PL_PAIN_SOUND_BHIT_KEVLAR,
	PL_PAIN_SOUND_BHIT_FLESH,
	PL_PAIN_SOUND_DEATH,
	MAX_PL_PAIN_SOUNDS,
};

enum MeleeSound
{
	MELEE_SOUND_DEPLOY,
	MELEE_SOUND_HIT,
	MELEE_SOUND_SLASH,
	MELEE_SOUND_STAB,
	MELEE_SOUND_HITWALL,
	MAX_MELEE_SOUNDS,
};

native rz_load_langs(const name[]);
native rz_sys_error(const error[], any:...);
native rz_print_chat(id, sender = print_team_default, text[], any:...);
native rz_give_bonus(id, amount, text[] = "", any:...);

native rz_main_lighting_global_get();
native rz_main_lighting_global_set(const character[]);
native rz_main_lighting_global_reset();
native rz_main_lighting_nvg_get();
native rz_main_lighting_nvg_set(const character[]);
native rz_main_lighting_nvg_reset();
native bool:rz_main_roundover_ct_win();
native rz_main_prepare_time();
native rz_main_round_time();
native bool:rz_main_warmup_enabled();
native rz_main_warmup_time();
native bool:rz_main_ammopacks_enabled();
native rz_main_ammopacks_join_amount();

native rz_module_create(const name[], Array:handle);
native rz_module_get_offset(module);
native rz_module_get_valid_index(module, index);
native rz_module_find(const name[]);

native bool:rz_game_is_warmup();
native rz_game_get_playersnum(TeamName:team);
native rz_game_get_alivesnum();

native rz_class_create(const name[], TeamName:team);
native rz_class_get_name(class, name[], len);
native TeamName:rz_class_get_team(class);
native rz_class_get_name_langkey(class, name[], len);
native rz_class_set_name_langkey(class, name[]);
native rz_class_get_hudcolor(class, color[3]);
native rz_class_set_hudcolor(class, color[3]);
native rz_class_get_props(class);
native rz_class_set_props(class, props);
native rz_class_get_playermodel(class);
native rz_class_set_playermodel(class, playerModel);
native rz_class_get_playersound(class);
native rz_class_set_playersound(class, playerSound);
native rz_class_get_melee(class);
native rz_class_set_melee(class, melee);
native rz_class_get_nightvision(class);
native rz_class_set_nightvision(class, nightvision);
native rz_class_get_default(TeamName:team);
native rz_class_set_default(TeamName:team, class);
native rz_class_override_default(TeamName:team, class);
native rz_class_start();
native rz_class_find(const name[]);
native rz_class_size();
native rz_class_player_get(id);
native rz_class_player_set(id, class);
native rz_class_player_change(id, attacker, class);

forward rz_class_change_pre(id, attacker, class);
forward rz_class_change_post(id, attacker, class);

native rz_subclass_create(class, const name[]);
native rz_subclass_get_class(subclass);
native rz_subclass_get_name(subclass, name[], len);
native rz_subclass_get_name_langkey(subclass, name[], len);
native rz_subclass_set_name_langkey(subclass, name[]);
native rz_subclass_get_desc_langkey(subclass, desc[], len);
native rz_subclass_set_desc_langkey(subclass, desc[]);
native rz_subclass_get_props(subclass);
native rz_subclass_set_props(subclass, props);
native rz_subclass_get_playermodel(subclass);
native rz_subclass_set_playermodel(subclass, playerModel);
native rz_subclass_get_playersound(subclass);
native rz_subclass_set_playersound(subclass, playerSound);
native rz_subclass_get_melee(subclass);
native rz_subclass_set_melee(subclass, melee);
native rz_subclass_get_nightvision(subclass);
native rz_subclass_set_nightvision(subclass, nightvision);
native rz_subclass_get_default(class);
native rz_subclass_set_default(class, subclass);
native rz_subclass_start();
native rz_subclass_find(const name[]);
native rz_subclass_size();
native rz_subclass_player_get(id);
native rz_subclass_player_set(id, subclass);
native rz_subclass_player_change(id, subclass);
native rz_subclass_player_get_status(id, subclass);
native rz_subclass_player_get_chosen(id, class);
native rz_subclass_player_set_chosen(id, class, subclass);

forward rz_subclass_change_pre(id, subclass);
forward rz_subclass_change_post(id, subclass);

native rz_props_create(const name[]);
native rz_props_get_health(props);
native rz_props_set_health(props, health);
native rz_props_get_basehealth(props);
native rz_props_set_basehealth(props, health);
native rz_props_get_armor(props);
native rz_props_set_armor(props, armor);
native rz_props_get_helmet(props);
native rz_props_set_helmet(props, bool:enabled);
native Float:rz_props_get_gravity(props);
native rz_props_set_gravity(props, Float:gravity);
native rz_props_get_speed(props);
native rz_props_set_speed(props, speed);
native rz_props_get_footsteps(props);
native rz_props_set_footsteps(props, enabled);
native Float:rz_props_get_velmod_flinch(props);
native rz_props_set_velmod_flinch(props, Float:velModFlinch);
native Float:rz_props_get_velmod_largeflinch(props);
native rz_props_set_velmod_largeflinch(props, Float:velModLargeFlinch);
native Float:rz_props_get_knockback(props);
native rz_props_set_knockback(props, Float:knockback);
native rz_props_get_bloodcolor(props);
native rz_props_set_bloodcolor(props, bloodColor);
native rz_props_player_get(id);
native rz_props_player_set(id, props);
native rz_props_player_change(id);

native rz_playermodel_create(const name[]);
native rz_playermodel_add(playerModel, const modelName[], bool:defaultHitboxes = true, body = 0);
native rz_playermodel_get_name(playerModel, name[], len);
native rz_playermodel_player_get(id);
native rz_playermodel_player_set(id, playerModel);
native rz_playermodel_player_change(id);

native rz_playersound_create(const name[]);
native rz_playersound_add(playerSound, PlayerPainSound:painSound, const sample[]);
native rz_playersound_find(const name[]);
native rz_playersound_player_get(id);
native rz_playersound_player_set(id, melee);

native rz_melee_create(const viewModel[] = "", const weaponModel[] = "", const weaponList[] = "", Float:damageMulti = -1.0, Float:stabDistance = -1.0, Float:swingDistance = -1.0);
native rz_melee_sound_add(melee, MeleeSound:meleeSound, const sample[]);
native rz_melee_player_get(id);
native rz_melee_player_set(id, melee);

native rz_nightvision_create(equip = 0, color[3] = NULL_VECTOR, alpha = -1);
native rz_nightvision_get_equip(nightvision);
native rz_nightvision_get_color(nightvision, color[3]);
native rz_nightvision_get_alpha(nightvision);
native rz_nightvision_player_get(id);
native rz_nightvision_player_set(id, nightvision);
native rz_nightvision_player_change(id);
native rz_nightvision_player_update(id = 0);

native rz_gamemode_create(const name[]);
native rz_gamemode_get_name(gameMode, name[], len);
native rz_gamemode_get_name_langkey(gameMode, name[], len);
native rz_gamemode_set_name_langkey(gameMode, name[]);
native rz_gamemode_get_notice_langkey(gameMode, notice[], len);
native rz_gamemode_set_notice_langkey(gameMode, notice[]);
native rz_gamemode_get_hudcolor(gameMode, color[3]);
native rz_gamemode_set_hudcolor(gameMode, color[3]);
native rz_gamemode_get_chance(gameMode);
native rz_gamemode_set_chance(gameMode, chance);
native rz_gamemode_get_minalives(gameMode);
native rz_gamemode_set_minalives(gameMode, playersNum);
native rz_gamemode_get_roundtime(gameMode);
native rz_gamemode_set_roundtime(gameMode, seconds);
native rz_gamemode_get_default();
native rz_gamemode_set_default(gameMode);
native rz_gamemode_get_current();
native rz_gamemode_can_launch(gameMode);
native rz_gamemode_set_force(gameMode, bool:instant = false);
native rz_gamemode_start();
native rz_gamemode_find(const name[]);
native rz_gamemode_size();

forward rz_gamemode_start_pre(mode, Array:alivesArray);
forward rz_gamemode_start_post(mode, Array:alivesArray);

native rz_item_create(const name[]);
native rz_item_get_name_langkey(item, name[], len);
native rz_item_set_name_langkey(item, name[]);
native rz_item_get_cost(item);
native rz_item_set_cost(item, cost);
native rz_item_start();
native rz_item_find(const name[]);
native rz_item_size();
native rz_item_player_get_status(id, item);
native rz_item_player_give(id, item);

forward rz_item_select_pre(id, item);
forward rz_item_select_post(id, item);

native rz_weapon_create(const reference[], const classname[], const name[], const viewModel[] = "", const weaponModel[] = "", const worldModel[] = "", const weaponList[] = "");
native rz_weapon_get_reference(weapon, reference[], len);
native rz_weapon_get_name(weapon, name[], len);
native rz_weapon_find(const classname[]);
native rz_weapon_player_give(id, weapon, any:giveType);

forward rz_weapon_grenade_throw_pre(id, entity, weapon);
forward rz_weapon_grenade_throw_pre(id, entity, weapon);
forward rz_weapon_grenade_explode_pre(id, weapon);
forward rz_weapon_grenade_explode_post(id, weapon);

forward rz_fire_grenade_burn_pre(id);
forward rz_fire_grenade_burn_post(id);

forward rz_frost_grenade_freeze_pre(id);
forward rz_frost_grenade_freeze_post(id);

#define RZ_CHECK_CLASS_EXISTS(%0,%1)			(%0 = (%0 = rz_class_find(%1)) != 0 ? %0 : set_fail_state("Class '%s' not found", %1))

#define CHECK_CONNECTED(%0,%1) \
	if (!is_user_connected(%0)) \
	{ \
		log_error(AMX_ERR_NATIVE, "Player %d is not connected", %0); \
		return %1; \
	}

#define CHECK_ALIVE(%0,%1) \
	if (!is_user_alive(%0)) \
	{ \
		log_error(AMX_ERR_NATIVE, "Player %d is not alive", %0); \
		return %1; \
	}

#define CHECK_PLAYABLE_TEAM(%0,%1) \
	if (TEAM_TERRORIST > %0 > TEAM_CT) \
	{ \
		log_error(AMX_ERR_NATIVE, "Invalid player team (%d)", %0); \
		return %1; \
	}

#define CHECK_MODULE_VALID_INDEX(%0,%1) \
	if (%0 == -1) \
	{ \
		log_error(AMX_ERR_NATIVE, "Invalid index (%d)", %0); \
		return %1; \
	}

/*
* This is the callback from the main plugin that gives major/minor versions for verifying compatibility for ReZombiePlague versions.
* If an AMXX plugin gets a failure, then you do need to upgrade to the latest version of the ReZP plugins or update the files included for AMXX plugins.
* Do not modify this!
*/
public __rezp_version_check(const majorVersion[], const minorVersion[])
{
	if (strcmp(majorVersion, REZP_VERSION_MAJOR) != 0)
	{
		set_fail_state("[ReZP]: Api major version mismatch; expected %s, real %s", REZP_VERSION_MAJOR, majorVersion);
		return;
	}

	if (strcmp(minorVersion, REZP_VERSION_MINOR) != 0)
	{
		set_fail_state("[ReZP]: Api minor version mismatch; expected at least %s, real %s", REZP_VERSION_MINOR, minorVersion);
		return;
	}
}
