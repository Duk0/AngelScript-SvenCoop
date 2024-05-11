// Poke646 Script
// Weapon Script: Nailgun
// Author: Zorbos

const float NAILGUN_MOD_DAMAGE = 15.0;
const float NAILGUN_MOD_FIRERATE = 0.10;

enum NAILGUNAnimation
{
	NAILGUN_LONGIDLE = 0,
	NAILGUN_IDLE1,
	NAILGUN_LAUNCH,
	NAILGUN_RELOAD,
	NAILGUN_DEPLOY,
	NAILGUN_FIRE1,
	NAILGUN_FIRE2,
	NAILGUN_FIRE3,
};

const int NAILGUN_DEFAULT_GIVE 	= 50;
const int NAILGUN_MAX_AMMO		= 200;
const int NAILGUN_MAX_AMMO2 	= -1;
const int NAILGUN_MAX_CLIP 		= 50;
const int NAILGUN_WEIGHT 		= 5;

class weapon_nailgun : ScriptBasePlayerWeaponEntity
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}
	
	float m_flNextAnimTime;
	int m_iShell;
	int	m_iSecondaryAmmo;
	
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, "models/poke646/weapons/nailgun/w_nailgun.mdl" );

		self.m_iDefaultAmmo = NAILGUN_DEFAULT_GIVE;

		self.m_iSecondaryAmmoType = 0;
		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( "models/poke646/weapons/nailgun/v_nailgun.mdl" );
		g_Game.PrecacheModel( "models/poke646/weapons/nailgun/w_nailgun.mdl" );
		g_Game.PrecacheModel( "models/poke646/weapons/nailgun/p_nailgun.mdl" );

		m_iShell = g_Game.PrecacheModel( "models/shell.mdl" );        

		//These are played by the model, needs changing there
		g_SoundSystem.PrecacheSound( "poke646/weapons/nailgun/nailgun_fire.wav" );
		g_SoundSystem.PrecacheSound( "poke646/weapons/nailgun/nailgun_clipout.wav" );
		g_SoundSystem.PrecacheSound( "poke646/weapons/nailgun/nailgun_clipin.wav" );

		g_SoundSystem.PrecacheSound( "weapons/dryfire1.wav" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= NAILGUN_MAX_AMMO;
		info.iAmmo1Drop	= NAILGUN_MAX_CLIP;
		info.iMaxAmmo2 	= NAILGUN_MAX_AMMO2;
		info.iAmmo2Drop	= -1;
		info.iMaxClip 	= NAILGUN_MAX_CLIP;
		info.iSlot 		= 1;
		info.iPosition 	= 5;
		info.iFlags 	= 0;
		info.iWeight 	= NAILGUN_WEIGHT;

		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer( pPlayer ) )
			return false;
			
		@m_pPlayer = pPlayer;

		NetworkMessage message( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			message.WriteLong( self.m_iId );
		message.End();

		return true;
	}
	
	bool PlayEmptySound()
	{
		if( self.m_bPlayEmptySound )
		{
			self.m_bPlayEmptySound = false;
			
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "weapons/dryfire1.wav", 0.8, ATTN_NORM, 0, PITCH_NORM );
		}
		
		return false;
	}

	bool Deploy()
	{
		return self.DefaultDeploy( self.GetV_Model( "models/poke646/weapons/nailgun/v_nailgun.mdl" ), self.GetP_Model( "models/poke646/weapons/nailgun/p_nailgun.mdl" ), NAILGUN_DEPLOY, "mp5" );
	}
	
	float WeaponTimeBase()
	{
		return g_Engine.time; //g_WeaponFuncs.WeaponTimeBase();
	}

	void PrimaryAttack()
	{
		// don't fire underwater
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
		{
			self.PlayEmptySound( );
			self.m_flNextPrimaryAttack = WeaponTimeBase() + NAILGUN_MOD_FIRERATE;
			return;
		}

		if( self.m_iClip <= 0 )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = WeaponTimeBase() + NAILGUN_MOD_FIRERATE;
			return;
		}

		m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;

		--self.m_iClip;
		
		switch ( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 2 ) )
		{
		case 0: self.SendWeaponAnim( NAILGUN_FIRE1, 0, 0 ); break;
		case 1: self.SendWeaponAnim( NAILGUN_FIRE2, 0, 0 ); break;
		case 2: self.SendWeaponAnim( NAILGUN_FIRE3, 0, 0 ); break;
		}
		
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "poke646/weapons/nailgun/nailgun_fire.wav", 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );

		// player "shoot" animation
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		Vector vecSrc	 = m_pPlayer.GetGunPosition();
		Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );
		
		int m_iBulletDamage = NAILGUN_MOD_DAMAGE;
		
		// optimized multiplayer. Widened to make it easier to hit a moving player
		m_pPlayer.FireBullets( 1, vecSrc, vecAiming, VECTOR_CONE_6DEGREES, 8192, BULLET_PLAYER_CUSTOMDAMAGE, 2, m_iBulletDamage );
			
		m_pPlayer.pev.punchangle.x = Math.RandomLong( -1, 1 );

		self.m_flNextPrimaryAttack = self.m_flNextPrimaryAttack + NAILGUN_MOD_FIRERATE;
		if( self.m_flNextPrimaryAttack < WeaponTimeBase() )
			self.m_flNextPrimaryAttack = WeaponTimeBase() + NAILGUN_MOD_FIRERATE;

		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  10, 15 );
		
		TraceResult tr;
		
		float x, y;
		
		g_Utility.GetCircularGaussianSpread( x, y );
		
		Vector vecDir = vecAiming 
						+ x * VECTOR_CONE_6DEGREES.x * g_Engine.v_right 
						+ y * VECTOR_CONE_6DEGREES.y * g_Engine.v_up;

		Vector vecEnd	= vecSrc + vecDir * 4096;

		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );
		
		if( tr.flFraction < 1.0 )
		{
			if( tr.pHit !is null )
			{
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
				
				if( pHit is null || pHit.IsBSPModel() )
				{
					switch( Math.RandomLong(0,2) )
					{
						case 0:
							g_Utility.Sparks(tr.vecEndPos);
							break;
						case 1:
							g_Utility.Sparks(tr.vecEndPos);
							break;
						case 2:
							break;
					}
				}
			}
		}
	}

	void Reload()
	{
		if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 || self.m_iClip == NAILGUN_MAX_CLIP )
			return;
			
		self.DefaultReload( NAILGUN_MAX_CLIP, NAILGUN_RELOAD, 1.5, 0 );

		//Set 3rd person reloading animation -Sniper
		BaseClass.Reload();
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();

		m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;

		int iAnim;
		switch( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed,  0, 1 ) )
		{
		case 0:	
			iAnim = NAILGUN_LONGIDLE;	
			break;
		
		case 1:
			iAnim = NAILGUN_IDLE1;
			break;
			
		default:
			iAnim = NAILGUN_IDLE1;
			break;
		}

		self.SendWeaponAnim( iAnim );

		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  10, 15 );// how long till we do this again.
	}
}

string GetNailgunName()
{
	return "weapon_nailgun";
}

void RegisterNailgun()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_nailgun", GetNailgunName() );
	g_ItemRegistry.RegisterWeapon( GetNailgunName(), "poke646", "9mm", "", "ammo_nailround" );
}
