void MapActivate()
{
	CBaseEntity@ pEntity = null;
	CBaseToggle@ pToggle;
	string szTargetname;

	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "trigger_multiple" ) ) !is null )
	{
		@pToggle = cast<CBaseToggle@>( pEntity );

		if ( pToggle is null )
			continue;

		if ( pToggle.m_flWait > 0 )
			continue;
			
		pToggle.m_flWait = 1; 
	}

	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "game_text" ) ) !is null )
	{
		g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "y", "0.55" );

		szTargetname = pEntity.GetTargetname();

		if ( szTargetname == "text" || szTargetname == "hammertext" ||  szTargetname == "magictext" )
			pEntity.pev.spawnflags = 2;
	}

/*	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "monster_scientist" ) ) !is null )
	{
		//edict_t@ pEdict = pEntity.edict();
		pEntity.pev.max_health = 200;
		pEntity.pev.health = 200;
		g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "is_not_revivable", "1" );
	}
	
	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "env_spark" ) ) !is null )
	{
		if ( pEntity.GetOrigin() == Vector( 1888, 1728, -1104 ) )
		{
			g_EntityFuncs.Remove( pEntity );
			pEntity.pev.spawnflags = 96;
			break;
		}
	}*/
}
