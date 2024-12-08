int g_iAmmoIndex = -1;
HUDTextParams g_hudTxtParam;
array<bool> g_bToggleStatus( g_Engine.maxClients + 1, false );
dictionary g_dMedkitStatus;

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Duko" );
	g_Module.ScriptInfo.SetContactInfo( "group.midu.cz" );

	g_Hooks.RegisterHook( Hooks::Game::MapChange, @MapChange );
	g_Hooks.RegisterHook( Hooks::Player::ClientSay, @ClientSay );
	g_Hooks.RegisterHook( Hooks::Player::ClientDisconnect, @ClientDisconnect );
	g_Hooks.RegisterHook( Hooks::Player::ClientPutInServer, @ClientPutInServer );
//	g_Hooks.RegisterHook( Hooks::Player::PlayerKilled, @PlayerKilled );

	g_hudTxtParam.r1 = 130;
	g_hudTxtParam.g1 = 160;
	g_hudTxtParam.b1 = 255;
	g_hudTxtParam.a1 = 0;
	g_hudTxtParam.r2 = 255;
	g_hudTxtParam.g2 = 255;
	g_hudTxtParam.b2 = 250;
	g_hudTxtParam.a2 = 0;

	g_hudTxtParam.x = 0.8;
	g_hudTxtParam.y = 0.01;

	g_hudTxtParam.effect = 0;

	g_hudTxtParam.fxTime = 0.;
	g_hudTxtParam.holdTime = 1.5;
					
	g_hudTxtParam.fadeinTime = 0;
	g_hudTxtParam.fadeoutTime = 0;

	g_hudTxtParam.channel = 7;
}

CClientCommand showmedkits( "showmedkits", "show players medkits", @CmdShowMedkits );

void CmdShowMedkits( const CCommand@ args )
{
	CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();

	if ( pPlayer is null || !pPlayer.IsConnected() )
		return;

	string szSteamId = g_EngineFuncs.GetPlayerAuthId( pPlayer.edict() );
	int iPlayer = pPlayer.entindex();
			
	if ( g_dMedkitStatus.exists( szSteamId ) )
	{
		g_dMedkitStatus.delete( szSteamId );
		g_bToggleStatus[iPlayer] = false;
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "[AS] Players medkits status is off.\n" );
	}
	else
	{
		g_dMedkitStatus.set( szSteamId, true );
		g_bToggleStatus[iPlayer] = true;
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "[AS] Players medkits status is on.\n" );
	}
}

void MapStart()
{
	g_iAmmoIndex = g_PlayerFuncs.GetAmmoIndex( "health" );

/*	for ( int iPlayer = 1; iPlayer <= g_Engine.maxClients; iPlayer++ )
		g_bToggleStatus[iPlayer] = false;*/
	g_bToggleStatus = array<bool>( g_Engine.maxClients + 1, false );

	g_Scheduler.SetInterval( "MedKitStatusThink", 1 );

	g_Scheduler.SetTimeout( "DeleteDictOnEmtpyServer", 180.5 );
}

HookReturnCode MapChange( const string& in szNextMap )
{
	g_Scheduler.ClearTimerList();

	return HOOK_CONTINUE;
}

HookReturnCode ClientSay( SayParameters@ pParams )
{
	const CCommand@ pArguments = pParams.GetArguments();

	if ( pArguments.ArgC() >= 1 )
	{
		CBasePlayer@ pPlayer = pParams.GetPlayer();

		string szArg = pArguments.Arg( 0 );
		szArg.Trim();
		if ( szArg.ICompare( "!medkits" ) == 0 )
		{
			if ( pPlayer is null || !pPlayer.IsConnected() )
				return HOOK_CONTINUE;

			string szSteamId = g_EngineFuncs.GetPlayerAuthId( pPlayer.edict() );
			int iPlayer = pPlayer.entindex();
			
			if ( g_dMedkitStatus.exists( szSteamId ) )
			{
				g_dMedkitStatus.delete( szSteamId );
				g_bToggleStatus[iPlayer] = false;
				g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "[AS] Players medkits status is off.\n" );
			}
			else
			{
				g_dMedkitStatus.set( szSteamId, true );
				g_bToggleStatus[iPlayer] = true;
				g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "[AS] Players medkits status is on.\n" );
			}

			return HOOK_CONTINUE;
		}
	}
	return HOOK_CONTINUE;
}

