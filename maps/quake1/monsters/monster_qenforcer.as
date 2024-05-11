const string Q1_ENFORCER_MODEL = "models/quake1/m_enforcer.mdl";

const string Q1_ENFORCER_IDLE = "quake1/monsters/enforcer/idle.wav";

const array<string> Q1_ENFORCER_SIGHT = 
{
	"quake1/monsters/enforcer/sight1.wav",
	"quake1/monsters/enforcer/sight2.wav",
	"quake1/monsters/enforcer/sight3.wav",
	"quake1/monsters/enforcer/sight4.wav",
};

const array<string> Q1_ENFORCER_PAIN = 
{
	"quake1/monsters/enforcer/pain1.wav",
	"quake1/monsters/enforcer/pain2.wav",
};

const string Q1_ENFORCER_DEATH = "quake1/monsters/enforcer/death.wav";
const string Q1_ENFORCER_SHOOT = "quake1/monsters/enforcer/enfire.wav";

const string Q1_ENFORCER_STOP = "quake1/monsters/enforcer/enfstop.wav";

enum Q1_ENFORCER_EVENTS
{
	ENF_END_ATTACK = 1,
	ENF_DROP_BACKPACK,
	ENF_SHOOT,
	ENF_IDLE_SOUND
}

class monster_qenforcer : ScriptBaseMonsterEntity, CQuakeMonster
{
	void Spawn()
	{
		Precache();

		g_EntityFuncs.SetModel( self, Q1_ENFORCER_MODEL );
		g_EntityFuncs.SetSize( self.pev, Vector( -16, -16, -24 ), Vector( 16, 16, 40 ) );

		self.pev.solid = SOLID_SLIDEBOX;
		self.pev.movetype = MOVETYPE_STEP;
		self.pev.health = 160;

		self.m_bloodColor = BLOOD_COLOR_RED;

		self.StartMonster();
		self.m_MonsterState = MONSTERSTATE_NONE;

		self.m_FormattedName = "Enforcer";

		self.pev.pain_finished = 0.0;
		m_iGibHealth = -40;

		WalkMonsterInit();
	}

	void Precache()
	{
		g_Game.PrecacheModel( Q1_ENFORCER_MODEL );
		g_Game.PrecacheModel( "models/quake1/laser.mdl" );

		g_SoundSystem.PrecacheSound( Q1_ENFORCER_IDLE );

		for ( uint i = 0; i < Q1_ENFORCER_SIGHT.length(); ++i )
			g_SoundSystem.PrecacheSound( Q1_ENFORCER_SIGHT[i] );

		g_SoundSystem.PrecacheSound( Q1_ENFORCER_DEATH );
		g_SoundSystem.PrecacheSound( Q1_ENFORCER_SHOOT );

		for ( uint i = 0; i < Q1_ENFORCER_PAIN.length(); ++i )
			g_SoundSystem.PrecacheSound( Q1_ENFORCER_PAIN[i] );

		g_SoundSystem.PrecacheSound( Q1_ENFORCER_STOP );
	}

	void MonsterIdle()
	{
		m_iAIState = STATE_IDLE;
		SetActivity( ACT_IDLE );
		m_flMonsterSpeed = 0;
	}

