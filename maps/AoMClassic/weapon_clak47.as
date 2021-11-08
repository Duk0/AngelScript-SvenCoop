// Afraid of Monsters Classic Script
// Weapon Script: AK-47
// Author: Zorbos

const float AK47_MOD_DAMAGE = 18.0;
const float AK47_MOD_FIRERATE = 0.1;

const float AK47_MOD_DAMAGE_SURVIVAL = 13.0; // Reduce damage by 25% on Survival

enum Ak47Animation
{
	AK47_LONGIDLE = 0,
	AK47_IDLE1,
	AK47_LAUNCH,
	AK47_RELOAD,
	AK47_DEPLOY,
	AK47_FIRE1,
	AK47_FIRE2,
	AK47_FIRE3,
};

const int AK47_DEFAULT_GIVE 	= 50;
const int AK47_MAX_AMMO		= 150;
const int AK47_MAX_AMMO2 	= -1;
const int AK47_MAX_CLIP 		= 50;
const int AK47_WEIGHT 		= 5;

class weapon_clak47 : ScriptBasePlayerWeaponEntity
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}
	
	private bool bSurvivalEnabled = g_SurvivalMode.MapSupportEnabled() && g_SurvivalMode.IsEnabled();
	
	float m_flNextAnimTime;
	int m_iShell;
	int iShellModelIndex;
	
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, "models/AoMClassic/weapons/ak47/w_clak47.mdl" );

		self.m_iDefaultAmmo = AK47_DEFAULT_GIVE;

		self.m_iSecondaryAmmoType = 0;
		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( "models/AoMClassic/weapons/ak47/v_clak47.mdl" );
		g_Game.PrecacheModel( "models/AoMClassic/weapons/ak47/w_clak47.mdl" );
		g_Game.PrecacheModel( "models/AoMClassic/weapons/ak47/p_clak47.mdl" );

		m_iShell = g_Game.PrecacheModel( "models/saw_shell.mdl" );             

		//These are played by the model, needs changing there
		g_SoundSystem.PrecacheSound( "AoMClassic/weapons/ak47/ak47_boltpull.wav" );
		g_SoundSystem.PrecacheSound( "AoMClassic/weapons/ak47/ak47_clipin.wav" );
		g_SoundSystem.PrecacheSound( "AoMClassic/weapons/ak47/ak47_clipout.wav" );
		g_SoundSystem.PrecacheSound( "AoMClassic/weapons/ak47/ak47_fire.wav" );
		g_SoundSystem.PrecacheSound( "AoMClassic/weapons/ak47/ak47_stockup.wav" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= AK47_MAX_AMMO;
		info.iAmmo1Drop	= AK47_MAX_CLIP;
		info.iMaxAmmo2 	= AK47_MAX_AMMO2;
		info.iAmmo2Drop	= -1;
		info.iMaxClip 	= AK47_MAX_CLIP;
		info.iSlot 		= 2;
		info.iPosition 	= 8;
		info.iFlags 	= 0;
		info.iWeight 	= AK47_WEIGHT;

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

		return true;
	}

	bool Deploy()
	{
		return self.DefaultDeploy( self.GetV_Model( "models/AoMClassic/weapons/ak47/v_clak47.mdl" ), self.GetP_Model( "models/AoMClassic/weapons/ak47/p_clak47.mdl" ), AK47_DEPLOY, "mp5" );
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
		case 0: self.SendWeaponAnim( AK47_FIRE1, 0, 0 ); break;
		case 1: self.SendWeaponAnim( AK47_FIRE2, 0, 0 ); break;
		case 2: self.SendWeaponAnim( AK47_FIRE3, 0, 0 ); break;
		}
		
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "AoMClassic/weapons/ak47/ak47_fire.wav", 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );

		// player "shoot" animation
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		Vector vecSrc	 = m_pPlayer.GetGunPosition();
		Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );
		
		// optimized multiplayer. Widened to make it easier to hit a moving player
		if ( bSurvivalEnabled )
			m_iBulletDamage = AK47_MOD_DAMAGE_SURVIVAL;
		else
			m_iBulletDamage = AK47_MOD_DAMAGE;
		
		m_pPlayer.FireBullets( 1, vecSrc, vecAiming, VECTOR_CONE_4DEGREES, 8192, BULLET_PLAYER_CUSTOMDAMAGE, 2, m_iBulletDamage );
			
		m_pPlayer.pev.punchangle.x = Math.RandomLong( -1, 1 );

		self.m_flNextPrimaryAttack = self.m_flNextPrimaryAttack + AK47_MOD_FIRERATE;
		if ( self.m_flNextPrimaryAttack < WeaponTimeBase() )
			self.m_flNextPrimaryAttack = WeaponTimeBase() + AK47_MOD_FIRERATE;

		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  10, 15 );
		
		NetworkMessage mFlash( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
			mFlash.WriteByte(TE_DLIGHT);
			mFlash.WriteCoord( m_pPlayer.GetGunPosition().x );
			mFlash.WriteCoord( m_pPlayer.GetGunPosition().y );
			mFlash.WriteCoord( m_pPlayer.GetGunPosition().z );
			mFlash.WriteByte( 14 ); // Radius
			mFlash.WriteByte( 255 ); // R
			mFlash.WriteByte( 255 ); // G
			mFlash.WriteByte( 204 ); // B
			mFlash.WriteByte( 1 ); // Lifetime
			mFlash.WriteByte( 1 ); // Decay
		mFlash.End();
		
		TraceResult tr;
		
		float x, y;
		
		g_Utility.GetCircularGaussianSpread( x, y );
		
		Vector vecDir = vecAiming 
						+ x * VECTOR_CONE_4DEGREES.x * g_Engine.v_right 
						+ y * VECTOR_CONE_4DEGREES.y * g_Engine.v_up;

		Vector vecEnd	= vecSrc + vecDir * 4096;

		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );
		
		if ( tr.flFraction < 1.0 )
		{
			if ( tr.pHit !is null )
			{
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
				
				if ( pHit is null || pHit.IsBSPModel() )
					g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_9MM );
			}
		}
		
		iShellModelIndex = g_EngineFuncs.ModelIndex( "models/saw_shell.mdl" );
		Vector brassOrigin = m_pPlayer.GetGunPosition() + g_Engine.v_forward * 22.0 +
							 g_Engine.v_up * -8.5 +
							 g_Engine.v_right * 9.0;
		Vector brassDir = g_Engine.v_right * Math.RandomFloat(75.0, 150.0) + 
						  g_Engine.v_up * Math.RandomFloat(10.0, 40.0) + 
						  g_Engine.v_forward * Math.RandomFloat(-35.0, 35.0);
		
		g_EntityFuncs.EjectBrass( brassOrigin, brassDir, 0.0f, iShellModelIndex, TE_BOUNCE_SHELL );
	}

	void Reload()
	{
		self.DefaultReload( AK47_MAX_CLIP, AK47_RELOAD, 2.0, 0 );

		//Set 3rd person reloading animation -Sniper
		BaseClass.Reload();
	}
}

string GetCLAK47Name()
{
	return "weapon_clak47";
}

void RegisterCLAK47()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_clak47", GetCLAK47Name() );
	g_ItemRegistry.RegisterWeapon( GetCLAK47Name(), "AoMClassic", "9mm", "", "ammo_9mmAR" );
}
