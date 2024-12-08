//
// AMX Mod X, based on AMX Mod by Aleksander Naszko ("OLO").
//
// Maps Menu Plugin
//

const int SELECT_MAX = 4; // don't change

array<string> g_mapName;
int g_mapNums;
array<int> g_menuPosition( g_Engine.maxClients + 1 );

array<int> g_voteCount( SELECT_MAX, 0 );

array<array<string>> g_voteSelected( g_Engine.maxClients + 1 );

float g_flVoting = 0;

array<CTextMenu@> g_MapsMenu( g_Engine.maxClients + 1, null );

CTextMenu@ g_VoteMenu, g_VoteMapsMenu;

//CScheduledFunction@ g_pDelayedChangeFunction = null;
CScheduledFunction@ g_pAutoRefuseFunction = null, g_pCheckVotesFunction = null;

CCVar@ g_pCCVar_VoteAnswers, g_pCCVar_VoteDelay, g_pCCVar_VoteTime, g_pCCVar_VoteMapRatio;

const string g_szMapsFile = "scripts/plugins/Configs/maps.ini";

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Duko" );
	g_Module.ScriptInfo.SetContactInfo( "group.midu.cz" );
	g_Module.ScriptInfo.SetMinimumAdminLevel( ADMIN_YES );

	@g_pCCVar_VoteAnswers = CCVar( "vote_answers", "1", "Display who votes for what option, set to 0 to disable, 1 to enable." );
	@g_pCCVar_VoteDelay = CCVar( "vote_delay", "10", "Minimum delay in seconds between two voting sessions" );
	@g_pCCVar_VoteTime = CCVar( "vote_time", "30", "How long voting session goes on" );
	@g_pCCVar_VoteMapRatio = CCVar( "votemap_ratio", "0.60", "map ratio for voting success" );
	
	g_Hooks.RegisterHook( Hooks::Game::MapChange, @MapChange );
	
	load_settings( g_szMapsFile );
}

void MapStart()
{
	if ( g_mapNums == 0 )
		load_settings( g_szMapsFile );
	
	g_flVoting = 0;
}

CClientCommand g_mapmenu( "mapmenu", "- displays changelevel menu", @cmdMapsMenu );
CClientCommand g_votemapmenu( "votemapmenu", "- displays votemap menu", @cmdVoteMapMenu );
CClientCommand g_nextmapmenu( "nextmapmenu", "- displays nextmap menu", @cmdMapsMenu );

CConCommand mapsreload( "mapsreload", "Reload maps file", @ReloadMaps );

HookReturnCode MapChange( const string& in szNextMap )
{
	// set all menus to null. Apparently this fixes crashes for some people:
	// http://forums.svencoop.com/showthread.php/43310-Need-help-with-text-menu#post515087
	for ( int iPlayer = 1; iPlayer <= g_Engine.maxClients; iPlayer++ )
	{
		if ( g_MapsMenu[iPlayer] !is null )
			@g_MapsMenu[iPlayer] = null;

		g_voteSelected[iPlayer].resize( 0 );
	}
	
	if ( g_VoteMenu !is null )
		@g_VoteMenu = null;

	if ( g_VoteMapsMenu !is null )
		@g_VoteMapsMenu = null;
		
	g_Scheduler.ClearTimerList();

/*	if ( g_pDelayedChangeFunction !is null )
		@g_pDelayedChangeFunction = null;*/
	
	return HOOK_CONTINUE;
}

void autoRefuse()
{
	g_Game.AlertMessage( at_logged, "Vote: Result refused\n" );
	g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, "Result refused\n" );
}

