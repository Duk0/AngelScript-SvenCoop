
array<string> g_pAmmo = { "health", "9mm", "357", "buckshot", "bolts", "556", "argrenades", "rockets", "uranium", "hornets", "hand grenade", "satchel charge", "trip mine", "snarks", "m40a1", "sporeclip", "shock charges" };
array<int> g_iAmmoIndex;

CScheduledFunction@ g_pInfiniteAmmoFunction = null;
array<CScheduledFunction@> g_pInfiniteAmmoPlayerFunction( g_Engine.maxClients + 1, null );

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Duko" );
	g_Module.ScriptInfo.SetContactInfo( "group.midu.cz" );
	g_Module.ScriptInfo.SetMinimumAdminLevel( ADMIN_YES );
	
	g_Hooks.RegisterHook( Hooks::Game::MapChange, @MapChange );
}

CClientCommand iammo( "iammo", "<playername/#userid/@all>", @CmdInfiniteAmmo );

HookReturnCode MapChange()
{
	g_Scheduler.ClearTimerList();

	return HOOK_CONTINUE;
}

void MapStart()
{
	if ( g_iAmmoIndex.length() > 0 )
		g_iAmmoIndex.resize( 0 );

	for ( uint i = 0; i < g_pAmmo.length(); ++i )
		g_iAmmoIndex.insertLast( g_PlayerFuncs.GetAmmoIndex( g_pAmmo[i] ) );
}

void InfiniteAmmo()
{
	if ( IsMaxEntsUsed() )
	{
		if ( TaskExist( g_pInfiniteAmmoFunction ) )
			g_Scheduler.RemoveTimer( g_pInfiniteAmmoFunction );
			
		g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, "OMG too much (" + g_EngineFuncs.NumberOfEntities() + ") created entities!\n" );
		
		return;
	}

	for ( int iPlayer = 1; iPlayer <= g_Engine.maxClients; ++iPlayer )
	{
		CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );

		if ( pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive() )
			continue;

		GiveAllAmmo( pPlayer );
	}
}

void InfiniteAmmoPlayer( int iPlayer )
{
	CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );

	if ( IsMaxEntsUsed() )
	{
		if ( TaskExist( g_pInfiniteAmmoPlayerFunction[iPlayer] ) )
			g_Scheduler.RemoveTimer( g_pInfiniteAmmoPlayerFunction[iPlayer] );
			
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "OMG too much (" + g_EngineFuncs.NumberOfEntities() + ") created entities!\n" );
		
		return;
	}

	if ( pPlayer is null || !pPlayer.IsConnected() )
	{
		if ( TaskExist( g_pInfiniteAmmoPlayerFunction[iPlayer] ) )
			g_Scheduler.RemoveTimer( g_pInfiniteAmmoPlayerFunction[iPlayer] );

		return;
	}
	
	if ( !pPlayer.IsAlive() )
		return;
		
	GiveAllAmmo( pPlayer );
}

void GiveAllAmmo( CBasePlayer@ pPlayer )
{
	for ( uint i = 0; i < g_iAmmoIndex.length(); ++i )
	{
		int iAmmoIndex = g_iAmmoIndex[i];
		if ( iAmmoIndex == -1 )
			continue;

		int iMaxAmmo = pPlayer.GetMaxAmmo( iAmmoIndex );
	/*	if ( iMaxAmmo == 10 )
			pPlayer.SetMaxAmmo( iAmmoIndex, iMaxAmmo + 10 );*/

		int iAmmoInventory = pPlayer.AmmoInventory( iAmmoIndex );
		if ( iMaxAmmo == iAmmoInventory )
			continue;

		pPlayer.m_rgAmmo( iAmmoIndex, iMaxAmmo );
	}
	
	//pPlayer.GiveNamedItem( "weapon_handgrenade" );
}

