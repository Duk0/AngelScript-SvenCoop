//
// AMX Mod X, based on AMX Mod by Aleksander Naszko ("OLO").
//
// Teleport Menu Plugin
//

array<bool> g_bMenuOption( g_Engine.maxClients + 1, false );
array<Vector> g_vecMenuOrigin( g_Engine.maxClients + 1, g_vecZero );
array<Vector> g_vecMenuVAngle( g_Engine.maxClients + 1, g_vecZero );
array<CTextMenu@> g_TeleMenu( g_Engine.maxClients + 1, null );

int g_iDuckingStateSaved = 0;
void SaveInDuckingState( int index )		{ g_iDuckingStateSaved |= 1 << ( index & 31 ); }
void SaveNoDuckingState( int index ) 		{ g_iDuckingStateSaved &= ~( 1 << ( index & 31 ) ); }
bool HasInDuckingStateSaved( int index ) 	{ return ( g_iDuckingStateSaved & 1 << ( index & 31 ) != 0 ); }

CClientCommand g_teleportmenu( "teleportmenu", "- displays teleport menu", @cmdTelMenu );

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Duko" );
	g_Module.ScriptInfo.SetContactInfo( "group.midu.cz" );
	g_Module.ScriptInfo.SetMinimumAdminLevel( ADMIN_YES );

	g_Hooks.RegisterHook( Hooks::Game::MapChange, @MapChange );
}

HookReturnCode MapChange( const string& in szNextMap )
{
	// set all menus to null. Apparently this fixes crashes for some people:
	// http://forums.svencoop.com/showthread.php/43310-Need-help-with-text-menu#post515087
	for ( int iPlayer = 1; iPlayer <= g_Engine.maxClients; iPlayer++ )
	{
		if ( g_TeleMenu[iPlayer] !is null )
			@g_TeleMenu[iPlayer] = null;

	//	g_bMenuOption[iPlayer] = false;
	//	g_vecMenuOrigin[iPlayer] = g_vecZero;
	//	g_vecMenuVAngle[iPlayer] = g_vecZero;
		//SaveNoDuckingState( iPlayer );
	}
	g_bMenuOption = array<bool>( g_Engine.maxClients + 1, false );
	g_vecMenuOrigin = array<Vector>( g_Engine.maxClients + 1, g_vecZero );
	g_vecMenuVAngle = array<Vector>( g_Engine.maxClients + 1, g_vecZero );
//	g_TeleMenu = array<CTextMenu@>( g_Engine.maxClients + 1, null );
	
	g_iDuckingStateSaved = 0;
	
	g_Scheduler.ClearTimerList();
	
	return HOOK_CONTINUE;
}

class MenuData
{
	string type;
	int page;
}

void actionTelMenuCallback( CTextMenu@ menu, CBasePlayer@ pPlayer, int iSlot, const CTextMenuItem@ pItem )
{
	int iPage = 0;
	bool bRefresh = false;
	if ( pItem !is null && pPlayer !is null )
	{
		int iPlayer = pPlayer.entindex();
		MenuData data;
		pItem.m_pUserData.retrieve( data );
		iPage = data.page;

		if ( data.type == "location" )
		{
			if ( g_vecMenuOrigin[iPlayer] == g_vecZero )
			{
				g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "Save location first\n" );
				menu.Open( 0, iPage, pPlayer );
			}
			else
			{
				g_bMenuOption[iPlayer] = !g_bMenuOption[iPlayer];
				bRefresh = true;
			}
		}
		else if ( data.type == "save" )
		{
			g_vecMenuOrigin[iPlayer] = pPlayer.GetOrigin();
			g_vecMenuVAngle[iPlayer] = Vector( pPlayer.pev.v_angle.x, pPlayer.pev.angles.y, 0 );
			if ( pPlayer.IsAlive() && pPlayer.pev.flags & FL_DUCKING != 0 )
				SaveInDuckingState( iPlayer );
			else
				SaveNoDuckingState( iPlayer );
			
			g_bMenuOption[iPlayer] = true;
			bRefresh = true;
		}
		else
		{
			CBasePlayer@ pDestPlayer = g_PlayerFuncs.FindPlayerByName( data.type, true );
			if ( pDestPlayer !is null && pDestPlayer.IsConnected() && pDestPlayer.IsAlive() )
			{
				bool bMessage = true;
				if ( g_bMenuOption[iPlayer] )
				{
					if ( HasInDuckingStateSaved( pDestPlayer.entindex() ) )
					{
						pDestPlayer.pev.flags |= FL_DUCKING;
						pDestPlayer.pev.view_ofs = Vector( 0.0, 0.0, 12.0 );
					}
					pDestPlayer.SetOrigin( g_vecMenuOrigin[iPlayer] );
					pDestPlayer.pev.angles = g_vecMenuVAngle[iPlayer];
					pDestPlayer.pev.fixangle = FAM_FORCEVIEWANGLES;
				}
				else
				{
					if ( pPlayer !is pDestPlayer )
					{
						if ( pPlayer.pev.flags & FL_DUCKING != 0 )
						{
							pDestPlayer.pev.flags |= FL_DUCKING;
							pDestPlayer.pev.view_ofs = Vector( 0.0, 0.0, 12.0 );
						}
						pDestPlayer.SetOrigin( pPlayer.GetOrigin() );
						pDestPlayer.pev.angles = Vector( pPlayer.pev.v_angle.x, pPlayer.pev.angles.y, 0 );
						pDestPlayer.pev.fixangle = FAM_FORCEVIEWANGLES;
					}
					else
						bMessage = false;
				}

				if ( bMessage )
				{
					g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, "ADMIN " + pPlayer.pev.netname + ": teleport " + pDestPlayer.pev.netname + "\n" );
					g_Game.AlertMessage( at_logged, "ADMIN: %1 teleport %2\n", pPlayer.pev.netname, pDestPlayer.pev.netname );
				}

				menu.Open( 0, iPage, pPlayer );
			}
			else
				bRefresh = true;
		}
	}

	if ( @menu !is null && menu.IsRegistered() )
	{
		//menu.Unregister();
		@menu = null;
	}

	if ( bRefresh )
		g_Scheduler.SetTimeout( "displayTelMenu", 0.01, @pPlayer, iPage );
}

