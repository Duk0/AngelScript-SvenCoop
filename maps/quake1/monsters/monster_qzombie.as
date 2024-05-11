const string Q1_ZOMBIE_MODEL = "models/quake1/m_zombie.mdl";

const string Q1_ZOMBIE_IDLE  = "quake1/monsters/zombie/idle.wav";
const string Q1_ZOMBIE_IDLEC = "quake1/monsters/zombie/idlec.wav";
const string Q1_ZOMBIE_PAIN  = "quake1/monsters/zombie/pain.wav";
const string Q1_ZOMBIE_DEATH = "quake1/monsters/zombie/death.wav";
const string Q1_ZOMBIE_GIB   = "quake1/monsters/zombie/gib.wav";
const string Q1_ZOMBIE_SHOOT = "quake1/monsters/zombie/shoot.wav";
const string Q1_ZOMBIE_HIT   = "quake1/monsters/zombie/hit.wav";
const string Q1_ZOMBIE_MISS  = "quake1/monsters/zombie/miss.wav";

const int SF_SPAWN_CRUCIFIED = 1;

enum Q1_ZOMBIE_EVENTS
{
	ZOMBIE_CRUCIFIED_IDLE_SOUND = 1,
	ZOMBIE_WALK_IDLE_SOUND,
	ZOMBIE_RUN_IDLE_SOUND,
	ZOMBIE_RIGHT_ATTACK,
	ZOMBIE_LEFT_ATTACK,
	ZOMBIE_FALL_SOUND,
	ZOMBIE_TEMP_DEAD
}

class monster_qzombie : ScriptBaseMonsterEntity, CQuakeMonster
{
	private bool m_fDown = false;
	private bool m_fPain = false;

	void Spawn()
	{
		Precache();

		g_EntityFuncs.SetModel( self, Q1_ZOMBIE_MODEL );
		g_EntityFuncs.SetSize( self.pev, Vector( -16, -16, -24 ), Vector( 16, 16, 40 ) );
		self.m_bloodColor = BLOOD_COLOR_RED;

		self.pev.health = 100;
		self.pev.solid = SOLID_SLIDEBOX;
		self.pev.movetype = MOVETYPE_STEP;

		self.StartMonster();
		self.m_MonsterState = MONSTERSTATE_NONE;

		self.m_FormattedName = "Zombie";

		self.pev.pain_finished = 0.0;

		m_iGibHealth = -5;

		if ( self.pev.SpawnFlagBitSet( SF_SPAWN_CRUCIFIED ) )
		{
			self.pev.movetype	= MOVETYPE_NONE;
			self.pev.takedamage	= DAMAGE_NO;

			// static monster as furniture
			m_iAIState = STATE_IDLE;
			SetActivity( ACT_SLEEP );

			SetThink( ThinkFunction( MonsterThink ) );
			self.pev.nextthink = g_Engine.time + ( Math.RandomFloat( 1, 10 ) * 0.1 );
		}
		else
		{
			WalkMonsterInit();
		}
	}

	void Precache()
	{
		g_Game.PrecacheModel( Q1_ZOMBIE_MODEL );
		g_Game.PrecacheModel( "models/quake1/zombiegib.mdl" );

		g_SoundSystem.PrecacheSound( Q1_ZOMBIE_IDLE );
		g_SoundSystem.PrecacheSound( Q1_ZOMBIE_IDLEC );
		g_SoundSystem.PrecacheSound( Q1_ZOMBIE_HIT );
		g_SoundSystem.PrecacheSound( Q1_ZOMBIE_MISS );
		g_SoundSystem.PrecacheSound( Q1_ZOMBIE_DEATH );
		g_SoundSystem.PrecacheSound( Q1_ZOMBIE_GIB );
		g_SoundSystem.PrecacheSound( Q1_ZOMBIE_SHOOT );
		g_SoundSystem.PrecacheSound( Q1_ZOMBIE_PAIN );
	}

	void AI_Idle()
	{
		if ( self.pev.SpawnFlagBitSet( SF_SPAWN_CRUCIFIED ) )
			return; // stay idle

		if ( FindTarget() )
			return;

		if ( g_Engine.time > m_flPauseTime )
		{
			MonsterWalk();
			return;
		}
	}

	void MonsterIdle()
	{
		m_iAIState = STATE_IDLE;
		SetActivity( ACT_IDLE );
		m_flMonsterSpeed = 0;
	}

	void MonsterDefeated()
	{
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, Q1_ZOMBIE_IDLE, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );

		self.pev.health = 60;
		self.pev.solid = SOLID_SLIDEBOX;

