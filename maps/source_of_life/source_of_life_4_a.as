#include "cb_return"
#include "lives"

const string szEntFile = "source_of_life/source_of_life_4_a.ent";

void MapActivate()
{
	LivesActivate();

	CBaseEntity@ pEntity = null;
	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "monster_zombie" ) ) !is null )
	{
		if ( pEntity.pev.model != "models/sence/source_of_life/npc/cave_demon.mdl" )
			continue;
		
		g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "bloodcolor", "1" );
	}

	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "trigger_auto" ) ) !is null )
	{
		if ( string( pEntity.pev.target ).CompareN( "sence4_auto_", 12 ) != 0 )
			continue;
		
		g_EntityFuncs.Remove( pEntity );
	}

	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "trigger_changevalue" ) ) !is null )
	{
		if ( pEntity.GetTargetname().CompareN( "sence4_auto_", 12 ) != 0 )
			continue;

		if ( pEntity.pev.target != "wootguy_data" )
			continue;
		
		g_EntityFuncs.Remove( pEntity );
	}


	@pEntity = g_EntityFuncs.FindEntityByTargetname( null, "girl_sound1" );
	if ( pEntity !is null )
		pEntity.pev.spawnflags = 49;

	@pEntity = g_EntityFuncs.FindEntityByTargetname( null, "girl_loop" );
	if ( pEntity !is null )
		pEntity.pev.spawnflags = 17;

	@pEntity = g_EntityFuncs.FindEntityByTargetname( null, "sys5_e02_sfx_theme1" );
	if ( pEntity !is null )
		pEntity.pev.spawnflags = 49;


	if ( !g_EntityLoader.LoadFromFile( szEntFile ) )
		g_EngineFuncs.ServerPrint( "Can't open " + szEntFile + "\n" );
}

void MapInit()
{
	CrowbarReturnInit();

	LivesInit();
}
