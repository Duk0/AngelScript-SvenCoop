string g_szCurrentMap;

enum SPMaps
{
	SP_GAME_BS = 1,
	SP_GAME_OP4
}

dictionary g_dMaps = {
{'ba_canal1', SP_GAME_BS},
{'ba_canal3', SP_GAME_BS},
{'ba_outro', SP_GAME_BS},
{'ba_power1', SP_GAME_BS},
{'ba_power2', SP_GAME_BS},
{'ba_tram1', SP_GAME_BS},
{'ba_xen1', SP_GAME_BS},
{'ba_xen2', SP_GAME_BS},
{'ba_xen3', SP_GAME_BS},
{'ba_xen5', SP_GAME_BS},
{'ba_yard2', SP_GAME_BS},
{'ba_yard4', SP_GAME_BS},
{'ba_yard5', SP_GAME_BS}
/*
{'of0a0', SP_GAME_OP4},
{'of1a1', SP_GAME_OP4},
{'of1a2', SP_GAME_OP4},
{'of1a4b', SP_GAME_OP4},
{'of1a5', SP_GAME_OP4},
{'of1a6', SP_GAME_OP4},
{'of2a1b', SP_GAME_OP4},
{'of2a6', SP_GAME_OP4},
{'of3a2', SP_GAME_OP4},
{'of3a4', SP_GAME_OP4},
{'of3a6', SP_GAME_OP4},
{'of4a1', SP_GAME_OP4},
{'of4a4', SP_GAME_OP4},
{'of5a2', SP_GAME_OP4},
{'of5a4', SP_GAME_OP4},
{'of6a1', SP_GAME_OP4},
{'of6a4b', SP_GAME_OP4},
{'of6a5', SP_GAME_OP4}*/
};

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Duko" );
	g_Module.ScriptInfo.SetContactInfo( "group.midu.cz" );
}

void MapInit()
{
	g_szCurrentMap = g_Engine.mapname;

	RegisterTriggerMP3Audio();
}

void MapActivate()
{
	ReplaceCDAudio();
}

class CDAudioData
{
	bool istrigger;
	string targetname;
	string model;
	float health;
	float delay;
}

void RegisterTriggerMP3Audio()
{
	if ( !g_dMaps.exists( g_szCurrentMap ) )
		return;

	g_CustomEntityFuncs.RegisterCustomEntity( "trigger_mp3audio", "trigger_mp3audio" );
	g_CustomEntityFuncs.RegisterCustomEntity( "target_mp3audio", "target_mp3audio" );
}

void ReplaceCDAudio()
{
	int iGame = -1;
	if ( !g_dMaps.get( g_szCurrentMap, iGame ) )
		return;

	CBaseEntity@ pEntity = null, pEnt;
	CBaseDelay@ pDelay;
	array<CDAudioData> pStored;
	CDAudioData data;

	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "trigger_cdaudio" ) ) !is null )
	{
		data.istrigger = true;
		data.targetname = pEntity.GetTargetname();
		data.model = pEntity.pev.model;
		data.health = pEntity.pev.health;

		@pDelay = cast<CBaseDelay@>( pEntity );
		if ( pDelay !is null )
			data.delay = pDelay.m_flDelay;

		pStored.insertLast( data );

		g_EntityFuncs.Remove( pEntity );
	}

	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "target_cdaudio" ) ) !is null )
	{
		data.istrigger = false;
		data.targetname = pEntity.GetTargetname();
		data.health = pEntity.pev.health;

		@pDelay = cast<CBaseDelay@>( pEntity );
		if ( pDelay !is null )
			data.delay = pDelay.m_flDelay;
			
		pStored.insertLast( data );

		g_EntityFuncs.Remove( pEntity );
	}

	for ( uint i = 0; i < pStored.length(); i++ )
	{
		data = pStored[i];
	
		@pEnt = g_EntityFuncs.Create( data.istrigger ? "trigger_mp3audio" : "target_mp3audio", g_vecZero, g_vecZero, true );
		if ( pEnt is null )
			continue;
			
		if ( data.istrigger )
			pEnt.pev.model = data.model;

		switch ( iGame )
		{
			case SP_GAME_BS: pEnt.pev.health = BShiftAudioTrack( data.health ); break;
			case SP_GAME_OP4: pEnt.pev.health = data.health; break;
		}
		
		if ( g_szCurrentMap == "ba_canal1" )
			data.delay += 17;
		
		if ( data.delay > 0 )
			pEnt.pev.fuser1 = data.delay;

		if ( g_szCurrentMap == "ba_tram1" )
			data.targetname = "mp3audio";
		if ( !data.targetname.IsEmpty() )
			pEnt.pev.targetname = data.targetname;
			
		g_EntityFuncs.DispatchSpawn( pEnt.edict() );
	}

	if ( g_szCurrentMap == "ba_tram1" )
	{
		@pEntity = g_EntityFuncs.FindEntityByTargetname( null, "start_titles" );
		if ( pEntity !is null )
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "mp3audio", "15" );
	}