HookReturnCode ClientDisconnect( CBasePlayer@ pPlayer )
{
	if ( pPlayer is null )
		return HOOK_CONTINUE;

	string szSteamId = g_EngineFuncs.GetPlayerAuthId( pPlayer.edict() );
	if ( g_dMedkitStatus.exists( szSteamId ) )
	{
		g_dMedkitStatus.delete( szSteamId );

		int iPlayer = pPlayer.entindex();
		g_bToggleStatus[iPlayer] = false;
	}

	return HOOK_CONTINUE;
}

HookReturnCode ClientPutInServer( CBasePlayer@ pPlayer )
{
	if ( pPlayer is null )
		return HOOK_CONTINUE;

	string szSteamId = g_EngineFuncs.GetPlayerAuthId( pPlayer.edict() );
	if ( g_dMedkitStatus.exists( szSteamId ) )
	{
		int iPlayer = pPlayer.entindex();
		g_bToggleStatus[iPlayer] = true;
	}

	return HOOK_CONTINUE;
}


/*
HookReturnCode PlayerKilled( CBasePlayer@ pPlayer, CBaseEntity@ pAttacker, int iGib )
{
	if ( pPlayer is null || !pPlayer.IsConnected() )
		return HOOK_CONTINUE;

	int iPlayer = pPlayer.entindex();


	return HOOK_CONTINUE;
}
*/

void MedKitStatusThink()
{
	if ( g_dMedkitStatus.isEmpty() )
		return;

	CBasePlayer@ pPlayer;
	array<CBasePlayer@> pPlayersList;
	int iAmmo;
	string szStatus;

	for ( int iPlayer = 1; iPlayer <= g_Engine.maxClients; iPlayer++ )
	{
		@pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );

		if ( pPlayer is null || !pPlayer.IsConnected() )
			continue;

		if ( !g_bToggleStatus[iPlayer] )
			continue;

		if ( pPlayer.HasNamedPlayerItem( "weapon_medkit" ) is null )
			continue;

		if ( pPlayer.IsAlive() )
		{
			iAmmo = pPlayer.AmmoInventory( g_iAmmoIndex );
			szStatus += string( pPlayer.pev.netname ) + " has " + iAmmo + " medkit points\n";
		}
		else
		{
			if ( !pPlayer.IsRevivable() )
				continue;
		}

	//	if ( !IsPlayerAdmin( pPlayer ) )
	//		continue;
	
		pPlayersList.insertLast( pPlayer );
	}
	
	if ( !szStatus.IsEmpty() )
	{
		CBasePlayer@ pTarget;

		for ( uint n = 0; n < pPlayersList.length(); n++ )
		{
			@pTarget = pPlayersList[n];

			if ( pTarget is null )
				continue;
			
			if ( pTarget.pev.max_health - pTarget.pev.health <= 15 )
				continue;

			g_PlayerFuncs.HudMessage( pTarget, g_hudTxtParam, szStatus );
		}
	}
}
/*
bool DeadNotify( CBasePlayer@ pPlayer )
{
	CBaseEntity@ pEntity = null;
	Vector vecOrigin = pPlayer.GetOrigin();
	bool bResult = false;

	while ( ( @pEntity = g_EntityFuncs.FindEntityInSphere( pEntity, vecOrigin, 50.0, "player", "classname" ) ) !is null )
	{
		CBasePlayer@ pTarget = cast<CBasePlayer@>( pEntity );

		if ( pTarget is null || !pTarget.IsConnected() || !pTarget.IsAlive() )
		{
			bResult = true;
			break;
		}	
	}
	
	return bResult;
}
*/
bool IsPlayerAdmin( CBasePlayer@ pPlayer )
{
	return g_PlayerFuncs.AdminLevel( pPlayer ) >= ADMIN_YES;
}

void DeleteDictOnEmtpyServer()
{
	if ( g_PlayerFuncs.GetNumPlayers() == 0 && !g_dMedkitStatus.isEmpty() )
		g_dMedkitStatus.deleteAll();
}
