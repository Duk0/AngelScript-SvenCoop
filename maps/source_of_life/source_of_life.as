#include "lives"

const string szEntFile = "source_of_life/source_of_life.ent";

void MapActivate()
{
	LivesActivate();

	CBaseEntity@ pEntity = g_EntityFuncs.FindEntityByTargetname( null, "church_theme" );
	if ( pEntity !is null )
		pEntity.pev.spawnflags = 17;

	if ( !g_EntityLoader.LoadFromFile( szEntFile ) )
		g_EngineFuncs.ServerPrint( "Can't open " + szEntFile + "\n" );
}

void MapInit()
{
	LivesInit();
}
