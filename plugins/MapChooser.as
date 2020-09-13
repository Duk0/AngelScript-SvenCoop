//
// Idea from AMX Mod X, based on AMX Mod by Aleksander Naszko ("OLO").
//
//
// Nextmap Chooser Plugin
// Port for Sven Co-op Angelscript
//

const int SELECTMAPS = 6; // 6 is maximum if we don't want pages
const int VOTETIME = 30; // in seconds

CCVar@ g_pCCVar_ExtendMapMax, g_pCCVar_ExtendMapStep, g_pCCVar_VoteAnswers, g_pCCVar_IgnoreEmpty;
CCVar@ g_pCCVar_VoteDelay, g_pCCVar_Rtv, g_pCCVar_RtvPercent, g_pCCVar_RtvMinTime, g_pCCVar_RtvMapTime;
const Cvar@ g_pCvarTimeLimit, g_pCvarTimeLeft;
const Cvar@ g_pCvarVoteAllow, g_pCvarVoteMapRequired;

CTextMenu@ g_VoteMenu;

array<string> g_pMapName;
array<string> g_pMapList;
array<string> g_pMapHistory;
array<int> g_pNextName( SELECTMAPS, 0 );
array<int> g_pVoteCount( SELECTMAPS + 2, 0 );

int g_iMapNums = 0;
int g_iMapVoteNum = 0;
int g_iExtendTime = 0;

string g_szCurrentMap;
//string g_szLastMap;

bool g_bSelected = false;

bool g_bIsPlayerConnected = false;
bool g_bMapHistoryLoaded = false;
const string g_szMapHistoryFile = "scripts/plugins/store/maphistory.ini";
string g_szModuleName;

CScheduledFunction@ g_pVoteNextMapFunction = null;

bool g_bCallSayVote = false;
bool g_bVoteFinished = false;
bool g_bForceVote = false;

bool g_bInProgress = false;
bool g_bHasBeenRocked = false;
bool g_bRockTheVote = false;

bool g_bNextMapByCmd = false;

int g_iRocks = 0;
array<bool> g_pRocked( g_Engine.maxClients + 1, false );

float g_flVoting = 0;

// ClientCommand
CClientCommand setnextmap( "setnextmap", "<mapname>", @SetNextMap, ConCommandFlag::AdminOnly ); // set nextmap
CClientCommand maphistory( "maphistory", "show played map list", @ShowMapHistory );	// show g_pMapHistory to client console 


void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Duko" );
	g_Module.ScriptInfo.SetContactInfo( "group.midu.cz" );

	@g_pCCVar_ExtendMapMax = CCVar( "extendmap_max", 120, "Max. time to which map can be extended in minutes", ConCommandFlag::AdminOnly );
	@g_pCCVar_ExtendMapStep = CCVar( "extendmap_step", 30, "Step for each extending in minutes", ConCommandFlag::AdminOnly );
	@g_pCCVar_VoteAnswers = CCVar( "vote_answers", 1, "Display who votes for what option, set to 0 to disable, 1 to enable.", ConCommandFlag::AdminOnly );
	@g_pCCVar_IgnoreEmpty = CCVar( "ignoreempty", 1, "Ignore adding list when server is empty. [0=disabled, 1=enabled]", ConCommandFlag::AdminOnly );

	@g_pCCVar_VoteDelay = CCVar( "vote_delay", 60, "Vote Delay in secs.", ConCommandFlag::AdminOnly );
	@g_pCCVar_Rtv = CCVar( "rtv", 1, "0 - disables rockthevote option", ConCommandFlag::AdminOnly );
	@g_pCCVar_RtvPercent = CCVar( "rtv_percent", 0.6, "rockthevote ratio (%/100 human-players they need to say rockthevote to start voting for the next map.", ConCommandFlag::AdminOnly );
	@g_pCCVar_RtvMinTime = CCVar( "rtv_min_time", 3, "minimum time (in minutes) required to play the map before players can use rockthevote feature.", ConCommandFlag::AdminOnly );
	@g_pCCVar_RtvMapTime = CCVar( "rtv_map_time", 10, "time after successful rtv then voting for the new map, the map will change to the new one (instead waiting until game end)", ConCommandFlag::AdminOnly );
	
	@g_pCvarTimeLimit = g_EngineFuncs.CVarGetPointer( "mp_timelimit" );
	@g_pCvarTimeLeft = g_EngineFuncs.CVarGetPointer( "mp_timeleft" );
	@g_pCvarVoteAllow = g_EngineFuncs.CVarGetPointer( "mp_voteallow" );
	@g_pCvarVoteMapRequired = g_EngineFuncs.CVarGetPointer( "mp_votemaprequired" );

	g_Hooks.RegisterHook( Hooks::Player::ClientPutInServer, @ClientPutInServer );
	g_Hooks.RegisterHook( Hooks::Player::ClientDisconnect, @ClientDisconnect );
	g_Hooks.RegisterHook( Hooks::Player::ClientSay, @ClientSay );
	g_Hooks.RegisterHook( Hooks::Game::MapChange, @MapChange );
	
	g_szModuleName = "[" + g_Module.GetModuleName() + "] ";
	
	//ReloadMapHistory();
	
	//g_EngineFuncs.ServerPrint( g_szModuleName + "g_pMapName.length() = " + g_pMapName.length() + ", g_pMapList.length() = " + g_pMapList.length() + ", g_pMapHistory.length() = " + g_pMapHistory.length() + "\n" );
}

