/***********************************************************************************\
*    Hook By P34nut    *    Thanks to Joka69, Chaosphere for testing and stuff!	    *
*************************************************************************************
* Commands/ bindings:	       
*	.+hook to throw the hook  
*	.-hook to delete your hook
*	Before use hook put in console:
*	alias +hook .+hook
*	alias -hook .-hook
* 
* Cvars:
*	.hookenable - Turns hook on or off 
*	.hookthrowspeed - Throw speed (default: 1000)
*	.hookspeed - Speed to hook (default: 300)
*	.hookwidth - Width of the hook (default: 32)
*	.hooksound - Sounds of the hook on or off (default: 1)
*	.hookcolor - The color of the hook 0 is white and 1 is team color (default: 1)
*	.hookplayers - If set 1 you can hook on players (default: 0)
*	.hookinterrupt - Remove the hook when something comes in its line (default: 0)
*	.hookadminonly - Hook for admin only (default: 0)
*	.hooksky - If set 1 you can hook in the sky (default: 0)
*	.hookopendoors - If set 1 you can open doors with the hook (default: 1)
*	.hookbuttons - If set 1 you can use buttons with the hook (default: 0)
*	.hookpickweapons - If set 1 you can pickup weapons with the hook (default: 1)
*	.hookhostflollow - If set 1 you can make hostages follow you (default 1)
*	.hookinstant - Hook doesnt throw (default: 0)
*	.hooknoise - adds some noise to the hook line (default: 0)
*	.hookmax - Maximun numbers of hooks a player can use per map
*		   - 0 for infinitive hooks (default: 0)
*	.hookdelay - Delay on the start map before a player can hook
*			     - 0.0 for no delay (default: 0.0)
*
* ChangeLog:
*	1.0: Release
*	1.5: added cvars:
*		.hooknoise
*		.hookmax
*		.hookdelay
*		public cvar: as_hookmod //todo
*	     added client admin commands:
*		.givehook <username>
*		.takehook <username>
*	1.5.1: Ported to Sven Co-op AngelScript by Duko (s highly experimental plugin)
*
\***********************************************************************************/

/*
as_reloadplugin HookMod
as_command .hookinstant 1
as_command .hookinterrupt 1
*/

//Cvars
CCVar@ g_pCVarHookEnable, g_pCVarThrowSpeed, g_pCVarSpeed, g_pCVarWidth, g_pCVarSound, g_pCVarColor;
CCVar@ g_pCVarInterrupt, g_pCVarAdmin, g_pCVarHookSky, g_pCVarOpenDoors, g_pCVarPlayers;
CCVar@ g_pCVarUseButtons, g_pCVarMonster, g_pCVarWeapons, g_pCVarInstant, g_pCVarHookNoise;
CCVar@ g_pCVarMaxHooks, g_pCVarMapStartDelay;

// some booleans
array<bool> g_bHooked( g_Engine.maxClients + 1, false );
array<bool> g_bCanThrowHook( g_Engine.maxClients + 1, true );
bool g_bMapStarted = true;
bool g_bWorkaroundFollow = true; // for testing change to false (recomended true)