void actionResult( CTextMenu@ menu, CBasePlayer@ pPlayer, int iSlot, const CTextMenuItem@ pItem )
{
	if ( pItem !is null && pPlayer !is null )
	{
		if ( g_pAutoRefuseFunction !is null && !g_pAutoRefuseFunction.HasBeenRemoved() )
			g_Scheduler.RemoveTimer( g_pAutoRefuseFunction );
		
		switch ( iSlot )
		{
			case 1:
			{
				string tempMap;
				pItem.m_pUserData.retrieve( tempMap );
				
				if ( tempMap.IsEmpty() || !g_EngineFuncs.IsMapValid( tempMap ) )
					return;

				// Set map in scoreboard too
				NetworkMessage msgNextMap( MSG_ALL, NetworkMessages::NextMap );
				msgNextMap.WriteString( tempMap );
				msgNextMap.End();

				NetworkMessage message( MSG_ALL, NetworkMessages::SVC_INTERMISSION );
				message.End();

				g_Scheduler.SetTimeout( "delayedChange", 2.0, tempMap );
				g_Game.AlertMessage( at_logged, "Vote: Result accepted\n" );
				g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, "Result accepted\n" );

				break;
			}
			case 2: autoRefuse(); break;
		}
	}

	if ( @menu !is null && menu.IsRegistered() )
	{
		//menu.Unregister();
		@menu = null;
	}
}

void checkVotes( int id )
{
	int a = 0;
	
	const int iLen = g_voteSelected[id].length();
	for ( int i = 0; i < iLen; i++ )
	{
		if ( g_voteCount[a] < g_voteCount[i] )
			a = i;
	}

	int votesNum = 0;
	for ( int b = 0; b < SELECT_MAX; b++ )
		votesNum += g_voteCount[b];

	int iRatio = votesNum > 0 ? int( ceil( g_pCCVar_VoteMapRatio.GetFloat() * float( votesNum ) ) ) : 1;
	int iResult = g_voteCount[a];
	
	string tempMap = "";

	if ( iResult >= iRatio )
	{
		tempMap = g_voteSelected[id][a];
		g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, "Voting successful. Map will be changed to " + tempMap + "\n" );
		g_Game.AlertMessage( at_logged, "Vote: Voting successful. Map will be changed to %1\n", tempMap );
	}
	
	if ( !tempMap.IsEmpty() && g_EngineFuncs.IsMapValid( tempMap ) )
	{
		CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( id );
	
		if ( pPlayer !is null && pPlayer.IsConnected() )
		{
			@g_MapsMenu[id] = CTextMenu( @actionResult );
			g_MapsMenu[id].SetTitle( "The winner: " + tempMap + "\nDo you want to continue?\n" );
			g_MapsMenu[id].AddItem( "Yes", any( tempMap ) );
			g_MapsMenu[id].AddItem( "No" );
			g_MapsMenu[id].Register();
			g_MapsMenu[id].Open( 15, 0, pPlayer );

			@g_pAutoRefuseFunction = g_Scheduler.SetTimeout( "autoRefuse", 15.1 );
		}
		else
		{
			// Set map in scoreboard too
			NetworkMessage msgNextMap( MSG_ALL, NetworkMessages::NextMap );
			msgNextMap.WriteString( tempMap );
			msgNextMap.End();

			NetworkMessage message( MSG_ALL, NetworkMessages::SVC_INTERMISSION );
			message.End();
			
			g_Scheduler.SetTimeout( "delayedChange", 2.0, tempMap );
		}
	}
	else
	{
		g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, "Voting failed\n" );
		g_Game.AlertMessage( at_logged, "Vote: Voting failed\n" );
	}
	
	if ( g_pCheckVotesFunction !is null && !g_pCheckVotesFunction.HasBeenRemoved() )
		g_Scheduler.RemoveTimer( g_pCheckVotesFunction );
}

void voteCount( CTextMenu@ menu, CBasePlayer@ pPlayer, int iSlot, const CTextMenuItem@ pItem )
{
	if ( pItem !is null && pPlayer !is null )
	{
		if ( pItem.m_pUserData !is null )
		{
			string szData;
			pItem.m_pUserData.retrieve( szData );

			if ( szData == "cancel" )
			{
				if ( g_VoteMenu !is null )
					@g_VoteMenu = null;

				if ( g_pCheckVotesFunction !is null && !g_pCheckVotesFunction.HasBeenRemoved() )
					g_Scheduler.RemoveTimer( g_pCheckVotesFunction );

				g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, "Voting has been canceled\n" );

				g_flVoting = g_Engine.time;
				g_Game.AlertMessage( at_logged, "Vote: Cancel vote session\n" );
			
				return;
			}
		}

		if ( g_pCCVar_VoteAnswers.GetBool() )
			g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, string( pPlayer.pev.netname ) + " voted for option " + pItem.m_szName + "\n" );

		g_voteCount[iSlot - 1]++;
	}

	if ( @menu !is null && menu.IsRegistered() )
	{
		//menu.Unregister();
		@menu = null;
	}
}