void CmdArraysLenght( const CCommand@ args )
{
	g_EngineFuncs.ServerPrint( g_szModuleName + "g_pMapName.length() = " + g_pMapName.length() + ", g_pMapList.length() = " + g_pMapList.length() + ", g_pMapHistory.length() = " + g_pMapHistory.length() + "\n" );
}

CConCommand arrayslenght( "arrayslenght", "Test", @CmdArraysLenght ); //as_command .arrayslenght

void MapStart()
{
	g_szCurrentMap = g_Engine.mapname;
	g_iMapVoteNum = 0;
	g_iExtendTime = 0;
	g_bSelected = false;
	
	g_bForceVote = false;
	g_iRocks = 0;
	g_bInProgress = false;
	g_bHasBeenRocked = false;
	g_bRockTheVote = false;
	g_flVoting = 0;
	g_bNextMapByCmd = false;

	if ( g_pMapName.length() == 0 )
		ReloadMapHistory();
	
	g_iMapNums = g_pMapName.length();

	g_bIsPlayerConnected = false;
	
	string szOld = g_MapCycle.GetNextMap();
	execRandomNextMap( szOld );	
	string szNew = g_MapCycle.GetNextMap();
	
	if ( szOld != szNew )
		g_EngineFuncs.ServerPrint( g_szModuleName + "Nextmap changed: " + szOld + "->" + szNew + "\n" );
	

	g_Scheduler.SetInterval( "voteNextmap", 15.0 );
}

HookReturnCode ClientPutInServer( CBasePlayer@ pPlayer )
{
	if ( pPlayer is null )
		return HOOK_CONTINUE;
		
	if ( pPlayer.pev.flags & FL_FAKECLIENT != 0 )
		return HOOK_CONTINUE;
		
	g_bIsPlayerConnected = true;

	int iPlayer = pPlayer.entindex();
	g_pRocked[iPlayer] = false;

	return HOOK_CONTINUE;
}

HookReturnCode ClientDisconnect( CBasePlayer@ pPlayer )
{
	if ( pPlayer is null )
		return HOOK_CONTINUE;

	if ( pPlayer.pev.flags & FL_FAKECLIENT != 0 )
		return HOOK_CONTINUE;

	int iPlayer = pPlayer.entindex();

	if ( g_pRocked[iPlayer] )
	{
		g_pRocked[iPlayer] = false;
		g_iRocks--;
	}

	return HOOK_CONTINUE;
}

