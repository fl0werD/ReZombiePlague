#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <reapi>
#include <rezp>
#include <util_messages>
#include <util_tempentities>

enum _:ClassData
{
	Class_Name[32],
	TeamName:Class_Team,
	Class_NameLangKey[32],
	Class_HudColor[3],
	Class_Props,
	Class_PlayerModel,
	Class_PlayerSound,
	Class_Melee,
	Class_NightVision,

}; new Array:g_aClasses;

enum _:Forwards
{
	Fw_Return,
	Fw_Class_Change_Pre,
	Fw_Class_Change_Post,

}; new gForwards[Forwards];

new g_iClass[MAX_PLAYERS + 1];

new g_iDefaultClass[TeamName];
new g_iDefaultClassOverride[TeamName];

new g_iModule;

new Float:mp_round_restart_delay;

public plugin_precache()
{
	register_plugin("[ReZP] Player: Class", REZP_VERSION_STR, "fl0wer");

	g_aClasses = ArrayCreate(ClassData, 0);
	g_iModule = rz_module_create("player_class", g_aClasses);
}

public plugin_init()
{
	RegisterHookChain(RG_CBasePlayer_Spawn, "@CBasePlayer_Spawn_Pre", false);

	gForwards[Fw_Class_Change_Pre] = CreateMultiForward("rz_class_change_pre", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL);
	gForwards[Fw_Class_Change_Post] = CreateMultiForward("rz_class_change_post", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL);
	
	bind_pcvar_float(get_cvar_pointer("mp_round_restart_delay"), mp_round_restart_delay);

	rz_load_langs("class");
}

public plugin_cfg()
{
	if (!g_iDefaultClass[TEAM_TERRORIST] || !g_iDefaultClass[TEAM_CT])
		set_fail_state("No loaded default classes");
}

@CBasePlayer_Spawn_Pre(id)
{
	if (get_member(id, m_bJustConnected))
		return;

	if (TEAM_TERRORIST > get_member(id, m_iTeam) > TEAM_CT)
		return;

	ChangeClass(id, id, g_iClass[id], true);
}

ChangeClass(id, attacker, class, bool:preSpawn = false)
{
	new index = rz_module_get_valid_index(g_iModule, class);

	if (index == -1)
		return false;

	ExecuteForward(gForwards[Fw_Class_Change_Pre], gForwards[Fw_Return], id, attacker, class);

	if (gForwards[Fw_Return] >= RZ_SUPERCEDE)
		return false;

	new data[ClassData];
	ArrayGetArray(g_aClasses, index, data);

	rz_subclass_player_set(id, 0);
	rz_props_player_set(id, data[Class_Props]);
	rz_playermodel_player_set(id, data[Class_PlayerModel]);
	rz_playersound_player_set(id, data[Class_PlayerSound]);
	rz_melee_player_set(id, data[Class_Melee]);
	rz_nightvision_player_set(id, data[Class_NightVision]);
	
	if (preSpawn)
	{
		set_member(id, m_iTeam, data[Class_Team]);
	}
	else
	{
		g_iClass[id] = class;
		
		if (attacker)
		{
			SendDeathMsg(attacker, id, 0, "teammate");
			SendScoreAttrib(id, 0);

			rg_set_user_team(id, data[Class_Team]);

			ExecuteHamB(Ham_AddPoints, id, 0, true);
			ExecuteHamB(Ham_AddPoints, attacker, 1, true);

			set_member(id, m_iDeaths, get_member(id, m_iDeaths) + 1);
		}
		else
		{
			rg_set_user_team(id, data[Class_Team]);

			SendDeathMsg(id, id, 0, "teammate");
			SendScoreAttrib(id, 0);
		}

		rg_give_default_items(id);

		if (data[Class_Team] == TEAM_TERRORIST)
			InfectionEffects(id);
	}

	ExecuteForward(gForwards[Fw_Class_Change_Post], gForwards[Fw_Return], id, attacker, class);

	if (get_member_game(m_bGameStarted) && !get_member_game(m_bFreezePeriod))
		RequestFrame("@RequestFrame_CheckChangeClassWinConditions");

	return true;
}

@RequestFrame_CheckChangeClassWinConditions()
{
	if (get_member_game(m_iRoundWinStatus) != WINSTATUS_NONE)
		return;

	new numAliveTR, numAliveCT, numDeadTR, numDeadCT;
	rg_initialize_player_counts(numAliveTR, numAliveCT, numDeadTR, numDeadCT);

	if (numAliveTR + numAliveCT + numDeadTR + numDeadCT >= 2)
	{
		if (!numAliveTR)
			rg_round_end(mp_round_restart_delay, WINSTATUS_CTS, ROUND_CTS_WIN, .trigger = true);
		else if (!numAliveCT)
			rg_round_end(mp_round_restart_delay, WINSTATUS_TERRORISTS, ROUND_TERRORISTS_WIN, .trigger = true);
	}
}

