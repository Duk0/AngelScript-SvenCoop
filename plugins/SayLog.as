const string g_szSayLogPath = "scripts/plugins/store/say_logs/";
array<string> g_pUserIP( g_Engine.maxClients + 1 );
array<string> g_pMessages;

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Duko" );
	g_Module.ScriptInfo.SetContactInfo( "group.midu.cz" );
	g_Hooks.RegisterHook( Hooks::Player::ClientSay, @ClientSay );
	g_Hooks.RegisterHook( Hooks::Player::ClientConnected, @ClientConnected );
	g_Hooks.RegisterHook( Hooks::Player::ClientPutInServer, @ClientPutInServer );
	g_Hooks.RegisterHook( Hooks::Game::MapChange, @MapChange );
}

void MapStart()
{
	string szLog;
	snprintf( szLog, "------- START MAP:  %1 -------", g_Engine.mapname );
	DateTime time;
	string szLogTime;
	time.Format( szLogTime, "%H:%M:%S" );
	g_pMessages.insertLast( szLogTime + " " + szLog );
	WriteMessages();
	
	g_Scheduler.SetInterval( "WriteMessages", 300.0 );
}

HookReturnCode ClientSay( SayParameters@ pParams )
{
	const CCommand@ pArguments = pParams.GetArguments();

	if ( pArguments.ArgC() >= 1 )
	{
		CBasePlayer@ pPlayer = pParams.GetPlayer();

		if ( pPlayer is null || !pPlayer.IsConnected() )
			return HOOK_CONTINUE;

		string szArguments = pArguments.GetCommandString();
		szArguments.Trim();
		if ( szArguments.IsEmpty() )
			return HOOK_CONTINUE;
		
		string szCmd = "say";
		ClientSayType type = pParams.GetSayType();
		if ( type == CLIENTSAY_SAYTEAM )
			szCmd += "_team";

		string szGeoIP = "N/A";
		DateTime time;
		string szLogTime;
		time.Format( szLogTime, "%H:%M:%S" );
		g_pMessages.insertLast( szLogTime + " - [" + szGeoIP + "] \"" + pPlayer.pev.netname + "\" " + szCmd + ": " + szArguments );
	}
	return HOOK_CONTINUE;
}

HookReturnCode ClientConnected( edict_t@ pEdict, const string& in szPlayerName, const string& in szIPAddress, bool& out bDisallowJoin, string& out szRejectReason )
{
	int iPlayer = g_EntityFuncs.EntIndex( pEdict );

	if ( iPlayer > 0 && !szIPAddress.IsEmpty() )
	{
		array<string>@ ip = szIPAddress.Split( ':' );
		g_pUserIP[iPlayer] = ip[0];
	}

	return HOOK_CONTINUE;
}

HookReturnCode ClientPutInServer( CBasePlayer@ pPlayer )
{
	if ( pPlayer is null )
		return HOOK_CONTINUE;
		
	int iPlayer = pPlayer.entindex();
	if ( iPlayer <= 0 )
		return HOOK_CONTINUE;

	string szSteamId = g_EngineFuncs.GetPlayerAuthId( pPlayer.edict() );
	string szGeoIP = "N/A";
	DateTime time;
	string szLogTime;
	time.Format( szLogTime, "%H:%M:%S" );
	g_pMessages.insertLast( szLogTime + " - [" + szGeoIP + "] \"" + pPlayer.pev.netname + "\" *** has joined (" + szSteamId + " | " + g_pUserIP[iPlayer] + ")" );

	return HOOK_CONTINUE;
}

HookReturnCode MapChange()
{
	g_Scheduler.ClearTimerList();
	
	return HOOK_CONTINUE;
}

void WriteMessages()
{
	uint uiLenMsgs = g_pMessages.length();
	if ( uiLenMsgs == 0 )
		return;

	DateTime time;
	string szLogDate;
	time.Format( szLogDate, g_szSayLogPath + "%Y-%m-%d--allsay.log" );

	File@ pFile = g_FileSystem.OpenFile( szLogDate, OpenFile::APPEND );

	if ( pFile !is null && pFile.IsOpen() )
	{
		for ( uint ui = 0; ui < uiLenMsgs; ui++ )
			pFile.Write( "L " + g_pMessages[ui] + "\n" );

		pFile.Close();
		
		g_pMessages.resize(0);
	}
}
