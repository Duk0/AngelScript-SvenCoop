const float WAIT_TIME = 0.3;
array<float> g_flWaitTime( g_Engine.maxClients + 1, 0.0 );

const float BLOCK_RADIUS = 100.0;

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Josh \"JPolito\" Polito & Sam \"Solokiller\" Vanheer" );
	g_Module.ScriptInfo.SetContactInfo( "JPolito@svencoop.com" );
	g_Hooks.RegisterHook( Hooks::Player::ClientSay, @ClientSay );
	g_Hooks.RegisterHook( Hooks::Player::ClientDisconnect, @ClientDisconnect );
}

void MapInit()
{
	g_PlayerLocations.deleteAll();
	
	g_SoundSystem.PrecacheSound( "items/r_item1.wav" );
	g_SoundSystem.PrecacheSound( "items/r_item2.wav" );

//	for ( int iPlayer = 1; iPlayer <= g_Engine.maxClients; iPlayer++ )
//		g_flWaitTime[iPlayer] = g_Engine.time;

	g_flWaitTime = array<float>( g_Engine.maxClients + 1, g_Engine.time );
}

class PlayerLocationData
{
	Vector origin;
	float pitch, yaw;
	int classify;
	bool induck;
}

dictionary g_PlayerLocations;

HookReturnCode ClientSay( SayParameters@ pParams )
{
	CBasePlayer@ pPlayer = pParams.GetPlayer();
	const CCommand@ pArguments = pParams.GetArguments();
	
	if ( pArguments.ArgC() >= 1 )
	{
		string szArg = pArguments.Arg( 0 );
		szArg.Trim();
		szArg.ToLowercase();

		if ( szArg == "/s" )
		{
			pParams.ShouldHide = true; // Do not show this command in player chat

			if ( pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive() )
				return HOOK_HANDLED;

			int iPlayer = pPlayer.entindex();

			if ( g_Engine.time - g_flWaitTime[iPlayer] < WAIT_TIME )
				return HOOK_HANDLED;
			
			g_flWaitTime[iPlayer] = g_Engine.time;

			if ( pPlayer.m_afPhysicsFlags & PFLAG_ONBARNACLE != 0 )
			{
				g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "Cannot save while paralyzed!\n" );
				return HOOK_HANDLED;
			}
			
			
			Vector vecOrigin = pPlayer.GetOrigin();

			CBaseEntity@ pEntity = null;
			while ( ( @pEntity = g_EntityFuncs.FindEntityInSphere( pEntity, vecOrigin, BLOCK_RADIUS, "func_*", "classname" ) ) !is null )
			{
			//	if ( pEntity.GetClassname() == "func_rotating" && pEntity.pev.SpawnFlagBitSet( 64 ) ) // Not Solid
				if ( pEntity.pev.solid == SOLID_NOT )
					continue;

				g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "Your position can not be saved here.\n" );
			//	g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "m: " + pEntity.pev.model + " " + "Your position can not be saved here.\n" );
				return HOOK_HANDLED;
			}
/*
			Vector vecMins = vecOrigin.opAdd( pPlayer.pev.mins );
			Vector vecMaxs = vecOrigin.opAdd( pPlayer.pev.maxs );
			array<CBaseEntity@> pArray( 1 );
			int iRes = g_EntityFuncs.EntitiesInBox( pArray, vecMins, vecMaxs, FL_WORLDBRUSH );
			
			if ( iRes > 0 )
			{
				CBaseEntity@ pEntity = pArray[ 0 ];
				
				if ( pEntity !is null && pEntity.pev.solid != SOLID_NOT )
				{
					g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "Your position can not be saved here.\n" );
					return HOOK_HANDLED;
				}
			}
*/
			string szSteamId = g_EngineFuncs.GetPlayerAuthId( pPlayer.edict() ); // Assigns the player their SteamID
			PlayerLocationData data;

			data.origin = vecOrigin; // Saves the player origin
			// Saves the player angles
			data.pitch = pPlayer.pev.v_angle.x;
			data.yaw = pPlayer.pev.angles.y;
			data.classify = pPlayer.Classify();
			data.induck = pPlayer.pev.flags & FL_DUCKING != 0;
			g_PlayerLocations.set( szSteamId, data );
			g_SoundSystem.PlaySound( pPlayer.edict(), CHAN_STATIC, "items/r_item2.wav", 1.0f, 1.0f, 0, 100 ) ; // Play "Position saved" sound
			g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "Your saved position has been set to: " + data.origin.x + " " + data.origin.y + " " + data.origin.z + "\n" ); // Shows the player's coordinates in console

			return HOOK_HANDLED;
		}
		else if ( szArg == "/p" || szArg == "/t" )
		{
			pParams.ShouldHide = true; // Do not show this command in player chat

			if ( pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive() )
				return HOOK_HANDLED;

			int iPlayer = pPlayer.entindex();

			if ( g_Engine.time - g_flWaitTime[iPlayer] < WAIT_TIME )
				return HOOK_HANDLED;
			
			g_flWaitTime[iPlayer] = g_Engine.time;

			if ( pPlayer.m_afPhysicsFlags & PFLAG_ONBARNACLE != 0 )
				return HOOK_HANDLED;
			
			string szSteamId = g_EngineFuncs.GetPlayerAuthId( pPlayer.edict() );
			PlayerLocationData data;
			
			if ( !g_PlayerLocations.get( szSteamId, data ) )
			{
				g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "You did not save any location!\n" );
				return HOOK_HANDLED;
			}

			if ( data.classify != pPlayer.Classify() )
			{
				g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "Cannot teleport after team change!\n" );
				return HOOK_HANDLED;
			}

			CBaseEntity@ pEntity = null;
			while ( ( @pEntity = g_EntityFuncs.FindEntityInSphere( pEntity, data.origin, BLOCK_RADIUS, "func_*", "classname" ) ) !is null )
			{
				if ( pEntity.pev.solid == SOLID_NOT )
					continue;

				g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "Some object blocks your saved position.\n" );
				return HOOK_HANDLED;
			}
			
			@pEntity = null;
			while ( ( @pEntity = g_EntityFuncs.FindEntityInSphere( pEntity, data.origin, BLOCK_RADIUS, "player", "classname" ) ) !is null )
			{
				if ( pEntity is pPlayer )
					continue;

				g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "Some player blocks your saved position.\n" );
				return HOOK_HANDLED;
			}