array<int> g_iHooksUsed( g_Engine.maxClients + 1, 0 ); // Used with .hookmax
array<bool> g_bHookAllowed( g_Engine.maxClients + 1, false ); // Used with .hookadminonly

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "P34nut|Duko" ); // ver. 1.5.1
	g_Module.ScriptInfo.SetContactInfo( "group.midu.cz" );
	//g_Module.ScriptInfo.SetMinimumAdminLevel( ADMIN_YES );
	
	g_Hooks.RegisterHook( Hooks::Player::PlayerKilled, @PlayerKilled );
	g_Hooks.RegisterHook( Hooks::Player::PlayerSpawn, @PlayerSpawn );
	g_Hooks.RegisterHook( Hooks::Game::MapChange, @MapChange );
	
	// Register cvars
	//register_cvar("as_hookmod",  "version 1.5.1", FCVAR_SERVER) // yay public cvar // need something for sc
	@g_pCVarHookEnable = 	CCVar( "hookenable", 1, "Turns hook on or off" );
	@g_pCVarThrowSpeed = 	CCVar( "hookthrowspeed", 1000, "Throw speed (default: 1000)" );
	@g_pCVarSpeed = 		CCVar( "hookspeed", 300, "Speed to hook (default: 300)" );
	@g_pCVarWidth = 		CCVar( "hookwidth", 16, "Width of the hook (default: 32)" );
	@g_pCVarSound = 		CCVar( "hooksound", 1, "Sounds of the hook on or off (default: 1)" );
	@g_pCVarColor =			CCVar( "hookcolor", 1, "The color of the hook 0 is white and 1 is glow color (default: 1)" );
	@g_pCVarPlayers = 		CCVar( "hookplayers", 0, "If set 1 you can hook on players (default: 0)" );
	@g_pCVarInterrupt = 	CCVar( "hookinterrupt", 0, "Remove the hook when something comes in its line (default: 0)" );
	@g_pCVarAdmin = 		CCVar( "hookadminonly", 1, "Hook for admin only (default: 0)" );
	@g_pCVarHookSky = 		CCVar( "hooksky", 0, "If set 1 you can hook in the sky (default: 0)" );
	@g_pCVarOpenDoors = 	CCVar( "hookopendoors", 1, "If set 1 you can open doors with the hook (default: 1)" );
	@g_pCVarUseButtons = 	CCVar( "hookusebuttons", 1, "If set 1 you can use buttons with the hook (default: 0)" );
	@g_pCVarMonster = 		CCVar( "hookmonsterflollow", 1, "If set 1 you can make ally monsters follow you (default 1)" );
	@g_pCVarWeapons =		CCVar( "hookpickweapons", 1, "If set 1 you can pickup weapons with the hook (default: 1)" );
	@g_pCVarInstant =		CCVar( "hookinstant", 0, "Hook doesnt throw (default: 0)" );
	@g_pCVarHookNoise = 	CCVar( "hooknoise", 0, "adds some noise to the hook line (default: 0)" );
	@g_pCVarMaxHooks = 		CCVar( "hookmax", 50, "Maximun numbers of hooks a player can use per map - 0 for infinitive hooks (default: 0)" );
	@g_pCVarMapStartDelay = CCVar( "hookmapstartdelay", 5.0, "Delay on the start map before a player can hook - 0.0 for no delay (default: 0.0)" );
}

// Hook commands
CClientCommand plushook( "+hook", "- to throw the hook", @make_hook );
CClientCommand minushook( "-hook", "- to delete your hook", @del_hook );

CClientCommand givehook( "givehook", "<username> - Give somebody access to the hook", @give_hook );
CClientCommand takehook( "takehook", "<userName> - Take away somebody his access to the hook", @take_hook );

HookReturnCode PlayerKilled( CBasePlayer@ pPlayer, CBaseEntity@ pAttacker, int iGib )
{
	if ( pPlayer is null || !pPlayer.IsConnected() )
		return HOOK_CONTINUE;

	int iPlayer = pPlayer.entindex();

	if ( iPlayer > 0 && !g_bCanThrowHook[iPlayer] )
		remove_hook( pPlayer, iPlayer );

	return HOOK_CONTINUE;
}

HookReturnCode PlayerSpawn( CBasePlayer@ pPlayer )
{
	if ( pPlayer is null || !pPlayer.IsConnected() )
		return HOOK_CONTINUE;

	int iPlayer = pPlayer.entindex();

	if ( g_pCVarMaxHooks.GetInt() > 0 && iPlayer > 0 && g_iHooksUsed[iPlayer] != 0 )
	{
		g_iHooksUsed[iPlayer] = 0;
		//g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "[Hook] 0 of " + g_pCVarMaxHooks.GetInt() + " hooks used.\n" );
	}

	return HOOK_CONTINUE;
}

HookReturnCode MapChange( const string& in szNextMap )
{
	g_Scheduler.ClearTimerList();
	
	g_bMapStarted = false;
	
	return HOOK_CONTINUE;
}

