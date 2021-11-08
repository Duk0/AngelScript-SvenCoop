void MapInit()
{
	g_SoundSystem.PrecacheSound( "escape_series/escape3/boss.wav" );
	g_Game.PrecacheGeneric( "sound/escape_series/escape3/boss.wav" );
}

void MapActivate()
{
	CBaseEntity@ pEntity = g_EntityFuncs.FindEntityByTargetname( pEntity, "boss_music" );
	if ( pEntity !is null )
		pEntity.pev.message = string_t( "escape_series/escape3/boss.wav" );

	@pEntity = null;
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
		g_EntityFuncs.Remove( pEntity );
}
