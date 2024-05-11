class qnailshooter : ScriptBaseEntity
{
	private float m_fShootTime = 0.0;

	void Spawn()
	{
		Precache();
		BaseClass.Spawn();

		self.pev.movetype = MOVETYPE_NONE;
		self.pev.solid = SOLID_NOT;

		if ( self.pev.dmg == 0 ) self.pev.dmg = 9;
	}

	void Precache()
	{
		g_Game.PrecacheModel( "models/quake1/spike.mdl" );
		g_SoundSystem.PrecacheSound( "quake1/weapons/nailgun2.wav" );
		g_SoundSystem.PrecacheSound( "quake1/weapons/tink1.wav" );
	}

	void Use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float value )
	{
		if ( m_fShootTime > g_Engine.time )
			return;

		m_fShootTime = g_Engine.time + 0.1; // don't let it shoot too often

		g_EngineFuncs.MakeVectors( self.pev.angles );
		g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, "quake1/weapons/nailgun2.wav", 1.0, ATTN_NORM );
		CBaseEntity@ pBolt = q1_ShootCustomProjectile( "projectile_qspike", "models/quake1/spike.mdl", 
												self.pev.origin, g_Engine.v_forward * 1024, 
												self.pev.angles, self );
		
		if ( pBolt is null )
			return;

		pBolt.pev.dmg = self.pev.dmg;
	}
}

// don't feel like fucking around with triggers all day
class trigger_qboss : ScriptBaseEntity
{
	private bool m_fPylonA = false;
	private bool m_fPylonB = false;
	private float m_flFireTime = 0;

	void Spawn()
	{
		Precache();
		BaseClass.Spawn();
		self.pev.movetype = MOVETYPE_NONE;
		self.pev.solid = SOLID_NOT;
	}

	void Precache()
	{
		g_SoundSystem.PrecacheSound( "quake1/shock.wav" );
	}

	void Use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float value )
	{
		if ( pCaller.GetClassname() == "func_door" )
		{
			if ( pCaller.pev.targetname == "pa" )
				m_fPylonA = !m_fPylonA;
			else if ( pCaller.pev.targetname == "pb" )
				m_fPylonB = !m_fPylonB;

			m_flFireTime = g_Engine.time + 1.0;
		}
		else if ( pCaller.GetClassname() == "func_button" )
		{
			if ( m_fPylonA && m_fPylonB && m_flFireTime <= g_Engine.time )
			{
				g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, "quake1/shock.wav", 1.0, ATTN_NORM );
				self.SUB_UseTargets( self, USE_TOGGLE, 0 );
				// try hurting the boss
				CBaseEntity@ pBoss = g_EntityFuncs.FindEntityByClassname( null, "monster_qboss" );
				if ( pBoss !is null )
					pBoss.TakeDamage( self.pev, pActivator.pev, 1, DMG_ENERGYBEAM );
			}
		}
	}
}

class trigger_qteleport : ScriptBaseEntity
{
	private int m_iNumAttempts = 0;
	private int m_iMaxAttempts = 2;

	void Spawn()
	{
		if ( self.pev.angles != g_vecZero )
			SetMovedir( self.pev );

		self.pev.movetype = MOVETYPE_NONE;
		self.pev.solid = SOLID_TRIGGER;

		g_EntityFuncs.SetModel( self, self.pev.model );
		
		if ( g_EngineFuncs.CVarGetFloat( "showtriggers" ) == 0 )
			self.pev.effects |= EF_NODRAW;

		if ( self.pev.SpawnFlagBitSet( 16384 ) )
			SetTouch( TouchFunction( TeleportTouch ) );
/*
		self.pev.nextthink = g_Engine.time + 0.2;
		g_Engine.force_retouch++; // make sure even still objects get hit
		SetThink( null );*/
	}
	
