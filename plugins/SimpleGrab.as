// SimpleGrab by DeepBlueSea
// ============================
// bind <key> ".grab"  // grab an entity
// bind <key> ".pull"  // pull a grabbed entity towards you
// bind <key> ".push"  // push a grabbed entity further away
// bind <key> ".undograb" // undo grab operation
//
// Thanks to:
// - Solokiller
// - Zodemon
// - nico 

// Changelog:
// == 1.02.2016 ==
// - Old rendermodes of entities are now saved and reapplied after grab
// - some displacement after picking up fixed
// - precache sounds
// == 2.02.2016 ==
// - bsp entities can now be grabbed too
// - added pull and push function
// - print out some info about the entity
// - precache sounds (misplaced, fixed)
// - fixed movement
// == 4.02.2016 ==
// - undo grab operation added
// - fixed slippage
// == 20.02.2016 ==
// - AS update
// == 28.02.2016 ==
// - grab bug after mapchange

const string g_KeyGrab = "$i_grabis";
const string g_KeyGrabEnt = "$i_grabent";
const string g_KeyGrabDist = "$f_grabdist";
const string g_KeyGrabEnd = "$v_grabend";
const string g_KeyGrabSave = "$v_grabsave";
const string g_KeyGrabFrames = "$f_grabframes";
const string g_KeyGrabMType = "$i_grabmtype";
const string g_KeyGrabSType = "$i_grabstype";
const string g_KeyGrabFlags = "$i_grabflags";


void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "DeepBlueSea" );
	g_Module.ScriptInfo.SetContactInfo( "irc://irc.rizon.net/#/dev/null" );
	g_Hooks.RegisterHook( Hooks::Player::ClientPutInServer, @ClientPutInServer );
  
	g_Hooks.RegisterHook( Hooks::Player::PlayerPostThink, @PlayerPostThink );
  
	// remove if this should be available for all players
	g_Module.ScriptInfo.SetMinimumAdminLevel( ADMIN_YES ); 
}

//===========================================================================//
void MapInit()
{
	g_SoundSystem.PrecacheSound( "items/r_item1.wav" );
	g_SoundSystem.PrecacheSound( "items/r_item2.wav" );  
}

void MapStart()
{
	CBasePlayer@ pPlayer;

	for ( int i = 1; i <= g_Engine.maxClients; i++ )
	{
		@pPlayer = g_PlayerFuncs.FindPlayerByIndex( i );
		if ( pPlayer is null )
			continue;

		CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
		pCustom.SetKeyvalue( g_KeyGrab, 0 );
	}
}

//===========================================================================//
const string g_Keyrendermode = "$i_grabrendermode";
const string g_Keyrenderfx = "$i_grabrenderfx";
const string g_Keyrenderamt = "$f_grabrenderamt";
const string g_KeyColorR = "$i_grabcolorr";
const string g_KeyColorG = "$i_grabcolorg";
const string g_KeyColorB = "$i_grabcolorb";

void PushRenderMode( CBaseEntity@ pEnt )
{
	CustomKeyvalues@ pCustom = pEnt.GetCustomKeyvalues();
	pCustom.SetKeyvalue( g_Keyrendermode, pEnt.pev.rendermode );
	pCustom.SetKeyvalue( g_Keyrenderfx, pEnt.pev.renderfx );
	pCustom.SetKeyvalue( g_Keyrenderamt, pEnt.pev.renderamt );
	pCustom.SetKeyvalue( g_KeyColorR, pEnt.pev.rendercolor.x );
	pCustom.SetKeyvalue( g_KeyColorG, pEnt.pev.rendercolor.y );
	pCustom.SetKeyvalue( g_KeyColorB, pEnt.pev.rendercolor.z );
}

void PopRenderMode( CBaseEntity@ pEnt )
{
	CustomKeyvalues@ pCustom = pEnt.GetCustomKeyvalues();
	pEnt.pev.rendermode = pCustom.GetKeyvalue( g_Keyrendermode ).GetInteger();
	pEnt.pev.renderfx = pCustom.GetKeyvalue( g_Keyrenderfx ).GetInteger();
	pEnt.pev.renderamt = pCustom.GetKeyvalue( g_Keyrenderamt ).GetInteger();
	pEnt.pev.rendercolor.x = pCustom.GetKeyvalue( g_KeyColorR ).GetInteger();
	pEnt.pev.rendercolor.y = pCustom.GetKeyvalue( g_KeyColorG ).GetInteger();
	pEnt.pev.rendercolor.z = pCustom.GetKeyvalue( g_KeyColorB ).GetInteger();
}

