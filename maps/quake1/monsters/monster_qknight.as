const string Q1_KNIGHT_MODEL = "models/quake1/m_knight.mdl";

const string Q1_KNIGHT_IDLE  = "quake1/monsters/knight/idle.wav";
const string Q1_KNIGHT_SIGHT = "quake1/monsters/knight/sight.wav";
const string Q1_KNIGHT_PAIN = "quake1/monsters/knight/pain.wav";
const string Q1_KNIGHT_DEATH = "quake1/monsters/knight/death.wav";

const array<string> Q1_KNIGHT_MELEE = 
{
	"quake1/monsters/knight/sword1.wav",
	"quake1/monsters/knight/sword2.wav",
};

enum Q1_KNIGHT_EVENTS
{
	KNIGHT_START_RUNATTACK = 1,
	KNIGHT_END_RUNATTACK,
	KNIGHT_IDLE_SOUND
}

class monster_qknight : ScriptBaseMonsterEntity, CQuakeMonster
{
	void Spawn()
	{
		Precache();

		g_EntityFuncs.SetModel( self, Q1_KNIGHT_MODEL );
		g_EntityFuncs.SetSize( self.pev, Vector( -16, -16, -24 ), Vector( 16, 16, 40 ) );
		self.m_bloodColor = BLOOD_COLOR_RED;

		self.pev.health = 150;
		self.pev.solid = SOLID_SLIDEBOX;
		self.pev.movetype = MOVETYPE_STEP;

		self.StartMonster();
		self.m_MonsterState = MONSTERSTATE_NONE;

		self.m_FormattedName = "Knight";

		self.pev.pain_finished = 0.0;
		self.pev.yaw_speed = 15;

		m_iGibHealth = -40;

		WalkMonsterInit();
	}

	void Precache()
	{
		g_Game.PrecacheModel( Q1_KNIGHT_MODEL );

		g_SoundSystem.PrecacheSound( Q1_KNIGHT_IDLE );
		g_SoundSystem.PrecacheSound( Q1_KNIGHT_SIGHT );
		g_SoundSystem.PrecacheSound( Q1_KNIGHT_DEATH );
		for ( uint i = 0; i < Q1_KNIGHT_MELEE.length(); ++i )
			g_SoundSystem.PrecacheSound( Q1_KNIGHT_MELEE[i] );

		g_SoundSystem.PrecacheSound( Q1_KNIGHT_PAIN );
	}

	void MonsterIdle()
	{
		m_iAIState = STATE_IDLE;
		SetActivity( ACT_IDLE );
		m_flMonsterSpeed = 0;
	}

	void MonsterSight()
	{
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, Q1_KNIGHT_SIGHT, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );
	}

	void MonsterWalk()
	{
		m_iAIState = STATE_WALK;
		SetActivity( ACT_WALK );
		m_flMonsterSpeed = 5;
		AI_Turn();
	}

	void MonsterRun()
	{
		m_iAIState = STATE_RUN;
		SetActivity( ACT_RUN );
		m_flMonsterSpeed = 18;
	}

	void MonsterMeleeAttack()
	{
		m_iAIState = STATE_ATTACK;

		if ( !self.m_hEnemy )
			return;

		CBaseEntity@ pEnemy = self.m_hEnemy;

		float flDist = ( pEnemy.EyePosition() - self.EyePosition() ).Length();

		int i = Math.RandomLong( 0, 1 );
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, Q1_KNIGHT_MELEE[i], Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );

		if ( flDist < 80 )
		{
			SetActivity( ACT_MELEE_ATTACK1 );
			m_flMonsterSpeed = 0;
		}
		else
		{
			SetActivity( ACT_MELEE_ATTACK2 );
			m_flMonsterSpeed = 18;
		}
	}

	void MonsterPain( CBaseEntity@ pAttacker, float flDamage )
	{
		if ( self.pev.pain_finished > g_Engine.time )
			return;

		m_iAIState = STATE_PAIN;
		SetActivity( ACT_BIG_FLINCH );

		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, Q1_KNIGHT_PAIN, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );
		self.pev.pain_finished = g_Engine.time + 1.0;
	}

	bool MonsterHasMissileAttack() { return false; }
	bool MonsterHasMeleeAttack() { return true; }
	bool MonsterHasPain() { return true; }

	void MonsterAttack()
	{
		if ( m_fAttackDone )
		{
			MonsterRun();
			m_fAttackDone = false;
		}

		if ( m_flMonsterSpeed != 0 )
		{
			// we in runattack!
			if ( m_fInAttack )
			{
				AI_Melee_Side();
			}
			else
			{
				AI_Charge_Side();
			}
		}
		else
		{
			AI_Charge( 5 );

			// standard attack
			if ( m_fInAttack )
				AI_Melee();
		}
	}

	void MonsterKilled( entvars_t@ pevAttacker, int iGib )
	{
		if ( ShouldGibMonster( iGib ) )
		{
			m_fHasRemove = true;
			g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "quake1/gib.wav", Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );
			g_EntityFuncs.SpawnRandomGibs( self.pev, 1, 1 );
			g_EntityFuncs.Remove( self );
			return;
		}

		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, Q1_KNIGHT_DEATH, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );
	}

	void HandleAnimEvent( MonsterEvent@ pEvent )
	{
		switch ( pEvent.event )
		{
			case KNIGHT_START_RUNATTACK:
				m_fInAttack = true;
				break;

			case KNIGHT_END_RUNATTACK:
				m_fInAttack = false;
				m_fAttackDone = true;
				break;

			case KNIGHT_IDLE_SOUND:
				if ( Math.RandomFloat( 0, 1 ) < 0.05 )
					g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, Q1_KNIGHT_IDLE, Math.RandomFloat( 0.95, 1.0 ), ATTN_IDLE, 0, 93 + Math.RandomLong( 0, 0xf ) );
				break;

			default:
				BaseClass.HandleAnimEvent( pEvent );
		}
	}
}

void q1_RegisterMonster_KNIGHT()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "monster_qknight", "monster_qknight" );
}
