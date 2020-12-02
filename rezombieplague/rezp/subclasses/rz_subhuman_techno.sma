#pragma semicolon 1

#include <amxmodx>
#include <rezp>

public plugin_precache()
{
	register_plugin("[ReZP] Human Sub-class: Techno Dancer", REZP_VERSION_STR, "fl0wer");

	new const CLASS_NAME[] = "human";
	new class = rz_class_find(CLASS_NAME);

	if (!class)
	{
		set_fail_state("Class '%s' not found", CLASS_NAME);
		return;
	}

	new const name[] = "human_technodancer";

	new subclass = rz_subclass_create(class, name);
	new props = rz_props_create(name);
	
	rz_subclass_set_name_langkey(subclass, "RZ_SUBHUMAN_TECHNO_NAME");
	rz_subclass_set_desc_langkey(subclass, "RZ_SUBHUMAN_TECHNO_DESC");
	rz_subclass_set_props(subclass, props);

	rz_props_set_health(props, 200);
}