	void MonsterSight()
	{
		AI_Face();
		int i = Math.RandomLong( 0, 3 );
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, Q1_ENFORCER_SIGHT[i], Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );
	}

	void MonsterWalk()
	{
		m_iAIState = STATE_WALK;
		SetActivity( ACT_WALK );
		m_flMonsterSpeed = 3;
		AI_Turn();
	}

	void MonsterRun()
	{
		m_iAIState = STATE_RUN;
		SetActivity( ACT_RUN );
		m_flMonsterSpeed = 12;
	}

	void MonsterMissileAttack()
	{
		if ( Math.RandomFloat( 0, 1 ) < 0.3 )
			m_fLeftY = !m_fLeftY;

		m_iAIState = STATE_ATTACK;
		SetActivity( ACT_RANGE_ATTACK1 );
	}

	void MonsterPain( CBaseEntity@ pAttacker, float flDamage )
	{
		if ( self.pev.pain_finished > g_Engine.time )
			return;

		int i = Math.RandomLong( 0, 1 );
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, Q1_ENFORCER_PAIN[i], Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );

		m_iAIState = STATE_PAIN;
		SetActivity( ACT_BIG_FLINCH );
		m_flMonsterSpeed = 0;

		self.pev.pain_finished = g_Engine.time + 1.0 - 0.3; // TODO: replace the 1.0 with sequence duration
	}

	bool MonsterHasMissileAttack() { return true; }
	bool MonsterHasPain() { return true; }

	void MonsterAttack()
	{
		if ( m_fAttackDone )
		{
			m_fAttackDone = false;
			m_fInAttack = false;

			if ( CheckRefire() )
				MonsterMissileAttack();
			else
				MonsterRun();
		}

		AI_Face();
	}

	void MonsterFire()
	{
		if ( m_fInAttack )
			return;

		AI_Face();

		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, Q1_ENFORCER_SHOOT, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );

		// fire somewhat behind the player, so a dodging player is harder to hit
		CBaseEntity@ pEnemy = self.m_hEnemy;
		if ( pEnemy is null )
			return;

		int iBulletDamage = 9;
		if ( pEnemy.IsPlayer() )
		{
			if ( pEnemy.pev.armorvalue > 0 )
				iBulletDamage *= 4;
			else
				iBulletDamage *= 2;
		}

		Math.MakeVectors( self.pev.angles );

		Vector vecOrg = self.pev.origin + g_Engine.v_forward * 30.0f + g_Engine.v_right * 8.5 + Vector( 0, 0, 16 );
		Vector vecDir = ( pEnemy.pev.origin - self.pev.origin ).Normalize();

		CBaseEntity@ pLaser = LaunchLaser( vecOrg, vecDir, self );
		if ( pLaser !is null )
		{
			pLaser.pev.dmg = iBulletDamage;
			pLaser.pev.effects |= EF_BRIGHTLIGHT;
		}

		self.pev.effects |= EF_MUZZLEFLASH;
		m_fInAttack = true;
	}

	void MonsterKilled( entvars_t@ pevAttacker, int iGib )
	{
		CBackPack@ pPack = q1_SpawnBackpack( self );
		if ( pPack !is null )
			pPack.m_iAmmoCells = 5;

		if ( ShouldGibMonster( iGib ) )
		{
			m_fHasRemove = true;
			g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "quake1/gib.wav", Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );
			g_EntityFuncs.SpawnHeadGib( self.pev );
			g_EntityFuncs.SpawnRandomGibs( self.pev, 1, 1 );
			g_EntityFuncs.Remove( self );
			return;
		}

		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, Q1_ENFORCER_DEATH, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );
	}

	void HandleAnimEvent( MonsterEvent@ pEvent )
	{
		switch ( pEvent.event )
		{
			case ENF_END_ATTACK:
				m_fAttackDone = true;
				m_fInAttack = true;
				break;

			case ENF_DROP_BACKPACK:
				break;

			case ENF_SHOOT:
				MonsterFire();
				break;

			case ENF_IDLE_SOUND:
				if ( Math.RandomFloat( 0, 1 ) < 0.2 )
					g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, Q1_ENFORCER_IDLE, Math.RandomFloat( 0.95, 1.0 ), ATTN_IDLE, 0, 93 + Math.RandomLong( 0, 0xf ) );
				break;

			default:
				BaseClass.HandleAnimEvent( pEvent );
		}
	}
}