void MapInit()
{
	// Hook Model
	g_Game.PrecacheModel( "models/crossbow_bolt.mdl" );
	
	// Hook Beam
	g_Game.PrecacheModel( "sprites/zbeam4.spr" );
	
	// Hook Sounds
	g_SoundSystem.PrecacheSound( "weapons/xbow_hit1.wav" ); // good hit
	g_SoundSystem.PrecacheSound( "weapons/xbow_hit2.wav" ); // wrong hit
	g_SoundSystem.PrecacheSound( "weapons/xbow_hitbod1.wav" ); // player hit
	g_SoundSystem.PrecacheSound( "weapons/xbow_fire1.wav" ); // deploy

	g_bHooked = array<bool>( g_Engine.maxClients + 1, false );
	g_bCanThrowHook = array<bool>( g_Engine.maxClients + 1, true );
	g_iHooksUsed = array<int>( g_Engine.maxClients + 1, 0 );
	//g_bHookAllowed = array<bool>( g_Engine.maxClients + 1, false ); // uncomment if need reset
	
	float fDelay = g_pCVarMapStartDelay.GetFloat();
	if ( fDelay > 0.0 )
		g_Scheduler.SetTimeout( "mapStartDelay", fDelay );
	else
		g_bMapStarted = true;
		
	g_CustomEntityFuncs.RegisterCustomEntity( "script_hook", "script_hook" );
}

void mapStartDelay()
{
	if ( !g_bMapStarted )
		g_bMapStarted = true;
}

void make_hook( const CCommand@ args )
{
	CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();

	if ( pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive() )
		return;
		
	int iPlayer = pPlayer.entindex();

	if ( g_pCVarHookEnable.GetBool() && g_bCanThrowHook[iPlayer] && !g_bHooked[iPlayer] )
	{		
		if ( g_pCVarAdmin.GetBool() )
		{
			// Only the admins can throw the hook	
			if ( !IsPlayerAdmin( pPlayer ) && !g_bHookAllowed[iPlayer] )
			{
				// Show a message
				g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "[Hook] You have no access to that command\n" );
				return;
			}
		}
		
		int iMaxHooks = g_pCVarMaxHooks.GetInt();
		if ( iMaxHooks > 0 )
		{
			if ( g_iHooksUsed[iPlayer] >= iMaxHooks )
			{
				g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "[Hook] You already used your maximum ammount (" + iMaxHooks + ") of hooks\n" );
				return;
			}
		/*	else 
				g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "[Hook] " + g_iHooksUsed[iPlayer] + " of " + iMaxHooks + " hooks used.\n" );*/
		}

		float fDelay = g_pCVarMapStartDelay.GetFloat();
		if ( fDelay > 0 && !g_bMapStarted )
		{
			g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "[Hook] You cannot use the hook in the first " + fDelay + " seconds\n" );
			return;
		}
			
		throw_hook( pPlayer, iPlayer );
	}
}

void del_hook( const CCommand@ args )
{
	CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();

	if ( pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive() )
		return;

	int iPlayer = pPlayer.entindex();

	// Remove players hook
	if ( !g_bCanThrowHook[iPlayer] )
		remove_hook( pPlayer, iPlayer );
}

