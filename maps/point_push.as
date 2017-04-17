enum PointPushFlags
{
	SF_TRIGGER_PUSH_ONCE = 1,
	SF_TRIGGER_PUSH_START_OFF = 2,
	SF_TRIGGER_NOCLIENTS = 8,
	SF_TRIGGER_NOMONSTERS = 16
}

class point_push : ScriptBaseEntity
{
	private Vector m_vecSize;

	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if ( szKey == "m_vecSize" )
		{
			g_Utility.StringToVector( m_vecSize, szValue );
			return true;
		}
		else
			return BaseClass.KeyValue( szKey, szValue );
	}

	void Precache()
	{
		BaseClass.Precache();
	}

/*	void SetupModel()
	{
		if ( string( self.pev.model ).IsEmpty() )
			g_Game.PrecacheModel( "models/kosobar.mdl" );
		else
			g_Game.PrecacheModel( self.pev.model );
	}*/
	
	void Spawn()
	{
		if ( self.pev.angles != g_vecZero )
			SetMovedir( self.pev );

		if ( self.pev.angles == g_vecZero )
			self.pev.angles.y = 360;

		self.pev.movetype = MOVETYPE_NONE;
		
		if ( ( self.pev.spawnflags & SF_TRIGGER_PUSH_START_OFF ) != 0 )
			self.pev.solid = SOLID_NOT;
		else
			self.pev.solid = SOLID_TRIGGER;
		
		if ( self.pev.speed == 0 )
			self.pev.speed = 100;
		
		g_EntityFuncs.SetOrigin( self, self.pev.origin );
		
		if ( m_vecSize != g_vecZero )
		{
			const Vector vecSize = m_vecSize.opDiv( 2 );

			const Vector vecMin = vecSize.opNeg();
			const Vector vecMax = vecSize;

			g_EntityFuncs.SetSize( self.pev, vecMin, vecMax );
		}
		else
			g_EntityFuncs.SetSize( self.pev, Vector( -10, -10, -10 ), Vector( 10, 10, 10 ) );
		
		if ( g_EngineFuncs.CVarGetFloat( "showtriggers" ) == 0 )
			self.pev.effects |= EF_NODRAW;
			
		self.Precache();
	}
	
	void Touch( CBaseEntity@ pOther )
	{
		//if ( ( pevToucher.flags & FL_CLIENT|FL_MONSTER ) == 0 )
		if ( !pOther.IsPlayer() && !pOther.IsMonster() )
			return;

		if ( ( self.pev.spawnflags & SF_TRIGGER_NOMONSTERS ) != 0 )
		{// no monsters allowed!
			if ( pOther.IsMonster() )
				return;
		}

		if ( ( self.pev.spawnflags & SF_TRIGGER_NOCLIENTS ) != 0 )
		{// no clients allowed
			if ( pOther.IsPlayer() )
				return;
		}
		
		entvars_t@ pevToucher = pOther.pev;
	
		switch( pevToucher.movetype )
		{
			case MOVETYPE_NONE:
			case MOVETYPE_PUSH:
			case MOVETYPE_NOCLIP:
		//	case MOVETYPE_FLYMISSILE:
			case MOVETYPE_BOUNCE:
		//	case MOVETYPE_BOUNCEMISSILE:
			case MOVETYPE_FOLLOW:
		//	case MOVETYPE_PUSHSTEP:
			return;
		}

		if ( pevToucher.solid != SOLID_NOT && pevToucher.solid != SOLID_BSP )
		{
			// Instant trigger, just transfer velocity and remove
			if ( ( self.pev.spawnflags & SF_TRIGGER_PUSH_ONCE ) != 0 )
			{
				pevToucher.velocity = pevToucher.velocity + ( pev.speed * pev.movedir );
				if ( pevToucher.velocity.z > 0 )
					pevToucher.flags &= ~FL_ONGROUND;
				g_EntityFuncs.Remove( self );
			}
			else
			{	// Push field, transfer to base velocity
				Vector vecPush = ( pev.speed * pev.movedir );
				if ( ( pevToucher.flags & FL_BASEVELOCITY ) != 0 )
					vecPush = vecPush + pevToucher.basevelocity;

				pevToucher.basevelocity = vecPush;

				pevToucher.flags |= FL_BASEVELOCITY;
	//			g_Game.AlertMessage( at_console, "Vel %1, base %2\n", pevToucher.velocity.z, pevToucher.basevelocity.z );
			}
		}
	}
	
	//void Use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float value ) {}
}

void SetMovedir( entvars_t@ pVars )
{
	if ( pVars.angles == Vector( 0, -1, 0 ) )
		pVars.movedir = Vector( 0, 0, 1 );
	else if ( pVars.angles == Vector( 0, -2, 0 ) )
		pVars.movedir = Vector( 0, 0, -1 );
	else
	{
		g_EngineFuncs.MakeVectors( pVars.angles );
		pVars.movedir = g_Engine.v_forward;
	}
	
	pVars.angles = g_vecZero;
}

void RegisterPointPushEntity()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "point_push", "point_push" );
}
