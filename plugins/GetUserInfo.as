array<string> g_pUserInfo = { "cl_lc", "cl_lw", "cl_updaterate", "rate", "name", "model", "topcolor", "bottomcolor" };

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Duko" );
	g_Module.ScriptInfo.SetContactInfo( "group.midu.cz" );
	g_Module.ScriptInfo.SetMinimumAdminLevel( ADMIN_YES );
}

CClientCommand g_getinfo( "getinfo", "<name> <info key>", @CmdGetInfo );
CClientCommand g_setinfo( "setinfo", "<name> <info key> <value>", @CmdSetInfo );

void CmdGetInfo( const CCommand@ args )
{
	CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();
	
	if ( pPlayer is null || !pPlayer.IsConnected() )
		return;

	if	( args.ArgC() < 2 )
	{
		g_EngineFuncs.ClientPrintf( pPlayer, print_console, "Usage: ." + g_getinfo.GetName() + " " + g_getinfo.GetHelpInfo() + "\n" );
		return;
	}

	string szArg = args.Arg( 1 );
	szArg.Trim();

	CBasePlayer@ pTarget = GetTargetPlayer( pPlayer, szArg, false );

	if ( pTarget is null )
		return;
	
	szArg = args.Arg( 2 );
	szArg.Trim();

	KeyValueBuffer@ pUserInfo = g_EngineFuncs.GetInfoKeyBuffer( pPlayer.edict() );

	if ( szArg.IsEmpty() )
	{
		uint uiCount = g_pUserInfo.length();
		string szOutput;
		
		for ( uint i = 0; i < uiCount; i++ )
			szOutput += g_pUserInfo[i] + " " + pUserInfo.GetValue( g_pUserInfo[i] ) + "\n";
		
		g_EngineFuncs.ClientPrintf( pPlayer, print_console, "Setinfo for player: " + pTarget.pev.netname + "\n" + szOutput );
		return;
	}
		
	string szValue = pUserInfo.GetValue( szArg );
		
	if ( szValue.IsEmpty() )
	{
		g_EngineFuncs.ClientPrintf( pPlayer, print_console, "Value is empty\n" );
		return;
	}
		
	g_EngineFuncs.ClientPrintf( pPlayer, print_console, "Setinfo for player: " + pTarget.pev.netname + "\n" + szArg + " " + szValue + "\n" );
}

void CmdSetInfo( const CCommand@ args )
{
	CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();
	
	if ( pPlayer is null || !pPlayer.IsConnected() )
		return;

	if	( args.ArgC() < 3 )
	{
		g_EngineFuncs.ClientPrintf( pPlayer, print_console, "Usage: ." + g_setinfo.GetName() + " " + g_setinfo.GetHelpInfo() + "\n" );
		return;
	}

	string szArg = args.Arg( 1 );
	szArg.Trim();

	CBasePlayer@ pTarget = GetTargetPlayer( pPlayer, szArg );

	if ( pTarget is null )
		return;
	
	string szKey = args.Arg( 2 );
	szKey.Trim();

	if ( g_pUserInfo.find( szKey ) < 0 )
	{
		g_EngineFuncs.ClientPrintf( pPlayer, print_console, "Keyvalue not found\n" );
		return;
	}

	string szValue = args.Arg( 3 );
	szValue.Trim();

	KeyValueBuffer@ pUserInfo = g_EngineFuncs.GetInfoKeyBuffer( pPlayer.edict() );
	
	pUserInfo.SetValue( szKey, szValue );

	ShowActivityToAdmins( pPlayer, "setinfo " + szKey + " " + szValue + " on player " + pTarget.pev.netname + "\n" );
	g_Game.AlertMessage( at_logged, "ADMIN: %1 setinfo %2 %3 on player %4\n", pPlayer.pev.netname, szKey, szValue, pTarget.pev.netname );
}

void ShowActivityToAdmins( CBasePlayer@ pPlayer, const string& in szMessage )
{
	CBasePlayer@ pTarget;

	for ( int iIndex = 1; iIndex <= g_PlayerFuncs.GetNumPlayers(); iIndex++ )
	{
		@pTarget = g_PlayerFuncs.FindPlayerByIndex( iIndex );
		
		if ( pTarget is null || !pTarget.IsConnected() )
			continue;
		
		if ( !IsPlayerAdmin( pTarget ) )
			continue;
		
		g_PlayerFuncs.ClientPrint( pTarget, HUD_PRINTTALK, "ADMIN " + pPlayer.pev.netname + ": " + szMessage );
	}
}

CBasePlayer@ GetTargetPlayer( CBasePlayer@ pPlayer, const string& in szNameOrUserId, const bool bImmunity = true )
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
		string szUserId;
		for ( int iIndex = 1; iIndex <= g_PlayerFuncs.GetNumPlayers(); iIndex++ )
		{
			@pTarget = g_PlayerFuncs.FindPlayerByIndex( iIndex );
			
			if ( pTarget is null || !pTarget.IsConnected() )
				continue;

			szUserId = "#" + g_EngineFuncs.GetPlayerUserId( pTarget.edict() );
			
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

	if ( bImmunity && pTarget !is pPlayer && IsPlayerAdmin( pTarget ) )
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
