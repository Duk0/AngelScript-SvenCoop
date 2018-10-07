array<string> g_pAllowedIPList = {
"192.168.0.0/16", "172.16.0.0/12", "10.0.0.0/8", // lan/local/internal ip
"x.x.x.x/18", "x.x.x.x" }; // external ip							

array<SubnetIP> g_pSubnetIP;

class SubnetIP
{
	uint ip;
	uint mask;
}

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Duko" );
	g_Module.ScriptInfo.SetContactInfo( "group.midu.cz" );
	
	g_Hooks.RegisterHook( Hooks::Player::ClientConnected, @ClientConnected );

	SubnetIP data;
	for ( uint uiIndex = 0; uiIndex < g_pAllowedIPList.length(); uiIndex++ )
	{
		array<string>@ subnet = g_pAllowedIPList[uiIndex].Split( '/' );
		data.ip = StringIPv4ToUInt( subnet[0] );
		
		if ( data.ip == 0 )
		{
			g_EngineFuncs.ServerPrint( "Bad format IP: " + g_pAllowedIPList[uiIndex] + "\n" );
			continue;
		}
		
		if ( subnet.length() == 2 )
			data.mask = atoui( subnet[1] );
		else
			data.mask = 24;
		
		if ( data.mask > 24 )
			data.mask = 24;
		
		// subnet less than 8 is too large, change if needed
		if ( data.mask < 8 )
			data.mask = 8;
	
		g_pSubnetIP.insertLast( data );
		
		g_EngineFuncs.ServerPrint( "IP: " + g_pAllowedIPList[uiIndex] + ", IP bits: " + data.ip + ", Mask len: " + data.mask + "\n" );
	}
}

HookReturnCode ClientConnected( edict_t@ pEdict, const string& in szPlayerName, const string& in szIPAddress, bool& out bDisallowJoin, string& out szRejectReason )
{
/*	// authid for ignore ip check
	string szSteamId = g_EngineFuncs.GetPlayerAuthId( pEdict );

	if ( szSteamId.Compare( "STEAM_0:1:23909265" ) == 0 || szSteamId.Compare( "STEAM_0:0:26180203" ) == 0 )
	{
		g_EngineFuncs.ServerPrint( "Allowed Auth Connection from: " + szSteamId + "\n" );
		return HOOK_CONTINUE;
	}
*/
	if ( szIPAddress.IsEmpty() )
		return HOOK_CONTINUE;

	array<string>@ ip = szIPAddress.Split( ':' );

	uint numip = StringIPv4ToUInt( ip[0] );
	
	SubnetIP data;
	for ( uint uiIndex = 0; uiIndex < g_pSubnetIP.length(); uiIndex++ )
	{
		data = g_pSubnetIP[uiIndex];
		
		if ( IsIPInRange( numip, data.ip, data.mask ) )
		{
		//	g_EngineFuncs.ServerPrint( "Connected IP: " + data.ip + ", Mask: " + data.mask + "\n" );
			g_EngineFuncs.ServerPrint( "Allowed IP Connection from: " + szIPAddress + "\n" );
			return HOOK_CONTINUE;
		}
	}

	bDisallowJoin = false;
	szRejectReason = "Only allowed IP can connect.";
	return HOOK_HANDLED;
}

bool IsIPInRange( uint ip_addr, uint net_addr, uint mask_len = 24 )
{
	uint ip_bits = ip_addr;
	uint net_bits = net_addr;
	//uint netmask = net_bits & ( (1 << mask_len) - 1 );
	uint netmask = net_bits & ( -1 << ( 32 - mask_len ) );
	
	//g_EngineFuncs.ServerPrint( "ip_bits " + ip_bits + ", net_bits " + net_bits + ", netmask " + netmask + ", mask_len " + mask_len + "\n" );
	
	return ( ip_bits & netmask ) == net_bits;
	//return ( ( ip_bits & netmask ) == ( net_bits & netmask ) );
}

/*
bool AllowedLan( uint ip )
{
	if ( (ip >> 24) & 0xFF == 10 || ( (ip >> 24) & 0xFF == 192 && (ip >> 16) & 0xFF == 168 ) )
		return true;
	
	return false;
}

string UIntIPv4ToString( uint ip )
{
	string szIP;
	snprintf( szIP, "%1.%2.%3.%4", (ip >> 24) & 0xFF, (ip >> 16) & 0xFF, (ip >> 8) & 0xFF, ip & 0xFF );  
	return szIP;  
}
*/

uint StringIPv4ToUInt( const string& in szIP )
{
	array<string>@ ip = szIP.Split( '.' );
	if ( ip.length() != 4 )
		return 0;

	return atoui( ip[3] ) | atoui( ip[2] ) << 8 | atoui( ip[1] ) << 16 | atoui( ip[0] ) << 24;
}

bool IsPlayerAdmin( CBasePlayer@ pPlayer )
{
	return g_PlayerFuncs.AdminLevel( pPlayer ) >= ADMIN_YES;
}
