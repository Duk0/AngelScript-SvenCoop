const int MAX_ATTEMPTS = 128;

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Duko" );
	g_Module.ScriptInfo.SetContactInfo( "group.midu.cz" );
	
	g_Hooks.RegisterHook( Hooks::Game::MapChange, @MapChange );
}

HookReturnCode MapChange()
{
	g_Scheduler.ClearTimerList();

	return HOOK_CONTINUE;
}

void MapStart()
{
	g_Scheduler.SetTimeout( "FixTurrets", 6 );
}

void FixTurrets()
{
	CBaseEntity@ pEntity = null;
	Vector vecOrigin;
	int iCount = 0;

	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "monster_turret" ) ) !is null )
	{
		if ( !MoveTurret( pEntity, 1 ) )
			continue;

		iCount++;
	}
	
	if ( iCount > 0 )
	{
		g_EngineFuncs.ServerPrint( "[TurretSoundFix] Fixed " + iCount + " monster_turret entities\n" );
		iCount = 0;
	}

	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "monster_miniturret" ) ) !is null )
	{
		if ( !MoveTurret( pEntity, 0.5 ) )
			continue;

		iCount++;
	}
	
	if ( iCount > 0 )
		g_EngineFuncs.ServerPrint( "[TurretSoundFix] Fixed " + iCount + " monster_miniturret entities\n" );
}

bool MoveTurret( CBaseEntity@ pEntity, float &in flOffset )
{
	bool bResult = false;
	Vector vecOrigin = pEntity.GetOrigin();
	float flOrientation = pEntity.pev.angles.x;
	
	for ( int iAttempts = 0; iAttempts < MAX_ATTEMPTS; iAttempts++ )
	{
		if ( pEntity.FVisible( vecOrigin ) )
		{
			if ( iAttempts > 0 )
				bResult = true;
				
		//	g_EngineFuncs.ServerPrint( "iAttempts = " + iAttempts + "\n" );

			break;
		}
	
		if ( flOrientation == 0 )
			vecOrigin.z += flOffset;
		else if ( flOrientation == 180 )
			vecOrigin.z -= flOffset;
	}
	
	if ( bResult )
		pEntity.SetOrigin( vecOrigin );
	
	return bResult;
}
