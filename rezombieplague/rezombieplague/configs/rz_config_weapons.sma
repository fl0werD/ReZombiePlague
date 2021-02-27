#pragma semicolon 1

#include <amxmodx>
#include <json>
#include <reapi>
#include <rezp>

new const DEFAULT_WEAPONS_FILE[] = "default_weapons.json";
new const WEAPONS_DIRECTORY[] = "weapons";

new bool:g_bCreating;
new JSON:g_iJsonHandle;
new JSON:g_iJsonHandleCopy;
new g_sBaseDirPath[PLATFORM_MAX_PATH];
new g_sWeaponsDirPath[PLATFORM_MAX_PATH];

new Float:g_flTemp;
new g_sTemp[RZ_MAX_RESOURCE_PATH];

public plugin_precache()
{
	register_plugin("[ReZP] Config: Weapons", REZP_VERSION_STR, "fl0wer");

	rz_get_configsdir(g_sBaseDirPath, charsmax(g_sBaseDirPath));

	DefaultWeaponsConfig();

	formatex(g_sWeaponsDirPath, charsmax(g_sWeaponsDirPath), "%s/%s", g_sBaseDirPath, WEAPONS_DIRECTORY);

	if (!dir_exists(g_sWeaponsDirPath))
	{
		if (mkdir(g_sWeaponsDirPath) != 0)
		{
			rz_log(true, "Cannot create weapons directory '%s'", g_sWeaponsDirPath);
			return;
		}

		rz_print("Weapons directory '%s' was created", g_sWeaponsDirPath);
	}

	WeaponConfigs();
	KnifeConfigs();
	GrenadeConfigs();
}

DefaultWeaponsConfig()
{
	new filePath[PLATFORM_MAX_PATH];
	formatex(filePath, charsmax(filePath), "%s/%s", g_sBaseDirPath, DEFAULT_WEAPONS_FILE);

	if (file_exists(filePath))
	{
		g_iJsonHandle = json_parse(filePath, true);

		if (g_iJsonHandle == Invalid_JSON)
		{
			rz_log(true, "Error parsing weapon file '%s'", filePath);
			return;
		}

		g_bCreating = false;
	}
	else
	{
		g_bCreating = true;
		g_iJsonHandle = json_init_object();

		rz_print("Weapons file '%s' was created", filePath);
	}

	g_iJsonHandleCopy = json_deep_copy(g_iJsonHandle);
	
	new JSON:weaponJson = Invalid_JSON;
	new weaponName[RZ_MAX_REFERENCE_LENGTH];

	for (new i = 1; i < MAX_WEAPONS - 1; i++)
	{
		if ((1<<i) & ((1<<CSW_GLOCK) | (1<<CSW_C4)))
			continue;

		rg_get_weapon_info(WeaponIdType:i, WI_NAME, weaponName, charsmax(weaponName));

		weaponJson = json_object_get_value(g_iJsonHandle, weaponName);

		if (json_is_object(weaponJson))
		{
			g_bCreating = false;
		}
		else
		{
			g_bCreating = true;
			weaponJson = json_init_object();

			rz_print("Default weapon '%s' was added", weaponName);
		}

		DefaultWeaponPropField(weaponJson, "name", i, RZ_DEFAULT_WEAPON_NAME, RZ_MAX_LANGKEY_LENGTH);
		DefaultWeaponPropField(weaponJson, "short_name", i, RZ_DEFAULT_WEAPON_SHORT_NAME, RZ_MAX_LANGKEY_LENGTH);
		DefaultWeaponPropField(weaponJson, "knockback_power", i, RZ_DEFAULT_WEAPON_KNOCKBACK_POWER, 12);

		json_object_set_value(g_iJsonHandle, weaponName, weaponJson);
		json_free(weaponJson);
	}

	if (!json_equals(g_iJsonHandle, g_iJsonHandleCopy))
		json_serial_to_file(g_iJsonHandle, filePath, true);

	json_free(g_iJsonHandle);
	json_free(g_iJsonHandleCopy);

	rz_print("Loaded all default weapons");
}

