//Server refused connection because:  Kicked due to reserved slot

int g_iReservedSlots = 12; // 12 default, this sets how many slots would you like reserved 
int g_iStoredSlots = g_iReservedSlots;
dictionary g_dPlayerReserved;
CScheduledFunction@ g_pCheckPlayersFunction = null;
string g_szModuleName;

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Duko" );
	g_Module.ScriptInfo.SetContactInfo( "group.midu.cz" );

	if ( g_iReservedSlots > 0 )
	{
		g_Hooks.RegisterHook( Hooks::Game::MapChange, @MapChange );
		g_Hooks.RegisterHook( Hooks::Player::CanPlayerUseReservedSlot, @CanPlayerUseReservedSlot );
		g_Hooks.RegisterHook( Hooks::Player::ClientPutInServer, @ClientPutInServer );
		g_Hooks.RegisterHook( Hooks::Player::ClientDisconnect, @ClientDisconnect );
	}
	
//	g_EngineFuncs.ServerPrint( "g_AdminControl.GetReservedSlots() = " + g_AdminControl.GetReservedSlots() + "\n" );

	g_szModuleName = "[" + g_Module.GetModuleName() + "] ";
}

void MapInit()
{
	if ( g_iReservedSlots == 0 )
	{
		if ( g_AdminControl.GetReservedSlots() > 0 )
		{
			g_AdminControl.SetReservedSlots( 0 );
			return;
		}
	}

	g_AdminControl.SetReservedSlots( g_iStoredSlots );
}

void MapStart()
{
	if ( g_iReservedSlots == 0 )
		return;

	@g_pCheckPlayersFunction = g_Scheduler.SetTimeout( "CheckPlayers", 25 );
}

HookReturnCode MapChange()
{
	g_Scheduler.ClearTimerList();

	return HOOK_CONTINUE;
}

HookReturnCode CanPlayerUseReservedSlot( edict_t@ pEdict, const string& in szPlayerName, const string& in szIPAddress, bool& out bAllowJoin )
{
	if ( FNullEnt( pEdict ) || !g_EntityFuncs.IsValidEntity( pEdict ) )
		return HOOK_CONTINUE;

	CBasePlayer@ pPlayer = cast<CBasePlayer@>( g_EntityFuncs.Instance( pEdict ) );
	if ( pPlayer is null )
		return HOOK_CONTINUE;

	if ( g_PlayerFuncs.AdminLevel( pPlayer ) >= ADMIN_YES )
	{
		g_EngineFuncs.ServerPrint( g_szModuleName + szPlayerName + " (" +  szIPAddress + ") used reserved slot.\n" );

		int iSlots = g_AdminControl.GetReservedSlots();

		if ( iSlots > 0 )
		{
			g_AdminControl.SetReservedSlots( iSlots - 1 );
			g_iStoredSlots = iSlots - 1;
			g_EngineFuncs.ServerPrint( g_szModuleName + "CanPlayerUseReservedSlot g_iStoredSlots = " + g_iStoredSlots + "\n" );
		}

		string szSteamId = g_EngineFuncs.GetPlayerAuthId( pEdict );

		g_dPlayerReserved.set( szSteamId, true );

		bAllowJoin = true;
		return HOOK_HANDLED;
	}

	return HOOK_CONTINUE;
}

HookReturnCode ClientPutInServer( CBasePlayer@ pPlayer )
{
	int iNumPlayers = g_PlayerFuncs.GetNumPlayers();

	if ( iNumPlayers + g_AdminControl.GetReservedSlots() == g_Engine.maxClients )
	{
		CBasePlayer@ pTarget;
		string szSteamId;
		int iSlots;
	
		for ( int iPlayer = 1; iPlayer <= iNumPlayers; iPlayer++ )
		{
			@pTarget = g_PlayerFuncs.FindPlayerByIndex( iPlayer );

			if ( pTarget is null || !pTarget.IsConnected() )
				continue;

			if ( g_PlayerFuncs.AdminLevel( pTarget ) < ADMIN_YES )
				continue;

			szSteamId = g_EngineFuncs.GetPlayerAuthId( pTarget.edict() );

			if ( !g_dPlayerReserved.exists( szSteamId ) )
			{
				iSlots = g_AdminControl.GetReservedSlots();

				if ( iSlots > 0 )
				{
					g_AdminControl.SetReservedSlots( iSlots - 1 );
					g_iStoredSlots = iSlots - 1;
					g_EngineFuncs.ServerPrint( g_szModuleName + "ClientPutInServer g_iStoredSlots = " + g_iStoredSlots + "\n" );
				}

				g_dPlayerReserved.set( szSteamId, true );
			}
		}
	}
	
	return HOOK_CONTINUE;
}

