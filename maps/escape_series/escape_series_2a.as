void MapActivate()
{
	CBaseEntity@ pEntity = null;
	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "weapon_*" ) ) !is null )
	{
		if ( pEntity.GetClassname() == "weapon_tripmine" )
			continue;

		if ( !pEntity.pev.SpawnFlagBitSet( SF_NORESPAWN ) )
			continue;
			
		pEntity.pev.spawnflags &= ~SF_NORESPAWN;
	}

	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "ammo_*" ) ) !is null )
	{
		if ( !pEntity.pev.SpawnFlagBitSet( SF_NORESPAWN ) )
			continue;
			
		pEntity.pev.spawnflags &= ~SF_NORESPAWN;
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
		g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "boss1_intro_music", "0" );


	@pEntity = g_EntityFuncs.FindEntityByTargetname( null, "weapon_uzi_maker" );
	if ( pEntity !is null )
		pEntity.pev.spawnflags &= ~SF_NORESPAWN;
}
