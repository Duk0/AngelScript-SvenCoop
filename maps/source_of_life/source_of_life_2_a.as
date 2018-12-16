#include "cb_return"
#include "lives"

const string szEntFile = "source_of_life/source_of_life_2_a.ent";

void MapActivate()
{
	LivesActivate();

	CBaseEntity@ pEntity = null;
	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "trigger_auto" ) ) !is null )
	{
		if ( string( pEntity.pev.target ).CompareN( "sence2_auto_", 12 ) != 0 )
			continue;
		
		g_EntityFuncs.Remove( pEntity );
	}

	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "trigger_changevalue" ) ) !is null )
	{
		if ( pEntity.GetTargetname().CompareN( "sence2_auto_", 12 ) != 0 )
			continue;

		if ( pEntity.pev.target != "wootguy_data" )
			continue;
		
		g_EntityFuncs.Remove( pEntity );
	}
	

	@pEntity = g_EntityFuncs.FindEntityByTargetname( null, "sys1_cut_intro_th2" );
	if ( pEntity !is null )
		pEntity.pev.spawnflags = 17;

	@pEntity = g_EntityFuncs.FindEntityByTargetname( null, "m_goregirl_loop" );
	if ( pEntity !is null )
		pEntity.pev.spawnflags = 17;

	@pEntity = g_EntityFuncs.FindEntityByTargetname( null, "sys5_giantf_theme2" );
	if ( pEntity !is null )
		pEntity.pev.spawnflags = 17;


/*	@pEntity = g_EntityFuncs.FindEntityByTargetname( null, "sys7_e01_crwakebt1" );
	if ( pEntity !is null )
		g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "-wait", "1" );*/

	@pEntity = g_EntityFuncs.FindEntityByTargetname( null, "sys7_e01_butfix1" );
	if ( pEntity !is null )
		g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "m_iszNewValue", "sys7_e01_relay1" );


	if ( !g_EntityLoader.LoadFromFile( szEntFile ) )
		g_EngineFuncs.ServerPrint( "Can't open " + szEntFile + "\n" );
}

void MapInit()
{
	CrowbarReturnInit();

	LivesInit();
}

