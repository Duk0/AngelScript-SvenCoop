// Afraid of Monsters: Director's Cut Script
// Weapon Script: Hammer
// Author: Zorbos

const float HAMMER_MOD_DAMAGE = 55.0;
const float HAMMER_MOD_ATKSPEED = 1.34;

const float HAMMER_MOD_DAMAGE_SURVIVAL = 41.0; // Reduce damage by 25% on Survival

enum hammer_e
{
	HAMMER_IDLE = 0,
	HAMMER_DRAW,
	HAMMER_HOLSTER,
	HAMMER_ATTACK1HIT,
	HAMMER_ATTACK1MISS,
	HAMMER_ATTACK2MISS,
	HAMMER_ATTACK2HIT,
	HAMMER_ATTACK3MISS,
	HAMMER_ATTACK3HIT
};

class weapon_dchammer : ScriptBasePlayerWeaponEntity
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}
	
	private CScheduledFunction@ m_pPostDropItemSched = null;
	private bool bSurvivalEnabled = g_SurvivalMode.MapSupportEnabled() && g_SurvivalMode.IsEnabled();
	
	bool m_IsPullingBack = false;
	int m_iSwing;
	TraceResult m_trHit;
	
	void Spawn()
	{
		self.Precache();
		g_EntityFuncs.SetModel( self, self.GetW_Model( "models/AoMDC/weapons/hammer/w_dchammer.mdl") );
		self.m_iClip			= -1;
		self.m_flCustomDmg		= self.pev.dmg;

		if ( g_bNoLimitWeapons )
		{
			if ( self.pev.targetname == "weapon_spawn" )
				self.pev.spawnflags = 256; // 256 = USE Only
		}
		else
		{	
			if ( self.pev.targetname == "weapon_give" )
				self.pev.spawnflags = 1024; // 1024 = Never respawn
			else if ( self.pev.targetname == "weapon_dropped" || self.pev.targetname == "weapon_spawn" )
				self.pev.spawnflags = 1280; // 1280 = USE Only + Never respawn
		}
		
		self.FallInit();// get ready to fall down.
		
		// Makes it slightly easier to pickup the gun
		if ( g_bEasyPickup )
			g_EntityFuncs.SetSize( self.pev, Vector( -4, -4, -2 ), Vector( 4, 4, 2 ) );
	}

	void Precache()
	{
		self.PrecacheCustomModels();

		g_Game.PrecacheModel( "models/AoMDC/weapons/hammer/v_dchammer.mdl" );
		g_Game.PrecacheModel( "models/AoMDC/weapons/hammer/w_dchammer.mdl" );
		g_Game.PrecacheModel( "models/AoMDC/weapons/hammer/p_dchammer.mdl" );

		g_SoundSystem.PrecacheSound( "AoMDC/weapons/hammer/hammer_hit.wav" );
		g_SoundSystem.PrecacheSound( "AoMDC/weapons/hammer/hammer_hitbody.wav" );
		g_SoundSystem.PrecacheSound( "AoMDC/weapons/hammer/hammer_miss.wav" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1		= -1;
		info.iMaxAmmo2		= -1;
		info.iMaxClip		= WEAPON_NOCLIP;
		info.iSlot			= 0;
		info.iPosition		= 6;
		info.iWeight		= 0;
		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if ( !BaseClass.AddToPlayer( pPlayer ) )
			return false;

		@m_pPlayer = pPlayer;

		NetworkMessage message( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			message.WriteLong( self.m_iId );
		message.End();

		if ( g_bNoLimitWeapons )
            return true;
		
		// Hack: Recreate the weapon at this exact location to get around the +USE functionality
		// only working on the first pickup whilst still preserving cross-map inventory
		if ( self.pev.targetname == "weapon_spawn" )
		{
			string pOrigin = string( self.pev.origin.x ) + " " +
								  self.pev.origin.y + " " +
								  self.pev.origin.z;
			string pAngles = string( self.pev.angles.x ) + " " +
								  self.pev.angles.y + " " +
								  self.pev.angles.z;
			dictionary@ pValues = {{"origin", pOrigin}, {"angles", pAngles},{"spawnflags", "1024"}, {"targetname", "weapon_spawn"}};
			g_EntityFuncs.CreateEntity( self.GetClassname(), @pValues, true );
		}

		self.pev.targetname = string_t(); // Reset the targetname as this weapon is no longer "dropped"
		self.pev.netname = string_t(); // Reset the owner
		
		DeleteNearbyDuplicatesByOwner();
		
		// Can only have one weapon of this category at a time
		CBasePlayerItem@ pItem1 = pPlayer.HasNamedPlayerItem( "weapon_dcknife" );
		CBasePlayerItem@ pItem2 = pPlayer.HasNamedPlayerItem( "weapon_dcaxe" );
		
		if ( pItem1 !is null ) // Player has a weapon in this category already
		{
			m_pPlayer.RemovePlayerItem( pItem1 ); // Remove the existing weapon first
			ThrowWeapon( cast<CBasePlayerWeapon@>( pItem1 ), true ); // .. then spawn a new one
		}
			
		if ( pItem2 !is null ) // Player has a weapon in this category already
		{
			m_pPlayer.RemovePlayerItem(pItem2); // Remove the existing weapon first
			ThrowWeapon( cast<CBasePlayerWeapon@>( pItem2 ), true ); // .. then spawn a new one
		}
		
		m_pPlayer.SwitchWeapon( self );

		return true;
	}
	
	bool Deploy()
	{
		return self.DefaultDeploy( self.GetV_Model( "models/AoMDC/weapons/hammer/v_dchammer.mdl" ), self.GetP_Model( "models/AoMDC/weapons/hammer/p_dchammer.mdl" ), HAMMER_ATTACK1HIT, "crowbar" );
	}
	
	void Holster( int skiplocal /* = 0 */ )
	{
		self.m_fInReload = false;// cancel any reload in progress.
		m_pPlayer.m_flNextAttack = g_WeaponFuncs.WeaponTimeBase() + 1.30;

		// Fix for the SendWeaponAnim crash
		SetThink( null );

		if ( g_bNoLimitWeapons )
            return;
		
		if ( m_pPostDropItemSched !is null )
			g_Scheduler.RemoveTimer( m_pPostDropItemSched );
		
		@m_pPostDropItemSched = g_Scheduler.SetTimeout( @this, "PostDropItem", 0.1 );
	}

	// Finds nearby dropped weapons that this player owns and removes them
	// Prevents spam by collecting the weapon over and over.
	void DeleteNearbyDuplicatesByOwner()
	{
		string m_iszOwnerId = g_EngineFuncs.GetPlayerAuthId( m_pPlayer.edict() );
		
		 // Find nearby dropped weapons of the same classname as this one, owned by the same player who owns this one
		CBaseEntity@ pDuplicate = g_EntityFuncs.FindEntityByString( null, "netname", m_iszOwnerId );

		if ( pDuplicate !is null && pDuplicate.GetClassname() == self.GetClassname() )
			g_EntityFuncs.Remove( pDuplicate );
	}
	
	// Creates a new weapon of the given type and "throws" it forward
	void ThrowWeapon(CBasePlayerWeapon@ pWeapon, bool bWasSwapped)
	{
		// Get player origin
		string plrOrigin = string( m_pPlayer.pev.origin.x ) + " " +
							    m_pPlayer.pev.origin.y + " " +
							    ( m_pPlayer.pev.origin.z + 20.0 );
								
		// Get player angles
		string plrAngleCompY;
		
		// Different weapons need to be thrown out at different angles so that they face the player.
		if ( pWeapon.GetClassname() == "weapon_dcknife" )
			plrAngleCompY = m_pPlayer.pev.angles.y + 85.0;
		else if ( pWeapon.GetClassname() == "weapon_dcaxe" )
			plrAngleCompY = m_pPlayer.pev.angles.y - 85.0;
		else
			plrAngleCompY = m_pPlayer.pev.angles.y - 90.0;
		
		string plrAngles = string( m_pPlayer.pev.angles.x ) + " " +
							    plrAngleCompY + " " +
							    m_pPlayer.pev.angles.z;
								
		// Spawnflags 1280 = USE Only + Never respawn
		dictionary@ pValues = {{"origin", plrOrigin}, {"angles", plrAngles}, {"targetname", "weapon_dropped"}, {"netname", ""}};
		
		if ( bWasSwapped )
			pValues.set( "netname", g_EngineFuncs.GetPlayerAuthId( m_pPlayer.edict() ) ); // The owner's STEAMID
		
		// Create the new item and "throw" it forward
		CBaseEntity@ pNew = g_EntityFuncs.CreateEntity( pWeapon.GetClassname(), @pValues, true );
		
		if ( pNew !is null )
            pNew.pev.velocity = g_Engine.v_forward * 200 + g_Engine.v_up * 125;
		
		m_pPlayer.SetItemPickupTimes(0);
	}
	
	// Handles the case in which this weapon is thrown VOLUNTARILY by the player or the player dies
	void PostDropItem()
	{
		if ( self is null || !g_EntityFuncs.IsValidEntity( self.pev.owner ) )
			return;

		CBaseEntity@ pWeaponbox = g_EntityFuncs.Instance( self.pev.owner ); // The 'actual' thrown weapon
		
		if ( pWeaponbox is null ) // Failsafe(s)
			return;

		if ( !pWeaponbox.pev.ClassNameIs( "weaponbox" ) )
			return;
		
		// Remove the 'actual' dropped weapon..
		g_EntityFuncs.Remove( pWeaponbox );
		
		CBasePlayerWeapon@ pWeapon = self;

        if ( pWeapon is null )
            return;
		
		// Spawn a new copy and "throw" it forward
		ThrowWeapon( pWeapon, false );
	}  
	
	void PrimaryAttack()
	{
		if( !m_IsPullingBack )
		{
			// We don't want the player to break/stop the animation or sequence.
			m_IsPullingBack = true;

			// We are pulling back our hammer
			self.SendWeaponAnim( HAMMER_ATTACK2MISS, 0, 0 );

			// Lets wait for the 'heavy smack'
			SetThink( ThinkFunction( this.DoHeavyAttack ) );
			self.pev.nextthink = g_Engine.time + 0.40;
		}
	}

	void NoPulling()
	{
		// We are no longer pulling back
		m_IsPullingBack = false;
	}

	void DoHeavyAttack()
	{
		HeavySmack();
	}
  
	void Smack()
	{
		g_WeaponFuncs.DecalGunshot( m_trHit, BULLET_PLAYER_CROWBAR );
	}
  
	bool HeavySmack()
	{
		TraceResult tr;

		bool fDidHit = false;
		float flDamage;

		Math.MakeVectors( m_pPlayer.pev.v_angle );
		Vector vecSrc  = m_pPlayer.GetGunPosition();
		Vector vecEnd  = vecSrc + g_Engine.v_forward * 32;

		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );

		if ( tr.flFraction >= 1.0 )
		{
			g_Utility.TraceHull( vecSrc, vecEnd, dont_ignore_monsters, head_hull, m_pPlayer.edict(), tr );
			if ( tr.flFraction < 1.0 )
			{
				// Calculate the point of intersection of the line (or hull) and the object we hit
				// This is and approximation of the "best" intersection
				if ( tr.pHit !is null )
				{
					CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
					if ( pHit is null || pHit.IsBSPModel() )
						g_Utility.FindHullIntersection( vecSrc, tr, tr, VEC_DUCK_HULL_MIN, VEC_DUCK_HULL_MAX, m_pPlayer.edict() );
				}
				vecEnd = tr.vecEndPos;  // This is the point on the actual surface (the hull could have hit space)
			}

			self.m_flNextPrimaryAttack = g_Engine.time + HAMMER_MOD_ATKSPEED;

			// play wiff or swish sound
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "AoMDC/weapons/hammer/hammer_miss.wav", 1, ATTN_NORM, 0, 94 + Math.RandomLong( 0,0xF ) );

			// player "shoot" animation
			m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		}
		else
		{
			// hit
			fDidHit = true;

			CBaseEntity@ pEntity = null;
			
			if ( tr.pHit !is null )
				@pEntity = g_EntityFuncs.Instance( tr.pHit );

			// player "shoot" animation
			m_pPlayer.SetAnimation( PLAYER_ATTACK1 ); 

			// AdamR: Custom damage option
			if ( bSurvivalEnabled)
				flDamage = HAMMER_MOD_DAMAGE_SURVIVAL;
			else
				flDamage = HAMMER_MOD_DAMAGE;
				
			if ( self.m_flCustomDmg > 0 )
				flDamage = self.m_flCustomDmg;
			// AdamR: End

			g_WeaponFuncs.ClearMultiDamage();

			if ( pEntity !is null )
			{
				if ( self.m_flNextPrimaryAttack + 1 < g_Engine.time )
				{
					// first swing does full damage
					pEntity.TraceAttack( m_pPlayer.pev, flDamage, g_Engine.v_forward, tr, DMG_CLUB );  
				}
				else
				{
					// subsequent swings do 50% (Changed -Sniper) (Half)
					pEntity.TraceAttack( m_pPlayer.pev, flDamage * 1.0, g_Engine.v_forward, tr, DMG_CLUB );  
				}
			}

			g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );

			//m_flNextPrimaryAttack = gpGlobals->time + 0.30; //0.25

			// play thwack, smack, or dong sound
			float flVol = 1.0;
			bool fHitWorld = true;

			if ( pEntity !is null )
			{
				self.m_flNextPrimaryAttack = g_Engine.time + HAMMER_MOD_ATKSPEED; //0.25

				if ( pEntity.Classify() != CLASS_NONE && pEntity.Classify() != CLASS_MACHINE && pEntity.BloodColor() != DONT_BLEED )
				{
					if ( pEntity.IsPlayer() )    // lets pull them
					{
						pEntity.pev.velocity = pEntity.pev.velocity + ( self.pev.origin - pEntity.pev.origin ).Normalize() * 120;
					}
					
					// play thwack or smack sound
					g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "AoMDC/weapons/hammer/hammer_hitbody.wav", 1, ATTN_NORM );
					g_PlayerFuncs.ScreenShake(m_pPlayer.pev.origin, 3.0, 10.0, 0.5, 1.0);
					
					m_pPlayer.m_iWeaponVolume = 128;

					if ( !pEntity.IsAlive() )
					{
						SetThink( ThinkFunction( this.NoPulling ) );
						self.pev.nextthink = g_Engine.time + 1.2;
						return true;
					}
					else
						flVol = 0.1;

					fHitWorld = false;
				}
			}

			// play texture hit sound
			// UNDONE: Calculate the correct point of intersection when we hit with the hull instead of the line

			if ( fHitWorld )
			{
				float fvolbar = g_SoundSystem.PlayHitSound( tr, vecSrc, vecSrc + ( vecEnd - vecSrc ) * 2, BULLET_PLAYER_CROWBAR );
				
				self.m_flNextPrimaryAttack = g_Engine.time + HAMMER_MOD_ATKSPEED; //0.25
			
				// override the volume here, cause we don't play texture sounds in multiplayer, 
				// and fvolbar is going to be 0 from the above call.

				fvolbar = 1;

				// also play crowbar strike
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "AoMDC/weapons/hammer/hammer_hit.wav", fvolbar, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) );
			}

			// delay the decal a bit
			m_trHit = tr;
			SetThink( ThinkFunction( this.Smack ) );
			self.pev.nextthink = g_Engine.time + 0.5;

			m_pPlayer.m_iWeaponVolume = int( flVol * 512 ); 
		}

		// Lets wait until we can attack again
		SetThink( ThinkFunction( this.NoPulling ) );
		self.pev.nextthink = g_Engine.time + HAMMER_MOD_ATKSPEED;
	
		return fDidHit;
	}
}

string GetDCHammerName()
{
	return "weapon_dchammer";
}

void RegisterDCHammer()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_dchammer", GetDCHammerName() );
	g_ItemRegistry.RegisterWeapon( GetDCHammerName(), "AoMDC" );
}
