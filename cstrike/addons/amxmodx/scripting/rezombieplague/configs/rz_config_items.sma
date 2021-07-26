#pragma semicolon 1

#include <amxmodx>
#include <json>
#include <rezp>

new const ITEMS_FILE[] = "items.json";

new bool:g_bCreating;
new JSON:g_iJsonHandle;
new JSON:g_iJsonHandleCopy;

new g_iTemp;
new g_sTemp[RZ_MAX_RESOURCE_PATH];

public plugin_precache()
{
	register_plugin("[ReZP] Config: Items", REZP_VERSION_STR, "fl0wer");

	ItemsConfig();
}

ItemsConfig()
{
	new size = rz_items_size();

	if (!size)
		return;

	new start = rz_items_start();
	new end = start + size;
	new baseDirPath[PLATFORM_MAX_PATH];
	new filePath[PLATFORM_MAX_PATH];

	rz_get_configsdir(baseDirPath, charsmax(baseDirPath));
	formatex(filePath, charsmax(filePath), "%s/%s", baseDirPath, ITEMS_FILE);

	if (file_exists(filePath))
	{
		g_iJsonHandle = json_parse(filePath, true);

		if (g_iJsonHandle == Invalid_JSON)
		{
			rz_log(true, "Error parsing items file '%s'", filePath);
			return;
		}

		g_bCreating = false;
	}
	else
	{
		g_bCreating = true;
		g_iJsonHandle = json_init_object();

		rz_print("Items file '%s' was created", filePath);
	}

	g_iJsonHandleCopy = json_deep_copy(g_iJsonHandle);

	new JSON:itemJson = Invalid_JSON;
	new handle[RZ_MAX_HANDLE_LENGTH];

	for (new i = start; i < end; i++)
	{
		rz_item_get(i, RZ_ITEM_HANDLE, handle, charsmax(handle));

		itemJson = json_object_get_value(g_iJsonHandle, handle);

		if (json_is_object(itemJson))
		{
			g_bCreating = false;
		}
		else
		{
			g_bCreating = true;
			itemJson = json_init_object();

			rz_print("Item '%s' was added", handle);
		}

		ItemPropField(itemJson, "name", i, RZ_ITEM_NAME, RZ_MAX_LANGKEY_LENGTH);
		ItemPropField(itemJson, "cost", i, RZ_ITEM_COST);

		json_object_set_value(g_iJsonHandle, handle, itemJson);
		json_free(itemJson);
	}

	if (!json_equals(g_iJsonHandle, g_iJsonHandleCopy))
		json_serial_to_file(g_iJsonHandle, filePath, true);

	json_free(g_iJsonHandle);
	json_free(g_iJsonHandleCopy);

	rz_print("Loaded %d items", size);
}

ItemPropField(JSON:object, value[], item, RZItemProp:prop, length = 0)
{
	switch (prop)
	{
		case RZ_ITEM_NAME:
		{
			if (!g_bCreating && json_object_has_value(object, value, JSONString))
			{
				json_object_get_string(object, value, g_sTemp, length - 1);
				rz_item_set(item, prop, g_sTemp);
			}
			else
			{
				rz_item_get(item, prop, g_sTemp, length - 1);
				json_object_set_string(object, value, g_sTemp);
			}
		}
		case RZ_ITEM_COST:
		{
			if (!g_bCreating && json_object_has_value(object, value, JSONNumber))
			{
				g_iTemp = json_object_get_number(object, value);
				rz_item_set(item, prop, g_iTemp);
			}
			else
			{
				g_iTemp = rz_item_get(item, prop);
				json_object_set_number(object, value, g_iTemp);
			}
		}
	}
}
