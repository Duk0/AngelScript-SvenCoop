// Afraid of Monsters: Director's Cut Script
// Weapon Script: Uzi
// Author: Zorbos

const float UZI_MOD_DAMAGE = 15.0;
const float UZI_MOD_FIRERATE = 0.08;

const float UZI_MOD_DAMAGE_SURVIVAL = 11.0; // Reduce damage by 25% on Survival

enum UziAnimation
{
	UZI_LONGIDLE = 0,
	UZI_IDLE1,
	UZI_LAUNCH,
	UZI_RELOAD,
	UZI_DEPLOY,
	UZI_FIRE1,
	UZI_FIRE2,
	UZI_FIRE3,
};

const int UZI_DEFAULT_AMMO 	= 25;
const int UZI_MAX_AMMO		= 120;
const int UZI_MAX_AMMO2 	= -1;
const int UZI_MAX_CLIP 		= 25;
const int UZI_WEIGHT 		= 5;

class weapon_dcuzi : ScriptBasePlayerWeaponEntity
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}
	
	private CScheduledFunction@ m_pPostDropItemSched = null;
	private bool bSurvivalEnabled = g_SurvivalMode.MapSupportEnabled() && g_SurvivalMode.IsEnabled();
	
	float m_flNextAnimTime;
	int m_iShell;
	int iShellModelIndex;
	int	m_iSecondaryAmmo;
	
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, "models/AoMDC/weapons/uzi/w_dcuzi.mdl" );

		if ( g_bNoLimitWeapons )
		{
			if ( self.pev.targetname == "weapon_spawn" )
				self.pev.spawnflags = 256; // 256 = USE Only

			self.m_iDefaultAmmo = UZI_DEFAULT_AMMO;
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
				self.m_iDefaultAmmo = UZI_DEFAULT_AMMO;
		}

		self.m_iSecondaryAmmoType = 0;
		self.FallInit();
		
		// Makes it slightly easier to pickup the gun
		if ( g_bEasyPickup )
			g_EntityFuncs.SetSize( self.pev, Vector( -4, -4, -2 ), Vector( 4, 4, 2 ) );
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( "models/AoMDC/weapons/uzi/v_dcuzi.mdl" );
		g_Game.PrecacheModel( "models/AoMDC/weapons/uzi/w_dcuzi.mdl" );
		g_Game.PrecacheModel( "models/AoMDC/weapons/uzi/p_dcuzi.mdl" );

		m_iShell = g_Game.PrecacheModel( "models/shell.mdl" );             

		//These are played by the model, needs changing there
		g_SoundSystem.PrecacheSound( "AoMDC/weapons/uzi/uzi_boltpull.wav" );
		g_SoundSystem.PrecacheSound( "AoMDC/weapons/uzi/uzi_fire.wav" );
		g_SoundSystem.PrecacheSound( "AoMDC/weapons/uzi/uzi_magin.wav" );
		g_SoundSystem.PrecacheSound( "AoMDC/weapons/uzi/uzi_magout.wav" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= UZI_MAX_AMMO;
		info.iAmmo1Drop	= MP5_MAX_CLIP; // = 30, UZI_MAX_CLIP
		info.iMaxAmmo2 	= -1;
		info.iAmmo2Drop	= -1;
		info.iMaxClip 	= UZI_MAX_CLIP;
		info.iSlot 		= 2;
		info.iPosition 	= 8;
		info.iFlags 	= 0;
		info.iWeight 	= UZI_WEIGHT;

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
			dictionary@ pValues = {{"origin", pOrigin}, {"angles", pAngles}, {"spawnflags", "1024"}, {"targetname", "weapon_spawn"}};
			g_EntityFuncs.CreateEntity( self.GetClassname(), @pValues, true );
		}	

		self.pev.targetname = string_t(); // Reset the targetname as this weapon is no longer "dropped"
		self.pev.globalname = string_t(); // Reset the owner
		
		int m_iDuplicateClip = DeleteNearbyDuplicatesByOwner();
		
		if ( m_iDuplicateClip >= 0 )
			self.m_iClip = m_iDuplicateClip;
		
		// Can only have one weapon of this category at a time
		CBasePlayerItem@ pItem1 = pPlayer.HasNamedPlayerItem( "weapon_dcmp5k" );
		CBasePlayerItem@ pItem2 = pPlayer.HasNamedPlayerItem( "weapon_dcshotgun" );
		
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
		string m_iszOwnerId = g_EngineFuncs.GetPlayerAuthId(m_pPlayer.edict());
		
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
	
	void Holster( int skipLocal = 0 )
	{
		m_pPlayer.m_flNextAttack = WeaponTimeBase() + 0.7f;
		BaseClass.Holster( skipLocal );

		if ( g_bNoLimitWeapons )
            return;
		
		if ( m_pPostDropItemSched !is null )
			g_Scheduler.RemoveTimer( m_pPostDropItemSched );
		
		@m_pPostDropItemSched = g_Scheduler.SetTimeout( @this, "PostDropItem", 0.1 );
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
		CBasePlayerWeapon@ pNew = cast<CBasePlayerWeapon@>( g_EntityFuncs.CreateEntity( pWeapon.GetClassname(), @pValues, true ) );
		
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
		
		m_pPlayer.SetItemPickupTimes( 0 );
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
		return self.DefaultDeploy( self.GetV_Model( "models/AoMDC/weapons/uzi/v_dcuzi.mdl" ), self.GetP_Model( "models/AoMDC/weapons/uzi/p_dcuzi.mdl" ), MP5_DEPLOY, "onehanded" );
	}
	
	float WeaponTimeBase()
	{
		return g_Engine.time; //g_WeaponFuncs.WeaponTimeBase();
	}

	void PrimaryAttack()
	{
		int m_iBulletDamage;
		
		// don't fire underwater
		if ( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
		{
			self.m_flNextPrimaryAttack = WeaponTimeBase();
			return;
		}

		if ( self.m_iClip <= 0 )
		{
			self.m_flNextPrimaryAttack = WeaponTimeBase();
			return;
		}

		m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;

		--self.m_iClip;
		
		switch ( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 2 ) )
		{
		case 0: self.SendWeaponAnim( UZI_FIRE1, 0, 0 ); break;
		case 1: self.SendWeaponAnim( UZI_FIRE2, 0, 0 ); break;
		case 2: self.SendWeaponAnim( UZI_FIRE3, 0, 0 ); break;
		}
		
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "AoMDC/weapons/uzi/uzi_fire.wav", 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );

		// player "shoot" animation
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		Vector vecSrc	 = m_pPlayer.GetGunPosition();
		Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_2DEGREES );
		
		if ( bSurvivalEnabled )
			m_iBulletDamage = UZI_MOD_DAMAGE_SURVIVAL;
		else
			m_iBulletDamage = UZI_MOD_DAMAGE;
			
		m_pPlayer.FireBullets( 1, vecSrc, vecAiming, VECTOR_CONE_4DEGREES, 8192, BULLET_PLAYER_CUSTOMDAMAGE, 2, m_iBulletDamage );
			
		//m_pPlayer.pev.punchangle.x = -1;

		self.m_flNextPrimaryAttack = self.m_flNextPrimaryAttack + UZI_MOD_FIRERATE;
		if ( self.m_flNextPrimaryAttack < WeaponTimeBase() )
			self.m_flNextPrimaryAttack = WeaponTimeBase();

		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  10, 15 );
		
		TraceResult tr;
		
		float x, y;
		
		g_Utility.GetCircularGaussianSpread( x, y );
		
		Vector vecDir = vecAiming 
						+ x * VECTOR_CONE_4DEGREES.x * g_Engine.v_right 
						+ y * VECTOR_CONE_4DEGREES.y * g_Engine.v_up;

		Vector vecEnd	= vecSrc + vecDir * 4096;

		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );
		
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
		
		if ( tr.flFraction < 1.0 )
		{
			if ( tr.pHit !is null )
			{
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
				
				if ( pHit is null || pHit.IsBSPModel() )
					g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_9MM );
			}
		}
		
		iShellModelIndex = g_EngineFuncs.ModelIndex( "models/shell.mdl" );
		Vector brassOrigin = m_pPlayer.GetGunPosition() + g_Engine.v_forward * 15.0 +
							 g_Engine.v_up * -5.0 +
							 g_Engine.v_right * 6.0;
		Vector brassDir = g_Engine.v_right * Math.RandomFloat(65.0, 100.0) + 
						  g_Engine.v_up * Math.RandomFloat(10.0, 45.0) + 
						  g_Engine.v_forward * Math.RandomFloat(-30.0, 30.0);
		
		g_EntityFuncs.EjectBrass( brassOrigin, brassDir, 0.0f, iShellModelIndex, TE_BOUNCE_SHELL );
	}

	void Reload()
	{
		self.DefaultReload( UZI_MAX_CLIP, UZI_RELOAD, 2.5, 0 );

		//Set 3rd person reloading animation -Sniper
		BaseClass.Reload();
	}
}

string GetDCUziName()
{
	return "weapon_dcuzi";
}

void RegisterDCUzi()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_dcuzi", GetDCUziName() );
	g_ItemRegistry.RegisterWeapon( GetDCUziName(), "AoMDC", "556", "", "ammo_dcmp5k" );
}
