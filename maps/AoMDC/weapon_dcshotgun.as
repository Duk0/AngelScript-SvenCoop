// Afraid of Monsters: Director's Cut Script
// Weapon Script: Shotgun
// Author: Zorbos

// special deathmatch shotgun spreads
const Vector VECTOR_CONE_DM_SHOTGUN( 0.08716, 0.04362, 0.00  );		// 10 degrees by 5 degrees
const Vector VECTOR_CONE_DM_DOUBLESHOTGUN( 0.17365, 0.04362, 0.00 ); 	// 20 degrees by 5 degrees

const float SHOTGUN_MOD_DAMAGE = 18.0;
const float SHOTGUN_MOD_FIRERATE = 1.15;

const float SHOTGUN_MOD_DAMAGE_SURVIVAL = 13.0; // Reduce damage by 25% on Survival

const int SHOTGUN_DEFAULT_AMMO = 8;
const int SHOTGUN_MAX_CARRY 	= 32;
const int SHOTGUN_MAX_CLIP 	= 8;
const int SHOTGUN_WEIGHT 		= 15;

const uint SHOTGUN_SINGLE_PELLETCOUNT = 8;
const uint SHOTGUN_DOUBLE_PELLETCOUNT = SHOTGUN_SINGLE_PELLETCOUNT * 2;

enum ShotgunAnimation
{
	SHOTGUN_IDLE = 0,
	SHOTGUN_FIRE,
	SHOTGUN_FIRE2,
	SHOTGUN_RELOAD,
	SHOTGUN_PUMP,
	SHOTGUN_START_RELOAD,
	SHOTGUN_DRAW,
	SHOTGUN_HOLSTER,
	SHOTGUN_IDLE4,
	SHOTGUN_IDLE_DEEP
};