HookReturnCode ClientSay( SayParameters@ pParams )
{
	const CCommand@ pArguments = pParams.GetArguments();

	if ( pArguments.ArgC() >= 1 )
	{
		string szArg = pArguments.Arg( 0 );
		szArg.Trim();

		CBasePlayer@ pPlayer = pParams.GetPlayer();

		if ( pPlayer is null || !pPlayer.IsConnected() )
			return HOOK_CONTINUE;

		if ( szArg.ICompare( "votenext" ) == 0 && IsPlayerAdmin( pPlayer ) )
		{
			if ( g_iMapNums <= 0 )
			{
				g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "There are no maps in menu\n" );
				return HOOK_CONTINUE;
			}

			float voting = g_flVoting + VOTETIME;

			if ( voting > g_Engine.time )
			{
				g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "There is already one voting...\n" );
				return HOOK_CONTINUE;
			}

			if ( voting > 0 && ( voting + g_pCCVar_VoteDelay.GetFloat() > g_Engine.time ) )
			{
				g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "You cannot start the vote for the next map now.\n" );
				return HOOK_CONTINUE;
			}

			float vote_time = VOTETIME + 2.0;
			g_flVoting = g_Engine.time + vote_time;
			
			g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "Voting is started. Wait a moment...\n" );
			g_bCallSayVote = true;
			@g_pVoteNextMapFunction = g_Scheduler.SetTimeout( "voteNextmap", 5.0 );

			return HOOK_CONTINUE;
		}
		else if ( szArg.ICompare( "rockthevote" ) == 0 || szArg.ICompare( "rtv" ) == 0 )
		{
			float voting = g_flVoting + VOTETIME;

			if ( voting > 0 && ( voting + g_pCCVar_VoteDelay.GetFloat() > g_Engine.time ) )
			{
				g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "You cannot start the vote for the next map now.\n" );

			//	g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "You need to wait " + g_pCCVar_VoteDelay.GetFloat() + " time.\n" );

				return HOOK_CONTINUE;
			}

			RockTheVote( pPlayer );

			return HOOK_CONTINUE;
		}
	}

	return HOOK_CONTINUE;
}

HookReturnCode MapChange()
{
	if ( g_VoteMenu !is null )
		@g_VoteMenu = null;

	if ( !g_szCurrentMap.IsEmpty() )
		updateHistoryList( g_szCurrentMap );

	g_Scheduler.ClearTimerList();
	
	return HOOK_CONTINUE;
}

void ReloadMapHistory()
{
	g_pMapName = g_pMapList = g_MapCycle.GetMapCycle(); // TODO: if needed, load maps from maps.ini file

	if ( !LoadMaps() || g_pMapList.length() == 0 )
		return;

	int iLen = g_pMapHistory.length();
	if ( g_pMapList.length() <= uint( iLen ) )
	{
		g_FileSystem.RemoveFile( g_szMapHistoryFile );
		g_pMapHistory.resize( 0 );
		g_Log.PrintF( g_szModuleName + "removed file " + g_szMapHistoryFile + "\n" );
	}
	else
	{
		//Bla( iLen );

		int iFound;
		for ( int i = 0; i < iLen; i++ )
		{
			if ( g_pMapName.length() == 0 )
				break;

			iFound = g_pMapName.find( g_pMapHistory[i] );
			if ( iFound < 0 )
				continue;

			g_pMapName.removeAt( iFound );
		}
	}

	g_EngineFuncs.ServerPrint( g_szModuleName + "g_pMapName.length() = " + g_pMapName.length() + ", g_pMapList.length() = " + g_pMapList.length() + ", g_pMapHistory.length() = " + g_pMapHistory.length() + "\n" );
}
/*
void Bla( int iLen, int iStart = 0 )
{
	int iFound;
	int iMapsRead = 0;
	for ( int i = iStart; i < iLen; i++ )
	{
		if ( g_pMapName.length() == 0 )
			break;

		if ( iMapsRead++ > 16 )
		{
			g_Scheduler.SetTimeout( "Bla", 0, iLen, i );
			return;
		}

		iFound = g_pMapName.find( g_pMapHistory[i] );
		if ( iFound < 0 )
			continue;

		g_pMapName.removeAt( iFound );
	}
	
	g_EngineFuncs.ServerPrint( g_szModuleName + "g_pMapName.length() = " + g_pMapName.length() + ", g_pMapList.length() = " + g_pMapList.length() + ", g_pMapHistory.length() = " + g_pMapHistory.length() + "\n" );
}
*/
void checkVotes()
{
	int b = 0;
	
	for ( int a = 0; a < g_iMapVoteNum; a++ )
	{
		if ( g_pVoteCount[b] < g_pVoteCount[a] )
			b = a;
	}

	if ( g_pVoteCount[SELECTMAPS] > g_pVoteCount[b] && g_pVoteCount[SELECTMAPS] > g_pVoteCount[SELECTMAPS + 1] )
	{
		int steptime = g_pCCVar_ExtendMapStep.GetInt();
		g_EngineFuncs.CVarSetFloat( "mp_timelimit", g_pCvarTimeLimit.value + steptime );
		g_iExtendTime += steptime;
		g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, "Choosing finished. Current map will be extended to next " + steptime + " minutes\n" );
		g_Game.AlertMessage( at_logged, "Vote: Voting for the nextmap finished. Map %1 will be extended to next %2 minutes\n", g_szCurrentMap, steptime ); // %s1 print to console :) WARNING: Angelscript: ASSPrintf: format parameter index is out of range!
		
		g_Scheduler.SetTimeout( "updateScoreboardTimeLeft", 0.1 ); // just wait a bit for update mp_timeleft cvar
		
		g_bInProgress = false;
		return;
	}
	
	string szMap;
	if ( g_pVoteCount[b] > 0 && g_pVoteCount[SELECTMAPS + 1] <= g_pVoteCount[b] )
	{
		g_Log.PrintF( g_szModuleName + "b: " + b + ", g_pNextName[b]: " + g_pNextName[b] + ", g_pVoteCount[b]: " + g_pVoteCount[b] + "\n" );

		if ( b > SELECTMAPS )
			g_Log.PrintF( g_szModuleName + "ERROR! b > SELECTMAPS\n" );
		else
		{
			szMap = g_pMapName[g_pNextName[b]];

			ChangeNextMap( szMap );
		}
	}
	
	if ( szMap.IsEmpty() )
		szMap = g_MapCycle.GetNextMap();

	if ( !g_pCCVar_Rtv.GetBool() || g_pCvarVoteAllow.value == 0 || g_pCvarVoteMapRequired.value < 0 )
	{
		g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, "Force change map failed.\n" );
		return;
	}

	if ( g_bForceVote ) 
	{
		float flMapChangeTime = Math.clamp( 5.0, 60.0, g_pCCVar_RtvMapTime.GetFloat() );

		g_Scheduler.SetTimeout( "DelayedMapChange", flMapChangeTime, szMap );
	}

	g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, "Choosing finished. The nextmap will be " + szMap + "\n" );
	g_Game.AlertMessage( at_logged, "Vote: Voting for the nextmap finished. The nextmap will be %1\n", szMap );

	g_bVoteFinished = true;
	g_bInProgress = false;
	g_bForceVote = false;
}

