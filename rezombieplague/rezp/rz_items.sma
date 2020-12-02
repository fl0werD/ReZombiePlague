#pragma semicolon 1

#include <amxmodx>
#include <rezp>

const ITEMS_MAX_PAGE_ITEMS = 7;

enum _:ItemData
{
	Item_Name[32],
	Item_NameLangKey[32],
	Item_Cost,

}; new Array:g_aItems;

enum Forwards
{
	Fw_Return,
	Fw_Item_Select_Pre,
	Fw_Item_Select_Post,

}; new gForwards[Forwards];

new g_iModule;

public plugin_precache()
{
	register_plugin("[ReZP] Items", REZP_VERSION_STR, "fl0wer");

	g_aItems = ArrayCreate(ItemData, 0);
	g_iModule = rz_module_create("items", g_aItems);
}

public plugin_init()
{
	gForwards[Fw_Item_Select_Pre] = CreateMultiForward("rz_item_select_pre", ET_CONTINUE, FP_CELL, FP_CELL);
	gForwards[Fw_Item_Select_Post] = CreateMultiForward("rz_item_select_post", ET_IGNORE, FP_CELL, FP_CELL);

	rz_load_langs("item");
}

public plugin_natives()
{
	register_native("rz_item_create", "@native_item_create");

	register_native("rz_item_get_name_langkey", "@native_item_get_name_langkey");
	register_native("rz_item_set_name_langkey", "@native_item_set_name_langkey");

	register_native("rz_item_get_cost", "@native_item_get_cost");
	register_native("rz_item_set_cost", "@native_item_set_cost");

	register_native("rz_item_start", "@native_item_start");
	register_native("rz_item_find", "@native_item_find");
	register_native("rz_item_size", "@native_item_size");

	register_native("rz_item_player_get_status", "@native_item_player_get_status");
	register_native("rz_item_player_give", "@native_item_player_give");
}

@native_item_create(plugin, argc)
{
	enum { arg_name = 1 };

	new data[ItemData];
	get_string(arg_name, data[Item_Name], charsmax(data[Item_Name]));

	return ArrayPushArray(g_aItems, data) + rz_module_get_offset(g_iModule);
}

@native_item_get_name_langkey(plugin, argc)
{
	enum { arg_item = 1, arg_name_lang_key, arg_len };

	new item = get_param(arg_item);
	new index = rz_module_get_valid_index(g_iModule, item);

	CHECK_MODULE_VALID_INDEX(index, false)
	
	new data[ItemData];
	ArrayGetArray(g_aItems, index, data);

	if (!data[Item_NameLangKey][0])
		return false;

	set_string(arg_name_lang_key, data[Item_NameLangKey], get_param(arg_len));
	return true;
}

@native_item_set_name_langkey(plugin, argc)
{
	enum { arg_item = 1, arg_name_lang_key };

	new item = get_param(arg_item);
	new index = rz_module_get_valid_index(g_iModule, item);

	CHECK_MODULE_VALID_INDEX(index, false)
	
	new data[ItemData];
	ArrayGetArray(g_aItems, index, data);
	get_string(arg_name_lang_key, data[Item_NameLangKey], charsmax(data[Item_NameLangKey]));
	ArraySetArray(g_aItems, index, data);

	return true;
}

@native_item_get_cost(plugin, argc)
{
	enum { arg_item = 1 };

	new item = get_param(arg_item);
	new index = rz_module_get_valid_index(g_iModule, item);

	CHECK_MODULE_VALID_INDEX(index, 0)

	new data[ItemData];
	ArrayGetArray(g_aItems, index, data);

	return data[Item_Cost];
}

@native_item_set_cost(plugin, argc)
{
	enum { arg_item = 1, arg_cost };

	new item = get_param(arg_item);
	new index = rz_module_get_valid_index(g_iModule, item);

	CHECK_MODULE_VALID_INDEX(index, 0)

	new data[ItemData];
	ArrayGetArray(g_aItems, index, data);
	data[Item_Cost] = get_param(arg_cost);
	ArraySetArray(g_aItems, index, data);

	return true;
}

@native_item_start(plugin, argc)
{
	return rz_module_get_offset(g_iModule);
}

@native_item_find(plugin, argc)
{
	enum { arg_name = 1 };

	new name[32];
	get_string(arg_name, name, charsmax(name));

	new i = ArrayFindString(g_aItems, name);

	if (i != -1)
		return i + rz_module_get_offset(g_iModule);

	return 0;
}

@native_item_size(plugin, argc)
{
	return ArraySize(g_aItems);
}

@native_item_player_get_status(plugin, argc)
{
	enum { arg_player = 1, arg_item };

	new player = get_param(arg_player);

	CHECK_CONNECTED(player, RZ_BREAK)

	new item = get_param(arg_item);
	new index = rz_module_get_valid_index(g_iModule, item);

	CHECK_MODULE_VALID_INDEX(index, RZ_BREAK)

	ExecuteForward(gForwards[Fw_Item_Select_Pre], gForwards[Fw_Return], player, item);
	return gForwards[Fw_Return];
}

@native_item_player_give(plugin, argc)
{
	enum { arg_player = 1, arg_item };

	new player = get_param(arg_player);

	CHECK_CONNECTED(player, false)

	new item = get_param(arg_item);
	new index = rz_module_get_valid_index(g_iModule, item);

	CHECK_MODULE_VALID_INDEX(index, false)

	ExecuteForward(gForwards[Fw_Item_Select_Post], gForwards[Fw_Return], player, item);
	return true;
}
