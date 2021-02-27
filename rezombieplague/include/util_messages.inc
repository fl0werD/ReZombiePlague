#if defined _util_messages_included
	#endinput
#endif

#define _util_messages_included

/**
 * You have to call message_begin[/_f] before call stocks.
 */

enum
{
	gmsgVoiceMask = 64,
	gmsgReqState, // Undone
	gmsgCurWeapon,
	gmsgGeiger, // Undone
	gmsgFlashlight,
	gmsgFlashBat,
	gmsgHealth, // Undone
	gmsgDamage,
	gmsgBattery,
	gmsgTrain, // Undone
	gmsgHudTextPro, // Undone
	gmsgHudText, // Undone
	gmsgSayText, // Undone
	gmsgTextMsg,
	gmsgWeaponList,
	gmsgResetHUD, // Undone
	gmsgInitHUD, // Undone
	gmsgViewMode, // Undone
	gmsgGameTitle, // Undone
	gmsgDeathMsg,
	gmsgScoreAttrib,
	gmsgScoreInfo, // Undone
	gmsgTeamInfo, // Undone
	gmsgTeamScore, // Undone
	gmsgGameMode, // Undone
	gmsgMOTD, // Undone
	gmsgServerName, // Undone
	gmsgAmmoPickup, // Undone
	gmsgWeapPickup, // Undone
	gmsgItemPickup, // Undone
	gmsgHideWeapon, // Undone
	gmsgSetFOV, // Undone
	gmsgShowMenu, // Undone
	gmsgScreenShake, // Undone
	gmsgScreenFade, // Undone
	gmsgAmmoX, // Undone
	gmsgSendAudio, // Undone
	gmsgRoundTime, // Undone
	gmsgMoney,
	gmsgArmorType, // Undone
	gmsgBlinkAcct,
	gmsgStatusValue, // Undone
	gmsgStatusText, // Undone
	gmsgStatusIcon,
	gmsgBarTime,
	gmsgReloadSound, // Undone
	gmsgCrosshair, // Undone
	gmsgNVGToggle, // Undone
	gmsgRadar, // Undone
	gmsgSpectator, // Undone
	gmsgVGUIMenu, // Undone
	gmsgTutorText, // Undone
	gmsgTutorLine, // Undone
	gmsgTutorState, // Undone
	gmsgTutorClose, // Undone
	gmsgAllowSpec, // Undone
	gmsgBombDrop, // Undone
	gmsgBombPickup, // Undone
	gmsgClCorpse, // Undone
	gmsgHostagePos, // Undone
	gmsgHostageK, // Undone
	gmsgHLTV, // Undone
	gmsgSpecHealth, // Undone
	gmsgForceCam, // Undone
	gmsgADStop, // Undone
	gmsgReceiveW, // Undone
	gmsgCZCareer, // Undone
	gmsgCZCareerHUD, // Undone
	gmsgShadowIdx, // Undone
	gmsgTaskTime, // Undone
	gmsgScenario, // Undone
	gmsgBotVoice, // Undone
	gmsgBuyClose, // Undone
	gmsgSpecHealth2, // Undone
	gmsgBarTime2, 
	gmsgItemStatus, // Undone
	gmsgLocation, // Undone
	gmsgBotProgress, // Undone
	gmsgBrass, // Undone
	gmsgFog, // Undone
	gmsgShowTimer, // Undone
	gmsgHudTextArgs, // Undone
	gmsgAccount, // Undone
	gmsgHealthInfo, // Undone
};

/*stock Send(id)
{
	message_begin(MSG_ONE, gmsg, _, id);
	message_end();
}*/

stock SendCurWeapon(isActive, any:weaponId, clipAmmo)
{
	write_byte(isActive);
	write_byte(weaponId);
	write_byte(clipAmmo);
	message_end();
}

stock SendFlashlight(flag, chargePercent)
{
	write_byte(flag);
	write_byte(chargePercent);
	message_end();
}

stock SendFlashBat(chargePercentage)
{
	write_byte(chargePercentage);
	message_end();
}

stock SendDamage(damageSave, damageTake, damageType, Float:coord[3] = NULL_VECTOR)
{
	write_byte(damageSave);
	write_byte(damageTake);
	write_long(damageType);
	write_coord_f(coord[0]);
	write_coord_f(coord[1]);
	write_coord_f(coord[2]);
	message_end();
}

stock SendBattery(armor)
{
	write_short(armor);
	message_end();
}

stock SendTextMsg(msgDest, msgName[], param1[] = "", param2[] = "", param3[] = "", param4[] = "")
{
	write_byte(msgDest);
	write_string(msgName);
	if (param1[0])
		write_string(param1);
	if (param2[0])
		write_string(param2);
	if (param3[0])
		write_string(param3);
	if (param4[0])
		write_string(param4);
	message_end();
}

stock SendWeaponList(const name[], ammo1, maxAmmo1, ammo2, maxAmmo2, slot, position, any:weaponId, flags)
{
	write_string(name);
	write_byte(ammo1);
	write_byte(maxAmmo1);
	write_byte(ammo2);
	write_byte(maxAmmo2);
	write_byte(slot);
	write_byte(position);
	write_byte(weaponId);
	write_byte(flags);
	message_end();
}

stock SendDeathMsg(killer, victim, headshot, const weapon[])
{
	write_byte(killer);
	write_byte(victim);
	write_byte(headshot);
	write_string(weapon);
	message_end();
}

stock SendScoreAttrib(playerId, flags)
{
	write_byte(playerId);
	write_byte(flags);
	message_end();
}

stock SendMoney(amount, any:flag)
{
	write_long(amount);
	write_byte(flag);
	message_end();
}

stock SendBlinkAcct(blinkAmt)
{
	write_byte(blinkAmt);
	message_end();
}

stock SendStatusIcon(status, const spriteName[], color[3] = { 0, 0, 0 })
{
	write_byte(status);
	write_string(spriteName);

	if (status != 0)
	{
		write_byte(color[0]);
		write_byte(color[1]);
		write_byte(color[2]);
	}

	message_end();
}

stock SendBarTime(duration = 0)
{
	write_short(duration);
	message_end();
}

stock SendBarTime2(duration, startPercent)
{
	write_short(duration);
	write_short(startPercent);
	message_end();
}
