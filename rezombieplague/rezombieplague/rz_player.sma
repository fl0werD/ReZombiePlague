#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <reapi>
#include <rezp>
#include <util_messages>
#include <util_tempentities>

new const RESPAWN_TIME = 3;
new const INFECTION_DEATHMSG[] = "teammate";

new const Float:HITGROUP_KNOCBACK_MULTIPLIER[MAX_BODYHITS] =
{
	-1.0, // HIT_GENERIC
	1.5, // HIT_HEAD
	-1.0, // HIT_CHEST
	1.25, // HIT_STOMACH
	-1.0, // HIT_LEFTARM
	-1.0, // HIT_RIGHTARM
	0.75, // HIT_LEFTLEG
	0.75, // HIT_RIGHTLEG
};

new g_iIntoGameNVG;
new g_iSpectatorNVG;

new g_iLastNVG[MAX_PLAYERS + 1];
new bool:g_bNightVision[MAX_PLAYERS + 1];

new Float:g_vecOldVelocity[3];
new g_iSettedBody[MAX_PLAYERS + 1];

new Float:mp_round_restart_delay;

public plugin_precache()
{
	register_plugin("[ReZP] Player", REZP_VERSION_STR, "fl0wer");
}

public plugin_init()
{
	register_message(get_user_msgid("ScreenFade"), "@MSG_ScreenFade");

	register_clcmd("nightvision", "@Command_NightVision");

	RegisterHookChain(RH_SV_StartSound, "@SV_StartSound_Pre", false);
	
	RegisterHookChain(RG_GetForceCamera, "@GetForceCamera_Post", true);
	RegisterHookChain(RG_ShowVGUIMenu, "@ShowVGUIMenu_Post", true);

	RegisterHookChain(RG_CBasePlayer_Spawn, "@CBasePlayer_Spawn_Pre", false);
	RegisterHookChain(RG_CBasePlayer_Spawn, "@CBasePlayer_Spawn_Post", true);
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "@CBasePlayer_TakeDamage_Pre", false);
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "@CBasePlayer_TakeDamage_Post", true);
	RegisterHookChain(RG_CBasePlayer_Killed, "@CBasePlayer_Killed_Post", true);
	RegisterHookChain(RG_CBasePlayer_ResetMaxSpeed, "@CBasePlayer_ResetMaxSpeed_Pre", false);
	RegisterHookChain(RG_CBasePlayer_GiveDefaultItems, "@CBasePlayer_GiveDefaultItems_Pre", false);
	RegisterHookChain(RG_CBasePlayer_AddAccount, "@CBasePlayer_AddAccount_Pre", false);
	RegisterHookChain(RG_CBasePlayer_HasRestrictItem, "@CBasePlayer_HasRestrictItem_Pre", false);
	RegisterHookChain(RG_CBasePlayer_OnSpawnEquip, "@CBasePlayer_OnSpawnEquip_Pre", false);
	RegisterHookChain(RG_CBasePlayer_Radio, "@CBasePlayer_Radio_Pre", false);
	RegisterHookChain(RG_CBasePlayer_StartObserver, "@CBasePlayer_StartObserver_Post", true);
	RegisterHookChain(RG_CBasePlayer_Observer_IsValidTarget, "@CBasePlayer_Observer_IsValidTarget_Post", true);

	bind_pcvar_float(get_cvar_pointer("mp_round_restart_delay"), mp_round_restart_delay);

	rz_load_langs("player");

	new nightVision = g_iIntoGameNVG = rz_nightvision_create("nightvision_intogame");

	rz_nightvision_set(nightVision, RZ_NIGHTVISION_EQUIP, RZ_NVG_EQUIP_APPEND_AND_ENABLE);
	rz_nightvision_set(nightVision, RZ_NIGHTVISION_ALPHA, 63);

	nightVision = g_iSpectatorNVG = rz_nightvision_create("nightvision_spectator");

	rz_nightvision_set(nightVision, RZ_NIGHTVISION_EQUIP, RZ_NVG_EQUIP_APPEND_AND_ENABLE);
	rz_nightvision_set(nightVision, RZ_NIGHTVISION_ALPHA, 63);
}

