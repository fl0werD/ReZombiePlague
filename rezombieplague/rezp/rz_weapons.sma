#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <reapi>
#include <rezp>
#include <util_messages>

enum _:WeaponData
{
	Weapon_Classname[32],
	Weapon_Reference[32],
	Weapon_Name[64],
	Weapon_ViewModel[MAX_QPATH],
	Weapon_WeaponModel[MAX_QPATH],
	Weapon_WorldModel[MAX_QPATH],
	Weapon_WeaponList[MAX_QPATH],

}; new Array:g_aWeapons;

enum _:Forwards
{
	Fw_Return,
	Fw_Weapon_Grenade_Throw_Pre,
	Fw_Weapon_Grenade_Throw_Post,
	Fw_Weapon_Grenade_Explode_Pre,
	Fw_Weapon_Grenade_Explode_Post,

}; new gForwards[Forwards];

new g_iModule;

public plugin_precache()
{
	register_plugin("[ReZP] Weapons", REZP_VERSION_STR, "fl0wer");

	g_aWeapons = ArrayCreate(WeaponData, 0);
	g_iModule = rz_module_create("weapons", g_aWeapons);
}

public plugin_init()
{
	RegisterHookChain(RG_ThrowHeGrenade, "@ThrowGrenade_Post", true);
	RegisterHookChain(RG_ThrowFlashbang, "@ThrowGrenade_Post", true);
	RegisterHookChain(RG_ThrowSmokeGrenade, "@ThrowGrenade_Post", true);
	RegisterHookChain(RG_CGrenade_ExplodeHeGrenade, "@CGrenade_ExplodeGrenade_Pre", false);
	RegisterHookChain(RG_CGrenade_ExplodeFlashbang, "@CGrenade_ExplodeGrenade_Pre", false);
	RegisterHookChain(RG_CGrenade_ExplodeSmokeGrenade, "@CGrenade_ExplodeGrenade_Pre", false);

	RegisterHookChain(RG_CBasePlayer_AddPlayerItem, "@CBasePlayer_AddPlayerItem_Post", true);
	RegisterHookChain(RG_CBasePlayerWeapon_DefaultDeploy, "@CBasePlayerWeapon_DefaultDeploy_Pre", false);
	RegisterHookChain(RG_CWeaponBox_SetModel, "@CWeaponBox_SetModel_Pre", false);

	gForwards[Fw_Weapon_Grenade_Throw_Pre] = CreateMultiForward("rz_weapon_grenade_throw_pre", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL);
	gForwards[Fw_Weapon_Grenade_Throw_Post] = CreateMultiForward("rz_weapon_grenade_throw_post", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL);
	gForwards[Fw_Weapon_Grenade_Explode_Pre] = CreateMultiForward("rz_weapon_grenade_explode_pre", ET_CONTINUE, FP_CELL, FP_CELL);
	gForwards[Fw_Weapon_Grenade_Explode_Post] = CreateMultiForward("rz_weapon_grenade_explode_post", ET_IGNORE, FP_CELL, FP_CELL);
}

@Command_SelectWeapon(id, impulse)
{
	new index = rz_module_get_valid_index(g_iModule, impulse);

	if (index == -1)
		return PLUGIN_CONTINUE;

	new data[WeaponData];
	ArrayGetArray(g_aWeapons, index, data);

	engclient_cmd(id, data[Weapon_Reference]);
	return PLUGIN_HANDLED;
}

@ThrowGrenade_Post(id, Float:vecStart[3], Float:vecVelocity[3])
{
	new activeItem = get_member(id, m_pActiveItem);

	if (is_nullent(activeItem))
		return;

	new impulse = get_entvar(activeItem, var_impulse);
	new index = rz_module_get_valid_index(g_iModule, impulse);

	if (index == -1)
		return;

	new entity = GetHookChainReturn(ATYPE_INTEGER);

	ExecuteForward(gForwards[Fw_Weapon_Grenade_Throw_Pre], gForwards[Fw_Return], id, entity, impulse);

	if (gForwards[Fw_Return] >= RZ_SUPERCEDE)
		return;

	set_entvar(entity, var_impulse, impulse);

	new data[WeaponData];
	ArrayGetArray(g_aWeapons, index, data);

	if (data[Weapon_WorldModel][0])
		engfunc(EngFunc_SetModel, entity, data[Weapon_WorldModel]);

	ExecuteForward(gForwards[Fw_Weapon_Grenade_Throw_Post], gForwards[Fw_Return], id, entity,  impulse);
}

@CGrenade_ExplodeGrenade_Pre(id)
{
	new impulse = get_entvar(id, var_impulse);
	new index = rz_module_get_valid_index(g_iModule, impulse);

	if (index == -1)
		return HC_CONTINUE;

	ExecuteForward(gForwards[Fw_Weapon_Grenade_Explode_Pre], gForwards[Fw_Return], id, impulse);

	switch (gForwards[Fw_Return])
	{
		case RZ_SUPERCEDE:
		{
			return HC_SUPERCEDE;
		}
		case RZ_BREAK:
		{
			set_entvar(id, var_flags, FL_KILLME);
			return HC_SUPERCEDE;
		}
	}

	ExecuteForward(gForwards[Fw_Weapon_Grenade_Explode_Post], gForwards[Fw_Return], id, impulse);
	return HC_CONTINUE;
}

