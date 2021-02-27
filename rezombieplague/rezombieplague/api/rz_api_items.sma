#pragma semicolon 1

#include <amxmodx>
#include <reapi>
#include <rezp>

enum _:ItemData
{
	Item_Handle[RZ_MAX_HANDLE_LENGTH],
	Item_Name[RZ_MAX_LANGKEY_LENGTH],
	Item_Cost,

}; new Array:g_aItems;

new gItemData[ItemData];

enum Forwards
{
	Fw_Return,
	Fw_Items_Select_Pre,
	Fw_Items_Select_Post,

}; new gForwards[Forwards];

new g_iModule;

public plugin_precache()
{
	register_plugin("[ReZP] API: Items", REZP_VERSION_STR, "fl0wer");

	g_aItems = ArrayCreate(ItemData, 0);
	g_iModule = rz_module_create("items", g_aItems);
}

public plugin_init()
{
	gForwards[Fw_Items_Select_Pre] = CreateMultiForward("rz_items_select_pre", ET_CONTINUE, FP_CELL, FP_CELL);
	gForwards[Fw_Items_Select_Post] = CreateMultiForward("rz_items_select_post", ET_IGNORE, FP_CELL, FP_CELL);

	rz_load_langs("items");
}

@Command_BuyExtra(id, item)
{
	if (!is_user_alive(id))
		return false;

	new index = rz_module_get_valid_index(g_iModule, item);

	if (index == -1)
		return false;

	ExecuteForward(gForwards[Fw_Items_Select_Pre], gForwards[Fw_Return], id, item);

	if (gForwards[Fw_Return] >= RZ_SUPERCEDE)
		return false;

	ArrayGetArray(g_aItems, index, gItemData);

	new cost = gItemData[Item_Cost];
	new name[RZ_MAX_LANGKEY_LENGTH];

	if (get_member(id, m_iAccount) < cost)
	{
		rz_print_chat(id, print_team_default, "%L", LANG_PLAYER, "RZ_ITEMS_INSUFFICIENT_FUNDS",
			LANG_PLAYER, gItemData[Item_Name],
			LANG_PLAYER, rz_main_get(RZ_MAIN_AMMOPACKS_ENABLED) ? "RZ_FMT_AMMOPACKS" : "RZ_FMT_DOLLARS", cost);
		return false;
	}

	ExecuteForward(gForwards[Fw_Items_Select_Post], gForwards[Fw_Return], id, item);
	
	rg_add_account(id, -cost);
	rz_print_chat(0, id, "%l", "RZ_ITEMS_PLAYER_BOUGHT", id, name);
	return PLUGIN_HANDLED;
}

public plugin_natives()
{
	register_native("rz_item_create", "@native_item_create");
	register_native("rz_item_get", "@native_item_get");
	register_native("rz_item_set", "@native_item_set");
	register_native("rz_item_command_add", "@native_item_command_add");

	register_native("rz_items_start", "@native_items_start");
	register_native("rz_items_find", "@native_items_find");
	register_native("rz_items_size", "@native_items_size");
	register_native("rz_items_player_get_status", "@native_items_player_get_status");
	register_native("rz_items_player_give", "@native_items_player_give");
}

@native_item_create(plugin, argc)
{
	enum { arg_handle = 1 };

	new data[ItemData];

	get_string(arg_handle, data[Item_Handle], charsmax(data[Item_Handle]));

	return ArrayPushArray(g_aItems, data) + rz_module_get_offset(g_iModule);
}

@native_item_get(plugin, argc)
{
	enum { arg_item = 1, arg_prop, arg_3, arg_4 };

	new item = get_param(arg_item);
	new index = rz_module_get_valid_index(g_iModule, item);

	RZ_CHECK_MODULE_VALID_INDEX(index, false)
	
	ArrayGetArray(g_aItems, index, gItemData);

	new prop = get_param(arg_prop);

	switch (prop)
	{
		case RZ_ITEM_HANDLE:
		{
			set_string(arg_3, gItemData[Item_Handle], get_param_byref(arg_4));
		}
		case RZ_ITEM_NAME:
		{
			set_string(arg_3, gItemData[Item_Name], get_param_byref(arg_4));
		}
		case RZ_ITEM_COST:
		{
			return gItemData[Item_Cost];
		}
		default:
		{
			rz_log(true, "Item property '%d' not found for '%s'", prop, gItemData[Item_Handle]);
			return false;
		}
	}

	return true;
}

@native_item_set(plugin, argc)
{
	enum { arg_item = 1, arg_prop, arg_3 };

	new item = get_param(arg_item);
	new index = rz_module_get_valid_index(g_iModule, item);

	RZ_CHECK_MODULE_VALID_INDEX(index, false)

	ArrayGetArray(g_aItems, index, gItemData);

	new prop = get_param(arg_prop);

	switch (prop)
	{
		case RZ_ITEM_HANDLE:
		{
			get_string(arg_3, gItemData[Item_Handle], charsmax(gItemData[Item_Handle]));
		}
		case RZ_ITEM_NAME:
		{
			get_string(arg_3, gItemData[Item_Name], charsmax(gItemData[Item_Handle]));
		}
		case RZ_ITEM_COST:
		{
			gItemData[Item_Cost] = get_param_byref(arg_3);
		}
		default:
		{
			rz_log(true, "Item property '%d' not found for '%s'", prop, gItemData[Item_Handle]);
			return false;
		}
	}

	ArraySetArray(g_aItems, index, gItemData);
	return true;
}

@native_item_command_add(plugin, argc)
{
	enum { arg_item = 1, arg_command };

	new item = get_param(arg_item);
	new index = rz_module_get_valid_index(g_iModule, item);

	RZ_CHECK_MODULE_VALID_INDEX(index, false)

	new command[32];
	get_string(arg_command, command, charsmax(command));

	if (!command[0])
		return false;

	register_clcmd(command, "@Command_BuyExtra", item);
	return true;
}

@native_items_start(plugin, argc)
{
	return rz_module_get_offset(g_iModule);
}

@native_items_find(plugin, argc)
{
	enum { arg_handle = 1 };

	new handle[RZ_MAX_HANDLE_LENGTH];
	get_string(arg_handle, handle, charsmax(handle));

	new i = ArrayFindString(g_aItems, handle);

	if (i != -1)
		return i + rz_module_get_offset(g_iModule);

	return 0;
}

@native_items_size(plugin, argc)
{
	return ArraySize(g_aItems);
}

@native_items_player_get_status(plugin, argc)
{
	enum { arg_player = 1, arg_item };

	new player = get_param(arg_player);

	RZ_CHECK_CONNECTED(player, RZ_BREAK)

	new item = get_param(arg_item);
	new index = rz_module_get_valid_index(g_iModule, item);

	RZ_CHECK_MODULE_VALID_INDEX(index, RZ_BREAK)

	ExecuteForward(gForwards[Fw_Items_Select_Pre], gForwards[Fw_Return], player, item);
	return gForwards[Fw_Return];
}

@native_items_player_give(plugin, argc)
{
	enum { arg_player = 1, arg_item };

	new player = get_param(arg_player);

	RZ_CHECK_CONNECTED(player, false)

	new item = get_param(arg_item);
	new index = rz_module_get_valid_index(g_iModule, item);

	RZ_CHECK_MODULE_VALID_INDEX(index, false)

	ExecuteForward(gForwards[Fw_Items_Select_Post], gForwards[Fw_Return], player, item);
	return true;
}
