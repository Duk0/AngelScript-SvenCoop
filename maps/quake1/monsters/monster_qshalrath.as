const string Q1_SHALRATH_MODEL = "models/quake1/m_shalrath.mdl";

const string Q1_SHALRATH_IDLE  = "quake1/monsters/shalrath/idle.wav";
const string Q1_SHALRATH_SIGHT = "quake1/monsters/shalrath/sight.wav";
const string Q1_SHALRATH_PAIN = "quake1/monsters/shalrath/pain.wav";
const string Q1_SHALRATH_DEATH = "quake1/monsters/shalrath/death.wav";

const array<string> Q1_SHALRATH_ATTACK = 
{
	"quake1/monsters/shalrath/attack.wav",
	"quake1/monsters/shalrath/attack2.wav",
};

enum Q1_SHALRATH_EVENTS
{
	SHALRATH_IDLE_SOUND = 1,
	SHALRATH_ATTACK,
	SHALRATH_ATTACK_SOUND
}

class monster_qshalrath : ScriptBaseMonsterEntity, CQuakeMonster
{
	void Spawn()
	{
		Precache();

		g_EntityFuncs.SetModel( self, Q1_SHALRATH_MODEL );
		g_EntityFuncs.SetSize( self.pev, Vector( -32, -32, -24 ), Vector( 32, 32, 64 ) );

		self.pev.solid = SOLID_SLIDEBOX;
		self.pev.movetype = MOVETYPE_STEP;
		self.pev.health = 800;

		self.m_bloodColor = BLOOD_COLOR_RED;

		self.StartMonster();
		self.m_MonsterState = MONSTERSTATE_NONE;

		self.m_FormattedName = "Vore";

		self.pev.pain_finished = 0.0;
		self.pev.yaw_speed = 20;

		m_iGibHealth = -90;

		WalkMonsterInit();
	}

	void Precache()
	{
		g_Game.PrecacheModel( Q1_SHALRATH_MODEL );
		g_Game.PrecacheModel( "models/quake1/v_spike.mdl" );

		g_SoundSystem.PrecacheSound( Q1_SHALRATH_IDLE );
		g_SoundSystem.PrecacheSound( Q1_SHALRATH_SIGHT );
		g_SoundSystem.PrecacheSound( Q1_SHALRATH_DEATH );
		g_SoundSystem.PrecacheSound( Q1_SHALRATH_PAIN );

		for ( uint i = 0; i < Q1_SHALRATH_ATTACK.length(); ++i )
			g_SoundSystem.PrecacheSound( Q1_SHALRATH_ATTACK[i] );
	}

	void MonsterIdle()
	{
		m_iAIState = STATE_IDLE;
		SetActivity( ACT_IDLE );
		m_flMonsterSpeed = 0;
	}

	void MonsterSight()
	{
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, Q1_SHALRATH_SIGHT, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );
	}

	void MonsterWalk()
	{
		m_iAIState = STATE_WALK;
		SetActivity( ACT_WALK );
		m_flMonsterSpeed = 4;
		AI_Turn();
	}

	void MonsterRun()
	{
		AI_Face();
		m_iAIState = STATE_RUN;
		SetActivity( ACT_RUN );
		m_flMonsterSpeed = 4;
	}

	void MonsterMissileAttack()
	{
		// don't launch more than 5 missiles at one time
		if ( self.pev.impulse > 5 )
			return;

		m_iAIState = STATE_ATTACK;
		SetActivity( ACT_MELEE_ATTACK1 );
	}

	void MonsterPain( CBaseEntity@ pAttacker, float flDamage )
	{
		if ( self.pev.pain_finished > g_Engine.time )
			return;

		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, Q1_SHALRATH_PAIN, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );

		m_iAIState = STATE_PAIN;
		SetActivity( ACT_BIG_FLINCH );
		self.pev.pain_finished = g_Engine.time + 3;
	}

	bool MonsterHasMissileAttack() { return true; }
	bool MonsterHasMeleeAttack() { return false; }
	bool MonsterHasPain() { return true; }

	void MonsterAttack()
	{
		if ( m_iAIState == STATE_ATTACK && self.m_fSequenceFinished )
		{
			m_iAttackState = ATTACK_NONE;
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
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, Q1_SHALRATH_DEATH, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );
	}

	void CreateMissile()
	{
		if ( !self.m_hEnemy )
			return;
			
		CBaseEntity@ pEnemy = self.m_hEnemy;

		Vector vecDir = ( ( pEnemy.pev.origin + Vector( 0, 0, 10 ) ) - self.pev.origin ).Normalize();
		Vector vecSrc =  self.pev.origin + Vector( 0, 0, 10 );

		float flDist = ( pEnemy.pev.origin - self.pev.origin ).Length();

		float flytime = flDist * 0.002;
		if ( flytime < 0.1f ) flytime = 0.1f;

		self.pev.effects |= EF_MUZZLEFLASH;
		g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, Q1_SHALRATH_ATTACK[1], 1.0, ATTN_IDLE );

		CBaseEntity@ pMiss = ShalrathCreateMissile( vecSrc, vecDir * 400.0f, self );

		if ( pMiss !is null )
		{
			@pMiss.pev.enemy = pEnemy.edict();
			pMiss.pev.nextthink = g_Engine.time + flytime;
			self.pev.impulse++;
		}
	}

	void HandleAnimEvent( MonsterEvent@ pEvent )
	{
		switch ( pEvent.event )
		{
			case SHALRATH_IDLE_SOUND:
				if ( Math.RandomFloat( 0, 1 ) < 0.05 )
					g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, Q1_SHALRATH_IDLE, Math.RandomFloat( 0.95, 1.0 ), ATTN_IDLE, 0, 93 + Math.RandomLong( 0, 0xf ) );
				break;

			case SHALRATH_ATTACK:
				CreateMissile();
				break;

			case SHALRATH_ATTACK_SOUND:
				g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, Q1_SHALRATH_ATTACK[0], Math.RandomFloat( 0.95, 1.0 ), ATTN_IDLE, 0, 93 + Math.RandomLong( 0, 0xf ) );
				break;

			default:
				BaseClass.HandleAnimEvent( pEvent );
		}
	}
}

