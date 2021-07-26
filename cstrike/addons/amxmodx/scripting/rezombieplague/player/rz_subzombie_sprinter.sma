#pragma semicolon 1

#include <amxmodx>
#include <rezp>

public plugin_precache()
{
	register_plugin("[ReZP] Zombie Sub-class: Sprinter", REZP_VERSION_STR, "fl0wer");

	new class;
	RZ_CHECK_CLASS_EXISTS(class, "class_zombie");

	new const handle[] = "subclass_zombie_sprinter";

	new subclass = rz_subclass_create(handle, class);
	new props = rz_playerprops_create(handle);
	
	rz_subclass_set(subclass, RZ_SUBCLASS_NAME, "RZ_SUBZOMBIE_SPRINTER_NAME");
	rz_subclass_set(subclass, RZ_SUBCLASS_DESC, "RZ_SUBZOMBIE_SPRINTER_DESC");
	rz_subclass_set(subclass, RZ_SUBCLASS_PROPS, props);

	rz_playerprops_set(props, RZ_PLAYER_PROPS_HEALTH, 700.0);
	rz_playerprops_set(props, RZ_PLAYER_PROPS_SPEED, 260.0);
	rz_playerprops_set(props, RZ_PLAYER_PROPS_GRAVITY, 0.9);
}
