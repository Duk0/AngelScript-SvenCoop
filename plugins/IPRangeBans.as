const string g_szIPBansFile = "scripts/plugins/store/iprangebans.dat";

array<SubnetBits> g_pSubnet;

class SubnetBits
{
	uint ip;
	uint mask;
}

string g_szLastIP = "0.0.0.0:27005";

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Duko" );
	g_Module.ScriptInfo.SetContactInfo( "group.midu.cz" );
	g_Module.ScriptInfo.SetMinimumAdminLevel( ADMIN_YES );
	
	g_Hooks.RegisterHook( Hooks::Player::ClientConnected, @ClientConnected );

	LoadBans();
}

void LoadBans()
{
	File@ pFile = g_FileSystem.OpenFile( g_szIPBansFile, OpenFile::READ );

	if ( pFile is null || !pFile.IsOpen() )
		return;

	string szLine;
	array<string>@ pSubnet;
	SubnetBits data;

	while ( !pFile.EOFReached() )
	{
		pFile.ReadLine( szLine );
		szLine.Trim();

		if ( szLine.IsEmpty() )
			continue;

		if ( szLine[0] == '/' && szLine[1] == '/' || szLine[0] == '#' || szLine[0] == ';' )
			continue;

		@pSubnet = szLine.Split( '/' );

		data.ip = IPToUInt( pSubnet[0] );
		
		if ( data.ip == 4294967295 )
		{
			g_EngineFuncs.ServerPrint( "Bad format IP: " + szLine + "\n" );
			continue;
		}
		
		if ( pSubnet.length() == 2 )
			data.mask = atoui( pSubnet[1] );
		else
			data.mask = 32;
		
		if ( data.mask > 32 )
			data.mask = 32;
	
		g_pSubnet.insertLast( data );
		
		g_EngineFuncs.ServerPrint( "IP: " + szLine + ", IP bits: " + data.ip + ", Mask bits: " + data.mask + "\n" );
	}
	
	pFile.Close();
}

HookReturnCode ClientConnected( edict_t@ pEdict, const string& in szPlayerName, const string& in szIPAddress, bool& out bDisallowJoin, string& out szRejectReason )
{
	if ( szIPAddress.Compare( g_szLastIP ) == 0 )
	{
		bDisallowJoin = false;
		szRejectReason = "You have been banned from this server!";
		return HOOK_HANDLED;
	}

	if ( szIPAddress.IsEmpty() )
	{
		bDisallowJoin = false;
		szRejectReason = "Client without IP address. (This should not happen)";
		return HOOK_HANDLED;
	}

	array<string>@ ip = szIPAddress.Split( ':' );

	uint ip_bits = IPToUInt( ip[0] );
	
	SubnetBits data;

	for ( uint uiIndex = 0; uiIndex < g_pSubnet.length(); uiIndex++ )
	{
		data = g_pSubnet[uiIndex];
		
		if ( IsIPInRange( ip_bits, data.ip, data.mask ) )
		{
			g_szLastIP = szIPAddress;

			bDisallowJoin = false;
			szRejectReason = "You have been banned from this server.";
			return HOOK_HANDLED;
		}
	}
	
	return HOOK_CONTINUE;
}

bool IsIPInRange( const uint& in ip_bits, const uint& in net_bits, const uint& in mask_len = 32 )
{
	uint netmask = mask_len != 0 ? 0XFFFFFFFF ^ ( ( 1 << 32 - mask_len ) - 1 ) : 0;

	return ( ( ip_bits & netmask ) == ( net_bits & netmask ) );
}

string UIntToIP( const uint& in ip )
{
	string szIP;
	snprintf( szIP, "%1.%2.%3.%4", (ip >> 24) & 0xFF, (ip >> 16) & 0xFF, (ip >> 8) & 0xFF, ip & 0xFF );  
	return szIP;  
}

uint IPToUInt( const string& in szIP )
{
	array<string>@ ip = szIP.Split( '.' );
	if ( ip.length() != 4 )
		return 4294967295;
	
	if ( !isdigit( ip[0] ) || !isdigit( ip[1] ) || !isdigit( ip[2] ) || !isdigit( ip[3] ) )
		return 4294967295;

	return atoui( ip[3] ) | atoui( ip[2] ) << 8 | atoui( ip[1] ) << 16 | atoui( ip[0] ) << 24;
}

void PrintToConsole( CBasePlayer@ pPlayer, const string& in szMessage )
{
	if ( pPlayer is null  )
		g_EngineFuncs.ServerPrint( szMessage );
	else
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, szMessage );
}

void AddIPRange( const CCommand@ args )
{
	CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();

	if ( pPlayer !is null && !pPlayer.IsConnected() )
		return;

	const string szIP = args.Arg( 1 );

	if ( szIP.IsEmpty() )
		return;

	array<string>@ pSubnet = szIP.Split( '/' );

	uint ip_bits = IPToUInt( pSubnet[0] );
	
	if ( ip_bits == 4294967295 )
		return;
	
	uint mask_bits = 32;

	if ( pSubnet.length() == 2 )
		mask_bits = atoui( pSubnet[1] );

	if ( mask_bits > 32 )
		mask_bits = 32;

	SubnetBits data;

	for ( uint uiIndex = 0; uiIndex < g_pSubnet.length(); uiIndex++ )
	{
		data = g_pSubnet[uiIndex];

		if ( mask_bits == 32 && data.mask == 32 && ip_bits == data.ip )
		{
			PrintToConsole( pPlayer, "IP: " + szIP + " is already banned\n" );
			return;
		}

		if ( ip_bits == data.ip && mask_bits == data.mask )
		{
			PrintToConsole( pPlayer, "IP Range: " + szIP + " is already banned\n" );
			return;
		}
		
		if ( IsIPInRange( ip_bits, data.ip, data.mask ) )
		{
			PrintToConsole( pPlayer, "IP: " + szIP + " is already banned in range: " + UIntToIP( data.ip ) + "/" + data.mask + "\n" );
			return;
		}
	}
	
	data.ip = ip_bits;
	data.mask = mask_bits;

	g_pSubnet.insertLast( data );


	File@ pFile = g_FileSystem.OpenFile( g_szIPBansFile, OpenFile::APPEND );

	if ( pFile is null || !pFile.IsOpen() )
		return;

	if ( mask_bits == 32 )
		pFile.Write( szIP + "/32\n" );
	else
		pFile.Write( szIP + "\n" );

	pFile.Close();
	
	PrintToConsole( pPlayer, "Banned IP: " + szIP + "\n" );
}

CConCommand addiprange( "addiprange", "AddIPRange", @AddIPRange ); // as_command .addiprange 192.168.0.0/24
CClientCommand addiprange_cl( "addiprange_cl", "AddIPRange", @AddIPRange );