public client_putinserver(id)
{
	rz_player_set(id, RZ_PLAYER_CLASS, 0);
	rz_player_set(id, RZ_PLAYER_SUBCLASS, 0);

	new classStart = rz_class_start();
	new classEnd = classStart + rz_class_size();

	for (new i = classStart; i < classEnd; i++)
	{
		rz_player_set(id, RZ_PLAYER_SUBCLASS_CHOSEN, 0, i);
	}
}

public rz_class_change_post(id, attacker, class, bool:preSpawn)
{
	new subclass = rz_subclass_get_default(class);

	if (subclass)
	{
		new chosen = rz_player_get(id, RZ_PLAYER_SUBCLASS_CHOSEN, class);

		if (chosen)
			subclass = chosen;

		if (!rz_subclass_player_change(id, subclass))
			subclass = 0;
	}

	rz_player_set(id, RZ_PLAYER_CLASS, class);
	rz_player_set(id, RZ_PLAYER_SUBCLASS, subclass);

	if (!subclass)
	{
		rz_player_set(id, RZ_PLAYER_PROPS, rz_class_get(class, RZ_CLASS_PROPS));
		rz_player_set(id, RZ_PLAYER_MODEL, rz_class_get(class, RZ_CLASS_MODEL));
		rz_player_set(id, RZ_PLAYER_SOUND, rz_class_get(class, RZ_CLASS_SOUND));
		rz_player_set(id, RZ_PLAYER_KNIFE, rz_class_get(class, RZ_CLASS_KNIFE));
		rz_player_set(id, RZ_PLAYER_NIGHTVISION, rz_class_get(class, RZ_CLASS_NIGHTVISION));
	}

	if (preSpawn)
	{
		set_member(id, m_iTeam, rz_class_get(class, RZ_CLASS_TEAM));

		rz_playermodel_player_change(id, rz_player_get(id, RZ_PLAYER_MODEL), true);
	}
	else
	{
		rg_give_default_items(id);
		rz_playerprops_player_change(id, rz_player_get(id, RZ_PLAYER_PROPS));
		rz_playermodel_player_change(id, rz_player_get(id, RZ_PLAYER_MODEL));

		if (attacker)
		{
			message_begin(MSG_ALL, gmsgDeathMsg);
			SendDeathMsg(attacker, id, 0, INFECTION_DEATHMSG);

			message_begin(MSG_ALL, gmsgScoreAttrib);
			SendScoreAttrib(id, 0);

			rg_set_user_team(id, rz_class_get(class, RZ_CLASS_TEAM), MODEL_UNASSIGNED);

			ExecuteHamB(Ham_AddPoints, id, 0, true);
			ExecuteHamB(Ham_AddPoints, attacker, 1, true);

			set_member(id, m_iDeaths, get_member(id, m_iDeaths) + 1);
		}
		else
		{
			rg_set_user_team(id, rz_class_get(class, RZ_CLASS_TEAM), MODEL_UNASSIGNED);

			message_begin(MSG_ALL, gmsgDeathMsg);
			SendDeathMsg(id, id, 0, INFECTION_DEATHMSG);

			message_begin(MSG_ALL, gmsgScoreAttrib);
			SendScoreAttrib(id, 0);
		}

		if (rz_class_get(class, RZ_CLASS_TEAM) == TEAM_TERRORIST)
		{
			InfectionEffects(id);
		}

		if (get_member_game(m_bGameStarted) && !get_member_game(m_bFreezePeriod))
			RequestFrame("@RequestFrame_CheckChangeClassWinConditions");
	}
}

