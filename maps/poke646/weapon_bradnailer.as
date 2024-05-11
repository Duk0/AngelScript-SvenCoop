// Poke646 Script
// Weapon Script: Bradnailer
// Author: Zorbos

const float BRADNAILER_DAMAGE = 15.0;
const float BRADNAILER_ALT_DAMAGE = 15.0;
const float BRADNAILER_MOD_PRIM_FIRERATE = 0.30;
const float BRADNAILER_MOD_ALT_FIRERATE = 0.20;

const int BRADNAILER_DEFAULT_AMMO 	= 25;
const int BRADNAILER_MAX_CARRY 	= 200;
const int BRADNAILER_MAX_CLIP 		= 25;
const int BRADNAILER_WEIGHT 		= 5;

enum BRADNAILERAnimation
{
	BRADNAILER_IDLE1 = 0,
	BRADNAILER_IDLE2,
	BRADNAILER_IDLE3,
	BRADNAILER_SHOOT,
	BRADNAILER_SHOOT_EMPTY,
	BRADNAILER_RELOAD,
	BRADNAILER_RELOAD_NOSHOT,
	BRADNAILER_DRAW,
	BRADNAILER_HOLSTER,
	BRADNAILER_ADD_SILENCER,
	BRADNAILER_TILT_DOWN,
	BRADNAILER_TILT_UP,
	BRADNAILER_FAST_SHOOT
};