void updateScoreboardTimeLeft()
{
	// change time left in scoreboard immediately
	NetworkMessage message( MSG_ALL, NetworkMessages::TimeEnd );
	message.WriteLong( int( g_pCvarTimeLeft.value ) );
	message.End();
}

void PerformChangeLevel( string& in szMapName )
{
	g_EngineFuncs.ChangeLevel( szMapName );
}

void DelayedMapChange( string& in szMapName )
{
	NetworkMessage message( MSG_ALL, NetworkMessages::SVC_INTERMISSION );
	message.End();

	g_Scheduler.SetTimeout( "PerformChangeLevel", 3.0, szMapName );
}

void countVoteCallback( CTextMenu@ menu, CBasePlayer@ pPlayer, int iSlot, const CTextMenuItem@ pItem )
{
	// iSlot = 1-10, key 0 is 10
	if ( pItem !is null && pPlayer !is null )
	{
		if ( g_pCCVar_VoteAnswers.GetBool() && !g_bVoteFinished )
		{			
			if ( iSlot == SELECTMAPS + 1 )
				g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, string( pPlayer.pev.netname ) + " chose map extending\n" );
			else if ( iSlot < SELECTMAPS + 1 )
				g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, string( pPlayer.pev.netname ) + " chose " + g_pMapName[g_pNextName[iSlot - 1]] + "\n" ); // pItem.szName
		}

		g_pVoteCount[iSlot - 1]++;
	}

	if ( pItem is null )
		g_pVoteCount[SELECTMAPS + 1]++; // used Exit key as "None" - nothing

	if ( @menu !is null && menu.IsRegistered() )
	{
		@menu = null;
	}
}

bool isInMenu( int id )
{
	for ( int a = 0; a < g_iMapVoteNum; a++ )
	{
		if ( id == g_pNextName[a] )
			return true;
	}

	return false;
}

