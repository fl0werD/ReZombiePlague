#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>
#include <rezp>
#include <util_messages>

const MeleeSound:MeleeSoundNone = any:-1;

enum _:MeleeData
{
	Melee_ViewModel[MAX_QPATH],
	Melee_WeaponModel[MAX_QPATH],
	Melee_WeaponList[MAX_QPATH],
	Float:Melee_DamageMulti,
	Float:Melee_StabDistance,
	Float:Melee_SwingDistance,
	Array:Melee_Sounds[MAX_MELEE_SOUNDS],

}; new Array:g_aMelees;

new g_iMelee[MAX_PLAYERS + 1];

new g_iModule;

public plugin_precache()
{
	register_plugin("[ReZP] Player: Melee", REZP_VERSION_STR, "fl0wer");

	g_aMelees = ArrayCreate(MeleeData, 0);
	g_iModule = rz_module_create("player_melee", g_aMelees);
}

public plugin_init()
{
	RegisterHookChain(RH_SV_StartSound, "@SV_StartSound_Pre", false);
	RegisterHookChain(RG_CBasePlayer_GiveDefaultItems, "@CBasePlayer_GiveDefaultItems_Post", true);

	RegisterHam(Ham_Item_AddToPlayer, "weapon_knife", "@CKnife_AddToPlayer_Post", true);
	RegisterHam(Ham_Item_Deploy, "weapon_knife", "@CKnife_Deploy_Post", true);
}

@Command_WeaponKnife(id)
{
	engclient_cmd(id, "weapon_knife");
	return PLUGIN_HANDLED;
}

@SV_StartSound_Pre(recipients, entity, channel, sample[], volume, Float:attenuation, flags, pitch)	
{
	if (sample[8] != 'k' || sample[9] != 'n' || sample[10] != 'i')
		return;

	if (!is_user_connected(entity))
		return;

	new MeleeSound:meleeSound = MeleeSoundNone;

	if (sample[14] == 'd' && sample[15] == 'e' && sample[16] == 'p')
	{
		meleeSound = MELEE_SOUND_DEPLOY;
	}
	else if (sample[14] == 's' && sample[15] == 'l' && sample[16] == 'a')
	{
		meleeSound = MELEE_SOUND_SLASH;
	}
	else if (sample[14] == 'h' && sample[15] == 'i' && sample[16] == 't')
	{
		meleeSound = (sample[17] == 'w') ? MELEE_SOUND_HITWALL : MELEE_SOUND_HIT;
	}
	else if (sample[14] == 's' && sample[15] == 't' && sample[16] == 'a')
	{
		meleeSound = MELEE_SOUND_STAB;
	}

	if (meleeSound == MeleeSoundNone)
		return;

	new index = rz_module_get_valid_index(g_iModule, g_iMelee[entity]);

	if (index != -1)
	{
		new data[MeleeData];
		ArrayGetArray(g_aMelees, index, data);

		new soundsSize = ArraySize(data[Melee_Sounds][meleeSound]);

		if (soundsSize)
		{
			new sound[MAX_QPATH];
			ArrayGetString(data[Melee_Sounds][meleeSound], random_num(0, soundsSize - 1), sound, charsmax(sound));

			SetHookChainArg(4, ATYPE_STRING, sound);
		}
	}
}

@CBasePlayer_GiveDefaultItems_Post(id)
{
	new melee = g_iMelee[id];

	if (!melee)
	{
		rg_give_item(id, "weapon_knife", GT_APPEND);
		return;
	}
	
	new index = rz_module_get_valid_index(g_iModule, melee);

	if (index == -1)
		return;

	new knife = rg_give_custom_item(id, "weapon_knife", GT_APPEND, melee);

	if (is_nullent(knife))
		return;

	new meleeData[MeleeData];
	ArrayGetArray(g_aMelees, index, meleeData);

	if (meleeData[Melee_DamageMulti] != -1.0)
	{
		set_member(knife, m_Knife_flStabDistance, Float:get_member(knife, m_Knife_flStabDistance) * meleeData[Melee_DamageMulti]);
		set_member(knife, m_Knife_flSwingBaseDamage, Float:get_member(knife, m_Knife_flSwingBaseDamage) * meleeData[Melee_DamageMulti]);
		set_member(knife, m_Knife_flSwingBaseDamage_Fast, Float:get_member(knife, m_Knife_flSwingBaseDamage_Fast) * meleeData[Melee_DamageMulti]);
	}

	if (meleeData[Melee_StabDistance] != -1.0)
	{
		set_member(knife, m_Knife_flStabDistance, meleeData[Melee_StabDistance]);
	}

	if (meleeData[Melee_SwingDistance] != -1.0)
	{
		set_member(knife, m_Knife_flSwingDistance, meleeData[Melee_SwingDistance]);
	}
}