class MenuData
{
	string type;
	int page;
	bool removable;
}

void displayVoteMapsMenu( CBasePlayer@ pPlayer, int iPage = 0, const int iIndex = -1 )
{
	int iPlayer = pPlayer.entindex();

	@g_MapsMenu[iPlayer] = CTextMenu( @actionVoteMapMenu );

	const int iLen = g_voteSelected[iPlayer].length();
	if ( iLen > 0 )
	{
		string szTitle = "Selected Maps\n\n";
		for ( int a = 0; a < iLen; a++ )
		{
			szTitle += g_voteSelected[iPlayer][a] + "\n";
		}
		
		szTitle += "\nVotemap Menu ";
		g_MapsMenu[iPlayer].SetTitle( szTitle );
	}
	else
		g_MapsMenu[iPlayer].SetTitle( "Votemap Menu " );

	string tempMap;
	MenuData data;
	int iCountItems = 0, iPageMenu = 0;

	for ( int b = 0; b < g_mapNums; b++ )
	{
		tempMap = g_mapName[b];

		data.type = tempMap;
		data.page = iPageMenu;
		data.removable = false;

		if ( g_voteSelected[iPlayer].find( tempMap ) >= 0 )
		{
			tempMap += " <--";
			data.removable = true;
		}
		
		if ( b == iIndex )
			iPage = iPageMenu;

		g_MapsMenu[iPlayer].AddItem( tempMap, any( data ) );

		iCountItems++;

		if ( iLen > 0 && iCountItems % 6 == 0 )
		{
			data.type = "start";
			g_MapsMenu[iPlayer].AddItem( "Start Voting", any( data ) );
		}
		
		if ( g_MapsMenu[iPlayer].GetItemCount() % 7 == 0 )
			iPageMenu++;
	}
	
/*	int iPageCount = g_MapsMenu[iPlayer].GetPageCount() - 1;
	if ( iPageCount < iPage )
		iPage = iPageCount;*/

	g_MapsMenu[iPlayer].Register();
	g_MapsMenu[iPlayer].Open( 0, iPage, pPlayer );
}

void cmdVoteMapMenu( const CCommand@ args )
{
	CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();

	if ( pPlayer is null || !pPlayer.IsConnected() )
		return;

	if ( !IsPlayerAdmin( pPlayer ) )
	{
		g_EngineFuncs.ClientPrintf( pPlayer, print_console, "You have no access to this command.\n" );
		return;
	}

	if ( g_flVoting > g_Engine.time )
	{
		g_EngineFuncs.ClientPrintf( pPlayer, print_chat, "There is already one voting...\n" );
		return;
	}

	if ( g_mapNums > 0 )
		displayVoteMapsMenu( pPlayer );
	else
	{
		g_EngineFuncs.ClientPrintf( pPlayer, print_console, "There are no maps in menu\n" );
		//g_EngineFuncs.ClientPrintf( pPlayer, print_chat, "There are no maps in menu\n" );
	}
}

void cmdMapsMenu( const CCommand@ args )
{
	CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();

	if ( pPlayer is null || !pPlayer.IsConnected() )
		return;

	if ( !IsPlayerAdmin( pPlayer ) )
	{
		g_EngineFuncs.ClientPrintf( pPlayer, print_console, "You have no access to this command.\n" );
		return;
	}

	if ( g_mapNums > 0 )
	{
		if ( args.Arg( 0 ) == ".nextmapmenu" )
			displayMapsMenu( pPlayer, true );
		else
			displayMapsMenu( pPlayer );
	}
	else
	{
		g_EngineFuncs.ClientPrintf( pPlayer, print_console, "There are no maps in menu\n" );
		//g_EngineFuncs.ClientPrintf( pPlayer, print_chat, "There are no maps in menu\n" );
	}
}

