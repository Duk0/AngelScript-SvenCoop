const string szEntFile = "escape_series/escape_series_2b.ent";

void MapActivate()
{
	CBaseEntity@ pEntity = null;
	string szClassName;
	while ( ( @pEntity = g_EntityFuncs.FindEntityByTargetname( pEntity, "cwlk3" ) ) !is null )
	{
		szClassName = pEntity.GetClassname();
		if ( szClassName != "func_door" && szClassName != "func_door_rotating" )
			continue;
		
		g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "m_iObeyTriggerMode", "0" );
	}

	while ( ( @pEntity = g_EntityFuncs.FindEntityByTargetname( pEntity, "boss1_end" ) ) !is null )
	{
		if ( pEntity.GetClassname() != "trigger_once" )
			continue;
		
		g_EntityFuncs.Remove( pEntity );
	}

	@pEntity = g_EntityFuncs.FindEntityByTargetname( null, "boss1_intro_music_multi" );
	if ( pEntity !is null )
		g_EntityFuncs.Remove( pEntity );
	
	@pEntity = g_EntityFuncs.FindEntityByTargetname( null, "boss1_start" );
	if ( pEntity !is null )
		g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "boss1_intro_music", "2" );


	if ( !g_EntityLoader.LoadFromFile( szEntFile ) )
		g_EngineFuncs.ServerPrint( "Can't open " + szEntFile + "\n" );
}
