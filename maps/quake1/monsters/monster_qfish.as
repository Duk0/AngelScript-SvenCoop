const string Q1_FISH_MODEL = "models/quake1/m_fish.mdl";

const string Q1_FISH_IDLE  = "quake1/monsters/fish/idle.wav";
const string Q1_FISH_DEATH = "quake1/monsters/fish/death.wav";
const string Q1_FISH_BITE = "quake1/monsters/fish/bite.wav";

enum Q1_FISH_EVENTS
{
	FISH_IDLE_SOUND = 1,
	FISH_MELEE_ATTACK
}

class monster_qfish : ScriptBaseMonsterEntity, CQuakeMonster
{
	void Spawn()
	{
		Precache();

		g_EntityFuncs.SetModel( self, Q1_FISH_MODEL );
		g_EntityFuncs.SetSize( self.pev, Vector( -16, -16, -24 ), Vector( 16, 16, 24 ) );

		self.pev.solid = SOLID_SLIDEBOX;
		self.pev.movetype = MOVETYPE_STEP;
		self.pev.health = 50;

		self.m_bloodColor = BLOOD_COLOR_RED;

		self.StartMonster();
		self.m_MonsterState = MONSTERSTATE_NONE;

		self.m_FormattedName = "Rotfish";

		self.pev.pain_finished = 0.0;
		
	//	m_iGibHealth = -20; // -20 (in SoA only; cannot be gibbed in vanilla Quake) 

		SwimMonsterInit();
	}

	void Precache()
	{
		g_Game.PrecacheModel( Q1_FISH_MODEL );

		g_SoundSystem.PrecacheSound( Q1_FISH_IDLE );
		g_SoundSystem.PrecacheSound( Q1_FISH_DEATH );
		g_SoundSystem.PrecacheSound( Q1_FISH_BITE );
	}

	void MonsterIdle()
	{
		m_iAIState = STATE_IDLE;
		SetActivity( ACT_SWIM );
		m_flMonsterSpeed = 0;
	}

	void MonsterWalk()
	{
		m_iAIState = STATE_WALK;
		SetActivity( ACT_SWIM );
		m_flMonsterSpeed = 8;
		AI_Turn();
	}

	void MonsterRun()
	{
		m_iAIState = STATE_RUN;
		SetActivity( ACT_SWIM );
		m_flMonsterSpeed = 12;
	}

	void MonsterMeleeAttack()
	{
		m_iAIState = STATE_ATTACK;
		SetActivity( ACT_MELEE_ATTACK1 );
	}

	void MonsterPain( CBaseEntity@ pAttacker, float flDamage )
	{
		if ( self.pev.pain_finished > g_Engine.time )
			return;

		m_iAIState = STATE_PAIN;
		SetActivity( ACT_BIG_FLINCH );
		
		AI_Pain( 6 );

		self.pev.pain_finished = g_Engine.time + 1.0;
	}

	bool MonsterHasMissileAttack() { return false; }
	bool MonsterHasMeleeAttack() { return true; }
	bool MonsterHasPain() { return true; }

	void MonsterAttack()
	{
		AI_Charge( 10 );
	
		if ( m_iAIState == STATE_ATTACK && self.m_fSequenceFinished )
			MonsterRun();
	}

	void FishMelee()
	{
		if ( !self.m_hEnemy )
			return; // removed before stroke

		CBaseEntity@ pEnemy = self.m_hEnemy;
			
		Vector delta = pEnemy.pev.origin - self.pev.origin;

		if ( delta.Length() > 60 )
			return;

		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, Q1_FISH_BITE, 1.0, ATTN_NORM );	
		float ldmg = ( Math.RandomFloat( 0.0f, 1.0f ) + Math.RandomFloat( 0.0f, 1.0f ) ) * 3;
		if ( pEnemy.IsPlayer() )
		{
			if ( pEnemy.pev.armorvalue > 0 )
				ldmg *= 4.0;
			else
				ldmg *= 2.0;
		}

		pEnemy.TakeDamage( self.pev, self.pev, ldmg, DMG_GENERIC );	
	}

	void MonsterKilled( entvars_t@ pevAttacker, int iGib )
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, Q1_FISH_BITE, 1.0, ATTN_NORM );	
	
		self.pev.flags &= ~(FL_SWIM);
		self.pev.gravity = 0.08f; // underwater gravity

		// a bit of a hack. If a corpses' bbox is positioned such that being left solid so that
		// it can be attacked will block the player on a slope or stairs, the corpse is made nonsolid. 
		g_EntityFuncs.SetSize( self.pev, Vector ( -16, -16, -24 ), Vector ( 16, 16, 16 ) );
	}

	void HandleAnimEvent( MonsterEvent@ pEvent )
	{
		switch ( pEvent.event )
		{
			case FISH_MELEE_ATTACK:
				FishMelee();
				break;

			case FISH_IDLE_SOUND:
				if ( Math.RandomFloat( 0, 1 ) < 0.05 )
					g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, Q1_FISH_IDLE, Math.RandomFloat( 0.95, 1.0 ), ATTN_IDLE, 0, 93 + Math.RandomLong( 0, 0xf ) );
				break;

			default:
				BaseClass.HandleAnimEvent( pEvent );
		}
	}
}

void q1_RegisterMonster_FISH()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "monster_qfish", "monster_qfish" );
}
