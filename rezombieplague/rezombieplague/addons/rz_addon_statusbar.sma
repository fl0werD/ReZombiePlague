#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <reapi>
#include <rezp>

enum
{
	PLAYERID_MODE_EVERYONE,
	PLAYERID_MODE_TEAMONLY,
	PLAYERID_MODE_OFF,
};

enum
{
	SBAR_TARGETTYPE_TEAMMATE = 1,
	SBAR_TARGETTYPE_ENEMY,
	SBAR_TARGETTYPE_HOSTAGE,
};

enum
{
	SBAR_TARGET_TYPE,
	SBAR_TARGET_ID,
	SBAR_TARGET_CLASS,
	SBAR_TARGET_SUBCLASS,
	SBAR_TARGET_HEALTH,
	SBAR_TARGET_ACCOUNT,
	SBAR_END,
};

new gStatusBarState[MAX_PLAYERS + 1][SBAR_END];
new Float:g_flNextSBarUpdateTime[MAX_PLAYERS + 1];
new Float:g_flStatusBarDisappearDelay[MAX_PLAYERS + 1];

new g_iHudSync_StatusBar;

new mp_playerid;

new Float:rz_statusbar_hud_pos[2];
new Float:rz_statusbar_spect_hud_pos[2];

public plugin_init()
{
	register_plugin("[ReZP] Addon: Status Bar", REZP_VERSION_STR, "fl0wer");

	RegisterHookChain(RG_CBasePlayer_Spawn, "@CBasePlayer_Spawn_Post", true);
	RegisterHookChain(RG_CBasePlayer_UpdateClientData, "@CBasePlayer_UpdateClientData_Post", true);

	bind_pcvar_num(get_cvar_pointer("mp_playerid"), mp_playerid);

	bind_pcvar_float(create_cvar("rz_statusbar_hud_x", "-1.0", _, "", true, -1.0, true, 1.0), rz_statusbar_hud_pos[0]);
	bind_pcvar_float(create_cvar("rz_statusbar_hud_y", "0.6", _, "", true, -1.0, true, 1.0), rz_statusbar_hud_pos[1]);
	bind_pcvar_float(create_cvar("rz_statusbar_spect_hud_x", "-1.0", _, "", true, -1.0, true, 1.0), rz_statusbar_spect_hud_pos[0]);
	bind_pcvar_float(create_cvar("rz_statusbar_spect_hud_y", "0.6", _, "", true, -1.0, true, 1.0), rz_statusbar_spect_hud_pos[1]);

	g_iHudSync_StatusBar = CreateHudSyncObj();
}

@CBasePlayer_Spawn_Post(id)
{
	if (!get_member(id, m_bJustConnected))
		return;

	set_member(id, m_flNextSBarUpdateTime, 99999999.0);
}

@CBasePlayer_UpdateClientData_Post(id)
{
	static Float:time;
	time = get_gametime();

	if (g_flNextSBarUpdateTime[id] > time)
		return;

	UpdateStatusBar(id);
	g_flNextSBarUpdateTime[id] = time + 0.2;
}

