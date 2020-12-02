#if defined _util_messages_included
	#endinput
#endif

#define _util_messages_included

/*
	VoiceMask
	ReqState
DONE! CurWeapon
	Geiger
DONE! Flashlight
DONE! FlashBat
	Health
	Damage
DONE! Battery
	Train
	HudTextPro
	HudText
	SayText
	TextMsg
DONE! WeaponList
	ResetHUD
	InitHUD
	ViewMode
	GameTitle
DONE! DeathMsg
DONE! ScoreAttrib
	ScoreInfo
	TeamInfo
	TeamScore
	GameMode
	MOTD
	ServerName
	AmmoPickup
	WeapPickup
	ItemPickup
	HideWeapon
	SetFOV
	ShowMenu
	ScreenShake
	ScreenFade
	AmmoX
	SendAudio
	RoundTime
DONE! Money
	ArmorType
DONE! BlinkAcct
	StatusValue
	StatusText
	StatusIcon
DONE! BarTime
	ReloadSound
	Crosshair
	NVGToggle
	Radar
	Spectator
	VGUIMenu
	TutorText
	TutorLine
	TutorState
	TutorClose
	AllowSpec
	BombDrop
	BombPickup
	ClCorpse
	HostagePos
	HostageK
	HLTV
	SpecHealth
	ForceCam
	ADStop
	ReceiveW
	CZCareer
	CZCareerHUD
	ShadowIdx
	TaskTime
	Scenario
	BotVoice
	BuyClose
	SpecHealth2
DONE! BarTime2
	ItemStatus
	Location
	BotProgress
	Brass
	Fog
	ShowTimer
	HudTextArgs
	Account
	HealthInfo

stock Send(id)
{
	static msg;

	if (!msg)
		msg = get_user_msgid("");

	message_begin(MSG_ONE, msg, _, id);
	message_end();
}*/

stock SendCurWeapon(id, isActive, any:weaponId, clipAmmo)
{
	static msg;

	if (!msg)
		msg = get_user_msgid("CurWeapon");

	message_begin(MSG_ONE, msg, _, id);
	write_byte(isActive);
	write_byte(weaponId);
	write_byte(clipAmmo);
	message_end();
}

stock SendFlashlight(id, flag, chargePercent)
{
	static msg;

	if (!msg)
		msg = get_user_msgid("Flashlight");

	message_begin(MSG_ONE, msg, _, id);
	write_byte(flag);
	write_byte(chargePercent);
	message_end();
}

stock SendFlashBat(id, chargePercentage)
{
	static msg;

	if (!msg)
		msg = get_user_msgid("FlashBat");

	message_begin(MSG_ONE, msg, _, id);
	write_byte(chargePercentage);
	message_end();
}

stock SendBattery(id, armor)
{
	static msg;

	if (!msg)
		msg = get_user_msgid("Battery");

	message_begin(MSG_ONE, msg, _, id);
	write_short(armor);
	message_end();
}

stock SendWeaponList(id, const name[], ammo1, maxAmmo1, ammo2, maxAmmo2, slot, position, any:weaponId, flags)
{
	static msg;

	if (!msg)
		msg = get_user_msgid("WeaponList");

	message_begin(MSG_ONE, msg, _, id);
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
	static msg;

	if (!msg)
		msg = get_user_msgid("DeathMsg");

	message_begin(MSG_ALL, msg);
	write_byte(killer);
	write_byte(victim);
	write_byte(headshot);
	write_string(weapon);
	message_end();
}

stock SendScoreAttrib(playerId, flags)
{
	static msg;

	if (!msg)
		msg = get_user_msgid("ScoreAttrib");

	message_begin(MSG_ALL, msg);
	write_byte(playerId);
	write_byte(flags);
	message_end();
}

stock SendMoney(id, amount, any:flag)
{
	static msg;

	if (!msg)
		msg = get_user_msgid("Money");

	message_begin(MSG_ONE, msg, _, id);
	write_long(amount);
	write_byte(flag);
	message_end();
}

stock SendBlinkAcct(id, blinkAmt)
{
	static msg;

	if (!msg)
		msg = get_user_msgid("BlinkAcct");

	message_begin(MSG_ONE, msg, _, id);
	write_byte(blinkAmt);
	message_end();
}

stock SendBarTime(id, duration = 0)
{
	static msg;

	if (!msg)
		msg = get_user_msgid("BarTime");

	message_begin(MSG_ONE, msg, _, id);
	write_short(duration);
	message_end();
}

stock SendBarTime2(id, duration, startPercent)
{
	static msg;

	if (!msg)
		msg = get_user_msgid("BarTime");

	message_begin(MSG_ONE, msg, _, id);
	write_short(duration);
	write_short(startPercent);
	message_end();
}
