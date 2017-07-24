//const Cvar@ g_pvHostname;
string g_szHostname;
dictionary g_dWelcomed;
array<CScheduledFunction@> g_pWelcomeMsgFunction( g_Engine.maxClients + 1, null );
bool g_bXMas = false;
bool g_bNewYear = false;

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Parakeet|Duko" );
	g_Module.ScriptInfo.SetContactInfo( "group.midu.cz" );

	g_Hooks.RegisterHook( Hooks::Player::ClientPutInServer, @ClientPutInServer );
	g_Hooks.RegisterHook( Hooks::Player::ClientDisconnect, @ClientDisconnect );
	g_Hooks.RegisterHook( Hooks::Game::MapChange, @MapChange );

	//@g_pvHostname = g_EngineFuncs.CVarGetPointer( "hostname" );
}

/*
void MapInit()
{
	g_SoundSystem.PrecacheSound( "scientist/goodtoseeyou.wav" );
	g_SoundSystem.PrecacheSound( "scientist/greetings.wav" );
	g_SoundSystem.PrecacheSound( "scientist/greetings2.wav" );
	//g_SoundSystem.PrecacheSound( "scientist/hello2.wav" );
	//g_SoundSystem.PrecacheSound( "scientist/hellofreeman.wav" );
	g_SoundSystem.PrecacheSound( "scientist/hellothere.wav" );
}
*/

void MapStart()
{
	g_Scheduler.SetTimeout( "CheckPlayers", 180.3 );

	DateTime time;
	int iMonth = time.GetMonth();
	int iDay = time.GetDayOfMonth();

	if ( iMonth == 12 )
	{
		switch ( iDay )
		{
			case 24:
			case 25:
			case 26: g_bXMas = true; break;
		}
	}
	
	if ( iMonth == 1 && iDay == 1 )
		g_bNewYear = true;
}

HookReturnCode ClientPutInServer( CBasePlayer@ pPlayer )
{
	if ( pPlayer is null || ( pPlayer.pev.flags & FL_FAKECLIENT ) != 0 )
		return HOOK_CONTINUE;

	string szSteamId = g_EngineFuncs.GetPlayerAuthId( pPlayer.edict() );
	float flWelcomeTime = 15.0;

	if ( g_dWelcomed.exists( szSteamId ) )
		flWelcomeTime = 10.0;

	int iPlayer = pPlayer.entindex();

	if ( g_pWelcomeMsgFunction[ iPlayer ] !is null && !g_pWelcomeMsgFunction[ iPlayer ].HasBeenRemoved() )
		g_Scheduler.RemoveTimer( g_pWelcomeMsgFunction[ iPlayer ] );

	@g_pWelcomeMsgFunction[ iPlayer ] = g_Scheduler.SetTimeout( "WelcomeMsg", flWelcomeTime, iPlayer );

	return HOOK_CONTINUE;
}

HookReturnCode ClientDisconnect( CBasePlayer@ pPlayer )
{
	if ( pPlayer is null )
		return HOOK_CONTINUE;

	int iPlayer = pPlayer.entindex();

	if ( g_pWelcomeMsgFunction[ iPlayer ] !is null && !g_pWelcomeMsgFunction[ iPlayer ].HasBeenRemoved() )
		g_Scheduler.RemoveTimer( g_pWelcomeMsgFunction[ iPlayer ] );

	string szSteamId = g_EngineFuncs.GetPlayerAuthId( pPlayer.edict() );

	if ( g_dWelcomed.exists( szSteamId ) )
		g_dWelcomed.delete( szSteamId );

	return HOOK_CONTINUE;
}

HookReturnCode MapChange()
{
/*	for ( int iPlayer = 1; iPlayer <= g_Engine.maxClients; ++iPlayer )
	{
		if ( g_pWelcomeMsgFunction[ iPlayer ] !is null )
			g_Scheduler.RemoveTimer( g_pWelcomeMsgFunction[ iPlayer ] );
	}*/
	
	g_Scheduler.ClearTimerList();

	g_bXMas = false;
	g_bNewYear = false;

	return HOOK_CONTINUE;
}

void WelcomeCmd( const CCommand@ args )
{
	CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();
	
	if ( pPlayer is null || !pPlayer.IsConnected() )
		return;
	
	WelcomeMsg( pPlayer.entindex() );
}

CClientCommand welcome( "welcome", "Welcome Command", @WelcomeCmd );

