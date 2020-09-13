//
// AMX Mod X, based on AMX Mod by Aleksander Naszko ("OLO").
//
// Admin Votes Plugin
//


string g_szAnswer;
array<string> g_pOptionName( 4 );
array<int> g_pVoteCount( 4, 0 );
int g_iValidMaps;
bool g_bYesNoVote;
int g_iVoteCaller;
string g_szExecute;
bool g_bExecResult;
float g_flVoteRatio;
float g_flVoting = 0;
array<string> g_szUserIP( g_Engine.maxClients + 1 );
CTextMenu@ g_VoteMenu;

CScheduledFunction@ g_pAutoRefuseFunction = null, g_pCheckVotesFunction = null;
//CScheduledFunction@ g_pDelayedExecFunction = null;

CCVar@ g_pCCVar_VoteAnswers, g_pCCVar_VoteDelay, g_pCCVar_VoteTime, g_pCCVar_VoteRatio, g_pCCVar_VoteMapRatio, g_pCCVar_VoteKickRatio, g_pCCVar_VoteBanRatio;

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Duko" );
	g_Module.ScriptInfo.SetContactInfo( "group.midu.cz" );
	g_Module.ScriptInfo.SetMinimumAdminLevel( ADMIN_YES );

	@g_pCCVar_VoteAnswers = CCVar( "vote_answers", "1", "Display who votes for what option, set to 0 to disable, 1 to enable." );
	@g_pCCVar_VoteDelay = CCVar( "vote_delay", "10", "Minimum delay in seconds between two voting sessions" );
	@g_pCCVar_VoteTime = CCVar( "vote_time", "30", "How long voting session goes on" );
	@g_pCCVar_VoteMapRatio = CCVar( "votemap_ratio", "0.60", "map ratio for voting success" );
	@g_pCCVar_VoteRatio = CCVar( "vote_ratio", "0.51", "ratio for voting success" );
	@g_pCCVar_VoteKickRatio = CCVar( "votekick_ratio", "0.66", "kick ratio for voting success" );
	@g_pCCVar_VoteBanRatio = CCVar( "voteban_ratio", "0.75", "ban ratio for voting success" );
	
	//if ( g_EngineFuncs.CVarGetFloat( "sv_lan" ) > 0 )
	g_Hooks.RegisterHook( Hooks::Player::ClientConnected, @ClientConnected );
	g_Hooks.RegisterHook( Hooks::Game::MapChange, @MapChange );
}

CClientCommand g_votemap( "votemap", "<map> [map] [map] [map]", @cmdVoteMap );
CClientCommand g_votekick( "votekick", "<name or #userid>", @cmdVoteKickBan ); // vote kick/ban for #userid use in quotes "" otherwise will not work // its already fixed :)
CClientCommand g_voteban( "voteban", "<name or #userid>", @cmdVoteKickBan );
CClientCommand g_vote( "vote", "<question> <answer#1> <answer#2>", @cmdVote );
CClientCommand g_cancelvote( "cancelvote", "- cancels last vote", @cmdCancelVote );

HookReturnCode ClientConnected( edict_t@ pEdict, const string& in szPlayerName, const string& in szIPAddress, bool& out bDisallowJoin, string& out szRejectReason )
{
	int iPlayer = g_EntityFuncs.EntIndex( pEdict );

	if ( iPlayer > 0 && !szIPAddress.IsEmpty() )
	{
		array<string>@ ip = szIPAddress.Split( ':' );
		g_szUserIP[iPlayer] = ip[0];
	}

	return HOOK_CONTINUE;
}

HookReturnCode MapChange()
{
	if ( g_VoteMenu !is null )
		@g_VoteMenu = null;

	g_Scheduler.ClearTimerList();

	g_szAnswer.Clear();
	g_szExecute.Clear();
	g_iVoteCaller = 0;
	g_flVoting = 0;
	
	return HOOK_CONTINUE;
}

