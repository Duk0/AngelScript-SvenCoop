dictionary g_dAuthIDs = {
{'STEAM_0:1:23909265', true},
{'STEAM_0:0:26180203', true}
};

array<string> g_pAllowedIP = {
"192.168.0.0/16", "172.16.0.0/12", "10.0.0.0/8", // Private network
//"100.64.0.0/10", // Private network
"127.0.0.0/8", // Host (for Bots)
//"0.0.0.0/8", // Software
//"0.0.0.0/0", // Whole Internet
"x.x.x.x/18", "x.x.x.x" }; // Internet

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
	
	g_Hooks.RegisterHook( Hooks::Player::ClientConnected, @ClientConnected );

	SubnetBits data;

	for ( uint uiIndex = 0; uiIndex < g_pAllowedIP.length(); uiIndex++ )
	{
		array<string>@ subnet = g_pAllowedIP[uiIndex].Split( '/' );
		data.ip = IPToUInt( subnet[0] );
		
		if ( data.ip == 4294967295 )
		{
			g_EngineFuncs.ServerPrint( "Bad format IP: " + g_pAllowedIP[uiIndex] + "\n" );
			continue;
		}
		
		if ( subnet.length() == 2 )
			data.mask = atoui( subnet[1] );
		else
			data.mask = 32;
		
		if ( data.mask > 32 )
			data.mask = 32;
		
		// bit-length of the prefix less than 8 is too large subnet, change if needed
		if ( data.mask < 8 )
			data.mask = 8;
	
		g_pSubnet.insertLast( data );
		
		g_EngineFuncs.ServerPrint( "IP: " + g_pAllowedIP[uiIndex] + ", IP bits: " + data.ip + ", Mask bits: " + data.mask + "\n" );
	}
}

HookReturnCode ClientConnected( edict_t@ pEdict, const string& in szPlayerName, const string& in szIPAddress, bool& out bDisallowJoin, string& out szRejectReason )
{
	if ( szIPAddress.Compare( g_szLastIP ) == 0 )
	{
		bDisallowJoin = false;
		szRejectReason = "Your IP address is NOT allowed to join here!";
		return HOOK_HANDLED;
	}

	// authid for ignore ip check
	string szSteamId = g_EngineFuncs.GetPlayerAuthId( pEdict );

	if ( g_dAuthIDs.exists( szSteamId ) )
	{
		g_EngineFuncs.ServerPrint( "Allowed Auth Connection from: " + szSteamId + "\n" );
		return HOOK_CONTINUE;
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
			g_EngineFuncs.ServerPrint( "Allowed IP Connection from: " + szIPAddress + "\n" );
			return HOOK_CONTINUE;
		}
	}
	
	g_szLastIP = szIPAddress;

	bDisallowJoin = false;
	szRejectReason = "Only allowed IP address can join.";
	return HOOK_HANDLED;
}

bool IsIPInRange( const uint& in ip_bits, const uint& in net_bits, const uint& in mask_len = 32 )
{
	uint netmask = mask_len != 0 ? 0XFFFFFFFF ^ ( ( 1 << 32 - mask_len ) - 1 ) : 0;

	return ( ( ip_bits & netmask ) == ( net_bits & netmask ) );
}

/*
bool AllowedLan( const uint& in ip )
{
	if ( (ip >> 24) & 0xFF == 10 || ( (ip >> 24) & 0xFF == 192 && (ip >> 16) & 0xFF == 168 ) )
		return true;
	
	return false;
}
*/

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

