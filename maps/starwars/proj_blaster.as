	
class CBlaster : ScriptBaseEntity
{
	bool keepRepeatingLight = true;
	float m_yawCenter;
	float m_pitchCenter;
	int m_iExplode, m_iSpriteTexture, m_iSpriteTexture2, m_iGlow, m_iSmoke, m_iTrail, m_iBlasterBolt, m_iBlasterImpact;
	CBeam@	m_pBeam;
	private CSprite@ m_pSprite;
	
	void Spawn()
	{
		Precache();
		self.pev.movetype = MOVETYPE_FLY;
		self.pev.solid = SOLID_BBOX;
		g_EntityFuncs.SetModel( self, E11_MODEL_PROJECTILE );
		self.pev.body = 1;
		m_yawCenter = pev.angles.y;
		m_pitchCenter = pev.angles.x;
		g_EntityFuncs.SetSize( self.pev, g_vecZero, g_vecZero );
		
		@m_pSprite = g_EntityFuncs.CreateSprite( "sprites/red.spr", self.pev.origin, false );
		
		if ( m_pSprite !is null )
		{
			m_pSprite.SetTransparency( kRenderTransAdd, 0, 0, 0, 50, 14 );
			m_pSprite.SetScale( 0.25 );
			m_pSprite.SetAttachment( self.edict(), 0 );
		}
	}
	
	void Precache()
	{
		m_iExplode = g_Game.PrecacheModel( "sprites/starwars/expB1.spr" );
		m_iSpriteTexture = g_Game.PrecacheModel( "sprites/white.spr" );
		m_iSpriteTexture2 = g_Game.PrecacheModel( "sprites/spray.spr" );
		m_iGlow = g_Game.PrecacheModel( "sprites/red.spr" );
		m_iSmoke = g_Game.PrecacheModel( "sprites/steam1.spr" );
		m_iTrail = g_Game.PrecacheModel( "sprites/smoke.spr" );
		m_iBlasterBolt = g_Game.PrecacheModel( "sprites/starwars/blasterboltred.spr" );
		m_iBlasterImpact = g_Game.PrecacheModel( "sprites/starwars/blasterimpact.spr" );
	}
	
	void Ignite()
	{
		uint8 r = 128, g = 128, b = 128, br = 128;
		uint8 r2 = 255, g2 = 200, b2 = 200, br2 = 128;
		
		// rocket trail
		NetworkMessage ntrail1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
			ntrail1.WriteByte( TE_BEAMFOLLOW );
			ntrail1.WriteShort( self.entindex() );
			ntrail1.WriteShort( m_iTrail );
			ntrail1.WriteByte( Math.RandomLong( 5, 30 ) ); //Life
			ntrail1.WriteByte( Math.RandomLong( 4, 5 ) ); //Width
			ntrail1.WriteByte( r );
			ntrail1.WriteByte( g );
			ntrail1.WriteByte( b );
			ntrail1.WriteByte( br );
		ntrail1.End();
		NetworkMessage ntrail2( MSG_PVS, NetworkMessages::SVC_TEMPENTITY );
			ntrail2.WriteByte( TE_BEAMFOLLOW );
			ntrail2.WriteShort( self.entindex() );
			ntrail2.WriteShort( m_iSpriteTexture2 );
			ntrail2.WriteByte( Math.RandomLong( 5, 30 ) ); //Life
			ntrail2.WriteByte( Math.RandomLong( 4, 5 ) ); //Width
			ntrail2.WriteByte( r2 );
			ntrail2.WriteByte( g2 );
			ntrail2.WriteByte( b2 );
			ntrail2.WriteByte( br2 );
		ntrail2.End();
	}
	
	void BlasterLight()
	{
		if ( m_pBeam !is null )
		{
			g_EntityFuncs.Remove( m_pBeam );
			@m_pBeam = null;
		}
		
		Math.MakeAimVectors( pev.angles );
		
		@m_pBeam = g_EntityFuncs.CreateBeam( "sprites/starwars/blasterboltred.spr", 15 );

		if ( m_pBeam !is null )
		{
			m_pBeam.SetStartPos( self.pev.origin + g_Engine.v_forward * 10 );
			m_pBeam.SetEndPos( self.pev.origin - g_Engine.v_forward * 90 );
			m_pBeam.SetColor( 255, 100, 100 );
			m_pBeam.SetScrollRate( 0 );
			m_pBeam.SetBrightness( 255 );
			m_pBeam.pev.velocity = self.pev.velocity;
		}
		
		if ( keepRepeatingLight )
		{
			SetThink( ThinkFunction( this.BlasterLight ) );
			self.pev.nextthink = g_Engine.time + 0.0;
		}
	}

	void ExplodeTouch( CBaseEntity@ pOther )
	{
		entvars_t@ pevOwner = self.pev.owner.vars;

		if ( g_EngineFuncs.PointContents( self.pev.origin ) == CONTENTS_SKY )
		{
			g_EntityFuncs.Remove( self );
			return;
		}

		TraceResult tr;
		Vector vecSpot = self.pev.origin - self.pev.velocity.Normalize() * 32;
		Vector vecEnd = self.pev.origin + self.pev.velocity.Normalize() * 64;
		g_Utility.TraceLine( vecSpot, vecEnd, ignore_monsters, self.edict(), tr );

		Explode( pOther, tr, DMG_ENERGYBEAM );
		ProjectileDynamicLight( self.pev.origin, 8, 255, 0, 0, 1, 150 );
		g_Utility.DecalTrace( tr, DECAL_SMALLSCORCH1 );
		
		if ( pOther.pev.takedamage == 1 )
		{
			g_WeaponFuncs.ClearMultiDamage();
			pOther.TraceAttack( pevOwner, self.pev.dmg / 8, g_Engine.v_forward , tr, DMG_BULLET ); 
			g_WeaponFuncs.ApplyMultiDamage( self.pev, pevOwner );
		}
	}

	void Explode( CBaseEntity@ pOther, TraceResult pTrace, int bitsDamageType )
	{
		entvars_t@ pevOwner = self.pev.owner.vars;
		
		int damaged = pOther.TakeDamage(self.pev, pevOwner, self.pev.dmg, DMG_ENERGYBEAM );
		g_WeaponFuncs.RadiusDamage( self.pev.origin, self.pev, pevOwner, self.pev.dmg / 4, self.pev.dmg / 2, CLASS_PLAYER, DMG_ENERGYBEAM );
		
		ProjectileEffect( self.pev.origin );
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, E11_SOUND_EXPLODE, 0.2, ATTN_LOW_HIGH, 0, PITCH_NORM );

		keepRepeatingLight = false;
		self.pev.velocity = g_vecZero;
		SetTouch( null );
		
