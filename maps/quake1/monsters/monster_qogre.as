const string Q1_OGRE_MODEL = "models/quake1/m_ogre.mdl";

const array<string> Q1_OGRE_IDLE = {
	"quake1/monsters/ogre/idle1.wav",
	"quake1/monsters/ogre/idle2.wav"
};

const string Q1_OGRE_SIGHT = "quake1/monsters/ogre/sight.wav";
const string Q1_OGRE_PAIN  = "quake1/monsters/ogre/pain.wav";
const string Q1_OGRE_DEATH = "quake1/monsters/ogre/death.wav";
const string Q1_OGRE_SHOOT = "quake1/weapons/grenade.wav";
const string Q1_OGRE_MELEE = "quake1/monsters/ogre/melee.wav";
const string Q1_OGRE_DRAG  = "quake1/monsters/ogre/drag.wav";

enum Q1_OGRE_EVENTS
{
	OGRE_DROP_BACKPACK = 1,
	OGRE_IDLE_SOUND,
	OGRE_IDLE_SOUND2,
	OGRE_DRAG_SOUND,
	OGRE_SHOOT_GRENADE,
	OGRE_CHAINSAW,
	OGRE_CHAINSAW_SOUND
}

class monster_qogre : ScriptBaseMonsterEntity, CQuakeMonster
{
	void Spawn()
	{
		Precache();

		g_EntityFuncs.SetModel( self, Q1_OGRE_MODEL );
		// FIXME: ogre with large hull failed to following by path_corner on e1m2 :-(
	//	g_EntityFuncs.SetSize( self.pev, Vector( -20, -20, -24 ), Vector( 20, 20, 40 ) );
		g_EntityFuncs.SetSize( self.pev, Vector( -16, -16, -24 ), Vector( 16, 16, 40 ) );

		self.pev.solid = SOLID_SLIDEBOX;
		self.pev.movetype = MOVETYPE_STEP;

		if ( self.pev.health == 0.0f )
			self.pev.max_health = self.pev.health = 400.0f;

		self.m_bloodColor = BLOOD_COLOR_RED;

	//	self.StartMonster();
		self.m_MonsterState = MONSTERSTATE_NONE;

		self.m_FormattedName = "Ogre";

		self.pev.pain_finished = 0.0;
		m_iGibHealth = -80;

		WalkMonsterInit();
	}

	void Precache()
	{
		BaseClass.Precache();
	
		g_Game.PrecacheModel( Q1_OGRE_MODEL );

		g_SoundSystem.PrecacheSound( Q1_OGRE_SIGHT );
		g_SoundSystem.PrecacheSound( Q1_OGRE_PAIN );
		g_SoundSystem.PrecacheSound( Q1_OGRE_DEATH );
		g_SoundSystem.PrecacheSound( Q1_OGRE_SHOOT );
		g_SoundSystem.PrecacheSound( Q1_OGRE_MELEE );
		g_SoundSystem.PrecacheSound( Q1_OGRE_DRAG );
		for ( uint i = 0; i < Q1_OGRE_IDLE.length(); ++i )
			g_SoundSystem.PrecacheSound( Q1_OGRE_IDLE[i] );
	}

