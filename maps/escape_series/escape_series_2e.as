void MapActivate()
{
	CBaseEntity@ pEntity = null;
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
		g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "boss1_intro_music", "12" );


	@pEntity = g_EntityFuncs.FindEntityByTargetname( pEntity, "countdown_music_kill" );
	if ( pEntity !is null )
		g_EntityFuncs.Remove( pEntity );

/*	@pEntity = g_EntityFuncs.FindEntityByTargetname( null, "countdown_multi" );
	if ( pEntity !is null )
		g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "countdown_music", "180#2" );*/
		
	@pEntity = g_EntityFuncs.FindEntityByTargetname( null, "countdown_music" );
	if ( pEntity !is null )
		pEntity.pev.spawnflags = 49;

	@pEntity = g_EntityFuncs.FindEntityByClassname( null, "trigger_changelevel" );
	if ( pEntity !is null )
		g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "keep_inventory", "0" );
}
