#if defined _rezp_items_included
	#endinput
#endif

#define _rezp_items_included

/**
 * Item properties.
 */
enum RZItemProp
{
	RZ_ITEM_HANDLE, // [RZ_MAX_HANDLE_LENGTH]
	RZ_ITEM_NAME, // [RZ_MAX_LANGKEY_LENGTH]
	RZ_ITEM_COST, // cell
};

native rz_item_create(const handle[]);

native any:rz_item_get(item, RZItemProp:prop, any:...);
native rz_item_set(item, RZItemProp:prop, any:...);
native rz_item_command_add(item, const command[]);

native rz_items_start();
native rz_items_find(const handle[]);
native rz_items_size();

native rz_items_player_get_status(id, item);
native rz_items_player_give(id, item);

forward rz_items_select_pre(id, item);
forward rz_items_select_post(id, item);
