#pragma semicolon 1

#include <amxmodx>
#include <reapi>
#include <rezp>

public plugin_precache()
{
	register_plugin("[ReZP] Player", REZP_VERSION_STR, "fl0wer");
}

public plugin_init()
{
	RegisterHookChain(RG_CBasePlayer_Spawn, "@CBasePlayer_Spawn_Pre", false);
	RegisterHookChain(RG_CBasePlayer_Spawn, "@CBasePlayer_Spawn_Post", true);
	RegisterHookChain(RG_CBasePlayer_GiveDefaultItems, "@CBasePlayer_GiveDefaultItems_Pre", false);
	RegisterHookChain(RG_CBasePlayer_AddAccount, "@CBasePlayer_AddAccount_Pre", false);
	RegisterHookChain(RG_CBasePlayer_HasRestrictItem, "@CBasePlayer_HasRestrictItem_Pre", false);
	RegisterHookChain(RG_CBasePlayer_OnSpawnEquip, "@CBasePlayer_OnSpawnEquip_Pre", false);
}

@CBasePlayer_Spawn_Pre(id)
{
	if (get_member(id, m_bJustConnected))
		return;

	if (TEAM_TERRORIST > get_member(id, m_iTeam) > TEAM_CT)
		return;

	new newClass;

	if (rz_game_is_warmup())
		newClass = rz_class_get_default(TEAM_CT);
	else
	{
		if (get_member_game(m_bGameStarted) && !get_member_game(m_bFreezePeriod))
			newClass = rz_class_get_default(TEAM_TERRORIST);
		else
			newClass = rz_class_get_default(TEAM_CT);
	}

	if (rz_class_player_get(id) == newClass)
		return;

	set_member(id, m_bNotKilled, false);

	rz_class_player_set(id, newClass);
}

@CBasePlayer_Spawn_Post(id)
{
	if (get_member(id, m_bJustConnected))
	{
		set_member(id, m_fNextSuicideTime, 99999999.0);
		return;
	}

	if (TEAM_TERRORIST > get_member(id, m_iTeam) > TEAM_CT)
		return;

	if (get_member_game(m_bFreezePeriod))
		set_member(id, m_bCanShootOverride, true);

	if (rz_main_ammopacks_enabled())
		set_member(id, m_iHideHUD, get_member(id, m_iHideHUD) | HIDEHUD_MONEY);
}

@CBasePlayer_GiveDefaultItems_Pre(id)
{
	rg_remove_all_items(id);
	return HC_SUPERCEDE;
}

@CBasePlayer_AddAccount_Pre(id, amount, RewardType:type, bool:trackChange)
{
	if (type == RT_NONE || type == RT_ENEMY_KILLED)
		return HC_CONTINUE;

	if (type == RT_PLAYER_JOIN && rz_main_ammopacks_enabled())
	{
		SetHookChainArg(2, ATYPE_INTEGER, rz_main_ammopacks_join_amount());
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
