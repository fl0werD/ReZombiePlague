#pragma semicolon 1

#include <amxmodx>
#include <reapi>
#include <rezp>
#include <rezp_util>

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
	SBAR_ID_TARGETTYPE = 1,
	SBAR_ID_TARGETNAME,
	SBAR_ID_TARGETHEALTH,
	SBAR_END,
};

new g_iHudSync_StatusBar;

new mp_playerid;

new Float:rz_statusbar_hud_pos[2];
new Float:rz_statusbar_spect_hud_pos[2];

public plugin_init()
{
	register_plugin("[ReZP] Addon: Status Bar", REZP_VERSION_STR, "fl0wer");

	register_message(get_user_msgid("StatusValue"), "@MSG_StatusValue");

	bind_pcvar_num(get_cvar_pointer("mp_playerid"), mp_playerid);

	bind_pcvar_float(create_cvar("rz_statusbar_hud_x", "-1.0", _, "", true, -1.0, true, 1.0), rz_statusbar_hud_pos[0]);
	bind_pcvar_float(create_cvar("rz_statusbar_hud_y", "0.6", _, "", true, -1.0, true, 1.0), rz_statusbar_hud_pos[1]);
	bind_pcvar_float(create_cvar("rz_statusbar_spect_hud_x", "-1.0", _, "", true, -1.0, true, 1.0), rz_statusbar_spect_hud_pos[0]);
	bind_pcvar_float(create_cvar("rz_statusbar_spect_hud_y", "0.8", _, "", true, -1.0, true, 1.0), rz_statusbar_spect_hud_pos[1]);

	g_iHudSync_StatusBar = CreateHudSyncObj();
}

@MSG_StatusValue(id, dest, player)
{
	if (mp_playerid == PLAYERID_MODE_OFF)
		return PLUGIN_CONTINUE;

	if (get_msg_arg_int(1) != SBAR_ID_TARGETNAME)
		return PLUGIN_HANDLED;

	new targetType = get_member(player, m_izSBarState, SBAR_ID_TARGETTYPE);

	if (targetType != SBAR_TARGETTYPE_TEAMMATE && targetType != SBAR_TARGETTYPE_ENEMY)
	{
		ClearSyncHud(player, g_iHudSync_StatusBar);
		return PLUGIN_HANDLED;
	}

	//client_print(player, print_chat, "type: %d (%d) target: %d (%d)", get_entvar(player, var_iuser1), targetType, get_entvar(player, var_iuser2), target);

	new target = get_msg_arg_int(2);
	new class = rz_class_player_get(target);

	if (!class)
		return PLUGIN_HANDLED;

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
			add_formatex(" [%l: %l]", "RZ_CLASS", name);
			add_formatex("^n[%l: %d%%]", "RZ_HEALTH", floatround((get_entvar(target, var_health) / get_entvar(target, var_max_health)) * 100.0));

			if (rz_main_ammopacks_enabled())
				add_formatex(" [%l: %d]", "RZ_AMMOPACKS", get_member(target, m_iAccount));
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
		add_formatex(" [%l: %l]", "RZ_CLASS", name);
		add_formatex("^n[%l: %d%%]", "RZ_HEALTH", floatround((get_entvar(target, var_health) / get_entvar(target, var_max_health)) * 100.0));

		if (rz_main_ammopacks_enabled())
			add_formatex(" [%l: %d]", "RZ_AMMOPACKS", get_member(target, m_iAccount));
	}
	else
		return PLUGIN_HANDLED;

	set_hudmessage(color[0], color[1], color[2], pos[0], pos[1], 0, 0.1, 256.0, 0.1, 0.0);
	ShowSyncHudMsg(player, g_iHudSync_StatusBar, "");
	ShowSyncHudMsg(player, g_iHudSync_StatusBar, text);

	return PLUGIN_HANDLED;
}