void throw_hook( CBasePlayer@ pPlayer, int iPlayer )
{
	// Get origin and angle for the hook
	Vector vecOrigin = pPlayer.GetOrigin();
	Vector vecAngle = pPlayer.pev.angles;
	Vector vecVAngle = pPlayer.pev.v_angle;
	vecAngle.x = -vecVAngle.x;
	vecAngle.z = 0;

	Vector vecStart;
	
	if ( g_pCVarInstant.GetBool() )
	{
		vecStart = GetPlayerHitpoint( pPlayer );
	
		/*if ( g_EngineFuncs.PointContents( vecStart ) != CONTENTS_SKY )
		{
			Vector fSize = pPlayer.pev.size;
			
			vecOrigin.x = vecStart.x + cos( Math.DegreesToRadians( vecVAngle.y ) ) * ( -10.0 + fSize.x );
			vecOrigin.y = vecStart.y + sin( Math.DegreesToRadians( vecVAngle.y ) ) * ( -10.0 + fSize.y );
			vecOrigin.z = vecStart.z;
		}
		else*/
		vecOrigin = vecStart;
	}

	// Make the hook!
	CBaseEntity@ pEntity = g_EntityFuncs.Create( "script_hook", vecOrigin, vecAngle, true, pPlayer.edict() );
	if ( pEntity is null )
	{
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "Can't create hook\n" );
		return;
	}

	// Player can't throw hook now
	g_bCanThrowHook[iPlayer] = false;

	pEntity.pev.v_angle = vecVAngle;

	if ( g_pCVarInstant.GetBool() )
	{
		pEntity.pev.vuser1 = vecOrigin;
	//	pEntity.SetOrigin( vecStart );
	}

	g_EntityFuncs.DispatchSpawn( pEntity.edict() );
}

void remove_hook( CBasePlayer@ pPlayer, int iPlayer )
{
	//Player can now throw hooks
	g_bCanThrowHook[iPlayer] = true;

	CBaseEntity@ pEntity = null;
	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "script_hook" ) ) !is null )
	{
		if ( pEntity.pev.owner !is pPlayer.edict() )
			continue;
			
		g_EntityFuncs.Remove( pEntity );
		break;
	}
	
	// Player is not hooked anymore
	g_bHooked[iPlayer] = false;
}

void give_hook( const CCommand@ args )
{
	CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();

	if ( pPlayer is null || !pPlayer.IsConnected() )
		return;

	if ( !IsPlayerAdmin( pPlayer ) )
	{
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "[Hook] You have no access to that command\n" );
		return;
	}
		
	if ( !g_pCVarAdmin.GetBool() )
	{
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "[Hook] Admin only mode is currently disabled\n" );
		return;
	}

	if ( args.ArgC() < 2 )
	{
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "Usage: ." + givehook.GetName() + " " + givehook.GetHelpInfo() + "\n" );
		return;
	}
	
	string szTarget = args.Arg( 1 );
	szTarget.Trim();

	CBasePlayer@ pTarget = GetTargetPlayer( pPlayer, szTarget );

	if ( pTarget is null )
		return;
	
	int iTarget = pTarget.entindex();
	
	if ( iTarget <= 0 )
		return;
		
	string szName = pTarget.pev.netname;
	
	if ( !g_bHookAllowed[iTarget] )
	{
		g_bHookAllowed[iTarget] = true;
		
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "[Hook] You gave " + szName + " access to the hook\n" );
	}
	else
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "[Hook] " + szName + " already have access to the hook\n" );
}

void take_hook( const CCommand@ args )
{
	CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();

	if ( pPlayer is null || !pPlayer.IsConnected() )
		return;

	if ( !IsPlayerAdmin( pPlayer ) )
	{
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "[Hook] You have no access to that command\n" );
		return;
	}
	
	if ( !g_pCVarAdmin.GetBool() )
	{
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "[Hook] Admin only mode is currently disabled\n" );
		return;
	}

	if ( args.ArgC() < 2 )
	{
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "Usage: ." + takehook.GetName() + " " + takehook.GetHelpInfo() + "\n" );
		return;
	}

	string szTarget = args.Arg( 1 );
	szTarget.Trim();

	CBasePlayer@ pTarget = GetTargetPlayer( pPlayer, szTarget );

	if ( pTarget is null )
		return;
	
	int iTarget = pTarget.entindex();
	
	if ( iTarget <= 0 )
		return;
		
	string szName = pTarget.pev.netname;
	
	if ( g_bHookAllowed[iTarget] )
	{
		g_bHookAllowed[iTarget] = false;
		
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "[Hook] You took away " + szName + " his access to the hook\n" );
	}
	else
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "[Hook] " + szName + " does not have access to the hook\n" );
}

