const string Q1_HKNIGHT_MODEL = "models/quake1/m_hknight.mdl";

const string Q1_HKNIGHT_IDLE  = "quake1/monsters/hknight/idle.wav";
const string Q1_HKNIGHT_SIGHT = "quake1/monsters/hknight/sight.wav";
const string Q1_HKNIGHT_PAIN = "quake1/monsters/hknight/pain.wav";
const string Q1_HKNIGHT_DEATH = "quake1/monsters/hknight/death.wav";
const string Q1_HKNIGHT_SLASH = "quake1/monsters/hknight/slash.wav";
const string Q1_HKNIGHT_ATTACK = "quake1/monsters/hknight/attack.wav";

const array<string> Q1_HKNIGHT_MELEE = 
{
	"quake1/monsters/knight/sword1.wav",
	"quake1/monsters/knight/sword2.wav",
};

enum Q1_HKNIGHT_EVENTS
{
	HKNIGHT_IDLE_SOUND = 3,
	HKNIGHT_SHOT_SPIKES,
	HKNIGHT_MELEE_ATTACK
}

class monster_qhellknight : ScriptBaseMonsterEntity, CQuakeMonster
{
	void Spawn()
	{
		Precache();

		g_EntityFuncs.SetModel( self, Q1_HKNIGHT_MODEL );
		g_EntityFuncs.SetSize( self.pev, Vector( -16, -16, -24 ), Vector( 16, 16, 40 ) );

		self.pev.solid = SOLID_SLIDEBOX;
		self.pev.movetype = MOVETYPE_STEP;
		self.pev.health = 500;

		self.m_bloodColor = BLOOD_COLOR_RED;

		self.StartMonster();
		self.m_MonsterState = MONSTERSTATE_NONE;

		self.m_FormattedName = "Death Knight";

		self.pev.pain_finished = 0.0;

		m_iGibHealth = -40;

		WalkMonsterInit();
	}

	void Precache()
	{
		g_Game.PrecacheModel( Q1_HKNIGHT_MODEL );
		g_Game.PrecacheModel( "models/quake1/k_spike.mdl" );

		g_SoundSystem.PrecacheSound( Q1_HKNIGHT_IDLE );
		g_SoundSystem.PrecacheSound( Q1_HKNIGHT_SIGHT );
		g_SoundSystem.PrecacheSound( Q1_HKNIGHT_PAIN );
		g_SoundSystem.PrecacheSound( Q1_HKNIGHT_DEATH );
		g_SoundSystem.PrecacheSound( Q1_HKNIGHT_SLASH );
		g_SoundSystem.PrecacheSound( Q1_HKNIGHT_ATTACK );

		for ( uint i = 0; i < Q1_HKNIGHT_MELEE.length(); ++i )
			g_SoundSystem.PrecacheSound( Q1_HKNIGHT_MELEE[i] );
	}

	void MonsterIdle()
	{
		m_iAIState = STATE_IDLE;
		SetActivity( ACT_IDLE );
		m_flMonsterSpeed = 0;
	}

	void MonsterSight()
	{
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, Q1_HKNIGHT_SIGHT, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );
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

	void MonsterChargeAttack()
	{
		m_iAIState = STATE_ATTACK;
		SetActivity( ACT_SPECIAL_ATTACK1 );
	//	m_flMonsterSpeed = 0;
	}

	void CheckForCharge()
	{
		// check for mad charge
		if ( !m_fEnemyVisible )
			return;

		if ( g_Engine.time < m_flAttackFinished )
			return;

		if ( !self.m_hEnemy )
			return;

		CBaseEntity@ pEnemy = self.m_hEnemy;

		if ( abs( self.pev.origin.z - pEnemy.pev.origin.z ) > 20 )
			return;	// too much height change

		if ( ( self.pev.origin - pEnemy.pev.origin ).Length() < 80 )
			return;	// use regular attack

		// charge		
		AttackFinished( 2 );
		MonsterChargeAttack();
	}

