#pragma semicolon 1

#include <amxmodx>
#include <rezp>

enum _:SubclassData
{
	Subclass_Handle[RZ_MAX_HANDLE_LENGTH],
	Subclass_Class,
	Subclass_Name[RZ_MAX_LANGKEY_LENGTH],
	Subclass_Desc[RZ_MAX_LANGKEY_LENGTH],
	Subclass_PlayerProps,
	Subclass_PlayerModel,
	Subclass_PlayerSound,
	Subclass_Knife,
	Subclass_NightVision,

}; new Array:g_aSubclasses;

new gSubclassData[SubclassData];

enum _:Forwards
{
	Fw_Return,
	Fw_Subclass_Change_Pre,
	Fw_Subclass_Change_Post,

}; new gForwards[Forwards];

new Trie:g_tDefaultSubclass;

new g_iModule;

public plugin_precache()
{
	register_plugin("[ReZP] API: Player Subclass", REZP_VERSION_STR, "fl0wer");

	g_aSubclasses = ArrayCreate(SubclassData, 0);
	g_iModule = rz_module_create("player_subclass", g_aSubclasses);

	g_tDefaultSubclass = TrieCreate();
}

public plugin_init()
{
	gForwards[Fw_Subclass_Change_Pre] = CreateMultiForward("rz_subclass_change_pre", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL);
	gForwards[Fw_Subclass_Change_Post] = CreateMultiForward("rz_subclass_change_post", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL);
}

ChangeSubclass(id, subclass, bool:instant = false)
{
	new index = rz_module_get_valid_index(g_iModule, subclass);

	if (index == -1)
		return false;

	ExecuteForward(gForwards[Fw_Subclass_Change_Pre], gForwards[Fw_Return], id, subclass, instant);

	if (gForwards[Fw_Return] >= RZ_SUPERCEDE)
		return false;

	ExecuteForward(gForwards[Fw_Subclass_Change_Post], gForwards[Fw_Return], id, subclass, instant);
	return true;
}

ClassToStr(class)
{
	new key[12];
	num_to_str(class, key, charsmax(key));

	return key;
}

public plugin_natives()
{
	register_native("rz_subclass_create", "@native_subclass_create");

	register_native("rz_subclass_get", "@native_subclass_get");
	register_native("rz_subclass_set", "@native_subclass_set");
	register_native("rz_subclass_start", "@native_subclass_start");
	register_native("rz_subclass_find", "@native_subclass_find");
	register_native("rz_subclass_size", "@native_subclass_size");

	register_native("rz_subclass_get_default", "@native_subclass_get_default");
	register_native("rz_subclass_set_default", "@native_subclass_set_default");

	register_native("rz_subclass_player_change", "@native_subclass_player_change");
	register_native("rz_subclass_player_get_status", "@native_subclass_player_get_status");
}

@native_subclass_create(plugin, argc)
{
	enum { arg_handle = 1, arg_class };

	new class = get_param(arg_class);
	new data[SubclassData];

	data[Subclass_Class] = class;
	get_string(arg_handle, data[Subclass_Handle], charsmax(data[Subclass_Handle]));
	data[Subclass_PlayerProps] = rz_playerprops_create(fmt("%s_playerprops", data[Subclass_Handle]));
	data[Subclass_PlayerModel] = rz_playermodel_create(fmt("%s_playermodels", data[Subclass_Handle]));
	data[Subclass_PlayerSound] = rz_playersound_create(fmt("%s_playersounds", data[Subclass_Handle]));
	data[Subclass_NightVision] = rz_nightvision_create(fmt("%s_nightvision", data[Subclass_Handle]));

	new id = ArrayPushArray(g_aSubclasses, data) + rz_module_get_offset(g_iModule);

	TrieSetCell(g_tDefaultSubclass, ClassToStr(class), id, false);
	return id;
}

@native_subclass_get(plugin, argc)
{
	enum { arg_subclass = 1, arg_prop, arg_3, arg_4 };

	new subclass = get_param(arg_subclass);
	new index = rz_module_get_valid_index(g_iModule, subclass);

	RZ_CHECK_MODULE_VALID_INDEX(index, false)
	
	ArrayGetArray(g_aSubclasses, index, gSubclassData);

	new prop = get_param(arg_prop);

	switch (prop)
	{
		case RZ_SUBCLASS_HANDLE:
		{
			set_string(arg_3, gSubclassData[Subclass_Handle], get_param_byref(arg_4));
		}
		case RZ_SUBCLASS_CLASS:
		{
			return any:gSubclassData[Subclass_Class];
		}
		case RZ_SUBCLASS_NAME:
		{
			set_string(arg_3, gSubclassData[Subclass_Name], get_param_byref(arg_4));
		}
		case RZ_SUBCLASS_DESC:
		{
			set_string(arg_3, gSubclassData[Subclass_Desc], get_param_byref(arg_4));
		}
		case RZ_SUBCLASS_PROPS:
		{
			return gSubclassData[Subclass_PlayerProps];
		}
		case RZ_SUBCLASS_MODEL:
		{
			return gSubclassData[Subclass_PlayerModel];
		}
		case RZ_SUBCLASS_SOUND:
		{
			return gSubclassData[Subclass_PlayerSound];
		}
		case RZ_SUBCLASS_KNIFE:
		{
			return gSubclassData[Subclass_Knife];
		}
		case RZ_SUBCLASS_NIGHTVISION:
		{
			return gSubclassData[Subclass_NightVision];
		}
		default:
		{
			rz_log(true, "Player subclass property '%d' not found for '%s'", prop, gSubclassData[Subclass_Handle]);
			return false;
		}
	}

	return true;
}

