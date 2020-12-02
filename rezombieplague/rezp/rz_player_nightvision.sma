#pragma semicolon 1

#include <amxmodx>
#include <reapi>
#include <rezp>
#include <rezp_util>

// bool nvg false in other hooks

enum _:NightVisionData
{
	NightVision_Equip,
	NightVision_Color[3],
	NightVision_Alpha,

}; new Array:g_aNightVisions;

new g_iNightVision[MAX_PLAYERS + 1];
new g_iLastNVG[MAX_PLAYERS + 1];
new bool:g_bNightVision[MAX_PLAYERS + 1];

new g_iIntoGameNVG;
new g_iSpectatorNVG;
new g_iModule;

public plugin_precache()
{
	register_plugin("[ReZP] Player: Night Vision", REZP_VERSION_STR, "fl0wer");

	g_aNightVisions = ArrayCreate(NightVisionData, 0);

	g_iModule = rz_module_create("player_nvg", g_aNightVisions);
	g_iIntoGameNVG = rz_nightvision_create(2, { 0, 0, 0 }, 63);
	g_iSpectatorNVG = rz_nightvision_create(2, { 0, 0, 0 }, 63);
}

public plugin_init()
{
	register_message(get_user_msgid("ScreenFade"), "@MSG_ScreenFade");

	register_clcmd("nightvision", "@Command_NightVision");

	RegisterHookChain(RG_GetForceCamera, "@GetForceCamera_Post", true);
	RegisterHookChain(RG_ShowVGUIMenu, "@ShowVGUIMenu_Post", true);

	RegisterHookChain(RG_CBasePlayer_Spawn, "@CBasePlayer_Spawn_Post", true);
	RegisterHookChain(RG_CBasePlayer_GiveDefaultItems, "@CBasePlayer_GiveDefaultItems_Post", true);
	RegisterHookChain(RG_CBasePlayer_StartObserver, "@CBasePlayer_StartObserver_Post", true);
	RegisterHookChain(RG_CBasePlayer_Observer_IsValidTarget, "@CBasePlayer_Observer_IsValidTarget_Post", true);
}

@MSG_ScreenFade(id, dest, player)
{
	return PLUGIN_HANDLED;
}

@Command_NightVision(id)
{
	if (!is_user_alive(id))
		return PLUGIN_HANDLED;

	if (!get_member(id, m_bHasNightVision))
		return PLUGIN_HANDLED;

	new Float:time = get_gametime();

	if (get_member(id, m_flLastCommandTime, CMD_NIGHTVISION) <= time)
	{
		set_member(id, m_flLastCommandTime, time + 0.3, CMD_NIGHTVISION);

		if (g_bNightVision[id])
		{
			rh_emit_sound2(id, 0, CHAN_ITEM, "items/nvg_off.wav", random_float(0.92, 1.0), ATTN_NORM);
			SetNightVisionEnabled(id, false);
		}
		else
		{
			rh_emit_sound2(id, 0, CHAN_ITEM, "items/nvg_on.wav", random_float(0.92, 1.0), ATTN_NORM);
			SetNightVisionEnabled(id, true);
		}
	}

	return PLUGIN_HANDLED;
}

@GetForceCamera_Post(id)
{
	if (!g_bNightVision[id])
		return;

	RequestFrame("@RequestFrame_UpdateNightVision", id);
}

@RequestFrame_UpdateNightVision(id)
{
	if (!is_user_connected(id))
		return;

	if (!g_iNightVision[id])
		g_iNightVision[id] = g_iSpectatorNVG;

	if (get_entvar(id, var_iuser1) == OBS_IN_EYE)
		g_iNightVision[id] = g_iLastNVG[id];
	else
		g_iNightVision[id] = g_iSpectatorNVG;

	SetNightVisionEnabled(id, true);
}

@ShowVGUIMenu_Post(id, VGUIMenu:menuType, bitsSlots, oldMenu[])
{
	if (menuType != VGUI_Menu_Team)
		return;

	if (get_member(id, m_iJoiningState) == JOINED)
		return;

	g_iNightVision[id] = g_iIntoGameNVG;

	set_member(id, m_bHasNightVision, true);
	SetNightVisionEnabled(id, true);
}

@CBasePlayer_Spawn_Post(id)
{
	if (get_member(id, m_bJustConnected))
		return;

	if (TEAM_TERRORIST > get_member(id, m_iTeam) > TEAM_CT)
		return;

	SetNightVisionEnabled(id, false);
}

@CBasePlayer_GiveDefaultItems_Post(id)
{
	ChangeNightVision(id);
}

@CBasePlayer_StartObserver_Post(id, Float:vecPosition[3], Float:vecViewAngle[3])
{
	g_bNightVision[id] = true;

	set_member(id, m_bHasNightVision, true);
}

@CBasePlayer_Observer_IsValidTarget_Post(id, player, bool:sameTeam)
{
	if (GetHookChainReturn(ATYPE_INTEGER) != player)
		return;

	g_iLastNVG[id] = rz_nightvision_player_get(player);
}

