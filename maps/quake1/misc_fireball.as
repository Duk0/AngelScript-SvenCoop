/*QUAKED misc_fireball (0 .5 .8) (-8 -8 -8) (8 8 8)
Lava Balls
*/
class CFireBallOriginal : ScriptBaseEntity
{
	void Precache()
	{
		BaseClass.Precache();

		g_Game.PrecacheModel( "models/quake1/lavaball.mdl" );
	}

	void OnCreate()
	{
		Precache();
	//	g_EngineFuncs.ServerPrint( "OnCreate() misc_fireball spawnflags: " + self.pev.spawnflags + "\n" );
	}

	void OnDestroy()
	{
	//	g_EngineFuncs.ServerPrint( "OnDestroy() misc_fireball spawnflags: " + self.pev.spawnflags + "\n" );
	
		if ( !self.pev.SpawnFlagBitSet( 2048 ) )
			return;

		CBaseEntity@ pEntity = g_EntityFuncs.Create( "misc_qfireball", self.GetOrigin(), g_vecZero, false );
		if ( pEntity is null )
			return;

		pEntity.pev.speed = self.pev.speed;
	}
}

class CFireBallSource : ScriptBaseEntity
{
	void Precache()
	{
		BaseClass.Precache();

		g_Game.PrecacheModel( "models/quake1/lavaball.mdl" );
	}

	void Spawn()
	{
		Precache();
	
		if ( self.pev.speed == 0 )
			self.pev.speed = 1000;

		self.pev.nextthink = g_Engine.time + Math.RandomFloat( 0.1, 5.0 );
	}

	void Think()
	{
		CBaseEntity@ pFireBall = g_EntityFuncs.Create( "qfireball", self.GetOrigin(), g_vecZero, false );
		if ( pFireBall !is null )
			pFireBall.pev.velocity.z = self.pev.speed + Math.RandomFloat( 0, 200 );

		self.pev.nextthink = g_Engine.time + Math.RandomFloat( 3, 8 );
	}
}

class CFireBall : ScriptBaseEntity
{
	void Spawn()
	{
		self.pev.solid = SOLID_TRIGGER;
		self.pev.movetype = MOVETYPE_TOSS;
		self.pev.velocity.x = Math.RandomFloat( -50, 50 );
		self.pev.velocity.y = Math.RandomFloat( -50, 50 );

		self.pev.avelocity.x = Math.RandomFloat( -50, 50 );
		self.pev.avelocity.y = Math.RandomFloat( -50, 50 );
		self.pev.avelocity.z = Math.RandomFloat( -50, 50 );
		SetTouch( TouchFunction( LavaTouch ) );
		self.pev.vuser1 = Vector( 1, 1, 1 );
		
		self.pev.effects |= EF_BRIGHTLIGHT;

		g_EntityFuncs.SetModel( self, "models/quake1/lavaball.mdl" );
		g_EntityFuncs.SetOrigin( self, self.pev.origin );
	}

	void LavaTouch( CBaseEntity@ pOther )
	{
		if ( self.pev.waterlevel > 0 )
		{
			g_EntityFuncs.Remove( self );
			return;
		}

		pOther.TakeDamage( self.pev, self.pev, 20, DMG_BURN );

		if ( pOther.pev.solid != SOLID_BSP )
		{
			g_EntityFuncs.Remove( self );
			return;
		}

		TraceResult tr = g_Utility.GetGlobalTrace();

		self.pev.rendermode = kRenderTransTexture;
		self.pev.renderamt = 255;
		self.pev.pain_finished = g_Engine.time;

		self.pev.vuser1 = tr.vecPlaneNormal * -1;
		g_Utility.DecalTrace( tr, DECAL_SCORCH1 + Math.RandomLong( 0, 1 ) );

		SetThink( ThinkFunction( DieThink ) );
		SetTouch( null );

	//	self.pev.renderfx = kRenderLavaDeform;
		self.pev.renderfx = kRenderFxPulseFast;
		self.pev.movetype = MOVETYPE_NONE;

		self.pev.nextthink = g_Engine.time + 0.001;
		self.pev.animtime = g_Engine.time + 0.1;
	}

	void DieThink()
	{
		float flDegree = ( g_Engine.time - self.pev.pain_finished ) / 1.0f;

		self.pev.renderamt = 255 - ( 255 * flDegree );
		self.pev.nextthink = g_Engine.time + 0.001;

		if ( self.pev.renderamt <= 200 ) self.pev.effects &= ~EF_BRIGHTLIGHT;

		if ( self.pev.renderamt <= 0 ) g_EntityFuncs.Remove( self );
	}
}

void q1_RegisterMiscFireBall()
{
	g_Game.PrecacheModel( "models/quake1/lavaball.mdl" );

	g_CustomEntityFuncs.RegisterCustomEntity( "CFireBallOriginal", "misc_fireball" );
	g_CustomEntityFuncs.RegisterCustomEntity( "CFireBallSource", "misc_qfireball" );
	g_CustomEntityFuncs.RegisterCustomEntity( "CFireBall", "qfireball" );
}
