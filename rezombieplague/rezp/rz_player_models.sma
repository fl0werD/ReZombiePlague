#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <reapi>
#include <rezp>

new const DEFAULT_PLAYERMODEL[TeamName][] = { "", "leet", "gign", "" };

enum _:PlayerModelData
{
	PlayerModel_Name[32],
	Array:PlayerModel_Models,

}; new Array:g_aPlayerModels;

enum _:PlayerModelHeader
{
	PlayerModel_ModelName[32],
	PlayerModel_ModelIndex,
	PlayerModel_Body,
};

new g_iPlayerModel[MAX_PLAYERS + 1];
new g_iCurRandomBody[MAX_PLAYERS + 1];

new g_iDefaultPlayerModel[TeamName];

new g_iModule;

public plugin_precache()
{
	register_plugin("[ReZP] Player: Models", REZP_VERSION_STR, "fl0wer");
	
	g_aPlayerModels = ArrayCreate(PlayerModelData, 0);
	g_iModule = rz_module_create("player_models", g_aPlayerModels);

	new const playerModelNames[TeamName][] = { "", "playermodel_default_tr", "playermodel_default_ct", "" };

	for (new TeamName:i = TEAM_TERRORIST; i <= TEAM_CT; i++)
	{
		g_iDefaultPlayerModel[i] = rz_playermodel_create(playerModelNames[i]);
		rz_playermodel_add(g_iDefaultPlayerModel[i], DEFAULT_PLAYERMODEL[i]);
	}
}

public plugin_init()
{
	RegisterHookChain(RG_CBasePlayer_Spawn, "@CBasePlayer_Spawn_Pre", false);
	RegisterHookChain(RG_CBasePlayer_Spawn, "@CBasePlayer_Spawn_Post", true);
}

public rz_class_change_post(id, attacker, class)
{
	ChangePlayerModel(id);
}

@CBasePlayer_Spawn_Pre(id)
{
	if (get_member(id, m_bJustConnected))
		return;

	if (TEAM_TERRORIST > get_member(id, m_iTeam) > TEAM_CT)
		return;

	g_iCurRandomBody[id] = -1;

	ChangePlayerModel(id);
}

@CBasePlayer_Spawn_Post(id)
{
	if (!is_user_alive(id))
		return;

	if (g_iCurRandomBody[id] != -1)
	{
		set_entvar(id, var_body, g_iCurRandomBody[id]);
	}
}

ChangePlayerModel(id, bool:preSpawn = false)
{
	new index = rz_module_get_valid_index(g_iModule, g_iPlayerModel[id]);
	new headerId = -1;
	new data[PlayerModelData];

	if (index != -1)
	{
		ArrayGetArray(g_aPlayerModels, index, data);

		new modelsNum = ArraySize(data[PlayerModel_Models]);

		if (modelsNum)
			headerId = random_num(0, modelsNum - 1);
	}

	if (headerId == -1)
	{
		index = rz_module_get_valid_index(g_iModule, g_iDefaultPlayerModel[get_member(id, m_iTeam)]);
		headerId = 0;

		ArrayGetArray(g_aPlayerModels, index, data);
	}

	new header[PlayerModelHeader];
	ArrayGetArray(data[PlayerModel_Models], headerId, header);

	if (preSpawn)
	{
		set_member(id, m_szModel, header[PlayerModel_ModelName]);
		set_member(id, m_modelIndexPlayer, header[PlayerModel_ModelIndex]);
		set_entvar(id, var_modelindex, header[PlayerModel_ModelIndex]);

		g_iCurRandomBody[id] = header[PlayerModel_Body];
	}
	else
	{
		rg_set_user_model(id, header[PlayerModel_ModelName]);
		set_member(id, m_modelIndexPlayer, header[PlayerModel_ModelIndex]);
		set_entvar(id, var_body, header[PlayerModel_Body]);
	}

	return true;
}

public plugin_natives()
{
	register_native("rz_playermodel_create", "@native_playermodel_create");
	register_native("rz_playermodel_add", "@native_playermodel_add");

	register_native("rz_playermodel_get_name", "@native_playermodel_get_name");

	register_native("rz_playermodel_player_get", "@native_playermodel_player_get");
	register_native("rz_playermodel_player_set", "@native_playermodel_player_set");
	register_native("rz_playermodel_player_change", "@native_playermodel_player_change");
}

@native_playermodel_create(plugin, argc)
{
	enum { arg_name = 1 };

	new data[PlayerModelData];

	get_string(arg_name, data[PlayerModel_Name], charsmax(data[PlayerModel_Name]));
	data[PlayerModel_Models] = ArrayCreate(PlayerModelHeader, 0);

	return ArrayPushArray(g_aPlayerModels, data) + rz_module_get_offset(g_iModule);
}

@native_playermodel_add(plugin, argc)
{
	enum { arg_player_model = 1, arg_model_name, arg_default_hitboxes, arg_body };

	new playerModel = get_param(arg_player_model);
	new index = rz_module_get_valid_index(g_iModule, playerModel);

	CHECK_MODULE_VALID_INDEX(index, false)

	new data[PlayerModelData];
	new header[PlayerModelHeader];

	ArrayGetArray(g_aPlayerModels, index, data);

	get_string(arg_model_name, header[PlayerModel_ModelName], charsmax(header[PlayerModel_ModelName]));
	header[PlayerModel_Body] = get_param(arg_body);

	if (get_param(arg_default_hitboxes))
		header[PlayerModel_ModelIndex] = precache_model("models/player.mdl");
	else
		header[PlayerModel_ModelIndex] = precache_model(fmt("models/player/%s/%s.mdl", header[PlayerModel_ModelName], header[PlayerModel_ModelName]));

	ArrayPushArray(data[PlayerModel_Models], header);
	return true;
}

@native_playermodel_get_name(plugin, argc)
{
	enum { arg_player_model = 1, arg_name, arg_len };

	new playerModel = get_param(arg_player_model);
	new index = rz_module_get_valid_index(g_iModule, playerModel);

	CHECK_MODULE_VALID_INDEX(index, false)
	
	new data[PlayerModelData];
	ArrayGetArray(g_aPlayerModels, index, data);

	set_string(arg_name, data[PlayerModel_Name], get_param(arg_len));
	return true;
}

@native_playermodel_player_get(plugin, argc)
{
	enum { arg_player = 1 };

	new player = get_param(arg_player);

	return g_iPlayerModel[player];
}

@native_playermodel_player_set(plugin, argc)
{
	enum { arg_player = 1, arg_player_model };

	new player = get_param(arg_player);
	new playerModel = get_param(arg_player_model);

	g_iPlayerModel[player] = playerModel;
	return true;
}

@native_playermodel_player_change(plugin, argc)
{
	enum { arg_player = 1 };

	new player = get_param(arg_player);
	CHECK_ALIVE(player, false)

	/*new attacker = get_param(arg_attacker);
	new class = get_param(arg_class);
	new index = rz_module_get_valid_index(g_iModule, class);

	CHECK_MODULE_VALID_INDEX(index, false)*/

	return ChangePlayerModel(player);
}