void voteNextmap()
{
	if ( g_bNextMapByCmd && !g_bCallSayVote && !g_bRockTheVote )
		return;

	float timeleft = g_pCvarTimeLeft.value;
		
	if ( ( timeleft < 1 || timeleft > 129 ) && !g_bCallSayVote && !g_bInProgress )
	{
		g_bSelected = false;
		return;
	}

	if ( g_bSelected && !g_bCallSayVote && !g_bRockTheVote )
		return;

	g_bSelected = true;
	g_bVoteFinished = false;

	@g_VoteMenu = CTextMenu( @countVoteCallback );
	g_VoteMenu.SetTitle( "Choose nextmap\n" );

	int a = 0;
	int dmax = ( g_iMapNums > SELECTMAPS ) ? SELECTMAPS : g_iMapNums;
	string mapname;

/*	if ( dmax < SELECTMAPS )
	{
		g_Game.AlertMessage( at_warning, "MapChooser vote can't start. Found only %1 map(s), minimum %2 are required\n", dmax, SELECTMAPS );
		return;
	}*/

	if ( dmax <= 0 )
	{
		g_Game.AlertMessage( at_warning, g_szModuleName + "Vote can't start. Maps not found, minimum 1 is required\n" );
		return;
	}
	
	for ( g_iMapVoteNum = 0; g_iMapVoteNum < dmax; g_iMapVoteNum++ )
	{
		a = Math.RandomLong( 0, g_iMapNums - 1 );
			
		while ( isInMenu( a ) )
		{
			if ( ++a >= g_iMapNums )
				a = 0;
		}

		mapname = g_pMapName[a];
		
		if ( mapname.ICompare( g_szCurrentMap ) == 0 )
			continue;
		
		g_pNextName[g_iMapVoteNum] = a;

		if ( g_iMapVoteNum == dmax - 1 )
			mapname += "\n";
		
		g_VoteMenu.AddItem( mapname );

		g_pVoteCount[g_iMapVoteNum] = 0;
	}
	
	g_pVoteCount[SELECTMAPS] = 0;
	g_pVoteCount[SELECTMAPS + 1] = 0;

	if ( g_iExtendTime < g_pCCVar_ExtendMapMax.GetInt() && !g_bCallSayVote && !g_bRockTheVote )
		g_VoteMenu.AddItem( "Extend current map " + g_szCurrentMap + "\n\nExit - keep current next map" );

	//g_VoteMenu.AddItem( "None" ); // used Exit key instead
	g_VoteMenu.Register();
	g_VoteMenu.Open( VOTETIME, 0 ); // open menu for all

	g_Scheduler.SetTimeout( "checkVotes", float( VOTETIME ) + 0.5 );
	if ( !g_bCallSayVote && !g_bRockTheVote )
		g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, "It's time to choose the nextmap...\n" );

	//g_SoundSystem.PlaySound( g_EntityFuncs.Instance( 0 ).edict(), CHAN_STATIC, "gman/gman_choose2.wav", VOL_NORM, ATTN_NONE );
	NetworkMessage message( MSG_ALL, NetworkMessages::SVC_STUFFTEXT );
	message.WriteString( "spk gman/gman_choose2" );
	message.End();

	g_bCallSayVote = false;

	if ( g_bHasBeenRocked && g_bRockTheVote )
		g_bRockTheVote = false;


	g_Game.AlertMessage( at_logged, "Vote: Voting for the nextmap started\n" );

	if ( TaskExist( g_pVoteNextMapFunction ) )
		g_Scheduler.RemoveTimer( g_pVoteNextMapFunction );
		
}

void ChangeNextMap( string &in szMap )
{
	//g_EngineFuncs.CVarSetString( "mp_nextmap_cycle", szMap ); // sometimes don't work idk why
	g_EngineFuncs.ServerCommand( "mp_nextmap_cycle " + szMap + "\n" );
	g_EngineFuncs.ServerExecute();

	// Set map in scoreboard too
	NetworkMessage message( MSG_ALL, NetworkMessages::NextMap );
	message.WriteString( szMap );
	message.End();
}