void delayedChange( string& in mapname )
{
	g_EngineFuncs.ChangeLevel( mapname );
}

void actionVoteMapMenu( CTextMenu@ menu, CBasePlayer@ pPlayer, int iSlot, const CTextMenuItem@ pItem )
{
	if ( pItem !is null && pPlayer !is null )
	{
		MenuData data;
		pItem.m_pUserData.retrieve( data );
		int iPlayer = pPlayer.entindex();

		if ( data.type == "start" )
		{
			if ( g_flVoting > g_Engine.time )
			{
				g_EngineFuncs.ClientPrintf( pPlayer, print_chat, "There is already one voting...\n" );
				return;
			}

			if ( g_flVoting > 0 && g_flVoting + g_pCCVar_VoteDelay.GetFloat() > g_Engine.time )
			{
				g_EngineFuncs.ClientPrintf( pPlayer, print_chat, "Voting not allowed at this time\n" );
				return;
			}

			for ( int a = 0; a < SELECT_MAX; a++ )
				g_voteCount[a] = 0;
			
			float vote_time = g_pCCVar_VoteTime.GetFloat() + 2.0;
			g_flVoting = g_Engine.time + vote_time;
			int iVoteTime = FloatRound( vote_time );

			@g_pCheckVotesFunction = g_Scheduler.SetTimeout( "checkVotes", vote_time + 0.5, iPlayer );
			
			string tempMap;

			@g_VoteMenu = CTextMenu( @voteCount );
			
			const int iLen = g_voteSelected[iPlayer].length();

			if ( iLen > 1 )
			{
				g_VoteMenu.SetTitle( "Which map do you want?\n" );
				
				for ( int c = 0; c < iLen; c++ )
				{
					tempMap = g_voteSelected[iPlayer][c];
					g_VoteMenu.AddItem( tempMap );
				}
			}
			else
			{
				tempMap = g_voteSelected[iPlayer][0];
				g_VoteMenu.SetTitle( "Change map to " + tempMap + "?\n" );
				g_VoteMenu.AddItem( "Yes" );
				g_VoteMenu.AddItem( "No" );
			}

			@g_VoteMapsMenu = g_VoteMenu;
			g_VoteMenu.Register();

			array<edict_t@> pPlayers;
			
			CBasePlayer@ pTarget;

			for ( int iIndex = 1; iIndex <= g_PlayerFuncs.GetNumPlayers(); iIndex++ )
			{
				@pTarget = g_PlayerFuncs.FindPlayerByIndex( iIndex );

				if ( pTarget is null || !pTarget.IsConnected() )
					continue;

				if ( pTarget is pPlayer )
					continue;

				if ( ( pTarget.pev.flags & FL_FAKECLIENT ) != 0 )
					continue;
				
				pPlayers.insertLast( pTarget.edict() );
			}	

			g_VoteMenu.Open( iVoteTime, 0, pPlayers );

			g_VoteMapsMenu.AddItem( "Cancel Vote", any( "cancel" ) );

			g_VoteMapsMenu.Register();
			g_VoteMapsMenu.Open( iVoteTime, 0, pPlayer );

			ShowActivity( pPlayer, "vote map(s)" );

			string szTemp;

			if ( iLen > 0 )
				snprintf( szTemp, "(map#1 \"%1\")", g_voteSelected[iPlayer][0] );

			if ( iLen > 1 )
				snprintf( szTemp, "%1 (map#2 \"%2\")", szTemp, g_voteSelected[iPlayer][1] );

			if ( iLen > 2 )
				snprintf( szTemp, "%1 (map#3 \"%2\")", szTemp, g_voteSelected[iPlayer][2] );

			if ( iLen > 3 )
				snprintf( szTemp, "%1 (map#4 \"%2\")", szTemp, g_voteSelected[iPlayer][3] );

			string authid = g_EngineFuncs.GetPlayerAuthId( pPlayer.edict() );
			string name = pPlayer.pev.netname;
			
			g_Game.AlertMessage( at_logged, "Vote: \"%1<%2><%3>\" vote maps %4\n", 
					name, g_EngineFuncs.GetPlayerUserId( pPlayer.edict() ), authid, szTemp );
		}
		else
		{
			const int iLen = g_voteSelected[iPlayer].length();

			if ( data.removable )
			{
				uint uiIndex = g_voteSelected[iPlayer].find( data.type );
				if ( uiIndex >= 0 )
					g_voteSelected[iPlayer].removeAt( uiIndex );
			}
			else
			{
				if ( iLen < SELECT_MAX )
					g_voteSelected[iPlayer].insertLast( data.type );
				else
					g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "Vote list is full! You can remove map or start vote.\n" );
			}
			
			int iIndex = -1;
			if ( iLen <= 1 )
				iIndex = g_mapName.find( data.type );

			g_Scheduler.SetTimeout( "displayVoteMapsMenu", 0.01, @pPlayer, data.page, iIndex );
		}
	}

	if ( @menu !is null && menu.IsRegistered() )
	{
		//menu.Unregister();
		@menu = null;
	}
}

