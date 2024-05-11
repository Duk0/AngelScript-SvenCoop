const string Q1_SHAMBLER_MODEL = "models/quake1/m_shambler.mdl";

const string Q1_SHAMBLER_IDLE   = "quake1/monsters/shambler/idle.wav";
const string Q1_SHAMBLER_SIGHT  = "quake1/monsters/shambler/sight.wav";
const string Q1_SHAMBLER_PAIN   = "quake1/monsters/shambler/pain.wav";
const string Q1_SHAMBLER_DEATH  = "quake1/monsters/shambler/death.wav";
const string Q1_SHAMBLER_CHARGE = "quake1/monsters/shambler/charge.wav";
const string Q1_SHAMBLER_SHOOT  = "quake1/monsters/shambler/shoot.wav";
const string Q1_SHAMBLER_MELEE1 = "quake1/monsters/shambler/melee1.wav";
const string Q1_SHAMBLER_MELEE2 = "quake1/monsters/shambler/melee2.wav";
const string Q1_SHAMBLER_STEP1  = "quake1/monsters/shambler/step1.wav";
const string Q1_SHAMBLER_STEP2  = "quake1/monsters/shambler/step2.wav";
const string Q1_SHAMBLER_HIT    = "quake1/monsters/shambler/hit.wav";

enum Q1_SHAMBLER_EVENTS
{
	SHAMBLER_IDLE_SOUND = 1,
	SHAMBLER_LEFT_STEP,
	SHAMBLER_RIGHT_STEP,
	SHAMBLER_CAST_LIGHTNING,
	SHAMBLER_BEGIN_CHARGING,
	SHAMBLER_END_CHARGING,
	SHAMBLER_SMASH,
	SHAMBLER_SWING_RIGHT,
	SHAMBLER_SWING_LEFT,
	SHAMBLER_SMASH_SOUND,
	SHAMBLER_SWING_SOUND
}

enum Q1_SHAMBLER_STATES
{
	SHAMBLER_STATE_START_CHARGING = 0,
	SHAMBLER_STATE_CHARGING = 2,
	SHAMBLER_STATE_END_CHARGING = 4
}

class monster_qshambler : ScriptBaseMonsterEntity, CQuakeMonster
{
	private bool m_fCharging = false;
	private int m_iChargeState = SHAMBLER_STATE_START_CHARGING;
	private int m_iAttackCount = 0;

	void Spawn()
	{
		Precache();

		g_EntityFuncs.SetModel( self, Q1_SHAMBLER_MODEL );
		self.m_bloodColor = BLOOD_COLOR_RED;

		self.pev.health = 600;
		self.pev.solid = SOLID_SLIDEBOX;
		self.pev.movetype = MOVETYPE_STEP;

		g_EntityFuncs.SetSize( self.pev, Vector( -32, -32, -24 ), Vector( 32, 32, 64 ) );

		self.StartMonster();
		self.m_MonsterState = MONSTERSTATE_NONE;

		self.m_FormattedName = "Shambler";

		self.pev.pain_finished = 0.0;
		m_iGibHealth = -60;

		WalkMonsterInit();
	}

	void Precache()
	{
		g_Game.PrecacheModel( Q1_SHAMBLER_MODEL );
		g_Game.PrecacheModel( "sprites/laserbeam.spr" );

		g_SoundSystem.PrecacheSound( Q1_SHAMBLER_IDLE );
		g_SoundSystem.PrecacheSound( Q1_SHAMBLER_SIGHT );
		g_SoundSystem.PrecacheSound( Q1_SHAMBLER_PAIN );
		g_SoundSystem.PrecacheSound( Q1_SHAMBLER_DEATH );
		g_SoundSystem.PrecacheSound( Q1_SHAMBLER_CHARGE );
		g_SoundSystem.PrecacheSound( Q1_SHAMBLER_SHOOT );
		g_SoundSystem.PrecacheSound( Q1_SHAMBLER_MELEE1 );
		g_SoundSystem.PrecacheSound( Q1_SHAMBLER_MELEE2 );
		g_SoundSystem.PrecacheSound( Q1_SHAMBLER_STEP1 );
		g_SoundSystem.PrecacheSound( Q1_SHAMBLER_STEP2 );
		g_SoundSystem.PrecacheSound( Q1_SHAMBLER_HIT );
	}

	void MonsterIdle()
	{
		m_iAIState = STATE_IDLE;
		SetActivity( ACT_IDLE );
		m_flMonsterSpeed = 0;
	}