HookReturnCode ClientDisconnect( CBasePlayer@ pPlayer )
{
/*	if ( pPlayer !is null )
	{
		//int iPlayer = g_EngineFuncs.IndexOfEdict( pPlayer.edict() );

		string szSteamId = g_EngineFuncs.GetPlayerAuthId( pPlayer.edict() );
		if ( g_dPlayerReserved.exists( szSteamId ) )
		{
			g_EngineFuncs.ServerPrint( g_szModuleName + "ClientDisconnect szSteamId = " + szSteamId + "\n" );
		
			int iSlots = g_AdminControl.GetReservedSlots();

			if ( iSlots < g_iReservedSlots )
			{
				g_AdminControl.SetReservedSlots( iSlots + 1 );
				g_iStoredSlots = iSlots + 1;
				g_EngineFuncs.ServerPrint( g_szModuleName + "ClientDisconnect g_iStoredSlots = " + g_iStoredSlots + "\n" );
			}

			g_dPlayerReserved.delete( szSteamId );
		}
	}*/

	if ( g_iReservedSlots == g_iStoredSlots )
		return HOOK_CONTINUE;

	if ( g_pCheckPlayersFunction !is null && !g_pCheckPlayersFunction.HasBeenRemoved() )
		g_Scheduler.RemoveTimer( g_pCheckPlayersFunction );

	@g_pCheckPlayersFunction = g_Scheduler.SetTimeout( "CheckPlayers", 10 );
	
	return HOOK_CONTINUE;
}

void CheckPlayers()
{
	if ( g_iReservedSlots == g_iStoredSlots )
		return;
		
	int iNumPlayers = g_PlayerFuncs.GetNumPlayers();

	if ( iNumPlayers > g_Engine.maxClients - g_iReservedSlots )
		return;
	
	bool bNotFull = iNumPlayers < g_Engine.maxClients - g_iReservedSlots;

	array<string>@ keys = g_dPlayerReserved.getKeys();
	
	string szSteamId;
	bool bDelete;
	CBasePlayer@ pPlayer;
	int iSlots;
	
	for ( uint index = 0; index < keys.length(); index++ )
	{
		szSteamId = keys[ index ];
		bDelete = true;

		if ( !bNotFull )
		{
			for ( int iPlayer = 1; iPlayer <= iNumPlayers; iPlayer++ )
			{
				@pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );

				if ( pPlayer is null || !pPlayer.IsConnected() )
					continue;
					
				if ( szSteamId == g_EngineFuncs.GetPlayerAuthId( pPlayer.edict() ) )
				{
					bDelete = false;
					//g_EngineFuncs.ServerPrint( "Reservation stay stored.\n" );
					break;
				}
			}
		}
		
		if ( bDelete )
		{
			if ( g_dPlayerReserved.exists( szSteamId ) )
			{
				iSlots = g_AdminControl.GetReservedSlots();

				if ( iSlots < g_iReservedSlots )
				{
					g_AdminControl.SetReservedSlots( iSlots + 1 );
					g_iStoredSlots = iSlots + 1;
					g_EngineFuncs.ServerPrint( g_szModuleName + "CheckPlayers g_iStoredSlots = " + g_iStoredSlots + "\n" );
				}

				g_dPlayerReserved.delete( szSteamId );
				//g_EngineFuncs.ServerPrint( "Reservation deleted.\n" );
			}
		}
	}
}
