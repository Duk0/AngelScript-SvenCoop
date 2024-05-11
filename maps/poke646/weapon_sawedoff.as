// Poke646 Script
// Weapon Script: Sawed Off Shotgun
// Author: Zorbos

// special deathmatch shotgun spreads
const Vector VECTOR_CONE_DM_SAWEDOFF( 0.15, 0.10, 0.00 );		// 10 degrees by 5 degrees

const float SAWEDOFF_DAMAGE = 30.0;
const float SAWEDOFF_MOD_FIRERATE = 1.30;
const float SAWEDOFF_MOD_RELOAD = 0.32;

const int SAWEDOFF_DEFAULT_AMMO 	= 12;
const int SAWEDOFF_MAX_CARRY 	= 48;
const int SAWEDOFF_MAX_CLIP 		= 12;
const int SAWEDOFF_WEIGHT 		= 15;

const uint SAWEDOFF_SINGLE_PELLETCOUNT = 12;
const uint SAWEDOFF_DOUBLE_PELLETCOUNT = SAWEDOFF_SINGLE_PELLETCOUNT * 2;

enum SawedOffAnimation
{
	SAWEDOFF_IDLE = 0,
	SAWEDOFF_FIRE,
	SAWEDOFF_INSERT,
	SAWEDOFF_RELOAD,
	SAWEDOFF_START_RELOAD,
	SAWEDOFF_DEPLOY,
	SAWEDOFF_IDLE2,
	SAWEDOFF_IDLE4,
	SAWEDOFF_IDLE3,
	SAWEDOFF_IDLE_DEEP
};

