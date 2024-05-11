const string Q1_FIEND_MODEL = "models/quake1/m_fiend.mdl";

const string Q1_FIEND_IDLE  = "quake1/monsters/fiend/idle.wav";
const string Q1_FIEND_SIGHT = "quake1/monsters/fiend/sight.wav";
const string Q1_FIEND_PAIN = "quake1/monsters/fiend/pain.wav";
const string Q1_FIEND_DEATH = "quake1/monsters/fiend/death.wav";
const string Q1_FIEND_SHOOT = "quake1/monsters/fiend/shoot.wav";
const string Q1_FIEND_MELEE = "quake1/monsters/fiend/melee.wav";
const string Q1_FIEND_LAND = "quake1/monsters/land.wav";

enum Q1_FIEND_EVENTS
{
	FIEND_IDLE_SOUND = 1,
	FIEND_LEAP,
	FIEND_ATTACK_RIGHT,
	FIEND_ATTACK_LEFT
}

class monster_qfiend : ScriptBaseMonsterEntity, CQuakeMonster
{
	private bool m_fMidJump = false;

	void Spawn()
	{
		Precache();

		g_EntityFuncs.SetModel( self, Q1_FIEND_MODEL );
		g_EntityFuncs.SetSize( self.pev, Vector( -32, -32, -24 ), Vector( 32, 32, 64 ) );
		self.m_bloodColor = BLOOD_COLOR_RED;

		self.pev.health = 500;
		self.pev.solid = SOLID_SLIDEBOX;
		self.pev.movetype = MOVETYPE_STEP;

		self.StartMonster();
		self.m_MonsterState = MONSTERSTATE_NONE;

		self.m_FormattedName = "Fiend";

		self.pev.pain_finished = 0.0;
		self.pev.yaw_speed = 20;

		m_iGibHealth = -80;

		WalkMonsterInit();
	}

	void Precache()
	{
		g_Game.PrecacheModel( Q1_FIEND_MODEL );

		g_SoundSystem.PrecacheSound( Q1_FIEND_IDLE );
		g_SoundSystem.PrecacheSound( Q1_FIEND_SIGHT );
		g_SoundSystem.PrecacheSound( Q1_FIEND_DEATH );
		g_SoundSystem.PrecacheSound( Q1_FIEND_SHOOT );
		g_SoundSystem.PrecacheSound( Q1_FIEND_MELEE );
		g_SoundSystem.PrecacheSound( Q1_FIEND_PAIN );
		g_SoundSystem.PrecacheSound( Q1_FIEND_LAND );
	}

	void JumpTouch( CBaseEntity@ pOther )
	{
		m_fMidJump = false;

		if ( self.pev.health <= 0 )
			return;

		if ( pOther.pev.takedamage != 0)
		{
			if ( self.pev.velocity.Length() > 400 )
			{
				float ldmg = 40 + Math.RandomFloat( 0.0, 10.0 );
				if ( pOther.IsPlayer() )
				{
					if ( pOther.pev.armorvalue > 0 )
						ldmg *= 2.0;
				}

				pOther.TakeDamage( self.pev, self.pev, ldmg, DMG_GENERIC );
			}
		}

		if ( g_EngineFuncs.EntIsOnFloor( self.edict() ) == 0 )
		{
			if ( self.pev.FlagBitSet( FL_ONGROUND ) )
			{
				// jump randomly to not get hung up
				self.pev.ideal_yaw += Math.RandomLong( -45, 45 );
				SetTouch( TouchFunction( MonsterTouch) );
				m_iAIState = STATE_ATTACK;
				SetActivity( ACT_LEAP );
			}

			return; // not on ground yet
		}

		SetTouch( TouchFunction( MonsterTouch ) );

		AI_Face();
		MonsterRun();
	}

	bool CheckMelee()
	{
		if ( m_iEnemyRange == RANGE_MELEE )
		{
			// FIXME: check canreach
			m_iAttackState = ATTACK_MELEE;
			return true;
		}
		return false;
	}

	bool CheckJump()
	{
		if ( !self.m_hEnemy )
			return false;

		CBaseEntity@ pEnemy = self.m_hEnemy;

		if ( self.pev.origin.z + self.pev.mins.z > pEnemy.pev.origin.z + pEnemy.pev.mins.z + 0.75f * pEnemy.pev.size.z )
			return false;

		if ( self.pev.origin.z + self.pev.maxs.z < pEnemy.pev.origin.z + pEnemy.pev.mins.z + 0.25f * pEnemy.pev.size.z )
			return false;

		Vector dist = pEnemy.pev.origin - self.pev.origin;
		dist.z = 0;

		float d = dist.Length();

		if ( d < 100 )
			return false;

		if ( d > 200 )
			return Math.RandomFloat( 0, 1 ) >= 0.9;

		return true;
	}

	void MonsterIdle()
	{
		m_iAIState = STATE_IDLE;
		SetActivity( ACT_IDLE );
		m_flMonsterSpeed = 0;
	}