void cmdCancelVote( const CCommand@ args )
{
	CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();

	if ( pPlayer is null || !pPlayer.IsConnected() )
		return;

	if ( !IsPlayerAdmin( pPlayer ) )
	{
		g_EngineFuncs.ClientPrintf( pPlayer, print_console, "You have no access to this command.\n" );
		return;
	}

	if ( g_pCheckVotesFunction !is null && !g_pCheckVotesFunction.HasBeenRemoved() )
	{
		string authid = g_EngineFuncs.GetPlayerAuthId( pPlayer.edict() );
		string name = pPlayer.pev.netname;

		g_Game.AlertMessage( at_logged, "Vote: \"%1<#%2><%3>\" cancel vote session\n", name, g_EngineFuncs.GetPlayerUserId( pPlayer.edict() ), authid + "\n" );
	
		ShowActivity( pPlayer, "cancel vote\n" );

		g_EngineFuncs.ClientPrintf( pPlayer, print_console, "Voting canceled\n" );
		g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, "Voting canceled\n" );
		g_Scheduler.RemoveTimer( g_pCheckVotesFunction );
		g_flVoting = g_Engine.time;
	}
	else
		g_EngineFuncs.ClientPrintf( pPlayer, print_console, "There is no voting to cancel or the vote session can't be canceled with that command\n" );
}

void delayedExec( string& in cmd )
{
	g_EngineFuncs.ServerCommand( cmd + "\n" );
}

void autoRefuse()
{
	g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, "Result refused\n" );
	g_Game.AlertMessage( at_logged, "Vote: Result refused\n" );
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
				g_Scheduler.SetTimeout( "delayedExec", 2.0, g_szExecute );
				g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, "Result accepted\n" );
				g_Game.AlertMessage( at_logged, "Vote: Result accepted\n" );
				break;
			}
			case 2: autoRefuse(); break;
		}
	}

	if ( @menu !is null && menu.IsRegistered() )
	{
		@menu = null;
	}
}

void checkVotes()
{
	int best = 0;
	
	if ( !g_bYesNoVote )
	{
		for ( int a = 0; a < 4; a++ )
			if ( g_pVoteCount[a] > g_pVoteCount[best] )
				best = a;
	}

	int votesNum = g_pVoteCount[0] + g_pVoteCount[1] + g_pVoteCount[2] + g_pVoteCount[3];
	int iRatio = votesNum > 0 ? int( ceil( g_flVoteRatio * float( votesNum ) ) ) : 1;
	int iResult = g_pVoteCount[best];
	
	if ( iResult < iRatio )
	{
		if ( g_bYesNoVote )
			g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, "Voting failed (yes \"" + g_pVoteCount[0] + "\") (no \"" + g_pVoteCount[1] + "\") (needed \"" + iRatio + "\")\n" );
		else
			g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, "Voting failed (got \""+ iResult + "\") (needed \"" + iRatio + "\")\n" );

		g_Game.AlertMessage( at_logged, "Vote: Voting failed (got \"%1\") (needed \"%2\")\n", iResult, iRatio );
		
		return;
	}

	snprintf( g_szExecute, g_szAnswer, g_pOptionName[best] );
	
	if ( g_bExecResult )
	{
		g_bExecResult = false;
		CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( g_iVoteCaller );
		
		if ( pPlayer !is null && pPlayer.IsConnected() )
		{
			@g_VoteMenu = CTextMenu( @actionResult );
			g_VoteMenu.SetTitle( "The result: " + g_szExecute + "\nDo you want to continue?\n" );
			g_VoteMenu.AddItem( "Yes" );
			g_VoteMenu.AddItem( "No" );
			g_VoteMenu.Register();
			g_VoteMenu.Open( 15, 0, pPlayer );

			@g_pAutoRefuseFunction = g_Scheduler.SetTimeout( "autoRefuse", 15.5 );
		}
		else
			g_Scheduler.SetTimeout( "delayedExec", 2.0, g_szExecute );
	}
	
	g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, "Voting successful (got \"" + iResult + "\") (needed \"" + iRatio + "\"). The result: " + g_szExecute + "\n" );
	
	g_Game.AlertMessage( at_logged, "Vote: Voting successful (got \"%1\") (needed \"%2\") (result \"%3\")\n", iResult, iRatio, g_szExecute );
}

void voteCount( CTextMenu@ menu, CBasePlayer@ pPlayer, int iSlot, const CTextMenuItem@ pItem )
{
	if ( pItem !is null && pPlayer !is null )
	{
		if ( g_pCCVar_VoteAnswers.GetBool() )
		{
			if ( g_bYesNoVote )
				g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, string( pPlayer.pev.netname ) + ( iSlot != 1 ? " voted against" : " voted for" ) + "\n" );
			else
				g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, string( pPlayer.pev.netname ) + " voted for option " + iSlot + "\n" );
		}

		g_pVoteCount[iSlot - 1]++;
	}

	if ( @menu !is null && menu.IsRegistered() )
	{
		@menu = null;
	}
}