WeaponConfigs()
{
	new size = rz_weapons_size();

	if (!size)
		return;

	new start = rz_weapons_start();
	new end = start + size;
	new failedCount;
	new handle[RZ_MAX_HANDLE_LENGTH];
	new filePath[PLATFORM_MAX_PATH];

	for (new i = start; i < end; i++)
	{
		rz_weapon_get(i, RZ_WEAPON_HANDLE, handle, charsmax(handle));
		formatex(filePath, charsmax(filePath), "%s/%s.json", g_sWeaponsDirPath, handle);

		if (file_exists(filePath))
		{
			g_iJsonHandle = json_parse(filePath, true);

			if (g_iJsonHandle == Invalid_JSON)
			{
				failedCount++;
				rz_log(true, "Error parsing weapon file '%s/%s.json'", WEAPONS_DIRECTORY, handle);
				continue;
			}

			g_bCreating = false;
			g_iJsonHandleCopy = json_deep_copy(g_iJsonHandle);
		}
		else
		{
			g_bCreating = true;
			g_iJsonHandle = json_init_object();

			rz_print("Weapon file '%s/%s.json' was created", WEAPONS_DIRECTORY, handle);
		}

		WeaponPropField("reference", i, RZ_WEAPON_REFERENCE, RZ_MAX_REFERENCE_LENGTH);
		WeaponPropField("name", i, RZ_WEAPON_NAME, RZ_MAX_LANGKEY_LENGTH);
		WeaponPropField("short_name", i, RZ_WEAPON_SHORT_NAME, RZ_MAX_LANGKEY_LENGTH);
		WeaponPropField("view_model", i, RZ_WEAPON_VIEW_MODEL, RZ_MAX_RESOURCE_PATH);
		WeaponPropField("player_model", i, RZ_WEAPON_PLAYER_MODEL, RZ_MAX_RESOURCE_PATH);
		WeaponPropField("world_model", i, RZ_WEAPON_WORLD_MODEL, RZ_MAX_RESOURCE_PATH);
		WeaponPropField("weaponlist", i, RZ_WEAPON_WEAPONLIST, RZ_MAX_RESOURCE_PATH);
		WeaponPropField("base_damage", i, RZ_WEAPON_BASE_DAMAGE, 12);
		WeaponPropField("base_damage2", i, RZ_WEAPON_BASE_DAMAGE2, 12);
		WeaponPropField("knockback_power", i, RZ_WEAPON_KNOCKBACK_POWER, 12);

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
		rz_print("Loaded %d weapons (%d failed)", size, failedCount);
	else
		rz_print("Loaded %d weapons", size);
}

KnifeConfigs()
{
	new size = rz_knifes_size();

	if (!size)
		return;

	new start = rz_knifes_start();
	new end = start + size;
	new failedCount;
	new handle[RZ_MAX_HANDLE_LENGTH];
	new filePath[PLATFORM_MAX_PATH];

	for (new i = start; i < end; i++)
	{
		rz_knife_get(i, RZ_KNIFE_HANDLE, handle, charsmax(handle));
		formatex(filePath, charsmax(filePath), "%s/%s.json", g_sWeaponsDirPath, handle);

		if (file_exists(filePath))
		{
			g_iJsonHandle = json_parse(filePath, true);

			if (g_iJsonHandle == Invalid_JSON)
			{
				failedCount++;
				rz_log(true, "Error parsing knife file '%s/%s.json'", WEAPONS_DIRECTORY, handle);
				continue;
			}

			g_bCreating = false;
			g_iJsonHandleCopy = json_deep_copy(g_iJsonHandle);
		}
		else
		{
			g_bCreating = true;
			g_iJsonHandle = json_init_object();

			rz_print("Knife file '%s/%s.json' was created", WEAPONS_DIRECTORY, handle);
		}

		KnifePropField("name", i, RZ_KNIFE_NAME, RZ_MAX_LANGKEY_LENGTH);
		KnifePropField("short_name", i, RZ_KNIFE_SHORT_NAME, RZ_MAX_LANGKEY_LENGTH);
		KnifePropField("view_model", i, RZ_KNIFE_VIEW_MODEL, RZ_MAX_RESOURCE_PATH);
		KnifePropField("player_model", i, RZ_KNIFE_PLAYER_MODEL, RZ_MAX_RESOURCE_PATH);
		KnifePropField("weaponlist", i, RZ_KNIFE_WEAPONLIST, RZ_MAX_RESOURCE_PATH);
		KnifePropField("stab_base_damage", i, RZ_KNIFE_STAB_BASE_DAMAGE, 12);
		KnifePropField("swing_base_damage", i, RZ_KNIFE_SWING_BASE_DAMAGE, 12);
		KnifePropField("stab_distance", i, RZ_KNIFE_STAB_DISTANCE, 12);
		KnifePropField("swing_distance", i, RZ_KNIFE_SWING_DISTANCE, 12);
		KnifePropField("knockback_power", i, RZ_KNIFE_KNOCKBACK_POWER, 12);

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
		rz_print("Loaded %d knives (%d failed)", size, failedCount);
	else
		rz_print("Loaded %d knives", size);
}

GrenadeConfigs()
{
	new size = rz_grenades_size();

	if (!size)
		return;

	new start = rz_grenades_start();
	new end = start + size;
	new failedCount;
	new handle[RZ_MAX_HANDLE_LENGTH];
	new filePath[PLATFORM_MAX_PATH];

	for (new i = start; i < end; i++)
	{
		rz_grenade_get(i, RZ_GRENADE_HANDLE, handle, charsmax(handle));
		formatex(filePath, charsmax(filePath), "%s/%s.json", g_sWeaponsDirPath, handle);

		if (file_exists(filePath))
		{
			g_iJsonHandle = json_parse(filePath, true);

			if (g_iJsonHandle == Invalid_JSON)
			{
				failedCount++;
				rz_log(true, "Error parsing grenade file '%s/%s.json'", WEAPONS_DIRECTORY, handle);
				continue;
			}

			g_bCreating = false;
			g_iJsonHandleCopy = json_deep_copy(g_iJsonHandle);
		}
		else
		{
			g_bCreating = true;
			g_iJsonHandle = json_init_object();

			rz_print("Grenade file '%s/%s.json' was created", WEAPONS_DIRECTORY, handle);
		}

		GrenadePropField("reference", i, RZ_GRENADE_REFERENCE, RZ_MAX_REFERENCE_LENGTH);
		GrenadePropField("name", i, RZ_GRENADE_NAME, RZ_MAX_LANGKEY_LENGTH);
		GrenadePropField("short_name", i, RZ_GRENADE_SHORT_NAME, RZ_MAX_LANGKEY_LENGTH);
		GrenadePropField("view_model", i, RZ_GRENADE_VIEW_MODEL, RZ_MAX_RESOURCE_PATH);
		GrenadePropField("player_model", i, RZ_GRENADE_PLAYER_MODEL, RZ_MAX_RESOURCE_PATH);
		GrenadePropField("world_model", i, RZ_GRENADE_WORLD_MODEL, RZ_MAX_RESOURCE_PATH);
		GrenadePropField("weaponlist", i, RZ_GRENADE_WEAPONLIST, RZ_MAX_RESOURCE_PATH);

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
		rz_print("Loaded %d grenades (%d failed)", size, failedCount);
	else
		rz_print("Loaded %d grenades", size);
}

DefaultWeaponPropField(JSON:object, value[], any:weaponId, RZDefaultWeaponProp:prop, length)
{
	switch (prop)
	{
		case RZ_DEFAULT_WEAPON_KNOCKBACK_POWER:
		{
			if (!g_bCreating && json_object_has_value(object, value, JSONString))
			{
				json_object_get_string(object, value, g_sTemp, length - 1);
				rz_weapon_default_set(weaponId, prop, str_to_float(g_sTemp));
			}
			else
			{
				g_flTemp = Float:rz_weapon_default_get(weaponId, prop);
				json_object_set_string(object, value, fmt("%.1f", g_flTemp));
			}
		}
		default:
		{
			if (!g_bCreating && json_object_has_value(object, value, JSONString))
			{
				json_object_get_string(object, value, g_sTemp, length - 1);
				rz_weapon_default_set(weaponId, prop, g_sTemp);
			}
			else
			{
				rz_weapon_default_get(weaponId, prop, g_sTemp, length - 1);
				json_object_set_string(object, value, g_sTemp);
			}
		}
	}
}

WeaponPropField(value[], weapon, RZWeaponProp:prop, length)
{
	switch (prop)
	{
		case RZ_WEAPON_KNOCKBACK_POWER:
		{
			if (!g_bCreating && json_object_has_value(g_iJsonHandle, value, JSONString))
			{
				json_object_get_string(g_iJsonHandle, value, g_sTemp, length - 1);
				rz_weapon_set(weapon, prop, str_to_float(g_sTemp));
			}
			else
			{
				g_flTemp = Float:rz_weapon_get(weapon, prop);
				json_object_set_string(g_iJsonHandle, value, fmt("%.1f", g_flTemp));
			}
		}
		default:
		{
			if (!g_bCreating && json_object_has_value(g_iJsonHandle, value, JSONString))
			{
				json_object_get_string(g_iJsonHandle, value, g_sTemp, length - 1);
				rz_weapon_set(weapon, prop, g_sTemp);
			}
			else
			{
				rz_weapon_get(weapon, prop, g_sTemp, length - 1);
				json_object_set_string(g_iJsonHandle, value, g_sTemp);
			}

			if (!g_sTemp[0])
				return;

			switch (prop)
			{
				case RZ_WEAPON_VIEW_MODEL, RZ_WEAPON_PLAYER_MODEL, RZ_WEAPON_WORLD_MODEL:
				{
					precache_model(g_sTemp);
				}
				case RZ_WEAPON_WEAPONLIST:
				{
					precache_generic(fmt("sprites/%s.txt", g_sTemp));
				}
			}
		}
	}
}

KnifePropField(value[], knife, RZKnifeProp:prop, length)
{
	switch (prop)
	{
		case RZ_KNIFE_STAB_BASE_DAMAGE, RZ_KNIFE_SWING_BASE_DAMAGE,
				RZ_KNIFE_STAB_DISTANCE, RZ_KNIFE_SWING_DISTANCE,
				RZ_KNIFE_KNOCKBACK_POWER:
		{
			if (!g_bCreating && json_object_has_value(g_iJsonHandle, value, JSONString))
			{
				json_object_get_string(g_iJsonHandle, value, g_sTemp, length - 1);
				rz_knife_set(knife, prop, str_to_float(g_sTemp));
			}
			else
			{
				g_flTemp = Float:rz_knife_get(knife, prop);

				json_object_set_string(g_iJsonHandle, value, fmt("%.1f", g_flTemp));
			}
		}
		default:
		{
			if (!g_bCreating && json_object_has_value(g_iJsonHandle, value, JSONString))
			{
				json_object_get_string(g_iJsonHandle, value, g_sTemp, length - 1);
				rz_knife_set(knife, prop, g_sTemp);
			}
			else
			{
				rz_knife_get(knife, prop, g_sTemp, length - 1);
				json_object_set_string(g_iJsonHandle, value, g_sTemp);
			}

			if (!g_sTemp[0])
				return;

			switch (prop)
			{
				case RZ_KNIFE_VIEW_MODEL, RZ_KNIFE_PLAYER_MODEL:
				{
					if (!equal(g_sTemp, "hide"))
						precache_model(g_sTemp);
				}
				case RZ_KNIFE_WEAPONLIST:
				{
					precache_generic(fmt("sprites/%s.txt", g_sTemp));
				}
			}
		}
	}
}

GrenadePropField(value[], grenade, RZGrenadeProp:prop, length)
{
	if (!g_bCreating && json_object_has_value(g_iJsonHandle, value, JSONString))
	{
		json_object_get_string(g_iJsonHandle, value, g_sTemp, length - 1);
		rz_grenade_set(grenade, prop, g_sTemp);
	}
	else
	{
		rz_grenade_get(grenade, prop, g_sTemp, length - 1);
		json_object_set_string(g_iJsonHandle, value, g_sTemp);
	}

	if (!g_sTemp[0])
		return;

	switch (prop)
	{
		case RZ_GRENADE_VIEW_MODEL, RZ_GRENADE_PLAYER_MODEL, RZ_GRENADE_WORLD_MODEL:
		{
			precache_model(g_sTemp);
		}
		case RZ_GRENADE_WEAPONLIST:
		{
			precache_generic(fmt("sprites/%s.txt", g_sTemp));
		}
	}
}