UpdateStatusBar(id)
{
	new newSBarState[SBAR_END];
	new Float:time = get_gametime();
	new Float:fraction;
	new Float:vecSrc[3];
	new Float:vecEnd[3];
	new Float:vecViewAngle[3];
	new Float:vecPunchAngle[3];
	new Float:vecViewForward[3];

	ExecuteHam(Ham_Player_GetGunPosition, id, vecSrc);
	get_entvar(id, var_v_angle, vecViewAngle);
	get_entvar(id, var_punchangle, vecPunchAngle);

	for (new i = 0; i < 3; i++)
		vecViewAngle[i] += vecPunchAngle[i];

	angle_vector(vecViewAngle, ANGLEVECTOR_FORWARD, vecViewForward);

	for (new i = 0; i < 3; i++)
		vecEnd[i] = vecSrc[i] + vecViewForward[i] * 2048.0;

	engfunc(EngFunc_TraceLine, vecSrc, vecEnd, DONT_IGNORE_MONSTERS, id, 0);
	get_tr2(0, TR_flFraction, fraction);

	new color[3];
	new name[RZ_MAX_LANGKEY_LENGTH];
	new Float:pos[2];
	
	new len;
	new text[512];

	//client_print(id, print_chat, "m_flStatusBarDisappearDelay %f %f", get_gametime(), Float:get_member(id, m_flStatusBarDisappearDelay));

	if (fraction < 1.0)
	{
		new hit = get_tr2(0, TR_pHit);

		if (is_user_connected(hit))
		{
			new observerMode = get_entvar(id, var_iuser1);
			new bool:sameTeam = get_member(hit, m_iTeam) == get_member(id, m_iTeam);

			newSBarState[SBAR_TARGET_TYPE] = sameTeam ? SBAR_TARGETTYPE_TEAMMATE : SBAR_TARGETTYPE_ENEMY;
			newSBarState[SBAR_TARGET_ID] = hit;

			if (is_user_alive(id))
			{
				if (sameTeam)
				{
					pos = rz_statusbar_hud_pos;

					new class = rz_player_get(hit, RZ_PLAYER_CLASS);
					new subclass = rz_player_get(hit, RZ_PLAYER_SUBCLASS);
					//new color[3];
					//new name[RZ_MAX_LANGKEY_LENGTH];

					rz_class_get(class, RZ_CLASS_HUD_COLOR, color);
					rz_class_get(class, RZ_CLASS_NAME, name, charsmax(name));

					SetGlobalTransTarget(id);

					add_formatex("[%l: %n]", "RZ_FRIEND", hit);

					if (subclass)
					{
						new subclassName[RZ_MAX_LANGKEY_LENGTH];
						rz_subclass_get(subclass, RZ_SUBCLASS_NAME, subclassName, charsmax(subclassName));

						add_formatex("^n[%l: %l]", name, subclassName);
					}
					else
						add_formatex("^n[%l: %l]", "RZ_CLASS", name);

					add_formatex("^n[%l: %d]", "RZ_HEALTH", floatround(get_entvar(hit, var_health)));

					if (rz_main_get(RZ_MAIN_AMMOPACKS_ENABLED))
						add_formatex("^n[%l: %d]", "RZ_AMMOPACKS", get_member(hit, m_iAccount));
				}
				else if (mp_playerid != PLAYERID_MODE_TEAMONLY)
				{
					add_formatex("[%l: %n]", "RZ_ENEMY", hit);
				}
				else
				{
					ClearSyncHud(id, g_iHudSync_StatusBar);
					return;
				}

				newSBarState[SBAR_TARGET_CLASS] = rz_player_get(hit, RZ_PLAYER_CLASS);
				newSBarState[SBAR_TARGET_SUBCLASS] = rz_player_get(hit, RZ_PLAYER_SUBCLASS);
				newSBarState[SBAR_TARGET_HEALTH] = floatround(get_entvar(hit, var_health));
				newSBarState[SBAR_TARGET_ACCOUNT] = get_member(hit, m_iAccount);
			}
			else if (observerMode != OBS_NONE)
			{
				pos = rz_statusbar_spect_hud_pos;

				new class = rz_player_get(hit, RZ_PLAYER_CLASS);
				new subclass = rz_player_get(hit, RZ_PLAYER_SUBCLASS);
				//new color[3];
				//new name[RZ_MAX_LANGKEY_LENGTH];

				rz_class_get(class, RZ_CLASS_HUD_COLOR, color);
				rz_class_get(class, RZ_CLASS_NAME, name, charsmax(name));

				SetGlobalTransTarget(id);

				add_formatex("[%l: %n]", "RZ_SPECTATING", hit);

				if (subclass)
				{
					new subclassName[RZ_MAX_LANGKEY_LENGTH];
					rz_subclass_get(subclass, RZ_SUBCLASS_NAME, subclassName, charsmax(subclassName));

					add_formatex("^n[%l: %l]", name, subclassName);
				}
				else
					add_formatex("^n[%l: %l]", "RZ_CLASS", name);
				
				add_formatex("^n[%l: %d]", "RZ_HEALTH", floatround(get_entvar(hit, var_health)));

				if (rz_main_get(RZ_MAIN_AMMOPACKS_ENABLED))
					add_formatex("^n[%l: %d]", "RZ_AMMOPACKS", get_member(hit, m_iAccount));
			}
			else
			{
				ClearSyncHud(id, g_iHudSync_StatusBar);
				return;
			}
		}
	}

	new bool:forceResend;

	if (g_flStatusBarDisappearDelay[id] > time)
	{
		for (new i = 0; i < SBAR_END; i++)
		{
			if (newSBarState[i] == gStatusBarState[id][i])
				continue;

			gStatusBarState[id][i] = newSBarState[i];
			forceResend = true;
		}
	}
	else
		forceResend = true;

	//client_print(id, print_chat, "not update %f", get_gametime());

	if (!forceResend)
		return;

	g_flStatusBarDisappearDelay[id] = time + 5.0;

	//client_print(id, print_chat, "update %f", get_gametime());
	set_hudmessage(color[0], color[1], color[2], pos[0], pos[1], 0, 0.1, 5.1, 0.1, 0.0);
	ShowSyncHudMsg(id, g_iHudSync_StatusBar, text);
}

