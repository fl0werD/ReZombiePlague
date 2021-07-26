#if defined _rezp_player_included
	#endinput
#endif

#define _rezp_player_included

enum RZPlayerProp
{
	RZ_PLAYER_CLASS,
	RZ_PLAYER_SUBCLASS,
	RZ_PLAYER_SUBCLASS_CHOSEN,
	RZ_PLAYER_PROPS,
	RZ_PLAYER_MODEL,
	RZ_PLAYER_SOUND,
	RZ_PLAYER_KNIFE,
	RZ_PLAYER_NIGHTVISION,
	bool:RZ_PLAYER_HAS_NIGHTVISION,
	bool:RZ_PLAYER_NIGHTVISION_ENABLED,
};

native any:rz_player_get(id, RZPlayerProp:prop, any:...);
native rz_player_set(id, RZPlayerProp:prop, any:...);

enum RZClassProp
{
	RZ_CLASS_HANDLE, // [RZ_MAX_HANDLE_LENGTH]
	RZ_CLASS_NAME, // [RZ_MAX_LANGKEY_LENGTH]
	RZ_CLASS_TEAM, // enum TeamName
	RZ_CLASS_HUD_COLOR, // [3]
	RZ_CLASS_PROPS, // cell
	RZ_CLASS_MODEL, // cell
	RZ_CLASS_SOUND, // cell
	RZ_CLASS_KNIFE, // cell
	RZ_CLASS_NIGHTVISION, // cell
};

native rz_class_create(const handle[], TeamName:team);
native any:rz_class_get(playerProps, RZClassProp:prop, any:...);
native rz_class_set(playerProps, RZClassProp:prop, any:...);
native rz_class_start();
native rz_class_find(const handle[]);
native rz_class_size();

native rz_class_get_default(TeamName:team, bool:overrided = true);
native rz_class_set_default(TeamName:team, class);
native rz_class_override_default(TeamName:team, class);

native rz_class_player_change(id, attacker, class, bool:preSpawn = false);

forward rz_class_change_pre(id, attacker, class, bool:preSpawn);
forward rz_class_change_post(id, attacker, class, bool:preSpawn);



enum RZSubclassProp
{
	RZ_SUBCLASS_HANDLE, // [RZ_MAX_HANDLE_LENGTH]
	RZ_SUBCLASS_CLASS, // cell
	RZ_SUBCLASS_NAME, // [RZ_MAX_LANGKEY_LENGTH]
	RZ_SUBCLASS_DESC, // [RZ_MAX_LANGKEY_LENGTH]
	RZ_SUBCLASS_PROPS, // cell
	RZ_SUBCLASS_MODEL, // cell
	RZ_SUBCLASS_SOUND, // cell
	RZ_SUBCLASS_KNIFE, // cell
	RZ_SUBCLASS_NIGHTVISION, // cell
};

native rz_subclass_create(const handle[], class);

native any:rz_subclass_get(playerProps, RZSubclassProp:prop, any:...);
native rz_subclass_set(playerProps, RZSubclassProp:prop, any:...);
native rz_subclass_start();
native rz_subclass_find(const handle[]);
native rz_subclass_size();

native rz_subclass_get_default(class);
native rz_subclass_set_default(class, subclass);

native rz_subclass_player_change(id, subclass);
native rz_subclass_player_get_status(id, subclass);

forward rz_subclass_change_pre(id, subclass);
forward rz_subclass_change_post(id, subclass);



enum RZPlayerPropsProp
{
	RZ_PLAYER_PROPS_HANDLE, // [RZ_MAX_HANDLE_LENGTH]
	RZ_PLAYER_PROPS_HEALTH, // Float
	RZ_PLAYER_PROPS_BASE_HEALTH, // Float
	RZ_PLAYER_PROPS_ARMOR, // Float
	RZ_PLAYER_PROPS_HELMET, // bool
	RZ_PLAYER_PROPS_GRAVITY, // Float
	RZ_PLAYER_PROPS_SPEED, // Float
	RZ_PLAYER_PROPS_FOOTSTEPS, // bool
	RZ_PLAYER_PROPS_VELMOD, // Float
	RZ_PLAYER_PROPS_VELMOD_HEAD, // Float
	RZ_PLAYER_PROPS_KNOCKBACK, // Float
	RZ_PLAYER_PROPS_BLOOD_COLOR, // cell
};

native rz_playerprops_create(const handle[]);
native any:rz_playerprops_get(playerProps, RZPlayerPropsProp:prop, any:...);
native rz_playerprops_set(playerProps, RZPlayerPropsProp:prop, any:...);
native rz_playerprops_valid(playerProps);

native rz_playerprops_player_change(id, playerProps, bool:spawn = false);



native rz_playermodel_create(const handle[]);

native rz_playermodel_get_handle(playerModel, handle[], len);
native rz_playermodel_find(const handle[]);
native rz_playermodel_add(playerModel, const modelName[], bool:defaultHitboxes = false, body = 0);

native rz_playermodel_player_change(id, playerModel, bool:preSpawn = false);



enum RZPainSound
{
	RZ_PAIN_SOUND_NONE = -1,
	RZ_PAIN_SOUND_BHIT_HELMET, // [RZ_MAX_RESOURCE_PATH]
	RZ_PAIN_SOUND_HEADSHOT, // [RZ_MAX_RESOURCE_PATH]
	RZ_PAIN_SOUND_BHIT_KEVLAR, // [RZ_MAX_RESOURCE_PATH]
	RZ_PAIN_SOUND_BHIT_FLESH, // [RZ_MAX_RESOURCE_PATH]
	RZ_PAIN_SOUND_DEATH, // [RZ_MAX_RESOURCE_PATH]
	RZ_MAX_PAIN_SOUNDS,
};

enum RZPlayerSoundProp
{
	RZ_PLAYER_SOUND_HANDLE, // [RZ_MAX_HANDLE_LENGTH]
	RZ_PLAYER_SOUND_SOUNDS_BANK, // [MAX_PAIN_SOUNDS], Array
};

native rz_playersound_create(const handle[]);

native any:rz_playersound_get(playerSound, RZPlayerSoundProp:prop, any:...);
native rz_playersound_set(playerSound, RZPlayerSoundProp:prop, any:...);
native rz_playersound_find(const handle[]);
native rz_playersound_valid(playerSound);

native rz_playersound_add(playerSound, RZPainSound:painSound, const sample[]);



enum RZNightVisionProp
{
	RZ_NIGHTVISION_HANDLE, // [RZ_MAX_HANDLE_LENGTH]
	RZ_NIGHTVISION_EQUIP, // enum RZNightVisionEquip
	RZ_NIGHTVISION_COLOR, // [3]
	RZ_NIGHTVISION_ALPHA, // cell
};

enum RZNightVisionEquip
{
	RZ_NVG_EQUIP_DISABLED,
	RZ_NVG_EQUIP_APPEND,
	RZ_NVG_EQUIP_APPEND_AND_ENABLE,
};

native rz_nightvision_create(const handle[]);

native any:rz_nightvision_get(weapon, RZNightVisionProp:prop, any:...);
native rz_nightvision_set(weapon, RZNightVisionProp:prop, any:...);

native rz_nightvisions_find(const handle[]);

native rz_nightvisions_player_change(id, nightVision, bool:enabled = true);

forward rz_nightvisions_change_pre(id, player, bool:enabled);
forward rz_nightvisions_change_post(id, player, bool:enabled);

//native rz_nightvision_player_update(id = 0);