		if ( m_pSprite !is null )
			g_EntityFuncs.Remove( m_pSprite );

		if ( m_pBeam !is null )
			g_EntityFuncs.Remove( m_pBeam );

		g_EntityFuncs.Remove( self );
	}
	
	void te_sparks( Vector pos, NetworkMessageDest msgType = MSG_BROADCAST, edict_t@ dest = null )
	{
		NetworkMessage m( msgType, NetworkMessages::SVC_TEMPENTITY, dest );
		m.WriteByte( TE_SPARKS );
		m.WriteCoord( pos.x );
		m.WriteCoord( pos.y );
		m.WriteCoord( pos.z );
		m.End();
	}

	void te_ricochet( Vector pos, uint8 scale = 10, 
		NetworkMessageDest msgType = MSG_BROADCAST, edict_t@ dest = null )
	{
		NetworkMessage m( msgType, NetworkMessages::SVC_TEMPENTITY, dest );
		m.WriteByte( TE_ARMOR_RICOCHET );
		m.WriteCoord( pos.x );
		m.WriteCoord( pos.y );
		m.WriteCoord( pos.z );
		m.WriteByte( scale );
		m.End();
	}

	void te_sprite( Vector pos, string sprite = "sprites/starwars/blasterimpact.spr", 
		uint8 scale = 1, uint8 alpha = 50, 
		NetworkMessageDest msgType = MSG_BROADCAST, edict_t@ dest = null )
	{
		NetworkMessage m( msgType, NetworkMessages::SVC_TEMPENTITY, dest );
		m.WriteByte( TE_SPRITE );
		m.WriteCoord( pos.x );
		m.WriteCoord( pos.y );
		m.WriteCoord( pos.z );
		m.WriteShort( m_iBlasterImpact > 0 ? m_iBlasterImpact : g_EngineFuncs.ModelIndex( sprite ) );
		m.WriteByte( scale );
		m.WriteByte( alpha );
		m.End();
	}

	void Killed( entvars_t@ pevAttacker, int iGib )
	{	
		if ( m_pSprite !is null )
			g_EntityFuncs.Remove( m_pSprite );

		if ( m_pBeam !is null )
			g_EntityFuncs.Remove( m_pBeam );

		g_EntityFuncs.Remove( self );
	}
	
	void UpdateOnRemove()
	{
		if ( m_pSprite !is null )
			g_EntityFuncs.Remove( m_pSprite );

		if ( m_pBeam !is null )
			g_EntityFuncs.Remove( m_pBeam );
	}

	void ProjectileEffect( Vector origin )
	{
/*		int fireballScale = 3;
		int fireballBrightness = 255;*/
		uint8 smokeScale = 7;
/*		int discLife = 12;
		int discWidth = 64;
		int discR = 255;
		int discG = 0;
		int discB = 0;
		int glowR = 255;
		int glowG = 0;
		int glowB = 0;
		int discBrightness = 128;
		int glowLife = 1;
		int glowScale = 8;
		int glowBrightness = 25;*/
		
		te_sparks( origin );
		te_sprite( origin );

		// Big Plume of Smoke
		NetworkMessage projectilexp2( MSG_PVS, NetworkMessages::SVC_TEMPENTITY );
			projectilexp2.WriteByte( TE_SMOKE );
			projectilexp2.WriteCoord( origin.x );
			projectilexp2.WriteCoord( origin.y );
			projectilexp2.WriteCoord( origin.z );
			projectilexp2.WriteShort( m_iSmoke );
			projectilexp2.WriteByte( smokeScale );
			projectilexp2.WriteByte( 24 ); //framrate
		projectilexp2.End();

	}
}

// HIGH POWER BLASTER _______________________________________________________________________________________________________
// HIGH POWER BLASTER _______________________________________________________________________________________________________
// HIGH POWER BLASTER _______________________________________________________________________________________________________
// HIGH POWER BLASTER _______________________________________________________________________________________________________
// HIGH POWER BLASTER _______________________________________________________________________________________________________


class CHPBlaster : ScriptBaseEntity
{
	bool keepRepeatingLight = true;
	float m_yawCenter;
	float m_pitchCenter;
	int m_iExplode, m_iSpriteTexture, m_iSpriteTexture2, m_iGlow, m_iSmoke, m_iTrail, m_iBlasterBolt, m_iBlasterImpact;
	CBeam@	m_pBeam;
	private CSprite@ m_pSprite;
	
	void Spawn()
	{
		Precache();
		self.pev.movetype = MOVETYPE_FLY;
		self.pev.solid = SOLID_BBOX;
		g_EntityFuncs.SetModel( self, BOWCASTER_MODEL_PROJECTILE );
		self.pev.body = 1;
		m_yawCenter = pev.angles.y;
		m_pitchCenter = pev.angles.x;
		g_EntityFuncs.SetSize( self.pev, g_vecZero, g_vecZero );
		
		@m_pSprite = g_EntityFuncs.CreateSprite( "sprites/red.spr", self.pev.origin, false );

		if ( m_pSprite !is null )
		{
			m_pSprite.SetTransparency( kRenderTransAdd, 0, 0, 0, 50, 14 );
			m_pSprite.SetScale( 0.25 );
			m_pSprite.SetAttachment( self.edict(), 0 );
		}
	}
	
	void Precache()
	{
		m_iExplode = g_Game.PrecacheModel( "sprites/starwars/expB1.spr" );
		m_iSpriteTexture = g_Game.PrecacheModel( "sprites/white.spr" );
		m_iSpriteTexture2 = g_Game.PrecacheModel( "sprites/spray.spr" );
		m_iGlow = g_Game.PrecacheModel( "sprites/red.spr" );
		m_iSmoke = g_Game.PrecacheModel( "sprites/steam1.spr" );
		m_iTrail = g_Game.PrecacheModel( "sprites/smoke.spr" );
		m_iBlasterBolt = g_Game.PrecacheModel( "sprites/starwars/blasterboltred.spr" );
		m_iBlasterImpact = g_Game.PrecacheModel( "sprites/starwars/blasterimpact.spr" );
	}
	