public plugin_natives()
{
	register_native("rz_class_create", "@native_class_create");

	register_native("rz_class_get_name", "@native_class_get_name");
	register_native("rz_class_get_team", "@native_class_get_team");

	register_native("rz_class_get_name_langkey", "@native_class_get_name_langkey");
	register_native("rz_class_set_name_langkey", "@native_class_set_name_langkey");

	register_native("rz_class_get_hudcolor", "@native_class_get_hudcolor");
	register_native("rz_class_set_hudcolor", "@native_class_set_hudcolor");

	register_native("rz_class_get_props", "@native_class_get_props");
	register_native("rz_class_set_props", "@native_class_set_props");

	register_native("rz_class_get_playermodel", "@native_class_get_playermodel");
	register_native("rz_class_set_playermodel", "@native_class_set_playermodel");

	register_native("rz_class_get_playersound", "@native_class_get_playersound");
	register_native("rz_class_set_playersound", "@native_class_set_playersound");

	register_native("rz_class_get_melee", "@native_class_get_melee");
	register_native("rz_class_set_melee", "@native_class_set_melee");

	register_native("rz_class_get_nightvision", "@native_class_get_nightvision");
	register_native("rz_class_set_nightvision", "@native_class_set_nightvision");

	register_native("rz_class_get_default", "@native_class_get_default");
	register_native("rz_class_set_default", "@native_class_set_default");
	register_native("rz_class_override_default", "@native_class_override_default");

	register_native("rz_class_start", "@native_class_start");
	register_native("rz_class_find", "@native_class_find");
	register_native("rz_class_size", "@native_class_size");

	register_native("rz_class_player_get", "@native_class_player_get");
	register_native("rz_class_player_set", "@native_class_player_set");
	register_native("rz_class_player_change", "@native_class_player_change");
}

@native_class_create(plugin, argc)
{
	enum { arg_name = 1, arg_team };

	new data[ClassData];

	get_string(arg_name, data[Class_Name], charsmax(data[Class_Name]));
	data[Class_Team] = any:get_param(arg_team);

	data[Class_HudColor] = { 255, 255, 255 };

	new TeamName:team = data[Class_Team];

	CHECK_PLAYABLE_TEAM(team, 0)

	new id = ArrayPushArray(g_aClasses, data) + rz_module_get_offset(g_iModule);

	if (!g_iDefaultClass[team])
		g_iDefaultClass[team] = id;

	return id;
}

@native_class_get_name(plugin, argc)
{
	enum { arg_class = 1, arg_name, arg_len };

	new class = get_param(arg_class);
	new index = rz_module_get_valid_index(g_iModule, class);

	CHECK_MODULE_VALID_INDEX(index, false)
	
	new data[ClassData];
	ArrayGetArray(g_aClasses, index, data);

	set_string(arg_name, data[Class_Name], get_param(arg_len));
	return true;
}

@native_class_get_team(plugin, argc)
{
	enum { arg_class = 1 };

	new class = get_param(arg_class);
	new index = rz_module_get_valid_index(g_iModule, class);

	CHECK_MODULE_VALID_INDEX(index, any:TEAM_UNASSIGNED)

	new data[ClassData];
	ArrayGetArray(g_aClasses, index, data);

	return any:data[Class_Team];
}

@native_class_get_name_langkey(plugin, argc)
{
	enum { arg_class = 1, arg_name_lang_key, arg_len };

	new class = get_param(arg_class);
	new index = rz_module_get_valid_index(g_iModule, class);

	CHECK_MODULE_VALID_INDEX(index, false)
	
	new data[ClassData];
	ArrayGetArray(g_aClasses, index, data);

	if (!data[Class_NameLangKey][0])
		return false;

	set_string(arg_name_lang_key, data[Class_NameLangKey], get_param(arg_len));
	return true;
}

@native_class_set_name_langkey(plugin, argc)
{
	enum { arg_class = 1, arg_name_lang_key };

	new class = get_param(arg_class);
	new index = rz_module_get_valid_index(g_iModule, class);

	CHECK_MODULE_VALID_INDEX(index, false)
	
	new data[ClassData];
	ArrayGetArray(g_aClasses, index, data);
	get_string(arg_name_lang_key, data[Class_NameLangKey], charsmax(data[Class_NameLangKey]));
	ArraySetArray(g_aClasses, index, data);

	return true;
}