CBaseEntity@ ShalrathCreateMissile( Vector vecOrigin, Vector vecVelocity, CBaseEntity@ pOwner )
{
	CBaseEntity@ pMiss = g_EntityFuncs.Create( "projectile_qshalmissile", vecOrigin, g_vecZero, true, pOwner.edict() );

	if ( pMiss is null )
		return null;

	pMiss.pev.avelocity = Vector( 300, 300, 300 );
	pMiss.pev.velocity = vecVelocity;
//	pMiss.Spawn();
	g_EntityFuncs.DispatchSpawn( pMiss.edict() );

	// done
	return pMiss;
}

int g_sModelIndexWExplosion;

class CShalMissile : ScriptBaseEntity
{
	void Spawn()
	{
	//	Precache();

		// Setup
		self.pev.solid = SOLID_BBOX;
		self.pev.movetype = MOVETYPE_FLYMISSILE;

		g_EntityFuncs.SetModel( self, "models/quake1/v_spike.mdl" );
		g_EntityFuncs.SetSize( self.pev, Vector( -1, -1, -1 ), Vector( 1, 1, 1 ) );	// allow to explode with himself
		g_EntityFuncs.SetOrigin( self, self.pev.origin );

		SetTouch( TouchFunction( ShalTouch ) );
		SetThink( ThinkFunction( ShalHome ) );
	}
/*
	void Precache()
	{
		g_Game.PrecacheModel( "models/quake1/v_spike.mdl" );
	}
*/
	void ShalHome()
	{
		if ( self.pev.enemy is null || self.pev.enemy.vars.health <= 0.0f )
		{
			CBaseEntity@ pOwner = g_EntityFuncs.Instance( self.pev.owner );
			if ( pOwner !is null ) pOwner.pev.impulse--; // decrease missiles		
			g_EntityFuncs.Remove( self );
			return;
		}

		CBaseEntity@ pEnemy = g_EntityFuncs.Instance( self.pev.enemy );
		Vector vecTmp = pEnemy.pev.origin + Vector( 0, 0, 10 );
		Vector vecDir = ( vecTmp - self.pev.origin ).Normalize();
/*
		if ( g_iSkillLevel == SKILL_NIGHTMARE )
			self.pev.velocity = vecDir * 350.0f;
		else self.pev.velocity = vecDir * 250.0f;
*/	
		self.pev.velocity = vecDir * 300.0f;

		self.pev.nextthink = g_Engine.time + 0.2f;
	}

	void ShalTouch( CBaseEntity@ pOther )
	{
		if ( pOther.edict() is self.pev.owner )
			return; // don't explode on owner

		CBaseEntity@ pOwner = g_EntityFuncs.Instance( self.pev.owner );
		
		CBaseEntity@ pWorld = GetWorld();

		if ( pOwner is null ) @pOwner = pWorld; // shalrath is gibbed
		else pOwner.pev.impulse--; // decrease missiles

		if ( pOther.pev.ClassNameIs( "monster_qzombie" ) )
			pOther.TakeDamage( self.pev, self.pev, 110, DMG_GENERIC );
/*
		q1_RadiusDamage( self, pOwner, 40.0, 40.0 + 40.0, DMG_GENERIC, pWorld );

		NetworkMessage m( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, self.pev.origin );
			m.WriteByte( TE_EXPLOSION );
			m.WriteCoord( self.pev.origin.x );
			m.WriteCoord( self.pev.origin.y );
			m.WriteCoord( self.pev.origin.z );
			m.WriteShort( g_sModelIndexWExplosion );
			m.WriteByte( uint8( Math.RandomLong( 0, 29 ) + 30 ) ); // scale * 10
			m.WriteByte( 15 ); // framerate
			m.WriteByte( TE_EXPLFLAG_NONE );
		m.End();
*/
/*
		bool bDoDamage = true;

		if ( pOther.pev.ClassNameIs( "monster_qshalrath" ) )
			bDoDamage = false;
*/
		g_EntityFuncs.CreateExplosion( self.pev.origin, g_vecZero, pOwner.edict(), 40, true );

		self.pev.velocity = g_vecZero;
		SetThink( null );
		SetTouch( null );

		g_EntityFuncs.Remove( self );
	}
}

void q1_RegisterMonster_SHALRATH()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "monster_qshalrath", "monster_qshalrath" );
	g_CustomEntityFuncs.RegisterCustomEntity( "CShalMissile", "projectile_qshalmissile" );
	
	g_sModelIndexWExplosion = g_Game.PrecacheModel( "sprites/WXplo1.spr" );
}
