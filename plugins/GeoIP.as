//as_reloadplugin GeoIP
//http://geolite.maxmind.com/download/geoip/database/GeoIPCountryCSV.zip

//array<uint> g_uiUserIP( g_Engine.maxClients + 1 );
bool g_bGeoIPLoaded = false;
array<GeoIP> g_pGeoIPTest;
array<string> g_pPartGeoIP;
//array<string> g_pPart2GeoIP;
//dictionary g_dGeoIP;
dictionary g_dUserIP;

class GeoIP
{
	uint min, max;
	string code, country;
}

class UserIP
{
	string ip;
	uint numip;
}

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Duko" );
	g_Module.ScriptInfo.SetContactInfo( "group.midu.cz" );
	g_Module.ScriptInfo.SetMinimumAdminLevel( ADMIN_OWNER );
	
	g_Hooks.RegisterHook( Hooks::Player::ClientConnected, @ClientConnected );
	g_Hooks.RegisterHook( Hooks::Player::ClientDisconnect, @ClientDisconnect );
	
	LoadGeoip();
}

HookReturnCode ClientConnected( edict_t@ pEdict, const string& in szPlayerName, const string& in szIPAddress, bool& out bDisallowJoin, string& out szRejectReason )
{
//	int iPlayer = g_EntityFuncs.EntIndex( pEdict );

//	if ( iPlayer <= 0 || szIPAddress.IsEmpty() )
	if ( szIPAddress.IsEmpty() )
		return HOOK_CONTINUE;

	array<string>@ ip = szIPAddress.Split( ':' );
	//g_uiUserIP[iPlayer] = StringIPv4ToInt( ip[0] );

	string szSteamId = g_EngineFuncs.GetPlayerAuthId( pEdict );
	if ( szSteamId.IsEmpty() )
		return HOOK_CONTINUE;

	UserIP data;
	data.ip = ip[0];
	data.numip = StringIPv4ToInt( ip[0] );
	g_dUserIP.set( szSteamId, data );

	return HOOK_CONTINUE;
}

HookReturnCode ClientDisconnect( CBasePlayer@ pPlayer )
{
	if ( pPlayer is null )
		return HOOK_CONTINUE;

	string szSteamId = g_EngineFuncs.GetPlayerAuthId( pPlayer.edict() );
	if ( !g_dUserIP.exists( szSteamId ) )
		return HOOK_CONTINUE;

	g_dUserIP.delete( szSteamId );

	return HOOK_CONTINUE;
}

void LoadGeoip( File@ pFile = null )
{
	if ( g_bGeoIPLoaded )
		return;

	if ( pFile is null )
	{
		@pFile = g_FileSystem.OpenFile( "scripts/plugins/Configs/GeoIPCountryWhois.csv", OpenFile::READ );
		g_EngineFuncs.ServerPrint( "Loading GeoIP database...\n" );
	}

	int iLinesRead = 0;

	if ( pFile !is null && pFile.IsOpen() )
	{
		string line;
		GeoIP data;
		while ( !pFile.EOFReached() )
		{
			pFile.ReadLine( line );
			line.Trim();
				
			if ( line.IsEmpty() )
				continue;
				
			line.Trim( '"' );
			array<string>@ buff = line.Split( '","' );
			//for ( uint uiIP = atoui( buff[2] ); uiIP <= atoui( buff[3] ); ++uiIP )
			//	g_dGeoIP.set( IntIPv4ToString( uiIP ), buff[4] );
		
			data.min = atoui( buff[2] );
			data.max = atoui( buff[3] );
			data.code = buff[4];
			data.country = buff[5];
	
			g_pGeoIPTest.insertLast( data );
			array<string>@ ip = buff[0].Split( '.' );
			string szip = ip[0] + "." + ip[1];
			g_pPartGeoIP.insertLast( szip );
		//	g_pPart2GeoIP.insertLast( szip + "." + ip[2] );

			if ( iLinesRead++ > 32 )
			{
				g_Scheduler.SetTimeout( "LoadGeoip", 0, @pFile );
				return;
			}
		}
			
		pFile.Close();	
	}

	g_EngineFuncs.ServerPrint( "GeoIP database loaded. " + g_pGeoIPTest.length() + " lines\n" );
	g_bGeoIPLoaded = true;
}