@native_class_get_hudcolor(plugin, argc)
{
	enum { arg_class = 1, arg_hud_color };

	new class = get_param(arg_class);
	new index = rz_module_get_valid_index(g_iModule, class);

	CHECK_MODULE_VALID_INDEX(index, false)
	
	new data[ClassData];
	ArrayGetArray(g_aClasses, index, data);

	set_array(arg_hud_color, data[Class_HudColor], sizeof(data[Class_HudColor]));
	return true;
}

@native_class_set_hudcolor(plugin, argc)
{
	enum { arg_class = 1, arg_hud_color };

	new class = get_param(arg_class);
	new index = rz_module_get_valid_index(g_iModule, class);

	CHECK_MODULE_VALID_INDEX(index, false)
	
	new data[ClassData];
	ArrayGetArray(g_aClasses, index, data);
	get_array(arg_hud_color, data[Class_HudColor], sizeof(data[Class_HudColor]));
	ArraySetArray(g_aClasses, index, data);

	return true;
}

@native_class_get_props(plugin, argc)
{
	enum { arg_class = 1 };

	new class = get_param(arg_class);
	new index = rz_module_get_valid_index(g_iModule, class);

	CHECK_MODULE_VALID_INDEX(index, 0)

	new data[ClassData];
	ArrayGetArray(g_aClasses, index, data);

	return data[Class_Props];
}

@native_class_set_props(plugin, argc)
{
	enum { arg_class = 1, arg_props };

	new class = get_param(arg_class);
	new index = rz_module_get_valid_index(g_iModule, class);

	CHECK_MODULE_VALID_INDEX(index, 0)

	new data[ClassData];
	ArrayGetArray(g_aClasses, index, data);
	data[Class_Props] = get_param(arg_props);
	ArraySetArray(g_aClasses, index, data);

	return true;
}

@native_class_get_playermodel(plugin, argc)
{
	enum { arg_class = 1 };

	new class = get_param(arg_class);
	new index = rz_module_get_valid_index(g_iModule, class);

	CHECK_MODULE_VALID_INDEX(index, 0)

	new data[ClassData];
	ArrayGetArray(g_aClasses, index, data);

	return data[Class_PlayerModel];
}

@native_class_set_playermodel(plugin, argc)
{
	enum { arg_class = 1, arg_player_model };

	new class = get_param(arg_class);
	new index = rz_module_get_valid_index(g_iModule, class);

	CHECK_MODULE_VALID_INDEX(index, 0)

	new data[ClassData];
	ArrayGetArray(g_aClasses, index, data);
	data[Class_PlayerModel] = get_param(arg_player_model);
	ArraySetArray(g_aClasses, index, data);

	return true;
}

@native_class_get_playersound(plugin, argc)
{
	enum { arg_class = 1 };

	new class = get_param(arg_class);
	new index = rz_module_get_valid_index(g_iModule, class);

	CHECK_MODULE_VALID_INDEX(index, 0)

	new data[ClassData];
	ArrayGetArray(g_aClasses, index, data);

	return data[Class_PlayerSound];
}

@native_class_set_playersound(plugin, argc)
{
	enum { arg_class = 1, arg_player_sound };

	new class = get_param(arg_class);
	new index = rz_module_get_valid_index(g_iModule, class);

	CHECK_MODULE_VALID_INDEX(index, 0)

	new data[ClassData];
	ArrayGetArray(g_aClasses, index, data);
	data[Class_PlayerSound] = get_param(arg_player_sound);
	ArraySetArray(g_aClasses, index, data);

	return true;
}

@native_class_get_melee(plugin, argc)
{
	enum { arg_class = 1 };

	new class = get_param(arg_class);
	new index = rz_module_get_valid_index(g_iModule, class);

	CHECK_MODULE_VALID_INDEX(index, 0)

	new data[ClassData];
	ArrayGetArray(g_aClasses, index, data);

	return data[Class_Melee];
}

@native_class_set_melee(plugin, argc)
{
	enum { arg_class = 1, arg_melee };

	new class = get_param(arg_class);
	new index = rz_module_get_valid_index(g_iModule, class);

	CHECK_MODULE_VALID_INDEX(index, 0)

	new data[ClassData];
	ArrayGetArray(g_aClasses, index, data);
	data[Class_Melee] = get_param(arg_melee);
	ArraySetArray(g_aClasses, index, data);

	return true;
}

@native_class_get_nightvision(plugin, argc)
{
	enum { arg_class = 1 };

	new class = get_param(arg_class);
	new index = rz_module_get_valid_index(g_iModule, class);

	CHECK_MODULE_VALID_INDEX(index, 0)

	new data[ClassData];
	ArrayGetArray(g_aClasses, index, data);

	return data[Class_NightVision];
}

