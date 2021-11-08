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

	@pEntity = g_EntityFuncs.FindEntityByTargetname( null, "spawn_change33_multi" );
	if ( pEntity !is null )
		g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "boss1_intro_music", "0" );
		
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
	while ( ( @pEntity = g_EntityFuncs.FindEntityByTargetname( pEntity, "boss_music" ) ) !is null )
	{
		if ( pEntity.GetClassname() != "multi_manager" )
			continue;

		g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "boss2_intro_music", "0" );
		break;
	}


	@pEntity = g_EntityFuncs.FindEntityByClassname( null, "trigger_changelevel" );
	if ( pEntity !is null )
		g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "keep_inventory", "0" );

	@pEntity = g_EntityFuncs.FindEntityByClassname( null, "weapon_m249" );
	if ( pEntity !is null )
		pEntity.pev.spawnflags &= ~SF_NORESPAWN;

	@pEntity = null;
	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "ammo_556" ) ) !is null )
	{
		if ( !pEntity.pev.SpawnFlagBitSet( SF_NORESPAWN ) )
			continue;
			
		pEntity.pev.spawnflags &= ~SF_NORESPAWN;
	}
}
