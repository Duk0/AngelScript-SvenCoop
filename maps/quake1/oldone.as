const string Q1_OLDONE_MODEL = "models/quake1/oldone.mdl";

const string Q1_OLDONE_IDLE  = "quake1/monsters/boss2/idle.wav";
const string Q1_OLDONE_SIGHT = "quake1/monsters/boss2/sight.wav";
const string Q1_OLDONE_POP = "quake1/monsters/boss2/pop.wav";
const string Q1_OLDONE_DEATH = "quake1/monsters/boss2/death.wav";

class CShubNiggurath : ScriptBaseAnimating
{
	public:
		void Spawn( void );
		void Precache( void );
		void Killed( entvars_t *pevAttacker, int iGib );

		void EXPORT DeathThink( void );
		void EXPORT Finale2( void );
		void EXPORT Finale3( void );
		void EXPORT Finale4( void );
		void EXPORT Finale5( void );
	};

	//=========================================================
	// Spawn
	//=========================================================
	void Spawn()
	{
		Precache( );

		g_EntityFuncs.SetModel( self, Q1_OLDONE_MODEL );
		g_EntityFuncs.SetSize( self.pev, Vector( -160, -128, -24 ), Vector( 160, 128, 256 ) );

		self.pev.solid	= SOLID_BBOX;	// g-cont. allow hitbox trace!
		self.pev.movetype = MOVETYPE_STEP;
		self.pev.health	= 40000;

		self.pev.takedamage = DAMAGE_YES;
		self.pev.animtime = g_Engine.time + 0.1;
		self.pev.framerate = 1.0;

		gpWorld->total_monsters++;
	}

	//=========================================================
	// Precache - precaches all resources this monster needs
	//=========================================================
	void Precache()
	{
		g_Game.PrecacheModel( Q1_OLDONE_MODEL );

		g_SoundSystem.PrecacheSound( Q1_OLDONE_DEATH );
		g_SoundSystem.PrecacheSound( Q1_OLDONE_IDLE );
		g_SoundSystem.PrecacheSound( Q1_OLDONE_SIGHT );
		g_SoundSystem.PrecacheSound( Q1_OLDONE_POP );
		g_SoundSystem.PrecacheSound( "ambience/rumble.wav" );
	}

	void Killed( entvars_t@ pevAttacker, int iGib )
	{
		g_intermission_exittime = g_Engine.time + 10000000;	// never allow exit
		g_intermission_running = 1;

		CBaseEntity@ pCamera = g_EntityFuncs.FindEntityByClassname( null, "info_intermission" );
		CBaseEntity@ pTeleport = g_EntityFuncs.FindEntityByClassname( null, "misc_teleporttrain" );

		self.pev.takedamage = DAMAGE_NO;

		if ( pTeleport !is null )
			g_EntityFuncs.Remove( pTeleport );

		CBasePlayer@ pPlayer;

		for ( int i = 1; i <= g_Engine.maxClients; i++ )
		{
			@pPlayer = g_PlayerFuncs.FindPlayerByIndex( i  );

			if ( pPlayer is null ) continue;

			if ( pCamera !is null )
			{
				g_EngineFuncs.SetView( pPlayer.edict(), pCamera.edict() );
				g_EntityFuncs.SetOrigin( pPlayer, pCamera.pev.origin );
			}

			pPlayer.EnableControl( false );
			pPlayer.pev.takedamage = DAMAGE_NO;
			pPlayer.pev.solid = SOLID_NOT;
			pPlayer.pev.movetype = MOVETYPE_NONE;
			pPlayer.pev.modelindex = 0;
			pPlayer.m_iHideHUD |= HIDEHUD_HUD;
/*
			NetworkMessage message( MSG_ONE, NetworkMessages::HideHUD, pPlayer.edict() );
				message.WriteByte( 1 ); // hide scoreboard and HUD
			message.End();*/
		}

		NetworkMessage message( MSG_ALL, NetworkMessages::HideHUD );
			message.WriteByte( 1 ); // hide scoreboard and HUD
		message.End();

		// make fake versions of all players as standins, and move the real
		// players to the intermission spot

		// wait for 1 second
		SetThink( Finale2 );
		self.pev.nextthink = g_Engine.time + 1.0f;
	}

	void Finale2()
	{
		Vector telePos = self.pev.origin - Vector( 0, 100, 0 );

		MESSAGE_BEGIN( MSG_PAS, gmsgTempEntity, telePos );
			WRITE_BYTE( TE_TELEPORT );
			WRITE_COORD( telePos.x );
			WRITE_COORD( telePos.y );
			WRITE_COORD( telePos.z );
		MESSAGE_END();

		EMIT_SOUND( ENT(pev), CHAN_VOICE, "misc/r_tele1.wav", 1, ATTN_NORM );

		SetThink( Finale3 );
		self.pev.nextthink = g_Engine.time + 2.0f;
	}

	void Finale3()
	{
		EMIT_SOUND( ENT(pev), CHAN_VOICE, Q1_OLDONE_DEATH, 1, ATTN_NORM );
		EMIT_SOUND( ENT(pev), CHAN_BODY, "ambience/rumble.wav", 1, ATTN_NORM );
		g_EngineFuncs.LightStyle( 0, "abcdefghijklmlkjihgfedcb" );	// apply to world
		g_PlayerFuncs.ScreenShake( self.pev.origin, 32.0f, 8.0f, 8.0f, 500.0f );

		SetThink( DeathThink );
		self.pev.nextthink = g_Engine.time + 2.0f;
	}

	void DeathThink()
	{
		if ( self.pev.sequence == 0 )
		{
			g_EngineFuncs.LightStyle( 0, "mkkigecacegikmm" );	// apply to world
			self.pev.sequence = 1;	// shake
			ResetSequenceInfo();
			self.pev.frame = 0.0f;
		}

		StudioFrameAdvance( );

		if ( self.m_fSequenceFinished )
		{
			if ( pev->sequence == 2 )
						{
				SetThink( NULL );
				Finale4();
				return;
			}

			ResetSequenceInfo();
			self.pev.frame = 0.0f;

			// play three times
			if ( ++self.pev.impulse > 2 )
			{
				self.pev.sequence = 2;	// explode
				ResetSequenceInfo();
				self.pev.frame = 0.0f;
			}
		}

		g_PlayerFuncs.ScreenShake( self.pev.origin, 32.0f, 8.0f, 1.0f, 500.0f );
		self.pev.nextthink = g_Engine.time + 0.1f;
	}

	void Finale4()
	{
		EMIT_SOUND( ENT(pev), CHAN_VOICE, Q1_OLDONE_POP, 1, ATTN_NORM );

		Vector vecSrc = self.pev.origin;
		float x, y, z;

		self.pev.health = -999;

		z = 16;
		while ( z <= 144 )
		{
			x = -64;
			while ( x <= 64 )
			{
				y = -64;
				while ( y <= 64 )
				{
					self.pev.origin.x = vecSrc.x + x;
					self.pev.origin.y = vecSrc.y + y;
					self.pev.origin.z = vecSrc.z + z;

					float r = Math.RandomFloat( 0.0f, 1.0f );
					if ( r < 0.3f )				
						CGib::ThrowGib( "models/gib1.mdl", pev );
					else if ( r < 0.6f )
						CGib::ThrowGib( "models/gib2.mdl", pev );
					else
						CGib::ThrowGib( "models/gib3.mdl", pev );
					y = y + 32;
				}
				x = x + 32;
			}
			z = z + 96;
		}

		// start the end text
		for ( int i = 1; i <= g_Engine.maxClients; i++ )
		{
			CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( i );

			if ( pPlayer is null ) continue;
			CenterPrint( pPlayer->pev, "GameFinale" );
			g_engfuncs.pfnFadeClientVolume( pPlayer->edict(), 100, 5, 150, 5 );
		}

		gpWorld->killed_monsters++;

		// just an event to increase internal client counter
		MESSAGE_BEGIN( MSG_ALL, gmsgKilledMonster );
		MESSAGE_END();

		// g-cont. i can see no reason to remove the oldone and the spawn fake client entity
		// i've just replace model :-)
		g_EntityFuncs.SetModel( self, "models/player.mdl" );
		g_EntityFuncs.SetOrigin( self, vecSrc - Vector( 32, 264, -12 ) );
		self.pev.weaponmodel = string_t( "models/p_crowbar.mdl" );
		self.pev.angles = Vector( 0, 275, 0 );
		self.pev.effects |= EF_NOINTERP;

		STOP_SOUND( (pev), CHAN_BODY, "ambience/rumble.wav" );

		MESSAGE_BEGIN( MSG_ALL, SVC_CDTRACK );
			WRITE_BYTE( 13 );
			WRITE_BYTE( 12 );
		MESSAGE_END();

		g_EngineFuncs.LightStyle( 0, "m" );

		SetThink( Finale5 );
		self.pev.nextthink = g_Engine.time + 40;
	}

	void Finale5()
	{
		g_PlayerFuncs.ScreenFadeAll( g_vecZero, 12.0f, 0.f, 255, FFADE_OUT|FFADE_STAYOUT );
		g_engfuncs.pfnEndSection( "oem_end_credits" );
	}
}

void q1_RegisterOldOne()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "CShubNiggurath", "monster_qoldone" );
}
