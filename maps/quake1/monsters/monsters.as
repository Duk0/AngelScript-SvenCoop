// most of this is taken directly from the Xash3D Quake Remake
// comments and everything

EHandle g_hWorld;

CBaseEntity@ GetWorld()
{
	if ( !g_hWorld || !g_hWorld.IsValid() )
		g_hWorld = g_EntityFuncs.Instance( 0 );

	return g_hWorld.GetEntity();
}

enum Q1_ATTACKSTATE
{
	ATTACK_NONE = 0,
	ATTACK_STRAIGHT,
	ATTACK_SLIDING,
	ATTACK_MELEE,
	ATTACK_MISSILE
};

enum Q1_AISTATE
{
	STATE_IDLE = 0,
	STATE_WALK,
	STATE_RUN,
	STATE_ATTACK,
	STATE_PAIN,
	STATE_DEAD
};

// distance ranges
enum Q1_RANGETYPE
{
	RANGE_MELEE = 0,
	RANGE_NEAR,
	RANGE_MID,
	RANGE_FAR
};

// you can use this in combination with either ScriptBaseAnimating or
// ScriptBaseMonsterEntity, but in the first case you won't have a
// HandleAnimEvents() function
mixin class CQuakeMonster
{
	private Vector m_vecSpawnPoint;

	private float m_flSearchTime = 0;
	private float m_flPauseTime = 0;
	private float m_flAttackFinished = 0;

	private bool m_fAttackDone = false;
	private bool m_fInAttack = false;

	private Q1_AISTATE m_iAIState = STATE_IDLE;
	private Q1_ATTACKSTATE m_iAttackState = ATTACK_NONE;

	private Activity m_Activity;           // what the monster is doing (animation)
	private Activity m_IdealActivity;      // monster should switch to this activity

	private float m_flMonsterSpeed = 0.0;
	private float m_flMoveDistance = 0.0;  // member last move distance. Used for strafe
	private bool m_fLeftY = false;

	private float m_flSightTime = 0.0;
	private int m_iRefireCount = 0;

	private float m_flEnemyYaw = 0.0;
	private Q1_RANGETYPE m_iEnemyRange = RANGE_MELEE;
	private bool m_fEnemyInFront = false;
	private bool m_fEnemyVisible = false;

	private int m_iGibHealth;

	private EHandle m_hSightEntity = null;
	private EHandle m_hGoalEnt = null;
//	private EHandle m_hEnemy = null;
	private EHandle m_hOldEnemy = null;
	private EHandle m_hMoveTarget = null;
	
	private bool m_fHitsound = false;
	private bool m_fHasRemove = false;
	
	private float m_flTime;

	int Classify()
	{
		return self.GetClassification( CLASS_ALIEN_MONSTER );
	}
/*
	void OnCreate()
	{
		g_EngineFuncs.ServerPrint( "OnCreate() " + self.GetClassname() +" spawnflags: " + self.pev.spawnflags + "\n" );
	}
*/
	void OnDestroy()
	{
		// PrecacheOther
		if ( self.GetOrigin() == g_vecZero )
			return;

		// just workaround, some monsters keep removing when fall down 
		if ( m_fHasRemove )
			return;

		g_EngineFuncs.ServerPrint( "OnDestroy() CQuakeMonster " + self.GetClassname() + ", origin: " + self.pev.origin.x + " " + self.pev.origin.y + " " + self.pev.origin.z + "\n" );

	//	g_iKilledMonsters++;

		g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, "[Quake Monster] " + self.m_FormattedName + " disappeared. Maybe he was too scared.\n" );
		
		g_iTotalMonsters--;

		if ( self.pev.target == "" )
			return;
			
		CBaseEntity@ pWorld = GetWorld();
		
		if ( pWorld is null )
			return;

		self.SUB_UseTargets( g_hWorld, USE_TOGGLE, 0 );
	}

	// overloaded monster functions (same as th_callbacks in quake)
	void MonsterIdle() {}

	void MonsterWalk() {}

	void MonsterRun() {}

	void MonsterMeleeAttack() {}

	void MonsterMissileAttack() {}

	void MonsterPain( CBaseEntity@ pAttacker, float flDamage )
	{
		m_iAIState = STATE_PAIN;
		SetActivity( ACT_BIG_FLINCH );
		m_flMonsterSpeed = 0;
	}

	void MonsterKilled( entvars_t@ pevAttacker, int iGib ) {}

	void MonsterSight() {}

	void MonsterAttack() { AI_Face(); }

	void CornerReached() {}  // called while path_corner is reached

	bool MonsterCheckAnyAttack()
	{
		return m_fEnemyVisible ? MonsterCheckAttack() : false;
	}

	bool MonsterCheckAttack()
	{
		CBaseEntity@ pTarg = self.m_hEnemy;
		if ( pTarg is null )
			return false;

		Vector spot1 = self.EyePosition();
		Vector spot2 = pTarg.EyePosition();

		TraceResult tr;
		g_Utility.TraceLine( spot1, spot2, dont_ignore_monsters, dont_ignore_glass, self.edict(), tr );

		if ( tr.pHit !is pTarg.edict() )
			return false;

		if ( tr.fInOpen != 0 && tr.fInWater != 0 )
			return false;

		if ( m_iEnemyRange == RANGE_MELEE )
		{
			if ( MonsterHasMeleeAttack() )
			{
				MonsterMeleeAttack();
				return true;
			}
		}

		if ( !MonsterHasMissileAttack() )
			return false;

		if ( g_Engine.time < m_flAttackFinished )
			return false;

		if ( m_iEnemyRange == RANGE_FAR )
			return false;

		float chance = 0.0;
		if ( m_iEnemyRange == RANGE_MELEE )
		{
			chance = 0.9;
			m_flAttackFinished = 0;
		}
		else if ( m_iEnemyRange == RANGE_NEAR )
		{
			if ( MonsterHasMeleeAttack() )
				chance = 0.2;
			else
				chance = 0.4;
		}
		else if ( m_iEnemyRange == RANGE_MID )
		{
			if ( MonsterHasMeleeAttack() )
				chance = 0.05;
			else
				chance = 0.1;
		}
		else
		{
			chance = 0;
		}

		if ( Math.RandomFloat( 0, 1 ) < chance )
		{
			MonsterMissileAttack();
			AttackFinished( Math.RandomFloat( 0, 2 ) );
			return true;
		}

		return false;
	}

	bool MonsterHasMeleeAttack() { return false; }
	bool MonsterHasMissileAttack() { return false; }
	bool MonsterHasPain() { return true; }  // tarbaby feels no pain

	void MonsterThink()
	{
		self.pev.nextthink = g_Engine.time + 0.1;
	//	Vector oldorigin = self.pev.origin;

		// NOTE: keep an constant interval to make sure what all events works as predicted
		float flInterval = self.StudioFrameAdvance( 0.099 ); // animate

		if ( m_iAIState != STATE_DEAD && self.m_fSequenceFinished )
		{
			self.ResetSequenceInfo();

			if ( m_iAIState == STATE_PAIN )
				MonsterRun(); // change activity
		}

		self.DispatchAnimEvents( flInterval );

		switch ( m_iAIState )
		{
			case STATE_WALK: AI_Walk( m_flMonsterSpeed ); break;
			case STATE_ATTACK: MonsterAttack(); break;
			case STATE_RUN: AI_Run( m_flMonsterSpeed ); break;
			case STATE_IDLE: AI_Idle(); break;
			default: break;
		}

		if ( self.IsAlive() && !self.pev.FlagBitSet( FL_ONGROUND|FL_FLY|FL_SWIM ) )
		{
			float gravity = g_pCvarGravity.value;
			if ( self.pev.velocity.z < gravity * -0.1f )
				m_fHitsound = true;
			else
				m_fHitsound = false;
		}
		else if ( m_fHitsound && self.pev.FlagBitSet( FL_ONGROUND ) )	// just hit ground
		{
			if ( self.pev.watertype > CONTENTS_WATER )
				g_SoundSystem.EmitSound( self.edict(), CHAN_AUTO, Q1_FIEND_LAND, 1.0, ATTN_NORM );

			m_fHitsound = false;
		}

		if ( self.pev.deadflag == DEAD_DEAD && m_iAIState != STATE_DEAD && m_Activity != ACT_DIESIMPLE && m_flTime < g_Engine.time )
		{
			m_flTime = g_Engine.time + 10.0;

			SetActivity( ACT_DIESIMPLE );
			m_iAIState = STATE_DEAD;
			
			g_EngineFuncs.ServerPrint( self.GetClassname() + ": m_iAIState: " + m_iAIState + ", m_iAttackState: " + m_iAttackState + ", m_Activity: " + m_Activity + ", m_IdealActivity: " + m_IdealActivity + "\n" );
		}
	}

	void MonsterUse( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float value )
	{
		if ( self.m_hEnemy )
			return;

		if ( self.pev.health <= 0 || self.pev.deadflag == DEAD_DEAD )
			return;

		if ( pActivator is null || pActivator.entindex() == 0 )
			return;

		if ( pActivator.pev.FlagBitSet( FL_NOTARGET ) )
			return;

		if ( !pActivator.IsPlayer() && self.Classify() == pActivator.Classify() )
			return;

		self.m_hEnemy = pActivator;
		SetThink( ThinkFunction( FoundTarget ) );
		self.pev.nextthink = g_Engine.time + 0.1;
	}

	void MonsterDeathUse( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float value )
	{
		self.pev.flags &= ~( FL_FLY|FL_SWIM );
		if ( self.pev.target == "" )
			return;

		self.SUB_UseTargets( pActivator, useType, value );
	}

	void MonsterTouch( CBaseEntity@ pOther )
	{
		if ( pOther.GetClassname() == "path_corner" )
			PathTouch( pOther );

		BaseClass.Touch( pOther );
	}

	int TakeDamage( entvars_t@ pevInflictor, entvars_t@ pevAttacker, float flDamage, int bitsDamageType )
	{
		if ( pevAttacker is null )
			return 0;

		CBaseEntity@ pAttacker = g_EntityFuncs.Instance( pevAttacker );

		if ( self.CheckAttacker( pAttacker ) )
			return 0;

		if ( self.pev.takedamage == 0 )
			return 0;

		if ( self.pev.deadflag == DEAD_DEAD )
			return 0;

		if ( self is pAttacker && pevAttacker.ClassNameIs( "monster_qshalrath" ) )
			return 0;

		CBaseEntity@ pEnemy = self.m_hEnemy;
		CBaseEntity@ pInflictor = g_EntityFuncs.Instance( pevInflictor );

		if ( pInflictor is null )
			return 0;

		float dmg_save = 0.0;
		float dmg_take = Math.Ceil( flDamage - dmg_save );
		
		CBaseEntity@ pWorld = GetWorld();

		// figure momentum add
		if ( ( pInflictor !is pWorld ) && ( self.pev.movetype == MOVETYPE_WALK ) )
		{
			Vector dir = ( self.pev.origin - pInflictor.Center() ).Normalize();
			self.pev.velocity = self.pev.velocity + dir * flDamage * 8;
		}

		if ( ( self.pev.flags & FL_GODMODE ) != 0 )
			return 0;

		// do the damage
		self.pev.health -= dmg_take;	

		if ( self.pev.health <= 0 )
		{
			Killed( pevAttacker, GIB_NORMAL );
			return 0;
		}

		if ( pAttacker is null )
			return 0;

		// Added score points - Duko
		if ( pAttacker.IsPlayer() )
		{
		//	self.GetDamagePoints( pevAttacker, pevInflictor, dmg_take );
		//	pAttacker.pev.frags += self.GetPointsForDamage( dmg_take );
		//	g_EngineFuncs.ServerPrint( "GetPointsForDamage: " + formatFloat( pInflictor.GetPointsForDamage( flDamage ), "", 0, 3 ) + ", flDamage: " + formatFloat( flDamage, "", 0, 3 ) + "\n" );
			pAttacker.pev.frags += dmg_take / 20;
		}
		
	//	g_EngineFuncs.ServerPrint( "pAttacker: " + pAttacker.entindex() + ", pEnemy: " + ( pEnemy is null ? "0" : string( pEnemy.entindex() ) ) + "\n" );

		if ( self.IsMonster() && pAttacker !is pWorld )
		{
			// get mad unless of the same class (except for soldiers)
			if ( self !is pAttacker && pAttacker !is pEnemy )
			{
			//	if ( self.GetClassname() != pAttacker.GetClassname() || self.GetClassname() == "monster_qarmy" )
			//	if ( !pAttacker.IsMonster() )
				if ( self.Classify() != pAttacker.Classify() )
				{
					if ( self.m_hEnemy && pEnemy.IsPlayer() )
						m_hOldEnemy = self.m_hEnemy;

					self.m_hEnemy = pAttacker;
					FoundTarget();
				}
			}
		}

		if ( MonsterHasPain() )
		{
			MonsterPain( pAttacker, dmg_take );
			self.pev.pain_finished = g_Engine.time + 5.0;
		}

		return 1;
	//	return BaseClass.TakeDamage( pevInflictor, pevAttacker, flDamage, bitsDamageType );
	}

	void Killed( entvars_t@ pevAttacker, int iGib )
	{
		MonsterKilled( pevAttacker, iGib );
		SetActivity( ACT_DIESIMPLE );
		m_iAIState = STATE_DEAD;
		self.pev.takedamage = DAMAGE_NO;
		self.pev.deadflag = DEAD_DEAD;
		self.pev.solid = SOLID_NOT;
		
		g_iKilledMonsters++;

		CBaseEntity@ pAttacker = g_EntityFuncs.Instance( pevAttacker );
		if ( pAttacker !is null && ( pAttacker.IsPlayer() || pAttacker.IsMonster() ) )
			pAttacker.AddPoints( 1, false );

		if ( !self.m_hEnemy )
			self.m_hEnemy = pAttacker;
		
//		g_EngineFuncs.ServerPrint( "Classname: " + self.GetClassname() + ", iGib: " + iGib + ", m_iAIState: " + m_iAIState + ", pAttacker: " + pAttacker.GetClassname() + ", m_hEnemy: " + m_hEnemy.GetEntity().GetClassname() + "\n" );

		MonsterDeathUse( self.m_hEnemy, self, USE_TOGGLE, 0.0 );
	}

	// common utility functions
	void SetEyePosition()
	{
		self.pev.view_ofs = Vector( 0, 0, 25 ); // TODO: figure out how to get eye offset from models
	}

	void SetActivity( Activity newActivity )
	{
		int iSeq = self.LookupActivity( newActivity );

		if ( iSeq > -1 )
		{
			if ( self.pev.sequence != iSeq || !self.m_fSequenceLoops )
				if ( !( m_Activity == ACT_WALK || m_Activity == ACT_RUN ) || !( newActivity == ACT_WALK || newActivity == ACT_RUN ) )
					self.pev.frame = 0;

			self.pev.sequence = iSeq;
			self.ResetSequenceInfo();
		}
		else
		{
			self.pev.sequence = 0;
		}

		m_Activity = newActivity;
		m_IdealActivity = newActivity;
	}

	void StopAnimation() { self.pev.framerate = 0; }

	void AttackFinished( float flFinishTime )
	{
		m_iRefireCount = 0;
		m_flAttackFinished = g_Engine.time + flFinishTime;
	}

	Q1_RANGETYPE TargetRange( CBaseEntity@ pTarg )
	{
		Vector vec1 = self.EyePosition();
		Vector vec2 = pTarg.EyePosition();

		float dist = ( vec2 - vec1 ).Length();
		if ( dist < 120 ) return RANGE_MELEE;
		if ( dist < 500 ) return RANGE_NEAR;
		if ( dist < 1000 ) return RANGE_MID;
		return RANGE_FAR;
	}

	bool TargetVisible( CBaseEntity@ pTarg )
	{
		if ( pTarg is null )
			return false;

		Vector vec1 = self.EyePosition();
		Vector vec2 = pTarg.EyePosition();
		TraceResult tr;
		g_Utility.TraceLine(vec1, vec2, ignore_monsters, ignore_glass, self.edict(), tr);

		if ( tr.fInOpen != 0 && tr.fInWater != 0 )
			return false;

		if ( tr.flFraction > 0.99 )
			return true;

		return false;
	}

	bool InFront( CBaseEntity@ pTarg )
	{
		Math.MakeVectors( self.pev.angles );
		Vector dir = ( pTarg.pev.origin - self.pev.origin ).Normalize();
		float flDot = DotProduct( dir, g_Engine.v_forward );

		if ( flDot > 0.3 )
			return true;

		return false;
	}

	bool FindTarget()
	{
		CBaseEntity@ pTarget = null;

		// if the first spawnflag bit is set, the monster will only wake up on
		// really seeing the player, not another monster getting angry

		// spawnflags & 3 is a big hack, because zombie crucified used the first
		// spawn flag prior to the ambush flag, and I forgot about it, so the second
		// spawn flag works as well
		if ( m_flSightTime >= ( g_Engine.time - 0.1f ) && !self.pev.SpawnFlagBitSet( 3 ) )
		{
			@pTarget = m_hSightEntity;
			CBaseMonster@ pMonster = cast<CBaseMonster@>( pTarget );
			if ( pTarget is null || pMonster is null || pMonster.m_hEnemy.GetEntity() is self.m_hEnemy.GetEntity() )
		//	if ( pTarget is null || pTarget.pev.enemy is self.pev.enemy )
				return false;
		}
		else
		{
			@pTarget = @g_EntityFuncs.Instance( g_EngineFuncs.FindClientInPVS( self.edict() ) );
			if ( pTarget is null )
				return false;
		}

		if ( pTarget.pev.health <= 0 )
			return false;
	
//		if ( pTarget.edict() is self.pev.enemy )
//			return false;

		if ( pTarget is self.m_hEnemy.GetEntity() )
			return false;
/*
		if ( self.m_hEnemy.GetEntity() !is null && pTarget.Classify() == self.m_hEnemy.GetEntity().Classify() )
			return false;
*/
		if ( pTarget.pev.FlagBitSet( FL_NOTARGET ) )
			return false;

		Q1_RANGETYPE range = TargetRange( pTarget );
		if ( range == RANGE_FAR )
			return false;

		if ( !TargetVisible( pTarget ) )
			return false;

/*		if ( !InFront( pTarget ) )
			return false;*/

		if ( range == RANGE_NEAR )
		{
		//	if ( pTarget->m_flShowHostile < gpGlobals->time && !InFront( pTarget ) )
			if ( pTarget.pev.fuser1 < g_Engine.time && !InFront( pTarget ) )
				return false;
		}
		else if ( range == RANGE_MID )
		{
			if ( !InFront( pTarget ) )
				return false;
		}

		self.m_hEnemy = pTarget;

		if ( !pTarget.IsPlayer() )
		{
		//	CBaseEntity@ pEnemy = g_EntityFuncs.Instance( pTarget.pev.enemy );
			self.m_hEnemy = cast<CBaseMonster@>( pTarget ).m_hEnemy;
			CBaseEntity@ pEnemy = self.m_hEnemy;

			if ( pEnemy is null || !pEnemy.IsPlayer() )
			{
				m_flPauseTime = g_Engine.time + 3.0;
				m_hGoalEnt = m_hMoveTarget;
				self.m_hEnemy = null;
				return false;
			}
		}
		
	//	@self.pev.enemy = @self.m_hEnemy.GetEntity().edict();

		FoundTarget();

		return true;
	}

	bool FacingIdeal()
	{
		float flDelta = Math.AngleMod( self.pev.angles.y - self.pev.ideal_yaw );
		return ( flDelta < 45 || flDelta > 315 );
	}

	void FoundTarget()
	{
		CBaseEntity@ pEnemy = self.m_hEnemy;

		if ( pEnemy !is null && ( pEnemy.IsPlayer() || self.Classify() != pEnemy.Classify() ) )
		{
			m_hSightEntity = pEnemy;
			m_flSightTime = g_Engine.time;
			// chain alert
			q1_AlertMonsters( pEnemy, self.pev.origin, 512 );
			// use target
		}
/*
		if ( pEnemy !is null )
			@self.pev.enemy = @pEnemy.edict();
		else
			@self.pev.enemy = null;
*/
		self.pev.fuser1 = g_Engine.time + 1.0; // wake up other monsters

		MonsterSight();
		HuntTarget();
	}

	void HuntTarget()
	{
		m_hGoalEnt = self.m_hEnemy;
		m_iAIState = STATE_RUN;

		CBaseEntity@ pEnemy = self.m_hEnemy;
		if ( pEnemy !is null )
			self.pev.ideal_yaw = Math.VecToYaw( pEnemy.pev.origin - self.pev.origin );

		SetThink( ThinkFunction( MonsterThink ) );
		self.pev.nextthink = g_Engine.time + 0.1;

		MonsterRun();
		AttackFinished( 1 );
	}

	bool ShouldGibMonster( int iGib )
	{
		return ( iGib == GIB_ALWAYS || self.pev.health < m_iGibHealth );
	}

	bool CheckRefire()
	{
		if ( m_iRefireCount != 0 )
			return false;

		CBaseEntity@ pEnemy = self.m_hEnemy;

		if ( pEnemy !is null && !TargetVisible( pEnemy ) )
			return false;

		++m_iRefireCount;

		return true;
	}

	// MoveExecute functions
	bool CloseEnough( float flDist )
	{
		if ( !m_hGoalEnt )
			return false;

		CBaseEntity@ pEnt = m_hGoalEnt;

		for ( int i = 0; i < 3; ++i )
		{
			if ( pEnt.pev.absmin[i] > self.pev.absmax[i] + flDist )
				return false;
			if ( pEnt.pev.absmax[i] < self.pev.absmin[i] - flDist )
				return false;
		}
		return true;
	}

	bool MoveStep( const Vector& in vecMove, bool relink )
	{
		float dz;
		TraceResult tr;

		// try the move	
		Vector oldorg = self.pev.origin;
		Vector neworg = self.pev.origin + vecMove;

		// flying monsters don't step up
		if ( self.pev.FlagBitSet( FL_SWIM|FL_FLY ) )
		{
			// try one move with vertical motion, then one without
			for ( int i = 0; i < 2; i++ )
			{
				CBaseEntity@ pEnemy = self.m_hEnemy;
				neworg = self.pev.origin + vecMove;

				if ( i == 0 && pEnemy !is null )
				{
					dz = self.pev.origin.z - pEnemy.pev.origin.z;

					if ( dz > 40 )
						neworg.z -= 8;
					if ( dz < 30 )
						neworg.z += 8;
				}

				g_Utility.TraceMonsterHull( self.edict(), self.pev.origin, neworg, dont_ignore_monsters, self.edict(), tr ); 
		
				if ( tr.flFraction == 1.0 )
				{
					if ( ( self.pev.flags & FL_SWIM ) != 0 && g_EngineFuncs.PointContents( tr.vecEndPos ) == CONTENTS_EMPTY )
						return false; // swim monster left water
		
					self.pev.origin = tr.vecEndPos;

					if ( relink )
						g_EntityFuncs.SetOrigin( self, self.pev.origin );
					return true;
				}
				
				if ( pEnemy is null )
					break;
			}
			
			return false;
		}

	//	float stepSize = 18.0; // default stepsize in sven
		float stepSize = g_pCvarStepSize.value;

		// push down from a step height above the wished position
		neworg.z += stepSize - 0.5;
		Vector end = neworg;
		end.z -= stepSize * 2.0 - 0.5;

		g_Utility.TraceMonsterHull( self.edict(), neworg, end, dont_ignore_monsters, self.edict(), tr );

		if ( tr.fAllSolid != 0 )
			return false;

		if ( tr.fStartSolid != 0 )
		{
			neworg.z -= stepSize;
			g_Utility.TraceMonsterHull( self.edict(), neworg, end, dont_ignore_monsters, self.edict(), tr );

			if ( tr.fAllSolid != 0 || tr.fStartSolid != 0 )
				return false;
		}

		if ( tr.flFraction == 1.0 )
		{
			// if monster had the ground pulled out, go ahead and fall
			if ( ( self.pev.flags & FL_PARTIALGROUND ) != 0 )
			{
				self.pev.origin = self.pev.origin + vecMove;

				if ( relink )
					g_EntityFuncs.SetOrigin( self, self.pev.origin );

				self.pev.flags &= ~FL_ONGROUND;
				return true;
			}

			return false; // walked off an edge
		}

		// check point traces down for dangling corners
		self.pev.origin = tr.vecEndPos;

		if ( g_EngineFuncs.EntIsOnFloor( self.edict() ) == 0 )
		{
			if ( ( self.pev.flags & FL_PARTIALGROUND ) != 0 )
			{
				// entity had floor mostly pulled out from underneath it
				// and is trying to correct
				if ( relink )
					g_EntityFuncs.SetOrigin( self, self.pev.origin );

				return true;
			}

			self.pev.origin = oldorg;
			return false;
		}

		// this cause remove monster if falling down to ground
	/*	if ( ( self.pev.flags & FL_PARTIALGROUND ) != 0 )
			self.pev.flags |= ~FL_PARTIALGROUND;*/

		@self.pev.groundentity = @tr.pHit;

		// the move is ok
		if ( relink )
			g_EntityFuncs.SetOrigin( self, self.pev.origin );

		return true;
	}

	bool WalkMove( float flYaw, float flDist )
	{
		return g_EngineFuncs.WalkMove( self.edict(), flYaw, flDist, WALKMOVE_NORMAL ) != 0;
	}

	bool StepDirection( float flYaw, float flDist )
	{
		self.pev.ideal_yaw = flYaw;
		g_EngineFuncs.ChangeYaw( self.edict() );
		flYaw = flYaw * Math.PI * 2.0 / 360.0;
		Vector move = Vector( cos( flYaw ) * flDist, sin( flYaw ) * flDist, 0.0 );
		Vector oldorg = self.pev.origin;
		if ( MoveStep( move, false ) )
		{
			float delta = self.pev.angles.y - self.pev.ideal_yaw;
			if ( delta > 45 && delta < 315 )
				self.pev.origin = oldorg;

			g_EntityFuncs.SetOrigin( self, self.pev.origin );
			return true;
		}

		g_EntityFuncs.SetOrigin( self, self.pev.origin );
		return false;
	}

	void NewChaseDir( CBaseEntity@ pEnemy, float flDist )
	{
		float olddir = Math.AngleMod( int( self.pev.ideal_yaw / 45 ) * 45.0 );
		float turnaround = Math.AngleMod( olddir - 180.0 );
		Vector delta = pEnemy.pev.origin - self.pev.origin;
		Vector d = g_vecZero;

		if ( delta.x > 10 ) d.y = 0;
		else if ( delta.x < -10 ) d.y = 180;
		else d.y = -1;
		if ( delta.y < -10 ) d.z = 270;
		else if ( delta.y > 10 ) d.z = 90;
		else d.z = -1;

		float tdir = 0.0;

		// direct route
		if ( d.y != -1 && d.z != -1 )
		{
			if ( d.y == 0 )
				tdir = d.z == 90 ? 45 : 315;
			else
				tdir = d.z == 90 ? 135 : 215;
			if ( tdir != turnaround && StepDirection( tdir, flDist ) )
				return;
		}

		// other directions
		if ( ( ( Math.RandomLong( 0, 2 ) & 3 ) & 1 ) != 0 || abs( delta.y ) > abs( delta.x ) )
		{
			tdir = d.y;
			d.y = d.z;
			d.z = tdir;
		}

		if ( d.y != -1 && d.y != turnaround && StepDirection( d.y, flDist ) )
			return;

		if ( d.z != -1 && d.z != turnaround && StepDirection( d.z, flDist ) )
			return;

		// there is no direct path to the player, so pick another direction
		// try old direction
		if ( olddir != -1 && StepDirection( olddir, flDist ) )
			return;

		// rotate to random side
		if ( Math.RandomLong(0, 1) == 1 )
		{
			for ( tdir = 0; tdir <= 315; tdir += 45 )
			{
				if ( tdir != turnaround && StepDirection( tdir, flDist ) )
					return;
			}
		}
		else
		{
			for ( tdir = 315; tdir >= 0; tdir -= 45 )
			{
				if ( tdir != turnaround && StepDirection( tdir, flDist ) )
					return;
			}
		}

		// if all else fails, turn around
		if ( turnaround != -1 && StepDirection( turnaround, flDist ) )
			return;

		// can't move
		self.pev.ideal_yaw = olddir;
		if ( g_EngineFuncs.EntIsOnFloor( self.edict() ) == 0 )
			self.pev.flags |= FL_PARTIALGROUND;
	}

	void MoveToGoal( float flDist, int iStrafe = 0 )
	{
		if ( ( self.pev.flags & ( FL_ONGROUND|FL_FLY|FL_SWIM ) ) == 0 )
			return;

		CBaseEntity@ pGoal = m_hGoalEnt;
		CBaseEntity@ pEnemy = self.m_hEnemy;
		
		if ( pGoal is null )
			return;

		if ( pEnemy !is null && CloseEnough( flDist ) )
			return;

		if ( ( Math.RandomLong( 0, 2 ) & 3 ) == 1 || !StepDirection( self.pev.ideal_yaw, flDist ) )
			NewChaseDir( pGoal, flDist );
	}

	void AI_Forward( float flDist ) { WalkMove( self.pev.angles.y, flDist ); }
	void AI_Backward( float flDist ) { WalkMove( self.pev.angles.y + 180.0, flDist ); }
	void AI_Pain( float flDist ) { AI_Backward( flDist ); }
	void AI_PainForward( float flDist ) { WalkMove( self.pev.ideal_yaw, flDist ); }

	void AI_Walk( float flDist )
	{
		m_flMoveDistance = flDist;
		g_EngineFuncs.ChangeYaw( self.edict() );

		if ( FindTarget() )
			return;

		MoveToGoal( flDist, 1 );

		if ( m_hGoalEnt && CloseEnough( flDist ) )
		{
			PathTouch( m_hGoalEnt );
		}
	}

	void AI_Run( float flDist )
	{
		Vector delta;

		m_flMoveDistance = flDist;

		// see if the enemy is dead
		CBaseEntity@ pEnemy = self.m_hEnemy;
		CBaseEntity@ pOldEnemy = m_hOldEnemy;
	//	g_EngineFuncs.ServerPrint( "pEnemy: " + ( pEnemy is null ? "0" : string( pEnemy.entindex() ) ) + ", pOldEnemy: " + ( pOldEnemy is null ? "0" : string( pOldEnemy.entindex() ) ) + "\n" );

		if ( !self.m_hEnemy || !pEnemy.IsAlive() || pEnemy.pev.health <= 0 || pEnemy.pev.FlagBitSet( FL_NOTARGET ) )
		{
			self.m_hEnemy = null;
		//	@self.pev.enemy = null;
			
			// FIXME: look all around for other targets
			if ( m_hOldEnemy && pOldEnemy.IsAlive() && pOldEnemy.pev.health > 0 && !pOldEnemy.pev.FlagBitSet( FL_NOTARGET ) )
			{
				self.m_hEnemy = m_hOldEnemy;
				@pEnemy = self.m_hEnemy;
			//	@self.pev.enemy = @pOldEnemy.edict();
				HuntTarget();
			}
			else
			{
			//	m_hOldEnemy = null;

				if ( m_hMoveTarget )
				{
					// g-cont. stay over defeated player a few seconds
					// then continue patrol (if present)
					m_flPauseTime = g_Engine.time + 5.0f;
					m_hGoalEnt = m_hMoveTarget;
				}

				MonsterIdle();
				return;
			}
		}

		if ( pEnemy is null )
			return;
		
		self.pev.fuser1 = g_Engine.time + 1.0; // wake up other monsters

		// check knowledge of enemy
		m_fEnemyVisible = TargetVisible( pEnemy );

		if ( m_fEnemyVisible )
			m_flSearchTime = g_Engine.time + 1.0;

		// look for other coop players
		if ( m_flSearchTime < g_Engine.time )
		{
			if ( FindTarget() )
				return;
		}

		m_fEnemyInFront = InFront( pEnemy );
		m_iEnemyRange = TargetRange( pEnemy );
		m_flEnemyYaw = Math.VecToYaw( pEnemy.pev.origin - self.pev.origin );

		if ( m_iAttackState == ATTACK_MISSILE )
		{
			AI_Run_Missile();
			return;
		}

		if ( m_iAttackState == ATTACK_MELEE )
		{
			AI_Run_Melee();
			return;
		}

		if ( MonsterCheckAnyAttack() )
			return; // beginning an attack

		if ( m_iAttackState == ATTACK_SLIDING )
		{
			AI_Run_Slide();
			return;
		}

		// head straight in
		MoveToGoal( flDist ); // done in C code...

		// HACK: this wasn't in the original code
		//       but the AI turns like a retard without it
		if ( m_fEnemyVisible )
			AI_Face();
	}

	void AI_Idle()
	{
		if ( FindTarget() )
			return;

		if ( g_Engine.time > m_flPauseTime )
		{
			MonsterWalk();
			return;
		}

		// change angle slightly
	}

	void AI_Turn()
	{
		if ( FindTarget() )
			return;

		g_EngineFuncs.ChangeYaw( self.edict() );
	}

	void AI_Run_Melee()
	{
		if ( FindTarget() )
			return;

		self.pev.ideal_yaw = m_flEnemyYaw;
		g_EngineFuncs.ChangeYaw( self.edict() );

		if ( FacingIdeal() )
		{
			MonsterMeleeAttack();
			m_iAttackState = ATTACK_STRAIGHT;
		}
	}

	void AI_Run_Missile()
	{
		if ( FindTarget() )
			return;

		self.pev.ideal_yaw = m_flEnemyYaw;
		g_EngineFuncs.ChangeYaw( self.edict() );

		if ( FacingIdeal() )
		{
			MonsterMissileAttack();
			m_iAttackState = ATTACK_STRAIGHT;
		}
	}

	void AI_Run_Slide()
	{
		self.pev.ideal_yaw = m_flEnemyYaw;
		g_EngineFuncs.ChangeYaw( self.edict() );

		float ofs = m_fLeftY ? 90 : -90;

		if ( WalkMove( self.pev.ideal_yaw + ofs, m_flMoveDistance ) )
			return;

		m_fLeftY = !m_fLeftY;

		WalkMove( self.pev.ideal_yaw - ofs, m_flMoveDistance );
	}

	void AI_Charge( float flDist ) { AI_Face(); MoveToGoal( flDist ); }

	void AI_Charge_Side()
	{
		if ( !self.m_hEnemy )
			return; // removed before stroke

		// aim to the left of the enemy for a flyby
		AI_Face();

		CBaseEntity@ pEnemy = self.m_hEnemy;
		Math.MakeVectors( self.pev.angles );
		Vector dtemp = pEnemy.pev.origin - g_Engine.v_right * 30;

		float heading = Math.VecToYaw( dtemp - self.pev.origin );
		WalkMove( heading, 20 );
	}

	void AI_Face()
	{
		if ( self.m_hEnemy )
		{
			CBaseEntity@ pEnemy = self.m_hEnemy;
			self.pev.ideal_yaw = Math.VecToYaw( pEnemy.pev.origin - self.pev.origin );
		}

		g_EngineFuncs.ChangeYaw( self.edict() );
	}

	void AI_Melee()
	{
		if ( !self.m_hEnemy )
			return; // removed before stroke

		CBaseEntity@ pEnemy = self.m_hEnemy;

		Vector delta = pEnemy.pev.origin - self.pev.origin;
		if ( delta.Length() > 60 )
			return;

		float ldmg = ( Math.RandomFloat( 0, 3 ) + Math.RandomFloat( 0, 3 ) + Math.RandomFloat( 0, 3 ) );
		if ( pEnemy.IsPlayer() )
		{
			if ( pEnemy.pev.armorvalue > 0 )
				ldmg *= 4.0;
			else
				ldmg *= 2.0;
		}

		pEnemy.TakeDamage( self.pev, self.pev, ldmg, DMG_GENERIC );
	}

	void AI_Melee_Side()
	{
		if ( !self.m_hEnemy )
			return; // removed before stroke

		AI_Charge_Side();

		CBaseEntity@ pEnemy = self.m_hEnemy;

		Vector delta = pEnemy.pev.origin - self.pev.origin;

		if ( delta.Length() > 60 )
			return;

		if ( !q1_CanDamage( pEnemy, self ) )
			return;

		float ldmg = ( Math.RandomFloat( 0, 3 ) + Math.RandomFloat( 0, 3 ) + Math.RandomFloat( 0, 3 ) );
		if ( pEnemy.IsPlayer() )
		{
			if ( pEnemy.pev.armorvalue > 0 )
				ldmg *= 4.0;
			else
				ldmg *= 2.0;
		}

		pEnemy.TakeDamage( self.pev, self.pev, ldmg, DMG_GENERIC );
	}

	void PathTouch( CBaseEntity@ pOther )
	{
/*		// from Xash3D port
		if ( pOther.m_hMoveTarget !is self )
			return;

		// If OTHER has an enemy, this touch is incidental, ignore
		if ( pOther.m_hEnemy )
			return; // fighting, not following a path*/

		CBaseEntity@ pMoveTarget = m_hMoveTarget;
		if ( pMoveTarget !is pOther )
			return;

		// If OTHER has an enemy, this touch is incidental, ignore
		if ( self.m_hEnemy )
			return; // fighting, not following a path
			
		CBaseMonster@ pMonster = cast<CBaseMonster@>( pOther );
		if ( pMonster !is null )
			CornerReached(); // ogre uses this

		CBaseEntity@ pGoal = pOther.GetNextTarget();
		m_hGoalEnt = pGoal;
		m_hMoveTarget = m_hGoalEnt;

		// If "next spot" was not found (does not exist - level design error)
		if ( !m_hMoveTarget )
		{
			if ( pMonster !is null )
			{
				// path is ends here
				m_flPauseTime = 99999999.0;
				MonsterIdle();
			}
		}
		else
		{
			// Turn towards the next stop in the path.
		//	self.pev.ideal_yaw = Math.VecToYaw( pGoal.pev.origin - self.pev.origin );
			pOther.pev.ideal_yaw = Math.VecToYaw( pGoal.pev.origin - pOther.pev.origin );
		}
	}

	int ISoundMask()
	{
		return bits_SOUND_COMBAT | bits_SOUND_PLAYER;
	}

	// monsters init
	void FlyMonsterInitThink()
	{
		self.pev.takedamage = DAMAGE_AIM;
		self.pev.ideal_yaw = self.pev.angles.y;

		if ( self.pev.yaw_speed == 0 )
			self.pev.yaw_speed = 10;

		SetEyePosition();
		SetUse( UseFunction( MonsterUse ) );

		self.pev.flags |= ( FL_FLY|FL_MONSTER );

		if ( !WalkMove( 0, 0 ) )
		{
			g_Game.AlertMessage( at_error, "Monster %1 stuck in wall--level design error\n", self.GetClassname() );
			self.pev.effects = EF_BRIGHTFIELD;
		}

		if ( self.pev.target != "" )
		{
			m_hGoalEnt = self.GetNextTarget();
			m_hMoveTarget = m_hGoalEnt;

			if ( !m_hGoalEnt )
			{
				g_Game.AlertMessage( at_error, "MonsterInit()--%1 couldn't find target %2", self.GetClassname(), self.pev.target );
			}

			CBaseEntity@ pGoalEnt = m_hGoalEnt;

			if ( m_hGoalEnt && pGoalEnt.GetClassname() == "path_corner" )
			{
				MonsterWalk();
			}
			else
			{
				m_flPauseTime = 99999999.0;
				MonsterIdle();
			}
		}
		else
		{
			m_flPauseTime = 99999999.0;
			MonsterIdle();
		}

		// run AI for monster
		SetThink( ThinkFunction( MonsterThink ) );
		self.pev.nextthink = g_Engine.time + 0.01;

		// move back to spawn, all monsters drop to floor in sven
		self.pev.origin = m_vecSpawnPoint;
	}

	void FlyMonsterInit()
	{
		// spread think times so they don't all happen at same time
		m_vecSpawnPoint = self.pev.origin;
		self.pev.nextthink += Math.RandomFloat( 0.1, 0.4 );
		SetThink( ThinkFunction( FlyMonsterInitThink ) );
		SetTouch( TouchFunction( MonsterTouch ) );

		// add one monster to stat
		g_iTotalMonsters++;
	}

	void WalkMonsterInitThink()
	{
		self.pev.origin.z += 1;
		g_EngineFuncs.DropToFloor( self.edict() );

		self.pev.takedamage = DAMAGE_AIM;
		self.pev.ideal_yaw = self.pev.angles.y;

		if ( self.pev.yaw_speed == 0 )
			self.pev.yaw_speed = 10;

		SetEyePosition();
		SetUse( UseFunction( MonsterUse ) );

		self.pev.flags |= FL_MONSTER;

		if ( self.pev.target != "" )
		{
			m_hGoalEnt = self.GetNextTarget();
			m_hMoveTarget = m_hGoalEnt;

			CBaseEntity@ pGoalEnt = m_hGoalEnt;

			if ( !m_hGoalEnt )
			{
				g_Game.AlertMessage( at_error, "MonsterInit()--%1 couldn't find target %2", self.GetClassname(), self.pev.target );
			}
			else
			{
				self.pev.ideal_yaw = Math.VecToYaw( pGoalEnt.pev.origin - self.pev.origin );
			}

			if ( m_hGoalEnt && pGoalEnt.GetClassname() == "path_corner" )
			{
				MonsterWalk();
			}
			else
			{
				m_flPauseTime = 99999999.0;
				MonsterIdle();
			}
		}
		else
		{
			m_flPauseTime = 99999999.0;
			MonsterIdle();
		}

		// run AI for monster
		SetThink( ThinkFunction( MonsterThink ) );
		self.pev.nextthink = g_Engine.time + 0.01;
	}

	void WalkMonsterInit()
	{
		// spread think times so they don't all happen at same time
		self.pev.nextthink += Math.RandomFloat( 0.1, 0.4 );
		SetThink( ThinkFunction( WalkMonsterInitThink ) );
		SetTouch( TouchFunction( MonsterTouch ) );

		// add one monster to stat
		g_iTotalMonsters++;
	}

	void SwimMonsterInitThink()
	{
		self.pev.takedamage = DAMAGE_AIM;
		self.pev.ideal_yaw = self.pev.angles.y;

		if ( self.pev.yaw_speed == 0 )
			self.pev.yaw_speed = 10;

		SetEyePosition();
		SetUse( UseFunction( MonsterUse ) );

		self.pev.flags |= ( FL_SWIM | FL_MONSTER );

		if ( self.pev.target != "" )
		{
			m_hGoalEnt = self.GetNextTarget();
			m_hMoveTarget = m_hGoalEnt;
			
			CBaseEntity@ pGoalEnt = m_hGoalEnt;

			if ( !m_hGoalEnt )
			{
				g_Game.AlertMessage( at_error, "MonsterInit()--%1 couldn't find target %2", self.GetClassname(), self.pev.target );
			}
			else
			{
				self.pev.ideal_yaw = Math.VecToYaw( pGoalEnt.pev.origin - self.pev.origin );
			}

			if ( m_hGoalEnt && pGoalEnt.GetClassname() == "path_corner" )
			{
				MonsterWalk();
			}
			else
			{
				m_flPauseTime = 99999999.0;
				MonsterIdle();
			}
		}
		else
		{
			m_flPauseTime = 99999999.0;
			MonsterIdle();
		}

		// run AI for monster
		SetThink( ThinkFunction( MonsterThink ) );
		self.pev.nextthink = g_Engine.time + 0.01;
	}

	void SwimMonsterInit()
	{
		// spread think times so they don't all happen at same time
		self.pev.nextthink += Math.RandomFloat( 0.1, 0.4 );
		SetThink( ThinkFunction( SwimMonsterInitThink ) );
		SetTouch( TouchFunction( MonsterTouch ) );

		// add one monster to stat
		g_iTotalMonsters++;
	}
}

