#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <reapi>
#include <rezp>

new const DEFAULT_PLAYERMODEL[TeamName][] = { "", "leet", "gign", "" };

enum _:PlayerModelHeader
{
	PlayerModel_ModelName[RZ_MAX_PLAYER_MODEL_LENGTH],
	PlayerModel_ModelIndex,
	PlayerModel_Body,
};

enum _:PlayerModelData
{
	PlayerModel_Handle[RZ_MAX_HANDLE_LENGTH],
	Array:PlayerModel_Models,

}; new Array:g_aPlayerModels;

new gLocalData[PlayerModelData];

new g_iDefaultPlayerModel[TeamName];

new g_iModule;

public plugin_precache()
{
	register_plugin("[ReZP] API: Player Models", REZP_VERSION_STR, "fl0wer");
	
	g_aPlayerModels = ArrayCreate(PlayerModelData, 0);
	g_iModule = rz_module_create("player_models", g_aPlayerModels);

	new const playerModelNames[TeamName][] = { "", "playermodel_default_tr", "playermodel_default_ct", "" };

	for (new TeamName:i = TEAM_TERRORIST; i <= TEAM_CT; i++)
	{
		g_iDefaultPlayerModel[i] = rz_playermodel_create(playerModelNames[i]);
		rz_playermodel_add(g_iDefaultPlayerModel[i], DEFAULT_PLAYERMODEL[i]);
	}
}

public plugin_natives()
{
	register_native("rz_playermodel_create", "@native_playermodel_create");

	register_native("rz_playermodel_get_handle", "@native_playermodel_get_handle");
	register_native("rz_playermodel_find", "@native_playermodel_find");
	register_native("rz_playermodel_add", "@native_playermodel_add");

	register_native("rz_playermodel_player_change", "@native_playermodel_player_change");
}

@native_playermodel_create(plugin, argc)
{
	enum { arg_handle = 1 };

	new data[PlayerModelData];

	get_string(arg_handle, data[PlayerModel_Handle], charsmax(data[PlayerModel_Handle]));
	data[PlayerModel_Models] = ArrayCreate(PlayerModelHeader, 0);

	return ArrayPushArray(g_aPlayerModels, data) + rz_module_get_offset(g_iModule);
}

@native_playermodel_get_handle(plugin, argc)
{
	enum { arg_player_model = 1, arg_handle, arg_len };

	new playerModel = get_param(arg_player_model);
	new index = rz_module_get_valid_index(g_iModule, playerModel);

	RZ_CHECK_MODULE_VALID_INDEX(index, false)
	
	ArrayGetArray(g_aPlayerModels, index, gLocalData);

	set_string(arg_handle, gLocalData[PlayerModel_Handle], get_param(arg_len));
	return true;
}

@native_playermodel_find(plugin, argc)
{
	enum { arg_handle = 1 };

	new handle[RZ_MAX_HANDLE_LENGTH];
	get_string(arg_handle, handle, charsmax(handle));

	new i = ArrayFindString(g_aPlayerModels, handle);

	if (i != -1)
		return i + rz_module_get_offset(g_iModule);

	return 0;
}

@native_playermodel_add(plugin, argc)
{
	enum { arg_player_model = 1, arg_model_name, arg_default_hitboxes, arg_body };

	new playerModel = get_param(arg_player_model);
	new index = rz_module_get_valid_index(g_iModule, playerModel);

	RZ_CHECK_MODULE_VALID_INDEX(index, false)

	new header[PlayerModelHeader];

	ArrayGetArray(g_aPlayerModels, index, gLocalData);

	get_string(arg_model_name, header[PlayerModel_ModelName], charsmax(header[PlayerModel_ModelName]));
	header[PlayerModel_Body] = get_param(arg_body);

	if (get_param(arg_default_hitboxes))
		header[PlayerModel_ModelIndex] = precache_model("models/player.mdl");
	else
		header[PlayerModel_ModelIndex] = precache_model(fmt("models/player/%s/%s.mdl", header[PlayerModel_ModelName], header[PlayerModel_ModelName]));

	ArrayPushArray(gLocalData[PlayerModel_Models], header);
	return true;
}

@native_playermodel_player_change(plugin, argc)
{
	enum { arg_player = 1, arg_player_model, arg_pre_spawn };

	new player = get_param(arg_player);
	RZ_CHECK_CONNECTED(player, false)

	new playerModel = get_param(arg_player_model);
	new index = rz_module_get_valid_index(g_iModule, playerModel);

	RZ_CHECK_MODULE_VALID_INDEX(index, false)

	new headerId = -1;

	if (index != -1)
	{
		ArrayGetArray(g_aPlayerModels, index, gLocalData);

		new modelsNum = ArraySize(gLocalData[PlayerModel_Models]);

		if (modelsNum)
			headerId = random_num(0, modelsNum - 1);
	}

	if (headerId == -1)
	{
		index = rz_module_get_valid_index(g_iModule, g_iDefaultPlayerModel[get_member(player, m_iTeam)]);
		headerId = 0;

		ArrayGetArray(g_aPlayerModels, index, gLocalData);
	}

	new bool:preSpawn = any:get_param(arg_pre_spawn);
	new header[PlayerModelHeader];

	ArrayGetArray(gLocalData[PlayerModel_Models], headerId, header);

	if (preSpawn)
	{
		set_member(player, m_szModel, header[PlayerModel_ModelName]);
		set_member(player, m_modelIndexPlayer, header[PlayerModel_ModelIndex]);
		set_entvar(player, var_modelindex, header[PlayerModel_ModelIndex]);
		set_entvar(player, var_body, header[PlayerModel_Body]);
	}
	else
	{
		rg_set_user_model(player, header[PlayerModel_ModelName]);
		
		set_member(player, m_modelIndexPlayer, header[PlayerModel_ModelIndex]);
		set_entvar(player, var_body, header[PlayerModel_Body]);
	}

	return true;
}