void CmdGeoIP( const CCommand@ args )
{
	if ( args.Arg( 1 ) == "test" )
	{
		uint uiIP = 3758096383;
		
		g_EngineFuncs.ServerPrint( "IP " + IntIPv4ToString( uiIP ) + "\n" );

		g_EngineFuncs.ServerPrint( "Country " + GetCountry( uiIP ) + "\n" );
		g_EngineFuncs.ServerPrint( "Country " + GetCountry( 2731805695 ) + "\n" );
		g_EngineFuncs.ServerPrint( "Country " + GetCountry( 3222031871 ) + "\n" );
		g_EngineFuncs.ServerPrint( "Country " + GetCountry( 3222953215 ) + "\n" );
		g_EngineFuncs.ServerPrint( "Country " + GetCountry( 3223563519 ) + "\n" );
		g_EngineFuncs.ServerPrint( "Country " + GetCountry( 3392924159 ) + "\n" );
		g_EngineFuncs.ServerPrint( "Country " + GetCountry( 3645759487 ) + "\n" );
		
		return;
	}
	
	string szSteamId;
	UserIP data;
	
	for ( int iTarget = 1; iTarget <= g_Engine.maxClients; ++iTarget )
	{
		CBasePlayer@ pTarget = g_PlayerFuncs.FindPlayerByIndex( iTarget );
		
		if ( pTarget is null || !pTarget.IsConnected() )
			continue;
			
		szSteamId = g_EngineFuncs.GetPlayerAuthId( pTarget.edict() );
		
		if ( !g_dUserIP.get( szSteamId, data ) )
			continue;

		//g_EngineFuncs.ServerPrint( string( pTarget.pev.netname ) + " is connected from " + GetCountry( g_uiUserIP[iTarget] ) + "\n" );
		g_EngineFuncs.ServerPrint( string( pTarget.pev.netname ) + " is connected from " + GetCountry( data.numip ) + "\n" );
	}
}

CConCommand cmdgeoip( "geoip", "geoip", @CmdGeoIP ); //as_command .geoip test

void ClCmdGeoLocation( const CCommand@ args )
{
	CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();
	
	if ( pPlayer is null || !pPlayer.IsConnected() )
		return;

	string szSteamId;
	UserIP data;

	for ( int iTarget = 1; iTarget <= g_Engine.maxClients; ++iTarget )
	{
		CBasePlayer@ pTarget = g_PlayerFuncs.FindPlayerByIndex( iTarget );
		
		if ( pTarget is null || !pTarget.IsConnected() )
			continue;

		szSteamId = g_EngineFuncs.GetPlayerAuthId( pTarget.edict() );
		
		if ( !g_dUserIP.get( szSteamId, data ) )
			continue;

		//g_EngineFuncs.ClientPrintf( pPlayer, print_console, string( pTarget.pev.netname ) + " is connected from " + GetCountry( g_uiUserIP[iTarget] ) + "\n" );
		g_EngineFuncs.ClientPrintf( pPlayer, print_console, string( pTarget.pev.netname ) + " is connected from " + GetCountry( data.numip ) + "\n" );
	}
}

CClientCommand geoloc( "geoloc", "geoip", @ClCmdGeoLocation );

string GetCountry( uint ip )
{
	if ( (ip >> 24) & 0xFF == 10 || ( (ip >> 24) & 0xFF == 192 && (ip >> 16) & 0xFF == 168 ) )
		return "Slovakia";

	string szPart;
/*	snprintf( szPart, "%1.%2.%3", (ip >> 24) & 0xFF, (ip >> 16) & 0xFF, (ip >> 8) & 0xFF );

	uint uiFind = g_pPart2GeoIP.find( szPart );
	
	if ( uiFind < 0 || uiFind == Math.UINT32_MAX )
	{
		snprintf( szPart, "%1.%2", (ip >> 24) & 0xFF, (ip >> 16) & 0xFF );
		uiFind = g_pPartGeoIP.find( szPart );
	}*/
	
	snprintf( szPart, "%1.%2", (ip >> 24) & 0xFF, (ip >> 16) & 0xFF );
	uint uiFind = g_pPartGeoIP.find( szPart );
	
	if ( uiFind < 0 || uiFind == Math.UINT32_MAX )
		return "Unknown";

	GeoIP data;
	for ( uint uIndex = uiFind; uIndex < g_pGeoIPTest.length(); uIndex++ )
	{
		data = g_pGeoIPTest[uIndex];

		if ( ip >= data.min && ip <= data.max )
			return data.country;
	}
	
	return "Unknown";
}

string IntIPv4ToString( uint ip )
{
	string szIP;
	snprintf( szIP, "%1.%2.%3.%4", (ip >> 24) & 0xFF, (ip >> 16) & 0xFF, (ip >> 8) & 0xFF, ip & 0xFF );  
	return szIP;  
}

uint StringIPv4ToInt( const string& in szIP )
{
	array<string>@ ip = szIP.Split( '.' );
	return atoi( ip[3] ) | atoi( ip[2] ) << 8 | atoi( ip[1] ) << 16 | atoi( ip[0] ) << 24;
}