/*@MSG_StatusValue(id, dest, player)
{
	if (mp_playerid == PLAYERID_MODE_OFF)
		return PLUGIN_CONTINUE;

	if (get_msg_arg_int(1) != SBAR_ID_TARGETNAME)
		return PLUGIN_HANDLED;

	new targetType = get_member(player, m_izSBarState, SBAR_ID_TARGETTYPE);

	if (targetType != SBAR_TARGETTYPE_TEAMMATE && targetType != SBAR_TARGETTYPE_ENEMY)
	{
		//ClearSyncHud(player, g_iHudSync_StatusBar);
		return PLUGIN_HANDLED;
	}

	//client_print(player, print_chat, "type: %d (%d) target: %d (%d)", get_entvar(player, var_iuser1), targetType, get_entvar(player, var_iuser2), target);

	new target = get_msg_arg_int(2);
	new class = rz_class_player_get(target);

	if (!class)
		return PLUGIN_HANDLED;

	new subclass = rz_subclass_player_get(target);
	new color[3];
	new name[32];
	new Float:pos[2];
	
	new len;
	new text[512];

	if (is_user_alive(player))
	{
		pos = rz_statusbar_hud_pos;

		SetGlobalTransTarget(player);

		rz_class_get_hudcolor(class, color);

		if (targetType == SBAR_TARGETTYPE_TEAMMATE)
		{
			rz_class_get_name_langkey(class, name, charsmax(name));

			add_formatex("[%l: %n]", "RZ_FRIEND", target);

			if (subclass)
			{
				new subclassName[32];
				rz_subclass_get_name_langkey(subclass, subclassName, charsmax(subclassName));

				add_formatex("^n[%l: %l]", name, subclassName);
			}
			else
				add_formatex("^n[%l: %l]", "RZ_CLASS", name);

			add_formatex("^n[%l: %d]", "RZ_HEALTH", floatround(get_entvar(target, var_health)));

			if (rz_main_ammopacks_enabled())
				add_formatex("^n[%l: %d]", "RZ_AMMOPACKS", get_member(target, m_iAccount));
		}
		else if (mp_playerid != PLAYERID_MODE_TEAMONLY)
		{
			add_formatex("[%l: %n]", "RZ_ENEMY", target);
		}
		else
			return PLUGIN_HANDLED;
	}
	else if (get_entvar(player, var_iuser1) != OBS_NONE)
	{
		pos = rz_statusbar_spect_hud_pos;

		SetGlobalTransTarget(player);

		rz_class_get_hudcolor(class, color);
		rz_class_get_name_langkey(class, name, charsmax(name));

		add_formatex("[%l: %n]", "RZ_SPECTATING", target);

		if (subclass)
		{
			new subclassName[32];
			rz_subclass_get_name_langkey(subclass, subclassName, charsmax(subclassName));

			add_formatex("^n[%l: %l]", name, subclassName);
		}
		else
			add_formatex("^n[%l: %l]", "RZ_CLASS", name);
		
		add_formatex("^n[%l: %d]", "RZ_HEALTH", floatround(get_entvar(target, var_health)));

		if (rz_main_ammopacks_enabled())
			add_formatex("^n[%l: %d]", "RZ_AMMOPACKS", get_member(target, m_iAccount));
	}
	else
		return PLUGIN_HANDLED;

	set_hudmessage(color[0], color[1], color[2], pos[0], pos[1], 0, 0.1, 0.2, 0.1, 0.0);
	ShowSyncHudMsg(player, g_iHudSync_StatusBar, text);
	return PLUGIN_HANDLED;
}
*/