void actionMapsMenu( CTextMenu@ menu, CBasePlayer@ pPlayer, int iSlot, const CTextMenuItem@ pItem )
{
	if ( pItem !is null && pPlayer !is null )
	{
		string tempMap = pItem.m_szName;

		if ( g_EngineFuncs.IsMapValid( tempMap ) )
		{
			// Set map in scoreboard too
			NetworkMessage msgNextMap( MSG_ALL, NetworkMessages::NextMap );
			msgNextMap.WriteString( tempMap );
			msgNextMap.End();

			NetworkMessage message( MSG_ALL, NetworkMessages::SVC_INTERMISSION );
			message.End();
				
			string authid = g_EngineFuncs.GetPlayerAuthId( pPlayer.edict() );
			string name = pPlayer.pev.netname;
			
			ShowActivity( pPlayer, "changelevel " + tempMap + "\n" );

			g_Game.AlertMessage( at_logged, "Cmd: \"%1<%2><%3>\" changelevel \"%4\"\n", name, g_EngineFuncs.GetPlayerUserId( pPlayer.edict() ), authid, tempMap );
			g_Scheduler.SetTimeout( "delayedChange", 2.0, tempMap );
		}
	}

	if ( @menu !is null && menu.IsRegistered() )
	{
		//menu.Unregister();
		@menu = null;
	}
}

void actionNextMapMenu( CTextMenu@ menu, CBasePlayer@ pPlayer, int iSlot, const CTextMenuItem@ pItem )
{
	if ( pItem !is null && pPlayer !is null )
	{
		string tempMap = pItem.m_szName;

		if ( g_EngineFuncs.IsMapValid( tempMap ) )
		{
			g_EngineFuncs.ServerCommand( "mp_nextmap_cycle " + tempMap + "\n" );
			g_EngineFuncs.ServerExecute();

			// Set map in scoreboard too
			NetworkMessage msgNextMap( MSG_ALL, NetworkMessages::NextMap );
			msgNextMap.WriteString( tempMap );
			msgNextMap.End();

			string authid = g_EngineFuncs.GetPlayerAuthId( pPlayer.edict() );
			string name = pPlayer.pev.netname;
			
			ShowActivity( pPlayer, "set nextmap to " + tempMap + "\n" );

			g_Game.AlertMessage( at_logged, "Cmd: \"%1<%2><%3>\" set nextmap to \"%4\"\n", name, g_EngineFuncs.GetPlayerUserId( pPlayer.edict() ), authid, tempMap );
		}
	}

	if ( @menu !is null && menu.IsRegistered() )
	{
		//menu.Unregister();
		@menu = null;
	}
}

