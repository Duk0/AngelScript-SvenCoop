const string Q1_BOSS_MODEL = "models/quake1/m_boss.mdl";

const string Q1_BOSS_RISE = "quake1/monsters/boss/rise.wav";
const string Q1_BOSS_SIGHT = "quake1/monsters/boss/sight.wav";
const string Q1_BOSS_PAIN = "quake1/monsters/boss/pain.wav";
const string Q1_BOSS_DEATH = "quake1/monsters/boss/death.wav";
const string Q1_BOSS_SHOOT = "quake1/monsters/boss/shoot.wav";

enum Q1_BOSS_EVENTS
{
	BOSS_OUT_SOUND = 1,
	BOSS_SIGHT_SOUND,
	BOSS_LAUNCH_LEFT_BALL,
	BOSS_LAUNCH_RIGHT_BALL,
	BOSS_DEATH_SOUND,
	BOSS_DEATH_SPLASH
}

class monster_qboss : ScriptBaseMonsterEntity, CQuakeMonster
{
	void Spawn()
	{
		Precache();

		SetUse( UseFunction( MonsterAwake ) );
		SetThink( ThinkFunction( MonsterThink ) );
		
		g_iTotalMonsters++;
	}

	void Precache()
	{
		g_Game.PrecacheModel( Q1_BOSS_MODEL );
		g_Game.PrecacheModel( "models/quake1/lavaball.mdl" );

		g_SoundSystem.PrecacheSound( Q1_BOSS_RISE );
		g_SoundSystem.PrecacheSound( Q1_BOSS_SIGHT );
		g_SoundSystem.PrecacheSound( Q1_BOSS_DEATH );
		g_SoundSystem.PrecacheSound( Q1_BOSS_SHOOT );
		g_SoundSystem.PrecacheSound( Q1_BOSS_PAIN );
	}

	bool MonsterHasMeleeAttack() { return true; }