	void Use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue = 0.0f )
	{
		SetThink( ThinkFunction( TeleportThink ) );
		self.pev.nextthink = g_Engine.time + 0.2;
	}

	void TeleportTouch( CBaseEntity@ pOther )
	{
		if ( !pOther.pev.FlagBitSet( FL_MONSTER ) )
			return;

		if ( self.pev.target == "" )
			return;

		CBaseEntity@ pTarget = g_EntityFuncs.FindEntityByTargetname( null, self.pev.target );
		
		if ( pTarget is null )
			return;

		Vector vecOrigin = pTarget.GetOrigin();
		vecOrigin.z += 30;

		g_EntityFuncs.SetOrigin( pOther, vecOrigin );

		if ( pTarget.pev.SpawnFlagBitSet( 32 ) )
			pTarget.SUB_UseTargets( self, USE_TOGGLE, 0 );
		
		if ( self.pev.SpawnFlagBitSet( 256 ) )
			pOther.pev.angles = pTarget.pev.angles;

		if ( self.pev.SpawnFlagBitSet( 512 ) )
		{
			pOther.pev.velocity = pTarget.pev.velocity;
			pOther.pev.basevelocity = pTarget.pev.basevelocity;
		}
		else
		{
			pOther.pev.velocity = pOther.pev.basevelocity = g_vecZero;
		}	
		
		g_EngineFuncs.ServerPrint( "TeleportTouch " + pOther.GetClassname() + "\n" );
	}

	void TeleportThink()
	{
		if ( self.pev.target == "" )
			return;

		if ( m_iNumAttempts >= m_iMaxAttempts )
		{
			SetThink( null );
			return;
		}
	
		self.pev.nextthink = g_Engine.time + 0.5;
		
		m_iNumAttempts++;

		array<CBaseEntity@> pArray( 1 );
		int iRes = g_EntityFuncs.EntitiesInBox( pArray, self.pev.mins, self.pev.maxs, FL_MONSTER );
		CBaseEntity@ pEntity = pArray[0];
		
		g_EngineFuncs.ServerPrint( "iRes: " + iRes + ", m_iNumAttempts: " + m_iNumAttempts + "\n" );
		
		if ( iRes <= 0 || pEntity is null )
			return;
			
		CBaseEntity@ pTarget = g_EntityFuncs.FindEntityByTargetname( null, self.pev.target );
		
		if ( pTarget is null )
			return;

		Vector vecOrigin = pTarget.GetOrigin();
		vecOrigin.z += 20;

		g_EntityFuncs.SetOrigin( pEntity, vecOrigin  );
		
		if ( pTarget.pev.SpawnFlagBitSet( 32 ) )
		{
		//	string szTarget = pTarget.pev.target;
			pTarget.SUB_UseTargets( self, USE_TOGGLE, 0 );
		}
		
		if ( self.pev.SpawnFlagBitSet( 256 ) )
			pEntity.pev.angles = pTarget.pev.angles;

		if ( self.pev.SpawnFlagBitSet( 512 ) )
		{
			pEntity.pev.velocity = pTarget.pev.velocity;
			pEntity.pev.basevelocity = pTarget.pev.basevelocity;
		}
		else
		{
			pEntity.pev.velocity = pEntity.pev.basevelocity = g_vecZero;
		}

		g_EngineFuncs.ServerPrint( "TeleportThink " + pEntity.GetClassname() + "\n" );
	}
}

class point_qteleport : ScriptBaseEntity
{
	private int m_iNumAttempts = 0;
	private int m_iMaxAttempts = 2;
	private float m_flRadius = 50.0;

	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if ( szKey == "m_flRadius" )
		{
			m_flRadius = atof( szValue );
			return true;
		}
		else
			return BaseClass.KeyValue( szKey, szValue );
	}

	void Spawn()
	{
		self.pev.movetype = MOVETYPE_NONE;
		self.pev.solid = SOLID_NOT;
	}
	
	void Use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue = 0.0f )
	{
		SetThink( ThinkFunction( TeleportThink ) );
		self.pev.nextthink = g_Engine.time + 0.2;
	}

	void TeleportThink()
	{
		if ( self.pev.target == "" )
			return;

		if ( m_iNumAttempts >= m_iMaxAttempts )
		{
			SetThink( null );
			return;
		}
	
		self.pev.nextthink = g_Engine.time + 0.5;
		
		m_iNumAttempts++;

		array<CBaseEntity@> pArray( 1 );
		int iRes = g_EntityFuncs.MonstersInSphere( pArray, self.GetOrigin(), m_flRadius );
		CBaseEntity@ pEntity = pArray[0];
		
		g_EngineFuncs.ServerPrint( "iRes: " + iRes + ", m_iNumAttempts: " + m_iNumAttempts + "\n" );
		
		if ( iRes <= 0 || pEntity is null )
			return;
			
		CBaseEntity@ pTarget = g_EntityFuncs.FindEntityByTargetname( null, self.pev.target );
		
		if ( pTarget is null )
			return;

		Vector vecOrigin = pTarget.GetOrigin();
		vecOrigin.z += 20;

		g_EntityFuncs.SetOrigin( pEntity, vecOrigin  );
		
		if ( pTarget.pev.SpawnFlagBitSet( 32 ) )
		{
		//	string szTarget = pTarget.pev.target;
			pTarget.SUB_UseTargets( self, USE_TOGGLE, 0 );
		}
		
		if ( self.pev.SpawnFlagBitSet( 256 ) )
			pEntity.pev.angles = pTarget.pev.angles;

		if ( self.pev.SpawnFlagBitSet( 512 ) )
		{
			pEntity.pev.velocity = pTarget.pev.velocity;
			pEntity.pev.basevelocity = pTarget.pev.basevelocity;
		}
		else
		{
			pEntity.pev.velocity = pEntity.pev.basevelocity = g_vecZero;
		}

		g_EngineFuncs.ServerPrint( "TeleportThink " + pEntity.GetClassname() + "\n" );
	}
}

void SetMovedir( entvars_t@ pevEnt )
{
	if ( pevEnt.angles == Vector( 0, -1, 0 ) )
		pevEnt.movedir = Vector( 0, 0, 1 );
	else if ( pevEnt.angles == Vector( 0, -2, 0 ) )
		pevEnt.movedir = Vector( 0, 0, -1 );
	else
	{
		g_EngineFuncs.MakeVectors( pevEnt.angles );
		pevEnt.movedir = g_Engine.v_forward;
	}
	
	pevEnt.angles = g_vecZero;
}

void q1_RegisterTriggers()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "qnailshooter", "qnailshooter" );
	g_CustomEntityFuncs.RegisterCustomEntity( "trigger_qboss", "trigger_qboss" );
	g_CustomEntityFuncs.RegisterCustomEntity( "trigger_qteleport", "trigger_qteleport" );
	g_CustomEntityFuncs.RegisterCustomEntity( "point_qteleport", "point_qteleport" );
}