		if ( g_EngineFuncs.WalkMove(self.edict(), 0, 0, WALKMOVE_NORMAL ) == 0 )
		{
			// no space to standing up (e.g. player blocked)
			self.pev.solid = SOLID_NOT;
			self.pev.nextthink = g_Engine.time + 5.0f;
		}
		else
		{
			self.ResetSequenceInfo();
			SetThink( ThinkFunction( MonsterThink ) );
			self.pev.nextthink = g_Engine.time + 0.1f;
		}
	}

	void MonsterSight()
	{
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, Q1_ZOMBIE_IDLE, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );
	}

	void MonsterWalk()
	{
		m_iAIState = STATE_WALK;
		SetActivity( ACT_WALK );
		m_flMonsterSpeed = 1;
	}

	void MonsterRun()
	{
		m_iAIState = STATE_RUN;
		SetActivity( ACT_RUN );
		m_flMonsterSpeed = 4;
		self.pev.radsuit_finished = 0.0;
		m_fDown = false;
		m_fPain = false;
	}

	void ThrowMeat( int iAttachment, Vector vecOffset )
	{
		if ( !self.m_hEnemy )
			return;

		CBaseEntity@ pEnemy = self.m_hEnemy;

		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, Q1_ZOMBIE_SHOOT, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );
		q1_ZombieMissile( self, pEnemy, self.pev.origin, vecOffset );

		MonsterRun();
	}

	void MonsterPain( CBaseEntity@ pAttacker, float flDamage )
	{
		self.pev.health = 60; // allways reset health

		if ( flDamage < 9 )
			return; // totally ignore

		if ( m_iAIState != STATE_PAIN )
			g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, Q1_ZOMBIE_PAIN, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 73 + Math.RandomLong( 0, 0x1f ) );

		m_iAIState = STATE_PAIN;

		if ( m_fDown )
			return; // down on ground, so don't reset any counters

		// go down immediately if a big enough hit
		if ( flDamage >= 25 )
		{
			SetActivity( ACT_BIG_FLINCH );
			m_fDown = true;
			AI_Pain( 2 );
			return;
		}

		if ( m_fPain )
		{
			// if hit again in next gre seconds while not in pain frames, definately drop
			self.pev.pain_finished = g_Engine.time + 3;
			return; // currently going through an animation, don't change
		}

		if ( self.pev.pain_finished > g_Engine.time )
		{
			// hit again, so drop down
			SetActivity( ACT_BIG_FLINCH );
			m_fDown = true;
			AI_Pain( 2 );
			return;
		}

		// go into one of the fast pain animations
		m_fPain = true;

		SetActivity( ACT_SMALL_FLINCH );
		AI_PainForward( 3 );
	}

	void MonsterMissileAttack()
	{
		m_iAIState = STATE_ATTACK;
		SetActivity( ACT_MELEE_ATTACK1 );
	}

	bool MonsterHasMissileAttack() { return true; }
	bool MonsterHasMeleeAttack() { return false; }
	bool MonsterHasPain() { return true; }

	void MonsterKilled( entvars_t@ pevAttacker, int iGib )
	{
		m_fHasRemove = true;
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, Q1_ZOMBIE_GIB, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );
		g_EntityFuncs.SpawnRandomGibs( self.pev, 1, 1 );
		g_EntityFuncs.Remove( self );
		return;
	}

	void HandleAnimEvent( MonsterEvent@ pEvent )
	{
		switch ( pEvent.event )
		{
			case ZOMBIE_CRUCIFIED_IDLE_SOUND:
				if ( Math.RandomFloat( 0.0, 1.0 ) < 0.05 )
					g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, Q1_ZOMBIE_IDLEC, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );
				self.pev.framerate = Math.RandomFloat( 0.5, 1.1 ); // randomize animation speed
				break;

			case ZOMBIE_RUN_IDLE_SOUND:
			case ZOMBIE_WALK_IDLE_SOUND:
				if ( Math.RandomFloat( 0.0, 1.0 ) < 0.05 )
					g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, Q1_ZOMBIE_IDLE, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 73 + Math.RandomLong( 0, 0x1f ) );
				break;

			case ZOMBIE_RIGHT_ATTACK:
				ThrowMeat( 1, Vector( -10, 22, 30 ) );
				break;

			case ZOMBIE_LEFT_ATTACK:
				ThrowMeat( 2, Vector( -10, -24, 29 ) );
				break;

			case ZOMBIE_FALL_SOUND:
				if ( self.pev.radsuit_finished == 0.0 )
					g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, Q1_ZOMBIE_DEATH, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );
				break;

			case ZOMBIE_TEMP_DEAD:
				if ( self.pev.radsuit_finished == 0.0 )
				{
					SetThink( ThinkFunction( MonsterDefeated ) );
					self.pev.nextthink = g_Engine.time + 5.0;
					self.StopAnimation(); // stop the animation!
					self.pev.solid = SOLID_NOT;
					self.pev.radsuit_finished = 1.0;
				}
				break;

			default:
				BaseClass.HandleAnimEvent( pEvent );
		}
	}
}

void q1_RegisterMonster_ZOMBIE()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "monster_qzombie", "monster_qzombie" );
}