	void CornerReached()
	{
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, Q1_OGRE_DRAG, Math.RandomFloat( 0.95, 1.0 ), ATTN_IDLE, 0, 93 + Math.RandomLong( 0, 0xf ) );
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
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, Q1_OGRE_SIGHT, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );
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
		m_flMonsterSpeed = 16;
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

	void MonsterPain( CBaseEntity@ pAttacker, float flDamage )
	{
		if ( self.pev.pain_finished > g_Engine.time )
			return;

		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, Q1_OGRE_PAIN, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );
		m_iAIState = STATE_PAIN;
		SetActivity( ACT_BIG_FLINCH ) ;
		m_flMonsterSpeed = 0;
		self.pev.pain_finished = g_Engine.time + 1.0 - 0.3; // TODO: replace the 1.0 with sequence duration
	}

	bool MonsterHasMissileAttack() { return true; }
	bool MonsterHasMeleeAttack() { return true; }
	bool MonsterHasPain() { return true; }

	void MonsterAttack()
	{
		if ( m_Activity == ACT_RANGE_ATTACK1 )
			AI_Face();
		else if ( m_Activity == ACT_MELEE_ATTACK1 )
			AI_Charge( 4 );
		if ( m_iAIState == STATE_ATTACK && self.m_fSequenceFinished )
			MonsterRun();
	}

	void MonsterGrenade()
	{
		if ( !self.m_hEnemy )
			return;

		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, Q1_OGRE_SHOOT, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );
		self.pev.effects |= EF_MUZZLEFLASH;

		CBaseEntity@ pEnemy = self.m_hEnemy;

		Vector vecVelocity = ( pEnemy.pev.origin - self.pev.origin ).Normalize() * 600.0f;
		vecVelocity.z = 200;

		CBaseEntity@ pGrenade = q1_ShootCustomProjectile( "projectile_qgrenade", "models/quake1/grenade.mdl",
																self.pev.origin, vecVelocity, self.pev.angles, self );
		if ( pGrenade is null )
			return;

		pGrenade.pev.dmg = 80;
	}

	void MonsterChainsaw( float side = 0.0 )
	{
		if ( !self.m_hEnemy )
			return;

		CBaseEntity@ pEnemy = self.m_hEnemy;

	//	if ( pEnemy.pev.takedamage == 0 )
		if ( !q1_CanDamage( pEnemy, self ) )
			return;

		AI_Charge( 10 );

		Vector delta = pEnemy.pev.origin - self.pev.origin;

		if ( delta.Length() > 100 )
			return;

		float ldmg = ( Math.RandomFloat( 0.0, 1.0 ) + Math.RandomFloat( 0.0, 1.0 ) + Math.RandomFloat( 0.0, 1.0 ) ) * 4;
		if ( pEnemy.IsPlayer() )
		{
			if ( pEnemy.pev.armorvalue > 0 )
				ldmg *= 4.0;
			else
				ldmg *= 2.0;
		}

		pEnemy.TakeDamage( self.pev, self.pev, ldmg, DMG_GENERIC );

		if ( side != 0.0 )
		{
			g_EngineFuncs.MakeVectors( self.pev.angles );

			if ( side == 1 )
				q1_SpawnMeatSpray( self.pev.origin + g_Engine.v_forward * 16, Math.RandomFloat( -100.0, 100.0 ) * g_Engine.v_right );
			else
				q1_SpawnMeatSpray( self.pev.origin + g_Engine.v_forward * 16, side * g_Engine.v_right );
		}
	}

	void MonsterKilled( entvars_t@ pevAttacker, int iGib )
	{
		CBackPack@ pPack = q1_SpawnBackpack( self );
		if ( pPack !is null )
			pPack.m_iAmmoRockets = 2;

		if ( ShouldGibMonster( iGib ) )
		{
			m_fHasRemove = true;
			g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "quake1/gib.wav", Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );
			g_EntityFuncs.SpawnRandomGibs( self.pev, 1, 1 );
			g_EntityFuncs.Remove( self );
			return;
		}

		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, Q1_OGRE_DEATH, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );
	}

	void HandleAnimEvent( MonsterEvent@ pEvent )
	{
		switch ( pEvent.event )
		{
			case OGRE_DROP_BACKPACK:
				break;

			case OGRE_SHOOT_GRENADE:
				MonsterGrenade();
				break;

			case OGRE_CHAINSAW:
				MonsterChainsaw( atof( pEvent.options() ) );
				break;

			case OGRE_CHAINSAW_SOUND:
				g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, Q1_OGRE_MELEE, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );
				break;

			case OGRE_IDLE_SOUND:
				if ( Math.RandomFloat( 0, 1 ) < 0.1 )
					g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, Q1_OGRE_IDLE[0], Math.RandomFloat( 0.95, 1.0 ), ATTN_IDLE, 0, 93 + Math.RandomLong( 0, 0xf ) );
				break;

			case OGRE_IDLE_SOUND2:
				if ( Math.RandomFloat( 0, 1 ) < 0.1 )
					g_SoundSystem.EmitSoundDyn(self.edict(), CHAN_VOICE, Q1_OGRE_IDLE[1], Math.RandomFloat( 0.95, 1.0 ), ATTN_IDLE, 0, 93 + Math.RandomLong( 0, 0xf ) );
				break;

			case OGRE_DRAG_SOUND:
				if ( Math.RandomFloat( 0, 1 ) < 0.05 )
					g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, Q1_OGRE_DRAG, Math.RandomFloat( 0.95, 1.0 ), ATTN_IDLE, 0, 93 + Math.RandomLong( 0, 0xf ) );

			default:
				BaseClass.HandleAnimEvent( pEvent );
		}
	}
}

void q1_RegisterMonster_OGRE()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "monster_qogre", "monster_qogre" );
}