void setRenderMode( CBaseEntity@ pEnt, int rendermode, int renderfx, int renderamt, Vector color )
{
	pEnt.pev.rendermode = rendermode;
	pEnt.pev.renderfx = renderfx;
	pEnt.pev.renderamt = renderamt;
	pEnt.pev.rendercolor = color;
}

//===========================================================================//
HookReturnCode ClientPutInServer( CBasePlayer@ pPlayer )
{
	if ( pPlayer is null )
		return HOOK_CONTINUE;

	CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
	pCustom.InitializeKeyvalueWithDefault( g_KeyGrab );
	pCustom.InitializeKeyvalueWithDefault( g_KeyGrabEnt );
	pCustom.InitializeKeyvalueWithDefault( g_KeyGrabDist );
	
	return HOOK_CONTINUE;
}

//===========================================================================//
HookReturnCode PlayerPostThink( CBasePlayer@ pPlayer )
{
	if ( pPlayer is null || !pPlayer.IsConnected() )
		return HOOK_CONTINUE;

	CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
	CustomKeyvalue valueKeyGrab( pCustom.GetKeyvalue( g_KeyGrab ) );

	if ( valueKeyGrab.GetInteger() > 0 )
	{
		CustomKeyvalue valueEntGrab( pCustom.GetKeyvalue( g_KeyGrabEnt ) );
		CBaseEntity@ pEntity = g_EntityFuncs.Instance( valueEntGrab.GetInteger() );

		if ( pEntity !is null )
		{
			CustomKeyvalue valueDistance( pCustom.GetKeyvalue( g_KeyGrabDist ) );

			Vector vecViewPos = pPlayer.GetOrigin();

			Vector vecForward;
			Vector vecDummy;
			g_EngineFuncs.AngleVectors( pPlayer.pev.v_angle, vecForward, vecDummy, vecDummy );

			Vector vOldEndPos;
			vOldEndPos = pCustom.GetKeyvalue( g_KeyGrabEnd ).GetVector();

			Vector vNewEndPos = vecViewPos + ( vecForward * valueDistance.GetFloat() );

			Vector vUpdatedPos = pEntity.GetOrigin() + ( vNewEndPos - vOldEndPos );

			pEntity.SetOrigin( vUpdatedPos );

			//pEntity.pev.oldorigin = vUpdatedPos;

			pEntity.pev.movedir = g_vecZero;
			pEntity.pev.framerate = 0.0;
			pEntity.pev.gravity = 0.0;
			pEntity.pev.flFallVelocity = 0.0;
			pEntity.pev.velocity = g_vecZero;

			pCustom.SetKeyvalue( g_KeyGrabEnd, vNewEndPos );
		}
		else 
		{
			pCustom.SetKeyvalue( g_KeyGrab, 0 );
		}
	}
	
	return HOOK_CONTINUE;
}

//===========================================================================//
void SetDistanceOffset( CBasePlayer@ pPlayer, float distOffset )
{
	CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
	CustomKeyvalue valueKeyGrab( pCustom.GetKeyvalue( g_KeyGrab ) );
	
	if ( valueKeyGrab.GetInteger() > 0 )
	{
		CustomKeyvalue valueDistance( pCustom.GetKeyvalue( g_KeyGrabDist ) );
		float distance = valueDistance.GetFloat() + distOffset;
		pCustom.SetKeyvalue( g_KeyGrabDist, distance );
	}
}

//===========================================================================//
CClientCommand g_Push( "push", "Push a grabbed entity", @Push );
void Push( const CCommand@ pArgs )
{
	CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();
	if ( pPlayer is null || !pPlayer.IsConnected() )
		return;

	SetDistanceOffset( pPlayer, 35.0 );
}

//===========================================================================//
CClientCommand g_Pull( "pull", "Pull a grabbed entity", @Pull );
void Pull( const CCommand@ pArgs )
{
	CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();
	if ( pPlayer is null || !pPlayer.IsConnected() )
		return;

	SetDistanceOffset( pPlayer, -35.0 );
}

