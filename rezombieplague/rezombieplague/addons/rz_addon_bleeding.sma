#pragma semicolon 1

#include <amxmodx>
#include <fakemeta>
#include <reapi>
#include <rezp>
#include <util_tempentities>

new const BLEEDING_DECALS[] = { 99 , 107 , 108 , 184 , 185 , 186 , 187 , 188 , 189 };

/*new const BLEEDING_DECAL_NAMES[][] =
{
	"{blood1",
	"{blood2",
	"{blood3",
	"{blood4",
	"{blood5",
	"{blood6",
};*/

new Array:g_aBleedingDecals;

new Float:rz_bleeding_frequency;
new Float:rz_bleeding_minspeed;

public plugin_precache()
{
	register_plugin("[ReZP] Addon: Bleeding", REZP_VERSION_STR, "fl0wer");

	bind_pcvar_float(create_cvar("rz_bleeding_frequency", "0.7", FCVAR_NONE, "", true, 0.1), rz_bleeding_frequency);
	bind_pcvar_float(create_cvar("rz_bleeding_minspeed", "80.0", FCVAR_NONE, "", true, 1.0), rz_bleeding_minspeed);

	g_aBleedingDecals = ArrayCreate(1, 0);

	for (new i = 0; i < sizeof(BLEEDING_DECALS); i++)
		ArrayPushCell(g_aBleedingDecals, BLEEDING_DECALS[i]);

	/*new decal;

	for (new i = 0; i < sizeof(BLEEDING_DECAL_NAMES); i++)
	{
		decal = engfunc(EngFunc_DecalIndex, BLEEDING_DECAL_NAMES[i]);

		if (decal == -1)
			continue;

		ArrayPushCell(g_aBleedingDecals, decal);
	}*/
}

public plugin_cfg()
{
	if (!ArraySize(g_aBleedingDecals))
	{
		set_fail_state("Not found bleeding decals");
		return;
	}

	new entity = rg_create_entity("info_target");

	set_entvar(entity, var_effects, EF_NODRAW);
	set_entvar(entity, var_nextthink, get_gametime() + 1.0);

	SetThink(entity, "@Bleeding_Think");
}

@Bleeding_Think(id)
{
	set_entvar(id, var_nextthink, get_gametime() + rz_bleeding_frequency);

	new textureIndex;
	new Float:vecOrigin[3];
	new Float:vecVelocity[3];
	new Float:vecMins[3];

	for (new i = 1; i <= MaxClients; i++)
	{
		if (!is_user_alive(i))
			continue;

		if (get_member(i, m_iTeam) != TEAM_TERRORIST)
			continue;

		if (!(get_entvar(i, var_flags) & FL_ONGROUND))
			continue;

		get_entvar(i, var_velocity, vecVelocity);

		if (vector_length(vecVelocity) < rz_bleeding_minspeed)
			continue;

		get_entvar(i, var_origin, vecOrigin);
		get_entvar(i, var_mins, vecMins);

		vecOrigin[2] += vecMins[2];
		textureIndex = ArrayGetCell(g_aBleedingDecals, random_num(0, ArraySize(g_aBleedingDecals) - 1));

		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		TE_WorldDecal(vecOrigin, textureIndex);
	}
}
