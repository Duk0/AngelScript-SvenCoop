const string Q1_TARBABY_MODEL = "models/quake1/m_tarbaby.mdl";

const string Q1_TARBABY_LAND  = "quake1/monsters/blob/land.wav";
const string Q1_TARBABY_SIGHT = "quake1/monsters/blob/sight.wav";
const string Q1_TARBABY_HIT = "quake1/monsters/blob/hit.wav";
const string Q1_TARBABY_DEATH = "quake1/monsters/blob/death.wav";

const float TAR_TIME_TO_EXLPODE	=	45.0f;	// makes a tarbaby like a snark :-)

class monster_qtarbaby : ScriptBaseMonsterEntity, CQuakeMonster
{
	void Spawn()
	{
		Precache();

		g_EntityFuncs.SetModel( self, Q1_TARBABY_MODEL );
		g_EntityFuncs.SetSize( self.pev, Vector( -16, -16, -24 ), Vector( 16, 16, 40 ) );

		self.pev.solid	= SOLID_SLIDEBOX;
		self.pev.movetype	= MOVETYPE_STEP;
		self.pev.health	= 160;
		
		self.m_bloodColor = DONT_BLEED;

		self.StartMonster();
		self.m_MonsterState = MONSTERSTATE_NONE;

		self.m_FormattedName = "Spawn";
		
		self.pev.pain_finished = 0.0;
		self.pev.yaw_speed = 20;

		WalkMonsterInit ();
	}

	void Precache()
	{
		g_Game.PrecacheModel( Q1_TARBABY_MODEL );

		g_SoundSystem.PrecacheSound( Q1_TARBABY_DEATH );
		g_SoundSystem.PrecacheSound( Q1_TARBABY_HIT );
		g_SoundSystem.PrecacheSound( Q1_TARBABY_LAND );
		g_SoundSystem.PrecacheSound( Q1_TARBABY_SIGHT );
	}

	bool MonsterHasMissileAttack() { return true; }
	bool MonsterHasMeleeAttack() { return true; }
	bool MonsterHasPain() { return false; }
	
	void MonsterSight()
	{
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, Q1_TARBABY_SIGHT, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );
	}

	void MonsterMissileAttack()
	{
		m_iAIState = STATE_ATTACK;
		SetActivity( ACT_LEAP );
	}

	void MonsterMeleeAttack()
	{
		m_iAIState = STATE_ATTACK;
		SetActivity( ACT_LEAP );
	}

	void MonsterIdle()
	{
		m_iAIState = STATE_IDLE;
		SetActivity( ACT_IDLE );
		m_flMonsterSpeed = 0;
		self.pev.pain_finished = 0;
		self.pev.framerate = 1.0f;
	}

	void MonsterWalk()
	{
		m_iAIState = STATE_WALK;
		SetActivity( ACT_WALK );
		m_flMonsterSpeed = 2;
		self.pev.pain_finished = 0;
		self.pev.framerate = 1.0f;
	}

	void MonsterRun()
	{
		m_iAIState = STATE_RUN;
		SetActivity( ACT_RUN );
		m_flMonsterSpeed = 2;
		self.pev.framerate = 1.0f;
	}

	void AI_Run_Melee()
	{
		AI_Face();
	}

	void AI_Run_Missile()
	{
		AI_Face();
	}

	void MonsterAttack()
	{
		if ( self.pev.pain_finished == 0 )
			self.pev.pain_finished = g_Engine.time + TAR_TIME_TO_EXLPODE;

		float speedFactor = 2.0f - ( ( self.pev.pain_finished - g_Engine.time ) / TAR_TIME_TO_EXLPODE );

		// multiply framerate by time to explode
		self.pev.framerate = 1.0f * speedFactor;

		if ( speedFactor >= 2.0f )
		{
			// time to self-destruction
			MonsterKilled( GetWorld().pev, GIB_ALWAYS );
			return;
		}

		if ( m_Activity == ACT_LEAP )
			AI_Face(); // doesn't change when is flying

		if ( !self.m_fSequenceFinished ) return;

		if ( m_Activity == ACT_LEAP )
		{
			MonsterBounce();
			SetActivity( ACT_FLY );
		}
		else if ( m_Activity == ACT_FLY )
		{
			if ( ++self.pev.impulse == 4 )
			{
				SetActivity( ACT_LEAP );
			}
		}
	}

	void MonsterBounce()
	{
		self.pev.movetype = MOVETYPE_BOUNCE;
		SetTouch( TouchFunction( JumpTouch ) );

		Math.MakeVectors( self.pev.angles );

		self.pev.velocity = g_Engine.v_forward * 600.0f + Vector( 0, 0, 200.0f );
		self.pev.velocity.z += Math.RandomFloat( 0.0f, 1.0f ) * 150.0f;
		self.pev.flags &= ~FL_ONGROUND;
		self.pev.impulse = 0;
		self.pev.origin.z++;
	}

	void JumpTouch( CBaseEntity@ pOther )
	{
		if ( self.pev.health <= 0 )
			return;
			
		if ( pOther.pev.takedamage != 0 && self.GetClassname() != pOther.GetClassname() )
		{
			if ( self.pev.velocity.Length() > 400 )
			{
				float ldmg = 10 + Math.RandomFloat( 0.0f, 10.0f );
				if ( pOther.IsPlayer() )
				{
					if ( pOther.pev.armorvalue > 0 )
						ldmg *= 4.0;
					else
						ldmg *= 2.0;
				}

				pOther.TakeDamage( self.pev, self.pev, ldmg, DMG_GENERIC );
				g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, Q1_TARBABY_HIT, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );
			}
		}
		else
		{
			g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, Q1_TARBABY_LAND, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );
		}

		if ( g_EngineFuncs.EntIsOnFloor( self.edict() ) == 0 )
		{
			if ( ( self.pev.flags & FL_ONGROUND ) != 0 )
			{
				self.pev.movetype = MOVETYPE_STEP;

				// jump randomly to not get hung up
				SetTouch( null );
				MonsterRun();
			}
			return;	// not on ground yet
		}

		SetTouch( null );
		
		CBaseEntity@ pEnemy = self.m_hEnemy;

		if ( pEnemy !is null && pEnemy.pev.health > 0 )
		{
			m_iAIState = STATE_ATTACK;
			SetActivity( ACT_LEAP );
		}
		else
		{
			self.pev.movetype = MOVETYPE_STEP;
			self.pev.pain_finished = 0;	// explode cancelling
			MonsterRun();
		}
	}

	void TarExplosion()
	{
	//	q1_RadiusDamage( self, self, 120.0, 120.0 + 40.0, DMG_GENERIC, GetWorld() );

		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, Q1_TARBABY_DEATH, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );

		Vector vecSrc = self.pev.origin - ( 8 * self.pev.velocity.Normalize() );

		NetworkMessage m( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
			m.WriteByte( TE_TAREXPLOSION );
			m.WriteCoord( vecSrc.x );
			m.WriteCoord( vecSrc.y );
			m.WriteCoord( vecSrc.z );
		m.End();

		g_EntityFuncs.Remove( self );
	}

	void MonsterKilled( entvars_t@ pevAttacker, int iGib )
	{
		m_fHasRemove = true;
		SetThink( ThinkFunction( TarExplosion ) );
		self.pev.nextthink = g_Engine.time + 0.2f;
		self.pev.renderfx = kRenderFxExplode;
	}
}

void q1_RegisterMonster_TARBABY()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "monster_qtarbaby", "monster_qtarbaby" );
}
