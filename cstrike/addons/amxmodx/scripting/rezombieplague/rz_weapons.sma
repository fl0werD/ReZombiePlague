#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <reapi>
#include <rezp>
#include <util_messages>

public plugin_precache()
{
	register_plugin("[ReZP] Weapons", REZP_VERSION_STR, "fl0wer");
}

public plugin_init()
{
	RegisterHookChain(RG_CBasePlayer_AddPlayerItem, "@CBasePlayer_AddPlayerItem_Post", true);
	RegisterHookChain(RG_CBasePlayerWeapon_DefaultDeploy, "@CBasePlayerWeapon_DefaultDeploy_Pre", false);
	RegisterHookChain(RG_CWeaponBox_SetModel, "@CWeaponBox_SetModel_Pre", false);

	new weaponName[RZ_MAX_REFERENCE_LENGTH];

	for (new i = 1; i < MAX_WEAPONS - 1; i++)
	{
		if ((1<<i) & ((1<<CSW_GLOCK) | (1<<CSW_C4)))
			continue;

		rg_get_weapon_info(WeaponIdType:i, WI_NAME, weaponName, charsmax(weaponName));

		RegisterHam(Ham_Spawn, weaponName, "@CBasePlayerWeapon_Spawn_Post", true);
	}

	rz_load_langs("weapons");
}