public rz_subclass_change_post(id, subclass)
{
	rz_player_set(id, RZ_PLAYER_PROPS, rz_subclass_get(subclass, RZ_SUBCLASS_PROPS));
	rz_player_set(id, RZ_PLAYER_MODEL, rz_subclass_get(subclass, RZ_SUBCLASS_MODEL));
	rz_player_set(id, RZ_PLAYER_SOUND, rz_subclass_get(subclass, RZ_SUBCLASS_SOUND));
	rz_player_set(id, RZ_PLAYER_KNIFE, rz_subclass_get(subclass, RZ_SUBCLASS_KNIFE));
	rz_player_set(id, RZ_PLAYER_NIGHTVISION, rz_subclass_get(subclass, RZ_SUBCLASS_NIGHTVISION));
}

public rz_nightvisions_change_post(id, player, bool:enabled)
{
	rz_player_set(player, RZ_PLAYER_HAS_NIGHTVISION, (rz_nightvision_get(id, RZ_NIGHTVISION_EQUIP) > RZ_NVG_EQUIP_DISABLED));
	rz_player_set(player, RZ_PLAYER_NIGHTVISION, id);
	rz_player_set(player, RZ_PLAYER_NIGHTVISION_ENABLED, enabled);

	if (enabled)
	{
		new color[3];
		rz_nightvision_get(id, RZ_NIGHTVISION_COLOR, color);

		rz_util_send_lightstyle(player, 0, fmt("%c", rz_main_lighting_nvg_get()));
		rz_util_send_screenfade(player, color, 0.0, 0.001, rz_nightvision_get(id, RZ_NIGHTVISION_ALPHA), (FFADE_OUT | FFADE_STAYOUT));
	}
	else
	{
		rz_util_send_lightstyle(player, 0, fmt("%c", rz_main_lighting_global_get()));
		rz_util_send_screenfade(player, { 0, 0, 0 }, 0.001);
	}
}

@MSG_ScreenFade(id, dest, player)
{
	return PLUGIN_HANDLED;
}

@Command_NightVision(id)
{
	if (!is_user_connected(id))
		return PLUGIN_HANDLED;

	if (!rz_player_get(id, RZ_PLAYER_HAS_NIGHTVISION))
		return PLUGIN_HANDLED;

	new Float:time = get_gametime();

	if (get_member(id, m_flLastCommandTime, CMD_NIGHTVISION) <= time)
	{
		new bool:enabled = rz_player_get(id, RZ_PLAYER_NIGHTVISION_ENABLED);

		enabled = !enabled;

		set_member(id, m_flLastCommandTime, time + 0.3, CMD_NIGHTVISION);
		rz_nightvisions_player_change(id, rz_player_get(id, RZ_PLAYER_NIGHTVISION), enabled);

		if (is_user_alive(id))
		{
			rh_emit_sound2(id, 0, CHAN_ITEM,
				rz_player_get(id, RZ_PLAYER_NIGHTVISION_ENABLED) ?
					"items/nvg_on.wav"
				:
					"items/nvg_off.wav",
				random_float(0.92, 1.0), ATTN_NORM);
		}
	}

	return PLUGIN_HANDLED;
}

@SV_StartSound_Pre(recipients, entity, channel, sample[], volume, Float:attenuation, flags, pitch)	
{
	if (sample[0] != 'p' || sample[1] != 'l' || sample[2] != 'a')
		return;

	if (!is_user_connected(entity))
		return;

	new playerSound = rz_player_get(entity, RZ_PLAYER_SOUND);

	if (rz_playersound_valid(playerSound))
	{
		new RZPainSound:painSound = RZ_PAIN_SOUND_NONE;

		if (sample[7] == 'b' && sample[8] == 'h' && sample[9] == 'i' && sample[10] == 't')
		{
			switch (sample[12])
			{
				case 'h': painSound = RZ_PAIN_SOUND_BHIT_HELMET;
				case 'k': painSound = RZ_PAIN_SOUND_BHIT_KEVLAR;
				case 'f': painSound = RZ_PAIN_SOUND_BHIT_FLESH;
			}
		}
		else if (sample[7] == 'h' && sample[8] == 'e' && sample[9] == 'a')
		{
			painSound = RZ_PAIN_SOUND_HEADSHOT;
		}
		else if (sample[7] == 'd' && ((sample[8] == 'i' && sample[9] == 'e') || (sample[8] == 'e' && sample[9] == 'a')))
		{
			painSound = RZ_PAIN_SOUND_DEATH;
		}

		if (painSound != RZ_PAIN_SOUND_NONE)
		{
			new Array:sounds = rz_playersound_get(playerSound, RZ_PLAYER_SOUND_SOUNDS_BANK, painSound);
			new soundsNum = ArraySize(sounds);

			if (soundsNum)
			{
				new sound[RZ_MAX_RESOURCE_PATH];
				ArrayGetString(sounds, random_num(0, soundsNum - 1), sound, charsmax(sound));

				SetHookChainArg(4, ATYPE_STRING, sound);
			}
		}
	}
}

