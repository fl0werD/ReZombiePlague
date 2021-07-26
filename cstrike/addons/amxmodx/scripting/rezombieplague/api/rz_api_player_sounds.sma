#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <reapi>
#include <rezp>

enum _:PlayerSoundData
{
	PlayerSound_Handle[RZ_MAX_HANDLE_LENGTH],
	Array:PlayerSound_SoundsBank[RZ_MAX_PAIN_SOUNDS],

}; new Array:g_aPlayerSounds;

new gPlayerSoundData[PlayerSoundData];

new g_iModule;

public plugin_precache()
{
	register_plugin("[ReZP] API: Player Sounds", REZP_VERSION_STR, "fl0wer");

	g_aPlayerSounds = ArrayCreate(PlayerSoundData, 0);
	g_iModule = rz_module_create("player_sounds", g_aPlayerSounds);
}

public plugin_natives()
{
	register_native("rz_playersound_create", "@native_playersound_create");
	register_native("rz_playersound_get", "@native_playersound_get");
	register_native("rz_playersound_set", "@native_playersound_set");
	register_native("rz_playersound_find", "@native_playersound_find");
	register_native("rz_playersound_valid", "@native_playersound_valid");

	register_native("rz_playersound_add", "@native_playersound_add");
}

@native_playersound_create(plugin, argc)
{
	enum { arg_handle = 1 };

	new data[PlayerSoundData];

	get_string(arg_handle, data[PlayerSound_Handle], charsmax(data[PlayerSound_Handle]));

	for (new any:i = 0; i < RZ_MAX_PAIN_SOUNDS; i++)
		data[PlayerSound_SoundsBank][i] = ArrayCreate(RZ_MAX_RESOURCE_PATH, 0);

	return ArrayPushArray(g_aPlayerSounds, data) + rz_module_get_offset(g_iModule);
}

@native_playersound_get_handle(plugin, argc)
{
	enum { arg_player_sound = 1, arg_handle, arg_len };

	new playerSound = get_param(arg_player_sound);
	new index = rz_module_get_valid_index(g_iModule, playerSound);

	RZ_CHECK_MODULE_VALID_INDEX(index, false)
	
	ArrayGetArray(g_aPlayerSounds, index, gPlayerSoundData);

	set_string(arg_handle, gPlayerSoundData[PlayerSound_Handle], get_param(arg_len));
	return true;
}

@native_playersound_get(plugin, argc)
{
	enum { arg_player_sound = 1, arg_prop, arg_3, arg_4 };

	new playerSound = get_param(arg_player_sound);
	new index = rz_module_get_valid_index(g_iModule, playerSound);

	RZ_CHECK_MODULE_VALID_INDEX(index, false)
	
	ArrayGetArray(g_aPlayerSounds, index, gPlayerSoundData);

	new prop = get_param(arg_prop);

	switch (prop)
	{
		case RZ_PLAYER_SOUND_HANDLE:
		{
			set_string(arg_3, gPlayerSoundData[PlayerSound_Handle], get_param_byref(arg_4));
		}
		case RZ_PLAYER_SOUND_SOUNDS_BANK:
		{
			new RZPainSound:painSound = any:get_param_byref(arg_3);
			
			return any:gPlayerSoundData[PlayerSound_SoundsBank][painSound];
		}
		default:
		{
			rz_log(true, "Player sound property '%d' not found for '%s'", prop, gPlayerSoundData[PlayerSound_Handle]);
			return false;
		}
	}

	return true;
}

@native_playersound_set(plugin, argc)
{
	enum { arg_player_sound = 1, arg_prop, arg_3, arg_element };

	new playerSound = get_param(arg_player_sound);
	new index = rz_module_get_valid_index(g_iModule, playerSound);

	RZ_CHECK_MODULE_VALID_INDEX(index, false)
	
	ArrayGetArray(g_aPlayerSounds, index, gPlayerSoundData);

	new prop = get_param(arg_prop);

	switch (prop)
	{
		case RZ_PLAYER_SOUND_HANDLE:
		{
			//get_string(arg_3, gPlayerSoundData[PlayerSound_Handle], charsmax(gPlayerSoundData[PlayerSound_Handle]));
		}
		case RZ_PLAYER_SOUND_SOUNDS_BANK:
		{
			new RZPainSound:painSound = any:get_param_byref(arg_element);

			gPlayerSoundData[PlayerSound_SoundsBank][painSound] = any:get_param_byref(arg_3);
		}
		default:
		{
			rz_log(true, "Player sound property '%d' not found for '%s'", prop, gPlayerSoundData[PlayerSound_Handle]);
			return false;
		}
	}

	ArraySetArray(g_aPlayerSounds, index, gPlayerSoundData);
	return true;
}

@native_playersound_find(plugin, argc)
{
	enum { arg_handle = 1 };

	new handle[RZ_MAX_HANDLE_LENGTH];
	get_string(arg_handle, handle, charsmax(handle));

	new i = ArrayFindString(g_aPlayerSounds, handle);

	if (i != -1)
		return i + rz_module_get_offset(g_iModule);

	return 0;
}

@native_playersound_valid(plugin, argc)
{
	enum { arg_player_sound = 1 };

	new playerSound = get_param(arg_player_sound);

	if (!playerSound)
		return false;

	return (rz_module_get_valid_index(g_iModule, playerSound) != -1);
}

@native_playersound_add(plugin, argc)
{
	enum { arg_player_sound = 1, arg_pain_sound, arg_sample };

	new playerSound = get_param(arg_player_sound);
	new index = rz_module_get_valid_index(g_iModule, playerSound);

	RZ_CHECK_MODULE_VALID_INDEX(index, false)

	new RZPainSound:painSound = any:get_param(arg_pain_sound);
	new sample[RZ_MAX_RESOURCE_PATH];
	get_string(arg_sample, sample, charsmax(sample));

	precache_sound(sample);

	ArrayGetArray(g_aPlayerSounds, index, gPlayerSoundData);

	ArrayPushString(gPlayerSoundData[PlayerSound_SoundsBank][painSound], sample);
	return true;
}
