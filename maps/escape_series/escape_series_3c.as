void MapInit()
{
	g_SoundSystem.PrecacheSound( "escape_series/escape3/boss.wav" );
	g_Game.PrecacheGeneric( "sound/escape_series/escape3/boss.wav" );
}

void MapActivate()
{
	CBaseEntity@ pEntity = null;
	bool bFirst = false;
	while ( ( @pEntity = g_EntityFuncs.FindEntityByTargetname( pEntity, "boss1_intro_music" ) ) !is null )
	{
		if ( bFirst )
		{
			g_EntityFuncs.Remove( pEntity );
			continue;
		}
	
		pEntity.pev.message = string_t( "escape_series/escape3/boss.wav" );
		bFirst = true;
	}

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
	
	@pEntity = g_EntityFuncs.FindEntityByTargetname( null, "boss1_start" );
	if ( pEntity !is null )
		g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "boss1_intro_music", "8" );


	@pEntity = null;
	while ( ( @pEntity = g_EntityFuncs.FindEntityByTargetname( pEntity, "dark_room_multi" ) ) !is null )
	{
		if ( pEntity.GetClassname() != "multi_manager" )
			continue;

		if ( pEntity.GetOrigin() != Vector( -3020, 651, -1244 ) )
			continue;

		g_EntityFuncs.Remove( pEntity );
		break;
	}
}