@GetForceCamera_Post(id)
{
	if (!g_bNightVision[id])
		return;

	RequestFrame("@RequestFrame_UpdateNightVision", id);
}

@ShowVGUIMenu_Post(id, VGUIMenu:menuType, bitsSlots, oldMenu[])
{
	if (menuType != VGUI_Menu_Team)
		return;

	if (get_member(id, m_iJoiningState) == JOINED)
		return;

	rz_nightvisions_player_change(id, g_iIntoGameNVG);
}

@CBasePlayer_Spawn_Pre(id)
{
	if (get_member(id, m_bJustConnected))
		return;

	new TeamName:team = get_member(id, m_iTeam);

	if (team != TEAM_TERRORIST && team != TEAM_CT)
		return;

	new newClass = rz_class_get_default(TEAM_CT);

	if (!rz_game_is_warmup() && get_member_game(m_bGameStarted) && !get_member_game(m_bFreezePeriod))
	{
		new gameMode = rz_gamemodes_get(RZ_GAMEMODES_CURRENT);

		if (gameMode)
		{
			switch (rz_gamemode_get(gameMode, RZ_GAMEMODE_DEATHMATCH))
			{
				case RZ_GM_DEATHMATCH_ONLY_TR:
				{
					newClass = rz_class_get_default(TEAM_TERRORIST);
				}
				case RZ_GM_DEATHMATCH_RANDOM:
				{
					if (random_num(0, 1))
						newClass = rz_class_get_default(TEAM_TERRORIST);
				}
				case RZ_GM_DEATHMATCH_BALANCE:
				{
					if (rz_game_get_playersnum(TEAM_TERRORIST) < rz_game_get_alivesnum() / 2)
						newClass = rz_class_get_default(TEAM_TERRORIST);
				}
			}
		}
	}

	if (rz_player_get(id, RZ_PLAYER_CLASS) == newClass)
		return;

	set_member(id, m_bNotKilled, false);

	rz_class_player_change(id, id, newClass, true);

	g_iSettedBody[id] = get_entvar(id, var_body);
}

@CBasePlayer_Spawn_Post(id)
{
	if (get_member(id, m_bJustConnected))
	{
		set_member(id, m_fNextSuicideTime, 99999999.0);
		return;
	}

	new TeamName:team = get_member(id, m_iTeam);

	if (team != TEAM_TERRORIST && team != TEAM_CT)
		return;

	rz_playerprops_player_change(id, rz_player_get(id, RZ_PLAYER_PROPS), true);
	rz_nightvisions_player_change(id, rz_player_get(id, RZ_PLAYER_NIGHTVISION), false);

	set_entvar(id, var_body, g_iSettedBody[id]);

	if (get_member_game(m_bFreezePeriod))
		set_member(id, m_bCanShootOverride, true);

	if (rz_main_get(RZ_MAIN_AMMOPACKS_ENABLED))
		set_member(id, m_iHideHUD, get_member(id, m_iHideHUD) | HIDEHUD_MONEY);

	if (get_member(id, m_iNumSpawns) == 1)
	{
		client_print_color(id, print_team_default, "^1• • • ^4Re Zombie Plague %s.%s ^1• • •", REZP_VERSION_MAJOR, REZP_VERSION_MINOR);
		rz_print_chat(id, print_team_default, "%L", LANG_PLAYER, "RZ_PRESS_GAME_MENU");
	}
}