void CmdInfiniteAmmo( const CCommand@ args )
{
	CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();

	if ( pPlayer is null || !pPlayer.IsConnected() )
		return;

	string szArg = args.Arg( 1 );
	szArg.Trim();

	if ( args.ArgC() < 2 )
	{
		g_EngineFuncs.ClientPrintf( pPlayer, print_console, "Usage: ." + iammo.GetName() + " " + iammo.GetHelpInfo() + "\n" );
		return;
	}

	if ( szArg.ICompare( "@all" ) == 0 )
	{
		if ( !TaskExist( g_pInfiniteAmmoFunction ) )
		{
			for ( int iPlayer = 1; iPlayer <= g_Engine.maxClients; ++iPlayer )
			{
				if ( TaskExist( g_pInfiniteAmmoPlayerFunction[iPlayer] ) )
					g_Scheduler.RemoveTimer( g_pInfiniteAmmoPlayerFunction[iPlayer] );
			}

			@g_pInfiniteAmmoFunction = g_Scheduler.SetInterval( "InfiniteAmmo", 0.5 );
			g_EngineFuncs.ClientPrintf( pPlayer, print_console, "Task Infinite Ammo for All is on\n" );
		}
		else
		{
			g_Scheduler.RemoveTimer( g_pInfiniteAmmoFunction );
		//	@g_pInfiniteAmmoFunction = null;
			g_EngineFuncs.ClientPrintf( pPlayer, print_console, "Task Infinite Ammo for All is off\n" );
		}
		
		return;
	}
	
	if ( TaskExist( g_pInfiniteAmmoFunction ) )
	{
		g_EngineFuncs.ClientPrintf( pPlayer, print_console, "Task Infinite Ammo for All already run\n" );
		return;
	}

	CBasePlayer@ pTarget = GetTargetPlayer( pPlayer, szArg );

	if ( pTarget is null )
		return;
	
	int iPlayer = pTarget.entindex();
	
	if ( !TaskExist( g_pInfiniteAmmoPlayerFunction[iPlayer] ) )
	{
		@g_pInfiniteAmmoPlayerFunction[iPlayer] = g_Scheduler.SetInterval( "InfiniteAmmoPlayer", 0.5, g_Scheduler.REPEAT_INFINITE_TIMES, iPlayer );
		g_EngineFuncs.ClientPrintf( pPlayer, print_console, "Task Infinite Ammo for " + pTarget.pev.netname + " is on\n" );
	}
	else
	{
		g_Scheduler.RemoveTimer( g_pInfiniteAmmoPlayerFunction[iPlayer] );
		g_EngineFuncs.ClientPrintf( pPlayer, print_console, "Task Infinite Ammo for " + pTarget.pev.netname + " is off\n" );
	}
}

CBasePlayer@ GetTargetPlayer( CBasePlayer@ pPlayer, const string& in szNameOrUserId )
{
	CBasePlayer@ pTarget = g_PlayerFuncs.FindPlayerByName( szNameOrUserId, false );
	int iCount = 0;

	if ( pTarget is null )
	{
		CBasePlayer@ pTempPlayer = null;
		string szPlayerName;
		for ( int iIndex = 1; iIndex <= g_Engine.maxClients; ++iIndex )
		{
			@pTempPlayer = g_PlayerFuncs.FindPlayerByIndex( iIndex );
			
			if ( pTempPlayer is null || !pTempPlayer.IsConnected() )
				continue;

			szPlayerName = pTempPlayer.pev.netname;
			
			if ( int( szPlayerName.Find( szNameOrUserId, 0, String::CaseInsensitive ) ) != -1 )
			{
				@pTarget = pTempPlayer;
				iCount++;
			}
			
			if ( iCount > 1 )
				break;
		}
	}
		
	if ( pTarget is null && szNameOrUserId[0] == "#" )
	{
		string szUserId;
		for ( int iIndex = 1; iIndex <= g_Engine.maxClients; ++iIndex )
		{
			@pTarget = g_PlayerFuncs.FindPlayerByIndex( iIndex );
			
			if ( pTarget is null || !pTarget.IsConnected() )
				continue;

			szUserId = "#" + g_EngineFuncs.GetPlayerUserId( pTarget.edict() );
			
			if ( szUserId == szNameOrUserId )
				break;
					
			@pTarget = null;
		}
	}

	if ( pTarget is null )
	{
		g_EngineFuncs.ClientPrintf( pPlayer, print_console, "Client with that name or userid not found\n" );
		return null;
	}

	if ( iCount > 1 )
	{
		g_EngineFuncs.ClientPrintf( pPlayer, print_console, "There is more than one client matching your argument\n" );
		return null;
	}

	if ( pTarget !is pPlayer && IsPlayerAdmin( pTarget ) )
	{
		g_EngineFuncs.ClientPrintf( pPlayer, print_console, "Client " + pTarget.pev.netname + " has immunity\n" );
		return null;
	}
	
	return pTarget;
}

bool TaskExist( CScheduledFunction@ pFunction )
{
	if ( pFunction is null )
		return false;

	return !pFunction.HasBeenRemoved();
}

bool IsPlayerAdmin( CBasePlayer@ pPlayer )
{
	return g_PlayerFuncs.AdminLevel( pPlayer ) >= ADMIN_YES;
}

bool IsMaxEntsUsed()
{
	return g_Engine.maxEntities <= g_EngineFuncs.NumberOfEntities() + 1024;
}