void displayTelMenu( CBasePlayer@ pPlayer, const int iPage = 0 )
{
	if ( pPlayer is null || !pPlayer.IsConnected() )
		return;

	//int iPlayer = g_EntityFuncs.EntIndex( pPlayer.edict() );
	int iPlayer = pPlayer.entindex();

	@g_TeleMenu[iPlayer] = CTextMenu( @actionTelMenuCallback );

	g_TeleMenu[iPlayer].SetTitle( "Teleport Menu " );

//	int iNumPlayers = g_PlayerFuncs.GetNumPlayers();
	int iNumPlayers = 0;
	CBasePlayer@ pTarget;
	for ( int i = 1; i <= g_Engine.maxClients; i++ )
	{
		@pTarget = g_PlayerFuncs.FindPlayerByIndex( i );

		if ( pTarget is null || !pTarget.IsConnected() || !pTarget.IsAlive() )
			continue;

		iNumPlayers++;
	}

	int iCountItems = 0, iPageMenu = 0, iMaxItems = 5;
	string szName;

	for ( int i = 1; i <= g_Engine.maxClients; i++ )
	{
		@pTarget = g_PlayerFuncs.FindPlayerByIndex( i );

		if ( pTarget is null || !pTarget.IsConnected() || !pTarget.IsAlive() )
			continue;

/*		if ( !pTarget.IsAlive() )
		{
			iNumPlayers--;
			continue;
		}*/

		AdminLevel_t adminlvl = g_PlayerFuncs.AdminLevel( pTarget );

		if ( pPlayer !is pTarget && adminlvl == ADMIN_OWNER )
		{
			iNumPlayers--;
			continue;
		}

		szName = pTarget.pev.netname;

		if ( adminlvl >= ADMIN_YES )
			szName += " *";

		MenuData data;
		data.type = string( pTarget.pev.netname );
		data.page = iPageMenu;
		g_TeleMenu[iPlayer].AddItem( szName, any( data ) );

		iCountItems++;

		if ( iCountItems % 5 == 0 || ( iNumPlayers < iMaxItems && iNumPlayers == iCountItems ) )
		{
			data.type = "location";
	
			if ( g_bMenuOption[iPlayer] && g_vecMenuOrigin[iPlayer] != g_vecZero )
				g_TeleMenu[iPlayer].AddItem( "To location: " + int( g_vecMenuOrigin[iPlayer].x ) + " " + int( g_vecMenuOrigin[iPlayer].y ) + " " + int( g_vecMenuOrigin[iPlayer].z ), any( data ) );
			else
				g_TeleMenu[iPlayer].AddItem( "Current Location", any( data ) );

			data.type = "save";
			g_TeleMenu[iPlayer].AddItem( "Save Location", any( data ) );
			
			iPageMenu++;
			iMaxItems *= 2;
		}
	}

	if ( iCountItems > 0 )
	{
		g_TeleMenu[iPlayer].Register();
		g_TeleMenu[iPlayer].Open( 0, iPage, pPlayer );
	}
}

void cmdTelMenu( const CCommand@ args )
{
	CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();

	if ( pPlayer is null || !pPlayer.IsConnected() )
		return;

	if ( g_PlayerFuncs.AdminLevel( pPlayer ) < ADMIN_YES )
	{
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "You have no access to this command.\n" );
		return;
	}

	displayTelMenu( pPlayer );
}