//===========================================================================//
CClientCommand g_UndoGrab( "undograb", "Undo a grab operation", @UndoGrab );
void UndoGrab( const CCommand@ pArgs )
{
	CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();
	if ( pPlayer is null || !pPlayer.IsConnected() )
		return;

	CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
	CustomKeyvalue valueKeyGrab( pCustom.GetKeyvalue( g_KeyGrab ) );
	if ( valueKeyGrab.GetInteger() == 0 )
	{
		CustomKeyvalue valueEntGrab( pCustom.GetKeyvalue( g_KeyGrabEnt ) );
		CBaseEntity@ pEntity = g_EntityFuncs.Instance( valueEntGrab.GetInteger() );

		if ( pEntity is null )
			return;

		pEntity.SetOrigin( pCustom.GetKeyvalue( g_KeyGrabSave ).GetVector() );
	}
}
//===========================================================================//
CClientCommand g_Grab( "grab", "Grab an entity", @Grab );
void Grab( const CCommand@ pArgs )
{
	CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();
	if ( pPlayer is null || !pPlayer.IsConnected() )
		return;

	CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
	CustomKeyvalue valueKeyGrab( pCustom.GetKeyvalue( g_KeyGrab ) );

	if ( valueKeyGrab.GetInteger() > 0 )
	{
		// Ungrab
		pCustom.SetKeyvalue( g_KeyGrab, 0 );

		CustomKeyvalue valueEntGrab( pCustom.GetKeyvalue( g_KeyGrabEnt ) );
		CBaseEntity@ pEntity = g_EntityFuncs.Instance( valueEntGrab.GetInteger() );

		if ( pEntity !is null )
		{
			g_SoundSystem.PlaySound( pEntity.edict(), CHAN_STATIC, "items/r_item2.wav", 1.0f, 1.0f, 0, 100 );
			g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "UNGRAB: (" + pEntity.GetClassname() + ") - [X: " + pEntity.pev.origin.x + "|Y: " + pEntity.pev.origin.y + " |Z: " + pEntity.pev.origin.z + "]\n" );

			if ( !pEntity.IsBSPModel() )
			{
				pEntity.pev.framerate = pCustom.GetKeyvalue( g_KeyGrabFrames ).GetFloat();
				g_EngineFuncs.DropToFloor( pEntity.edict() );

				if ( pEntity.IsNetClient() )
				{
					pEntity.pev.movetype = pCustom.GetKeyvalue( g_KeyGrabMType ).GetInteger();
					pEntity.pev.flags = pCustom.GetKeyvalue( g_KeyGrabFlags ).GetInteger();
					pEntity.pev.solid = pCustom.GetKeyvalue( g_KeyGrabSType ).GetInteger();
				}
			}

			PopRenderMode( pEntity ); // restore old rendermode	
		}
	}
	else
	{
		Vector vecViewPos = pPlayer.GetOrigin() + pPlayer.pev.view_ofs;

		Vector vecForward;
		Vector vecDummy;
		g_EngineFuncs.AngleVectors( pPlayer.pev.v_angle, vecForward, vecDummy, vecDummy );

		TraceResult tr;
		g_Utility.TraceLine( vecViewPos, vecViewPos + ( vecForward * 4096 ), dont_ignore_monsters, pPlayer.edict(), tr );
		
		if ( tr.pHit is null )
			return;
		
		CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );
		//CBaseEntity @pEntity = g_Utility.FindEntityForward( pPlayer, 4096 );

		if ( pEntity !is null && pEntity.GetClassname() != "worldspawn" )
		{
			Vector vecOrigin = pEntity.GetOrigin();
			//Vector vecEndPos = pEntity.Center();
			Vector vecEndPos = tr.vecEndPos;
			//vecEndPos.z -= pEntity.pev.size.z / 2;
			g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "GRAB:	  (" + pEntity.GetClassname() + ") - [X: " + vecOrigin.x + "|Y: " + vecOrigin.y + " |Z: " + vecOrigin.z + "]\n" );

			g_SoundSystem.PlaySound( pEntity.edict(), CHAN_STATIC, "items/r_item1.wav", 1.0f, 1.0f, 0, 100 );
			pCustom.SetKeyvalue( g_KeyGrab, 1 );
			pCustom.SetKeyvalue( g_KeyGrabEnt, pEntity.entindex() );
			pCustom.SetKeyvalue( g_KeyGrabFrames, pEntity.pev.framerate );

			pCustom.SetKeyvalue( g_KeyGrabMType, pEntity.pev.movetype );
			pCustom.SetKeyvalue( g_KeyGrabSType, pEntity.pev.solid );
			pCustom.SetKeyvalue( g_KeyGrabFlags, pEntity.pev.flags );

			pCustom.SetKeyvalue( g_KeyGrabEnd, vecEndPos );
			pCustom.SetKeyvalue( g_KeyGrabSave, vecOrigin );

			float distance = ( vecEndPos - vecViewPos ).Length();
			pCustom.SetKeyvalue( g_KeyGrabDist, distance );

			if ( !pEntity.IsBSPModel() && pEntity.IsNetClient() )
			{
				pEntity.pev.movetype = MOVETYPE_PUSH;
				pEntity.pev.flags = FL_FLY;
				pEntity.pev.movedir = g_vecZero; 
				pEntity.pev.solid = SOLID_NOT;
			}

			PushRenderMode( pEntity ); // backup current rendermode
			setRenderMode( pEntity, kRenderTransAdd, kRenderFxPulseFast, 85, Vector( 255, 128, 0 ) );	 
		}		
	}
}
//===========================================================================//