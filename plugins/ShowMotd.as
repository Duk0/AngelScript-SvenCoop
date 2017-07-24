//as_reloadplugin ShowMotd

const int MAX_MOTD_CHUNK = 45; // 48 and more blend text
const string g_szHelpFile = "scripts/plugins/Configs/help.txt";
//const Cvar@ g_pvHostname;

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Duko" );
	g_Module.ScriptInfo.SetContactInfo( "group.midu.cz" );
	g_Hooks.RegisterHook( Hooks::Player::ClientSay, @ClientSay );
//	@g_pvHostname = g_EngineFuncs.CVarGetPointer( "hostname" );
}
/*
void MapInit()
{
	string szFilename = g_EngineFuncs.CVarGetString( "motdfile" );
	//string szFilename = "scripts/plugins/admins.txt";
	File@ pAdminFile = g_FileSystem.OpenFile( szFilename, OpenFile::READ );
	g_EngineFuncs.ServerPrint( "[MOTD] File " + szFilename + " is " + ( (pAdminFile is null) ? "null" : "not null" ) + "\n" );
}
*/
HookReturnCode ClientSay( SayParameters@ pParams )
{
	const CCommand@ pArguments = pParams.GetArguments();

	if ( pArguments.ArgC() >= 1 )
	{
		string szArg = pArguments.Arg( 0 );
		if ( szArg.ICompare( "!motd" ) == 0 || szArg.ICompare( "!help" ) == 0 )
		{
			CBasePlayer@ pPlayer = pParams.GetPlayer();

			if ( pPlayer is null || !pPlayer.IsConnected() )
				return HOOK_HANDLED;

			ShowMotd( pPlayer, g_szHelpFile, "HELP" );
			//ShowMotd( pPlayer, g_szHelpFile, "MESSAGE OF THE DAY" );

			return HOOK_HANDLED;
		}
	}
	return HOOK_CONTINUE;
}

void CmdMotd( const CCommand@ args )
{
	CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();
	
	if ( pPlayer is null || !pPlayer.IsConnected() )
		return;
		
	ShowMotd( pPlayer, g_szHelpFile, "HELP" );
}

CClientCommand motd( "motd", "Show Motd", @CmdMotd );

void CmdHelp( const CCommand@ args )
{
	CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();
	
	if ( pPlayer is null || !pPlayer.IsConnected() )
		return;

	File@ pFile = g_FileSystem.OpenFile( g_szHelpFile, OpenFile::READ );

	if ( pFile !is null && pFile.IsOpen() )
	{
		string line, szToShow;
		while ( !pFile.EOFReached() )
		{
			pFile.ReadLine( line );
			line.Trim();
			line.Trim( '\r' );
				
			szToShow += line + "\n";
		}

		pFile.Close();
		g_EngineFuncs.ClientPrintf( pPlayer, print_console, szToShow );
	}
}

CClientCommand help( "help", "Help", @CmdHelp );

bool ShowMotd( CBasePlayer@ pPlayer, string& in szBody, string& in szHead = "" )
{
	int ilen = szHead.Length();
	
	if ( ilen <= 0 )
		szHead = g_EngineFuncs.CVarGetString( "hostname" ); //g_pvHostname.GetString();

	ilen = szBody.Length();
	int iFile = 0;
	string szToShow; // = szBody;
	
	if ( ilen < 128 )
	{
		File@ pFile = g_FileSystem.OpenFile( szBody, OpenFile::READ );
		
		if ( pFile !is null && pFile.IsOpen() )
		{
			string line;
			while ( !pFile.EOFReached() )
			{
				pFile.ReadLine( line );
				line.Trim();
				
				szToShow += line + "\n";
			}

			pFile.Close();
			iFile = szToShow.Length();
		}
	}
	
	if ( iFile <= 0 )
		szToShow = szBody;
	else
		ilen = iFile;
	
	if ( pPlayer is null )
	{
		g_Game.AlertMessage( at_error, "Invalid player id %1\n", pPlayer.entindex() );
		return false;
	}
	
	if ( pPlayer.IsConnected() )
		UTIL_ShowMOTD( pPlayer.edict(), szToShow, ilen, szHead );
	
	return true;
}

void UTIL_ShowMOTD( edict_t@ client, string motd, int mlen, const string name )
{
	const string hostname = g_EngineFuncs.CVarGetString( "hostname" ); //g_pvHostname.GetString();

	if ( !hostname.IsEmpty() && hostname != name )
	{
		NetworkMessage msgname( MSG_ONE, NetworkMessages::ServerName, g_vecZero, client );
		msgname.WriteString( name );
		msgname.End();
	}

	string chunk;
	int a = 0;

	while ( mlen > a )
	{
		chunk = motd.SubString( a, a + MAX_MOTD_CHUNK > mlen ? mlen - a : MAX_MOTD_CHUNK );
		a += MAX_MOTD_CHUNK;

		NetworkMessage msgmotd( MSG_ONE, NetworkMessages::MOTD, g_vecZero, client );
		msgmotd.WriteByte( chunk.Length() == MAX_MOTD_CHUNK ? uint8( 0 ) : uint8( 1 ) ); // 0 means there is still more message to come
		msgmotd.WriteString( chunk );
		msgmotd.End();	
	}
	
	if ( !hostname.IsEmpty() && hostname != name )
	{
		NetworkMessage msghostname( MSG_ONE, NetworkMessages::ServerName, g_vecZero, client );
		msghostname.WriteString( hostname );
		msghostname.End();
	}
}