	void MonsterSight()
	{
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, Q1_SHAMBLER_SIGHT, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );
	}

	void MonsterWalk()
	{
		m_iAIState = STATE_WALK;
		SetActivity( ACT_WALK );
		m_flMonsterSpeed = 8;
	}

	void MonsterRun()
	{
		m_iAIState = STATE_RUN;
		SetActivity( ACT_RUN );
		m_flMonsterSpeed = 20;
	}

	void MonsterMissileAttack()
	{
		m_iAIState = STATE_ATTACK;
		SetActivity( ACT_RANGE_ATTACK1 );
	}

	void MonsterMeleeAttack()
	{
		m_iAIState = STATE_ATTACK;
		SetActivity( ACT_MELEE_ATTACK1 );
	}

	bool MonsterCheckAttack()
	{
		if ( m_fCharging )
			return true;

		if ( !self.m_hEnemy )
			return false;

		CBaseEntity@ pEnemy = self.m_hEnemy;

		if ( m_iEnemyRange == RANGE_MELEE )
		{
		//	if ( pEnemy.pev.takedamage != 0 )
			if ( q1_CanDamage( pEnemy, self ) )
			{
				m_iAttackState = ATTACK_MELEE;
				return true;
			}
		}

		if ( g_Engine.time < m_flAttackFinished )
			return false;

		if ( !m_fEnemyVisible )
			return false;

		// see if any entities are in the way of the shot
		Vector spot1 = self.EyePosition();
		Vector spot2 = pEnemy.EyePosition();

		if ( ( spot1 - spot2 ).Length() > 600 )
			return false;

		TraceResult tr;
		g_Utility.TraceLine( spot1, spot2, dont_ignore_monsters, dont_ignore_glass, self.edict(), tr );

		if ( tr.fInOpen != 0 && tr.fInWater != 0 )
			return false; // sight line crossed contents

		if ( tr.pHit !is pEnemy.edict() )
			return false; // don't have a clear shot

		// missile attack
		if ( m_iEnemyRange == RANGE_FAR )
			return false;

		m_iAttackState = ATTACK_MISSILE;
		AttackFinished( 2 + Math.RandomFloat( 0.0f, 2.0f ) );

		return true;
	}

	void BeginCharging()
	{
		if ( m_fCharging )
			return;

		m_fCharging = true;
		self.StopAnimation();
		SetThink( ThinkFunction( Charge ) );
		self.pev.nextthink = g_Engine.time + 0.1;
		self.pev.effects |= EF_MUZZLEFLASH;

		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, Q1_SHAMBLER_CHARGE, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );

		m_iChargeState = SHAMBLER_STATE_START_CHARGING; // reset charge counter
		m_iAttackCount = 0;
	}

	void Charge()
	{
		if ( m_iChargeState == SHAMBLER_STATE_CHARGING || m_iChargeState >= SHAMBLER_STATE_END_CHARGING )
		{
			// continue animation
			self.ResetSequenceInfo();
			if ( m_iChargeState >= SHAMBLER_STATE_END_CHARGING )
			{
				m_fCharging = false;
				SetThink( ThinkFunction( MonsterThink ) );
				m_iChargeState = SHAMBLER_STATE_START_CHARGING;
				self.pev.nextthink = g_Engine.time + 0.1;
				return;
			}
		}

		float flInterval = self.StudioFrameAdvance( 0.099 ); // animate
		self.DispatchAnimEvents( flInterval );

		self.pev.nextthink = g_Engine.time + 0.1;
		self.pev.effects |= EF_MUZZLEFLASH;
		m_iChargeState++;
	}

	void EndCharging()
	{
		if ( !m_fCharging )
			return;
		self.StopAnimation();
	}

	void CastLightning()
	{
		if ( !self.m_hEnemy )
			return;

		CBaseEntity@ pEnemy = self.m_hEnemy;
		if ( pEnemy is null )
			return;

		AI_Face();

		if ( m_iAttackCount == 0 )
			g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, Q1_SHAMBLER_SHOOT, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );

		self.pev.effects |= EF_MUZZLEFLASH;
		++m_iAttackCount;
		AI_Face();

		Vector vecOrg = self.pev.origin + Vector( 0, 0, 40 );
		Vector vecDir = ( pEnemy.pev.origin + Vector( 0, 0, 16 ) - vecOrg ).Normalize();
		Vector vecEnd = vecOrg + vecDir * 600;

		TraceResult tr;
		g_Utility.TraceLine( vecOrg, vecEnd, dont_ignore_monsters, self.edict(), tr );
		q1_TE_BeamPoints( vecOrg, tr.vecEndPos );

		if ( tr.pHit !is null )
		{
			CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
		//	if ( pHit !is null && !pHit.IsBSPModel() && q1_CanDamage( pHit, self ) )
			if ( pHit !is null && !pHit.IsBSPModel() && pHit.pev.takedamage != 0 )
			{
				g_WeaponFuncs.ClearMultiDamage();
				pHit.TraceAttack( self.pev, 10, vecDir, tr, DMG_SHOCK );
				g_WeaponFuncs.ApplyMultiDamage( self.pev, self.pev );
			}
		}
	}

	void MonsterClaw( float side )
	{
		if ( !self.m_hEnemy )
			return;

		CBaseEntity@ pEnemy = self.m_hEnemy;

		AI_Charge( 10 );

		Vector delta = pEnemy.pev.origin - self.pev.origin;

		if ( delta.Length() > 100 )
			return;

		float ldmg = ( Math.RandomFloat( 0, 1 ) + Math.RandomFloat( 0, 1 ) + Math.RandomFloat( 0, 1 ) ) * 20;
		pEnemy.TakeDamage( self.pev, self.pev, ldmg, DMG_SLASH );
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, Q1_SHAMBLER_HIT, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );

		if ( side != 0.0 )
		{
			g_EngineFuncs.MakeVectors( self.pev.angles );
			q1_SpawnMeatSpray( self.pev.origin + g_Engine.v_forward * 16, side * g_Engine.v_right );
		}
	}

	void MonsterSmash()
	{
		if ( !self.m_hEnemy )
			return;

		CBaseEntity@ pEnemy = self.m_hEnemy;

		AI_Charge( 0 );

		Vector delta = pEnemy.pev.origin - self.pev.origin;

		if ( delta.Length() > 100 )
			return;

		if ( !q1_CanDamage( pEnemy, self ) )
			return;

		float ldmg = ( Math.RandomFloat( 0, 1 ) + Math.RandomFloat( 0, 1 ) + Math.RandomFloat( 0, 1 ) ) * 40;
		pEnemy.TakeDamage( self.pev, self.pev, ldmg, DMG_SLASH );
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, Q1_SHAMBLER_HIT, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );

		g_EngineFuncs.MakeVectors( self.pev.angles );
		q1_SpawnMeatSpray( self.pev.origin + g_Engine.v_forward * 16, Math.RandomFloat( -100, 100 ) * g_Engine.v_right );
		q1_SpawnMeatSpray( self.pev.origin + g_Engine.v_forward * 16, Math.RandomFloat( -100, 100 ) * g_Engine.v_right );
	}

	void MonsterPain( CBaseEntity@ pAttacker, float flDamage )
	{
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, Q1_SHAMBLER_PAIN, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );

		if ( self.pev.health <= 0 )
			return; // allready dying, don't go into pain frame

		if ( Math.RandomFloat( 0.0, 1.0 ) * 400 > flDamage )
			return; // didn't flinch

		if ( self.pev.pain_finished > g_Engine.time )
			return;

		self.pev.pain_finished = g_Engine.time + 2;

		m_iAIState = STATE_PAIN;
		SetActivity( ACT_BIG_FLINCH );
	}

	bool MonsterHasMissileAttack() { return true; }
	bool MonsterHasMeleeAttack() { return true; }
	bool MonsterHasPain() { return true; }

	void MonsterAttack()
	{
		AI_Charge( 5 );

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

		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, Q1_SHAMBLER_DEATH, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );
	}

	void HandleAnimEvent(MonsterEvent@ pEvent)
	{
		CBaseEntity@ pEnemy = self.m_hEnemy;
		switch ( pEvent.event )
		{
			case SHAMBLER_IDLE_SOUND:
				if ( Math.RandomFloat( 0, 1 ) < 0.1 )
					g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, Q1_SHAMBLER_IDLE, Math.RandomFloat( 0.95, 1.0 ), ATTN_IDLE, 0, 93 + Math.RandomLong( 0, 0xf ) );
				break;

			case SHAMBLER_LEFT_STEP:
				// dont make sound steps while shambler do melee attack
				if ( !self.m_hEnemy || ( pEnemy.pev.origin - self.pev.origin ).Length() > 100 )
				{
					g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, Q1_SHAMBLER_STEP1, Math.RandomFloat( 0.95, 1.0 ), ATTN_IDLE, 0, 93 + Math.RandomLong( 0, 0xf ) );
					g_PlayerFuncs.ScreenShake( self.pev.origin + Vector( 0, 0, -24 ), 2.0f, 2.0f, 0.5f, 250.0f );
				}
				break;

			case SHAMBLER_RIGHT_STEP:
				if ( !self.m_hEnemy || ( pEnemy.pev.origin - self.pev.origin ).Length() > 100 )
				{
					g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, Q1_SHAMBLER_STEP2, Math.RandomFloat( 0.95, 1.0 ), ATTN_IDLE, 0, 93 + Math.RandomLong( 0, 0xf ) );
					g_PlayerFuncs.ScreenShake( self.pev.origin + Vector( 0, 0, -24 ), 2.0f, 2.0f, 0.5f, 250.0f );
				}
				break;

			case SHAMBLER_CAST_LIGHTNING:
				CastLightning();
				break;

			case SHAMBLER_BEGIN_CHARGING:
				BeginCharging();
				break;

			case SHAMBLER_END_CHARGING:
				EndCharging();
				break;

			case SHAMBLER_SMASH:
				MonsterSmash();
				break;

			case SHAMBLER_SMASH_SOUND:
				g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, Q1_SHAMBLER_MELEE1, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );
				break;

			case SHAMBLER_SWING_SOUND:
				g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, Q1_SHAMBLER_MELEE2, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );
				break;

			case SHAMBLER_SWING_LEFT:
				MonsterClaw( 250 );
				break;

			case SHAMBLER_SWING_RIGHT:
				MonsterClaw( -250 );
				break;

			default:
				BaseClass.HandleAnimEvent( pEvent );
		}
	}
}

void q1_RegisterMonster_SHAMBLER()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "monster_qshambler", "monster_qshambler" );
}
