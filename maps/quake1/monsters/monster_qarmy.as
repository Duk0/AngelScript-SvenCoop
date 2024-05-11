const string Q1_ARMY_MODEL = "models/quake1/m_army.mdl";

const string Q1_ARMY_IDLE  = "quake1/monsters/army/idle.wav";
const string Q1_ARMY_SIGHT = "quake1/monsters/army/sight.wav";

const array<string> Q1_ARMY_PAIN = {
	"quake1/monsters/army/pain1.wav",
	"quake1/monsters/army/pain2.wav"
};

const string Q1_ARMY_DEATH = "quake1/monsters/army/death.wav";
const string Q1_ARMY_SHOOT = "quake1/monsters/army/shoot.wav";

enum Q1_ARMY_EVENTS
{
	ARMY_END_ATTACK = 1,
	ARMY_DROP_BACKPACK,
	ARMY_SHOOT,
	ARMY_IDLE_SOUND
}

class monster_qarmy : ScriptBaseMonsterEntity, CQuakeMonster
{
	void Spawn()
	{
		Precache();

		g_EntityFuncs.SetModel( self, Q1_ARMY_MODEL );
		self.m_bloodColor = BLOOD_COLOR_RED;

		self.pev.health = 100;
		self.pev.solid = SOLID_SLIDEBOX;
		self.pev.movetype = MOVETYPE_STEP;
		g_EntityFuncs.SetSize( self.pev, Vector( -16, -16, -24 ), Vector( 16, 16, 40 ) );

		self.StartMonster();
		self.m_MonsterState = MONSTERSTATE_NONE;

		self.m_FormattedName = "Grunt";

		self.pev.pain_finished = 0.0;
		m_iGibHealth = -35;

		WalkMonsterInit();
	}

	void Precache()
	{
		g_Game.PrecacheModel( Q1_ARMY_MODEL );

		g_SoundSystem.PrecacheSound( Q1_ARMY_IDLE );
		g_SoundSystem.PrecacheSound( Q1_ARMY_SIGHT );
		g_SoundSystem.PrecacheSound( Q1_ARMY_DEATH );
		g_SoundSystem.PrecacheSound( Q1_ARMY_SHOOT );
		for ( uint i = 0; i < Q1_ARMY_PAIN.length(); ++i )
			g_SoundSystem.PrecacheSound( Q1_ARMY_PAIN[i] );
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
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, Q1_ARMY_SIGHT, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );
	}

	void MonsterWalk()
	{
		m_iAIState = STATE_WALK;
		SetActivity( ACT_WALK );
		m_flMonsterSpeed = 2.5;
		AI_Turn();
	}

	void MonsterRun()
	{
		m_iAIState = STATE_RUN;
		SetActivity( ACT_RUN );
		m_flMonsterSpeed = 8;
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
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, Q1_ARMY_PAIN[i], Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );

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

		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, Q1_ARMY_SHOOT, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );

		// fire somewhat behind the player, so a dodging player is harder to hit
		CBaseEntity@ pEnemy = self.m_hEnemy;
		if ( pEnemy is null )
			return;

		int iBulletDamage = 4;
		if ( pEnemy.IsPlayer() )
		{
			if ( pEnemy.pev.armorvalue > 0 )
				iBulletDamage *= 4;
			else
				iBulletDamage *= 2;
		}

		Vector vecDir = ( ( pEnemy.pev.origin - pEnemy.pev.velocity * 0.2f ) - self.pev.origin ).Normalize();
		self.FireBullets( 4, self.pev.origin, vecDir, Vector( 0.1, 0.1, 0 ), 2048, BULLET_PLAYER_CUSTOMDAMAGE, 4, iBulletDamage );

		self.pev.effects |= EF_MUZZLEFLASH;
		m_fInAttack = true;
	}

	void MonsterKilled( entvars_t@ pevAttacker, int iGib )
	{
		CBackPack@ pPack = q1_SpawnBackpack( self );
		if ( pPack !is null )
			pPack.m_iAmmoShells = 5;

		if ( ShouldGibMonster( iGib ) )
		{
			m_fHasRemove = true;
			g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "quake1/gib.wav", Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );
			g_EntityFuncs.SpawnHeadGib( self.pev );
			g_EntityFuncs.SpawnRandomGibs( self.pev, 1, 1 );
			g_EntityFuncs.Remove( self );
			return;
		}

		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, Q1_ARMY_DEATH, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );
	}

	void HandleAnimEvent( MonsterEvent@ pEvent )
	{
		switch ( pEvent.event )
		{
			case ARMY_END_ATTACK:
				m_fAttackDone = true;
				m_fInAttack = true;
				break;

			case ARMY_DROP_BACKPACK:
				break;

			case ARMY_SHOOT:
				MonsterFire();
				break;

			case ARMY_IDLE_SOUND:
				if ( Math.RandomFloat( 0, 1 ) < 0.2 )
					g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, Q1_ARMY_IDLE, Math.RandomFloat( 0.95, 1.0 ), ATTN_IDLE, 0, 93 + Math.RandomLong( 0, 0xf ) );
				break;

			default:
				BaseClass.HandleAnimEvent( pEvent );
		}
	}
}

void q1_RegisterMonster_ARMY()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "monster_qarmy", "monster_qarmy" );
}
