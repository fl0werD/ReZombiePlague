#pragma semicolon 1

#include <amxmodx>
#include <rezp>

public plugin_precache()
{
	register_plugin("[ReZP] Zombie Sub-class: Sprinter", REZP_VERSION_STR, "fl0wer");

	new const CLASS_NAME[] = "zombie";
	new class = rz_class_find(CLASS_NAME);

	if (!class)
	{
		set_fail_state("Class '%s' not found", CLASS_NAME);
		return;
	}

	new const name[] = "zombie_sprinter";

	new subclass = rz_subclass_create(class, name);
	new props = rz_props_create(name);
	
	rz_subclass_set_name_langkey(subclass, "RZ_SUBZOMBIE_SPRINTER_NAME");
	rz_subclass_set_desc_langkey(subclass, "RZ_SUBZOMBIE_SPRINTER_DESC");
	rz_subclass_set_props(subclass, props);

	rz_props_set_health(props, 700);
	rz_props_set_speed(props, 260);
	rz_props_set_gravity(props, 0.9);
}
