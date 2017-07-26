
array<bool> g_fMoveLivingPlayers( g_Engine.maxClients + 1, true );
array<bool> g_fRespawnDeadPlayers( g_Engine.maxClients + 1, true );
RespawnMenu g_RespawnMenu;

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
		if ( !g_fMoveLivingPlayers[iPlayer] )
			g_fMoveLivingPlayers[iPlayer] = true;

		if ( !g_fRespawnDeadPlayers[iPlayer] )
			g_fRespawnDeadPlayers[iPlayer] = true;
	}
	
	g_Scheduler.ClearTimerList();
	
	return HOOK_CONTINUE;
}

final class RespawnMenu
{
	private CTextMenu@ m_pMenu = null;
	
	void Show( CBasePlayer@ pPlayer = null )
	{
		if ( m_pMenu is null || !m_pMenu.IsRegistered() )
			CreateMenu( pPlayer );
			
		if ( pPlayer !is null )
			m_pMenu.Open( 0, 0, pPlayer );
	}
	
	private void RefeshMenu( CBasePlayer@ pPlayer = null )
	{
		if ( m_pMenu is null )
			return;

		if ( !m_pMenu.IsRegistered() )
			return;

		m_pMenu.Unregister();
		@m_pMenu = null;
		
		Show( pPlayer );
	}
	
	private void CreateMenu( CBasePlayer@ pPlayer = null )
	{
		@m_pMenu = CTextMenu( TextMenuPlayerSlotCallback( this.Callback ) );

		m_pMenu.SetTitle( "Player Respawn Menu:\n" );
		
		int iPlayer = pPlayer.entindex();
		m_pMenu.AddItem( "Respawn" );
		m_pMenu.AddItem( "Revive" );
		m_pMenu.AddItem( "Kill" );
		m_pMenu.AddItem( "Respawn All" );
		m_pMenu.AddItem( "Move Living " + ( g_fMoveLivingPlayers[iPlayer] ? "(On)" : "(Off)" ) );
		m_pMenu.AddItem( "Respawn Dead " + ( g_fRespawnDeadPlayers[iPlayer] ? "(On)" : "(Off)" ) );

		m_pMenu.Register();
	}
	
	private void Callback( CTextMenu@ menu, CBasePlayer@ pPlayer, int iSlot, const CTextMenuItem@ pItem )
	{
		// iSlot = 1-10, key 0 is 10
		if ( pItem is null || pPlayer is null )
			return;
		
		if ( !pPlayer.IsConnected() )
			return;
			
		int iPlayer = pPlayer.entindex();
		bool bRefresh = false;

		switch( iSlot )
		{
			case 1:
			{
				if ( !pPlayer.IsAlive() )
					bRefresh = true;

				g_PlayerFuncs.RespawnPlayer( pPlayer, g_fMoveLivingPlayers[iPlayer], g_fRespawnDeadPlayers[iPlayer] );
				
				break;
			}

			case 2:
			{
				if ( !pPlayer.IsAlive() )
				{
					pPlayer.Revive();
					pPlayer.pev.health = pPlayer.pev.max_health;
					--pPlayer.m_iDeaths;
				}
				
				break;
			}

			case 3:
			{
				if ( pPlayer.IsAlive() )
					pPlayer.TakeHealth( -pPlayer.pev.health, DMG_GENERIC );
				
				break;
			}

			case 4:
			{
				if ( !pPlayer.IsAlive() )
					bRefresh = true;

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
				
				break;
			}

			case 5:
			{
				g_fMoveLivingPlayers[iPlayer] = !g_fMoveLivingPlayers[iPlayer];
				bRefresh = true;
				break;
			}

			case 6:
			{
				g_fRespawnDeadPlayers[iPlayer] = !g_fRespawnDeadPlayers[iPlayer];
				bRefresh = true;
				break;
			}
		}

		if ( !bRefresh )
		{
			Show( pPlayer );
			return;
		}

		g_Scheduler.SetTimeout( this, "RefeshMenu", 0.01, @pPlayer );
	}
}

void cmdRespawnMenu( const CCommand@ args )
{
	CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();

	if ( pPlayer is null || !pPlayer.IsConnected() )
		return;

	g_RespawnMenu.Show( pPlayer );
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