// Stock by Chaosphere
Vector GetPlayerHitpoint( CBasePlayer@ pPlayer )
{
	if ( !pPlayer.IsAlive() )
		return g_vecZero;

	Vector vecVOrigin = pPlayer.GetOrigin() + pPlayer.pev.view_ofs;
	
	Vector vecEOrigin, vecTemp;
	g_EngineFuncs.AngleVectors( pPlayer.pev.v_angle, vecEOrigin, vecTemp, vecTemp );
	
	TraceResult tr;
	g_Utility.TraceLine( vecVOrigin, vecVOrigin + ( vecEOrigin * 8192 ), dont_ignore_monsters, pPlayer.edict(), tr );

	
	return tr.vecEndPos;
}

CBasePlayer@ GetTargetPlayer( CBasePlayer@ pPlayer, const string& in szNameOrUserId )
{
	CBasePlayer@ pTarget = g_PlayerFuncs.FindPlayerByName( szNameOrUserId, false );
	int iCount = 0;

	if ( pTarget is null )
	{
		CBasePlayer@ pTempPlayer = null;
		string szPlayerName;
		for ( int iClient = 1; iClient <= g_PlayerFuncs.GetNumPlayers(); iClient++ )
		{
			@pTempPlayer = g_PlayerFuncs.FindPlayerByIndex( iClient );
			
			if ( pTempPlayer is null || !pTempPlayer.IsConnected() )
				continue;

			szPlayerName = pTempPlayer.pev.netname;
			
			if ( int( szPlayerName.Find( szNameOrUserId, 0, String::CaseInsensitive ) ) != -1 )
			{
				@pTarget = pTempPlayer;
				iCount++;
			}
			
			if ( iCount > 1 )
				break;
		}
	}
		
	if ( pTarget is null && szNameOrUserId[0] == "#" )
	{
		string szUserId;
		for ( int iClient = 1; iClient <= g_PlayerFuncs.GetNumPlayers(); iClient++ )
		{
			@pTarget = g_PlayerFuncs.FindPlayerByIndex( iClient );
			
			if ( pTarget is null || !pTarget.IsConnected() )
				continue;

			szUserId = "#" + g_EngineFuncs.GetPlayerUserId( pTarget.edict() );
			
			if ( szUserId == szNameOrUserId )
				break;
					
			@pTarget = null;
		}
	}

	if ( pTarget is null )
	{
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "Client with that name or userid not found\n" );
		return null;
	}

	if ( iCount > 1 )
	{
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "There is more than one client matching your argument\n" );
		return null;
	}

	if ( pTarget !is pPlayer && IsPlayerAdmin( pTarget ) )
	{
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "Client " + pTarget.pev.netname + " has immunity\n" );
		return null;
	}

/*	if ( !pTarget.IsAlive() )
	{
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "That action can't be performed on dead client " + pTarget.pev.netname + "\n" );
		return null;
	}*/
	
	return pTarget;
}

bool IsPlayerAdmin( CBasePlayer@ pPlayer )
{
	return g_PlayerFuncs.AdminLevel( pPlayer ) >= ADMIN_YES;
}

class script_hook : ScriptBaseEntity
{
	private CBeam@ m_pBeam = null;

