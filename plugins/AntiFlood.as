// vim: set ts=4 sw=4 tw=99 noet:
//
// AMX Mod X, based on AMX Mod by Aleksander Naszko ("OLO").
// Copyright (C) The AMX Mod X Development Team.
//
// This software is licensed under the GNU General Public License, version 3 or higher.
// Additional exceptions apply. For full license details, see LICENSE.txt or visit:
//     https://alliedmods.net/amxmodx-license

//
// Anti Flood Plugin
//

array<float> g_Flooding( g_Engine.maxClients + 1, 0.0 );
array<int> g_Flood( g_Engine.maxClients + 1, 0 );

CCVar@ g_pvFloodTime;

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "AMXX Dev Team|Duko" );
	g_Module.ScriptInfo.SetContactInfo( "group.midu.cz" );
	
	g_Hooks.RegisterHook( Hooks::Player::ClientSay, @ClientSay );

	@g_pvFloodTime = CCVar( "flood_time", 0.75 );
}

void MapInit()
{
	for ( int iPlayer = 1; iPlayer <= g_Engine.maxClients; ++iPlayer )
	{
		g_Flooding[ iPlayer ] = g_Engine.time;
		g_Flood[ iPlayer ] = 0;
	}
}

HookReturnCode ClientSay( SayParameters@ pParams )
{
	const CCommand@ pArguments = pParams.GetArguments();

	if ( pArguments.ArgC() < 1 )
		return HOOK_CONTINUE;

	CBasePlayer@ pPlayer = pParams.GetPlayer();

	if ( pPlayer is null || !pPlayer.IsConnected() )
		return HOOK_CONTINUE;
			
	float maxChat = g_pvFloodTime.GetFloat();

	if ( maxChat > 0 )
	{
		int iPlayer = pPlayer.entindex();

		float nexTime = g_Engine.time;
		
		if ( g_Flooding[ iPlayer ] > nexTime )
		{
			if ( g_Flood[ iPlayer ] >= 3 )
			{
				g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTNOTIFY, "** Stop flooding the server! **\n" );
				g_Flooding[ iPlayer ] = nexTime + maxChat + 3.0;
				pParams.ShouldHide = true;
				return HOOK_HANDLED;
			}
			g_Flood[ iPlayer ]++;
		}
		else if ( g_Flood[ iPlayer ] > 0 )
		{
			g_Flood[ iPlayer ]--;
		}
		
		g_Flooding[ iPlayer ] = nexTime + maxChat;
	}

	return HOOK_CONTINUE;
}