	void Ignite()
	{
		uint8 r = 128, g = 128, b = 128, br = 128;
		uint8 r2 = 255, g2 = 200, b2 = 200, br2 = 128;
		
		// rocket trail
		NetworkMessage ntrail1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
			ntrail1.WriteByte( TE_BEAMFOLLOW );
			ntrail1.WriteShort( self.entindex() );
			ntrail1.WriteShort( m_iTrail );
			ntrail1.WriteByte( Math.RandomLong( 5, 30 ) ); //Life
			ntrail1.WriteByte( Math.RandomLong( 4, 5 ) ); //Width
			ntrail1.WriteByte( r );
			ntrail1.WriteByte( g );
			ntrail1.WriteByte( b );
			ntrail1.WriteByte( br );
		ntrail1.End();
		NetworkMessage ntrail2( MSG_PVS, NetworkMessages::SVC_TEMPENTITY );
			ntrail2.WriteByte( TE_BEAMFOLLOW );
			ntrail2.WriteShort( self.entindex() );
			ntrail2.WriteShort( m_iSpriteTexture2 );
			ntrail2.WriteByte( Math.RandomLong( 5, 30 ) ); //Life
			ntrail2.WriteByte( Math.RandomLong( 4, 5 ) ); //Width
			ntrail2.WriteByte( r2 );
			ntrail2.WriteByte( g2 );
			ntrail2.WriteByte( b2 );
			ntrail2.WriteByte( br2 );
		ntrail2.End();
	}
	
	void BlasterLight()
	{
		if ( m_pBeam !is null )
		{
			g_EntityFuncs.Remove( m_pBeam );
			@m_pBeam = null;
		}

		Math.MakeAimVectors( pev.angles );

		@m_pBeam = g_EntityFuncs.CreateBeam( "sprites/starwars/blasterboltred.spr", 25 );

		if ( m_pBeam !is null )
		{
			m_pBeam.SetStartPos( self.pev.origin + g_Engine.v_forward * 10 );
			m_pBeam.SetEndPos( self.pev.origin - g_Engine.v_forward * 90 );
			m_pBeam.SetColor( 255, 100, 100 );
			m_pBeam.SetScrollRate( 0 );
			m_pBeam.SetBrightness( 255 );
			m_pBeam.pev.velocity = self.pev.velocity;
		}
		
		if ( keepRepeatingLight )
		{
			SetThink( ThinkFunction( this.BlasterLight ) );
			self.pev.nextthink = g_Engine.time + 0.0;
		}
	}

	void ExplodeTouch( CBaseEntity@ pOther )
	{
		entvars_t@ pevOwner = self.pev.owner.vars;

		if ( g_EngineFuncs.PointContents( self.pev.origin ) == CONTENTS_SKY )
		{
			g_EntityFuncs.Remove( self );
			return;
		}

		TraceResult tr;
		Vector vecSpot = self.pev.origin - self.pev.velocity.Normalize() * 32;
		Vector vecEnd = self.pev.origin + self.pev.velocity.Normalize() * 64;
		g_Utility.TraceLine( vecSpot, vecEnd, ignore_monsters, self.edict(), tr );

		//_______PUSHING__________
		
		if ( pOther.pev.classname != "monster_sentry" && pOther.pev.classname != "flechette" && !pOther.IsBSPModel() )
		{
			Math.MakeVectors( pevOwner.v_angle );
			pOther.pev.velocity = pOther.pev.velocity + g_Engine.v_forward * 4 * self.pev.dmg;
		}
		
		//________________________

		Explode( pOther, tr, DMG_ENERGYBEAM );
		ProjectileDynamicLight( self.pev.origin, 8, 255, 0, 0, 1, 150 );
		g_Utility.DecalTrace( tr, DECAL_OFSCORCH1 );
		
		if ( pOther.pev.takedamage == 1 )
		{
			g_WeaponFuncs.ClearMultiDamage();
			pOther.TraceAttack( pevOwner, self.pev.dmg / 8, g_Engine.v_forward , tr, DMG_BULLET ); 
			g_WeaponFuncs.ApplyMultiDamage( self.pev, pevOwner );
		}
	}

	void Explode( CBaseEntity@ pOther, TraceResult pTrace, int bitsDamageType )
	{
		entvars_t@ pevOwner = self.pev.owner.vars;
		
		int damaged = pOther.TakeDamage(self.pev, pevOwner, self.pev.dmg, DMG_ENERGYBEAM );
		g_WeaponFuncs.RadiusDamage( self.pev.origin, self.pev, pevOwner, self.pev.dmg / 4, self.pev.dmg / 2, CLASS_PLAYER, DMG_ENERGYBEAM );
		
		ProjectileEffect( self.pev.origin );
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, BOWCASTER_SOUND_EXPLODE, 0.4, ATTN_LOW_HIGH, 0, PITCH_NORM );

		keepRepeatingLight = false;
		self.pev.velocity = g_vecZero;
		SetTouch( null );
		
		if ( m_pSprite !is null )
			g_EntityFuncs.Remove( m_pSprite );

		if ( m_pBeam !is null )
			g_EntityFuncs.Remove( m_pBeam );

		g_EntityFuncs.Remove( self );
	}
	
	void te_sprite( Vector pos, string sprite = "sprites/starwars/blasterimpact.spr", 
		uint8 scale = 1, uint8 alpha = 50, 
		NetworkMessageDest msgType = MSG_BROADCAST, edict_t@ dest = null )
	{
		NetworkMessage m( msgType, NetworkMessages::SVC_TEMPENTITY, dest );
		m.WriteByte( TE_SPRITE );
		m.WriteCoord( pos.x );
		m.WriteCoord( pos.y );
		m.WriteCoord( pos.z );
		m.WriteShort( m_iBlasterImpact > 0 ? m_iBlasterImpact : g_EngineFuncs.ModelIndex( sprite ) );
		m.WriteByte( scale );
		m.WriteByte( alpha );
		m.End();
	}	
		
	void te_sparks( Vector pos, 
		NetworkMessageDest msgType = MSG_BROADCAST, edict_t@ dest = null)
	{
		NetworkMessage m( msgType, NetworkMessages::SVC_TEMPENTITY, dest );
		m.WriteByte( TE_SPARKS );
		m.WriteCoord( pos.x );
		m.WriteCoord( pos.y );
		m.WriteCoord( pos.z );
		m.End();
	}

	void te_ricochet( Vector pos, uint8 scale = 10, 
		NetworkMessageDest msgType = MSG_BROADCAST, edict_t@ dest = null )
	{
		NetworkMessage m( msgType, NetworkMessages::SVC_TEMPENTITY, dest );
		m.WriteByte( TE_ARMOR_RICOCHET );
		m.WriteCoord( pos.x );
		m.WriteCoord( pos.y );
		m.WriteCoord( pos.z );
		m.WriteByte( scale );
		m.End();
	}

	void Killed( entvars_t@ pevAttacker, int iGib )
	{
		entvars_t@ pevOwner = self.pev.owner.vars;

		if ( pevOwner !is null && pevOwner.ClassNameIs( "player" ) )
			g_EngineFuncs.SetView( self.pev.owner, self.pev.owner );

		if ( m_pSprite !is null )
			g_EntityFuncs.Remove( m_pSprite );

		if ( m_pBeam !is null )
			g_EntityFuncs.Remove( m_pBeam );

		g_EntityFuncs.Remove( self );
	}
	
	void UpdateOnRemove()
	{
		if ( m_pSprite !is null )
			g_EntityFuncs.Remove( m_pSprite );

		if ( m_pBeam !is null )
			g_EntityFuncs.Remove( m_pBeam );
	}
	
	void ProjectileEffect( Vector origin )
	{
/*		int fireballScale = 3;
		int fireballBrightness = 255;*/
		uint8 smokeScale = 12;
/*		int discLife = 12;
		int discWidth = 64;
		int discR = 255;
		int discG = 0;
		int discB = 0;
		int glowR = 255;
		int glowG = 0;
		int glowB = 0;
		int discBrightness = 128;
		int glowLife = 1;
		int glowScale = 8;
		int glowBrightness = 25;*/
		
		te_sparks( origin );
		te_sprite( origin );

		// Big Plume of Smoke
		NetworkMessage projectilexp2( MSG_PVS, NetworkMessages::SVC_TEMPENTITY );
			projectilexp2.WriteByte( TE_SMOKE );
			projectilexp2.WriteCoord( origin.x );
			projectilexp2.WriteCoord( origin.y );
			projectilexp2.WriteCoord( origin.z );
			projectilexp2.WriteShort( m_iSmoke );
			projectilexp2.WriteByte( smokeScale );
			projectilexp2.WriteByte( 24 ); //framrate
		projectilexp2.End();
	}
}


