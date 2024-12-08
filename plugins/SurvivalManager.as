bool g_bLastStatus = false;
const Cvar@ g_pCvarSurvivalVoteallow;
string g_szPlayerName;

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Duko" );
	g_Module.ScriptInfo.SetContactInfo( "group.midu.cz" );
	
	g_Hooks.RegisterHook( Hooks::Player::ClientSay, @ClientSay );
	g_Hooks.RegisterHook( Hooks::Game::MapChange, @MapChange );

	@g_pCvarSurvivalVoteallow = g_EngineFuncs.CVarGetPointer( "mp_survival_voteallow" );
}

void MapStart()
{
	if ( !g_bLastStatus && g_SurvivalMode.MapSupportEnabled() && g_SurvivalMode.IsEnabled() )
	{
		g_EngineFuncs.ServerPrint( "[SurvivaManager] Survival Disabling...\n"  );
		g_SurvivalMode.Disable();
	}

	if ( g_SurvivalMode.MapSupportEnabled() )
		g_EngineFuncs.ServerPrint( "[SurvivaManager] Survival is " + ( g_SurvivalMode.IsEnabled() ? "Enabled" : "Disabled" )  + ".\n"  );
}

HookReturnCode ClientSay( SayParameters@ pParams )
{
	const CCommand@ pArguments = pParams.GetArguments();

	if ( pArguments.ArgC() >= 1 )
	{
		string szArg = pArguments.Arg( 0 );
		szArg.Trim();
		szArg.ToLowercase();

		if ( szArg == "!survival" )
		{
			CBasePlayer@ pPlayer = pParams.GetPlayer();

			if ( pPlayer is null || !pPlayer.IsConnected() )
				return HOOK_CONTINUE;

			SurvivalVote( pPlayer );
		}
	}

	return HOOK_CONTINUE;
}

HookReturnCode MapChange( const string& in szNextMap )
{
	if ( g_SurvivalMode.MapSupportEnabled() )
		g_bLastStatus = g_SurvivalMode.IsEnabled();
	else
	{
		if ( g_bLastStatus )
			g_bLastStatus = false;
	}
	
	g_Scheduler.ClearTimerList();

	return HOOK_CONTINUE;
}

void SurvivalVote( CBasePlayer@ pPlayer )
{
	if ( g_pCvarSurvivalVoteallow !is null && g_pCvarSurvivalVoteallow.value < 1 )
	{
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCENTER, "Survival Mode Voting not allowed.\n" );
		return;
	}

	if ( g_Utility.VoteActive() )
	{
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCENTER, "Can't start vote. Other vote in progress.\n" );
		return;
	}

	if ( !g_SurvivalMode.MapSupportEnabled() )
	{
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTNOTIFY, "Survival Mode is not supported on this map.\n" );
		return;
	}
	
	g_szPlayerName = pPlayer.pev.netname;
	
	StartSurvivalModeVote();
}

void StartSurvivalModeVote()
{
	float flVoteTime = g_EngineFuncs.CVarGetFloat( "mp_votetimecheck" );
	
	if ( flVoteTime <= 0 )
		flVoteTime = 16;
	
	float flPercentage = g_EngineFuncs.CVarGetFloat( "mp_votesurvivalmoderequired" );
	
	if ( flPercentage <= 0 )
		flPercentage = 51;
		
	Vote vote( "Survival Mode", "Would you like to " + ( g_SurvivalMode.IsEnabled() ? "Disable" : "Enable" ) + " Survival Mode?", flVoteTime, flPercentage );
	
	vote.SetVoteBlockedCallback( @SurvivalModeVoteBlocked );
	vote.SetVoteEndCallback( @SurvivalModeVoteEnd );
	
	vote.Start();
	
	if ( g_szPlayerName.IsEmpty() )
		g_szPlayerName = "*Empty*";
	
	g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, ( g_SurvivalMode.IsEnabled() ? "Disable" : "Enable" ) + " " + vote.GetName() + " started by " + g_szPlayerName + "\n" );
}

void SurvivalModeVoteBlocked( Vote@ pVote, float flTime )
{
	//Try again later
	g_Scheduler.SetTimeout( "StartSurvivalModeVote", flTime );
}

void SurvivalModeVoteEnd( Vote@ pVote, bool bResult, int iVoters )
{
	if ( !bResult )
	{
		g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, "Vote for Survival Mode failed.\n" );
		return;
	}
	
	g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, "Vote to " + ( !g_SurvivalMode.IsEnabled() ? "Enable" : "Disable" ) + " Survival Mode passed.\n" );
	
	g_SurvivalMode.Toggle();

	NetworkMessage message( MSG_ALL, NetworkMessages::SVC_STUFFTEXT );
	message.WriteString( "spk buttons/bell1" ); // tfc/misc/endgame, ambience/warn2
	message.End();
}

void CmdToggleSurvival( const CCommand@ args )
{
	CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();

	if ( pPlayer is null || !pPlayer.IsConnected() )
		return;

	if ( !IsPlayerAdmin( pPlayer ) )
	{
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "You have no access to that command\n" );
		return;
	}
	
	g_SurvivalMode.Toggle();
}

CClientCommand togglesurvival( "togglesurvival", "togglesurvival", @CmdToggleSurvival );

bool IsPlayerAdmin( CBasePlayer@ pPlayer )
{
	return g_PlayerFuncs.AdminLevel( pPlayer ) >= ADMIN_YES;
}
