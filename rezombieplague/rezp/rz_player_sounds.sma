#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <reapi>
#include <rezp>

const PlayerPainSound:PlayerPainSoundNone = any:-1;

enum _:PlayerSoundData
{
	PlayerSound_Name[32],
	Array:PlayerSound_Sounds[MAX_PL_PAIN_SOUNDS],

}; new Array:g_aPlayerSounds;

new g_iPlayerSound[MAX_PLAYERS + 1];

new g_iModule;

public plugin_precache()
{
	register_plugin("[ReZP] Player: Sounds", REZP_VERSION_STR, "fl0wer");

	g_aPlayerSounds = ArrayCreate(PlayerSoundData, 0);
	g_iModule = rz_module_create("player_sounds", g_aPlayerSounds);
}

public plugin_init()
{
	RegisterHookChain(RH_SV_StartSound, "@SV_StartSound_Pre", false);
}

@SV_StartSound_Pre(recipients, entity, channel, sample[], volume, Float:attenuation, flags, pitch)	
{
	if (sample[0] != 'p' || sample[1] != 'l' || sample[2] != 'a')
		return;

	if (!is_user_connected(entity))
		return;

	new PlayerPainSound:painSound = PlayerPainSoundNone;

	if (sample[7] == 'b' && sample[8] == 'h' && sample[9] == 'i' && sample[10] == 't')
	{
		switch (sample[12])
		{
			case 'h': painSound = PL_PAIN_SOUND_BHIT_HELMET;
			case 'k': painSound = PL_PAIN_SOUND_BHIT_KEVLAR;
			case 'f': painSound = PL_PAIN_SOUND_BHIT_FLESH;
		}
	}
	else if (sample[7] == 'h' && sample[8] == 'e' && sample[9] == 'a')
	{
		painSound = PL_PAIN_SOUND_HEADSHOT;
	}
	else if (sample[7] == 'd' && ((sample[8] == 'i' && sample[9] == 'e') || (sample[8] == 'e' && sample[9] == 'a')))
	{
		painSound = PL_PAIN_SOUND_DEATH;
	}

	if (painSound == PlayerPainSoundNone)
		return;

	new index = rz_module_get_valid_index(g_iModule, g_iPlayerSound[entity]);

	if (index != -1)
	{
		new data[PlayerSoundData];
		ArrayGetArray(g_aPlayerSounds, index, data);

		new soundsSize = ArraySize(data[PlayerSound_Sounds][painSound]);

		if (soundsSize)
		{
			new sound[MAX_QPATH];
			ArrayGetString(data[PlayerSound_Sounds][painSound], random_num(0, soundsSize - 1), sound, charsmax(sound));

			SetHookChainArg(4, ATYPE_STRING, sound);
		}
	}
}

public plugin_natives()
{
	register_native("rz_playersound_create", "@native_playersound_create");
	register_native("rz_playersound_add", "@native_playersound_add");

	//register_native("rz_playersound_get_name", "@native_playersound_get_name");
	register_native("rz_playersound_find", "@native_playersound_find");

	register_native("rz_playersound_player_get", "@native_playersound_player_get");
	register_native("rz_playersound_player_set", "@native_playersound_player_set");
}

@native_playersound_create(plugin, argc)
{
	enum { arg_name = 1 };

	new data[PlayerSoundData];

	get_string(arg_name, data[PlayerSound_Name], charsmax(data[PlayerSound_Name]));

	for (new any:i = 0; i < MAX_PL_PAIN_SOUNDS; i++)
		data[PlayerSound_Sounds][i] = ArrayCreate(MAX_QPATH, 0);

	return ArrayPushArray(g_aPlayerSounds, data) + rz_module_get_offset(g_iModule);
}

@native_playersound_add(plugin, argc)
{
	enum { arg_player_sound = 1, arg_pain_sound, arg_sample };

	new playerSound = get_param(arg_player_sound);
	new index = rz_module_get_valid_index(g_iModule, playerSound);

	CHECK_MODULE_VALID_INDEX(index, false)

	new PlayerPainSound:painSound = any:get_param(arg_pain_sound);
	new sample[MAX_QPATH];
	get_string(arg_sample, sample, charsmax(sample));

	precache_sound(sample);

	new data[PlayerSoundData];
	ArrayGetArray(g_aPlayerSounds, index, data);

	ArrayPushString(data[PlayerSound_Sounds][painSound], sample);
	return true;
}

@native_playersound_find(plugin, argc)
{
	enum { arg_name = 1 };

	new name[32];
	get_string(arg_name, name, charsmax(name));

	new i = ArrayFindString(g_aPlayerSounds, name);

	if (i != -1)
		return i + rz_module_get_offset(g_iModule);

	return 0;
}

@native_playersound_player_get(plugin, argc)
{
	enum { arg_player = 1 };

	new player = get_param(arg_player);

	return g_iPlayerSound[player];
}

@native_playersound_player_set(plugin, argc)
{
	enum { arg_player = 1, arg_player_sound };

	new player = get_param(arg_player);
	new playerSound = get_param(arg_player_sound);

	g_iPlayerSound[player] = playerSound;

	return true;
}