//________________________________________________________________________________
//________________________________________________________________________________
//________________________________________________________________________________
//________________________________________________________________________________
//____FLECHETTEAMMOCSHOOT____


class CCShoot : ScriptBaseEntity
{
	bool keepRepeatingLight = true;
	float m_yawCenter;
	float m_pitchCenter;
	int m_iExplode, m_iSpriteTexture, m_iSpriteTexture2, m_iGlow, m_iSmoke, m_iTrail, m_iSpriteTextureShoot;
	private CSprite@ m_pSprite;
	
	void Spawn()
	{
		Precache();
		self.pev.movetype = MOVETYPE_TOSS;
		self.pev.solid = SOLID_BBOX;
		g_EntityFuncs.SetModel( self, HREPEATER_MODEL_NULL );
		self.pev.body = 1;
		m_yawCenter = pev.angles.y;
		m_pitchCenter = pev.angles.x;
		g_EntityFuncs.SetSize( self.pev, g_vecZero, g_vecZero );
		
		@m_pSprite = g_EntityFuncs.CreateSprite( "sprites/starwars/cshoot.spr", self.pev.origin, false );
		
		if ( m_pSprite !is null )
		{
			m_pSprite.SetTransparency( kRenderTransAdd, 0, 0, 0, 255, 14 );
			m_pSprite.SetScale( 0.25 );
			m_pSprite.SetAttachment( self.edict(), 0 );
		}
	}
	
	void Precache()
	{
		m_iExplode = g_Game.PrecacheModel( "sprites/starwars/expB1.spr" );
		m_iSpriteTexture = g_Game.PrecacheModel( "sprites/white.spr" );
		m_iSpriteTexture2 = g_Game.PrecacheModel( "sprites/spray.spr" );
		m_iGlow = g_Game.PrecacheModel( "sprites/red.spr" );
		m_iSmoke = g_Game.PrecacheModel( "sprites/steam1.spr" );
		m_iTrail = g_Game.PrecacheModel( "sprites/smoke.spr" );
		m_iSpriteTextureShoot = g_Game.PrecacheModel( "sprites/starwars/cshoot.spr" );
	}
	
	void CShootLight()
	{
		if ( keepRepeatingLight )
		{
			ProjectileDynamicLight( self.pev.origin, 16, 0, 0, 25, 0, 150 );	
			SetThink( ThinkFunction( this.CShootLight ) );
			self.pev.nextthink = g_Engine.time + 0.0;
		}
	}
	
	void ExplodeTouch( CBaseEntity@ pOther )
	{
		entvars_t@ pevOwner = self.pev.owner.vars;

		if ( g_EngineFuncs.PointContents( self.pev.origin ) == CONTENTS_SKY )
		{
			g_EntityFuncs.Remove( self );
			return;
		}
		
		TraceResult tr;
		Vector vecSpot = self.pev.origin - self.pev.velocity.Normalize() * 32;
		Vector vecEnd = self.pev.origin + self.pev.velocity.Normalize() * 64;
		g_Utility.TraceLine( vecSpot, vecEnd, ignore_monsters, self.edict(), tr );
		
		//_______PUSHING__________
		
		if ( pOther.pev.classname != "monster_sentry" && pOther.pev.classname != "flechette" && !pOther.IsBSPModel() )
		{
			Math.MakeVectors( pevOwner.v_angle );
			pOther.pev.velocity = pOther.pev.velocity - (self.pev.origin - pOther.pev.origin).Normalize() * ( self.pev.dmg * 10 );
		}

		//________________________

		Explode( pOther, tr, DMG_BULLET );
		ProjectileDynamicLight( self.pev.origin, 16, 0, 0, 25, 1, 150 );	
		g_Utility.DecalTrace( tr, DECAL_OFSCORCH3 );

		
		if ( pOther.pev.takedamage == 1 )
		{
			g_WeaponFuncs.ClearMultiDamage();
			pOther.TraceAttack( pevOwner, self.pev.dmg / 8, g_Engine.v_forward , tr, DMG_BULLET ); 
			g_WeaponFuncs.ApplyMultiDamage( self.pev, pevOwner);
		}
	}

	void Explode( CBaseEntity@ pOther, TraceResult pTrace, int bitsDamageType )
	{
		entvars_t@ pevOwner = self.pev.owner.vars;
		
		g_WeaponFuncs.RadiusDamage( self.pev.origin, self.pev, pevOwner, self.pev.dmg * 2 , self.pev.dmg * 2.2, CLASS_NONE, DMG_ENERGYBEAM);
		
		while( ( @pOther = g_EntityFuncs.FindEntityInSphere( pOther, self.pev.origin, self.pev.dmg * 2.2, "*", "classname" ) ) !is null )
		{
			if ( pOther.pev.classname != "monster_sentry" && pOther.pev.classname != "flechette" && !pOther.IsBSPModel() )
			{
				Math.MakeVectors( pevOwner.v_angle );
				pOther.pev.velocity = pOther.pev.velocity - ( self.pev.origin - pOther.pev.origin ).Normalize() * ( self.pev.dmg * 10 );
			}
		}
		
		ProjectileEffect( self.pev.origin );
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, HREPEATER_SOUND_EXPLODEALT, 0.4, ATTN_LOW_HIGH, 0, PITCH_NORM );