void cmdVoteMap( const CCommand@ args )
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
		g_EngineFuncs.ClientPrintf( pPlayer, print_console, "There is already one voting...\n" );
		return;
	}
	
	if ( g_flVoting > 0 && g_flVoting + g_pCCVar_VoteDelay.GetFloat() > g_Engine.time )
	{
		g_EngineFuncs.ClientPrintf( pPlayer, print_console, "Voting not allowed at this time\n" );
		return;
	}

	int argc = args.ArgC();
	if ( argc > 5 ) argc = 5;

	if ( argc < 2 )
	{
		g_EngineFuncs.ClientPrintf( pPlayer, print_console, "Usage: ." + g_votemap.GetName() + " " + g_votemap.GetHelpInfo() + "\n" );
		return;
	}
	
	g_iValidMaps = 0;
	
	for ( int a = 0; a < 4; a++ )
		g_pOptionName[a].Clear();
	
	for ( int i = 1; i < argc; i++ )
	{
		g_pOptionName[g_iValidMaps] = args.Arg( i );
		g_pOptionName[g_iValidMaps].Trim();
		
		if ( g_EngineFuncs.IsMapValid( g_pOptionName[g_iValidMaps] ) )
			g_iValidMaps++;
	}
	
	if ( g_iValidMaps == 0 )
	{
		g_EngineFuncs.ClientPrintf( pPlayer, print_console, "Given " + ( ( argc == 2 ) ? "map is" : "maps are" ) + " not valid\n" );
		return;
	}
	
	@g_VoteMenu = CTextMenu( @voteCount );

	if ( g_iValidMaps > 1 )
	{
		g_VoteMenu.SetTitle( "Choose map:\n" );
		
		for ( int a = 0; a < g_iValidMaps; a++ )
			g_VoteMenu.AddItem( g_pOptionName[a] );
		
		g_bYesNoVote = false;
	}
	else
	{
		g_VoteMenu.SetTitle( "Change map to " + g_pOptionName[0] + "?\n" );
		g_VoteMenu.AddItem( "Yes" );
		g_VoteMenu.AddItem( "No" );
		g_bYesNoVote = true;
	}
	
	string authid = g_EngineFuncs.GetPlayerAuthId( pPlayer.edict() );
	string name = pPlayer.pev.netname;
	
	if ( argc == 2 )
		g_Game.AlertMessage( at_logged, "Vote: \"%1<#%2><%3>\" vote map (map \"%4\")\n", name, g_EngineFuncs.GetPlayerUserId( pPlayer.edict() ), authid, g_pOptionName[0] );
	else
		g_Game.AlertMessage( at_logged, "Vote: \"%1<#%2><%3>\" vote maps (map#1 \"%4\") (map#2 \"%5\") (map#3 \"%6\") (map#4 \"%7\")\n", name, g_EngineFuncs.GetPlayerUserId( pPlayer.edict() ), authid, g_pOptionName[0], g_pOptionName[1], g_pOptionName[2], g_pOptionName[3] );
	
	ShowActivity( pPlayer, "vote map(s)\n" );

	g_bExecResult = true;
	
	float vote_time = g_pCCVar_VoteTime.GetFloat() + 2.0;
	
	g_flVoting = g_Engine.time + vote_time;
	g_flVoteRatio = g_pCCVar_VoteMapRatio.GetFloat();
	g_szAnswer = "changelevel %1";
	g_VoteMenu.Register();
	g_VoteMenu.Open( int( vote_time ), 0 );
	@g_pCheckVotesFunction = g_Scheduler.SetTimeout( "checkVotes", vote_time + 0.5 );
	g_iVoteCaller = pPlayer.entindex();
	g_EngineFuncs.ClientPrintf( pPlayer, print_console, "Voting has started...\n" );

	for ( int a = 0; a < 4; a++ )
		g_pVoteCount[a] = 0;
}