uint MaskBitsToUIntNetmask( const uint& in mask_bits )
{
/*	string szNetmask;
	
	switch ( mask_bits )
	{
		case 0: szNetmask = "0.0.0.0"; break;
		case 1: szNetmask = "128.0.0.0"; break;
		case 2: szNetmask = "192.0.0.0"; break;
		case 3: szNetmask = "224.0.0.0"; break;
		case 4: szNetmask = "240.0.0.0"; break;
		case 5: szNetmask = "248.0.0.0"; break;
		case 6: szNetmask = "252.0.0.0"; break;
		case 7: szNetmask = "254.0.0.0"; break;
		case 8: szNetmask = "255.0.0.0"; break;
		case 9: szNetmask = "255.128.0.0"; break;
		case 10: szNetmask = "255.192.0.0"; break;
		case 11: szNetmask = "255.224.0.0"; break;
		case 12: szNetmask = "255.240.0.0"; break;
		case 13: szNetmask = "255.248.0.0"; break;
		case 14: szNetmask = "255.252.0.0"; break;
		case 15: szNetmask = "255.254.0.0"; break;
		case 16: szNetmask = "255.255.0.0"; break;
		case 17: szNetmask = "255.255.128.0"; break;
		case 18: szNetmask = "255.255.192.0"; break;
		case 19: szNetmask = "255.255.224.0"; break;
		case 20: szNetmask = "255.255.240.0"; break;
		case 21: szNetmask = "255.255.248.0"; break;
		case 22: szNetmask = "255.255.252.0"; break;
		case 23: szNetmask = "255.255.254.0"; break;
		case 24: szNetmask = "255.255.255.0"; break;
		case 25: szNetmask = "255.255.255.128"; break;
		case 26: szNetmask = "255.255.255.192"; break;
		case 27: szNetmask = "255.255.255.224"; break;
		case 28: szNetmask = "255.255.255.240"; break;
		case 29: szNetmask = "255.255.255.248"; break;
		case 30: szNetmask = "255.255.255.252"; break;
		case 31: szNetmask = "255.255.255.254"; break;
		case 32: szNetmask = "255.255.255.255"; break;
		default: szNetmask = "255.255.255.255"; break;
	}
	
	array<string>@ netmask = szNetmask.Split( '.' );
	
	return atoui( netmask[3] ) | atoui( netmask[2] ) << 8 | atoui( netmask[1] ) << 16 | atoui( netmask[0] ) << 24;
*/
	switch ( mask_bits )
	{
		case 0: return 0;
		case 1: return 2147483648;
		case 2: return 3221225472;
		case 3: return 3758096384;
		case 4: return 4026531840;
		case 5: return 4160749568;
		case 6: return 4227858432;
		case 7: return 4261412864;
		case 8: return 4278190080;
		case 9: return 4286578688;
		case 10: return 4290772992;
		case 11: return 4292870144;
		case 12: return 4293918720;
		case 13: return 4294443008;
		case 14: return 4294705152;
		case 15: return 4294836224;
		case 16: return 4294901760;
		case 17: return 4294934528;
		case 18: return 4294950912;
		case 19: return 4294959104;
		case 20: return 4294963200;
		case 21: return 4294965248;
		case 22: return 4294966272;
		case 23: return 4294966784;
		case 24: return 4294967040;
		case 25: return 4294967168;
		case 26: return 4294967232;
		case 27: return 4294967264;
		case 28: return 4294967280;
		case 29: return 4294967288;
		case 30: return 4294967292;
		case 31: return 4294967294;
		case 32: return 4294967295;
		default: return 4294967295;
	}
	
	return 0;
}


void TestIP( const CCommand@ args )
{
	const string szIP = args.Arg( 1 );

	if ( szIP.IsEmpty() )
		return;

	array<string>@ ip = szIP.Split( ':' );

	uint ip_bits = IPToUInt( ip[0] );

	SubnetBits data;
	for ( uint uiIndex = 0; uiIndex < g_pSubnet.length(); uiIndex++ )
	{
		data = g_pSubnet[uiIndex];
		
		if ( IsIPInRange( ip_bits, data.ip, data.mask ) )
		{
			g_EngineFuncs.ServerPrint( "IP: " + szIP + " is in range: " + UIntToIP( data.ip ) + "/" + data.mask + "\n" );
			return;
		}
	}
	
	g_EngineFuncs.ServerPrint( "IP: " + szIP + " is NOT in ranges\n" );
}

void TestMask( const CCommand@ args )
{
	const string szNetmask = args.Arg( 1 );

	if ( szNetmask.IsEmpty() )
		return;

	uint mask_bits = atoui( szNetmask );
	
	if ( mask_bits > 32 )
		return;

	uint netmask = mask_bits != 0 ? 0XFFFFFFFF ^ ( ( 1 << 32 - mask_bits ) - 1 ) : 0;
	
	g_EngineFuncs.ServerPrint( "MaskBitsToUIntNetmask: " + MaskBitsToUIntNetmask( mask_bits ) + ", netmask: " + netmask + ( ( MaskBitsToUIntNetmask( mask_bits ) == netmask ) ? ", Values are equals" : "" ) + "\n" );
}

CConCommand ipinrange( "ipinrange", "IP in range", @TestIP ); // as_command .ipinrange 91.125.128.0
CConCommand netmask( "netmask", "Netmask", @TestMask ); // as_command .netmask 12