		keepRepeatingLight = false;
		self.pev.velocity = g_vecZero;
		SetTouch( null );

		if ( m_pSprite !is null )
			g_EntityFuncs.Remove( m_pSprite );

		g_EntityFuncs.Remove( self );
	}

	void Killed( entvars_t@ pevAttacker, int iGib )
	{
		entvars_t@ pevOwner = self.pev.owner.vars;

		if ( pevOwner !is null && pevOwner.ClassNameIs( "player" ) )
			g_EngineFuncs.SetView( self.pev.owner, self.pev.owner );

		if ( m_pSprite !is null )
			g_EntityFuncs.Remove( m_pSprite );

		g_EntityFuncs.Remove( self );
	}
	
	void UpdateOnRemove()
	{
		if ( m_pSprite !is null )
			g_EntityFuncs.Remove( m_pSprite );
	}

	void ProjectileEffect( Vector origin )
	{
/*		int fireballScale = 3;
		int fireballBrightness = 255;*/
		uint8 smokeScale = 14;
		uint8 discLife = 2;
		uint8 discWidth = 24;
		uint8 discR = 100;
		uint8 discG = 100;
		uint8 discB = 255;
/*		int glowR = 0;
		int glowG = 0;
		int glowB = 255;*/
		uint8 discBrightness = 255;
/*		int glowLife = 1;
		int glowScale = 8;
		int glowBrightness = 25;*/
		
		NetworkMessage projectilexp2( MSG_PVS, NetworkMessages::SVC_TEMPENTITY );
			projectilexp2.WriteByte( TE_SMOKE );
			projectilexp2.WriteCoord( origin.x );
			projectilexp2.WriteCoord( origin.y );
			projectilexp2.WriteCoord( origin.z );
			projectilexp2.WriteShort( m_iSmoke );
			projectilexp2.WriteByte( smokeScale );
			projectilexp2.WriteByte( 24 ); //framrate
		projectilexp2.End();
		
		NetworkMessage projectilexp3( MSG_PVS, NetworkMessages::SVC_TEMPENTITY );
			projectilexp3.WriteByte( TE_BEAMCYLINDER );
			projectilexp3.WriteCoord( origin.x );
			projectilexp3.WriteCoord( origin.y );
			projectilexp3.WriteCoord( origin.z );
			projectilexp3.WriteCoord( origin.x );
			projectilexp3.WriteCoord( origin.y );
			projectilexp3.WriteCoord( origin.z + 320 );
			projectilexp3.WriteShort( m_iSpriteTexture );
			projectilexp3.WriteByte( 0 );
			projectilexp3.WriteByte( 0 );
			projectilexp3.WriteByte( discLife );
			projectilexp3.WriteByte( discWidth );
			projectilexp3.WriteByte( 0 );
			projectilexp3.WriteByte( discR );
			projectilexp3.WriteByte( discG );
			projectilexp3.WriteByte( discB );
			projectilexp3.WriteByte( discBrightness );
			projectilexp3.WriteByte( 0 );
		projectilexp3.End();
		
		NetworkMessage projectilexp5( MSG_PVS, NetworkMessages::SVC_TEMPENTITY );
			projectilexp5.WriteByte( TE_BEAMCYLINDER );
			projectilexp5.WriteCoord( origin.x );
			projectilexp5.WriteCoord( origin.y );
			projectilexp5.WriteCoord( origin.z );
			projectilexp5.WriteCoord( origin.x );
			projectilexp5.WriteCoord( origin.y );
			projectilexp5.WriteCoord( origin.z + 240 );
			projectilexp5.WriteShort( m_iSpriteTexture );
			projectilexp5.WriteByte( 0 );
			projectilexp5.WriteByte( 0 );
			projectilexp5.WriteByte( discLife );
			projectilexp5.WriteByte( discWidth );
			projectilexp5.WriteByte( 0 );
			projectilexp5.WriteByte( discR );
			projectilexp5.WriteByte( discG );
			projectilexp5.WriteByte( discB );
			projectilexp5.WriteByte( discBrightness );
			projectilexp5.WriteByte( 0 );
		projectilexp5.End();	
	}
}

//______________________________________________________________
//______________________________________________________________
//______________________________________________________________
//_____STORMTROOPERBLASTERSHOOT_________________________________

class CBlasterNpc : ScriptBaseEntity
{
	bool keepRepeatingLight = true;
	float m_yawCenter;
	float m_pitchCenter;
	int m_iExplode, m_iSpriteTexture, m_iSpriteTexture2, m_iGlow, m_iSmoke, m_iTrail, m_iBlasterBolt, m_iBlasterImpact;
	CBeam@	m_pBeam;
	
	void Spawn()
	{
		Precache();
		self.pev.movetype = MOVETYPE_FLY;
		self.pev.solid = SOLID_BBOX;
		g_EntityFuncs.SetModel( self, E11_MODEL_PROJECTILE );
		self.pev.body = 1;
		m_yawCenter = pev.angles.y;
		m_pitchCenter = pev.angles.x;
		g_EntityFuncs.SetSize( self.pev, g_vecZero, g_vecZero );
	}
	
	void Precache()
	{
		m_iExplode = g_Game.PrecacheModel( "sprites/starwars/expB1.spr" );
		m_iSpriteTexture = g_Game.PrecacheModel( "sprites/white.spr" );
		m_iSpriteTexture2 = g_Game.PrecacheModel( "sprites/spray.spr" );
		m_iGlow = g_Game.PrecacheModel( "sprites/red.spr" );
		m_iSmoke = g_Game.PrecacheModel( "sprites/steam1.spr" );
		m_iTrail = g_Game.PrecacheModel( "sprites/smoke.spr" );
		m_iBlasterBolt = g_Game.PrecacheModel( "sprites/starwars/blasterboltred.spr" );
		m_iBlasterImpact = g_Game.PrecacheModel( "sprites/starwars/blasterimpact.spr" );	
	}
	
	void BlasterLight()
	{
		if ( m_pBeam !is null )
		{
			g_EntityFuncs.Remove( m_pBeam );
			@m_pBeam = null;
		}
		
		Math.MakeAimVectors( pev.angles );
		
		@m_pBeam = g_EntityFuncs.CreateBeam( "sprites/starwars/blasterboltred.spr", 25 );
		
		if ( m_pBeam !is null )
		{
			m_pBeam.SetStartPos( self.pev.origin + g_Engine.v_forward * 10 );
			m_pBeam.SetEndPos( self.pev.origin - g_Engine.v_forward * 90 );
			m_pBeam.SetColor( 255, 100, 100 );
			m_pBeam.SetScrollRate( 0 );
			m_pBeam.SetBrightness( 255 );
			m_pBeam.pev.velocity = self.pev.velocity;
		}
		
		if ( keepRepeatingLight )
		{
			SetThink( ThinkFunction( this.BlasterLight ) );
			self.pev.nextthink = g_Engine.time + 0.0;
		}
	}

