int g_iTotalSecrets = 0;
int g_iFoundSecrets = 0;
int g_iTotalMonsters = 0;
int g_iKilledMonsters = 0;

bool g_bShowQuickStats = false;
string g_szIntermissionMsg = "empty";
bool g_bMultipleExit = false;

void q1_ActivateScretCounter()
{
	CBaseEntity@ pEntity = null;
	CBaseEntity@ pEnt;
	string szMessage, szTargetName;

	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "trigger_once" ) ) !is null )
	{
		szMessage = pEntity.pev.message;
	
		if ( szMessage.IsEmpty() )
			continue;

		if ( szMessage != "You've found a secret!" )
			continue;

		if ( !string( pEntity.pev.target ).IsEmpty() )
			continue;

		g_iTotalSecrets++;
		
		pEntity.pev.target = string_t( "q1_secret_counter" );

		szTargetName = pEntity.GetTargetname();

		if ( szTargetName.IsEmpty() )
			continue;

		@pEnt = g_EntityFuncs.Create( "env_message", g_vecZero, g_vecZero, true );
		if ( pEnt is null )
			continue;
		
		pEnt.pev.targetname = szTargetName;
		pEnt.pev.message = szMessage;
		pEnt.pev.target = pEntity.pev.target;
		pEnt.pev.spawnflags = 1;

		g_EntityFuncs.DispatchSpawn( pEnt.edict() );
		
		g_EntityFuncs.Remove( pEntity );
	}

	if ( g_iTotalSecrets > 0 )
	{
		const string szEntFile = "quake1/ents/secret_counter.ent";

		if ( !g_EntityLoader.LoadFromFile( szEntFile ) )
			g_EngineFuncs.ServerPrint( "Can't open " + szEntFile + "\n" );

		g_bShowQuickStats = true;
	}

	if ( !g_bShowQuickStats && g_iTotalMonsters > 0 )
		g_bShowQuickStats = true;
	
	int iCount = 0;
	
	bool bHasSecretMap = ( g_Engine.mapname == "q1_e1m4" );

	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "trigger_changelevel" ) ) !is null )
	{
		if ( !pEntity.GetTargetname().IsEmpty() )
			continue;
			
		iCount++;

		pEntity.pev.solid = SOLID_NOT;
	//	pEntity.pev.spawnflags |= 2;
		pEntity.pev.targetname = string_t( "intermission" + iCount );

		@pEnt = g_EntityFuncs.Create( "trigger_qintermission", pEntity.GetOrigin(), g_vecZero, true );
		if ( pEnt is null )
			continue;

		pEnt.pev.model = pEntity.pev.model;
		pEnt.pev.spawnflags = pEntity.pev.spawnflags;
		pEnt.pev.target = string_t( "intermission" + iCount );
		
		if ( bHasSecretMap && pEnt.pev.model == "*69" ) // "map" "q1_e1m8"
			pEnt.pev.iuser1 = 1;

		g_EntityFuncs.DispatchSpawn( pEnt.edict() );
	}
	
	g_bMultipleExit = bHasSecretMap && ( iCount > 1 );

	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "info_intermission" ) ) !is null )
	{
/*		@pEnt = g_EntityFuncs.Create( "info_target", pEntity.GetOrigin(), g_vecZero, true );
		if ( pEnt is null )
			continue;

		iCount++;
			
		pEnt.pev.targetname = string_t( "q1_camera_target_" + iCount );
		
		g_EntityFuncs.DispatchSpawn( pEnt.edict() );*/

/*
		@pEnt = g_EntityFuncs.Create( "trigger_camera", pEntity.GetOrigin(), g_vecZero, true );
		if ( pEnt is null )
			continue;
	
		pEnt.pev.spawnflags = 24;
		pEnt.pev.targetname = string_t( "q1_camera" );
	//	pEnt.pev.target = string_t( "q1_camera_target_" + iCount );
		pEnt.pev.angles = Vector( 35, 45, 0 );

		g_EntityFuncs.DispatchKeyValue( pEnt.edict(), "wait", "5" );
		
		g_EntityFuncs.DispatchSpawn( pEnt.edict() );*/

/*		@pEnt = g_EntityFuncs.Create( "info_target", pEntity.GetOrigin(), g_vecZero, true );
		if ( pEnt is null )
			continue;
	
		pEnt.pev.targetname = string_t( "q1_camera" );
		
		g_EntityFuncs.DispatchSpawn( pEnt.edict() );*/
		
		g_EntityFuncs.Remove( pEntity );
	}
}

