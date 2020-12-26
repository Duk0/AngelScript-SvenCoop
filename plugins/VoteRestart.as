const Cvar@ g_pCvarVoteAllow, g_pCvarVoteTimeCheck, g_pCvarVoteMapRequired;
string g_szPlayerName;

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Duko" );
	g_Module.ScriptInfo.SetContactInfo( "group.midu.cz" );

	g_Hooks.RegisterHook( Hooks::Game::MapChange, @MapChange );
	g_Hooks.RegisterHook( Hooks::Player::ClientSay, @ClientSay );

	@g_pCvarVoteAllow = g_EngineFuncs.CVarGetPointer( "mp_voteallow" );
	@g_pCvarVoteTimeCheck = g_EngineFuncs.CVarGetPointer( "mp_votetimecheck" );
	@g_pCvarVoteMapRequired = g_EngineFuncs.CVarGetPointer( "mp_votemaprequired" );
}

HookReturnCode MapChange()
{
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
		if ( szArg.ICompare( "!restart" ) == 0 )
		{
			CBasePlayer@ pPlayer = pParams.GetPlayer();

			if ( pPlayer is null || !pPlayer.IsConnected() )
				return HOOK_CONTINUE;

			RestartVote( pPlayer );
		}
	}
	return HOOK_CONTINUE;
}

void RestartVote( CBasePlayer@ pPlayer )
{
	if ( g_pCvarVoteAllow !is null && g_pCvarVoteAllow.value < 1 )
	{
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCENTER, "Voting not allowed on server.\n" );
		return;
	}

	if ( g_pCvarVoteMapRequired.value < 0 )
	{
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCENTER, "This type of vote is disabled.\n" );
		return;
	}

	if ( g_Utility.VoteActive() )
	{
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCENTER, "Can't start vote. Other vote in progress.\n" );
		return;
	}
	
	g_szPlayerName = pPlayer.pev.netname;
	
	StartMapRestartVote();
}

void StartMapRestartVote()
{
	float flVoteTime = g_pCvarVoteTimeCheck.value;
	
	if ( flVoteTime <= 0 )
		flVoteTime = 16;
		
	float flPercentage = g_pCvarVoteMapRequired.value;
	
	if ( flPercentage <= 0 )
		flPercentage = 51;
		
	Vote vote( "Restart map vote", "Restart map?", flVoteTime, flPercentage );
	
	vote.SetVoteBlockedCallback( @RestartMapVoteBlocked );
	vote.SetVoteEndCallback( @RestartMapVoteEnd );
	
	vote.Start();

	if ( g_szPlayerName.IsEmpty() )
		g_szPlayerName = "*Empty*";
	
	g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, vote.GetName() + " started by " + g_szPlayerName + "\n" );
}

void RestartMapVoteBlocked( Vote@ pVote, float flTime )
{
	//Try again later
	g_Scheduler.SetTimeout( "StartMapRestartVote", flTime );
}

void RestartMapVoteEnd( Vote@ pVote, bool bResult, int iVoters )
{
	if ( !bResult )
	{
		g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, "Vote for Restart map failed\n" );
		return;
	}
	
	g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, "Vote for Restart map passed\n" );
	
	g_Scheduler.SetTimeout( "PerformRestartMap", 2.0 );

	NetworkMessage message( MSG_ALL, NetworkMessages::SVC_STUFFTEXT );
	message.WriteString( "spk buttons/bell1" ); // tfc/misc/endgame, ambience/warn2
	message.End();
}

void PerformRestartMap()
{
	g_EngineFuncs.ChangeLevel( g_Engine.mapname );
}