class weapon_sawedoff : ScriptBasePlayerWeaponEntity
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}
	
	float m_flNextReload;
	int m_iShell;
	float m_flPumpTime;
	bool m_fShotgunReload;
	int iShellModelIndex;

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, "models/vendetta/weapons/sawedoff/w_sawedoff.mdl" );
		
		self.m_iDefaultAmmo = SAWEDOFF_DEFAULT_AMMO;

		self.FallInit();// get ready to fall
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( "models/vendetta/weapons/sawedoff/v_sawedoff.mdl" );
		g_Game.PrecacheModel( "models/vendetta/weapons/sawedoff/w_sawedoff.mdl" );
		g_Game.PrecacheModel( "models/vendetta/weapons/sawedoff/p_sawedoff.mdl" );

		m_iShell = g_Game.PrecacheModel( "models/vendetta/items/shotgunshell.mdl" );// shotgun shell

		g_SoundSystem.PrecacheSound( "vendetta/weapons/sawedoff/sawedoff_fire.wav" );
		g_SoundSystem.PrecacheSound( "vendetta/weapons/sawedoff/sawedoff_pump.wav" );
		g_SoundSystem.PrecacheSound( "vendetta/weapons/sawedoff/sawedoff_reload1.wav" );
		g_SoundSystem.PrecacheSound( "vendetta/weapons/sawedoff/sawedoff_reload2.wav" );
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
		info.iMaxAmmo1 	= SAWEDOFF_MAX_CARRY;
		info.iAmmo1Drop	= SAWEDOFF_MAX_CLIP;
		info.iMaxAmmo2 	= -1;
		info.iAmmo2Drop	= -1;
		info.iMaxClip 	= SAWEDOFF_MAX_CLIP;
		info.iSlot 		= 2;
		info.iPosition 	= 6;
		info.iFlags 	= 0;
		info.iWeight 	= SAWEDOFF_WEIGHT;

		return true;
	}

	bool Deploy()
	{
		return self.DefaultDeploy( self.GetV_Model( "models/vendetta/weapons/sawedoff/v_sawedoff.mdl" ), self.GetP_Model( "models/vendetta/weapons/sawedoff/p_sawedoff.mdl" ), SAWEDOFF_DEPLOY, "shotgun" );
	}
	
	void Holster( int skipLocal = 0 )
	{
		m_fShotgunReload = false;
		
		BaseClass.Holster( skipLocal );
	}

	void ItemPostFrame()
	{
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

		self.SendWeaponAnim( SAWEDOFF_FIRE, 0, 0 );
		
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "vendetta/weapons/sawedoff/sawedoff_fire.wav", Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0x1f ) );
		
		m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;

		if ( self.m_iClip == 1 ) // Can't have negative ammo
		{
			--self.m_iClip;
		}
		else
		{
			--self.m_iClip;
			--self.m_iClip;
		}

		// player "shoot" animation
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		Vector vecSrc	 = m_pPlayer.GetGunPosition();
		Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

		int m_iBulletDamage = SAWEDOFF_DAMAGE;

		m_pPlayer.FireBullets( 4, vecSrc, vecAiming, VECTOR_CONE_DM_SAWEDOFF, 2048, BULLET_PLAYER_CUSTOMDAMAGE, 0, m_iBulletDamage );

		if ( self.m_iClip != 0 )
			m_flPumpTime = g_Engine.time + 0.5;
			
		m_pPlayer.pev.punchangle.x = -15.0;
		m_pPlayer.pev.velocity = -128 * g_Engine.v_forward; // Knockback!

		self.m_flNextPrimaryAttack = g_Engine.time + SAWEDOFF_MOD_FIRERATE;

		if ( self.m_iClip != 0 )
			self.m_flTimeWeaponIdle = g_Engine.time + 5.0;
		else
			self.m_flNextPrimaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + SAWEDOFF_MOD_FIRERATE;

		m_fShotgunReload = false;
		
		CreatePelletDecals( vecSrc, vecAiming, VECTOR_CONE_DM_SAWEDOFF, SAWEDOFF_SINGLE_PELLETCOUNT );
		
		SetThink( ThinkFunction( this.EjectShell ) ); // Delay the shell ejection a bit
		self.pev.nextthink = g_Engine.time + 0.70;
	}

	void EjectShell()
	{
		iShellModelIndex = g_EngineFuncs.ModelIndex( "models/vendetta/items/shotgunshell.mdl" );

		if ( m_pPlayer is null )
			return;

		g_EntityFuncs.EjectBrass( m_pPlayer.GetOrigin() + (g_Engine.v_right * 10.0) + (g_Engine.v_forward * 15.0), g_Engine.v_right * 30.0 , 0.0f, iShellModelIndex, TE_BOUNCE_SHOTSHELL );
		g_EntityFuncs.EjectBrass( m_pPlayer.GetOrigin() + (g_Engine.v_right * 10.0) + (g_Engine.v_forward * 15.0), g_Engine.v_right * 60.0 , 0.0f, iShellModelIndex, TE_BOUNCE_SHOTSHELL );
	}

	void Reload()
	{
		if ( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 || self.m_iClip == SAWEDOFF_MAX_CLIP )
			return;

		if ( m_flNextReload > g_Engine.time )
			return;

		// don't reload until recoil is done
		if ( self.m_flNextPrimaryAttack > g_Engine.time && !m_fShotgunReload )
			return;

		// check to see if we're ready to reload
		if ( !m_fShotgunReload )
		{
			self.SendWeaponAnim( SAWEDOFF_START_RELOAD, 0, 0 );
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

			if ( self.m_iClip == SAWEDOFF_MAX_CLIP )
			{
				m_fShotgunReload = false;
				return;
			}

			self.SendWeaponAnim( SAWEDOFF_INSERT, 0 );
			m_flNextReload 					= g_Engine.time + SAWEDOFF_MOD_RELOAD;
			self.m_flNextPrimaryAttack 		= g_Engine.time + SAWEDOFF_MOD_RELOAD;
			self.m_flNextSecondaryAttack 	= g_Engine.time + SAWEDOFF_MOD_RELOAD;
			self.m_flTimeWeaponIdle 		= g_Engine.time + SAWEDOFF_MOD_RELOAD;
				
			// Add them to the clip
			self.m_iClip += 1;
			m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );
			
			switch ( Math.RandomLong( 0, 1 ) )
			{
			case 0:
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, "vendetta/weapons/sawedoff/sawedoff_reload1.wav", 1, ATTN_NORM, 0, 85 + Math.RandomLong( 0, 0x1f ) );
				break;
			case 1:
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, "vendetta/weapons/sawedoff/sawedoff_reload2.wav", 1, ATTN_NORM, 0, 85 + Math.RandomLong( 0, 0x1f ) );
				break;
			}
		}

		BaseClass.Reload();
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();

		m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

		if ( self.m_flTimeWeaponIdle < g_Engine.time )
		{
			if ( self.m_iClip == 0 && !m_fShotgunReload && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) != 0 )
			{
				self.Reload();
			}
			else if ( m_fShotgunReload )
			{
				if ( self.m_iClip != SAWEDOFF_MAX_CLIP && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) > 0 )
				{
					self.Reload();
				}
				else
				{
					// reload debounce has timed out
					self.SendWeaponAnim( SAWEDOFF_RELOAD, 0, 0 );

					m_fShotgunReload = false;
					self.m_flTimeWeaponIdle = g_Engine.time + 1.0;
				}
			}
			else
			{
				int iAnim;
				float flRand = g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 0, 1 );
				if ( flRand <= 0.8 )
				{
					iAnim = SAWEDOFF_IDLE;
					self.m_flTimeWeaponIdle = g_Engine.time + (60.0/12.0);// * RANDOM_LONG(2, 5);
				}
				else if ( flRand <= 0.95 )
				{
					iAnim = SAWEDOFF_IDLE;
					self.m_flTimeWeaponIdle = g_Engine.time + (20.0/9.0);
				}
				else
				{
					iAnim = SAWEDOFF_IDLE;
					self.m_flTimeWeaponIdle = g_Engine.time+ (20.0/9.0);
				}
				self.SendWeaponAnim( iAnim, 1, 0 );
			}
		}
	}
}

string GetSawedOffName()
{
	return "weapon_sawedoff";
}

void RegisterSawedOff()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_sawedoff", GetSawedOffName() );
	g_ItemRegistry.RegisterWeapon( GetSawedOffName(), "poke646", "buckshot", "", "ammo_buckshot" );
}