void SecretCounter( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
{
	g_iFoundSecrets++;
}

void MakeStats( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
{
	MakeStatsMsg();
}

void ShowStats( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
{
	if ( g_szIntermissionMsg.IsEmpty() )
		return;
	
	Message( null, g_szIntermissionMsg, -1, -1, 18 );
}

void MakeStatsMsg()
{
	int iTime = int( g_Engine.time );
	snprintf( g_szIntermissionMsg, "COMPLETED\n\nTime     %1:%2\n\nSecrets     %3/%4     \n\nKills     %5/%6", AttachSpacePad( iTime / 60 ),
				AttachSpacePad( iTime % 60, false, true ), AttachSpacePad( g_iFoundSecrets ), AttachSpacePad( g_iTotalSecrets, false ),
				AttachSpacePad( g_iKilledMonsters ), AttachSpacePad( g_iTotalMonsters, false ) );
}

string AttachSpacePad( int iNum, bool bFront = true, bool bZero = false )
{
	string szTemp = string( iNum );
	
	if ( szTemp.Length() == 1 )
	{
		if ( bZero ) {
			if ( bFront )
				return " 0" + szTemp;
			else
				return "0" + szTemp + " ";
		} else {
			if ( bFront )
				return " " + szTemp;
			else
				return szTemp + " ";
		}
	}
	
	return szTemp;
}

/*
CBaseEntity@ FindIntermission()
{
	CBaseEntity@ pSpot = g_EntityFuncs.FindEntityByClassname( null, "info_intermission" );
	CBaseEntity@ pNewSpot;

	if ( pSpot !is null )
	{
		// at least one intermission spot in the world.
		int iRand = Math.RandomLong( 0, 3 );

		while ( iRand > 0 )
		{
			@pNewSpot = g_EntityFuncs.FindEntityByClassname( pSpot, "info_intermission" );
			
			if ( pNewSpot !is null )
				@pSpot = pNewSpot;

			iRand--;
		}
	}
	
	return pSpot;
}
*/
void Message( CBasePlayer@ pPlayer, const string& in szText, float x = -1, float y = -1, float holdTime = 10.0f )
{
	HUDTextParams txtPrms;

	txtPrms.x = x;
	txtPrms.y = y;
	txtPrms.effect = 0;

	// Text colour
	txtPrms.r1 = 255;
	txtPrms.g1 = 150;
	txtPrms.b1 = 50;
	txtPrms.a1 = 255;

	// Fade-in colour
	txtPrms.r2 = 255;
	txtPrms.g2 = 0;
	txtPrms.b2 = 0;
	txtPrms.a2 = 200;
	
	txtPrms.fadeinTime = 0.0f;
	txtPrms.fadeoutTime = 0.0f;
	txtPrms.holdTime = holdTime + 2.0f;
	txtPrms.fxTime = 0.0f;
	txtPrms.channel = 1;
	
	if ( pPlayer !is null )
		g_PlayerFuncs.HudMessage( pPlayer, txtPrms, szText );
	else
		g_PlayerFuncs.HudMessageAll( txtPrms, szText );

	g_bShowQuickStats = false;
}

class CTriggerIntermission : ScriptBaseEntity
{
	private string m_szTarget;
	private float m_flDelay = 22.0f;
	private bool m_bVoteResult = false;
	private bool m_bVoteStarted = false;
	private bool m_bVoteIgnored = false;

	void Spawn()
	{
		if ( self.pev.angles != g_vecZero )
			SetMovedir( self.pev );

		self.pev.movetype = MOVETYPE_NONE;
		self.pev.solid = SOLID_TRIGGER;

		g_EntityFuncs.SetModel( self, self.pev.model );
		
		if ( g_EngineFuncs.CVarGetFloat( "showtriggers" ) == 0 )
			self.pev.effects |= EF_NODRAW;

		m_szTarget = self.pev.target;
		m_bVoteIgnored = ( self.pev.iuser1 == 1 );

		if ( m_flDelay < 10.0 )
			m_flDelay = 10.0f;

		if ( self.pev.SpawnFlagBitSet( 1 ) )
			SetTouch( TouchFunction( NormalTouch ) );
		else
			SetTouch( TouchFunction( IntermissionTouch ) );
	}

	void IntermissionTouch( CBaseEntity@ pOther )
	{
		if ( !pOther.IsPlayer() )
			return;

		if ( m_szTarget.IsEmpty() )
			return;

		if ( m_bVoteStarted )
			return;

		if ( g_bMultipleExit && !m_bVoteIgnored && !m_bVoteResult && g_iTotalSecrets > 0 && g_iFoundSecrets < g_iTotalSecrets )
		{
			StartExitVote();
			return;
		}

/*		CBaseEntity@ pCamera = FindIntermission();

		if ( pCamera !is null )
		{
			CBasePlayer@ pTarget;
			for ( int iTarget = 1; iTarget <= g_Engine.maxClients; iTarget++ )
			{
				@pTarget = g_PlayerFuncs.FindPlayerByIndex( iTarget );
				if ( pTarget is null || !pTarget.IsConnected() )
					continue;

				g_EngineFuncs.SetView( pTarget.edict(), pCamera.edict() );
				g_EntityFuncs.SetOrigin( pTarget, pCamera.pev.origin );

				pTarget.EnableControl( false );
				pTarget.pev.takedamage = DAMAGE_NO;
				pTarget.pev.solid = SOLID_NOT;
				pTarget.pev.movetype = MOVETYPE_NONE;
				pTarget.m_iHideHUD |= 1;
			}
		}*/

		SetTouch( null );

		NetworkMessage message( MSG_ALL, NetworkMessages::HideHUD );
			message.WriteByte( 1 ); // hide scoreboard and HUD
		message.End();
		
		CBaseEntity@ pMusic = g_EntityFuncs.FindEntityByTargetname( null, "q1_music" );
		if ( pMusic !is null )
		{
			pMusic.Use( self, self, USE_OFF );
			g_SoundSystem.PlaySound( pMusic.edict(), CHAN_MUSIC, "quake1/music/track03.ogg", 0.7, ATTN_NONE );
		}

		CBaseEntity@ pCamera = g_EntityFuncs.RandomTargetname( "q1_camera" );
		if ( pCamera !is null )
			pCamera.Use( self, self, USE_ON );

/*
		NetworkMessage message( MSG_ALL, NetworkMessages::SVC_INTERMISSION );
		message.End();*/

		MakeStatsMsg();

		if ( !g_szIntermissionMsg.IsEmpty() )
		{
			Message( null, g_szIntermissionMsg, -1, -1, m_flDelay );
		//	g_PlayerFuncs.ClientPrintAll( HUD_PRINTCENTER, g_szIntermissionMsg );
		}

		//g_EntityFuncs.FireTargets( m_szTarget, null, null, USE_TOGGLE, 0, 10.0 );
		
		SetThink( ThinkFunction( IntermissionThink ) );
		self.pev.nextthink = g_Engine.time + m_flDelay;

	//	SetTouch( null );
	}

	void NormalTouch( CBaseEntity@ pOther )
	{
		if ( m_szTarget.IsEmpty() )
			return;

		if ( !pOther.IsPlayer() )
			return;

	//	g_EntityFuncs.FireTargets( m_szTarget, null, null, USE_TOGGLE );
	//	self.SUB_UseTargets( pOther, USE_TOGGLE, 0 );

		CBaseEntity@ pEntity = g_EntityFuncs.FindEntityByTargetname( null, m_szTarget );
		if ( pEntity !is null )
			pEntity.Touch( pOther );

	//	SetTouch( null );
	}
/*
	void Touch( CBaseEntity@ pOther )
	{
		if ( !pOther.pev.FlagBitSet( FL_CLIENT ) )
			return;

		g_EntityFuncs.Remove( self );
	}*/
	
	void IntermissionThink()
	{
		if ( m_szTarget.IsEmpty() )
			return;

		CBaseEntity@ pEntity = g_EntityFuncs.FindEntityByTargetname( null, m_szTarget );
		if ( pEntity !is null )
		{
			CBaseEntity@ pEnt = null;
			while ( ( @pEnt = g_EntityFuncs.FindEntityByClassname( pEnt, "player" ) ) !is null )
			{
				pEntity.Touch( pEnt );
				break;
			}
		}

		SetThink( null );
	}

	void StartExitVote()
	{
		Vote vote( "Quake exit map vote", "There is other exit to the secret level.\nWould you like exit this map?", 15, 51 );

		vote.SetVoteBlockedCallback( VoteBlocked( this.VoteExitBlocked ) );
		vote.SetVoteEndCallback( VoteEnd( this.VoteExitEnd ) );
		
		vote.Start();
		
		m_bVoteStarted = true;
	}
	
	void VoteExitBlocked( Vote@ pVote, float flTime )
	{
		//Schedule to vote again after the current vote has finished
		g_Scheduler.SetTimeout( @this, "StartExitVote", flTime - g_Engine.time );
	}
	
	void VoteExitEnd( Vote@ pVote, bool bResult, int iVoters )
	{
		m_bVoteResult = bResult;
		
		m_bVoteStarted = false;

		if ( bResult )
		{
			CBaseEntity@ pEnt = null;
			while ( ( @pEnt = g_EntityFuncs.FindEntityByClassname( pEnt, "player" ) ) !is null )
			{
				IntermissionTouch( pEnt );
				break;
			}
		}
	}
}

void q1_RegisterIntermission()
{
	g_CustomEntityFuncs.RegisterCustomEntity ( "CTriggerIntermission", "trigger_qintermission" );

	g_SoundSystem.PrecacheSound( "quake1/music/track03.ogg" );
}