class weapon_dcshotgun : ScriptBasePlayerWeaponEntity
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}
	
	private CScheduledFunction@ m_pPostDropItemSched = null;
	private bool bSurvivalEnabled = g_SurvivalMode.MapSupportEnabled() && g_SurvivalMode.IsEnabled();
	
	float m_flNextReload;
	int m_iShell;
	int iShellModelIndex;
	float m_flPumpTime;
	bool m_fPlayPumpSound;
	bool m_fShotgunReload;
	bool bIsFiring = false;

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, "models/AoMDC/weapons/shotgun/w_dcshotgun.mdl" );

		if ( g_bNoLimitWeapons )
		{
			if ( self.pev.targetname == "weapon_spawn" )
				self.pev.spawnflags = 256; // 256 = USE Only

			self.m_iDefaultAmmo = SHOTGUN_DEFAULT_AMMO;
		}
		else
		{	
			if ( self.pev.targetname == "weapon_give" )
				self.pev.spawnflags = 1024; // 1024 = Never respawn
			else if ( self.pev.targetname == "weapon_dropped" || self.pev.targetname == "weapon_spawn" )
				self.pev.spawnflags = 1280; // 1280 = USE Only + Never respawn
			
			if ( self.pev.targetname == "weapon_dropped" )
				self.m_iDefaultAmmo = self.m_iClip;
			else
				self.m_iDefaultAmmo = SHOTGUN_DEFAULT_AMMO;
		}

		self.FallInit();// get ready to fall
		
		// Makes it slightly easier to pickup the gun
		if ( g_bEasyPickup )
			g_EntityFuncs.SetSize( self.pev, Vector( -4, -4, -2 ), Vector( 4, 4, 2 ) );
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( "models/AoMDC/weapons/shotgun/v_dcshotgun.mdl" );
		g_Game.PrecacheModel( "models/AoMDC/weapons/shotgun/w_dcshotgun.mdl" );
		g_Game.PrecacheModel( "models/AoMDC/weapons/shotgun/p_dcshotgun.mdl" );

		m_iShell = g_Game.PrecacheModel( "models/shotgunshell.mdl" );// shotgun shell

		g_SoundSystem.PrecacheSound( "AoMDC/weapons/shotgun/shotgun_fire.wav" ); //shotgun reload
		g_SoundSystem.PrecacheSound( "AoMDC/weapons/shotgun/shotgun_insert.wav" );	// shotgun reload

		g_SoundSystem.PrecacheSound( "AoMDC/weapons/shotgun/sshell1.wav" );	// shotgun reload
		g_SoundSystem.PrecacheSound( "AoMDC/weapons/shotgun/sshell2.wav" );	// shotgun reload
		g_SoundSystem.PrecacheSound( "AoMDC/weapons/shotgun/sshell3.wav" );	// shotgun reload
		
		g_SoundSystem.PrecacheSound( "weapons/dryfire.wav" ); // gun empty sound
		g_SoundSystem.PrecacheSound( "AoMDC/weapons/shotgun/shotgun_pump.wav" );	// cock gun
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
			dictionary@ pValues = {{"origin", pOrigin}, {"angles", pAngles}, {"spawnflags", "1024"}, {"targetname", "weapon_spawn"}};
			g_EntityFuncs.CreateEntity( self.GetClassname(), @pValues, true );
		}
		

		self.pev.targetname = string_t(); // Reset the targetname as this weapon is no longer "dropped"
		self.pev.globalname = string_t(); // Reset the owner
		
		int m_iDuplicateClip = DeleteNearbyDuplicatesByOwner();
		
		if ( m_iDuplicateClip >= 0 )
			self.m_iClip = m_iDuplicateClip;
		
		// Can only have one weapon of this category at a time
		CBasePlayerItem@ pItem1 = pPlayer.HasNamedPlayerItem( "weapon_dcuzi" );
		CBasePlayerItem@ pItem2 = pPlayer.HasNamedPlayerItem( "weapon_dcmp5k" );
		
		if ( pItem1 !is null ) // Player has a weapon in this category already
		{
			m_pPlayer.RemovePlayerItem( pItem1 ); // Remove the existing weapon first
			ThrowWeapon( cast<CBasePlayerWeapon@>( pItem1 ), true ); // .. then spawn a new one
		}
			
		if ( pItem2 !is null ) // Player has a weapon in this category already
		{
			m_pPlayer.RemovePlayerItem( pItem2 ); // Remove the existing weapon first
			ThrowWeapon( cast<CBasePlayerWeapon@>( pItem2 ), true ); // .. then spawn a new one
		}
		
		m_pPlayer.SwitchWeapon( self );
		
		return true;
	}

	// Finds nearby dropped weapons that this player owns and removes them
	// Prevents spam by collecting the weapon over and over.
	int DeleteNearbyDuplicatesByOwner()
	{
		int m_iDuplicateClip = 0;
		string m_iszOwnerId = g_EngineFuncs.GetPlayerAuthId( m_pPlayer.edict() );
		
		 // Find nearby dropped weapons of the same classname as this one, owned by the same player who owns this one
		CBaseEntity@ pDuplicate = g_EntityFuncs.FindEntityByString( null, "globalname", m_iszOwnerId );

		if ( pDuplicate !is null && pDuplicate.GetClassname() == self.GetClassname() )
		{
			CBasePlayerWeapon@ pWeapon = cast<CBasePlayerWeapon@>( pDuplicate );

            if ( pWeapon !is null )
                m_iDuplicateClip = pWeapon.m_iClip; // Save the current clip to import into the next weapon

			g_EntityFuncs.Remove( pDuplicate );
			
			return m_iDuplicateClip;
		}
		
		return -1; // No duplicate weapons found
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= SHOTGUN_MAX_CARRY;
		info.iAmmo1Drop	= SHOTGUN_MAX_CLIP;
		info.iMaxAmmo2 	= -1;
		info.iAmmo2Drop	= -1;
		info.iMaxClip 	= SHOTGUN_MAX_CLIP;
		info.iSlot 		= 2;
		info.iPosition 	= 9;
		info.iFlags 	= 0;
		info.iWeight 	= SHOTGUN_WEIGHT;

		return true;
	}

	// Creates a new weapon of the given type and "throws" it forward
	void ThrowWeapon( CBasePlayerWeapon@ pWeapon, bool bWasSwapped )
	{
		// Get player origin		
		string plrOrigin = string( m_pPlayer.pev.origin.x ) + " " +
							    m_pPlayer.pev.origin.y + " " +
							    ( m_pPlayer.pev.origin.z + 20.0 );
								
		// Get player angles
		string plrAngleCompY;
		
		// Different weapons need to be thrown out at different angles so that they face the player.
		if ( pWeapon.GetClassname() == "weapon_dcuzi" )
			plrAngleCompY = m_pPlayer.pev.angles.y;
		else if ( pWeapon.GetClassname() == "weapon_dcmp5k" )
			plrAngleCompY = m_pPlayer.pev.angles.y + 90.0;
		else
			plrAngleCompY = m_pPlayer.pev.angles.y + 145.0;
		
		string plrAngles = string( m_pPlayer.pev.angles.x ) + " " +
							    plrAngleCompY + " " +
							    m_pPlayer.pev.angles.z;
								
		// Spawnflags 1280 = USE Only + Never respawn
		dictionary@ pValues = {{"origin", plrOrigin}, {"angles", plrAngles}, {"targetname", "weapon_dropped"}, {"globalname", ""}};
		
		if ( bWasSwapped )
			pValues.set( "globalname", g_EngineFuncs.GetPlayerAuthId( m_pPlayer.edict() ) ); // The owner's STEAMID
		
		// Create the new item and "throw" it forward
		CBasePlayerWeapon@ pNew = cast<CBasePlayerWeapon@>( g_EntityFuncs.CreateEntity(pWeapon.GetClassname(), @pValues, true) );
		
		if ( pWeapon.GetClassname() == self.GetClassname() ) // We're dropping THIS weapon
		{
            if ( pNew !is null )
                pNew.m_iClip = self.m_iClip; // Remember how many bullets are in the magazine

			m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) * 2 ); // Stop ammo stacking
		}
		else // We're dropping a different weapon. Preserve it's current magazine state
		{
            if ( pNew !is null )
                pNew.m_iClip = pWeapon.m_iClip;
		}
		
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
	
	bool Deploy()
	{
		return self.DefaultDeploy( self.GetV_Model( "models/AoMDC/weapons/shotgun/v_dcshotgun.mdl" ), self.GetP_Model( "models/AoMDC/weapons/shotgun/p_dcshotgun.mdl" ), SHOTGUN_DRAW, "shotgun" );
	}
	
	void Holster( int skipLocal = 0 )
	{
		m_fShotgunReload = false;
		bIsFiring = false;		
		BaseClass.Holster( skipLocal );

		if ( g_bNoLimitWeapons )
            return;
		
		if ( m_pPostDropItemSched !is null )
			g_Scheduler.RemoveTimer( m_pPostDropItemSched );
		
		@m_pPostDropItemSched = g_Scheduler.SetTimeout( @this, "PostDropItem", 0.1 );
	}

	void ItemPostFrame()
	{
		if ( m_flPumpTime != 0 && m_flPumpTime < g_Engine.time && m_fPlayPumpSound )
		{
			// play pumping sound
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, "AoMDC/weapons/shotgun/shotgun_pump.wav", 1, ATTN_NORM, 0, 85 + Math.RandomLong( 0,0x1f ) );

			m_fPlayPumpSound = false;
		}

		BaseClass.ItemPostFrame();
	}
	
	void CreatePelletDecals( const Vector& in vecSrc, const Vector& in vecAiming, const Vector& in vecSpread, const uint uiPelletCount )
	{
		TraceResult tr;
		
		float x, y;
		
		for ( uint uiPellet = 0; uiPellet < uiPelletCount; ++uiPellet )
		{
			g_Utility.GetCircularGaussianSpread( x, y );
			
			Vector vecDir = vecAiming 
							+ x * vecSpread.x * g_Engine.v_right 
							+ y * vecSpread.y * g_Engine.v_up;

			Vector vecEnd	= vecSrc + vecDir * 2048;
			
			g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );
			
			if ( tr.flFraction < 1.0 )
			{
				if ( tr.pHit !is null )
				{
					CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
					
					if ( pHit is null || pHit.IsBSPModel() )
						g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_BUCKSHOT );
				}
			}
		}
	}

	void PrimaryAttack()
	{
		int m_iBulletDamage;
		
		if ( bIsFiring )
			return;
			
		if ( !bIsFiring )
			bIsFiring = true;
			
		// don't fire underwater
		if ( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
		{
			self.m_flNextPrimaryAttack = g_Engine.time + 0.15;
			return;
		}

		if ( self.m_iClip <= 0 )
		{
			self.m_flNextPrimaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 0.75;
			self.Reload();
			return;
		}

		self.SendWeaponAnim( SHOTGUN_FIRE, 0, 0 );
		
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "AoMDC/weapons/shotgun/shotgun_fire.wav", Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0x1f ) );
		
		m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;

		--self.m_iClip;

		// player "shoot" animation
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		Vector vecSrc	 = m_pPlayer.GetGunPosition();
		Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

		if ( bSurvivalEnabled )
			m_iBulletDamage = SHOTGUN_MOD_DAMAGE_SURVIVAL;
		else
			m_iBulletDamage = SHOTGUN_MOD_DAMAGE;

		m_pPlayer.FireBullets( 4, vecSrc, vecAiming, VECTOR_CONE_DM_SHOTGUN, 2048, BULLET_PLAYER_CUSTOMDAMAGE, 0, m_iBulletDamage );

		if ( self.m_iClip != 0 )
			m_flPumpTime = g_Engine.time + 0.5;
			
		NetworkMessage mFlash(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY);
			mFlash.WriteByte(TE_DLIGHT);
			mFlash.WriteCoord(m_pPlayer.GetGunPosition().x);
			mFlash.WriteCoord(m_pPlayer.GetGunPosition().y);
			mFlash.WriteCoord(m_pPlayer.GetGunPosition().z);
			mFlash.WriteByte(14); // Radius
			mFlash.WriteByte(255); // R
			mFlash.WriteByte(255); // G
			mFlash.WriteByte(204); // B
			mFlash.WriteByte(1); // Lifetime
			mFlash.WriteByte(1); // Decay
		mFlash.End();

		self.m_flNextPrimaryAttack = g_Engine.time + SHOTGUN_MOD_FIRERATE;

		if ( self.m_iClip != 0 )
			self.m_flTimeWeaponIdle = g_Engine.time + SHOTGUN_MOD_FIRERATE;
		else
			self.m_flNextPrimaryAttack = self.m_flTimeWeaponIdle = SHOTGUN_MOD_FIRERATE;

		m_fShotgunReload = false;
		m_fPlayPumpSound = true;
		
		CreatePelletDecals( vecSrc, vecAiming, VECTOR_CONE_DM_SHOTGUN, SHOTGUN_SINGLE_PELLETCOUNT );
		
		SetThink( ThinkFunction( this.EjectShell ) ); // Delay the shell ejection a bit
		self.pev.nextthink = g_Engine.time + 0.6;
	}
	
	void EjectShell()
	{
		if ( m_pPlayer is null )
			return;

		iShellModelIndex = g_EngineFuncs.ModelIndex( "models/shotgunshell.mdl" );
		Vector shellOrigin = m_pPlayer.GetGunPosition() + g_Engine.v_right * 10.0 + g_Engine.v_forward * 20.0 + g_Engine.v_up * -15.0;
		Vector shellDir = g_Engine.v_right * Math.RandomFloat(30.0, 80.0) + g_Engine.v_up * Math.RandomFloat(10.0, 40.0) + g_Engine.v_forward * Math.RandomFloat(-20.0, 20.0);
		
		g_EntityFuncs.EjectBrass( shellOrigin, shellDir, 0.0f, iShellModelIndex, TE_BOUNCE_SHOTSHELL );
	}

	void Reload()
	{
		if ( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 || self.m_iClip == SHOTGUN_MAX_CLIP )
			return;

		if ( m_flNextReload > g_Engine.time )
			return;

		// don't reload until recoil is done
		if ( self.m_flNextPrimaryAttack > g_Engine.time && !m_fShotgunReload )
			return;

		// check to see if we're ready to reload
		if ( !m_fShotgunReload )
		{
			self.SendWeaponAnim( SHOTGUN_START_RELOAD, 0, 0 );
			m_pPlayer.m_flNextAttack 	= 0.6;	//Always uses a relative time due to prediction
			self.m_flTimeWeaponIdle			= g_Engine.time + 0.6;
			self.m_flNextPrimaryAttack 		= g_Engine.time + 1.0;
			self.m_flNextSecondaryAttack	= g_Engine.time + 1.0;
			m_fShotgunReload = true;
			return;
		}
		else if ( m_fShotgunReload )
		{
			if ( self.m_flTimeWeaponIdle > g_Engine.time )
				return;

			if ( self.m_iClip == SHOTGUN_MAX_CLIP )
			{
				m_fShotgunReload = false;
				return;
			}

			self.SendWeaponAnim( SHOTGUN_RELOAD, 0 );
			m_flNextReload 					= g_Engine.time + 0.5;
			self.m_flNextPrimaryAttack 		= g_Engine.time + 0.5;
			self.m_flNextSecondaryAttack 	= g_Engine.time + 0.5;
			self.m_flTimeWeaponIdle 		= g_Engine.time + 0.5;
				
			// Add them to the clip
			self.m_iClip += 1;
			m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );
			
			switch ( Math.RandomLong( 0, 1 ) )
			{
			case 0:
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, "AoMDC/weapons/shotgun/shotgun_insert.wav", 1, ATTN_NORM, 0, 85 + Math.RandomLong( 0, 0x1f ) );
				break;
			case 1:
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, "AoMDC/weapons/shotgun/shotgun_insert.wav", 1, ATTN_NORM, 0, 85 + Math.RandomLong( 0, 0x1f ) );
				break;
			}
		}

		BaseClass.Reload();
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();
		bIsFiring = false;
		m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

		if( self.m_flTimeWeaponIdle < g_Engine.time )
		{
			if( self.m_iClip == 0 && !m_fShotgunReload && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) != 0 )
			{
				self.Reload();
			}
			else if( m_fShotgunReload )
			{
				if( self.m_iClip != SHOTGUN_MAX_CLIP && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) > 0 )
				{
					self.Reload();
				}
				else
				{
					// reload debounce has timed out
					self.SendWeaponAnim( SHOTGUN_PUMP, 0, 0 );

					g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, "AoMDC/weapons/shotgun/shotgun_pump.wav", 1, ATTN_NORM, 0, 85 + Math.RandomLong( 0,0x1f ) );
					m_fShotgunReload = false;
					self.m_flTimeWeaponIdle = g_Engine.time + 1.0;
				}
			}
			else
			{
				int iAnim;
				float flRand = g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 0, 1 );
				if( flRand <= 0.8 )
				{
					iAnim = SHOTGUN_IDLE_DEEP;
					self.m_flTimeWeaponIdle = g_Engine.time + (60.0/12.0);// * RANDOM_LONG(2, 5);
				}
				else if( flRand <= 0.95 )
				{
					iAnim = SHOTGUN_IDLE;
					self.m_flTimeWeaponIdle = g_Engine.time + (20.0/9.0);
				}
				else
				{
					iAnim = SHOTGUN_IDLE4;
					self.m_flTimeWeaponIdle = g_Engine.time+ (20.0/9.0);
				}
				self.SendWeaponAnim( iAnim, 1, 0 );
			}
		}
	}
}

string GetDCShotgunName()
{
	return "weapon_dcshotgun";
}

void RegisterDCShotgun()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_dcshotgun", GetDCShotgunName() );
	g_ItemRegistry.RegisterWeapon( GetDCShotgunName(), "AoMDC", "buckshot", "", "ammo_dcshotgun" );
}
