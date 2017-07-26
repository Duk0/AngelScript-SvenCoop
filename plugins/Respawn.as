
array<CTextMenu@> g_RespawnMenu( g_Engine.maxClients + 1, null );
array<bool> g_fMoveLivingPlayers( g_Engine.maxClients + 1, true );
array<bool> g_fRespawnDeadPlayers( g_Engine.maxClients + 1, true );

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Duko" );
	g_Module.ScriptInfo.SetContactInfo( "group.midu.cz" );
	g_Module.ScriptInfo.SetMinimumAdminLevel( ADMIN_YES );

	g_Hooks.RegisterHook( Hooks::Player::ClientSay, @ClientSay );
	g_Hooks.RegisterHook( Hooks::Game::MapChange, @MapChange );
}

CClientCommand g_respawnmenu( "respawnmenu", "- displays respawn menu", @cmdRespawnMenu );

HookReturnCode ClientSay( SayParameters@ pParams )
{
	const CCommand@ pArguments = pParams.GetArguments();
	
	if ( pArguments.ArgC() >= 1 )
	{
		if ( pArguments.Arg( 0 ) == "/r" )
		{
			pParams.ShouldHide = true; // Do not show this command in player chat

			CBasePlayer@ pPlayer = pParams.GetPlayer();

			if ( pPlayer is null || !pPlayer.IsConnected() )
				return HOOK_HANDLED;
			
			g_PlayerFuncs.RespawnPlayer( pPlayer, true, true );

			return HOOK_HANDLED;
		}
	}
	
	return HOOK_CONTINUE;
}

HookReturnCode MapChange()
{
	for ( int iPlayer = 1; iPlayer <= g_Engine.maxClients; ++iPlayer )
	{
		if ( g_RespawnMenu[iPlayer] !is null )
			@g_RespawnMenu[iPlayer] = null;

		if ( !g_fMoveLivingPlayers[iPlayer] )
			g_fMoveLivingPlayers[iPlayer] = true;

		if ( !g_fRespawnDeadPlayers[iPlayer] )
			g_fRespawnDeadPlayers[iPlayer] = true;
	}
	
	g_Scheduler.ClearTimerList();
	
	return HOOK_CONTINUE;
}

void actionRespawnMenu( CTextMenu@ menu, CBasePlayer@ pPlayer, int iSlot, const CTextMenuItem@ pItem )
{
	if ( pItem !is null && pPlayer !is null )
	{
		if ( !pPlayer.IsConnected() )
			return;
			
		int iPlayer = pPlayer.entindex();
		bool bAlive = false;
		string szData;
		pItem.m_pUserData.retrieve( szData );

		if ( szData == "respawn" )
		{
			if ( pPlayer.IsAlive() )
				bAlive = true;

			g_PlayerFuncs.RespawnPlayer( pPlayer, g_fMoveLivingPlayers[iPlayer], g_fRespawnDeadPlayers[iPlayer] );
		}

		if ( szData == "revive" )
		{
			bAlive = true;

			if ( !pPlayer.IsAlive() )
			{
				pPlayer.Revive();
				pPlayer.pev.health = pPlayer.pev.max_health;
				--pPlayer.m_iDeaths;
			}
		}

		if ( szData == "kill" )
		{
			bAlive = true;

			if ( pPlayer.IsAlive() )
				pPlayer.TakeHealth( -pPlayer.pev.health, DMG_GENERIC );
		}

		if ( szData == "respawnall" )
		{
			if ( pPlayer.IsAlive() )
				bAlive = true;

			if ( IsPlayerAdminOwner( pPlayer ) )
			{
				g_PlayerFuncs.RespawnAllPlayers( g_fMoveLivingPlayers[iPlayer], g_fRespawnDeadPlayers[iPlayer] );
			}
			else
			{
				for ( int iClient = 1; iClient <= g_Engine.maxClients; ++iClient )
				{
					CBasePlayer@ pTarget = g_PlayerFuncs.FindPlayerByIndex( iClient );
				
					if ( pTarget is null || !pTarget.IsConnected() )
						continue;

					if ( IsPlayerAdminOwner( pTarget ) )
						continue;

					g_PlayerFuncs.RespawnPlayer( pTarget, g_fMoveLivingPlayers[iPlayer], g_fRespawnDeadPlayers[iPlayer] );
				}
			}

			string szText = "Moved ";
			if ( g_fMoveLivingPlayers[iPlayer] )
				szText += "living";
			else
				szText += "dead";

			if ( g_fRespawnDeadPlayers[iPlayer] )
				szText += " and respawned";

			szText += " all players";
					
			ShowActivity( pPlayer, szText + "\n" );
			g_Game.AlertMessage( at_logged, "ADMIN %1: %2\n", pPlayer.pev.netname, szText );
		}

		if ( bAlive )
		{
			g_RespawnMenu[iPlayer].Open( 0, 0, pPlayer );
			return;
		}

		if ( szData == "movealive" )
			g_fMoveLivingPlayers[iPlayer] = !g_fMoveLivingPlayers[iPlayer];

		if ( szData == "respawndead" )
			g_fRespawnDeadPlayers[iPlayer] = !g_fRespawnDeadPlayers[iPlayer];
		
		g_Scheduler.SetTimeout( "displayRespawnMenu", 0.01, @pPlayer );
	}
}