	void ExplodeTouch( CBaseEntity@ pOther )
	{
		entvars_t@ pevOwner = self.pev.owner.vars;

		if ( g_EngineFuncs.PointContents( self.pev.origin ) == CONTENTS_SKY )
		{
			g_EntityFuncs.Remove( self );
			return;
		}

		TraceResult tr;
		Vector vecSpot = self.pev.origin - self.pev.velocity.Normalize() * 32;
		Vector vecEnd = self.pev.origin + self.pev.velocity.Normalize() * 64;
		g_Utility.TraceLine( vecSpot, vecEnd, ignore_monsters, self.edict(), tr );

		Explode( pOther, tr, DMG_ENERGYBEAM );
		
		ProjectileDynamicLight( self.pev.origin, 8, 255, 0, 0, 1, 150 );
		g_Utility.DecalTrace( tr, DECAL_SMALLSCORCH1 );
		
		if ( pOther.pev.takedamage == 1 )
		{
			g_WeaponFuncs.ClearMultiDamage();
			pOther.TraceAttack( pevOwner, self.pev.dmg / 8, g_Engine.v_forward , tr, DMG_BULLET ); 
			g_WeaponFuncs.ApplyMultiDamage( self.pev, pevOwner);
		}
	}

	void Explode( CBaseEntity@ pOther, TraceResult pTrace, int bitsDamageType )
	{
		entvars_t@ pevOwner = self.pev.owner.vars;
		
		int damaged = pOther.TakeDamage(self.pev, pevOwner, self.pev.dmg, DMG_ENERGYBEAM );
		g_WeaponFuncs.RadiusDamage( self.pev.origin, self.pev, pevOwner, self.pev.dmg / 4, self.pev.dmg / 2, CLASS_PLAYER, DMG_ENERGYBEAM);

	//	if ( !pOther.IsPlayer() )
		ProjectileEffect( self.pev.origin );

		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, E11_SOUND_EXPLODE, 0.2, ATTN_LOW_HIGH, 0, PITCH_NORM );

		keepRepeatingLight = false;
		self.pev.velocity = g_vecZero;
		SetTouch( null );
		
		if ( m_pBeam !is null )
			g_EntityFuncs.Remove( m_pBeam );

		g_EntityFuncs.Remove( self );
	}
	
	void Killed( entvars_t@ pevAttacker, int iGib )
	{
		entvars_t@ pevOwner = self.pev.owner.vars;

		if ( pevOwner.ClassNameIs( "player" ) )
		{
			g_EngineFuncs.SetView( self.pev.owner, self.pev.owner );
		}

		if ( m_pBeam !is null )
			g_EntityFuncs.Remove( m_pBeam );

		g_EntityFuncs.Remove( self );
	}
	
	void UpdateOnRemove()
	{
		if ( m_pBeam !is null )
			g_EntityFuncs.Remove( m_pBeam );
	}
	
	void te_sprite( Vector pos, string sprite = "sprites/starwars/blasterimpact.spr", 
		uint8 scale = 1, uint8 alpha = 50, 
		NetworkMessageDest msgType = MSG_BROADCAST, edict_t@ dest = null )
	{
		NetworkMessage m( msgType, NetworkMessages::SVC_TEMPENTITY, dest );
		m.WriteByte( TE_SPRITE );
		m.WriteCoord( pos.x );
		m.WriteCoord( pos.y );
		m.WriteCoord( pos.z );
		m.WriteShort( m_iBlasterImpact > 0 ? m_iBlasterImpact : g_EngineFuncs.ModelIndex( sprite ) );
		m.WriteByte( scale );
		m.WriteByte( alpha );
		m.End();
	}
		
	void te_sparks( Vector pos, 
		NetworkMessageDest msgType = MSG_BROADCAST, edict_t@ dest = null )
	{
		NetworkMessage m( msgType, NetworkMessages::SVC_TEMPENTITY, dest );
		m.WriteByte( TE_SPARKS );
		m.WriteCoord( pos.x );
		m.WriteCoord( pos.y );
		m.WriteCoord( pos.z );
		m.End();
	}

	void te_ricochet( Vector pos, uint8 scale = 10, 
		NetworkMessageDest msgType = MSG_BROADCAST, edict_t@ dest = null )
	{
		NetworkMessage m( msgType, NetworkMessages::SVC_TEMPENTITY, dest );
		m.WriteByte( TE_ARMOR_RICOCHET );
		m.WriteCoord( pos.x );
		m.WriteCoord( pos.y );
		m.WriteCoord( pos.z );
		m.WriteByte( scale );
		m.End();
	}

	void ProjectileEffect( Vector origin )
	{
/*		int fireballScale = 3;
		int fireballBrightness = 255;*/
		uint8 smokeScale = 7;
/*		int discLife = 12;
		int discWidth = 64;
		int discR = 255;
		int discG = 0;
		int discB = 0;
		int glowR = 255;
		int glowG = 0;
		int glowB = 0;
		int discBrightness = 128;
		int glowLife = 1;
		int glowScale = 8;
		int glowBrightness = 25;*/
		
		te_sparks( origin );
		te_sprite( origin );

		// Big Plume of Smoke
		NetworkMessage projectilexp2( MSG_PVS, NetworkMessages::SVC_TEMPENTITY );
			projectilexp2.WriteByte( TE_SMOKE );
			projectilexp2.WriteCoord( origin.x );
			projectilexp2.WriteCoord( origin.y );
			projectilexp2.WriteCoord( origin.z );
			projectilexp2.WriteShort( m_iSmoke );
			projectilexp2.WriteByte( smokeScale );
			projectilexp2.WriteByte( 24 ); //framrate
		projectilexp2.End();
	}
}

//__________________
//__________________
//__________________

