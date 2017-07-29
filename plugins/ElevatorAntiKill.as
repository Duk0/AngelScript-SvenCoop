array<string> m_pMovableEntList = { "func_door", "func_train", "func_tracktrain", "func_plat" };

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Duko" );
	g_Module.ScriptInfo.SetContactInfo( "group.midu.cz" );

	g_Hooks.RegisterHook( Hooks::Player::PlayerPreThink, @PlayerPreThink );
}

HookReturnCode PlayerPreThink( CBasePlayer@ pPlayer, uint& out uiFlags )
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

	//if ( pEntity.pev.speed != 0 && m_pMovableEntList.find( pEntity.GetClassname() ) >= 0 )
	if ( m_pMovableEntList.find( pEntity.GetClassname() ) < 0 )
		return HOOK_CONTINUE;

	MovePlayer( pPlayer, vecOrigin );
	
	return HOOK_CONTINUE;
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