	void MonsterAwake( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
	{
		g_EntityFuncs.SetModel( self, Q1_BOSS_MODEL );

		self.m_bloodColor = BLOOD_COLOR_RED;
		self.pev.health = 666;
		self.pev.yaw_speed = 20;
		self.pev.solid = SOLID_BBOX;
		self.pev.movetype = MOVETYPE_STEP;
		g_EntityFuncs.SetSize( self.pev, Vector( -128, -128, -24 ), Vector( 128, 128, 256 ) );

		SetUse( null );
		self.StartMonster();
		self.m_MonsterState = MONSTERSTATE_NONE;
		self.m_FormattedName = "Chthon";

		self.m_hEnemy = pActivator;
		m_iAIState = STATE_IDLE;
		SetActivity( ACT_USE );
		MonsterThink();

		q1_TE_LavaSplash( self.pev.origin );
		q1_TE_LavaSplash( self.pev.origin );
	}

	int TakeDamage( entvars_t@ pevInflictor, entvars_t@ pevAttacker, float flDamage, int bitsDamageType)
	{
		// ignore all damage except env_laser
		if ( bitsDamageType != DMG_ENERGYBEAM )
			return 0;

		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, Q1_BOSS_PAIN, 1.0, ATTN_NORM );

		self.pev.health -= 111;

		if ( self.pev.health > 0 )
		{
			SetActivity( ACT_SMALL_FLINCH );
			m_iAIState = STATE_WALK;
			m_iAttackState = ATTACK_NONE;
		}
		else
		{
			SetActivity( ACT_BIG_FLINCH );
			m_iAIState = STATE_WALK;
			m_iAttackState = ATTACK_NONE;
		
			CBaseEntity@ pEntity = null;
			CBasePlayer@ pPlayer;

			while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "player" ) ) !is null )
			{
				@pPlayer = cast<CBasePlayer@>( pEntity );
				if ( pPlayer is null || !pPlayer.IsConnected() )
					continue;

				pEntity.AddPoints( 666, false );
			}

			g_iKilledMonsters++;
		}

		return 1;
	}

	void AI_Idle()
	{
		if ( self.m_fSequenceFinished )
			AI_Run_Missile();
	}

	void AI_Face()
	{
		CBaseEntity@ pEnemy = self.m_hEnemy;

		if ( self.m_hEnemy && self.m_hEnemy.IsValid() && pEnemy.pev.health <= 0.0 || Math.RandomFloat( 0, 1 ) < 0.02 )
		{
			@pEnemy = g_EntityFuncs.FindEntityByClassname( pEnemy, "player" );
			if ( pEnemy is null )
				@pEnemy = g_EntityFuncs.FindEntityByClassname( pEnemy, "player" );
			if ( pEnemy !is null )
				self.m_hEnemy = pEnemy;
		}

		if ( self.m_hEnemy && self.m_hEnemy.IsValid() )
			self.pev.ideal_yaw = Math.VecToYaw( pEnemy.pev.origin - self.pev.origin );

		g_EngineFuncs.ChangeYaw( self.edict() );
	}

	void AI_Walk( float flDist )
	{
		if ( m_iAttackState == ATTACK_MISSILE )
		{
			AI_Run_Missile();
			return;
		}

		CBaseEntity@ pEnemy = self.m_hEnemy;

		if ( self.m_fSequenceFinished )
		{
			// just a switch between walk and attack
			if ( !self.m_hEnemy || !self.m_hEnemy.IsValid() || pEnemy.pev.health <= 0 )
			{
				m_iAttackState = ATTACK_NONE;
				m_iAIState = STATE_WALK;
				SetActivity( ACT_WALK ); // play walk animation
			}
			else if ( m_Activity == ACT_MELEE_ATTACK1 || m_Activity == ACT_SMALL_FLINCH )
			{
				m_iAIState = STATE_WALK;
				m_iAttackState = ATTACK_MISSILE;
			}
			else if ( m_Activity == ACT_BIG_FLINCH )
			{
				m_iAIState = STATE_WALK;
				m_iAttackState = ATTACK_NONE;
				SetActivity( ACT_DIEVIOLENT );
			}
			else if ( m_Activity == ACT_DIEVIOLENT )
			{
				m_iAIState = STATE_DEAD;
				if ( self.m_hEnemy && self.m_hEnemy.IsValid() )
					self.SUB_UseTargets( pEnemy, USE_TOGGLE, 0 );

				m_fHasRemove = true;
				g_EntityFuncs.Remove( self );
				return;
			}
			else
			{
				// this prevents Chthon from stalling after his target dies
				AI_Run_Missile();
			}
		}

		AI_Face();
	}

	void AI_Run_Missile()
	{
		m_iAIState = STATE_WALK;
		m_iAttackState = ATTACK_NONE; // wait for sequence end
		SetActivity( ACT_MELEE_ATTACK1 );
	}

	void LaunchMissile( Vector p, int iAttachment )
	{
		if ( !self.m_hEnemy || !self.m_hEnemy.IsValid() )
			return;

		CBaseEntity@ pEnemy = self.m_hEnemy;

		Vector vecAngles = Math.VecToAngles( pEnemy.pev.origin - self.pev.origin );
		g_EngineFuncs.MakeVectors( vecAngles );

		Vector vecSrc = self.pev.origin + p.x * g_Engine.v_forward + p.y * g_Engine.v_right + p.z * Vector( 0, 0, 1 );
		Vector vecEnd, vecDir;

		// lead the player
		float t = ( pEnemy.pev.origin - vecSrc ).Length() / 300.0;
		Vector vec = pEnemy.pev.velocity;
		vec.z = 0;
		vecEnd = pEnemy.pev.origin + t * vec;
		vecDir = ( vecEnd - vecSrc ).Normalize();

		g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, Q1_BOSS_SHOOT, 1.0, ATTN_NORM );
		CBaseEntity@ pGrenade = q1_ShootCustomProjectile( "projectile_qrocket", "models/quake1/lavaball.mdl",
															vecSrc, vecDir * 300, vecAngles, self );

		if ( pGrenade is null )
			return;

		pGrenade.pev.dmg = 150;
		pGrenade.pev.avelocity = Vector( 200, 100, 300 );
		g_EntityFuncs.SetModel( pGrenade, "models/quake1/lavaball.mdl" ); // TODO: remove the default SetModel on qrocket
	}

	void HandleAnimEvent( MonsterEvent@ pEvent )
	{
		switch ( pEvent.event )
		{
			case BOSS_OUT_SOUND:
				g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, Q1_BOSS_RISE, 1.0, ATTN_NORM );
				break;

			case BOSS_SIGHT_SOUND:
				g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, Q1_BOSS_SIGHT, 1.0, ATTN_NORM );
				break;

			case BOSS_LAUNCH_RIGHT_BALL:
				LaunchMissile( Vector( 100, -100, 200 ), 1 );
				break;

			case BOSS_LAUNCH_LEFT_BALL:
				LaunchMissile( Vector( 100, 100, 200 ), 2 );
				break;

			case BOSS_DEATH_SOUND:
				g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, Q1_BOSS_DEATH, 1.0, ATTN_NORM );
				break;

			case BOSS_DEATH_SPLASH:
				g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, Q1_BOSS_RISE, 1.0, ATTN_NORM );
				q1_TE_LavaSplash( self.pev.origin );
				q1_TE_LavaSplash( self.pev.origin );
				break;

			default:
				BaseClass.HandleAnimEvent( pEvent );
		}
	}
}

void q1_RegisterMonster_BOSS()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "monster_qboss", "monster_qboss" );
}
