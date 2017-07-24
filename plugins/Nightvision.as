//Version 1.1
//CScheduledFunction@ g_pNVThinkFunc = null;
array<bool> g_bPlayerNV( g_Engine.maxClients + 1, false );
const Vector g_vecNVColor( 0, 255, 0 );
const int g_iRadius = 40;
const int g_iDecay = 1;
const int g_iLife = 2;

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Nero" );
	g_Module.ScriptInfo.SetContactInfo( "Nero @ Svencoop forums" );
  
	g_Hooks.RegisterHook( Hooks::Player::PlayerKilled, @PlayerKilled );
	g_Hooks.RegisterHook(Hooks::Player::ClientDisconnect, @ClientDisconnect);
	g_Hooks.RegisterHook(Hooks::Player::ClientPutInServer, @ClientPutInServer);
	g_Hooks.RegisterHook( Hooks::Game::MapChange, @MapChange );
}

CClientCommand nightvision( "nightvision", "Toggles night vision on/off", @ToggleNV );

void MapInit()
{
	g_SoundSystem.PrecacheSound( "player/hud_nightvision.wav" );
}

void MapStart()
{
	for ( int iPlayer = 1; iPlayer <= g_Engine.maxClients; ++iPlayer )
		g_bPlayerNV[iPlayer] = false;

	g_Scheduler.SetInterval( "nvThink", 0.02f );
}

void ToggleNV( const CCommand@ args )
{
	CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();

	if ( pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive() )
		return;
		
	if ( pPlayer.m_afPhysicsFlags & PFLAG_CAMERA != 0 )
		return;
 
	int iPlayer = pPlayer.entindex();

	if ( g_bPlayerNV[iPlayer] )
	{
		removeNV( pPlayer );
	}
	else
	{
		if ( pPlayer.FlashlightIsOn() )
			pPlayer.FlashlightTurnOff();

		g_PlayerFuncs.ScreenFade( pPlayer, g_vecNVColor, 0.01, 0.5, 128, FFADE_OUT | FFADE_STAYOUT);
		g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_WEAPON, "player/hud_nightvision.wav", 1.0, ATTN_NORM, 0, PITCH_NORM );
	}
		
	g_bPlayerNV[iPlayer] = !g_bPlayerNV[iPlayer];
}

void nvMsg( CBasePlayer@ pPlayer )
{
	Vector vecSrc = pPlayer.EyePosition();

	NetworkMessage nvon( MSG_ONE, NetworkMessages::SVC_TEMPENTITY, pPlayer.edict() );
	nvon.WriteByte( TE_DLIGHT );
	nvon.WriteCoord( vecSrc.x );
	nvon.WriteCoord( vecSrc.y );
	nvon.WriteCoord( vecSrc.z );
	nvon.WriteByte( uint8( g_iRadius ) );
	nvon.WriteByte( uint8( g_vecNVColor.x ) );
	nvon.WriteByte( uint8( g_vecNVColor.y ) );
	nvon.WriteByte( uint8( g_vecNVColor.z ) );
	nvon.WriteByte( uint8( g_iLife ) );
	nvon.WriteByte( uint8( g_iDecay ) );
	nvon.End();
}

void removeNV( CBasePlayer@ pPlayer )
{
	g_PlayerFuncs.ScreenFade( pPlayer, g_vecNVColor, 0.01, 0.5, 128, FFADE_IN );
	g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_WEAPON, "player/hud_nightvision.wav", 0.8, ATTN_NORM, 0, PITCH_LOW );
}

HookReturnCode ClientDisconnect( CBasePlayer@ pPlayer )
{
	if ( pPlayer is null )
		return HOOK_CONTINUE;

	int iPlayer = pPlayer.entindex();

	if ( g_bPlayerNV[iPlayer] )
	{
		removeNV( pPlayer );
		g_bPlayerNV[iPlayer] = false;
	}
 
	return HOOK_CONTINUE;
}

HookReturnCode ClientPutInServer( CBasePlayer@ pPlayer )
{
	if ( pPlayer is null )
		return HOOK_CONTINUE;

	int iPlayer = pPlayer.entindex();

	if ( g_bPlayerNV[iPlayer] )
	{
		removeNV( pPlayer );
		g_bPlayerNV[iPlayer] = false;
	}
 
	return HOOK_CONTINUE;
}

HookReturnCode PlayerKilled( CBasePlayer@ pPlayer, CBaseEntity@ pAttacker, int iGib )
{
	if ( pPlayer is null )
		return HOOK_CONTINUE;

	int iPlayer = pPlayer.entindex();

	if ( g_bPlayerNV[iPlayer] )
	{
		removeNV( pPlayer );
		g_bPlayerNV[iPlayer] = false;
	}
 
	return HOOK_CONTINUE;
}

HookReturnCode MapChange()
{
	g_Scheduler.ClearTimerList();

	return HOOK_CONTINUE;
}

void nvThink()
{
	for ( int iPlayer = 1; iPlayer <= g_Engine.maxClients; ++iPlayer )
	{
		CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );

		if ( pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive() )
			continue;

		if ( !g_bPlayerNV[iPlayer] )
			continue;
			
		if ( pPlayer.m_afPhysicsFlags & PFLAG_CAMERA != 0 )
		{
			removeNV( pPlayer );
			g_bPlayerNV[iPlayer] = false;
			continue;
		}
		
		nvMsg( pPlayer );
	}
}
