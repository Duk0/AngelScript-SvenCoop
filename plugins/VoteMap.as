const float CMD_WAIT_TIME = 2.0;
float g_flCmdWaitTime = 0.0;

array<string> g_pMapVoteList;
int g_iMapNums;
bool g_bCancelled = false;

array<CTextMenu@> g_VoteMapMenu( g_Engine.maxClients + 1, null );

const string g_szMapsFile = "scripts/plugins/Configs/maps.ini";

const Cvar@ g_pCvarVoteAllow, g_pCvarVoteTimeCheck, g_pCvarVoteMapRequired;

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Duko" );
	g_Module.ScriptInfo.SetContactInfo( "group.midu.cz" );
	
	g_Hooks.RegisterHook( Hooks::Game::MapChange, @MapChange );
	g_Hooks.RegisterHook( Hooks::Player::ClientSay, @ClientSay );

	@g_pCvarVoteAllow = g_EngineFuncs.CVarGetPointer( "mp_voteallow" );
	@g_pCvarVoteTimeCheck = g_EngineFuncs.CVarGetPointer( "mp_votetimecheck" );
	@g_pCvarVoteMapRequired = g_EngineFuncs.CVarGetPointer( "mp_votemaprequired" );
	
	load_settings( g_szMapsFile );
}

void MapStart()
{
	if ( g_iMapNums == 0 )
		load_settings( g_szMapsFile );
		
	g_flCmdWaitTime = g_Engine.time;
	
	g_bCancelled = false;
}

//CClientCommand g_votemapmenu( "vote", "- displays votemap menu", @cmdVoteMapMenu );
CClientCommand g_cancelvotemap( "cancelvotemap", "- cancels map vote", @cmdCancelVoteMap );
//CClientCommand g_votemap( "mapvote", "- map vote", @cmdVoteMap );

HookReturnCode MapChange()
{
	for ( int iPlayer = 1; iPlayer <= g_Engine.maxClients; ++iPlayer )
	{
		if ( g_VoteMapMenu[iPlayer] !is null )
			@g_VoteMapMenu[iPlayer] = null;
	}
	
	g_Scheduler.ClearTimerList();
	
	return HOOK_CONTINUE;
}

HookReturnCode ClientSay( SayParameters@ pParams )
{
	const CCommand@ pArguments = pParams.GetArguments();

	if ( pArguments.ArgC() >= 1 )
	{
		string szArg = pArguments.Arg( 0 );
		szArg.Trim();
		if ( szArg.ICompare( "votemap" ) == 0 || szArg.ICompare( "!votemap" ) == 0 )
		{
			CBasePlayer@ pPlayer = pParams.GetPlayer();

			if ( pPlayer is null || !pPlayer.IsConnected() )
				return HOOK_CONTINUE;

			if ( g_pCvarVoteAllow.value == 0 )
			{
				g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCENTER, "Voting not allowed on server.\n" );
				return HOOK_CONTINUE;
			}

			if ( g_pCvarVoteMapRequired.value < 0 )
			{
				g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCENTER, "This type of vote is disabled.\n" );
				return HOOK_CONTINUE;
			}

			if ( g_iMapNums <= 0 )
			{
				g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "There are no maps in menu\n" );
				return HOOK_CONTINUE;
			}

			string szArg2 = pArguments.Arg( 1 );
			szArg2.Trim();
			
			if ( szArg2.IsEmpty() )
				displayVoteMapMenu( pPlayer );
			else
				ForceVoteMap( pPlayer, szArg2 );
		}
	}
	return HOOK_CONTINUE;
}
/*
void cmdVoteMapMenu( const CCommand@ args )
{
	CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();

	if ( pPlayer is null || !pPlayer.IsConnected() )
		return;

	if ( g_iMapNums <= 0 )
	{
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "There are no maps in menu\n" );
		return;
	}

	displayVoteMapMenu( pPlayer );
}
*/

void cmdCancelVoteMap( const CCommand@ args )
{
	CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();

	if ( pPlayer is null || !pPlayer.IsConnected() )
		return;

	if ( !IsPlayerAdmin( pPlayer ) )
	{
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "[AS] You have no access to that command\n" );
		return;
	}
	
	g_bCancelled = true;
	g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "Map vote will be cancelled.\n" );
}

void delayedChange( string& in mapname )
{
	if ( !g_EngineFuncs.IsMapValid( mapname ) )
		return;

	g_EngineFuncs.ChangeLevel( mapname );
}

void actionMapsMenu( CTextMenu@ menu, CBasePlayer@ pPlayer, int iSlot, const CTextMenuItem@ pItem )
{
	if ( pItem !is null && pPlayer !is null )
	{
		if ( g_pCvarVoteAllow.value == 0 || g_pCvarVoteMapRequired.value < 0 )
			return;

		string szMap = pItem.m_szName;

		if ( g_EngineFuncs.IsMapValid( szMap ) )
			StartVoteMap( pPlayer, szMap );
	}

/*	if ( @menu !is null && menu.IsRegistered() )
	{
		//menu.Unregister();
		@menu = null;
	}*/
}