void displayMapsMenu( CBasePlayer@ pPlayer, const bool bNextMap = false )
{
	int iPlayer = pPlayer.entindex();

	if ( bNextMap )
	{
		@g_MapsMenu[iPlayer] = CTextMenu( @actionNextMapMenu );
		g_MapsMenu[iPlayer].SetTitle( "Nextmap Menu " );
	}
	else
	{
		@g_MapsMenu[iPlayer] = CTextMenu( @actionMapsMenu );
		g_MapsMenu[iPlayer].SetTitle( "Changelevel Menu " );
	}

	for ( int i = 0; i < g_mapNums; i++ )
		g_MapsMenu[iPlayer].AddItem( g_mapName[i] );

	g_MapsMenu[iPlayer].Register();
	g_MapsMenu[iPlayer].Open( 0, 0, pPlayer );
}
/*
bool ValidMap( string& in mapname, string &out map )
{
	if ( g_EngineFuncs.IsMapValid( mapname ) )
	{
		map = mapname;
		return true;
	}

	// If the is_map_valid check failed, check the end of the string
	int len = mapname.Length() - 4;
	
	// The mapname was too short to possibly house the .bsp extension
	if ( len <= 0 )
		return false;

	if ( mapname.EndsWith( ".bsp", String::CaseSensitive ) )
	{
		// If the ending was .bsp, then cut it off.
		// the string is byref'ed, so this copies back to the loaded text.
		mapname.Truncate( len );
		
		// recheck
		if ( g_EngineFuncs.IsMapValid( mapname ) )
		{
			map = mapname;
			return true;
		}
	}
	
	return false;
}
*/
void load_settings( string& in filename )
{
	File@ pFile = g_FileSystem.OpenFile( filename, OpenFile::READ );

	if ( pFile !is null && pFile.IsOpen() )
	{
		string line;
		while ( !pFile.EOFReached() )
		{
			pFile.ReadLine( line );
			line.Trim();

/*			line.Trim( '\r' );	
			if ( line == '\r' )
				continue;*/

			if ( line.IsEmpty() )
				continue;

			if ( line[0] == '/' && line[1] == '/' )
				continue;

			if ( line[0] == ';' )
				continue;

			if ( !g_EngineFuncs.IsMapValid( line ) )
			{
				g_EngineFuncs.ServerPrint( "Map " + line + "not valid\n" );
				continue;
			}

			g_mapName.insertLast( line );
		}
		
		pFile.Close();

		g_mapNums = g_mapName.length();
	}
	else
	{
		g_mapName = g_MapCycle.GetMapCycle();
		g_mapNums = g_mapName.length();
	}
	
	g_EngineFuncs.ServerPrint( "MapsMenu loaded " + g_mapNums + " maps\n" );
}

void ReloadMaps( const CCommand@ args )
{
	if ( g_mapName.length() > 0 )
		g_mapName.resize( 0 );
	
	if ( g_mapNums > 0 )
		g_mapNums = 0;
	
	load_settings( g_szMapsFile );
}

void ShowActivity( CBasePlayer@ pPlayer, const string& in szMessage )
{
	CBasePlayer@ pTarget;

	for ( int iIndex = 1; iIndex <= g_PlayerFuncs.GetNumPlayers(); iIndex++ )
	{
		@pTarget = g_PlayerFuncs.FindPlayerByIndex( iIndex );
		
		if ( pTarget is null || !pTarget.IsConnected() )
			continue;
		
		if ( IsPlayerAdmin( pTarget ) )
			g_PlayerFuncs.ClientPrint( pTarget, HUD_PRINTTALK, "ADMIN " + pPlayer.pev.netname + ": " + szMessage );
		else
			g_PlayerFuncs.ClientPrint( pTarget, HUD_PRINTTALK, "ADMIN: " + szMessage );
	}
}

bool IsPlayerAdmin( CBasePlayer@ pPlayer )
{
	return g_PlayerFuncs.AdminLevel( pPlayer ) >= ADMIN_YES;
}

int FloatRound( float fA )
{
	return int( floor( fA + 0.5 ) );
}
