const string Q1_DOG_MODEL = "models/quake1/m_dog.mdl";

const string Q1_DOG_IDLE  = "quake1/monsters/dog/idle.wav";
const string Q1_DOG_SIGHT = "quake1/monsters/dog/sight.wav";
const string Q1_DOG_PAIN = "quake1/monsters/dog/pain.wav";
const string Q1_DOG_DEATH = "quake1/monsters/dog/death.wav";
//const string Q1_DOG_SHOOT = "quake1/monsters/dog/shoot.wav";
const string Q1_DOG_MELEE = "quake1/monsters/dog/melee.wav";

enum Q1_DOG_EVENTS
{
	DOG_IDLE_SOUND = 1,
	DOG_LEAP,
	DOG_ATTACK
}

class monster_qdog : ScriptBaseMonsterEntity, CQuakeMonster
{
	private bool m_fMidJump = false;

	void Spawn()
	{
		Precache();

		g_EntityFuncs.SetModel( self, Q1_DOG_MODEL );
		g_EntityFuncs.SetSize( self.pev, Vector( -32, -32, -24 ), Vector( 32, 32, 40 ) );
		self.m_bloodColor = BLOOD_COLOR_RED;

		self.pev.health = 75;
		self.pev.solid = SOLID_SLIDEBOX;
		self.pev.movetype = MOVETYPE_STEP;

		self.StartMonster();
		self.m_MonsterState = MONSTERSTATE_NONE;

		self.pev.pain_finished = 0.0;
		self.pev.yaw_speed = 20;

		m_iGibHealth = -35;

		self.m_FormattedName = "Rottweiler";

		WalkMonsterInit();
	}

	void Precache()
	{
		g_Game.PrecacheModel( Q1_DOG_MODEL );

		g_SoundSystem.PrecacheSound( Q1_DOG_IDLE );
		g_SoundSystem.PrecacheSound( Q1_DOG_SIGHT );
		g_SoundSystem.PrecacheSound( Q1_DOG_DEATH );
	//	g_SoundSystem.PrecacheSound( Q1_DOG_SHOOT );
		g_SoundSystem.PrecacheSound( Q1_DOG_MELEE );
		g_SoundSystem.PrecacheSound( Q1_DOG_PAIN );
	}

	void JumpTouch( CBaseEntity@ pOther )
	{
		m_fMidJump = false;

		if ( self.pev.health <= 0 )
			return;

		if ( pOther.pev.takedamage != 0 )
		{
			if ( self.pev.velocity.Length() > 300 )
			{
				float ldmg = 10 + Math.RandomFloat( 0.0, 10.0 );
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
				SetTouch( TouchFunction( MonsterTouch ) );
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
		CBaseEntity@ pEnemy = self.m_hEnemy;

		if ( pEnemy is null )
			return false;

		if ( self.pev.origin.z + self.pev.mins.z > pEnemy.pev.origin.z + pEnemy.pev.mins.z + 0.75f * pEnemy.pev.size.z )
			return false;

		if ( self.pev.origin.z + self.pev.maxs.z < pEnemy.pev.origin.z + pEnemy.pev.mins.z + 0.25f * pEnemy.pev.size.z )
			return false;

		Vector dist = pEnemy.pev.origin - self.pev.origin;
		dist.z = 0;

		float d = dist.Length();
		if ( d < 80 )
			return false;
		if ( d > 150 )
			return false;

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
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, Q1_DOG_SIGHT, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );
	}

	void MonsterWalk()
	{
		m_fMidJump = false;
		m_iAIState = STATE_WALK;
		SetActivity( ACT_WALK );
		m_flMonsterSpeed = 7;
		AI_Turn();
	}

	void MonsterRun()
	{
		m_fMidJump = false;
		AI_Face();
		m_iAIState = STATE_RUN;
		SetActivity( ACT_RUN );
		m_flMonsterSpeed = 32;
	}

	bool MonsterCheckAttack()
	{
		// if close enough for slashing, go for it
		if ( CheckMelee() )
		{
			m_iAttackState = ATTACK_MELEE;
			return true;
		}

		if ( CheckJump() )
		{
			m_iAttackState = ATTACK_MISSILE;
			return true;
		}

		AI_Face();

		return false;
	}

	void MonsterLeap()
	{
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, Q1_DOG_IDLE, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );

		AI_Face();

		m_fMidJump = true;
		SetTouch( TouchFunction( JumpTouch ) );
		g_EngineFuncs.MakeVectors( self.pev.angles );

		self.pev.origin.z += 1;
		self.pev.velocity = g_Engine.v_forward * 300 + Vector( 0, 0, 200 );
		self.pev.flags &= ~FL_ONGROUND;
	}