SetNightVisionEnabled(id, bool:enable)
{
	if (enable)
	{
		new index = rz_module_get_valid_index(g_iModule, g_iNightVision[id]);

		if (index != -1)
		{
			new data[NightVisionData];
			ArrayGetArray(g_aNightVisions, index, data);

			new color[3];

			for (new i = 0; i < 3; i++)
				color[i] = data[NightVision_Color][i];

			g_bNightVision[id] = true;

			UTIL_LightStyle(id, 0, fmt("%c", rz_main_lighting_nvg_get()));
			UTIL_ScreenFade(id, color, 0.0, 0.001, data[NightVision_Alpha], (FFADE_OUT | FFADE_STAYOUT));

			// cicle players
		}
	}
	else
	{
		g_bNightVision[id] = false;

		UTIL_LightStyle(id, 0, fmt("%c", rz_main_lighting_global_get()));
		UTIL_ScreenFade(id, { 0, 0, 0 }, 0.001);
	}
}

ChangeNightVision(id)
{
	new nightvision = g_iNightVision[id];

	if (nightvision)
	{
		new index = rz_module_get_valid_index(g_iModule, g_iNightVision[id]);

		if (index == -1)
			return false;

		new data[NightVisionData];
		ArrayGetArray(g_aNightVisions, index, data);

		set_member(id, m_bHasNightVision, data[NightVision_Equip] ? true : false);
		SetNightVisionEnabled(id, data[NightVision_Equip] == 2 ? true : false);
	}
	else
	{
		set_member(id, m_bHasNightVision, false);
		SetNightVisionEnabled(id, false);
	}

	return true;
}

public plugin_natives()
{
	register_native("rz_nightvision_create", "@native_nightvision_create");

	register_native("rz_nightvision_get_equip", "@native_nightvision_get_equip");
	register_native("rz_nightvision_get_color", "@native_nightvision_get_color");
	register_native("rz_nightvision_get_alpha", "@native_nightvision_get_alpha");

	register_native("rz_nightvision_player_get", "@native_nightvision_player_get");
	register_native("rz_nightvision_player_set", "@native_nightvision_player_set");
	register_native("rz_nightvision_player_change", "@native_nightvision_player_change");
	register_native("rz_nightvision_player_update", "@native_nightvision_player_update");
}

@native_nightvision_create(plugin, argc)
{
	enum { arg_equip = 1, arg_color, arg_alpha };

	new data[NightVisionData];

	data[NightVision_Equip] = get_param(arg_equip);
	get_array(arg_color, data[NightVision_Color], sizeof(data[NightVision_Color]));
	data[NightVision_Alpha] = get_param(arg_alpha);
	
	return ArrayPushArray(g_aNightVisions, data) + rz_module_get_offset(g_iModule);
}

@native_nightvision_get_equip(plugin, argc)
{
	enum { arg_nightvision = 1 };

	new nightvision = get_param(arg_nightvision);
	new index = rz_module_get_valid_index(g_iModule, nightvision);

	CHECK_MODULE_VALID_INDEX(index, 0)

	new data[NightVisionData];
	ArrayGetArray(g_aNightVisions, index, data);

	return data[NightVision_Equip];
}

@native_nightvision_get_color(plugin, argc)
{
	enum { arg_nightvision = 1, arg_color };

	new nightvision = get_param(arg_nightvision);
	new index = rz_module_get_valid_index(g_iModule, nightvision);

	CHECK_MODULE_VALID_INDEX(index, 0)

	new data[NightVisionData];
	ArrayGetArray(g_aNightVisions, index, data);

	set_array(arg_color, data[NightVision_Color], sizeof(data[NightVision_Color]));
	return true;
}

@native_nightvision_get_alpha(plugin, argc)
{
	enum { arg_nightvision = 1 };

	new nightvision = get_param(arg_nightvision);
	new index = rz_module_get_valid_index(g_iModule, nightvision);

	CHECK_MODULE_VALID_INDEX(index, 0)

	new data[NightVisionData];
	ArrayGetArray(g_aNightVisions, index, data);

	return data[NightVision_Alpha];
}

@native_nightvision_player_get(plugin, argc)
{
	enum { arg_player = 1 };

	new player = get_param(arg_player);

	return g_iNightVision[player];
}

@native_nightvision_player_set(plugin, argc)
{
	enum { arg_player = 1, arg_nightvision };

	new player = get_param(arg_player);
	new nightvision = get_param(arg_nightvision);

	g_iNightVision[player] = nightvision;
	return true;
}

@native_nightvision_player_change(plugin, argc)
{
	enum { arg_player = 1 };

	new player = get_param(arg_player);
	CHECK_CONNECTED(player, false)

	return ChangeNightVision(player);
}

@native_nightvision_player_update(plugin, argc)
{
	enum { arg_player = 1 };

	new player = get_param(arg_player);

	if (player)
	{
		SetNightVisionEnabled(player, g_bNightVision[player]);
	}
	else
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (!is_user_connected(i))
				continue;

			SetNightVisionEnabled(i, g_bNightVision[i]);
		}
	}

	return true;
}
