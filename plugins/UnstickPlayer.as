/* - - - - - - - - - - -

AngelScript port from AMX Mod X plugin.

  | Author    : Arkshine
  | Plugin    : Unstick Player
  | Version   : v1.0.3
  | Ported by : Duko

(!) AMX Mod X Support : http://forums.alliedmods.net/showthread.php?p=717994#post717994
(!) Requested by Rirre.


	Description :
	- - - - - - -
		Unstick player via a client command.


	Credits :
	- - - - - 
		* AMX Mod X Team. ( original plugin )


	Changelog :
   	 - - - - - -
		v1.0.3 : [ 3 feb 2016 ]
			
			(+) AngelScript port
			
			
		v1.0.2 : [ 25 nov 2008 ]

			(+) Initial release.

- - - - - - - - - - - */


const int START_DISTANCE = 32;	// --| The first search distance for finding a free location in the map.
const int MAX_ATTEMPTS = 128;	// --| How many times to search in an area for a free space.


CCVar@ g_pUnstuckFrequency;
array<float> g_flLastCmdTime( g_Engine.maxClients + 1, 0.0 );


void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Arkshine|Duko" );
	g_Module.ScriptInfo.SetContactInfo( "group.midu.cz" );

	// --| Cvars.
	@g_pUnstuckFrequency = CCVar( "unstuck_frequency", "3.0", "Unstuck Frequency in sec" );

	g_Hooks.RegisterHook( Hooks::Player::ClientSay, @ClientSay );
}

void MapInit()
{
	g_SoundSystem.PrecacheSound( "fvox/fuzz.wav" );

	for ( int iPlayer = 1; iPlayer <= g_Engine.maxClients; ++iPlayer )
		g_flLastCmdTime[ iPlayer ] = g_Engine.time;
}

HookReturnCode ClientSay( SayParameters@ pParams )
{
	const CCommand@ pArguments = pParams.GetArguments();

	if ( pArguments.ArgC() >= 1 )
	{
		string szArg = pArguments.Arg( 0 );
		szArg.Trim();

		if ( szArg.ICompare( "!stuck" ) == 0 || szArg.ICompare( "!unstuck" ) == 0 || szArg.ICompare( "unstuck" ) == 0 )
		{
			CBasePlayer@ pPlayer = pParams.GetPlayer();

			if ( pPlayer is null || !pPlayer.IsConnected() )
				return HOOK_CONTINUE;

			int iPlayer = pPlayer.entindex();
			float f_MinFrequency = g_pUnstuckFrequency.GetFloat();
			float f_ElapsedCmdTime = g_Engine.time - g_flLastCmdTime[ iPlayer ];
		 
			if ( f_ElapsedCmdTime < f_MinFrequency ) 
			{
				pParams.ShouldHide = true;
				g_EngineFuncs.ClientPrintf( pPlayer, print_center, "You must wait " + ( float( int( ( f_MinFrequency - f_ElapsedCmdTime ) * 10 ) ) / 10 ) + " seconds before\ntrying to free yourself.\n" );
				return HOOK_HANDLED;
			}
			   
			g_flLastCmdTime[ iPlayer ] = g_Engine.time;
			
			int iValue;
			   
			if ( ( iValue = UTIL_UnstickPlayer( pPlayer, START_DISTANCE, MAX_ATTEMPTS ) ) != 1 )
			{
				switch ( iValue )
				{
					case 0  : g_EngineFuncs.ClientPrintf( pPlayer, print_center, "Couldn't find a free spot to move you too\n" ); break;
					case -1 : g_EngineFuncs.ClientPrintf( pPlayer, print_center, "You can't free yourself as dead player\n" ); break;
					case -2 : g_EngineFuncs.ClientPrintf( pPlayer, print_center, "You can't free yourself while used noclip\n" ); break;
					case -3 : g_EngineFuncs.ClientPrintf( pPlayer, print_center, "You can't free yourself while paralyzed\n" ); break;
				}
			}
			else
			{
				HUDTextParams hudPrms;
				hudPrms.x = -1;
				hudPrms.y = 0.65;
				
				hudPrms.effect = 0;
				
				hudPrms.r1 = 255;
				hudPrms.g1 = 150;
				hudPrms.b1 = 50;
				hudPrms.a1 = 0;

				hudPrms.r2 = 255;
				hudPrms.g2 = 255;
				hudPrms.b2 = 255;
				hudPrms.a2 = 150;
				
				hudPrms.fadeinTime = 0.01;
				hudPrms.fadeoutTime = 0.3;
				hudPrms.holdTime = 3.5;
				hudPrms.fxTime = 0.0;
				hudPrms.channel = 4;
				
				g_PlayerFuncs.HudMessage( pPlayer, hudPrms, "You should be unstucked now!" );
				g_SoundSystem.PlaySound( pPlayer.edict(), CHAN_STATIC, "fvox/fuzz.wav", VOL_NORM, ATTN_NORM );
			}
		}
	}

	return HOOK_CONTINUE;
}

int UTIL_UnstickPlayer( CBasePlayer@ pPlayer, const int i_StartDistance, const int i_MaxAttempts )
{
	if ( !pPlayer.IsAlive() )
		return -1;

	if ( pPlayer.pev.movetype == MOVETYPE_NOCLIP )
		return -2;

	if ( ( pPlayer.m_afPhysicsFlags & PFLAG_ONBARNACLE ) != 0 )
		return -3;

	Vector vecOriginalOrigin = pPlayer.GetOrigin();

	Vector vecNewOrigin;
	int iDistance = i_StartDistance;
	TraceResult tr;
	HULL_NUMBER hullNumber = ( pPlayer.pev.flags & FL_DUCKING ) != 0 ? head_hull : human_hull;

	while ( iDistance < 1000 )
	{
		for ( int iAttempts = 0; iAttempts < i_MaxAttempts; iAttempts++ )
		{
			vecNewOrigin.x = Math.RandomFloat( vecOriginalOrigin.x - iDistance, vecOriginalOrigin.x + iDistance );
			vecNewOrigin.y = Math.RandomFloat( vecOriginalOrigin.y - iDistance, vecOriginalOrigin.y + iDistance );
			vecNewOrigin.z = Math.RandomFloat( vecOriginalOrigin.z - iDistance, vecOriginalOrigin.z + iDistance );

			g_Utility.TraceHull( vecNewOrigin, vecNewOrigin, dont_ignore_monsters, hullNumber, pPlayer.edict(), tr );

			if ( IntToBool( tr.fInOpen ) && !IntToBool( tr.fAllSolid ) && !IntToBool( tr.fStartSolid ) )
			{
				pPlayer.SetOrigin( vecNewOrigin );
				return 1;
			}
		}

		iDistance += i_StartDistance;
	}

	return 0; // Couldn't be found
}

bool IntToBool( int iVal )
{
	if ( iVal > 0 )
		return true;

	return false;
}
