#pragma semicolon 1

#include <amxmodx>
#include <reapi>
#include <rezp>
#include <util_messages>

new Float:g_flNextHudInfoTime[MAX_PLAYERS + 1];

new g_iHudSync_Info;

new Float:rz_playerinfo_hud_pos[2];

public plugin_init()
{
	register_plugin("[ReZP] Addon: Player Info", REZP_VERSION_STR, "fl0wer");

	register_message(get_user_msgid("Money"), "@MSG_Money");
	register_message(get_user_msgid("SpecHealth"), "@MSG_SpecHealth");
	register_message(get_user_msgid("SpecHealth2"), "@MSG_SpecHealth2");

	RegisterHookChain(RG_CBasePlayer_Spawn, "@CBasePlayer_Spawn_Post", true);
	//RegisterHookChain(RG_CBasePlayer_TakeDamage, "@CBasePlayer_TakeDamage_Post", true);
	RegisterHookChain(RG_CBasePlayer_Killed, "@CBasePlayer_Killed_Post", true);
	RegisterHookChain(RG_CBasePlayer_UpdateClientData, "@CBasePlayer_UpdateClientData_Post", true);
	RegisterHookChain(RG_CBasePlayer_AddAccount, "@CBasePlayer_AddAccount_Post", true);

	bind_pcvar_float(create_cvar("rz_playerinfo_hud_x", "0.02", _, "", true, -1.0, true, 1.0), rz_playerinfo_hud_pos[0]);
	bind_pcvar_float(create_cvar("rz_playerinfo_hud_y", "0.2", _, "", true, -1.0, true, 1.0), rz_playerinfo_hud_pos[1]);

	g_iHudSync_Info = CreateHudSyncObj();
}

public client_putinserver(id)
{
	g_flNextHudInfoTime[id] = 0.0;
}

public rz_class_change_post(id, attacker, class)
{
	g_flNextHudInfoTime[id] = get_gametime() + 0.1;
}

public rz_subclass_change_post(id, subclass)
{
	g_flNextHudInfoTime[id] = get_gametime() + 0.1;
}

@MSG_Money(id, dest, player)
{
	if (get_msg_arg_int(2) == 0)
		return PLUGIN_CONTINUE;

	return PLUGIN_HANDLED;
}

@MSG_SpecHealth(id, dest, player)
{
	new observerTarget = get_member(player, m_hObserverTarget);
	new Float:health = get_entvar(observerTarget, var_health);
	new Float:maxHealth = get_entvar(observerTarget, var_max_health);

	if (health < 0.0)
		health = 0.0;

	set_msg_arg_int(1, ARG_BYTE, floatround((health / maxHealth) * 100.0));
}

@MSG_SpecHealth2(id, dest, player)
{
	new observerTarget = get_msg_arg_int(2);
	new Float:health = get_entvar(observerTarget, var_health);
	new Float:maxHealth = get_entvar(observerTarget, var_max_health);

	set_msg_arg_int(1, ARG_BYTE, floatround((health / maxHealth) * 100.0));
}

@CBasePlayer_Spawn_Post(id)
{
	if (!is_user_alive(id))
		return;

	g_flNextHudInfoTime[id] = get_gametime() + 0.2;
}

@CBasePlayer_TakeDamage_Post(id, inflictor, attacker, Float:damage, bitsDamageType)
{
	if (!rg_is_player_can_takedamage(id, attacker))
		return;

	if (!is_user_alive(id))
		return;

	PlayerInfoHud_Show(id);
}

@CBasePlayer_Killed_Post(id, attacker, gib)
{
	ClearSyncHud(id, g_iHudSync_Info);
}

@CBasePlayer_UpdateClientData_Post(id)
{
	if (!g_flNextHudInfoTime[id])
		return;

	if (!is_user_alive(id))
		return;

	new Float:time = get_gametime();

	if (g_flNextHudInfoTime[id] > time)
		return;

	g_flNextHudInfoTime[id] = time + 1.0;

	PlayerInfoHud_Show(id);
}

@CBasePlayer_AddAccount_Post(id, amount, RewardType:type, bool:trackChange)
{
	if (!rz_main_get(RZ_MAIN_AMMOPACKS_ENABLED))
		return;

	g_flNextHudInfoTime[id] = get_gametime() + 0.1;
}

PlayerInfoHud_Show(id)
{
	new class = rz_player_get(id, RZ_PLAYER_CLASS);

	if (!class)
		return;

	new subclass = rz_player_get(id, RZ_PLAYER_SUBCLASS);
	new color[3];
	new name[RZ_MAX_LANGKEY_LENGTH];

	rz_class_get(class, RZ_CLASS_HUD_COLOR, color);
	rz_class_get(class, RZ_CLASS_NAME, name, charsmax(name));

	new len;
	new text[512];

	SetGlobalTransTarget(id);
	
	add_formatex("[%l: %d]", "RZ_HEALTH", floatround(get_entvar(id, var_health)));

	if (rz_main_get(RZ_MAIN_AMMOPACKS_ENABLED))
		add_formatex("^n[%l: %d]", "RZ_AMMOPACKS", get_member(id, m_iAccount));

	if (subclass)
	{
		new subclassName[RZ_MAX_LANGKEY_LENGTH];
		rz_subclass_get(subclass, RZ_SUBCLASS_NAME, subclassName, charsmax(subclassName));

		add_formatex("^n[%l: %l]", name, subclassName);
	}
	else
		add_formatex("^n[%l: %l]", "RZ_CLASS", name);

	set_hudmessage(color[0], color[1], color[2], rz_playerinfo_hud_pos[0], rz_playerinfo_hud_pos[1], 0, 0.0, 2.0, 0.0, 0.0);
	ShowSyncHudMsg(id, g_iHudSync_Info, text);

	message_begin(MSG_ONE, gmsgMoney, _, id);
	SendMoney(get_member(id, m_iAccount), true);
}
