#pragma semicolon 1

#include <amxmodx>
#include <hamsandwich>
#include <reapi>
#include <rezp>

enum _:SubclassData
{
	Subclass_Class,
	Subclass_Name[32],
	Subclass_NameLangKey[32],
	Subclass_DescLangKey[32],
	Subclass_Props,
	Subclass_PlayerModel,
	Subclass_PlayerSound,
	Subclass_Melee,
	Subclass_NightVision,

}; new Array:g_aSubclasses;

enum _:Forwards
{
	Fw_Return,
	Fw_Subclass_Change_Pre,
	Fw_Subclass_Change_Post,

}; new gForwards[Forwards];

new g_iSubclass[MAX_PLAYERS + 1];
new Trie:g_tDefaultSubclass;
new Trie:g_tChosenSubclass[MAX_PLAYERS + 1];

new g_iModule;

public plugin_precache()
{
	register_plugin("[ReZP] Player: Subclass", REZP_VERSION_STR, "fl0wer");

	g_aSubclasses = ArrayCreate(SubclassData, 0);
	g_iModule = rz_module_create("player_subclass", g_aSubclasses);

	g_tDefaultSubclass = TrieCreate();
	
	for (new i = 1; i <= MaxClients; i++)
		g_tChosenSubclass[i] = TrieCreate();
}

public plugin_init()
{
	gForwards[Fw_Subclass_Change_Pre] = CreateMultiForward("rz_subclass_change_pre", ET_CONTINUE, FP_CELL, FP_CELL);
	gForwards[Fw_Subclass_Change_Post] = CreateMultiForward("rz_subclass_change_post", ET_IGNORE, FP_CELL, FP_CELL);
	
	rz_load_langs("subclass");
}

public client_putinserver(id)
{
	TrieClear(g_tChosenSubclass[id]);
}

public rz_class_change_post(id, attacker, class)
{
	new subclass;
	new defaultSubclass;
	new key[12];

	key = ClassToStr(class);

	if (!TrieGetCell(g_tDefaultSubclass, key, defaultSubclass))
		return;

	if (TrieGetCell(g_tChosenSubclass[id], key, subclass))
		ChangeSubclass(id, subclass);
	else
		ChangeSubclass(id, defaultSubclass);
}

ChangeSubclass(id, subclass, bool:instant = false)
{
	new index = rz_module_get_valid_index(g_iModule, subclass);

	if (index == -1)
		return;

	ExecuteForward(gForwards[Fw_Subclass_Change_Pre], gForwards[Fw_Return], id, subclass);

	new data[SubclassData];
	ArrayGetArray(g_aSubclasses, index, data);
	
	g_iSubclass[id] = subclass;

	if (data[Subclass_Props])
		rz_props_player_set(id, data[Subclass_Props]);

	if (data[Subclass_PlayerModel])
		rz_playermodel_player_set(id, data[Subclass_PlayerModel]);

	if (data[Subclass_PlayerSound])
		rz_playersound_player_set(id, data[Subclass_PlayerSound]);
	
	if (data[Subclass_Melee])
		rz_melee_player_set(id, data[Subclass_Melee]);
	
	if (data[Subclass_NightVision])
		rz_nightvision_player_set(id, data[Subclass_NightVision]);

	if (instant)
	{
		rg_give_default_items(id);
		rz_props_player_change(id);
		rz_playermodel_player_change(id);
	}

	ExecuteForward(gForwards[Fw_Subclass_Change_Post], gForwards[Fw_Return], id, subclass);
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

	register_native("rz_subclass_get_class", "@native_subclass_get_class");
	register_native("rz_subclass_get_name", "@native_subclass_get_name");

	register_native("rz_subclass_get_name_langkey", "@native_subclass_get_name_langkey");
	register_native("rz_subclass_set_name_langkey", "@native_subclass_set_name_langkey");

	register_native("rz_subclass_get_desc_langkey", "@native_subclass_get_desc_langkey");
	register_native("rz_subclass_set_desc_langkey", "@native_subclass_set_desc_langkey");

	register_native("rz_subclass_get_props", "@native_subclass_get_props");
	register_native("rz_subclass_set_props", "@native_subclass_set_props");

	register_native("rz_subclass_get_playermodel", "@native_subclass_get_playermodel");
	register_native("rz_subclass_set_playermodel", "@native_subclass_set_playermodel");

	register_native("rz_subclass_get_playersound", "@native_subclass_get_playersound");
	register_native("rz_subclass_set_playersound", "@native_subclass_set_playersound");

	register_native("rz_subclass_get_melee", "@native_subclass_get_melee");
	register_native("rz_subclass_set_melee", "@native_subclass_set_melee");

	register_native("rz_subclass_get_nightvision", "@native_subclass_get_nightvision");
	register_native("rz_subclass_set_nightvision", "@native_subclass_set_nightvision");

	register_native("rz_subclass_get_default", "@native_subclass_get_default");
	register_native("rz_subclass_set_default", "@native_subclass_set_default");

	register_native("rz_subclass_start", "@native_subclass_start");
	register_native("rz_subclass_find", "@native_subclass_find");
	register_native("rz_subclass_size", "@native_subclass_size");

	register_native("rz_subclass_player_get", "@native_subclass_player_get");
	register_native("rz_subclass_player_set", "@native_subclass_player_set");
	register_native("rz_subclass_player_change", "@native_subclass_player_change");
	register_native("rz_subclass_player_get_status", "@native_subclass_player_get_status");

	register_native("rz_subclass_player_get_chosen", "@native_subclass_player_get_chosen");
	register_native("rz_subclass_player_set_chosen", "@native_subclass_player_set_chosen");
}

