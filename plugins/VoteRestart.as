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

			StartMapRestartVote( pPlayer );
		}
	}
	return HOOK_CONTINUE;
}

void StartMapRestartVote( CBasePlayer@ pPlayer )
{
	if ( g_Utility.VoteActive() )
	{
		g_EngineFuncs.ClientPrintf( pPlayer, print_center, "Can't start vote. Other vote in progress.\n" );
		return;
	}

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
	
	g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, vote.GetName() + " started by " + pPlayer.pev.netname + "\n" );
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

	NetworkMessage message( MSG_ALL, NetworkMessages::NetworkMessageType( 9 ) );
	message.WriteString( "spk buttons/bell1" ); // tfc/misc/endgame, ambience/warn2
	message.End();
}

void PerformRestartMap()
{
	g_EngineFuncs.ChangeLevel( g_Engine.mapname );
}