@native_class_set_nightvision(plugin, argc)
{
	enum { arg_class = 1, arg_night_vision };

	new class = get_param(arg_class);
	new index = rz_module_get_valid_index(g_iModule, class);

	CHECK_MODULE_VALID_INDEX(index, 0)

	new data[ClassData];
	ArrayGetArray(g_aClasses, index, data);
	data[Class_NightVision] = get_param(arg_night_vision);
	ArraySetArray(g_aClasses, index, data);

	return true;
}

@native_class_get_default(plugin, argc)
{
	enum { arg_team = 1 };

	new TeamName:team = any:get_param(arg_team);

	CHECK_PLAYABLE_TEAM(team, false)

	if (g_iDefaultClassOverride[team])
		return g_iDefaultClassOverride[team];

	return g_iDefaultClass[team];
}

@native_class_set_default(plugin, argc)
{
	enum { arg_team = 1, arg_class };

	new TeamName:team = any:get_param(arg_team);

	CHECK_PLAYABLE_TEAM(team, false)

	new class = get_param(arg_class);
	new index = rz_module_get_valid_index(g_iModule, class);

	CHECK_MODULE_VALID_INDEX(index, false)

	g_iDefaultClass[team] = class;
	return true;
}

@native_class_override_default(plugin, argc)
{
	enum { arg_team = 1, arg_class };

	new TeamName:team = any:get_param(arg_team);

	CHECK_PLAYABLE_TEAM(team, false)

	new class = get_param(arg_class);

	if (!class)
	{
		g_iDefaultClassOverride[team] = 0;
		return true;
	}

	new index = rz_module_get_valid_index(g_iModule, class);

	CHECK_MODULE_VALID_INDEX(index, false)

	g_iDefaultClassOverride[team] = class;
	return true;
}

@native_class_start(plugin, argc)
{
	return rz_module_get_offset(g_iModule);
}

@native_class_find(plugin, argc)
{
	enum { arg_name = 1 };

	new name[32];
	get_string(arg_name, name, charsmax(name));

	new i = ArrayFindString(g_aClasses, name);

	if (i != -1)
		return i + rz_module_get_offset(g_iModule);

	return 0;
}

@native_class_size(plugin, argc)
{
	return ArraySize(g_aClasses);
}

@native_class_player_get(plugin, argc)
{
	enum { arg_player = 1 };

	new player = get_param(arg_player);

	//CHECK_ALIVE(player, 0)

	return g_iClass[player];
}

@native_class_player_set(plugin, argc)
{
	enum { arg_player = 1, arg_class };

	new player = get_param(arg_player);

	//CHECK_CONNECTED(player, false)

	new class = get_param(arg_class);
	new index = rz_module_get_valid_index(g_iModule, class);

	CHECK_MODULE_VALID_INDEX(index, false)

	g_iClass[player] = class;
	return true;
}

@native_class_player_change(plugin, argc)
{
	enum { arg_player = 1, arg_attacker, arg_class };

	new player = get_param(arg_player);
	CHECK_ALIVE(player, false)

	new attacker = get_param(arg_attacker);
	new class = get_param(arg_class);
	new index = rz_module_get_valid_index(g_iModule, class);

	CHECK_MODULE_VALID_INDEX(index, false)

	return ChangeClass(player, attacker, class);
}

InfectionEffects(id)
{
	//if (get_pcvar_num(cvar_infect_screen_shake))
	{
		message_begin(MSG_ONE, get_user_msgid("ScreenShake"), _, id);
		write_short((1<<12) * 4);
		write_short((1<<12) * 2);
		write_short((1<<12) * 10);
		message_end();
	}
	
	new Float:vecOrigin[3];
	get_entvar(id, var_origin, vecOrigin);
	
	//if (get_pcvar_num(cvar_infect_tracers))
	{
		message_begin_f(MSG_PVS, SVC_TEMPENTITY, vecOrigin);
		TE_Implosion(vecOrigin, 128, 20, 3);
	}
	
	//if (get_pcvar_num(cvar_infect_particles))
	{
		message_begin_f(MSG_PVS, SVC_TEMPENTITY, vecOrigin);
		TE_ParticleBurst(vecOrigin, 50, 70, 3);
	}
	
	new cvar_infect_sparkle_color[3] = { 0, 150, 0 };

	//if (get_pcvar_num(cvar_infect_sparkle))
	{
		message_begin_f(MSG_PVS, SVC_TEMPENTITY, vecOrigin);
		TE_DLight(vecOrigin, 20, cvar_infect_sparkle_color, 2, 0);
	}
}