@native_subclass_create(plugin, argc)
{
	enum { arg_class = 1, arg_name };

	new class = get_param(arg_class);
	new data[SubclassData];

	data[Subclass_Class] = class;
	get_string(arg_name, data[Subclass_Name], charsmax(data[Subclass_Name]));

	new id = ArrayPushArray(g_aSubclasses, data) + rz_module_get_offset(g_iModule);

	TrieSetCell(g_tDefaultSubclass, ClassToStr(class), id, false);

	return id;
}

@native_subclass_get_class(plugin, argc)
{
	enum { arg_subclass = 1 };

	new subclass = get_param(arg_subclass);
	new index = rz_module_get_valid_index(g_iModule, subclass);

	CHECK_MODULE_VALID_INDEX(index, 0)

	new data[SubclassData];
	ArrayGetArray(g_aSubclasses, index, data);

	return data[Subclass_Class];
}

@native_subclass_get_name(plugin, argc)
{
	enum { arg_subclass = 1, arg_name, arg_len };

	new subclass = get_param(arg_subclass);
	new index = rz_module_get_valid_index(g_iModule, subclass);

	CHECK_MODULE_VALID_INDEX(index, false)
	
	new data[SubclassData];
	ArrayGetArray(g_aSubclasses, index, data);

	set_string(arg_name, data[Subclass_Name], get_param(arg_len));
	return true;
}

@native_subclass_get_name_langkey(plugin, argc)
{
	enum { arg_subclass = 1, arg_name_lang_key, arg_len };

	new subclass = get_param(arg_subclass);
	new index = rz_module_get_valid_index(g_iModule, subclass);

	CHECK_MODULE_VALID_INDEX(index, false)
	
	new data[SubclassData];
	ArrayGetArray(g_aSubclasses, index, data);

	if (!data[Subclass_NameLangKey][0])
		return false;

	set_string(arg_name_lang_key, data[Subclass_NameLangKey], get_param(arg_len));
	return true;
}

@native_subclass_set_name_langkey(plugin, argc)
{
	enum { arg_subclass = 1, arg_name_lang_key };

	new subclass = get_param(arg_subclass);
	new index = rz_module_get_valid_index(g_iModule, subclass);

	CHECK_MODULE_VALID_INDEX(index, false)

	new data[SubclassData];
	ArrayGetArray(g_aSubclasses, index, data);
	get_string(arg_name_lang_key, data[Subclass_NameLangKey], charsmax(data[Subclass_NameLangKey]));
	ArraySetArray(g_aSubclasses, index, data);

	return true;
}

