// wizard

const string Q1_SCRAG_MODEL = "models/quake1/m_scrag.mdl";

const array<string> Q1_SCRAG_IDLE = {
	"quake1/monsters/scrag/idle.wav",
	"quake1/monsters/scrag/idle2.wav"
};

const string Q1_SCRAG_SIGHT = "quake1/monsters/scrag/sight.wav";
const string Q1_SCRAG_PAIN = "quake1/monsters/scrag/pain.wav";
const string Q1_SCRAG_DEATH = "quake1/monsters/scrag/death.wav";
const string Q1_SCRAG_SHOOT = "quake1/monsters/scrag/shoot.wav";
const string Q1_SCRAG_HIT = "quake1/monsters/scrag/hit.wav";

enum Q1_SCRAG_EVENTS
{
	SCRAG_START_ATTACK = 1,
	SCRAG_END_ATTACK,
	SCRAG_IDLE_SOUND
}

class monster_qscrag : ScriptBaseMonsterEntity, CQuakeMonster
{
	void Spawn()
	{
		Precache();

		g_EntityFuncs.SetModel( self, Q1_SCRAG_MODEL );
		g_EntityFuncs.SetSize( self.pev, Vector( -16, -16, -24 ), Vector( 16, 16, 40 ) );

		self.pev.solid = SOLID_SLIDEBOX;
		self.pev.movetype = MOVETYPE_FLY;
	//	self.pev.movetype = MOVETYPE_STEP;
		self.pev.flags |= FL_FLY;
		self.pev.health = 160;

		self.m_bloodColor = BLOOD_COLOR_RED;

		self.StartMonster();
		self.m_MonsterState = MONSTERSTATE_NONE;

		self.m_FormattedName = "Scrag";

		self.pev.pain_finished = 0.0;

		m_iGibHealth = -40;

		FlyMonsterInit();
	}

	void Precache()
	{
		g_Game.PrecacheModel( Q1_SCRAG_MODEL );
		g_Game.PrecacheModel( "models/quake1/spike.mdl" );

		for ( uint i = 0; i < Q1_SCRAG_IDLE.length(); ++i )
			g_SoundSystem.PrecacheSound( Q1_SCRAG_IDLE[i] );

		g_SoundSystem.PrecacheSound( Q1_SCRAG_SIGHT );
		g_SoundSystem.PrecacheSound( Q1_SCRAG_DEATH );
		g_SoundSystem.PrecacheSound( Q1_SCRAG_SHOOT );
		g_SoundSystem.PrecacheSound( Q1_SCRAG_PAIN );
		g_SoundSystem.PrecacheSound( Q1_SCRAG_HIT );
	}

	void MonsterIdle()
	{
		m_iAttackState = ATTACK_NONE;
		m_iAIState = STATE_IDLE;
		SetActivity( ACT_IDLE );
		m_flMonsterSpeed = 0;
	}

