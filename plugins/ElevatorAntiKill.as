array<string> m_pMovableEntList = { "func_door", "func_train", "func_tracktrain", "func_trackchange", "func_plat" };
int g_iTest = 0;

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Duko" );
	g_Module.ScriptInfo.SetContactInfo( "group.midu.cz" );

	//g_Hooks.RegisterHook( Hooks::Player::PlayerPostThink, @PlayerPostThink );
	g_Hooks.RegisterHook( Hooks::Game::MapChange, @MapChange );
	//g_Scheduler.SetInterval( "ElevatorThink", 0.5 );
}

void MapStart()
{
	g_Scheduler.SetInterval( "ElevatorThink", 0.5 );
}

HookReturnCode MapChange()
{
	g_Scheduler.ClearTimerList();

	return HOOK_CONTINUE;
}

/*HookReturnCode PlayerPostThink( CBasePlayer@ pPlayer )
{
	if ( pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive() )
		return HOOK_CONTINUE;

	CBaseEntity@ pEntity = g_EntityFuncs.Instance( pPlayer.pev.groundentity );
	if ( pEntity is null || !pEntity.IsPlayer() )
		return HOOK_CONTINUE;

	Vector vecOrigin = pEntity.GetOrigin();
	@pEntity = g_EntityFuncs.Instance( pEntity.pev.groundentity );
	//if ( pEntity is null || !pEntity.IsMoving() )
	if ( pEntity is null || pEntity.IsPlayer() || pEntity is g_EntityFuncs.Instance( 0 ) )
		return HOOK_CONTINUE;

	//if ( pEntity.pev.speed == 0 || m_pMovableEntList.find( pEntity.GetClassname() ) < 0 )
	if ( m_pMovableEntList.find( pEntity.GetClassname() ) < 0 )
		return HOOK_CONTINUE;

	MovePlayer( pPlayer, vecOrigin );
	
	return HOOK_CONTINUE;
}*/

void ElevatorThink()
{
	CBasePlayer@ pPlayer;
	CBaseEntity@ pEntity;
	Vector vecOrigin;
	for ( int iPlayer = 1; iPlayer <= g_Engine.maxClients; ++iPlayer )
	{
		@pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );

		if ( pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive() )
			continue;

		@pEntity = g_EntityFuncs.Instance( pPlayer.pev.groundentity );
		if ( pEntity is null || !pEntity.IsPlayer() )
			continue;

		vecOrigin = pEntity.GetOrigin();
		@pEntity = g_EntityFuncs.Instance( pEntity.pev.groundentity );
		//if ( pEntity is null || !pEntity.IsMoving() )
		if ( pEntity is null || pEntity.IsPlayer() || pEntity is g_EntityFuncs.Instance( 0 ) )
			continue;

		//if ( pEntity.pev.speed == 0 || m_pMovableEntList.find( pEntity.GetClassname() ) < 0 )
		if ( m_pMovableEntList.find( pEntity.GetClassname() ) < 0 )
			continue;

		MovePlayer( pPlayer, vecOrigin );
	}
}

void MovePlayer( CBasePlayer@ pPlayer, Vector &in vecOrigin )
{
	int iStartDistance = 32, iDistance = iStartDistance, iMaxAttempts = 128;
	Vector vecNewOrigin;
	TraceResult tr;
	HULL_NUMBER hullNumber = ( pPlayer.pev.flags & FL_DUCKING ) != 0 ? head_hull : human_hull;

	while ( iDistance < 1000 )
	{
		for ( int iAttempts = 0; iAttempts < iMaxAttempts; iAttempts++ )
		{
			vecNewOrigin.x = Math.RandomFloat( vecOrigin.x - iDistance, vecOrigin.x + iDistance );
			vecNewOrigin.y = Math.RandomFloat( vecOrigin.y - iDistance, vecOrigin.y + iDistance );
			vecNewOrigin.z = Math.RandomFloat( vecOrigin.z - iDistance, vecOrigin.z + iDistance );

			g_Utility.TraceHull( vecNewOrigin, vecNewOrigin, dont_ignore_monsters, hullNumber, pPlayer.edict(), tr );

			if ( IntToBool( tr.fInOpen ) && !IntToBool( tr.fAllSolid ) && !IntToBool( tr.fStartSolid ) )
			{
				pPlayer.SetOrigin( vecNewOrigin );
				return;
			}
		}

		iDistance += iStartDistance;
	}
}

bool IntToBool( int iVal )
{
	if ( iVal > 0 )
		return true;

	return false;
}
