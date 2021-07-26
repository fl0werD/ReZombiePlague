#if defined _rezp_gamemode_included
	#endinput
#endif

#define _rezp_gamemode_included

enum RZGameModesProp
{
	RZ_GAMEMODES_DEFAULT,
	RZ_GAMEMODES_CURRENT,
	RZ_GAMEMODES_LAST,
	RZ_GAMEMODES_FORCE,
};

enum RZGameModeProp
{
	RZ_GAMEMODE_HANDLE, // [RZ_MAX_HANDLE_LENGTH]
	RZ_GAMEMODE_NAME, // [RZ_MAX_LANGKEY_LENGTH]
	RZ_GAMEMODE_NOTICE, // [RZ_MAX_LANGKEY_LENGTH]
	RZ_GAMEMODE_HUD_COLOR, // [3]
	RZ_GAMEMODE_CHANCE, // cell
	RZ_GAMEMODE_MIN_ALIVES, // cell
	RZ_GAMEMODE_ROUND_TIME, // cell
	RZ_GAMEMODE_CHANGE_CLASS, // bool
	RZ_GAMEMODE_DEATHMATCH, // cell
};

enum RZGameModeDeathmatch
{
	RZ_GM_DEATHMATCH_DISABLED,
	RZ_GM_DEATHMATCH_ONLY_TR,
	RZ_GM_DEATHMATCH_ONLY_CT,
	RZ_GM_DEATHMATCH_RANDOM,
	RZ_GM_DEATHMATCH_BALANCE,
};

native rz_gamemode_create(const handle[]);

native any:rz_gamemode_get(gameMode, RZGameModeProp:prop, any:...);
native rz_gamemode_set(gameMode, RZGameModeProp:prop, any:...);

native any:rz_gamemodes_get(RZGameModesProp:prop, any:...);
native rz_gamemodes_set(RZGameModesProp:prop, any:...);
native rz_gamemodes_start();
native rz_gamemodes_find(const handle[]);
native rz_gamemodes_size();
native rz_gamemodes_change(gameMode);
native rz_gamemodes_get_status(gameMode, bool:force = false);

forward rz_gamemodes_change_pre(gameMode, alivesNum, bool:force);
forward rz_gamemodes_change_post(gameMode, Array:alivesArray);