CBlaster@ ShootBlaster( entvars_t@ pevOwner, Vector vecStart, Vector vecVelocity )
{
	CBaseEntity@ pEntity = g_EntityFuncs.CreateEntity( "blaster", null, false );
	if ( pEntity is null )
		return null;
	
	CBlaster@ pProjectile = cast<CBlaster@>( CastToScriptClass( pEntity ) );
	if ( pProjectile is null )
		return null;

	g_EntityFuncs.DispatchSpawn( pProjectile.self.edict() );
	g_EntityFuncs.SetOrigin( pProjectile.self, vecStart );
	
	pProjectile.pev.velocity = vecVelocity;
	pProjectile.pev.angles = Math.VecToAngles( pProjectile.pev.velocity );
	@pProjectile.pev.owner = pevOwner.pContainingEntity;
	pProjectile.SetTouch( TouchFunction( pProjectile.ExplodeTouch ) );
	pProjectile.pev.dmg = E11_DAMAGE;
	ProjectileDynamicLight( pProjectile.pev.origin, 6, 255, 0, 0, 5, 50 );
	
	//Effecto aditivo.
	pProjectile.pev.rendermode 	= kRenderTransAdd;
	pProjectile.pev.renderfx 	= kRenderFxNone;
	pProjectile.pev.renderamt 	= 0;
	pProjectile.pev.rendercolor = Vector( 0, 0, 0 );
	
	pProjectile.SetThink( ThinkFunction( pProjectile.BlasterLight ) );
	pProjectile.pev.nextthink = g_Engine.time + 0.02;
		
	return pProjectile;
}

CBlaster@ ShootBlasterPistol( entvars_t@ pevOwner, Vector vecStart, Vector vecVelocity )
{
	CBaseEntity@ pEntity = g_EntityFuncs.CreateEntity( "blaster", null, false );
	if ( pEntity is null )
		return null;

	CBlaster@ pProjectile = cast<CBlaster@>( CastToScriptClass( pEntity ) );
	if ( pProjectile is null )
		return null;

	g_EntityFuncs.DispatchSpawn( pProjectile.self.edict() );
	g_EntityFuncs.SetOrigin( pProjectile.self, vecStart );
	
	pProjectile.pev.velocity = vecVelocity;
	pProjectile.pev.angles = Math.VecToAngles( pProjectile.pev.velocity );
	@pProjectile.pev.owner = pevOwner.pContainingEntity;
	pProjectile.SetTouch( TouchFunction( pProjectile.ExplodeTouch ) );
	pProjectile.pev.dmg = DL44_DAMAGE;
	ProjectileDynamicLight( pProjectile.pev.origin, 6, 255, 0, 0, 5, 50 );
	
	//Effecto aditivo.
	pProjectile.pev.rendermode 	= kRenderTransAdd;
	pProjectile.pev.renderfx 	= kRenderFxNone;
	pProjectile.pev.renderamt 	= 0;
	pProjectile.pev.rendercolor = Vector( 0, 0, 0 );
	
	pProjectile.SetThink( ThinkFunction( pProjectile.BlasterLight ) );
	pProjectile.pev.nextthink = g_Engine.time + 0.02;

	return pProjectile;
}

CBlaster@ ShootBlasterAlt( entvars_t@ pevOwner, Vector vecStart, Vector vecVelocity )
{
	CBaseEntity@ pEntity = g_EntityFuncs.CreateEntity( "blaster", null, false );
	if ( pEntity is null )
		return null;

	CBlaster@ pProjectile = cast<CBlaster@>( CastToScriptClass( pEntity ) );
	if ( pProjectile is null )
		return null;

	g_EntityFuncs.DispatchSpawn( pProjectile.self.edict() );
	g_EntityFuncs.SetOrigin( pProjectile.self, vecStart );
	
	pProjectile.pev.velocity = vecVelocity;
	pProjectile.pev.angles = Math.VecToAngles( pProjectile.pev.velocity );
	@pProjectile.pev.owner = pevOwner.pContainingEntity;
	pProjectile.SetTouch( TouchFunction( pProjectile.ExplodeTouch ) );
	pProjectile.pev.dmg = E11_DAMAGE;
	ProjectileDynamicLight( pProjectile.pev.origin, 6, 255, 0, 0, 5, 50 );
	
	//Effecto aditivo.
	pProjectile.pev.rendermode 	= kRenderTransAdd;
	pProjectile.pev.renderfx 	= kRenderFxNone;
	pProjectile.pev.renderamt 	= 0;
	pProjectile.pev.rendercolor = Vector( 0, 0, 0 );

	pProjectile.SetThink( ThinkFunction( pProjectile.BlasterLight ) );
	pProjectile.pev.nextthink = g_Engine.time + 0.02;

	return pProjectile;
}

CHPBlaster@ ShootBlasterCrossbow1( entvars_t@ pevOwner, Vector vecStart, Vector vecVelocity )
{
	CBaseEntity@ pEntity = g_EntityFuncs.CreateEntity( "HPblaster", null, false );
	if ( pEntity is null )
		return null;

	CHPBlaster@ pProjectile = cast<CHPBlaster@>( CastToScriptClass( pEntity ) );
	if ( pProjectile is null )
		return null;

	g_EntityFuncs.DispatchSpawn( pProjectile.self.edict() );
	g_EntityFuncs.SetOrigin( pProjectile.self, vecStart );
	
	pProjectile.pev.velocity = vecVelocity;
	pProjectile.pev.angles = Math.VecToAngles( pProjectile.pev.velocity );
	@pProjectile.pev.owner = pevOwner.pContainingEntity;
	pProjectile.SetTouch( TouchFunction( pProjectile.ExplodeTouch ) );
	pProjectile.pev.dmg = BOWCASTER_DAMAGE;
	ProjectileDynamicLight( pProjectile.pev.origin, 6, 255, 0, 0, 5, 50 );
	
	//Effecto aditivo.
	pProjectile.pev.rendermode 	= kRenderTransAdd;
	pProjectile.pev.renderfx 	= kRenderFxNone;
	pProjectile.pev.renderamt 	= 0;
	pProjectile.pev.rendercolor = Vector( 0, 0, 0 );
	
	pProjectile.SetThink( ThinkFunction( pProjectile.BlasterLight ) );
	pProjectile.pev.nextthink = g_Engine.time + 0.02;
	
	return pProjectile;
}

