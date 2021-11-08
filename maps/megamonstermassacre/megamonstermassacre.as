//const string szEntFile = "4ways/4ways.ent";

void MapActivate()
{
	CBaseEntity@ pEntity = null;
	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "monster_alien_grunt" ) ) !is null )
	{
		pEntity.pev.max_health = 300;
		pEntity.pev.health = 300;
	}

	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "monster_bullchicken" ) ) !is null )
	{
		pEntity.pev.max_health = 3000;
		pEntity.pev.health = 3000;
	}

	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "monster_alien_slave" ) ) !is null )
	{
		pEntity.pev.max_health = 2250;
		pEntity.pev.health = 2250;
	}

	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "monster_headcrab" ) ) !is null )
	{
		pEntity.pev.max_health = 900;
		pEntity.pev.health = 900;
	}

	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "monster_zombie" ) ) !is null )
	{
		pEntity.pev.max_health = 1200;
		pEntity.pev.health = 1200;
	}
	
	while ( ( @pEntity = g_EntityFuncs.FindEntityByTargetname( pEntity, "group giant" ) ) !is null )
	{
		string szClassName = pEntity.GetClassname();
		Vector vecOrigin = pEntity.GetOrigin();

		if ( szClassName == "squadmaker" && vecOrigin == Vector( -1280, -512, -800 ) )
		{
			pEntity.pev.max_health = 2250;
			pEntity.pev.health = 2250;
		}

		if ( szClassName == "squadmaker" && vecOrigin == Vector( -1536, -256, -800 ) )
		{
			pEntity.pev.max_health = 1200;
			pEntity.pev.health = 1200;
		}

		if ( szClassName == "squadmaker" && vecOrigin == Vector( -1472, 64, -800 ) )
		{
			pEntity.pev.max_health = 900;
			pEntity.pev.health = 900;
		}

		if ( szClassName == "squadmaker" && vecOrigin == Vector( -1088, -448, -800 ) )
		{
			pEntity.pev.max_health = 900;
			pEntity.pev.health = 900;
		}

		if ( szClassName == "squadmaker" && vecOrigin == Vector( -1216, 64, -800 ) )
		{
			pEntity.pev.max_health = 1200;
			pEntity.pev.health = 1200;
		}
	}

	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "game_text" ) ) !is null )
	{
		string szTargetname = pEntity.GetTargetname();
		if ( szTargetname == "endrelay" || szTargetname == "massacretext" || szTargetname == "blastoff" || szTargetname.CompareN( "cd", 2 ) == 0 )
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "y", "0.55" );
	}

	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "weapon_9mmAR" ) ) !is null )
	{
		g_EntityFuncs.Create( "ammo_buckshot", pEntity.GetOrigin(), pEntity.pev.angles, false );
		g_EntityFuncs.Remove( pEntity );
	}

	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "weapon_shotgun" ) ) !is null )
	{
		g_EntityFuncs.Create( "ammo_buckshot", pEntity.GetOrigin(), pEntity.pev.angles, false );
		g_EntityFuncs.Remove( pEntity );
	}

/*	if ( !g_EntityLoader.LoadFromFile( szEntFile ) )
		g_EngineFuncs.ServerPrint( "Can't open " + szEntFile + "\n" );*/
}