#include "cb_return"

void MapActivate()
{
	CBaseEntity@ pEntity = g_EntityFuncs.Create( "info_target", g_vecZero, g_vecZero, false );
	if ( pEntity !is null )
		pEntity.pev.target = string_t( "sys10_e01_mskyth2" );
}

void MapInit()
{
	CrowbarReturnInit();
}