void execRandomNextMap( string &in szMapName )
{
	// Check mapcycle num. (first map with cfg overwrote, then return 0 too.)
	if ( g_MapCycle.Count() <= 0 )
		return;
	
	// Nextmap is not in mapcycle, no change return.
	if ( g_pMapList.find( szMapName ) < 0 )
		return;

	if ( g_pMapName.length() == 0 )
		return;

	if ( int( szMapName.Find( "_lobby", 0, String::CaseInsensitive ) ) != -1 )
		return;
	
	// Random choose
	uint target = Math.RandomLong( 0, g_pMapName.length() - 1 );
	
	if ( g_pMapName.length() == 1 && g_pMapName[target] == g_szCurrentMap )
		return;

	while ( g_pMapName[target] == g_szCurrentMap || !g_EngineFuncs.IsMapValid( g_pMapName[target] ) )
		target = Math.RandomLong( 0, g_pMapName.length() - 1 );
	
	// Execute ServerCommand
	g_EngineFuncs.ServerCommand( "mp_nextmap_cycle " + g_pMapName[target] + "\n" );
	g_EngineFuncs.ServerExecute();
}

/** Update past maps */
void updateHistoryList( string &in szMapName )
{
	if ( g_pCCVar_IgnoreEmpty.GetBool() && !g_bIsPlayerConnected )
		return;
		
	if ( !g_EngineFuncs.IsMapValid( szMapName ) )
		return;

	// if szMapName is not included g_pMapList, return
	if ( g_pMapList.find( szMapName ) < 0 )
		return;

	// if szMapName replayed, return
	if ( g_pMapHistory.find( szMapName ) >= 0 )
		return;

	int iFound = g_pMapName.find( szMapName );

	if ( iFound >= 0 )
	{
		g_pMapName.removeAt( iFound );
		--g_iMapNums;
	}

//	g_szLastMap = szMapName;

	// Add past map
	g_pMapHistory.insertLast( szMapName );

	SaveMap( szMapName );
}

void SetNextMap( const CCommand@ args )
{
	CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();

	if ( pPlayer is null || !pPlayer.IsConnected() )
		return;

	if ( !IsPlayerAdmin( pPlayer ) )
	{
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, g_szModuleName + "You must be an admin to use this command!\n" );
		return;
	}
	
	if ( args.ArgC() < 2 )
	{
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "Usage: ." + setnextmap.GetName() + " " + setnextmap.GetHelpInfo() + "\n" );
		return;
	}

	string szMapName = args.Arg( 1 );
	szMapName.Trim();

	if ( !g_EngineFuncs.IsMapValid( szMapName ) )
	{
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, g_szModuleName + "Map " + szMapName + " is not valid.\n" );
		return;
	}
	
	// Grab the current nextmap
	string szNexMap = g_MapCycle.GetNextMap();
	if ( szNexMap == szMapName )
	{
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, g_szModuleName + "You can't change to the same map. Please select another map.\n" );
		return;
	}
	
	ChangeNextMap( szMapName );
	g_bNextMapByCmd = true;
	
	string szMsg = g_szModuleName + "Nextmap changed (by admin): " + szNexMap + "->" + szMapName + "\n";
	g_PlayerFuncs.ClientPrintAll( HUD_PRINTCONSOLE, szMsg );
	g_EngineFuncs.ServerPrint( szMsg );
}

/** Show g_pMapHistory to player's console */
void ShowMapHistory( const CCommand@ args )
{
	CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();

	if ( pPlayer is null || !pPlayer.IsConnected() )
		return;
	
	g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "--------- Map History ---------\n" );

	string szBuffer;
	for ( uint i = 0; i < g_pMapHistory.length(); i++ )
	{
		szBuffer += string( i + 1 ) +  ": "  + g_pMapHistory[i] + "\n";
		
		if ( szBuffer.Length() < 96 )
			continue;

		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, szBuffer );
		szBuffer.Clear();
	}

	if ( !szBuffer.IsEmpty() )
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, szBuffer );

	g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "---------------------------------\n" );
}

void SaveMap( const string& in szMap )
{
	File@ pFile = g_FileSystem.OpenFile( g_szMapHistoryFile, OpenFile::APPEND );

	if ( pFile !is null && pFile.IsOpen() )
	{
		pFile.Write( szMap + "\n" );
		pFile.Close();
	}
}

bool LoadMaps()
{
	if ( g_pMapHistory.length() > 0 )
		return true;

	File@ pFile = g_FileSystem.OpenFile( g_szMapHistoryFile, OpenFile::READ );

	if ( pFile !is null && pFile.IsOpen() )
	{
		string line;
		while ( !pFile.EOFReached() )
		{
			pFile.ReadLine( line );
			line.Trim();
			
			if ( line.IsEmpty() )
				continue;
			
			if ( !g_EngineFuncs.IsMapValid( line ) )
				continue;
				
			g_pMapHistory.insertLast( line );
		}

		pFile.Close();
		return true;
	}
	return false;
}