	void CheckContinueCharge()
	{
		if ( g_Engine.time > m_flAttackFinished )
		{
			AttackFinished( 3 );
			MonsterRun();
			return;	// done charging
		}

		int i = Math.RandomLong( 0, 1 );
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, Q1_HKNIGHT_MELEE[i], Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );
	}

	void MonsterMissileAttack()
	{
		m_iAIState = STATE_ATTACK;
		SetActivity( ACT_RANGE_ATTACK1 );
		m_flMonsterSpeed = 0;
	}

	void MonsterMeleeAttack()
	{
		m_iAIState = STATE_ATTACK;
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, Q1_HKNIGHT_SLASH, 1.0, ATTN_NORM );
		SetActivity( ACT_MELEE_ATTACK1 );
		m_flMonsterSpeed = 0;
	}

	void ShootSpike( float flOffset )
	{
		if ( !self.m_hEnemy )
			return;

		CBaseEntity@ pEnemy = self.m_hEnemy;

		Vector ang = Math.VecToAngles( pEnemy.pev.origin - self.pev.origin );
		ang.y += flOffset * 6;
		
		Math.MakeVectors( ang );

		Vector org = self.pev.origin + self.pev.mins + self.pev.size * 0.5f + g_Engine.v_forward * 20;

		// set missile speed
		Vector vec = g_Engine.v_forward.Normalize();
		vec.z = -vec.z + Math.RandomFloat( -0.05f, 0.05f );

		g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, Q1_HKNIGHT_ATTACK, 1.0, ATTN_NORM );

		int iNailDamage = 12;
		if ( pEnemy.IsPlayer() )
		{
			if ( pEnemy.pev.armorvalue > 0 )
				iNailDamage *= 4;
			else
				iNailDamage *= 2;
		}

		CBaseEntity@ pNail = CreateKnightSpike( org, vec, self );
		if ( pNail !is null )
			pNail.pev.dmg = iNailDamage;
	}

	void MonsterPain( CBaseEntity@ pAttacker, float flDamage )
	{
		if ( self.pev.pain_finished > g_Engine.time )
			return;

		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, Q1_HKNIGHT_PAIN, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );

		if ( ( g_Engine.time - self.pev.pain_finished ) > 5 )
		{
			// allways go into pain frame if it has been a while
			m_iAIState = STATE_PAIN;
			SetActivity( ACT_BIG_FLINCH );
			self.pev.pain_finished = g_Engine.time + 1.0;
			return;
		}

		if ( Math.RandomFloat( 0.0f, 30.0f ) > flDamage )
			return; // didn't flinch

		m_iAIState = STATE_PAIN;
		SetActivity( ACT_BIG_FLINCH );
		self.pev.pain_finished = g_Engine.time + 1.0;
	}

	bool MonsterHasMissileAttack() { return true; }
	bool MonsterHasMeleeAttack() { return true; }
	bool MonsterHasPain() { return true; }

	void MonsterAttack()
	{
		if ( m_Activity == ACT_RANGE_ATTACK1 )
			AI_Face();

		if ( m_Activity == ACT_MELEE_ATTACK1 )
			AI_Charge( 5 );

		if ( m_Activity == ACT_SPECIAL_ATTACK1 )
			AI_Charge( 18 );

		if ( m_iAIState == STATE_ATTACK && self.m_fSequenceFinished )
			MonsterRun();
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

		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, Q1_HKNIGHT_DEATH, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );
	}

	void HandleAnimEvent( MonsterEvent@ pEvent )
	{
		switch ( pEvent.event )
		{
			case HKNIGHT_IDLE_SOUND:
				if ( m_Activity == ACT_RUN )
					CheckForCharge ();

				if ( Math.RandomFloat( 0, 1 ) < 0.1 )
					g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, Q1_HKNIGHT_IDLE, Math.RandomFloat( 0.95, 1.0 ), ATTN_IDLE, 0, 93 + Math.RandomLong( 0, 0xf ) );
				break;

			case HKNIGHT_SHOT_SPIKES:
				ShootSpike( atof( pEvent.options() ) );
				break;

			case HKNIGHT_MELEE_ATTACK:
				AI_Melee();
				break;

			default:
				BaseClass.HandleAnimEvent( pEvent );
		}
	}
}

CBaseEntity@ CreateKnightSpike( Vector vecOrigin, Vector vecDir, CBaseEntity@ pOwner )
{
	CBaseEntity@ pNail = g_EntityFuncs.Create( "projectile_qspike", vecOrigin, Math.VecToAngles( vecDir ), false, pOwner.edict() );

	if ( pNail is null )
		return null;

	g_EntityFuncs.SetModel( pNail, "models/quake1/k_spike.mdl" );
	g_EntityFuncs.SetSize( pNail.pev, Vector( -0.5, -0.5, -0.5 ), Vector( 0.5, 0.5, 0.5 ) );
	pNail.pev.velocity = vecDir * 300;
//	pNail.pev.effects |= EF_FULLBRIGHT;

	return pNail;
}

void q1_RegisterMonster_HELLKNIGHT()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "monster_qhellknight", "monster_qhellknight" );
}