void displayRespawnMenu( CBasePlayer@ pPlayer )
{
	if ( pPlayer is null || !pPlayer.IsConnected() )
		return;

	int iPlayer = pPlayer.entindex();
	
	if ( iPlayer > g_Engine.maxClients || iPlayer <= 0 )
		return;

	@g_RespawnMenu[iPlayer] = CTextMenu( @actionRespawnMenu );
	g_RespawnMenu[iPlayer].SetTitle( "Player Respawn Menu\n\n" );

	g_RespawnMenu[iPlayer].AddItem( "Respawn", any( "respawn" ) );
	g_RespawnMenu[iPlayer].AddItem( "Revive", any( "revive" ) );
	g_RespawnMenu[iPlayer].AddItem( "Kill", any( "kill" ) );
	g_RespawnMenu[iPlayer].AddItem( "Respawn All", any( "respawnall" ) );
	g_RespawnMenu[iPlayer].AddItem( "Move Living " + ( g_fMoveLivingPlayers[iPlayer] ? "(On)" : "(Off)" ), any( "movealive" ) );
	g_RespawnMenu[iPlayer].AddItem( "Respawn Dead " + ( g_fRespawnDeadPlayers[iPlayer] ? "(On)" : "(Off)" ), any( "respawndead" ) );

	g_RespawnMenu[iPlayer].Register();
	g_RespawnMenu[iPlayer].Open( 0, 0, pPlayer );
}

void cmdRespawnMenu( const CCommand@ args )
{
	CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();

	displayRespawnMenu( pPlayer );
}

void ShowActivity( CBasePlayer@ pPlayer, const string& in szMessage )
{
	for ( int iIndex = 1; iIndex <= g_Engine.maxClients; ++iIndex )
	{
		CBasePlayer@ pTarget = g_PlayerFuncs.FindPlayerByIndex( iIndex );
		
		if ( pTarget is null || !pTarget.IsConnected() )
			continue;
		
		if ( g_PlayerFuncs.AdminLevel( pTarget ) >= ADMIN_YES )
			g_PlayerFuncs.ClientPrint( pTarget, HUD_PRINTTALK, "ADMIN " + pPlayer.pev.netname + ": " + szMessage );
		else
			g_PlayerFuncs.ClientPrint( pTarget, HUD_PRINTTALK, "ADMIN: " + szMessage );
	}
}

bool IsPlayerAdminOwner( CBasePlayer@ pPlayer )
{
	return g_PlayerFuncs.AdminLevel( pPlayer ) == ADMIN_OWNER;
}