	void MonsterMelee()
	{
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, Q1_DOG_MELEE, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );

		if ( !self.m_hEnemy )
			return;

		CBaseEntity@ pEnemy = self.m_hEnemy;

		if ( pEnemy is null )
			return;

		AI_Charge( 10 );

		if ( !q1_CanDamage( pEnemy, self ) )
			return;

		Vector delta = pEnemy.pev.origin - self.pev.origin;

		if ( delta.Length() > 100 )
			return;

		float ldmg = ( Math.RandomFloat( 0, 1 ) + Math.RandomFloat( 0, 1 ) + Math.RandomFloat( 0, 1 ) ) * 8;
		if ( pEnemy.IsPlayer() )
		{
			if ( pEnemy.pev.armorvalue > 0 )
				ldmg *= 2.0;
		}
		
		pEnemy.TakeDamage( self.pev, self.pev, ldmg, DMG_GENERIC );
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

		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, Q1_DOG_PAIN, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );

		if ( self.pev.pain_finished > g_Engine.time )
			return;

		m_iAIState = STATE_PAIN;
		SetActivity( ACT_BIG_FLINCH );
		AI_Pain( 4 );
		
		self.pev.pain_finished = g_Engine.time + 0.6;
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
			AI_Charge( 10 );
		}

		if ( m_iAIState == STATE_ATTACK && self.m_fSequenceFinished )
		{
			m_iAttackState = ATTACK_NONE; // reset shadow of attack state
			MonsterRun();
		}
	}
/*
	void MonsterFire()
	{
		if ( m_fInAttack )
			return;

		AI_Face();

		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, Q1_DOG_SHOOT, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );

		// fire somewhat behind the player, so a dodging player is harder to hit
		CBaseEntity@ pEnemy = self.m_hEnemy;
		if ( pEnemy is null )
			return;

		Vector vecDir = ( ( pEnemy.pev.origin - pEnemy.pev.velocity * 0.2f ) - self.pev.origin ).Normalize();
		self.FireBullets( 4, self.pev.origin, vecDir, Vector( 0.1, 0.1, 0 ), 2048, BULLET_PLAYER_CUSTOMDAMAGE, 4, 5 );

		self.pev.effects |= EF_MUZZLEFLASH;
		m_fInAttack = true;
	}
*/
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

		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, Q1_DOG_DEATH, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );
	}

	void HandleAnimEvent( MonsterEvent@ pEvent )
	{
		switch ( pEvent.event )
		{
			case DOG_ATTACK:
				MonsterMelee();
				break;

			case DOG_LEAP:
				MonsterLeap();
				break;

			case DOG_IDLE_SOUND:
				if ( Math.RandomFloat( 0, 1 ) < 0.05 )
					g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, Q1_DOG_IDLE, Math.RandomFloat( 0.95, 1.0 ), ATTN_IDLE, 0, 93 + Math.RandomLong( 0, 0xf ) );
				break;

			default:
				BaseClass.HandleAnimEvent( pEvent );
		}
	}
}

void q1_RegisterMonster_DOG()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "monster_qdog", "monster_qdog" );
}