@native_subclass_get_desc_langkey(plugin, argc)
{
	enum { arg_subclass = 1, arg_desc_lang_key, arg_len };

	new subclass = get_param(arg_subclass);
	new index = rz_module_get_valid_index(g_iModule, subclass);

	CHECK_MODULE_VALID_INDEX(index, false)
	
	new data[SubclassData];
	ArrayGetArray(g_aSubclasses, index, data);

	if (!data[Subclass_DescLangKey][0])
		return false;

	set_string(arg_desc_lang_key, data[Subclass_DescLangKey], get_param(arg_len));
	return true;
}

@native_subclass_set_desc_langkey(plugin, argc)
{
	enum { arg_subclass = 1, arg_desc_lang_key };

	new subclass = get_param(arg_subclass);
	new index = rz_module_get_valid_index(g_iModule, subclass);

	CHECK_MODULE_VALID_INDEX(index, false)

	new data[SubclassData];
	ArrayGetArray(g_aSubclasses, index, data);
	get_string(arg_desc_lang_key, data[Subclass_DescLangKey], charsmax(data[Subclass_DescLangKey]));
	ArraySetArray(g_aSubclasses, index, data);

	return true;
}

@native_subclass_get_props(plugin, argc)
{
	enum { arg_subclass = 1 };

	new subclass = get_param(arg_subclass);
	new index = rz_module_get_valid_index(g_iModule, subclass);

	CHECK_MODULE_VALID_INDEX(index, 0)

	new data[SubclassData];
	ArrayGetArray(g_aSubclasses, index, data);

	return data[Subclass_Props];
}

@native_subclass_set_props(plugin, argc)
{
	enum { arg_subclass = 1, arg_props };

	new subclass = get_param(arg_subclass);
	new index = rz_module_get_valid_index(g_iModule, subclass);

	CHECK_MODULE_VALID_INDEX(index, 0)

	new data[SubclassData];
	ArrayGetArray(g_aSubclasses, index, data);
	data[Subclass_Props] = get_param(arg_props);
	ArraySetArray(g_aSubclasses, index, data);

	return data[Subclass_Props];
}

@native_subclass_get_playermodel(plugin, argc)
{
	enum { arg_subclass = 1 };

	new subclass = get_param(arg_subclass);
	new index = rz_module_get_valid_index(g_iModule, subclass);

	CHECK_MODULE_VALID_INDEX(index, 0)

	new data[SubclassData];
	ArrayGetArray(g_aSubclasses, index, data);

	return data[Subclass_PlayerModel];
}

@native_subclass_set_playermodel(plugin, argc)
{
	enum { arg_subclass = 1, arg_player_model };

	new subclass = get_param(arg_subclass);
	new index = rz_module_get_valid_index(g_iModule, subclass);

	CHECK_MODULE_VALID_INDEX(index, 0)

	new data[SubclassData];
	ArrayGetArray(g_aSubclasses, index, data);
	data[Subclass_PlayerModel] = get_param(arg_player_model);
	ArraySetArray(g_aSubclasses, index, data);

	return true;
}

@native_subclass_get_playersound(plugin, argc)
{
	enum { arg_subclass = 1 };

	new subclass = get_param(arg_subclass);
	new index = rz_module_get_valid_index(g_iModule, subclass);

	CHECK_MODULE_VALID_INDEX(index, 0)

	new data[SubclassData];
	ArrayGetArray(g_aSubclasses, index, data);

	return data[Subclass_PlayerSound];
}

@native_subclass_set_playersound(plugin, argc)
{
	enum { arg_subclass = 1, arg_player_sound };

	new subclass = get_param(arg_subclass);
	new index = rz_module_get_valid_index(g_iModule, subclass);

	CHECK_MODULE_VALID_INDEX(index, 0)

	new data[SubclassData];
	ArrayGetArray(g_aSubclasses, index, data);
	data[Subclass_PlayerSound] = get_param(arg_player_sound);
	ArraySetArray(g_aSubclasses, index, data);

	return true;
}