	void MonsterSight()
	{
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, Q1_SCRAG_SIGHT, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );
	}

	void MonsterWalk()
	{
		m_iAttackState = ATTACK_NONE;
		m_iAIState = STATE_WALK;
		SetActivity( ACT_WALK );
		m_flMonsterSpeed = 8;
	}

	void MonsterSide()
	{
		m_iAIState = STATE_RUN;
		SetActivity( ACT_RUN );
		m_flMonsterSpeed = 8;
	}

	void MonsterRun()
	{
		m_iAIState = STATE_RUN;
		SetActivity( ACT_RUN );
		m_flMonsterSpeed = 16;
	}

	bool MonsterCheckAttack()
	{
		if ( g_Engine.time < m_flAttackFinished )
			return false;

		if ( !m_fEnemyVisible )
			return false;

		if ( m_iEnemyRange == RANGE_FAR )
		{
			if ( m_iAttackState != ATTACK_STRAIGHT )
			{
				m_iAttackState = ATTACK_STRAIGHT;
				MonsterRun();
			}
			return false;
		}

		CBaseEntity@ pTarg = self.m_hEnemy;

		if ( pTarg is null )
			return false;

		// see if any entities are in the way of the shot
		Vector spot1 = self.EyePosition();
		Vector spot2 = pTarg.EyePosition();

		TraceResult tr;
		g_Utility.TraceLine( spot1, spot2, dont_ignore_monsters, dont_ignore_glass, self.edict(), tr );

		if ( tr.pHit !is pTarg.edict() )
		{
			// don't have a clear shot, so move to a side
			if ( m_iAttackState != ATTACK_STRAIGHT )
			{
				m_iAttackState = ATTACK_STRAIGHT;
				MonsterRun();
			}
			return false;
		}

		float chance = 0.0;
		if ( m_iEnemyRange == RANGE_MELEE )
			chance = 0.9;
		else if ( m_iEnemyRange == RANGE_NEAR )
			chance = 0.6;
		else if ( m_iEnemyRange == RANGE_MID )
			chance = 0.2;
		else
			chance = 0.0;

		if ( Math.RandomFloat( 0, 1 ) < chance )
		{
			m_iAttackState = ATTACK_MISSILE;
			return true;
		}

		if ( m_iEnemyRange == RANGE_MID )
		{
			if ( m_iAttackState != ATTACK_STRAIGHT )
			{
				m_iAttackState = ATTACK_STRAIGHT;
				MonsterRun();
			}
		}
		else
		{
			if ( m_iAttackState != ATTACK_SLIDING )
			{
				m_iAttackState = ATTACK_SLIDING;
				MonsterSide();
			}
		}

		return false;
	}

	void MonsterMissileAttack()
	{
		m_iAIState = STATE_ATTACK;
		SetActivity( ACT_MELEE_ATTACK1 );
	}

	void MonsterAttackFinished()
	{
		AttackFinished( 2 );

		if ( m_iEnemyRange >= RANGE_MID || !m_fEnemyVisible )
		{
			m_iAttackState = ATTACK_STRAIGHT;
			MonsterRun();
		}
		else
		{
			m_iAttackState = ATTACK_SLIDING;
			MonsterSide();
		}
	}

	void MonsterPain( CBaseEntity@ pAttacker, float flDamage )
	{
		if ( Math.RandomLong( 0, 5 ) < 2 )
			g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, Q1_SCRAG_PAIN, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong(0, 0xf ) );

		if ( Math.RandomLong( 0, 70 ) > flDamage )
			return;

		if ( self.pev.pain_finished > g_Engine.time )
			return;

		m_iAIState = STATE_PAIN;
		SetActivity( ACT_BIG_FLINCH );
		
		self.pev.pain_finished = g_Engine.time + 1.0;
	}

	void MonsterTimedIdleSound()
	{
		if ( self.pev.radsuit_finished < g_Engine.time )
		{
			int i = Math.RandomLong( 0, 1 );
			g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, Q1_SCRAG_IDLE[i], Math.RandomFloat( 0.95, 1.0 ), ATTN_IDLE, 0, 93 + Math.RandomLong( 0, 0xf ) );

			self.pev.radsuit_finished = g_Engine.time + Math.RandomFloat( 2, 8 );
		}
	}

	void MonsterFastFire()
	{
		if ( !self.m_hEnemy )
			return;

		CBaseEntity@ pEnemy = self.m_hEnemy;

		g_EngineFuncs.MakeVectors( self.pev.angles );

		Vector vecSrc, vecOffset;

		vecSrc = self.pev.origin + Vector( 0, 0, 30 ) + g_Engine.v_forward * 14 + g_Engine.v_right * 14;
		vecOffset = -8 * g_Engine.v_right;
		q1_ScragDelaySpike( self, pEnemy, vecSrc, vecOffset, 0.8 );

		vecSrc = self.pev.origin + Vector( 0, 0, 30 ) + g_Engine.v_forward * 14 + g_Engine.v_right * -14;
		vecOffset = 8 * g_Engine.v_right;
		q1_ScragDelaySpike( self, pEnemy, vecSrc, vecOffset, 0.3 );
	}

	bool MonsterHasMissileAttack() { return true; }
	bool MonsterHasMeleeAttack() { return false; }
	bool MonsterHasPain() { return true; }

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

		self.pev.velocity.x = Math.RandomFloat( -200, 200 );
		self.pev.velocity.y = Math.RandomFloat( -200, 200 );
		self.pev.velocity.z = Math.RandomFloat( 100, 200 );
		self.pev.movetype = MOVETYPE_TOSS;
	//	self.pev.movetype = MOVETYPE_STEP;
		self.pev.flags &= ~( FL_ONGROUND|FL_FLY );
		
		m_fHitsound = true;

		// a bit of a hack. If a corpses' bbox is positioned such that being left solid so that
		// it can be attacked will block the player on a slope or stairs, the corpse is made nonsolid.
		g_EntityFuncs.SetSize( self.pev, Vector( -16, -16, -16 ), Vector( 16, 16, 16 ) );

		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, Q1_SCRAG_DEATH, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );
	}

	void HandleAnimEvent( MonsterEvent@ pEvent )
	{
		switch ( pEvent.event )
		{
			case SCRAG_START_ATTACK:
				MonsterFastFire();
				break;

			case SCRAG_END_ATTACK:
				MonsterAttackFinished();
				break;

			case SCRAG_IDLE_SOUND:
				MonsterTimedIdleSound();
				break;

			default:
				BaseClass.HandleAnimEvent( pEvent );
		}
	}
}

void q1_RegisterMonster_SCRAG()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "monster_qscrag", "monster_qscrag" );
}
