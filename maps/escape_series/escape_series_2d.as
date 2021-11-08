void MapActivate()
{
	CBaseEntity@ pEntity = null;
	while ( ( @pEntity = g_EntityFuncs.FindEntityByTargetname( pEntity, "boss1_end" ) ) !is null )
	{
		if ( pEntity.GetClassname() != "trigger_once" )
			continue;
		
		g_EntityFuncs.Remove( pEntity );
	}

/*	@pEntity = g_EntityFuncs.FindEntityByTargetname( null, "killer" );
	if ( pEntity !is null )
		g_EntityFuncs.Remove( pEntity )*/

	@pEntity = g_EntityFuncs.FindEntityByTargetname( null, "boss1_intro_music_multi" );
	if ( pEntity !is null )
		g_EntityFuncs.Remove( pEntity );

	@pEntity = null;
	while ( ( @pEntity = g_EntityFuncs.FindEntityByTargetname( pEntity, "respawn" ) ) !is null )
	{
		if ( pEntity.GetClassname() != "multi_manager" )
			continue;

		g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "boss1_intro_music", "3" );
		break;
	}

	@pEntity = null;
	while ( ( @pEntity = g_EntityFuncs.FindEntityByTargetname( pEntity, "boss2_end" ) ) !is null )
	{
		if ( pEntity.GetClassname() != "trigger_once" )
			continue;
		
		g_EntityFuncs.Remove( pEntity );
	}

	@pEntity = g_EntityFuncs.FindEntityByTargetname( null, "killer2" );
	if ( pEntity !is null )
		g_EntityFuncs.Remove( pEntity );

	@pEntity = g_EntityFuncs.FindEntityByTargetname( null, "boss2_intro_music_multi" );
	if ( pEntity !is null )
		g_EntityFuncs.Remove( pEntity );

	@pEntity = null;
	while ( ( @pEntity = g_EntityFuncs.FindEntityByString( pEntity, "target", "boss2_intro_music_multi" ) ) !is null )
	{
		if ( pEntity.GetClassname() != "trigger_once" )
			continue;

		pEntity.pev.target = string_t( "boss2_intro_music" );
		break;
	}
}