@CBasePlayer_TakeDamage_Pre(id, inflictor, attacker, Float:damage, bitsDamageType)
{
	get_entvar(id, var_velocity, g_vecOldVelocity);
}

@CBasePlayer_TakeDamage_Post(id, inflictor, attacker, Float:damage, bitsDamageType)
{
	if (!(bitsDamageType & (DMG_NEVERGIB | DMG_BULLET)))
		return;

	if (id == attacker || !is_user_connected(attacker))
		return;

	if (!rg_is_player_can_takedamage(id, attacker))
		return;

	new props = rz_player_get(id, RZ_PLAYER_PROPS);

	if (!rz_playerprops_valid(props))
		return;

	new activeItem = get_member(attacker, m_pActiveItem);
	new lastHitGroup = get_member(id, m_LastHitGroup);
	new Float:playerKnockback = Float:rz_playerprops_get(props, RZ_PLAYER_PROPS_KNOCKBACK);
	new i;
	new Float:weaponKnockbackPower = 1.0;
	new Float:ducking = 1.0;
	new Float:damage = 170.0;
	new Float:vecOrigin[3];
	new Float:vecOrigin2[3];
	new Float:vecVelocity[3];
	new Float:vecAttack[3];

	if (HITGROUP_KNOCBACK_MULTIPLIER[lastHitGroup] > 0.0)
		damage *= HITGROUP_KNOCBACK_MULTIPLIER[lastHitGroup];

	get_entvar(id, var_origin, vecOrigin);
	get_entvar(attacker, var_origin, vecOrigin2);

	for (i = 0; i < 3; i++)
		vecAttack[i] = vecOrigin[i] - vecOrigin2[i];

	new Float:length = floatsqroot(vecAttack[0] * vecAttack[0] + vecAttack[1] * vecAttack[1] + vecAttack[2] * vecAttack[2]);

	if (length != 0.0)
	{
		length = 1.0 / length;

		for (i = 0; i < 3; i++)
			vecAttack[i] *= length;
	}
	else
		vecAttack = Float:{ 0.0, 0.0, 1.0 };

	if (!is_nullent(activeItem))
	{
		new impulse = get_entvar(activeItem, var_impulse);

		if (impulse && rz_weapons_valid(impulse))
			weaponKnockbackPower = Float:rz_weapon_get(impulse, RZ_WEAPON_KNOCKBACK_POWER);
		else
			weaponKnockbackPower = Float:rz_weapon_default_get(get_member(activeItem, m_iId), RZ_DEFAULT_WEAPON_KNOCKBACK_POWER);

		if (weaponKnockbackPower <= 0.0)
			weaponKnockbackPower = 1.0;
	}
	
	if (get_entvar(id, var_flags) & (FL_DUCKING | FL_ONGROUND) == (FL_DUCKING | FL_ONGROUND))
		ducking = 0.5;

	for (i = 0; i < 3; i++)
		vecVelocity[i] = g_vecOldVelocity[i] + vecAttack[i] * damage * weaponKnockbackPower * playerKnockback * ducking;

	set_entvar(id, var_velocity, vecVelocity);

	if (lastHitGroup == HIT_HEAD)
		set_member(id, m_flVelocityModifier, Float:rz_playerprops_get(props, RZ_PLAYER_PROPS_VELMOD_HEAD));
	else
		set_member(id, m_flVelocityModifier, Float:rz_playerprops_get(props, RZ_PLAYER_PROPS_VELMOD));
}

@CBasePlayer_Killed_Post(id, attacker, gib)
{
	if (rg_is_player_can_respawn(id))
	{
		new gameMode = rz_gamemodes_get(RZ_GAMEMODES_CURRENT);

		if (gameMode && rz_gamemode_get(gameMode, RZ_GAMEMODE_DEATHMATCH))
		{
			set_member(id, m_flRespawnPending, get_gametime() + float(RESPAWN_TIME));

			message_begin(MSG_ONE, gmsgBarTime, _, id);
			SendBarTime(RESPAWN_TIME);
			
			client_print(id, print_center, "Time until Respawn: %d sec", RESPAWN_TIME);
		}
	}
}