CBlaster@ ShootBlasterCrossbow2( entvars_t@ pevOwner, Vector vecStart, Vector vecVelocity )
{
	CBaseEntity@ pEntity = g_EntityFuncs.CreateEntity( "blaster", null, false );
	if ( pEntity is null )
		return null;

	CBlaster@ pProjectile = cast<CBlaster@>( CastToScriptClass( pEntity ) );
	if ( pProjectile is null )
		return null;

	g_EntityFuncs.DispatchSpawn( pProjectile.self.edict() );
	g_EntityFuncs.SetOrigin( pProjectile.self, vecStart );
	
	pProjectile.pev.velocity = vecVelocity;
	pProjectile.pev.angles = Math.VecToAngles( pProjectile.pev.velocity );
	@pProjectile.pev.owner = pevOwner.pContainingEntity;
	pProjectile.SetTouch( TouchFunction( pProjectile.ExplodeTouch ) );
	pProjectile.pev.dmg = BOWCASTER_DAMAGE * 0.3;
	ProjectileDynamicLight( pProjectile.pev.origin, 6, 255, 0, 0, 5, 50 );
	
	//Effecto aditivo.
	pProjectile.pev.rendermode 	= kRenderTransAdd;
	pProjectile.pev.renderfx 	= kRenderFxNone;
	pProjectile.pev.renderamt 	= 0;
	pProjectile.pev.rendercolor = Vector( 0, 0, 0 );
	
	pProjectile.SetThink( ThinkFunction( pProjectile.BlasterLight ) );
	pProjectile.pev.nextthink = g_Engine.time + 0.02;
	
	return pProjectile;
}

CCShoot@ ShootCShoot( entvars_t@ pevOwner, Vector vecStart, Vector vecVelocity )
{
	CBaseEntity@ pEntity = g_EntityFuncs.CreateEntity( "flechetteCShoot", null, false );
	if ( pEntity is null )
		return null;

	CCShoot@ pProjectile = cast<CCShoot@>( CastToScriptClass( pEntity ) );
	if ( pProjectile is null )
		return null;

	g_EntityFuncs.DispatchSpawn( pProjectile.self.edict() );
	g_EntityFuncs.SetOrigin( pProjectile.self, vecStart );
	
	pProjectile.pev.velocity = vecVelocity;
	pProjectile.pev.angles = Math.VecToAngles( pProjectile.pev.velocity );
	@pProjectile.pev.owner = pevOwner.pContainingEntity;
	pProjectile.SetTouch( TouchFunction( pProjectile.ExplodeTouch ) );
	pProjectile.pev.dmg = HREPEATER_DAMAGE * 10;
	ProjectileDynamicLight( pProjectile.pev.origin, 16, 100, 100, 255, 5, 50 );

	//Effecto aditivo.
	pProjectile.pev.rendermode 	= kRenderTransAdd;
	pProjectile.pev.renderfx 	= kRenderFxNone;
	pProjectile.pev.renderamt 	= 0;
	pProjectile.pev.rendercolor = Vector( 0, 0, 0 );
	
	pProjectile.SetThink( ThinkFunction( pProjectile.CShootLight ) );
	pProjectile.pev.nextthink = g_Engine.time + 0.0;
	
	return pProjectile;
}

CHPBlaster@ ShootBlasterT21( entvars_t@ pevOwner, Vector vecStart, Vector vecVelocity )
{
	CBaseEntity@ pEntity = g_EntityFuncs.CreateEntity( "HPblaster", null, false );
	if ( pEntity is null )
		return null;

	CHPBlaster@ pProjectile = cast<CHPBlaster@>( CastToScriptClass( pEntity ) );
	if ( pProjectile is null )
		return null;

	g_EntityFuncs.DispatchSpawn( pProjectile.self.edict() );
	g_EntityFuncs.SetOrigin( pProjectile.self, vecStart );
	
	pProjectile.pev.velocity = vecVelocity;
	pProjectile.pev.angles = Math.VecToAngles( pProjectile.pev.velocity );
	@pProjectile.pev.owner = pevOwner.pContainingEntity;
	pProjectile.SetTouch( TouchFunction( pProjectile.ExplodeTouch ) );
	pProjectile.pev.dmg = T21_DAMAGE;
	ProjectileDynamicLight( pProjectile.pev.origin, 6, 255, 0, 0, 5, 50 );
	
	//Effecto aditivo.
	pProjectile.pev.rendermode 	= kRenderTransAdd;
	pProjectile.pev.renderfx 	= kRenderFxNone;
	pProjectile.pev.renderamt 	= 0;
	pProjectile.pev.rendercolor = Vector( 0, 0, 0 );
	
	pProjectile.SetThink( ThinkFunction( pProjectile.BlasterLight ) );
	pProjectile.pev.nextthink = g_Engine.time + 0.02;
	
	return pProjectile;
}

CBlasterNpc@ ShootBlasterNpc( int damageBlaster, entvars_t@ pevOwner, Vector vecStart, Vector vecVelocity )
{
	CBaseEntity@ pEntity = g_EntityFuncs.CreateEntity( "blasterNpc", null, false );
	if ( pEntity is null )
		return null;

	CBlasterNpc@ pProjectile = cast<CBlasterNpc@>( CastToScriptClass( pEntity ) );
	if ( pProjectile is null )
		return null;

	g_EntityFuncs.DispatchSpawn( pProjectile.self.edict() );
	g_EntityFuncs.SetOrigin( pProjectile.self, vecStart );
	
	pProjectile.pev.velocity = vecVelocity;
	pProjectile.pev.angles = Math.VecToAngles( pProjectile.pev.velocity );
	@pProjectile.pev.owner = pevOwner.pContainingEntity;
	pProjectile.SetTouch( TouchFunction( pProjectile.ExplodeTouch ) );
	pProjectile.pev.dmg = damageBlaster;
	ProjectileDynamicLight( pProjectile.pev.origin, 10, 255, 0, 0, 5, 40 );	
	
	//Effecto aditivo.
	pProjectile.pev.rendermode 	= kRenderTransAdd;
	pProjectile.pev.renderfx 	= kRenderFxNone;
	pProjectile.pev.renderamt 	= 0;
	pProjectile.pev.rendercolor = Vector( 0, 0, 0 );
	
	pProjectile.SetThink( ThinkFunction( pProjectile.BlasterLight ) );
	pProjectile.pev.nextthink = g_Engine.time + 0.03;
	
	return pProjectile;
}

void ProjectileDynamicLight( Vector vecPos, uint8 radius, uint8 r, uint8 g, uint8 b, uint8 life, uint8 decay )
{
	NetworkMessage ndl( MSG_PVS, NetworkMessages::SVC_TEMPENTITY );
		ndl.WriteByte( TE_DLIGHT );
		ndl.WriteCoord( vecPos.x );
		ndl.WriteCoord( vecPos.y );
		ndl.WriteCoord( vecPos.z );
		ndl.WriteByte( radius );
		ndl.WriteByte( r );
		ndl.WriteByte( g );
		ndl.WriteByte( b );
		ndl.WriteByte( life );
		ndl.WriteByte( decay );
	ndl.End();
}

void RegisterBlaster()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "CBlaster", "blaster" );
}

void RegisterHPBlaster()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "CHPBlaster", "HPblaster" );
}

void RegisterCShoot()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "CCShoot", "flechetteCShoot" );
}

void RegisterBlasterNpc()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "CBlasterNpc", "blasterNpc" );
}