class projectile_qlaser : ScriptBaseEntity
{
	void Spawn()
	{
	//	Precache();

		// Setup
		self.pev.movetype = MOVETYPE_FLY;
		self.pev.solid = SOLID_BBOX;
		
		// Safety removal
		self.pev.nextthink = g_Engine.time + 5;
		SetThink( ThinkFunction( ThinkRemove ) );

	//	SetThink( null );
	//	self.pev.nextthink = g_Engine.time + 0.1;
		
		// Touch
		SetTouch( TouchFunction( LaserTouch ) );

		// Model
		g_EntityFuncs.SetModel( self, "models/quake1/laser.mdl" );
		g_EntityFuncs.SetSize( self.pev, g_vecZero, g_vecZero );
		g_EntityFuncs.SetOrigin( self, self.pev.origin );

		// Damage
		self.pev.dmg = 9;

		// Effects
	//	self.pev.effects |= EF_BRIGHTLIGHT;
	}
/*	
	void Precache()
	{
		g_Game.PrecacheModel( "models/quake1/laser.mdl" );
		g_SoundSystem.PrecacheSound( Q1_ENFORCER_STOP );
	}
*/
/*
	void Think()
	{
		self.pev.nextthink = g_Engine.time + 5;
		SetThink( ThinkFunction( ThinkRemove ) );

		self.pev.effects |= EF_BRIGHTLIGHT;
	}
*/
	void ThinkRemove()
	{
		self.SUB_Remove();
	}

	void LaserTouch( CBaseEntity@ pOther )
	{
		if ( pOther.pev.solid == SOLID_TRIGGER )
			return;

		TraceResult tr = g_Utility.GetGlobalTrace();

		// Remove if we've hit skybrush
		if ( IsSkySurface( pOther, tr.vecEndPos, self.pev.velocity.Normalize() ) )
		{
			g_EntityFuncs.Remove( self );
			return;
		}

		g_SoundSystem.EmitSound( pOther.edict(), CHAN_WEAPON, Q1_ENFORCER_STOP, 1.0, ATTN_NORM );

		// Hit something that bleeds
		if ( pOther.pev.takedamage != 0 )
		{
			CBaseEntity@ pOwner = g_EntityFuncs.Instance( self.pev.owner );
			if ( pOwner is null ) @pOwner = GetWorld();

			if ( pOther.IRelationship( pOwner ) != R_AL )
				g_WeaponFuncs.SpawnBlood( self.pev.origin, pOther.BloodColor(), self.pev.dmg );

			pOther.TakeDamage( self.pev, pOwner.pev, self.pev.dmg, DMG_GENERIC );
		}
		else
		{
			if ( pOther.pev.solid == SOLID_BSP || pOther.pev.movetype == MOVETYPE_PUSHSTEP )
			{
				Vector vecDir = self.pev.velocity.Normalize();
				Vector point = self.pev.origin - vecDir * 8;

				NetworkMessage m( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
					m.WriteByte( TE_GUNSHOT );
					m.WriteCoord( point.x );
					m.WriteCoord( point.y );
					m.WriteCoord( point.z );
				m.End();
			}
		}

		g_EntityFuncs.Remove( self );
	}
}

bool IsSkySurface( CBaseEntity@ pEnt, const Vector& in point, const Vector& in vecDir )
{
	Vector vecSrc = point + vecDir * -2.0f;
	Vector vecEnd = point + vecDir * 2.0f;

	const string szTex = g_Utility.TraceTexture( pEnt.edict(), vecSrc, vecEnd );

	if ( szTex.IsEmpty() )
		return false;

	if ( szTex.CompareN( "sky", 3 ) == 0 )
		return true;

	return false;
}

CBaseEntity@ LaunchLaser( Vector vecOrigin, Vector vecAngles, CBaseEntity@ pOwner )
{
	CBaseEntity@ pLaser = g_EntityFuncs.Create( "projectile_qlaser", vecOrigin, Math.VecToAngles( vecAngles ), true, pOwner.edict() );

	if ( pLaser is null )
		return null;

	pLaser.pev.velocity = vecAngles * 600;

	//pLaser.Spawn();
	g_EntityFuncs.DispatchSpawn( pLaser.edict() );

	return pLaser;
}

void q1_RegisterMonster_ENFORCER()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "monster_qenforcer", "monster_qenforcer" );
	g_CustomEntityFuncs.RegisterCustomEntity( "projectile_qlaser", "projectile_qlaser" );
}