	void MonsterSight()
	{
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, Q1_FIEND_SIGHT, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );
	}

	void MonsterWalk()
	{
		m_fMidJump = false;
		m_iAIState = STATE_WALK;
		SetActivity( ACT_WALK );
		m_flMonsterSpeed = 6;
		AI_Turn();
	}

	void MonsterRun()
	{
		m_fMidJump = false;
		AI_Face();
		m_iAIState = STATE_RUN;
		SetActivity( ACT_RUN );
		m_flMonsterSpeed = 20;
	}

	bool MonsterCheckAttack()
	{
		if ( m_iAIState == STATE_ATTACK || m_fMidJump )
			return false;

		// if close enough for slashing, go for it
		if ( CheckMelee() )
		{
			m_iAttackState = ATTACK_MELEE;
			return true;
		}

		if ( CheckJump() )
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, Q1_FIEND_SHOOT, 1.0, ATTN_NORM );
			m_iAttackState = ATTACK_MISSILE;
			return true;
		}

		AI_Face();

		return false;
	}

	void MonsterLeap()
	{
	//	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, Q1_FIEND_SHOOT, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );

		AI_Face();

		m_fMidJump = true;
		SetTouch( TouchFunction( JumpTouch ) );
		g_EngineFuncs.MakeVectors( self.pev.angles );

		TraceResult tr;
		Vector end = self.pev.origin + Vector( 0, 0, 18 );
		if ( !g_Utility.TraceMonsterHull( self.edict(), self.pev.origin, end, dont_ignore_monsters, self.edict(), tr ) )
			self.pev.origin.z += 18;

		self.pev.velocity = g_Engine.v_forward * 600 + Vector( 0, 0, 250 );
		self.pev.flags &= ~FL_ONGROUND;
	}

	void MonsterMelee( float side )
	{
		if ( !self.m_hEnemy )
			return;

		CBaseEntity@ pEnemy = self.m_hEnemy;

		AI_Face();
		WalkMove( self.pev.ideal_yaw, 12 );

		Vector delta = pEnemy.pev.origin - self.pev.origin;

		if ( delta.Length() > 100 )
			return;

	//	if ( pEnemy.pev.takedamage == 0 )
		if ( !q1_CanDamage( pEnemy, self ) )
			return;

		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, Q1_FIEND_MELEE, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );
		float ldmg = 10 + 5.0 * Math.RandomFloat( 0, 1 );
		if ( pEnemy.IsPlayer() )
		{
			if ( pEnemy.pev.armorvalue > 0 )
				ldmg *= 2.0;
		}

		pEnemy.TakeDamage( self.pev, self.pev, ldmg, DMG_GENERIC );

		g_EngineFuncs.MakeVectors( self.pev.angles );
		q1_SpawnMeatSpray( self.pev.origin + g_Engine.v_forward * 16, side * g_Engine.v_right );
	}

	void MonsterMissileAttack()
	{
		m_iAIState = STATE_ATTACK;
		SetActivity( ACT_LEAP );
	}

	void MonsterMeleeAttack()
	{
		m_iAIState = STATE_ATTACK;
		SetActivity( ACT_MELEE_ATTACK1 );
	}

	void MonsterPain( CBaseEntity@ pAttacker, float flDamage )
	{
		if ( m_fMidJump )
			return;

		if ( self.pev.pain_finished > g_Engine.time )
			return;

		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, Q1_FIEND_PAIN, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );
		self.pev.pain_finished = g_Engine.time + 1;

		if ( Math.RandomFloat( 0, 1 ) * 200.0 > flDamage )
			return;

		m_iAIState = STATE_PAIN;
		SetActivity( ACT_BIG_FLINCH );
	}

	bool MonsterHasMissileAttack() { return true; }
	bool MonsterHasMeleeAttack() { return true; }
	bool MonsterHasPain() { return true; }

	void MonsterAttack()
	{
		if ( m_iAttackState == ATTACK_MELEE )
		{
			if ( !m_fMidJump )
				AI_Face();

		}
		else if ( m_iAttackState == ATTACK_MISSILE )
		{
			AI_Charge( 18 );
		}

		if ( m_iAIState == STATE_ATTACK && self.m_fSequenceFinished )
		{
			m_iAttackState = ATTACK_NONE; // reset shadow of attack state
			MonsterRun();
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

		// regular death
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, Q1_FIEND_DEATH, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );
	}

	void HandleAnimEvent( MonsterEvent@ pEvent )
	{
		switch ( pEvent.event )
		{
			case FIEND_ATTACK_LEFT:
				MonsterMelee( -200.0 );
				break;

			case FIEND_ATTACK_RIGHT:
				MonsterMelee( 200.0 );
				break;

			case FIEND_LEAP:
				MonsterLeap();
				break;

			case FIEND_IDLE_SOUND:
				if ( Math.RandomFloat( 0, 1 ) < 0.05 )
					g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, Q1_FIEND_IDLE, Math.RandomFloat( 0.95, 1.0 ), ATTN_IDLE, 0, 93 + Math.RandomLong( 0, 0xf ) );
				break;

			default:
				BaseClass.HandleAnimEvent( pEvent );
		}
	}
}

void q1_RegisterMonster_FIEND()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "monster_qfiend", "monster_qfiend" );
}