void displayVoteMapMenu( CBasePlayer@ pPlayer )
{
	int iPlayer = pPlayer.entindex();

	@g_VoteMapMenu[iPlayer] = CTextMenu( @actionMapsMenu );
	g_VoteMapMenu[iPlayer].SetTitle( "Votemap Menu " );

	for ( int i = 0; i < g_iMapNums; ++i )
		g_VoteMapMenu[iPlayer].AddItem( g_pMapVoteList[i] );

	g_VoteMapMenu[iPlayer].Register();
	g_VoteMapMenu[iPlayer].Open( 0, 0, pPlayer );
}

void ForceVoteMap( CBasePlayer@ pPlayer, string &in szMap )
{
	if ( g_Engine.time - g_flCmdWaitTime < CMD_WAIT_TIME )
		return;
			
	g_flCmdWaitTime = g_Engine.time;

	bool bFound = false;

	for ( uint n = 0; n < g_pMapVoteList.length(); n++ )
	{
		if ( szMap.ICompare( g_pMapVoteList[n] ) != 0 )
			continue;

		szMap = g_pMapVoteList[n];
		bFound = true;
		break;
	}

	//if ( g_pMapVoteList.find( szMap ) < 0 )
	if ( !bFound )
	{
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "[VoteMap] Map [" + szMap + "] not found.\n" );
		return;
	}

	StartVoteMap( pPlayer, szMap );
}

void StartVoteMap( CBasePlayer@ pPlayer, string &in szMap )
{
	if ( g_Utility.VoteActive() )
	{
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCENTER, "Can't start vote. Other vote in progress.\n" );
		return;
	}
	
	if ( g_bCancelled )
		g_bCancelled = false;

	float flVoteTime = g_pCvarVoteTimeCheck.value;
	
	if ( flVoteTime <= 0 )
		flVoteTime = 16;
		
	float flPercentage = g_pCvarVoteMapRequired.value;
	
	if ( flPercentage <= 0 )
		flPercentage = 51;
	
	Vote vote( "Map vote", "Would you like to change map to \"" + szMap + "\"?", flVoteTime, flPercentage );
	
	vote.SetUserData( any( szMap ) );
	vote.SetVoteBlockedCallback( @VoteMapBlocked );
	vote.SetVoteEndCallback( @VoteMapEnd );
	
	vote.Start();

	string szName = pPlayer.pev.netname;
	string szAuthid = g_EngineFuncs.GetPlayerAuthId( pPlayer.edict() );

	g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, "> Map vote for [" + szMap + "] started by " + szName + "\n" );

	g_Game.AlertMessage( at_logged, "VoteMap: \"%1<%2><%3>\" started vote map to \"%4\"\n", szName, g_EngineFuncs.GetPlayerUserId( pPlayer.edict() ), szAuthid, szMap );
}

void VoteMapBlocked( Vote@ pVote, float flTime )
{
	//Try again later
	g_Scheduler.SetTimeout( "StartVoteMap", flTime );
}

void VoteMapEnd( Vote@ pVote, bool bResult, int iVoters )
{
	string szMap;
	pVote.GetUserData().retrieve( szMap );

	if ( !bResult || g_bCancelled || g_pCvarVoteAllow.value == 0 || g_pCvarVoteMapRequired.value < 0 )
	{
		g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, "Vote for map [" + szMap + "] failed\n" );
		return;
	}
	
	g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, "Vote for map [" + szMap + "] passed\n" ); // Vote-MapChange to "%s" Now
	
	g_Scheduler.SetTimeout( "delayedChange", 2.0, szMap );

	NetworkMessage message( MSG_ALL, NetworkMessages::NetworkMessageType( 9 ) );
	message.WriteString( "spk buttons/bell1" ); // tfc/misc/endgame, ambience/warn2
	message.End();
}
/*
bool ValidMap( string &in mapname, string &out map )
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
				continue;

			g_pMapVoteList.insertLast( line );
		}
		
		pFile.Close();

		g_iMapNums = g_pMapVoteList.length();
	}
	else
	{
		g_pMapVoteList = g_MapCycle.GetMapCycle();
		g_iMapNums = g_pMapVoteList.length();
	}
	
	g_EngineFuncs.ServerPrint( "VoteMap loaded " + g_iMapNums + " maps\n" );
}

bool IsPlayerAdmin( CBasePlayer@ pPlayer )
{
	return g_PlayerFuncs.AdminLevel( pPlayer ) >= ADMIN_YES;
}