void cmdVote( const CCommand@ args )
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
		g_EngineFuncs.ClientPrintf( pPlayer, print_console, "There is already one voting...\n" );
		return;
	}
	
	if ( g_flVoting > 0 && g_flVoting + g_pCCVar_VoteDelay.GetFloat() > g_Engine.time )
	{
		g_EngineFuncs.ClientPrintf( pPlayer, print_console, "Voting not allowed at this time\n" );
		return;
	}

	int count = args.ArgC();

	if ( count < 4 )
	{
		g_EngineFuncs.ClientPrintf( pPlayer, print_console, "Usage: ." + g_vote.GetName() + " " + g_vote.GetHelpInfo() + "\n" );
		return;
	}

	string quest = args.Arg( 1 );
	quest.Trim();
	
	if ( int( "sv_cheats".Find( quest, 0, String::CaseInsensitive ) ) != -1 || int( "sv_password".Find( quest, 0, String::CaseInsensitive ) ) != -1 || int( "rcon_password".Find( quest, 0, String::CaseInsensitive ) ) != -1 )
	{
		g_EngineFuncs.ClientPrintf( pPlayer, print_console, "Voting for that has been forbidden\n" );
		return;
	}
	
	string szOption;

	for ( int i = 0; i < 4 && ( i + 2 ) < count; i++ )
	{
		szOption = args.Arg( i + 2 );
		szOption.Trim();
		g_pOptionName[i] = szOption;
	}

	string authid = g_EngineFuncs.GetPlayerAuthId( pPlayer.edict() );
	string name = pPlayer.pev.netname;
	g_Game.AlertMessage( at_logged, "Vote: \"%1<#%2><%3>\" vote custom (question \"%4\") (option#1 \"%5\") (option#2 \"%6\")\n", name, g_EngineFuncs.GetPlayerUserId( pPlayer.edict() ), authid, quest, g_pOptionName[0], g_pOptionName[1] );

	ShowActivity( pPlayer, "vote custom\n" );

	count -= 2;
	if ( count > 4 )
		count = 4;

	@g_VoteMenu = CTextMenu( @voteCount );
	g_VoteMenu.SetTitle( "Vote: " + quest + "\n" );
	
	for ( int i = 0; i < count; i++ )
		g_VoteMenu.AddItem( g_pOptionName[i] );

	g_bExecResult = false;
	
	float vote_time = g_pCCVar_VoteTime.GetFloat() + 2.0;
	
	g_flVoting = g_Engine.time + vote_time;
	g_flVoteRatio = g_pCCVar_VoteRatio.GetFloat();
	g_szAnswer = quest + " - %1";
	g_VoteMenu.Register();
	g_VoteMenu.Open( int( vote_time ), 0 );
	@g_pCheckVotesFunction = g_Scheduler.SetTimeout( "checkVotes", vote_time + 0.5 );
	g_iVoteCaller = pPlayer.entindex();
	g_EngineFuncs.ClientPrintf( pPlayer, print_console, "Voting has started...\n" );

	for ( int a = 0; a < 4; a++ )
		g_pVoteCount[a] = 0;

	g_bYesNoVote = false;
}