@CBasePlayer_AddPlayerItem_Post(id, item)
{
	if (!GetHookChainReturn(ATYPE_INTEGER))
		return;

	if (get_member(item, m_iId) == WEAPON_KNIFE)
		return;

	new impulse = get_entvar(item, var_impulse);
	new name[MAX_QPATH];

	if (impulse)
	{
		new index = rz_module_get_valid_index(g_iModule, impulse);

		if (index != -1)
		{
			new data[WeaponData];
			ArrayGetArray(g_aWeapons, index, data);

			if (data[Weapon_WeaponList][0])
				name = data[Weapon_WeaponList];
		}
	}

	if (!name[0])
		rg_get_iteminfo(item, ItemInfo_pszName, name, charsmax(name));

	SendWeaponList
	(
		id,
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
	if (get_member(id, m_iId) == WEAPON_KNIFE)
		return;

	new impulse = get_entvar(id, var_impulse);

	if (!impulse)
		return;

	new index = rz_module_get_valid_index(g_iModule, impulse);

	if (index == -1)
		return;

	new data[WeaponData];
	ArrayGetArray(g_aWeapons, index, data);

	if (data[Weapon_ViewModel][0])
		SetHookChainArg(2, ATYPE_STRING, data[Weapon_ViewModel]);

	if (data[Weapon_WeaponModel][0])
		SetHookChainArg(3, ATYPE_STRING, data[Weapon_WeaponModel]);
}

@CWeaponBox_SetModel_Pre(id, model[])
{
	new item;
	new impulse;
	new index;

	for (new InventorySlotType:i = PRIMARY_WEAPON_SLOT; i <= C4_SLOT; i++)
	{
		item = get_member(id, m_WeaponBox_rgpPlayerItems, i);

		if (is_nullent(item))
			continue;

		impulse = get_entvar(item, var_impulse);

		if (!impulse)
			continue;

		index = rz_module_get_valid_index(g_iModule, impulse);

		if (index == -1)
			break;

		new data[WeaponData];
		ArrayGetArray(g_aWeapons, index, data);

		if (data[Weapon_WorldModel][0])
			SetHookChainArg(2, ATYPE_STRING, data[Weapon_WorldModel]);

		break;
	}
}

public plugin_natives()
{
	register_native("rz_weapon_create", "@native_weapon_create");
	register_native("rz_weapon_get_reference", "@native_weapon_get_reference");
	register_native("rz_weapon_get_name", "@native_weapon_get_name");
	register_native("rz_weapon_find", "@native_weapon_find");
	register_native("rz_weapon_player_give", "@native_weapon_player_give");
}

@native_weapon_create(plugin, argc)
{
	enum { arg_reference = 1, arg_classname, arg_name, arg_model_view, arg_model_weapon, arg_model_model, arg_weaponlist };

	new data[WeaponData];

	get_string(arg_reference, data[Weapon_Reference], charsmax(data[Weapon_Reference]));
	get_string(arg_classname, data[Weapon_Classname], charsmax(data[Weapon_Classname]));
	get_string(arg_name, data[Weapon_Name], charsmax(data[Weapon_Name]));
	get_string(arg_model_view, data[Weapon_ViewModel], charsmax(data[Weapon_ViewModel]));
	get_string(arg_model_weapon, data[Weapon_WeaponModel], charsmax(data[Weapon_WeaponModel]));
	get_string(arg_model_model, data[Weapon_WorldModel], charsmax(data[Weapon_WorldModel]));
	get_string(arg_weaponlist, data[Weapon_WeaponList], charsmax(data[Weapon_WeaponList]));

	if (data[Weapon_ViewModel][0])
		precache_model(data[Weapon_ViewModel]);

	if (data[Weapon_WeaponModel][0])
		precache_model(data[Weapon_WeaponModel]);

	if (data[Weapon_WorldModel][0])
		precache_model(data[Weapon_WorldModel]);
	
	new id = ArrayPushArray(g_aWeapons, data) + rz_module_get_offset(g_iModule);

	if (data[Weapon_WeaponList][0])
	{
		precache_generic(fmt("sprites/%s.txt", data[Weapon_WeaponList]));
		register_clcmd(data[Weapon_WeaponList], "@Command_SelectWeapon", id);
	}

	return id;
}

@native_weapon_get_reference(plugin, argc)
{
	enum { arg_weapon = 1, arg_reference, arg_len };

	new weapon = get_param(arg_weapon);
	new index = rz_module_get_valid_index(g_iModule, weapon);

	CHECK_MODULE_VALID_INDEX(index, false)
	
	new data[WeaponData];
	ArrayGetArray(g_aWeapons, index, data);

	set_string(arg_reference, data[Weapon_Reference], get_param(arg_len));
	return true;
}

@native_weapon_get_name(plugin, argc)
{
	enum { arg_weapon = 1, arg_name, arg_len };

	new weapon = get_param(arg_weapon);
	new index = rz_module_get_valid_index(g_iModule, weapon);

	CHECK_MODULE_VALID_INDEX(index, false)
	
	new data[WeaponData];
	ArrayGetArray(g_aWeapons, index, data);

	set_string(arg_name, data[Weapon_Name], get_param(arg_len));
	return true;
}

@native_weapon_find(plugin, argc)
{
	enum { arg_classname = 1 };

	new classname[32];
	get_string(arg_classname, classname, charsmax(classname));

	new i = ArrayFindString(g_aWeapons, classname);

	if (i != -1)
		return i + rz_module_get_offset(g_iModule);

	return 0;
}

@native_weapon_player_give(plugin, argc)
{
	enum { arg_player = 1, arg_weapon, arg_give_type };

	new player = get_param(arg_player);
	CHECK_ALIVE(player, false)

	new weapon = get_param(arg_weapon);
	new index = rz_module_get_valid_index(g_iModule, weapon);

	CHECK_MODULE_VALID_INDEX(index, false)

	new GiveType:giveType = any:get_param(arg_give_type);
	
	new data[WeaponData];
	ArrayGetArray(g_aWeapons, index, data);

	new item = rg_give_custom_item(player, data[Weapon_Reference], giveType, weapon);

	if (is_nullent(item))
		return 0;

	return item;
}