@native_subclass_get_melee(plugin, argc)
{
	enum { arg_subclass = 1 };

	new subclass = get_param(arg_subclass);
	new index = rz_module_get_valid_index(g_iModule, subclass);

	CHECK_MODULE_VALID_INDEX(index, 0)

	new data[SubclassData];
	ArrayGetArray(g_aSubclasses, index, data);

	return data[Subclass_Melee];
}

@native_subclass_set_melee(plugin, argc)
{
	enum { arg_subclass = 1, arg_melee };

	new subclass = get_param(arg_subclass);
	new index = rz_module_get_valid_index(g_iModule, subclass);

	CHECK_MODULE_VALID_INDEX(index, 0)

	new data[SubclassData];
	ArrayGetArray(g_aSubclasses, index, data);
	data[Subclass_Melee] = get_param(arg_melee);
	ArraySetArray(g_aSubclasses, index, data);

	return true;
}

@native_subclass_get_nightvision(plugin, argc)
{
	enum { arg_subclass = 1 };

	new subclass = get_param(arg_subclass);
	new index = rz_module_get_valid_index(g_iModule, subclass);

	CHECK_MODULE_VALID_INDEX(index, 0)

	new data[SubclassData];
	ArrayGetArray(g_aSubclasses, index, data);

	return data[Subclass_NightVision];
}

@native_subclass_set_nightvision(plugin, argc)
{
	enum { arg_subclass = 1, arg_night_vision };

	new subclass = get_param(arg_subclass);
	new index = rz_module_get_valid_index(g_iModule, subclass);

	CHECK_MODULE_VALID_INDEX(index, 0)

	new data[SubclassData];
	ArrayGetArray(g_aSubclasses, index, data);
	data[Subclass_NightVision] = get_param(arg_night_vision);
	ArraySetArray(g_aSubclasses, index, data);

	return true;
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

@native_subclass_start(plugin, argc)
{
	return rz_module_get_offset(g_iModule);
}

@native_subclass_find(plugin, argc)
{
	enum { arg_name = 1 };

	new name[32];
	get_string(arg_name, name, charsmax(name));

	new i = ArrayFindString(g_aSubclasses, name);

	if (i != -1)
		return i + rz_module_get_offset(g_iModule);

	return 0;
}

@native_subclass_size(plugin, argc)
{
	return ArraySize(g_aSubclasses);
}

@native_subclass_player_get(plugin, argc)
{
	enum { arg_player = 1 };

	new player = get_param(arg_player);

	return g_iSubclass[player];
}

@native_subclass_player_set(plugin, argc)
{
	enum { arg_player = 1, arg_subclass };

	new player = get_param(arg_player);
	new subclass = get_param(arg_subclass);

	g_iSubclass[player] = subclass;
	return true;
}

@native_subclass_player_change(plugin, argc)
{
	enum { arg_player = 1, arg_subclass };

	new player = get_param(arg_player);
	new subclass = get_param(arg_subclass);

	ChangeSubclass(player, subclass, true);
	return true;
}

@native_subclass_player_get_status(plugin, argc)
{
	enum { arg_player = 1, arg_subclass };

	new player = get_param(arg_player);

	CHECK_CONNECTED(player, RZ_BREAK)

	new subclass = get_param(arg_subclass);
	new index = rz_module_get_valid_index(g_iModule, subclass);

	CHECK_MODULE_VALID_INDEX(index, RZ_BREAK)

	ExecuteForward(gForwards[Fw_Subclass_Change_Pre], gForwards[Fw_Return], player, subclass);
	return gForwards[Fw_Return];
}

@native_subclass_player_get_chosen(plugin, argc)
{
	enum { arg_player = 1, arg_class };

	new player = get_param(arg_player);
	new class = get_param(arg_class);
	new value;

	TrieGetCell(g_tChosenSubclass[player], ClassToStr(class), value);
	return value;
}

@native_subclass_player_set_chosen(plugin, argc)
{
	enum { arg_player = 1, arg_class, arg_subclass };

	new player = get_param(arg_player);
	new class = get_param(arg_class);
	new subclass = get_param(arg_subclass);

	TrieSetCell(g_tChosenSubclass[player], ClassToStr(class), subclass);
	return true;
}