void RockTheVote( CBasePlayer@ pPlayer )
{
	if ( !g_pCCVar_Rtv.GetBool() )
	{
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "Rockthevote has been disabled on this server.\n" );
		return;
	}

	if ( g_pCvarVoteAllow.value == 0 )
	{
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCENTER, "Voting not allowed on server.\n" );
		return;
	}

	if ( g_pCvarVoteMapRequired.value < 0 )
	{
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCENTER, "This type of vote is disabled.\n" );
		return;
	}

	if ( g_iMapNums <= 0 )
	{
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "There are no maps in menu\n" );
		return;
	}

	if ( g_bInProgress || TaskExist( g_pVoteNextMapFunction ) )
	{
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "Voting is in progress or is about to begin.\n" );
		return;
	}

	if ( g_bSelected || g_bVoteFinished )
	{
		string szMap = g_MapCycle.GetNextMap();
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "Voting is complete and players have voted for " + szMap + ".\n" );
		return;
	}

	if ( g_bHasBeenRocked )
	{
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "Voting has been rocked on this map already, it cannot be rocked twice on the same map.\n" );
		return;
	}
	
	float timeleft = g_pCvarTimeLeft.value;
	float timelimit = g_pCvarTimeLimit.value;

	if ( timeleft < 129 && timelimit > 0.0 )
	{
		if ( timeleft < 1 )
		{
			g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "There is not enough time remaining on the map to rockthevote.\n" );
			return;
		}
	}
	
	float minutesplayed = g_Engine.time / 60.0;
	float wait = g_pCCVar_RtvMinTime.GetFloat();

	if ( wait < 1.0 )
		wait = 1.0;
	else if ( wait > 100.0 )
		wait = 100.0;

	if ( ( minutesplayed + 0.5 ) < wait )
	{
		if ( wait - 0.5 - minutesplayed > 0.0 )
		{
			int minutes = FloatRound( wait + 0.5 - minutesplayed );
			g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "You must wait another " + ( minutes > 0 ? minutes : 1 ) + " minutes until you can say \"rockthevote\".\n" );
		}
		else
			g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "Under 1 minute until you may rockthevote.\n" );

		return;
	}

	int iPlayer = pPlayer.entindex();

	if ( !g_pRocked[iPlayer] )
	{
		g_pRocked[iPlayer] = true;
		g_iRocks++;
	}
	else
	{
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "Voting has been rocked on this map already, it cannot be rocked twice on the same map.\n" );
		return;
	}

	float rtv_percent = g_pCCVar_RtvPercent.GetFloat();

	if ( rtv_percent < 0.03 )
		rtv_percent = 0.03;
	else if ( rtv_percent > 1.0 )
		rtv_percent = 1.0;

	int needed = FloatRound( g_PlayerFuncs.GetNumPlayers() * rtv_percent + 0.49 );

	if ( g_iRocks >= needed )
	{
		g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, "Enough people (" + g_iRocks + ") now have said \"rockthevote\", so a vote will begin shortly.\n" );
	//	set_hudmessage( 222, 70,0, -1.0, 0.70, 0, 1.0, 10.0, 0.1, 0.2, 4 );
	//	show_hudmessage( 0, "Due to " + g_iRocks + " players Rocking the vote,\n Vote is now rocked\nVoting Will begin shortly." );

		g_bHasBeenRocked = true;
		g_bRockTheVote = true;
		g_bInProgress = true;
		g_bVoteFinished = false;
		@g_pVoteNextMapFunction = g_Scheduler.SetTimeout( "voteNextmap", 15.0 );

		for ( int i = 1; i <= g_Engine.maxClients; i++ )
			g_pRocked[i] = false;

		g_iRocks = 0;

		g_bForceVote = true;

		float vote_time = g_flVoting + 2.0;
		g_flVoting = g_Engine.time + vote_time; 
	}
	else
		g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, string( needed - g_iRocks ) + " more players must say \"rockthevote\" to start a vote.\n" );
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

int FloatRound( float fA )
{
	return int( floor( fA + 0.5 ) );
}

//as_reloadplugin MapChooser