@SV_StartSound_Pre(recipients, entity, channel, sample[], volume, Float:attenuation, flags, pitch)	
{
	if (sample[8] != 'k' || sample[9] != 'n' || sample[10] != 'i')
		return;

	if (!is_user_connected(entity))
		return;

	new activeItem = get_member(entity, m_pActiveItem);

	if (is_nullent(activeItem))
		return;

	new impulse = get_entvar(activeItem, var_impulse);

	if (rz_knifes_valid(impulse))
	{
		new RZKnifeSound:knifeSound = RZ_KNIFE_SOUND_NONE;

		if (sample[14] == 'd' && sample[15] == 'e' && sample[16] == 'p')
		{
			knifeSound = RZ_KNIFE_SOUND_DEPLOY;
		}
		else if (sample[14] == 's' && sample[15] == 'l' && sample[16] == 'a')
		{
			knifeSound = RZ_KNIFE_SOUND_SLASH;
		}
		else if (sample[14] == 'h' && sample[15] == 'i' && sample[16] == 't')
		{
			knifeSound = (sample[17] == 'w') ? RZ_KNIFE_SOUND_HITWALL : RZ_KNIFE_SOUND_HIT;
		}
		else if (sample[14] == 's' && sample[15] == 't' && sample[16] == 'a')
		{
			knifeSound = RZ_KNIFE_SOUND_STAB;
		}

		if (knifeSound != RZ_KNIFE_SOUND_NONE)
		{
			new Array:sounds = rz_knife_get(impulse, RZ_KNIFE_SOUNDS_BANK, knifeSound);
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

@CBasePlayer_AddPlayerItem_Post(id, item)
{
	if (!GetHookChainReturn(ATYPE_INTEGER))
		return;

	new impulse = get_entvar(item, var_impulse);
	new name[RZ_MAX_RESOURCE_PATH];

	if (impulse)
	{
		switch (get_member(item, m_iId))
		{
			case WEAPON_KNIFE:
			{
				if (rz_knifes_valid(impulse))
					rz_knife_get(impulse, RZ_KNIFE_WEAPONLIST, name, charsmax(name));
			}
			case WEAPON_HEGRENADE, WEAPON_FLASHBANG, WEAPON_SMOKEGRENADE:
			{
				if (rz_grenades_valid(impulse))
					rz_grenade_get(impulse, RZ_GRENADE_WEAPONLIST, name, charsmax(name));
			}
			default:
			{
				if (rz_weapons_valid(impulse))
					rz_weapon_get(impulse, RZ_WEAPON_WEAPONLIST, name, charsmax(name));
			}
		}
	}

	if (!name[0])
		rg_get_iteminfo(item, ItemInfo_pszName, name, charsmax(name));

	message_begin(MSG_ONE, gmsgWeaponList, _, id);
	SendWeaponList
	(
		name,
		get_member(item, m_Weapon_iPrimaryAmmoType),
		rg_get_iteminfo(item, ItemInfo_iMaxAmmo1),
		get_member(item, m_Weapon_iSecondaryAmmoType),
		rg_get_iteminfo(item, ItemInfo_iMaxAmmo2),
		rg_get_iteminfo(item, ItemInfo_iSlot),
		rg_get_iteminfo(item, ItemInfo_iPosition),
		rg_get_iteminfo(item, ItemInfo_iId),
		rg_get_iteminfo(item, ItemInfo_iFlags)
	);
}

@CBasePlayerWeapon_DefaultDeploy_Pre(id, viewModel[], weaponModel[], anim, animExt[], skiplocal)
{
	new impulse = get_entvar(id, var_impulse);

	if (!impulse)
		return;

	new newViewModel[RZ_MAX_RESOURCE_PATH];
	new newPlayerModel[RZ_MAX_RESOURCE_PATH];

	switch (get_member(id, m_iId))
	{
		case WEAPON_KNIFE:
		{
			if (rz_knifes_valid(impulse))
			{
				rz_knife_get(impulse, RZ_KNIFE_VIEW_MODEL, newViewModel, charsmax(newViewModel));
				rz_knife_get(impulse, RZ_KNIFE_PLAYER_MODEL, newPlayerModel, charsmax(newPlayerModel));
			}
			else
				return;
		}
		case WEAPON_HEGRENADE, WEAPON_FLASHBANG, WEAPON_SMOKEGRENADE:
		{
			if (rz_grenades_valid(impulse))
			{
				rz_grenade_get(impulse, RZ_GRENADE_VIEW_MODEL, newViewModel, charsmax(newViewModel));
				rz_grenade_get(impulse, RZ_GRENADE_PLAYER_MODEL, newPlayerModel, charsmax(newPlayerModel));
			}
			else
				return;
		}
		default:
		{
			if (rz_weapons_valid(impulse))
			{
				rz_weapon_get(impulse, RZ_WEAPON_VIEW_MODEL, newViewModel, charsmax(newViewModel));
				rz_weapon_get(impulse, RZ_WEAPON_PLAYER_MODEL, newPlayerModel, charsmax(newPlayerModel));
			}
			else
				return;
		}
	}

	if (newViewModel[0])
		SetHookChainArg(2, ATYPE_STRING, newViewModel);

	if (equal(newPlayerModel, "hide"))
		SetHookChainArg(3, ATYPE_STRING, "");
	else if (newPlayerModel[0])
		SetHookChainArg(3, ATYPE_STRING, newPlayerModel);
}

@CWeaponBox_SetModel_Pre(id, model[])
{
	new item;
	new impulse;
	new worldModel[RZ_MAX_RESOURCE_PATH];

	for (new InventorySlotType:i = PRIMARY_WEAPON_SLOT; i <= PISTOL_SLOT; i++)
	{
		item = get_member(id, m_WeaponBox_rgpPlayerItems, i);

		if (is_nullent(item))
			continue;

		impulse = get_entvar(item, var_impulse);

		if (!impulse)
			continue;

		if (rz_weapons_valid(impulse))
		{
			rz_weapon_get(impulse, RZ_WEAPON_WORLD_MODEL, worldModel, charsmax(worldModel));

			if (worldModel[0])
				SetHookChainArg(2, ATYPE_STRING, worldModel);

			break;
		}
	}
}

@CBasePlayerWeapon_Spawn_Post(id)
{
	new impulse = get_entvar(id, var_impulse);

	if (!impulse)
		return;

	new WeaponIdType:weaponId = get_member(id, m_iId);

	switch (weaponId)
	{
		case WEAPON_KNIFE:
		{
			if (rz_knifes_valid(impulse))
			{
				SetMemberByProp(id, m_Knife_flStabBaseDamage, rz_knife_get(impulse, RZ_KNIFE_STAB_BASE_DAMAGE));
				SetMemberByProp(id, m_Knife_flSwingBaseDamage, rz_knife_get(impulse, RZ_KNIFE_SWING_BASE_DAMAGE));
				SetMemberByProp(id, m_Knife_flStabDistance, rz_knife_get(impulse, RZ_KNIFE_STAB_DISTANCE));
				SetMemberByProp(id, m_Knife_flSwingDistance, rz_knife_get(impulse, RZ_KNIFE_SWING_DISTANCE));
			}
		}
		case WEAPON_HEGRENADE, WEAPON_FLASHBANG, WEAPON_SMOKEGRENADE:
		{
		}
		default:
		{
			if (rz_weapons_valid(impulse))
			{
				SetMemberByProp(id, m_Weapon_flBaseDamage, rz_weapon_get(impulse, RZ_WEAPON_BASE_DAMAGE));

				switch (weaponId)
				{
					case WEAPON_FAMAS: SetMemberByProp(id, m_Famas_flBaseDamageBurst, rz_weapon_get(impulse, RZ_WEAPON_BASE_DAMAGE2));
					case WEAPON_USP: SetMemberByProp(id, m_USP_flBaseDamageSil, rz_weapon_get(impulse, RZ_WEAPON_BASE_DAMAGE2));
					case WEAPON_M4A1: SetMemberByProp(id, m_M4A1_flBaseDamageSil, rz_weapon_get(impulse, RZ_WEAPON_BASE_DAMAGE2));
				}
			}
		}
	}
}

SetMemberByProp(id, any:member, Float:value)
{
	if (!value)
		return;
	
	set_member(id, member, value);
}