void q1_AlertMonsters( CBaseEntity@ pWho, Vector vecWhere, float flRadius )
{
	array <CBaseEntity@> aEnts( 32 );
	int iNum = g_EntityFuncs.MonstersInSphere( aEnts, vecWhere, flRadius );
	CBaseEntity@ pEnt;

	for ( int i = 0; i < iNum; ++i )
	{
		@pEnt = aEnts[i];
		if ( pEnt is null )
			continue;

		if ( pEnt.pev.health > 0 && pEnt !is pWho && pEnt.IsMonster() )
		{
			if ( pEnt.FVisible( vecWhere ) )
				pEnt.Use( pWho, pWho, USE_TOGGLE );
		}
	}
}

void q1_SpawnMeatSpray( Vector vecOrigin, Vector vecVelocity )
{
/*	vecVelocity.z += 250 + Math.RandomFloat( 0.0f, 50.0f );
	q1_ShootCustomProjectile( "projectile_qspray", "models/quake1/zombiegib.mdl",
													vecOrigin, vecVelocity, Math.VecToAngles( vecVelocity ), null );*/
													
	CBaseEntity@ pSpray = g_EntityFuncs.Create( "projectile_qspray", vecOrigin, Math.VecToAngles( vecVelocity ), true );
	if ( pSpray is null ) 
		return;

	pSpray.pev.velocity = vecVelocity;

	g_EntityFuncs.DispatchSpawn( pSpray.edict() );
	
//	g_Utility.BloodStream( vecOrigin, vecVelocity, BLOOD_COLOR_RED, 1 )
}

void q1_StartMonster()
{
	g_hWorld = g_EntityFuncs.Instance( 0 );
}
