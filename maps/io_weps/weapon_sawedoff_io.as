enum TheyHungerSAWEDOFFAnimation_e
{
	TOZ34_IDLE = 0,
	TOZ34_DRAW,
	TOZ34_RELOAD_SINGLE,
	TOZ34_RELOAD,
	TOZ34_SHOOT1
};

const int SAWEDOFF_MAX_CARRY	= 125;
const int SAWEDOFF_DEFAULT_GIVE	= 4;
const int SAWEDOFF_MAX_CLIP 	= 2;
const int SAWEDOFF_WEIGHT   	= 35;
const uint SAWEDOFF_SINGLE_PELLETCOUNTER = 24;
const uint SAWEDOFF_DOUBLE_PELLETCOUNT = SAWEDOFF_SINGLE_PELLETCOUNTER * 2;
const Vector VECTOR_CONE_DM_SAWEDOFFS( 0.10716, 0.12362, 0.00 );
const Vector VECTOR_CONE_DM_SAWEDOFFD( 0.12716, 0.16365, 0.00 );

class weapon_sawedoff : ScriptBasePlayerWeaponEntity
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}

	int m_iShotsFired;

	string TOZ34_W_MODEL = "models/rngstuff/kuilu/weapons/w_sawedoff.mdl";
	string TOZ34_V_MODEL = "models/rngstuff/kuilu/weapons/v_sawedoff.mdl";
	string TOZ34_P_MODEL = "models/rngstuff/kuilu/weapons/p_sawedoff.mdl";

	string TOZ34_S_FIRE1 = "rng/kuilu/weapons/shotgun_fire.ogg";
	string TOZ34_S_DFIRE = "rng/kuilu/weapons/shotgun_fire2.ogg";

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, TOZ34_W_MODEL );
		
		self.m_iDefaultAmmo = SAWEDOFF_DEFAULT_GIVE;
		m_iShotsFired = 0;
		
		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( TOZ34_W_MODEL );
		g_Game.PrecacheModel( TOZ34_V_MODEL );
		g_Game.PrecacheModel( TOZ34_P_MODEL );

		g_SoundSystem.PrecacheSound( TOZ34_S_DFIRE );
		g_SoundSystem.PrecacheSound( TOZ34_S_FIRE1 );
		g_SoundSystem.PrecacheSound( "rng/kuilu/weapons/shotgun_close.ogg" );
		g_SoundSystem.PrecacheSound( "rng/kuilu/weapons/shotgun_open.ogg" );
		g_SoundSystem.PrecacheSound( "rng/kuilu/weapons/shotgun_shell_out.ogg" );
		g_SoundSystem.PrecacheSound( "rng/kuilu/weapons/shotgun_shell1.ogg" );
		g_SoundSystem.PrecacheSound( "rng/kuilu/weapons/shotgun_shell2.ogg" );
		g_SoundSystem.PrecacheSound( "rng/kuilu/weapons/shotgun_shells_eject.ogg" );

		g_Game.PrecacheGeneric( "sound/" + TOZ34_S_DFIRE );
		g_Game.PrecacheGeneric( "sound/" + TOZ34_S_FIRE1 );
		g_Game.PrecacheGeneric( "sound/" + "rng/kuilu/weapons/shotgun_close.ogg" );
		g_Game.PrecacheGeneric( "sound/" + "rng/kuilu/weapons/shotgun_open.ogg" );
		g_Game.PrecacheGeneric( "sound/" + "rng/kuilu/weapons/shotgun_shell_out.ogg" );
		g_Game.PrecacheGeneric( "sound/" + "rng/kuilu/weapons/shotgun_shell1.ogg" );
		g_Game.PrecacheGeneric( "sound/" + "rng/kuilu/weapons/shotgun_shell2.ogg" );
		g_Game.PrecacheGeneric( "sound/" + "rng/kuilu/weapons/shotgun_shells_eject.ogg" );

		g_Game.PrecacheGeneric( "sprites/" + "kuilu/weapon_sawedoff.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "kuilu/weapon_sawedoff.txt" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= SAWEDOFF_MAX_CARRY;
		info.iAmmo1Drop	= SAWEDOFF_MAX_CLIP;
		info.iMaxAmmo2	= -1;
		info.iAmmo2Drop	= -1;
		info.iMaxClip	= SAWEDOFF_MAX_CLIP;
		info.iSlot		= 2;
		info.iPosition	= 6;
		info.iFlags		= 0;
		info.iWeight	= SAWEDOFF_WEIGHT;
		
		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if ( !BaseClass.AddToPlayer( pPlayer ) )
			return false;
			
		@m_pPlayer = pPlayer;

		NetworkMessage hunger1( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
		hunger1.WriteLong( self.m_iId );
		hunger1.End();

		return true;
	}

	bool PlayEmptySound()
	{
		if ( self.m_bPlayEmptySound )
		{
			self.m_bPlayEmptySound = false;
			
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_AUTO, "weapons/357_cock1.wav", 0.8, ATTN_NORM, 0, PITCH_NORM );
		}
		return false;
	}

	float WeaponTimeBase()
	{
		return g_Engine.time;
	}

	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy ( self.GetV_Model( TOZ34_V_MODEL ), self.GetP_Model( TOZ34_P_MODEL ), TOZ34_DRAW, "shotgun" );
			
			float deployTime = 1.15f;
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + deployTime;
			return bResult;
		}
	}

	void Holster( int skipLocal = 0 ) 
	{
		self.m_fInReload = false;
		BaseClass.Holster( skipLocal );
	}

	void CreatePelletDecals( const Vector& in vecSrc, const Vector& in vecAiming, const Vector& in vecSpread, const uint uiPelletCount )
	{
		TraceResult tr;
		
		float x, y;
		
		for( uint uiPellet = 0; uiPellet < uiPelletCount; ++uiPellet )
		{
			g_Utility.GetCircularGaussianSpread( x, y );
			
			Vector vecDir = vecAiming + x * vecSpread.x * g_Engine.v_right + y * vecSpread.y * g_Engine.v_up;

			Vector vecEnd = vecSrc + vecDir * 2048;
			
			g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );
			
			if ( tr.flFraction < 1.0 )
			{
				if ( tr.pHit !is null )
				{
					CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
					
					if ( pHit is null || pHit.IsBSPModel() )
					{
						g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_BUCKSHOT );
					}
				}
			}
		}
	}

	void PrimaryAttack()
	{
		if ( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD || self.m_iClip <= 0 )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.15f;
			return;
		}

		m_iShotsFired++;
		if ( m_iShotsFired > 1 )
		{
			return;
		}
		
		self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.123;
		
		m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;
		
		--self.m_iClip;
		
		m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		//self.pev.effects |= EF_MUZZLEFLASH;
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		
		self.SendWeaponAnim( TOZ34_SHOOT1, 0, 0 );
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_AUTO, TOZ34_S_FIRE1, Math.RandomFloat( 0.98, 1.0 ), ATTN_NORM, 0, 85 + Math.RandomLong( 0, 0x1f ) );
		
		Vector vecSrc	 = m_pPlayer.GetGunPosition();
		Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

		m_pPlayer.FireBullets( SAWEDOFF_SINGLE_PELLETCOUNTER, vecSrc, vecAiming, VECTOR_CONE_DM_SAWEDOFFS, 3064, BULLET_PLAYER_BUCKSHOT, 0 );

		if ( self.m_iClip == 0 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
		{
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );
		}

		m_pPlayer.pev.punchangle.x += Math.RandomLong( -5, -3 );

		//self.m_flNextPrimaryAttack = self.m_flNextPrimaryAttack + 0.15f;
		if ( self.m_flNextPrimaryAttack < WeaponTimeBase() )
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.15f;

		CreatePelletDecals( vecSrc, vecAiming, VECTOR_CONE_DM_SAWEDOFFS, SAWEDOFF_SINGLE_PELLETCOUNTER );
	}

	void SecondaryAttack()
	{
		// don't fire underwater
		if ( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = g_Engine.time + 0.15;
			return;
		}

		if ( self.m_iClip <= 1 )
		{
			self.Reload();
			self.PlayEmptySound();
			return;
		}
		
		self.SendWeaponAnim( TOZ34_SHOOT1, 0, 0 );
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		self.m_iClip -= 2;
		
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_AUTO, TOZ34_S_DFIRE, Math.RandomFloat( 0.98, 1.0 ), ATTN_NORM, 0, 85 + Math.RandomLong( 0, 0x1f ) );

		m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;
		m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		//self.pev.effects |= EF_MUZZLEFLASH;

		Vector vecSrc	 = m_pPlayer.GetGunPosition();
		Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );
		
		m_pPlayer.FireBullets( SAWEDOFF_DOUBLE_PELLETCOUNT, vecSrc, vecAiming, VECTOR_CONE_DM_SAWEDOFFD, 2048, BULLET_PLAYER_BUCKSHOT, 0 );

		if ( self.m_iClip == 0 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
		{
			// HEV suit - indicate out of ammo condition
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );
		}

		self.m_flNextPrimaryAttack = g_Engine.time + 0.60;
		self.m_flNextSecondaryAttack = g_Engine.time + 0.60;
		
		if ( self.m_iClip != 0 )
			self.m_flTimeWeaponIdle = g_Engine.time + 2.0;
		else
			self.m_flTimeWeaponIdle = g_Engine.time + 0.60;
			
		m_pPlayer.pev.punchangle.x = -10.0;
		
		CreatePelletDecals( vecSrc, vecAiming, VECTOR_CONE_DM_SAWEDOFFD, SAWEDOFF_DOUBLE_PELLETCOUNT );
	}

	void Reload()
	{
		if ( self.m_iClip < SAWEDOFF_MAX_CLIP )
		{
			BaseClass.Reload();
		}
		m_iShotsFired = 0;

		( self.m_iClip == 1 || m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 1 ) ? self.DefaultReload( SAWEDOFF_MAX_CLIP, TOZ34_RELOAD_SINGLE, 3.62, 0 ) : 
																						self.DefaultReload( SAWEDOFF_MAX_CLIP, TOZ34_RELOAD, 3.02, 0 );

		/*if ( self.m_iClip == 1 || m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 1)
		{
			
		}
		else if ( self.m_iClip < 1 )
		{
			m_iShotsFired = 0;
			self.DefaultReload( SAWEDOFF_MAX_CLIP, TOZ34_RELOAD, 3.02, 0 );
		}*/
	}

	void WeaponIdle()
	{
		// Can we fire?
		if ( self.m_flNextPrimaryAttack < WeaponTimeBase() )
		{
		// If the player is still holding the attack button, m_iShotsFired won't reset to 0
		// Preventing the automatic firing of the weapon
			if ( !( ( m_pPlayer.pev.button & IN_ATTACK ) != 0 ) )
			{
				// Player released the button, reset now
				m_iShotsFired = 0;
			}
		}

		self.ResetEmptySound();

		m_pPlayer.GetAutoaimVector( AUTOAIM_10DEGREES );
		
		if ( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;
		
		self.SendWeaponAnim( TOZ34_IDLE, 0, 0 );
		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  5, 7 );
	}
}

string SAWEDOFFName()
{
	return "weapon_sawedoff";
}

void RegisterSAWEDOFF()
{
	g_CustomEntityFuncs.RegisterCustomEntity( SAWEDOFFName(), SAWEDOFFName() );
	g_ItemRegistry.RegisterWeapon( SAWEDOFFName(), "kuilu", "buckshot", "", "ammo_buckshot" );
}