@CKnife_AddToPlayer_Post(id, player)
{
	if (!is_entity(player))
		return;

	new impulse = get_entvar(id, var_impulse);
	new name[MAX_QPATH];

	if (impulse)
	{
		new index = rz_module_get_valid_index(g_iModule, impulse);

		if (index != -1)
		{
			new meleeData[MeleeData];
			ArrayGetArray(g_aMelees, index, meleeData);

			if (meleeData[Melee_WeaponList][0])
				name = meleeData[Melee_WeaponList];
		}
	}

	if (!name[0])
		rg_get_iteminfo(id, ItemInfo_pszName, name, charsmax(name));

	SendWeaponList
	(
		player,
		name,
		get_member(id, m_Weapon_iPrimaryAmmoType),
		rg_get_iteminfo(id, ItemInfo_iMaxAmmo1),
		get_member(id, m_Weapon_iSecondaryAmmoType),
		rg_get_iteminfo(id, ItemInfo_iMaxAmmo2),
		rg_get_iteminfo(id, ItemInfo_iSlot),
		rg_get_iteminfo(id, ItemInfo_iPosition),
		rg_get_iteminfo(id, ItemInfo_iId),
		rg_get_iteminfo(id, ItemInfo_iFlags)
	);
}

@CKnife_Deploy_Post(id)
{
	new player = get_member(id, m_pPlayer);
	new index = rz_module_get_valid_index(g_iModule, g_iMelee[player]);

	if (index == -1)
		return;

	new meleeData[MeleeData];
	ArrayGetArray(g_aMelees, index, meleeData);

	if (meleeData[Melee_ViewModel][0])
		set_entvar(player, var_viewmodel, meleeData[Melee_ViewModel]);

	if (meleeData[Melee_WeaponModel][0])
	{
		if (equal(meleeData[Melee_WeaponModel], "hide"))
			set_entvar(player, var_weaponmodel, NULL_STRING);
		else
			set_entvar(player, var_weaponmodel, meleeData[Melee_WeaponModel]);
	}
}

public plugin_natives()
{
	register_native("rz_melee_create", "@native_melee_create");

	register_native("rz_melee_sound_add", "@native_melee_sound_add");

	register_native("rz_melee_player_get", "@native_melee_player_get");
	register_native("rz_melee_player_set", "@native_melee_player_set");
}

@native_melee_create(plugin, argc)
{
	enum { arg_view_model = 1, arg_weapon_model, arg_weaponlist, arg_damage_multi, arg_stab_distance, arg_swing_distance };

	new data[MeleeData];

	get_string(arg_view_model, data[Melee_ViewModel], charsmax(data[Melee_ViewModel]));
	get_string(arg_weapon_model, data[Melee_WeaponModel], charsmax(data[Melee_WeaponModel]));
	get_string(arg_weaponlist, data[Melee_WeaponList], charsmax(data[Melee_WeaponList]));
	data[Melee_DamageMulti] = get_param_f(arg_damage_multi);
	data[Melee_StabDistance] = get_param_f(arg_stab_distance);
	data[Melee_SwingDistance] = get_param_f(arg_swing_distance);

	if (data[Melee_ViewModel][0])
		precache_model(data[Melee_ViewModel]);

	if (data[Melee_WeaponModel][0] && !equal(data[Melee_WeaponModel], "hide"))
		precache_model(data[Melee_WeaponModel]);

	if (data[Melee_WeaponList][0])
		register_clcmd(data[Melee_WeaponList], "@Command_WeaponKnife");

	for (new any:i = 0; i < MAX_MELEE_SOUNDS; i++)
		data[Melee_Sounds][i] = ArrayCreate(MAX_QPATH, 0);

	return ArrayPushArray(g_aMelees, data) + rz_module_get_offset(g_iModule);
}

@native_melee_sound_add(plugin, argc)
{
	enum { arg_melee = 1, arg_melee_sound, arg_sample };

	new melee = get_param(arg_melee);
	new index = rz_module_get_valid_index(g_iModule, melee);

	CHECK_MODULE_VALID_INDEX(index, false)

	new MeleeSound:meleeSound = any:get_param(arg_melee_sound);
	new sample[MAX_QPATH];
	get_string(arg_sample, sample, charsmax(sample));

	precache_sound(sample);

	new data[MeleeData];
	ArrayGetArray(g_aMelees, index, data);

	ArrayPushString(data[Melee_Sounds][meleeSound], sample);
	return true;
}

@native_melee_player_get(plugin, argc)
{
	enum { arg_player = 1 };

	new player = get_param(arg_player);

	return g_iMelee[player];
}

@native_melee_player_set(plugin, argc)
{
	enum { arg_player = 1, arg_melee };

	new player = get_param(arg_player);
	new melee = get_param(arg_melee);

	if (melee != 0)
	{
		new index = rz_module_get_valid_index(g_iModule, melee);

		CHECK_MODULE_VALID_INDEX(index, false)
	}

	g_iMelee[player] = melee;
	return true;
}
