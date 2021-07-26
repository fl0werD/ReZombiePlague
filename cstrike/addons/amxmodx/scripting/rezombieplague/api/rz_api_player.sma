#pragma semicolon 1

#include <amxmodx>
#include <rezp>

new gPlayer[MAX_PLAYERS + 1][RZPlayerProp];

new Trie:g_tChosenSubclass[MAX_PLAYERS + 1];

public plugin_precache()
{
	register_plugin("[ReZP] API: Player", REZP_VERSION_STR, "fl0wer");
	
	for (new i = 1; i <= MaxClients; i++)
		g_tChosenSubclass[i] = TrieCreate();
}

ClassToStr(class)
{
	new key[12];
	num_to_str(class, key, charsmax(key));

	return key;
}

public plugin_natives()
{
	PlayerNatives();
}

PlayerNatives()
{
	register_native("rz_player_get", "@native_player_get");
	register_native("rz_player_set", "@native_player_set");
}

@native_player_get(plugin, argc)
{
	enum { arg_player = 1, arg_prop, arg_3 };

	new player = get_param(arg_player);
	RZ_CHECK_CONNECTED(player, 0)

	new RZPlayerProp:prop = any:get_param(arg_prop);

	switch (prop)
	{
		case RZ_PLAYER_CLASS, RZ_PLAYER_SUBCLASS, RZ_PLAYER_PROPS, RZ_PLAYER_MODEL, RZ_PLAYER_SOUND, RZ_PLAYER_KNIFE,
			RZ_PLAYER_NIGHTVISION, RZ_PLAYER_HAS_NIGHTVISION, RZ_PLAYER_NIGHTVISION_ENABLED:
		{
			return gPlayer[player][prop];
		}
		case RZ_PLAYER_SUBCLASS_CHOSEN:
		{
			new value;
			TrieGetCell(g_tChosenSubclass[player], ClassToStr(get_param_byref(arg_3)), value);

			return value;
		}
		default:
		{
			rz_log(true, "Player property '%d' not found", prop);
			return false;
		}
	}

	return true;
}

@native_player_set(plugin, argc)
{
	enum { arg_player = 1, arg_prop, arg_3, arg_element };

	new player = get_param(arg_player);
	RZ_CHECK_CONNECTED(player, 0)

	new RZPlayerProp:prop = any:get_param(arg_prop);

	switch (prop)
	{
		case RZ_PLAYER_CLASS, RZ_PLAYER_SUBCLASS, RZ_PLAYER_PROPS, RZ_PLAYER_MODEL, RZ_PLAYER_SOUND, RZ_PLAYER_KNIFE,
			RZ_PLAYER_NIGHTVISION, RZ_PLAYER_HAS_NIGHTVISION, RZ_PLAYER_NIGHTVISION_ENABLED:
		{
			gPlayer[player][prop] = get_param_byref(arg_3);
		}
		case RZ_PLAYER_SUBCLASS_CHOSEN:
		{
			new subclass = get_param_byref(arg_3);
			new class = get_param_byref(arg_element);

			if (!subclass)
				TrieDeleteKey(g_tChosenSubclass[player], ClassToStr(class));
			else
				TrieSetCell(g_tChosenSubclass[player], ClassToStr(class), subclass);
		}
		default:
		{
			rz_log(true, "Player property '%d' not found", prop);
			return false;
		}
	}

	return true;
}