@native_subclass_set(plugin, argc)
{
	enum { arg_subclass = 1, arg_prop, arg_3 };

	new subclass = get_param(arg_subclass);
	new index = rz_module_get_valid_index(g_iModule, subclass);

	RZ_CHECK_MODULE_VALID_INDEX(index, false)
	
	ArrayGetArray(g_aSubclasses, index, gSubclassData);

	new prop = get_param(arg_prop);

	switch (prop)
	{
		case RZ_SUBCLASS_HANDLE:
		{
			get_string(arg_3, gSubclassData[Subclass_Handle], charsmax(gSubclassData[Subclass_Handle]));
		}
		case RZ_SUBCLASS_CLASS:
		{
			gSubclassData[Subclass_Class] = get_param_byref(arg_3);
		}
		case RZ_SUBCLASS_NAME:
		{
			get_string(arg_3, gSubclassData[Subclass_Name], charsmax(gSubclassData[Subclass_Name]));
		}
		case RZ_SUBCLASS_DESC:
		{
			get_string(arg_3, gSubclassData[Subclass_Desc], charsmax(gSubclassData[Subclass_Desc]));
		}
		case RZ_SUBCLASS_PROPS:
		{
			gSubclassData[Subclass_PlayerProps] = get_param_byref(arg_3);
		}
		case RZ_SUBCLASS_MODEL:
		{
			gSubclassData[Subclass_PlayerModel] = get_param_byref(arg_3);
		}
		case RZ_SUBCLASS_SOUND:
		{
			gSubclassData[Subclass_PlayerSound] = get_param_byref(arg_3);
		}
		case RZ_SUBCLASS_KNIFE:
		{
			gSubclassData[Subclass_Knife] = get_param_byref(arg_3);
		}
		case RZ_SUBCLASS_NIGHTVISION:
		{
			gSubclassData[Subclass_NightVision] = get_param_byref(arg_3);
		}
		default:
		{
			rz_log(true, "Player subclass property '%d' not found for '%s'", prop, gSubclassData[Subclass_Handle]);
			return false;
		}
	}

	ArraySetArray(g_aSubclasses, index, gSubclassData);
	return true;
}

@native_subclass_start(plugin, argc)
{
	return rz_module_get_offset(g_iModule);
}

@native_subclass_find(plugin, argc)
{
	enum { arg_handle = 1 };

	new handle[RZ_MAX_HANDLE_LENGTH];
	get_string(arg_handle, handle, charsmax(handle));

	new i = ArrayFindString(g_aSubclasses, handle);

	if (i != -1)
		return i + rz_module_get_offset(g_iModule);

	return 0;
}

@native_subclass_size(plugin, argc)
{
	return ArraySize(g_aSubclasses);
}

@native_subclass_get_default(plugin, argc)
{
	enum { arg_class = 1 };

	new class = get_param(arg_class);
	new value;

	TrieGetCell(g_tDefaultSubclass, ClassToStr(class), value);
	return value;
}

@native_subclass_set_default(plugin, argc)
{
	enum { arg_class = 1, arg_subclass };

	new class = get_param(arg_class);
	new subclass = get_param(arg_subclass);

	TrieSetCell(g_tDefaultSubclass, ClassToStr(class), subclass);
	return true;
}

@native_subclass_player_change(plugin, argc)
{
	enum { arg_player = 1, arg_subclass, arg_instant };

	new player = get_param(arg_player);
	new subclass = get_param(arg_subclass);

	return ChangeSubclass(player, subclass, any:get_param(arg_instant));
}

@native_subclass_player_get_status(plugin, argc)
{
	enum { arg_player = 1, arg_subclass };

	new player = get_param(arg_player);

	RZ_CHECK_CONNECTED(player, RZ_BREAK)

	new subclass = get_param(arg_subclass);
	new index = rz_module_get_valid_index(g_iModule, subclass);

	RZ_CHECK_MODULE_VALID_INDEX(index, RZ_BREAK)

	ExecuteForward(gForwards[Fw_Subclass_Change_Pre], gForwards[Fw_Return], player, subclass, false);
	return gForwards[Fw_Return];
}
