#pragma semicolon 1

#include <amxmodx>
#include <json>
#include <rezp>

new const PLAYER_DIRECTORY[] = "player";

new bool:g_bCreating;
new JSON:g_iJsonHandle;
new JSON:g_iJsonHandleCopy;
new g_sBaseDirPath[PLATFORM_MAX_PATH];
new g_sPlayerDirPath[PLATFORM_MAX_PATH];
new g_sHandle[RZ_MAX_HANDLE_LENGTH];

new g_iTemp;
new Float:g_flTemp;
new g_sTemp[RZ_MAX_RESOURCE_PATH];

public plugin_precache()
{
	register_plugin("[ReZP] Config: Player", REZP_VERSION_STR, "fl0wer");

	rz_get_configsdir(g_sBaseDirPath, charsmax(g_sBaseDirPath));
	formatex(g_sPlayerDirPath, charsmax(g_sPlayerDirPath), "%s/%s", g_sBaseDirPath, PLAYER_DIRECTORY);

	if (!dir_exists(g_sPlayerDirPath))
	{
		if (mkdir(g_sPlayerDirPath) != 0)
		{
			rz_log(true, "Cannot create player directory '%s'", g_sPlayerDirPath);
			return;
		}

		rz_print("Player directory '%s' was created", g_sPlayerDirPath);
	}

	ClassConfigs();
}

ClassConfigs()
{
	new size = rz_class_size();

	if (!size)
		return;

	new start = rz_class_start();
	new end = start + size;
	new failedCount;
	new filePath[PLATFORM_MAX_PATH];

	for (new i = start; i < end; i++)
	{
		rz_class_get(i, RZ_CLASS_HANDLE, g_sHandle, charsmax(g_sHandle));
		formatex(filePath, charsmax(filePath), "%s/%s.json", g_sPlayerDirPath, g_sHandle);

		if (file_exists(filePath))
		{
			g_iJsonHandle = json_parse(filePath, true);

			if (g_iJsonHandle == Invalid_JSON)
			{
				failedCount++;
				rz_log(true, "Error parsing class file '%s/%s.json'", PLAYER_DIRECTORY, g_sHandle);
				continue;
			}

			g_bCreating = false;
			g_iJsonHandleCopy = json_deep_copy(g_iJsonHandle);
		}
		else
		{
			g_bCreating = true;
			g_iJsonHandle = json_init_object();

			rz_print("Class file '%s/%s.json' was created", PLAYER_DIRECTORY, g_sHandle);
		}

		ClassPropField("name", i, RZ_CLASS_NAME, RZ_MAX_LANGKEY_LENGTH);
		//ClassPropField("team", i, RZ_CLASS_TEAM); // will break classes by default
		ClassPropField("hud_color", i, RZ_CLASS_HUD_COLOR);
		ClassPropField("properties", i, RZ_CLASS_PROPS);
		ClassPropField("player_models", i, RZ_CLASS_MODEL);
		ClassPropField("player_sounds", i, RZ_CLASS_SOUND);
		ClassPropField_Knife("knife", i, RZ_MAX_HANDLE_LENGTH, "weapon_knife");
		ClassPropField("nightvision", i, RZ_CLASS_NIGHTVISION);

		if (g_bCreating)
		{
			json_serial_to_file(g_iJsonHandle, filePath, true);
		}
		else if (!json_equals(g_iJsonHandle, g_iJsonHandleCopy))
		{
			json_serial_to_file(g_iJsonHandle, filePath, true);
			json_free(g_iJsonHandleCopy);
		}

		json_free(g_iJsonHandle);
	}

	if (failedCount)
		rz_print("Loaded %d classes (%d failed)", size, failedCount);
	else
		rz_print("Loaded %d classes", size);
}

ClassPropField(value[], class, RZClassProp:prop, length = 0)
{
	switch (prop)
	{
		case RZ_CLASS_HUD_COLOR:
		{
			new colorInt[3];

			if (!g_bCreating && json_object_has_value(g_iJsonHandle, value, JSONString))
			{
				new color[3][4];

				json_object_get_string(g_iJsonHandle, value, g_sTemp, length - 1);

				if (parse(g_sTemp, color[0], charsmax(color[]), color[1], charsmax(color[]), color[2], charsmax(color[])) == 3)
				{
					colorInt[0] = str_to_num(color[0]);
					colorInt[1] = str_to_num(color[1]);
					colorInt[2] = str_to_num(color[2]);

					rz_class_set(class, prop, colorInt);
				}
				else
				{
					rz_class_get(class, RZ_CLASS_HANDLE, g_sHandle, charsmax(g_sHandle));
					rz_log(true, "Error parsing property '%s' for class '%s'", value, g_sHandle);
				}
			}
			else
			{
				rz_class_get(class, prop, colorInt);
				json_object_set_string(g_iJsonHandle, value, fmt("%d %d %d", colorInt[0], colorInt[1], colorInt[2]));
			}
		}
		case RZ_CLASS_PROPS, RZ_CLASS_MODEL, RZ_CLASS_SOUND, RZ_CLASS_NIGHTVISION:
		{
			if (!g_bCreating && json_object_has_value(g_iJsonHandle, value, JSONNumber))
			{
				g_iTemp = json_object_get_number(g_iJsonHandle, value);
				rz_class_set(class, prop, g_iTemp);
			}
			else
			{
				g_iTemp = rz_class_get(class, prop);
				json_object_set_number(g_iJsonHandle, value, g_iTemp);
			}
		}
		default:
		{
			if (!g_bCreating && json_object_has_value(g_iJsonHandle, value, JSONString))
			{
				json_object_get_string(g_iJsonHandle, value, g_sTemp, length - 1);
				rz_class_set(class, prop, g_sTemp);
			}
			else
			{
				rz_class_get(class, prop, g_sTemp, length - 1);
				json_object_set_string(g_iJsonHandle, value, g_sTemp);
			}
		}
	}
}

ClassPropField_Knife(value[], class, length, defValue[])
{
	if (!g_bCreating && json_object_has_value(g_iJsonHandle, value, JSONString))
	{
		json_object_get_string(g_iJsonHandle, value, g_sTemp, length - 1);

		if (g_sTemp[0] && !equal(g_sTemp, defValue))
		{
			new knife = rz_knifes_find(g_sTemp);

			if (knife)
			{
				rz_class_set(class, RZ_CLASS_KNIFE, knife);
			}
			else
			{
				rz_class_get(class, RZ_CLASS_HANDLE, g_sHandle, charsmax(g_sHandle));
				rz_log(true, "Error searching knife '%s' for class '%s'", value, g_sHandle);
			}
		}
		else
		{
			rz_class_set(class, RZ_CLASS_KNIFE, 0);
		}
	}
	else
	{
		new knife = rz_class_get(class, RZ_CLASS_KNIFE);

		if (knife)
		{
			rz_knife_get(knife, RZ_KNIFE_HANDLE, g_sHandle, charsmax(g_sHandle));
			json_object_set_string(g_iJsonHandle, value, g_sHandle);
		}
		else
			json_object_set_string(g_iJsonHandle, value, defValue);
	}
}