	void Spawn()
	{
		//const Vector vecMins( -2.840000, -14.180000, -2.840000 );
		//const Vector vecMaxs( 2.840000, 0.020000, 2.840000 );
		const Vector vecMins( -3.5, -3.5, -3.5 );
		const Vector vecMaxs( 3.5, 3.5, 3.5 );
		
		//Set some Data
		g_EntityFuncs.SetModel( self, "models/crossbow_bolt.mdl" );
		g_EntityFuncs.SetSize( self.pev, vecMins, vecMaxs );
		
		//self.pev.angles = vecAngle;
		
		self.pev.solid = SOLID_BBOX;
	//	self.pev.solid = SOLID_TRIGGER;
		self.pev.movetype = MOVETYPE_FLY;

		self.pev.nextthink = g_Engine.time + 0.1;

		//Set hook velocity
		float flSpeed = g_pCVarThrowSpeed.GetFloat();
				
		Math.MakeVectors( self.pev.v_angle );
		Vector vecForward = g_Engine.v_forward;	
		Vector vecVelocity = vecForward * flSpeed;
		/*vecVelocity.x = vecForward.x * flSpeed;
		vecVelocity.y = vecForward.y * flSpeed;
		vecVelocity.z = vecForward.z * flSpeed;*/
			
		self.pev.velocity = vecVelocity;

		CBaseEntity@ pOwner = g_EntityFuncs.Instance( self.pev.owner );
		if ( pOwner is null )
			return;
		
		// Make the line between Hook and Player
		@m_pBeam = g_EntityFuncs.CreateBeam( "sprites/zbeam4.spr", g_pCVarWidth.GetInt() );
		if ( m_pBeam is null )
			return;

		if ( g_pCVarInstant.GetBool() )
			m_pBeam.PointEntInit( self.pev.vuser1, pOwner );
		else
			m_pBeam.EntsInit( pOwner, self );

		m_pBeam.SetFrame( 1.0 );
		//pBeam.LiveForTime( 255 );
		m_pBeam.SetNoise( g_pCVarHookNoise.GetInt() );
			
		Vector vecColor( 255, 255, 255 );
		if ( g_pCVarColor.GetBool() )
		{
			if ( pOwner.pev.renderfx == kRenderFxGlowShell )
				vecColor = pOwner.pev.rendercolor;
			if ( vecColor == g_vecZero )
				vecColor = Vector( 255, 255, 255 );
		}
			
		m_pBeam.SetColor( int( vecColor.x ), int( vecColor.y ), int( vecColor.z ) );
		m_pBeam.SetBrightness( 192 );
		m_pBeam.SetScrollRate( 0 );
		
		if ( g_pCVarSound.GetBool() && !g_pCVarInstant.GetBool() )
			g_SoundSystem.PlaySound( pOwner.edict(), CHAN_STATIC, "weapons/xbow_fire1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_HIGH );
	}
	
	void OnDestroy()
	{
		if ( m_pBeam is null )
			return;

		g_EntityFuncs.Remove( m_pBeam );
	}

	void Think()
	{
		self.pev.nextthink = g_Engine.time + 0.1;

		CBaseEntity@ pOwner = g_EntityFuncs.Instance( self.pev.owner );
		if ( pOwner is null || !pOwner.IsPlayer() )
			return;
		
		CBasePlayer@ pPlayer = cast<CBasePlayer@>( @pOwner );
		if ( pPlayer is null )
			return;
		
		int iPlayer = pPlayer.entindex();
		Vector entOrigin = self.GetOrigin();
	
		// If user is behind a box or something.. remove it
		// only works if .hookinterrupt 1 or higher is
		// AS: this crash server if 1 // todo fix
		if ( g_bMapStarted && g_pCVarInterrupt.GetBool() )
		{
			Vector usrOrigin = pPlayer.GetOrigin();
			
			TraceResult tr;
			g_Utility.TraceLine( usrOrigin, entOrigin, ignore_monsters, null, tr );
			
		//	g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "tr.flFraction = " + tr.flFraction + "\n" );
			
			if ( tr.flFraction != 1.0 )
			{
				remove_hook( pPlayer, iPlayer );
				return;
			}
		}
		
		// If cvar .hooksky is 0 and hook is in the sky remove it!
		if ( !g_pCVarHookSky.GetBool() && g_EngineFuncs.PointContents( entOrigin ) == CONTENTS_SKY )
		{
			if ( g_pCVarSound.GetBool() )
				g_SoundSystem.PlaySound( self.edict(), CHAN_STATIC, "weapons/xbow_hit2.wav", VOL_NORM, 0.3, 0, PITCH_NORM );

			remove_hook( pPlayer, iPlayer );
			return;
		}
	}

	void Touch( CBaseEntity@ pOther )
	{
		if ( pOther is null )
			return;
			
		CBaseEntity@ pOwner = g_EntityFuncs.Instance( self.pev.owner );
		if ( pOwner is null || !pOwner.IsPlayer() )
			return;
		
		CBasePlayer@ pPlayer = cast<CBasePlayer@>( pOwner );
		if ( pPlayer is null )
			return;
		
		Vector entOrigin = self.GetOrigin();
		
		int iPlayer = pPlayer.entindex();

		g_bHooked[iPlayer] = true;

		// If cvar .hooksky is 0 and hook is in the sky remove it!
		if ( !g_pCVarHookSky.GetBool() && g_EngineFuncs.PointContents( entOrigin ) == CONTENTS_SKY )
		{
			if ( g_pCVarSound.GetBool() )
				g_SoundSystem.PlaySound( self.edict(), CHAN_STATIC, "weapons/xbow_hit2.wav", VOL_NORM, 0.3, 0, PITCH_NORM );

			remove_hook( pPlayer, iPlayer );
			return;
		}

		string szClassname = pOther.GetClassname();
			
		//g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "pHit.GetClassname() = " + pHit.GetClassname() + "\n" );

		if ( !g_pCVarPlayers.GetBool() && szClassname == "player" )
		{
			// Hit a player
			if ( g_pCVarSound.GetBool() )
				g_SoundSystem.PlaySound( self.edict(), CHAN_STATIC, "weapons/xbow_hitbod1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM );

			remove_hook( pPlayer, iPlayer );
				
			return;
		}
		else if ( g_pCVarMonster.GetBool() && szClassname.CompareN( "monster_", 8 ) == 0 )
		{
			CBaseMonster@ pMonster = cast<CBaseMonster@>( pOther );
			// Makes an ally monsters follow
			if ( pOther.IsPlayerAlly() && pMonster !is null && pMonster.m_afCapability != 0 )
				pOther.Use( pPlayer, pPlayer, USE_ON );

			if ( !g_pCVarPlayers.GetBool() )
			{
				if ( g_pCVarSound.GetBool() )
					g_SoundSystem.PlaySound( self.edict(), CHAN_STATIC, "weapons/xbow_hitbod1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM );

				remove_hook( pPlayer, iPlayer );

				return;
			}
		}
		else if ( g_pCVarOpenDoors.GetBool() && ( szClassname == "func_door" || szClassname == "func_door_rotating" ) )
		{
			// Open doors
			// Double doors tested in de_nuke and de_wallmart
			string szTargetName = pOther.GetTargetname();
			if ( !szTargetName.IsEmpty() )
			{	
				CBaseEntity@ pEnt = null;
				while ( ( @pEnt = g_EntityFuncs.FindEntityByString( pEnt, "target", szTargetName ) ) !is null )
				{
					if ( pEnt.GetClassname() == "trigger_multiple" )
					{
						pEnt.Touch( pPlayer );
						break; // No need to touch anymore
					}
				}
			}
			else
			{
				// No double doors.. just touch it
				pOther.Touch( pPlayer );
			}		
		}
		else if ( g_pCVarUseButtons.GetBool() && szClassname == "func_button" )
		{
			if ( pOther.pev.spawnflags & 256 != 0 )
				pOther.Touch( pPlayer ); // Touch only
			else			
				pOther.Use( pPlayer, pPlayer, USE_ON ); // Use Buttons			
		}

		// Pick up weapons..
		if ( g_pCVarWeapons.GetBool() )
		{
			CBaseEntity@ pEnt = null;
			string szEntClass;
			while ( ( @pEnt = g_EntityFuncs.FindEntityInSphere( pEnt, entOrigin, 30.0, "*", "classname" ) ) !is null )
			{
				szEntClass = pEnt.GetClassname();
					
				if ( szEntClass == "weaponbox" || szEntClass.CompareN( "weapon_", 7 ) == 0  || szEntClass.CompareN( "ammo_", 5 ) == 0 )
					pEnt.Touch( pPlayer );
			}
		}

		if ( g_pCVarSound.GetBool() )
			g_SoundSystem.PlaySound( self.edict(), CHAN_STATIC, "weapons/xbow_hit1.wav", VOL_NORM, 0.4, 0, PITCH_NORM );
			
		// Make some sparks :D
		g_Utility.Sparks( entOrigin );
			

		// AS: parent hook entity to brush clients will crash
		// explained: https://forums.alliedmods.net/showthread.php?t=248539
		if ( g_bWorkaroundFollow )
		{
			if ( pOther.IsMoving() && pOther.pev.speed != 0 )
			{
				self.pev.velocity = pOther.pev.velocity;
			//	self.pev.movetype = MOVETYPE_TOSS;
			}
			else
			{
				self.pev.velocity = g_vecZero;
				self.pev.movetype = MOVETYPE_NONE;
			}
			
			@self.pev.euser1 = @pOther.edict();
		}
		else
		{
			if ( szClassname == "func_door" )
			{
				//@self.pev.owner = @pOther.edict();
				//self.pev.velocity = pOther.pev.velocity;
			
				self.pev.skin = pOther.entindex();
			//	self.pev.body = pOther.entindex();
				@self.pev.aiment = @pOther.edict();
			//	@self.pev.aiment = pOther.edict();
				self.pev.movetype = MOVETYPE_FOLLOW;
			}
			else
			{
				// Stop the hook from moving
				self.pev.velocity = g_vecZero;
				self.pev.movetype = MOVETYPE_NONE;
			}
		}
		
		if ( g_pCVarMaxHooks.GetInt() > 0 && !IsPlayerAdmin( pPlayer ) )
			g_iHooksUsed[iPlayer]++;

		SetThink( ThinkFunction( this.GotoHookThink ) );
		self.pev.nextthink = g_Engine.time + 0.05;
	}

	void GotoHookThink()
	{
		self.pev.nextthink = g_Engine.time + 0.05;

		CBaseEntity@ pOwner = g_EntityFuncs.Instance( self.pev.owner );

		if ( pOwner is null || !pOwner.IsPlayer() )
			return;

		// workaround for MOVETYPE_FOLLOW
		if ( g_bWorkaroundFollow )
		{
			CBaseEntity@ pOther = g_EntityFuncs.Instance( self.pev.euser1 );

			if ( pOther !is null && pOther.IsMoving() && pOther.pev.speed != 0 )
			{
				self.pev.velocity = pOther.pev.velocity;

				if ( self.pev.movetype != MOVETYPE_FLY )
					self.pev.movetype = MOVETYPE_FLY;
			}
			else
			{
				if ( self.pev.velocity != g_vecZero )
				{
					self.pev.velocity = g_vecZero;
					self.pev.movetype = MOVETYPE_NONE;
				}
			}
		}
		
/*		if ( pOther !is null && pOther.IsMoving() && pOther.pev.speed != 0 && self.pev.movetype != MOVETYPE_FOLLOW )
		{
			@self.pev.owner = @pOther.edict();	
			self.pev.movetype = MOVETYPE_FOLLOW;
			@self.pev.aiment = @pOther.edict();
			return;
		}*/
		
		int iPlayer = pOwner.entindex();

		// If map isn't started velocity is just 0
		Vector vecVelocity( 0.0, 0.0, 1.0 );
		
		// If map is started and player is hooked we can set the user velocity!
		if ( g_bMapStarted && g_bHooked[iPlayer] )
		{
			Vector vecHookOrigin = self.GetOrigin(), vecUsrOrigin = pOwner.GetOrigin();
			float flDist = ( vecHookOrigin - vecUsrOrigin ).Length();
			
			if ( flDist >= 30.0 )
			{
				float flSpeed = g_pCVarSpeed.GetFloat();
				
				flSpeed *= 0.52;
				
				vecVelocity.x = ( vecHookOrigin.x - vecUsrOrigin.x ) * ( 2.0 * flSpeed ) / flDist;
				vecVelocity.y = ( vecHookOrigin.y - vecUsrOrigin.y ) * ( 2.0 * flSpeed ) / flDist;
				vecVelocity.z = ( vecHookOrigin.z - vecUsrOrigin.z ) * ( 2.0 * flSpeed ) / flDist;
			}
		}
		// Set the velocity
		pOwner.pev.velocity = vecVelocity;
	}
}