void WelcomeMsg( int iPlayer )
{
	CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );

	if ( pPlayer is null || !pPlayer.IsConnected() )
		return;

	string name = pPlayer.pev.netname;
	string szSteamId = g_EngineFuncs.GetPlayerAuthId( pPlayer.edict() );
	string szSound = "scientist/hellothere(v70)";
	
	if ( g_bXMas )
		szSound = "tfc/misc/b2(v70)";

	if ( g_bNewYear )
		szSound = "vox/have(e45) pipe(e10) yankee(s65) number(e10) you year";

	if ( g_dWelcomed.exists( szSteamId ) )
	{
		string mapname = g_Engine.mapname;

		g_PlayerFuncs.HudMessage( pPlayer, SetHudMessage(), "Glad to see you again, " + name + "\nHave fun on: " + mapname + "!" );
  		g_EngineFuncs.ClientPrintf( pPlayer, print_console, "* Glad to see you again, " + name + "\n* Have fun on: " + mapname + "!\n" );

		switch ( Math.RandomLong( 0, 2 ) )
		{
			case 0: szSound = "scientist/goodtoseeyou"; break;
			case 1: szSound = "scientist/greetings"; break;
			case 2: szSound = "scientist/greetings2"; break;
		//	case 3: szSound = "scientist/hello2"; break;
		}
		
		szSound += "(v50)";
	}
	else 
	{
		g_szHostname = g_EngineFuncs.CVarGetString( "hostname" );

		g_PlayerFuncs.HudMessage( pPlayer, SetHudMessage(), "Hey, " + name + "\nWelcome to " + g_szHostname + "!" );

		g_dWelcomed.set( szSteamId, true );

		if ( g_PlayerFuncs.AdminLevel( pPlayer ) >= ADMIN_YES )
		{
			if ( g_pWelcomeMsgFunction[ iPlayer ] !is null && !g_pWelcomeMsgFunction[ iPlayer ].HasBeenRemoved() )
				g_Scheduler.RemoveTimer( g_pWelcomeMsgFunction[ iPlayer ] );

			@g_pWelcomeMsgFunction[ iPlayer ] = g_Scheduler.SetTimeout( "AdminMsg", 10.0, iPlayer );
		}
	}

	//PlaySoundToPlayer( pPlayer, szSound + ".wav" );
	//g_SoundSystem.PlaySound( pPlayer.edict(), CHAN_STATIC, szSound + ".wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM, iPlayer );

	NetworkMessage message( MSG_ONE, NetworkMessages::Speaksent, g_vecZero, pPlayer.edict() );
	message.WriteString( ";spk \"" + szSound + "\"" );
	message.End();
}

void AdminMsg( int iPlayer )
{
	CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );

	if ( pPlayer is null || !pPlayer.IsConnected() )
		return;

	if ( g_szHostname.IsEmpty() )
		g_szHostname = g_EngineFuncs.CVarGetString( "hostname" );

	g_PlayerFuncs.HudMessage( pPlayer, SetHudMessage(), "You have Admin's flags\nEnforce the law on " + g_szHostname + "!" );

	string szName = pPlayer.pev.netname;
	string szSoundMsg;

	if ( szName == "Duko"  )
		szSoundMsg = "vox/(v65) do(e60) code(e40) is(e100) supercooled";
	else if ( szName == "Miko"  )
		szSoundMsg = "vox/minutes(e35) code(e40) is(e100) supercooled";
	else if ( szName == "jas[Alpha]"  )
		szSoundMsg = "vox/india(s50) yes(s87) _comma(e40) is(e100) supercooled";
	
	if ( !szSoundMsg.IsEmpty() )
	{
		NetworkMessage message( MSG_ALL, NetworkMessages::Speaksent );
		message.WriteString( ";spk \"" + szSoundMsg + "\"" );
		message.End();
	}
}

//set_hudmessage(red=200, green=100, blue=0, Float:x=-1.0, Float:y=0.35, effects=0, Float:fxtime=6.0, Float:holdtime=12.0, Float:fadeintime=0.1, Float:fadeouttime=0.2,channel=4);
HUDTextParams SetHudMessage()
{
	HUDTextParams hudTxtParam;
		
	hudTxtParam.r1 = 20;
	hudTxtParam.g1 = 200;
	hudTxtParam.b1 = 110;
	hudTxtParam.a1 = 0;

	hudTxtParam.r2 = 255;
	hudTxtParam.g2 = 255;
	hudTxtParam.b2 = 250;
	hudTxtParam.a2 = 0;

	hudTxtParam.x = 0.04;
	hudTxtParam.y = 0.40;

	hudTxtParam.effect = 2;

	hudTxtParam.fxTime = 0.03;
	hudTxtParam.holdTime = 6.0;
				
	hudTxtParam.fadeinTime = 0.03;
	hudTxtParam.fadeoutTime = 0.1;

	hudTxtParam.channel = 5;

	return hudTxtParam;
}
/*
void PlaySoundToPlayer( CBasePlayer@ pPlayer, const string& in szSample )
{
	dictionary pDictionary = { { 'message', szSample }, { 'health', '10' }, { 'playmode', '1' }, { 'spawnflags', '64' } };
	CBaseEntity@ pEntity = g_EntityFuncs.CreateDefaultEntity( "ambient_generic", pDictionary, true );
	if ( pEntity !is null )
	{
		pEntity.Use( pPlayer, null, USE_ON );
		g_EntityFuncs.Remove( pEntity );
	}
}
*/

void CheckPlayers()
{
	if ( g_PlayerFuncs.GetNumPlayers() == 0 && !g_dWelcomed.isEmpty() )
		g_dWelcomed.deleteAll();
}