/*
			Vector vecMins = data.origin.opAdd( pPlayer.pev.mins );
			Vector vecMaxs = data.origin.opAdd( pPlayer.pev.maxs );
			array<CBaseEntity@> pArray( 1 );
			int iRes = g_EntityFuncs.EntitiesInBox( pArray, vecMins, vecMaxs, FL_CLIENT|FL_MONSTER|FL_FAKECLIENT|FL_WORLDBRUSH );
			
			if ( iRes > 0 )
			{
				CBaseEntity@ pEntity = pArray[ 0 ];

				if ( pEntity !is null && pEntity.pev.solid != SOLID_NOT )
				{

					if ( pEntity.IsPlayer() )
						g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "Some player blocks your saved position.\n" );
					else
						g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "Some object blocks your saved position.\n" );
					
					return HOOK_HANDLED;
				}
			}
*/
			if ( data.induck )
			{
				//pPlayer.Duck();
				pPlayer.pev.flags |= FL_DUCKING;
				pPlayer.pev.view_ofs = Vector( 0.0, 0.0, 12.0 );
			//	pPlayer.pev.view_ofs.z -= 15;
			}
				
			if ( pPlayer.m_flFallVelocity > 200 )
				pPlayer.pev.velocity = pPlayer.pev.basevelocity = g_vecZero;

			pPlayer.SetOrigin( data.origin ); // Sets the player origin
			// Sets the player angles
			pPlayer.pev.angles = Vector( data.pitch, data.yaw, 0 ); // z = 0: Do a barrel roll, not
			pPlayer.pev.fixangle = FAM_FORCEVIEWANGLES; // Applies the player angles
			NetworkMessage message( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY ); // Begin "swirling cloud of particles" effect
			message.WriteByte( TE_TELEPORT );
			message.WriteCoord( data.origin.x );
			message.WriteCoord( data.origin.y );
			message.WriteCoord( data.origin.z );
			message.End(); // End "swirling cloud of particles" effect
			g_SoundSystem.PlaySound( pPlayer.edict(), CHAN_STATIC, "items/r_item1.wav", 1.0f, 1.0f, 0, 100 ); // Play "Position loaded" sound
			//g_Game.AlertMessage( at_console, "Sending Player \"%1\" to: " + data.origin.x + " " + data.origin.y + " " + data.origin.z + "\n", pPlayer.pev.netname ); // Shows the player's coordinates in console

			return HOOK_HANDLED;
		}
	}
	
	return HOOK_CONTINUE;
}

HookReturnCode ClientDisconnect( CBasePlayer@ pPlayer )
{
	if ( pPlayer is null )
		return HOOK_CONTINUE;

	string szSteamId = g_EngineFuncs.GetPlayerAuthId( pPlayer.edict() );
	if ( !g_PlayerLocations.exists( szSteamId ) )
		return HOOK_CONTINUE;

	//g_Game.AlertMessage( at_console, "Player \"%1\" has left. Deleting saved teleport data.\n", pPlayer.pev.netname ); // Shows which player's shit is getting deleted
	g_PlayerLocations.delete( szSteamId ); // Deletes location data from the dictionary for the player who disconnects

	return HOOK_CONTINUE;
}
