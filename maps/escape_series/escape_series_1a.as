void MapActivate()
{
	CBaseEntity@ pEntity = null;
	while ( ( @pEntity = g_EntityFuncs.FindEntityByTargetname( pEntity, "boss1_end" ) ) !is null )
	{
		if ( pEntity.GetClassname() != "trigger_once" )
			continue;
		
		g_EntityFuncs.Remove( pEntity );
	}
	
	@pEntity = g_EntityFuncs.FindEntityByTargetname( null, "killer" );
	if ( pEntity !is null )
		g_EntityFuncs.Remove( pEntity );

	@pEntity = g_EntityFuncs.FindEntityByTargetname( null, "boss1_intro_music_multi" );
	if ( pEntity !is null )
		g_EntityFuncs.Remove( pEntity );
	
	@pEntity = g_EntityFuncs.FindEntityByTargetname( null, "level05_key_multi_man" );
	if ( pEntity !is null )
		g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "boss1_intro_music", "0" );
}