class weapon_bradnailer : ScriptBasePlayerWeaponEntity
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}

	int m_iShell;
	bool m_bCanReload = true;
	bool m_bIsTilted = false;

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, "models/poke646/weapons/bradnailer/w_bradnailer.mdl" );
		
		self.m_iDefaultAmmo = BRADNAILER_DEFAULT_AMMO;

		self.FallInit();// get ready to fall
	}
	
	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( "models/poke646/weapons/bradnailer/w_bradnailer.mdl" );
		g_Game.PrecacheModel( "models/poke646/weapons/bradnailer/v_bradnailer.mdl" );
		g_Game.PrecacheModel( "models/poke646/weapons/bradnailer/p_bradnailer.mdl" );

		g_SoundSystem.PrecacheSound( "poke646/weapons/bradnailer/bradnailer_clipout.wav" ); // reloading sound
		g_SoundSystem.PrecacheSound( "poke646/weapons/bradnailer/bradnailer_clipin.wav" ); // reloading sound

		g_SoundSystem.PrecacheSound( "poke646/weapons/bradnailer/bradnailer_fire.wav" ); // firing sound
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
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= BRADNAILER_MAX_CARRY;
		info.iAmmo1Drop	= BRADNAILER_MAX_CLIP;
		info.iMaxAmmo2 	= -1;
		info.iAmmo2Drop	= -1;
		info.iMaxClip 	= BRADNAILER_MAX_CLIP;
		info.iSlot 		= 1;
		info.iPosition 	= 4;
		info.iFlags 	= 0;
		info.iWeight 	= BRADNAILER_WEIGHT;

		return true;
	}

	bool Deploy()
	{
		return self.DefaultDeploy( self.GetV_Model( "models/poke646/weapons/bradnailer/v_bradnailer.mdl" ), self.GetP_Model( "models/poke646/weapons/bradnailer/p_bradnailer.mdl" ), BRADNAILER_DRAW, "onehanded" );
	}

	void Holster( int skiplocal /* = 0 */ )
	{
		m_bIsTilted = false;
		m_pPlayer.m_flNextAttack = g_WeaponFuncs.WeaponTimeBase() + 0.5;
		m_bCanReload = true;
	}

	float WeaponTimeBase()
	{
		return g_Engine.time; //g_WeaponFuncs.WeaponTimeBase();
	}

	void PrimaryAttack()
	{
		if (m_bIsTilted) // Tilted, don't fire
			return;

		// don't fire underwater
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
		{
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.15;
			return;
		}
	
		if (self.m_iClip == 0)
		{
			self.m_flNextPrimaryAttack = g_Engine.time + BRADNAILER_MOD_PRIM_FIRERATE;
			return;
		}

		self.SendWeaponAnim( BRADNAILER_SHOOT, 0, 0 );

		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "poke646/weapons/bradnailer/bradnailer_fire.wav", Math.RandomFloat( 0.92, 1.0 ), ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) );

		m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;

		--self.m_iClip;

		// player "shoot" animation
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		Vector vecSrc	 = m_pPlayer.GetGunPosition();
		Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_2DEGREES );

		int m_iBulletDamage = BRADNAILER_DAMAGE;

		m_pPlayer.FireBullets( 1, vecSrc, vecAiming, VECTOR_CONE_2DEGREES, 8192, BULLET_PLAYER_CUSTOMDAMAGE, 0, m_iBulletDamage );
		self.m_flNextPrimaryAttack = g_Engine.time + BRADNAILER_MOD_PRIM_FIRERATE;
		self.m_flTimeWeaponIdle = WeaponTimeBase();

		m_pPlayer.pev.punchangle.x = -1.0;
		
		TraceResult tr;
		float x, y;
		
		g_Utility.GetCircularGaussianSpread( x, y );
		
		Vector vecDir = vecAiming 
						+ x * VECTOR_CONE_2DEGREES.x * g_Engine.v_right 
						+ y * VECTOR_CONE_2DEGREES.y * g_Engine.v_up;

		Vector vecEnd	= vecSrc + vecDir * 4096;

		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );
		
		if ( tr.flFraction < 1.0 )
		{
			if ( tr.pHit !is null )
			{
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
				
				if ( pHit is null || pHit.IsBSPModel() )
				{
					switch( Math.RandomLong( 0, 2 ) )
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

	void SecondaryAttack()
	{
		m_bCanReload = false;
		
		if (!m_bIsTilted) // Not tilted yet
		{
			self.SendWeaponAnim( BRADNAILER_TILT_DOWN );
			
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.4;
			self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.4;
			
			self.m_flTimeWeaponIdle = WeaponTimeBase() + 0.4;
			m_bIsTilted = true;
		}
		else // Already tilted. Attack
		{
			DoSecondaryAttack();
			self.m_flTimeWeaponIdle = WeaponTimeBase() + 0.4;
		}
	}

	void DoSecondaryAttack()
	{
		// don't fire underwater
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = WeaponTimeBase() + BRADNAILER_MOD_ALT_FIRERATE;
			return;
		}
		
		if (self.m_iClip == 0)
		{
			self.PlayEmptySound();
			self.m_flNextSecondaryAttack = g_Engine.time + BRADNAILER_MOD_ALT_FIRERATE;
			m_bCanReload = true;
			return;
		}

		self.SendWeaponAnim( BRADNAILER_FAST_SHOOT, 0, 0 );

		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "poke646/weapons/bradnailer/bradnailer_fire.wav", Math.RandomFloat( 0.92, 1.0 ), ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) );

		m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;

		--self.m_iClip;

		// player "shoot" animation
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		Vector vecSrc	 = m_pPlayer.GetGunPosition();
		Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_2DEGREES );

		int m_iBulletDamage = BRADNAILER_ALT_DAMAGE;

		m_pPlayer.FireBullets( 1, vecSrc, vecAiming, VECTOR_CONE_2DEGREES, 8192, BULLET_PLAYER_CUSTOMDAMAGE, 0, m_iBulletDamage );

		self.m_flNextSecondaryAttack = g_Engine.time + BRADNAILER_MOD_ALT_FIRERATE;

		m_pPlayer.pev.punchangle.x = -5.0;
		
		TraceResult tr;
		float x, y;
		
		g_Utility.GetCircularGaussianSpread( x, y );
		
		Vector vecDir = vecAiming 
						+ x * VECTOR_CONE_2DEGREES.x * g_Engine.v_right 
						+ y * VECTOR_CONE_2DEGREES.y * g_Engine.v_up;

		Vector vecEnd	= vecSrc + vecDir * 4096;

		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );
		
		if ( tr.flFraction < 1.0 )
		{
			if ( tr.pHit !is null )
			{
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
				
				if ( pHit is null || pHit.IsBSPModel() )
				{
					switch( Math.RandomLong( 0, 2 ) )
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
		if (!m_bCanReload)
			return;
			
		if (m_bIsTilted)
		{
			self.SendWeaponAnim( BRADNAILER_TILT_UP );
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.4;
			self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.4;
			m_bIsTilted = false;
		}
		else
		{
			if ( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 || self.m_iClip == BRADNAILER_MAX_CLIP )
				return;

			self.DefaultReload( 25, BRADNAILER_RELOAD, 1.65, 0 );

			BaseClass.Reload();
			return;
		}
	}
	
	void WeaponIdle()
	{
		if ( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;

		if (m_bIsTilted)
		{
			self.SendWeaponAnim( BRADNAILER_TILT_UP );
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.4;
			self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.4;
			m_bIsTilted = false;
			m_bCanReload = true;
		}
		
		self.m_flTimeWeaponIdle = WeaponTimeBase();
	}
}

string GetBradnailerName()
{
	return "weapon_bradnailer";
}

void RegisterBradnailer()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_bradnailer", GetBradnailerName() );
	g_ItemRegistry.RegisterWeapon( GetBradnailerName(), "poke646", "9mm", "", "ammo_nailclip" );
}