/*	if ( g_szCurrentMap == "ba_canal1" )
	{
		@pEntity = null;
			
		while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "trigger_auto" ) ) !is null )
		{
			if ( !pEntity.HasTarget( "start_seq" ) )
				continue;
			
			g_EntityFuncs.Remove( pEntity );
			
			g_EngineFuncs.ServerPrint( "Removed trigger_auto\n" );
		}
	
		@pEnt = g_EntityFuncs.Create( "trigger_relay", g_vecZero, g_vecZero, true );
		if ( pEnt !is null )
		{
			pEnt.pev.targetname = "game_playerspawn";
			pEnt.pev.target = "start_seq";
			pEnt.pev.spawnflags = 1;
			
			g_EntityFuncs.DispatchSpawn( pEnt.edict() );
		}
	}*/

	if ( g_szCurrentMap == "ba_outro" )
	{
		@pEntity = g_EntityFuncs.FindEntityByTargetname( null, "jp_endgame" );
		if ( pEntity !is null )
			pEntity.pev.targetname = "msg_thanks_to";
			
		@pEntity = null;
			
		while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "env_message" ) ) !is null )
			pEntity.pev.spawnflags = 3;
	}
}

int BShiftAudioTrack( float flTrack )
{
	int iTrack = int( flTrack );

	switch ( iTrack )
	{
		case 8: iTrack = 16; break;
		case 5: iTrack = 13; break;
		case 20: iTrack = 9; break;
		case 7: iTrack = 15; break;
		case 15: iTrack = 4; break;
		case 3: iTrack = 11; break; // ba_tram1 title_manager "mp3audio" "4"
		case 4: iTrack = 12; break;
		case 10: iTrack = 18; break;
		case 11: iTrack = 19; break; // "delay" "12"
		case 12: iTrack = 2; break; // "delay" "10"
		case 14: iTrack = 3; break; // "delay" "12"
		case 16: iTrack = 5; break;
	}
	
	return iTrack;
}

const array<string> g_szTrack = { "dummy", "dummy",
"half-life01", "prospero01", "half-life12",
"half-life07", "half-life10", "suspense01",
"suspense03", "half-life09", "half-life02",
"half-life13", "half-life04", "half-life15",
"half-life14", "half-life16", "suspense02",
"half-life03", "half-life08", "prospero02",
"half-life05" };

class trigger_mp3audio : ScriptBaseEntity
{
	void Precache()
	{
		BaseClass.Precache();

		string szTrack = GetTrack( int( self.pev.health ) );
		if ( !szTrack.IsEmpty() )
			g_Game.PrecacheGeneric( szTrack );
	}
	
	void Spawn()
	{
		if ( self.pev.angles != g_vecZero )
			SetMovedir( self.pev );

		self.pev.movetype 		= MOVETYPE_NONE;
		self.pev.solid 			= SOLID_TRIGGER;

		g_EntityFuncs.SetModel( self, self.pev.model );
		
		if ( g_EngineFuncs.CVarGetFloat( "showtriggers" ) == 0 )
			self.pev.effects |= EF_NODRAW;
			
		self.Precache();
	}
	
	void Touch( CBaseEntity@ pOther )
	{
		if ( !pOther.IsPlayer() )
			return;
		
		float flDelay = self.pev.fuser1;
		if ( flDelay > 0 )
			g_Scheduler.SetTimeout( @this, "Play", flDelay );
		else
			Play();
	}

	void Use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float value )
	{
		float flDelay = self.pev.fuser1;
		if ( flDelay > 0 )
			g_Scheduler.SetTimeout( @this, "Play", flDelay );
		else
			Play();

		//g_Log.PrintF( "[GearBoxOST] flDelay = " + flDelay + "\n" );
	}
	
	void Play()
	{
		PlayMP3Track( int( self.pev.health ) );
		g_EntityFuncs.Remove( self );
	}
}

class target_mp3audio : ScriptBaseEntity
{
	void Precache()
	{
		BaseClass.Precache();

		string szTrack = GetTrack( int( self.pev.health ) );
		if ( !szTrack.IsEmpty() )
			g_Game.PrecacheGeneric( szTrack );
	}
	
	void Spawn()
	{
		self.pev.movetype 		= MOVETYPE_NONE;
		self.pev.solid 			= SOLID_NOT;
			
		self.Precache();
	}

	void Use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float value )
	{
		float flDelay = self.pev.fuser1;
		if ( flDelay > 0 )
			g_Scheduler.SetTimeout( @this, "Play", flDelay );
		else
			Play();
	}
	
	void Play()
	{
		PlayMP3Track( int( self.pev.health ) );
		g_EntityFuncs.Remove( self );
	}
}

void SetMovedir( entvars_t@ pVars )
{
	if ( pVars.angles == Vector( 0, -1, 0 ) )
		pVars.movedir = Vector( 0, 0, 1 );
	else if ( pVars.angles == Vector( 0, -2, 0 ) )
		pVars.movedir = Vector( 0, 0, -1 );
	else
	{
		g_EngineFuncs.MakeVectors( pVars.angles );
		pVars.movedir = g_Engine.v_forward;
	}
	
	pVars.angles = g_vecZero;
}

string GetTrack( int iTrack )
{
	if ( iTrack < 2 || iTrack > 20 )
		return "";

	string szBuff = g_szTrack[ iTrack ];
	if ( szBuff == "dummy" )
		return "";

	string szTrack;
	snprintf( szTrack, "sound/opfor/%1.mp3", szBuff );
	return szTrack;
}

void PlayMP3Track( int iTrack )
{
	if ( iTrack < -1 || iTrack > 20 )
	{
		g_Game.AlertMessage( at_console, "TriggerMP3Audio - Track %d out of range\n" );
		return;
	}

	string szCmd;

	if ( iTrack == -1 )
		szCmd = ";mp3 stop";
	else
	{
		string szTrack = GetTrack( iTrack );
		if ( szTrack.IsEmpty() )
			return;

		szCmd = ";mp3 play " + szTrack;
	}

	NetworkMessage message( MSG_ALL, NetworkMessages::Speaksent );
	message.WriteString( szCmd );
	message.End();
}