void cmdVoteKickBan( const CCommand@ args )
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
		g_EngineFuncs.ClientPrintf( pPlayer, print_console, "There is already one voting...\n" );
		return;
	}

	if ( g_flVoting > 0 && g_flVoting + g_pCCVar_VoteDelay.GetFloat() > g_Engine.time )
	{
		g_EngineFuncs.ClientPrintf( pPlayer, print_console, "Voting not allowed at this time\n" );
		return;
	}
	
	bool voteban = ( args.Arg( 0 ) == ".voteban" );
	string arg = args.Arg( 1 );
	arg.Trim();

	if ( arg.IsEmpty() )
	{
		CClientCommand@ pClCmd = g_votekick;
		if ( voteban )
			@pClCmd = g_voteban;

		g_EngineFuncs.ClientPrintf( pPlayer, print_console, "Usage: ." + pClCmd.GetName() + " " + pClCmd.GetHelpInfo() + "\n" );
		return;
	}
	
	CBasePlayer@ pTarget = GetTargetPlayer( pPlayer, arg );
	
	if ( pTarget is null || !pTarget.IsConnected() )
		return;
	
	arg = pTarget.pev.netname;
	
	if ( voteban && ( pTarget.pev.flags & FL_FAKECLIENT ) != 0 )
	{
		g_EngineFuncs.ClientPrintf( pPlayer, print_console, "That action can't be performed on bot " + arg + "\n" );
		return;
	}
	
	@g_VoteMenu = CTextMenu( @voteCount );
	g_VoteMenu.SetTitle( voteban ? "Ban " : "Kick " + arg + "?\n" );
	g_VoteMenu.AddItem( "Yes" );
	g_VoteMenu.AddItem( "No" );

	g_bYesNoVote = true;
	
	bool ipban = false;
	
	if ( voteban )
	{
		g_pOptionName[0] = g_EngineFuncs.GetPlayerAuthId( pTarget.edict() );
		
		// Do the same check that's in plmenu to determine if this should be an IP ban instead
		if ( g_pOptionName[0] == "STEAM_ID_LAN" || g_pOptionName[0] == "STEAM_ID_PENDING" )
		{
			g_pOptionName[0] = g_szUserIP[pTarget.entindex()];
			
			ipban = true;
		}
	}
	else
	{
		g_pOptionName[0] = string( g_EngineFuncs.GetPlayerUserId( pTarget.edict() ) );
	}
	
	string authid = g_EngineFuncs.GetPlayerAuthId( pPlayer.edict() );
	string name = pPlayer.pev.netname;
	
	g_Game.AlertMessage( at_logged, "Vote: \"%1<#%2><%3>\" vote %4 (target \"%5\")\n", name, g_EngineFuncs.GetPlayerUserId( pPlayer.edict() ), authid, voteban ? "ban" : "kick", arg + "\n" );
	
	ShowActivity( pPlayer, "vote " + ( voteban ? "ban" : "kick" ) + " for " + arg + "\n" );

	g_bExecResult = true;
	
	float vote_time = g_pCCVar_VoteTime.GetFloat() + 2.0;
	
	g_flVoting = g_Engine.time + vote_time;
	g_flVoteRatio = voteban ? g_pCCVar_VoteKickRatio.GetFloat() : g_pCCVar_VoteBanRatio.GetFloat();

	if ( voteban )
	{
		if ( ipban )
			g_szAnswer = "addip 30.0 %1;wait;writeip";
		else
			g_szAnswer = "banid 30.0 %1 kick;wait;writeid";
	}
	else
	{
		g_szAnswer = "kick \"#%1\"";
	}

	g_VoteMenu.Register();
	g_VoteMenu.Open( int( vote_time ), 0 );
	@g_pCheckVotesFunction = g_Scheduler.SetTimeout( "checkVotes", vote_time + 0.5 );
	g_iVoteCaller = pPlayer.entindex();
	g_EngineFuncs.ClientPrintf( pPlayer, print_console, "Voting has started...\n" );

	for ( int a = 0; a < 4; a++ )
		g_pVoteCount[a] = 0;
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

CBasePlayer@ GetTargetPlayer( CBasePlayer@ pPlayer, const string& in szNameOrUserId )
{
	CBasePlayer@ pTarget = g_PlayerFuncs.FindPlayerByName( szNameOrUserId, false );
	int iCount = 0;

	if ( pTarget is null )
	{
		CBasePlayer@ pTempPlayer = null;
		string szPlayerName;
		for ( int iIndex = 1; iIndex <= g_PlayerFuncs.GetNumPlayers(); iIndex++ )
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
		for ( int iIndex = 1; iIndex <= g_PlayerFuncs.GetNumPlayers(); iIndex++ )
		{
			@pTarget = g_PlayerFuncs.FindPlayerByIndex( iIndex );
			
			if ( pTarget is null )
				continue;

			const string szUserId = "#" + g_EngineFuncs.GetPlayerUserId( pTarget.edict() );
			
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

	if ( pTarget !is null && IsPlayerAdmin( pTarget ) )
	{
		g_EngineFuncs.ClientPrintf( pPlayer, print_console, "Client " + pTarget.pev.netname + " has immunity\n" );
		return null;
	}
	
	return pTarget;
}

bool IsPlayerAdmin( CBasePlayer@ pPlayer )
{
	return g_PlayerFuncs.AdminLevel( pPlayer ) >= ADMIN_YES;
}

int FloatRound( float fA )
{
	return int( floor( fA + 0.5 ) );
}
