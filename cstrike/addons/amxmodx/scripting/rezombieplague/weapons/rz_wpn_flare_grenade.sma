#pragma semicolon 1

#include <amxmodx>
#include <reapi>
#include <rezp>
#include <util_tempentities>

new const FLARE_VIEW_MODEL[] = "models/zombie_plague/v_grenade_flare.mdl";
new const FLARE_EXPLODE_SOUND[] = "items/nvg_on.wav";

new g_iModelIndex_LaserBeam;

new g_iGrenade_Flare;

new cvar_flare_duration = 60;
new cvar_flare_radius = 25;
new cvar_flare_color = 0;

public plugin_precache()
{
	register_plugin("[ReZP] Grenade: Flare", REZP_VERSION_STR, "fl0wer");

	precache_sound(FLARE_EXPLODE_SOUND);

	g_iModelIndex_LaserBeam = precache_model("sprites/laserbeam.spr");

	new grenade = g_iGrenade_Flare = rz_grenade_create("grenade_flare", "weapon_smokegrenade");

	rz_grenade_set(grenade, RZ_GRENADE_NAME, "RZ_WPN_FLARE_GRENADE");
	rz_grenade_set(grenade, RZ_GRENADE_SHORT_NAME, "RZ_WPN_FLARE_SHORT");
	rz_grenade_set(grenade, RZ_GRENADE_VIEW_MODEL, FLARE_VIEW_MODEL);
}

public rz_grenades_throw_post(id, entity, grenade)
{
	if (grenade != g_iGrenade_Flare)
		return;

	new color[3];
	new Float:vecColor[3];

	switch (cvar_flare_color)
	{
		case 0: color[0] = color[1] = color[2] = 255;
		case 1:
		{
			color[0] = random_num(50, 255);
			color[1] = color[2] = 0;
		}
		case 2:
		{
			color[1] = random_num(50, 255);
			color[0] = color[2] = 0;
		}
		case 3:
		{
			color[0] = color[1] = 0;
			color[2] = random_num(50, 255);
		}
		case 4:
		{
			for (new i = 0; i < 3; i++)
				color[i] = random_num(50, 200);
		}
		case 5:
		{
			switch (random_num(1, 3))
			{
				case 1:
				{
					color[0] = random_num(50, 255);
					color[1] = color[2] = 0;
				}
				case 2:
				{
					color[1] = random_num(50, 255);
					color[0] = color[2] = 0;
				}
				case 3:
				{
					color[0] = color[1] = 0;
					color[2] = random_num(50, 255);
				}
			}
		}
	}

	IVecFVec(color, vecColor);

	rz_util_set_rendering(entity, kRenderNormal, 16.0, vecColor, kRenderFxGlowShell);

	message_begin_f(MSG_ALL, SVC_TEMPENTITY);
	TE_BeamFollow(entity, g_iModelIndex_LaserBeam, 10, 10, color, 200);

	set_entvar(entity, var_punchangle, vecColor);
}

public rz_grenades_explode_pre(id, grenade)
{
	if (grenade != g_iGrenade_Flare)
		return RZ_CONTINUE;

	rh_emit_sound2(id, 0, CHAN_WEAPON, FLARE_EXPLODE_SOUND, 1.0, ATTN_NORM, 0, PITCH_NORM);
	
	set_entvar(id, var_nextthink, get_gametime() + 0.1);
	set_member(id, m_Grenade_SGSmoke, cvar_flare_duration / 2);

	SetThink(id, "@Flare_Think");
	return RZ_SUPERCEDE;
}

@Flare_Think(id)
{
	new duration = get_member(id, m_Grenade_SGSmoke);

	if (duration < 0)
	{
		set_entvar(id, var_flags, FL_KILLME);
		return;
	}

	new color[3];
	new Float:vecOrigin[3];
	new Float:vecColor[3];

	get_entvar(id, var_origin, vecOrigin);
	get_entvar(id, var_punchangle, vecColor);

	FVecIVec(vecColor, color);

	message_begin_f(MSG_PVS, SVC_TEMPENTITY, vecOrigin);
	TE_DLight(vecOrigin, cvar_flare_radius, color, 21, duration < 1 ? 3 : 0);

	message_begin_f(MSG_PVS, SVC_TEMPENTITY, vecOrigin);
	TE_Sparks(vecOrigin);

	set_member(id, m_Grenade_SGSmoke, --duration);
	set_entvar(id, var_nextthink, get_gametime() + 2.0);
}
