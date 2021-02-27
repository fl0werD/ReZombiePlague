#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <reapi>
#include <rezp>

new mp_infinite_ammo;

public plugin_init()
{
	register_plugin("[ReZP] Addon: Buy Ammo", REZP_VERSION_STR, "fl0wer");

	register_clcmd("buyammo1", "@Command_BuyAmmo", any:PRIMARY_WEAPON_SLOT);
	register_clcmd("buyammo2", "@Command_BuyAmmo", any:PISTOL_SLOT);
}

public plugin_cfg()
{
	bind_pcvar_num(get_cvar_pointer("mp_infinite_ammo"), mp_infinite_ammo);
}

@Command_BuyAmmo(id, InventorySlotType:slotType)
{
	if (mp_infinite_ammo == 2)
		return PLUGIN_CONTINUE;

	if (!rz_main_get(RZ_MAIN_AMMOPACKS_ENABLED))
		return PLUGIN_CONTINUE;

	if (!is_user_alive(id))
		return PLUGIN_CONTINUE;

	if (get_member(id, m_iAccount) < 1)
	{
		rz_print_chat(id, print_team_default, "You don't have enough ammo packs.");
		return PLUGIN_HANDLED;
	}

	new weapon;
	new ammo;
	new maxAmmo;
	new ammoName[16];
	new bool:refilled;

	for (new InventorySlotType:i = PRIMARY_WEAPON_SLOT; i <= PISTOL_SLOT; i++)
	{
		weapon = get_member(id, m_rgpPlayerItems, i);

		if (is_nullent(weapon))
			continue;

		ammo = get_member(id, m_rgAmmo, get_member(weapon, m_Weapon_iPrimaryAmmoType));
		maxAmmo = rg_get_iteminfo(weapon, ItemInfo_iMaxAmmo1);

		if (ammo >= maxAmmo)
			continue;

		rg_get_iteminfo(weapon, ItemInfo_pszAmmo1, ammoName, charsmax(ammoName));

		if (ExecuteHam(Ham_GiveAmmo, id, maxAmmo, ammoName, maxAmmo) == -1)
			continue;

		refilled = true;
	}

	if (!refilled)
		return PLUGIN_HANDLED;

	rg_add_account(id, -1);
	rh_emit_sound2(id, 0, CHAN_ITEM, "items/9mmclip1.wav", VOL_NORM, ATTN_NORM);
	rz_print_chat(id, print_team_default, "You purchased extra ammo for your guns.");

	return PLUGIN_HANDLED;
}

@CBasePlayer_Spawn_Post(id)
{
	if (mp_infinite_ammo == 2)
		return;

	if (!rz_main_get(RZ_MAIN_AMMOPACKS_ENABLED))
		return;

	if (!is_user_alive(id))
		return;

	if (get_member(id, m_iNumSpawns) != 1)
		return;

	rz_print_chat(id, print_team_default, "%L", LANG_PLAYER, "RZ_PRESS_BUY_AMMO");
}