@CBasePlayer_ResetMaxSpeed_Pre(id)
{
	if (!is_user_alive(id))
		return HC_CONTINUE;

	new props = rz_player_get(id, RZ_PLAYER_PROPS);

	if (!rz_playerprops_valid(props))
		return HC_CONTINUE;

	new Float:speed;
	new Float:propSpeed = Float:rz_playerprops_get(props, RZ_PLAYER_PROPS_SPEED);

	if (!propSpeed)
	{
		new activeItem = get_member(id, m_pActiveItem);
		
		if (!is_nullent(activeItem))
			ExecuteHamB(Ham_CS_Item_GetMaxSpeed, activeItem, speed);
		else
			speed = 240.0;
	}
	else
		speed = propSpeed;

	set_entvar(id, var_maxspeed, speed);
	return HC_SUPERCEDE;
}

@CBasePlayer_GiveDefaultItems_Pre(id)
{
	rg_remove_all_items(id);
	rg_give_custom_item(id, "weapon_knife", GT_APPEND, rz_player_get(id, RZ_PLAYER_KNIFE));

	// double set
	rz_nightvisions_player_change(id, rz_player_get(id, RZ_PLAYER_NIGHTVISION), false);
	return HC_SUPERCEDE;
}

@CBasePlayer_AddAccount_Pre(id, amount, RewardType:type, bool:trackChange)
{
	if (type == RT_NONE || type == RT_ENEMY_KILLED)
		return HC_CONTINUE;

	if (type == RT_PLAYER_JOIN && rz_main_get(RZ_MAIN_AMMOPACKS_ENABLED))
	{
		SetHookChainArg(2, ATYPE_INTEGER, rz_main_get(RZ_MAIN_AMMOPACKS_JOIN_AMOUNT));
		return HC_CONTINUE;
	}

	return HC_SUPERCEDE;
}

@CBasePlayer_HasRestrictItem_Pre(id, ItemID:item, ItemRestType:type)
{
	if (get_member(id, m_iTeam) != TEAM_TERRORIST)
		return HC_CONTINUE;

	SetHookChainReturn(ATYPE_BOOL, true);
	return HC_SUPERCEDE;
}

@CBasePlayer_OnSpawnEquip_Pre(id, bool:addDefault, bool:equipGame)
{
	SetHookChainArg(3, ATYPE_BOOL, false);
}

@CBasePlayer_Radio_Pre(id, msgId[], msgVerbose[], pitch, bool:showIcon)
{
	return HC_SUPERCEDE;
}

@CBasePlayer_StartObserver_Post(id, Float:vecPosition[3], Float:vecViewAngle[3])
{
	/*g_bNightVision[id] = true;
	g_bHasNightVision[id] = true;*/
}

@CBasePlayer_Observer_IsValidTarget_Post(id, player, bool:sameTeam)
{
	if (GetHookChainReturn(ATYPE_INTEGER) != player)
		return;

	g_iLastNVG[id] = rz_player_get(player, RZ_PLAYER_NIGHTVISION);
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

@RequestFrame_UpdateNightVision(id)
{
	if (!is_user_connected(id))
		return;

	new nightVision;

	if (!rz_player_get(id, RZ_PLAYER_NIGHTVISION))
		nightVision = g_iSpectatorNVG;

	if (get_entvar(id, var_iuser1) == OBS_IN_EYE)
		nightVision = g_iLastNVG[id];
	else
		nightVision = g_iSpectatorNVG;

	rz_nightvisions_player_change(id, nightVision);
}

InfectionEffects(id)
{
	//if (get_pcvar_num(cvar_infect_screen_shake))
	{
		message_begin(MSG_ONE, gmsgScreenShake, _, id);
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
