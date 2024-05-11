// Poke646: Vendetta Script
// Weapon Script: Bow Rifle
// Author: Zorbos

const float CMLWBR_MOD_DAMAGE = 100.0;
const float CMLWBR_MOD_FIRERATE = 1.55;
const int CMLWBR_MOD_PROJ_SPEED = 1000;
const int CMLWBR_MOD_PROJ_SPEED_UNDERWATER = 500;

const int CMLWBR_DEFAULT_AMMO 	= 5;
const int CMLWBR_MAX_CARRY 	= 20;
const int CMLWBR_MAX_CLIP 		= 5;
const int CMLWBR_WEIGHT 		= 5;

enum CMLWBRAnimation
{
	CMLWBR_IDLE1 = 0,
	CMLWBR_IDLE2,
	CMLWBR_FIDGET1,
	CMLWBR_FIDGET2,
	CMLWBR_FIRE,
	CMLWBR_FIRE_LAST,
	CMLWBR_RELOAD,
	CMLWBR_RELOAD_EMPTY,
	CMLWBR_DRAW
};

class weapon_cmlwbr : ScriptBasePlayerWeaponEntity
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}
	
	bool m_fInReload = false;
	int m_iZoomLevel;
	
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, "models/vendetta/weapons/cmlwbr/w_cmlwbr.mdl" );
		
		self.m_iDefaultAmmo = CMLWBR_DEFAULT_AMMO;

		self.FallInit();// get ready to fall
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( "models/vendetta/weapons/cmlwbr/v_cmlwbr.mdl" );
		g_Game.PrecacheModel( "models/vendetta/weapons/cmlwbr/w_cmlwbr.mdl" );
		g_Game.PrecacheModel( "models/vendetta/weapons/cmlwbr/p_cmlwbr.mdl" );

		g_Game.PrecacheModel( "models/vendetta/items/crossbow_bolt.mdl" );

		g_SoundSystem.PrecacheSound( "vendetta/weapons/cmlwbr/cmlwbr_drawback.wav" );
		g_SoundSystem.PrecacheSound( "vendetta/weapons/cmlwbr/cmlwbr_fire.wav" );
		g_SoundSystem.PrecacheSound( "vendetta/weapons/cmlwbr/cmlwbr_reload.wav" );
		g_SoundSystem.PrecacheSound( "vendetta/weapons/cmlwbr/cmlwbr_reload_empty.wav" );
		g_SoundSystem.PrecacheSound( "vendetta/weapons/cmlwbr/cmlwbr_zoom.wav" );
		
		g_SoundSystem.PrecacheSound( "weapons/dryfire1.wav" ); // gun empty sound
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
		info.iMaxAmmo1 	= CMLWBR_MAX_CARRY;
		info.iAmmo1Drop	= CMLWBR_MAX_CLIP;
		info.iMaxAmmo2 	= -1;
		info.iAmmo2Drop	= -1;
		info.iMaxClip 	= CMLWBR_MAX_CLIP;
		info.iSlot 		= 2;
		info.iPosition 	= 5;
		info.iFlags 	= 0;
		info.iWeight 	= CMLWBR_WEIGHT;

		return true;
	}

	bool Deploy()
	{
		m_iZoomLevel = 0; // Reset zoom state
		return self.DefaultDeploy( self.GetV_Model( "models/vendetta/weapons/cmlwbr/v_cmlwbr.mdl" ), self.GetP_Model( "models/vendetta/weapons/cmlwbr/p_cmlwbr.mdl" ), CMLWBR_DRAW, "bow" );
	}

	float WeaponTimeBase()
	{
		return g_Engine.time; //g_WeaponFuncs.WeaponTimeBase();
	}

	void Holster( int skipLocal = 0 )
	{
		if ( m_iZoomLevel == 1 or m_iZoomLevel == 2)
		{
			g_PlayerFuncs.ScreenFade( m_pPlayer, Vector( 0, 0, 0 ), 0.25, 0, 220, FFADE_IN );
			ZoomIn(0);
			m_iZoomLevel = 0;
		}

		self.m_fInReload = false;
		m_pPlayer.m_flNextAttack = WeaponTimeBase() + 0.7f;
		BaseClass.Holster( skipLocal );
	}

	void PrimaryAttack()
	{
		if ( self.m_iClip <= 0 )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = WeaponTimeBase() + CMLWBR_MOD_FIRERATE;
			return;
		}

		m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;

		if ( self.m_iClip == 1 )
			self.SendWeaponAnim( CMLWBR_FIRE_LAST, 0, 0 );
		else
			self.SendWeaponAnim( CMLWBR_FIRE, 0, 0 );

		--self.m_iClip;

		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "vendetta/weapons/cmlwbr/cmlwbr_fire.wav", 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );

		// player "shoot" animation
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		Vector vecBoltOrigin = m_pPlayer.GetGunPosition();
		Vector vecDir = g_Engine.v_forward;
		Vector vecSpeed;

		if ( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
			vecSpeed = vecDir * CMLWBR_MOD_PROJ_SPEED_UNDERWATER;
		else
			vecSpeed = vecDir * CMLWBR_MOD_PROJ_SPEED;

		Vector vecV_Angle = m_pPlayer.pev.v_angle;
		Vector vecAngles = m_pPlayer.pev.angles;
		vecAngles.x = -vecV_Angle.x;
		vecAngles.z = 0;
		
		CBaseEntity@ pBolt = g_EntityFuncs.Create( "crossbow_bolt", vecBoltOrigin, vecAngles, false, m_pPlayer.edict() );
		pBolt.pev.dmg = CMLWBR_MOD_DAMAGE;
		pBolt.pev.velocity = vecSpeed;

		m_pPlayer.pev.punchangle.x = Math.RandomLong( -3, 3 );

		self.m_flNextPrimaryAttack = WeaponTimeBase() + CMLWBR_MOD_FIRERATE;

		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  10, 15 );
	}

	void SecondaryAttack()
	{
		if ( m_iZoomLevel == 0 )
		{
			m_pPlayer.m_szAnimExtension = "sniperscope";

			ZoomIn(35);
			m_iZoomLevel = 1; // Zoom level 1
		}
		else if ( m_iZoomLevel == 1)
		{
			m_pPlayer.m_szAnimExtension = "sniperscope";

			ZoomIn(15);
			m_iZoomLevel = 2; // Zoom level 2
		}
		else
		{
			m_pPlayer.m_szAnimExtension = "sniper";

			ZoomIn(0);
			m_iZoomLevel = 0; // Reset zoom state
		}
		
		self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.50;
		self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.50;
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();

		if ( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;

		int iAnim;
		switch ( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed,  0, 1 ) )
		{
		case 0:	
			iAnim = CMLWBR_FIDGET1;	
			break;
		
		case 1:
			iAnim = CMLWBR_IDLE1;
			break;
			
		default:
			iAnim = CMLWBR_IDLE1;
			break;
		}

		self.SendWeaponAnim( iAnim );

		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  10, 15 );// how long till we do this again.
	}

	bool PlayEmptySound()
	{
		if ( self.m_bPlayEmptySound )
		{
			self.m_bPlayEmptySound = false;
			
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "weapons/dryfire1.wav", 0.8, ATTN_NORM, 0, PITCH_NORM );
		}
		
		return false;
	}

	void ZoomIn( const int iFov )
	{
		m_pPlayer.pev.fov = m_pPlayer.m_iFOV = iFov;
		g_PlayerFuncs.ScreenFade( m_pPlayer, Vector( 0, 0, 0 ), 0.25, 0, 220, FFADE_IN );
		g_SoundSystem.PlaySound( m_pPlayer.edict(), CHAN_WEAPON, "vendetta/weapons/cmlwbr/cmlwbr_zoom.wav", 1.0f, ATTN_NORM, 0, 100, m_pPlayer.entindex() );
	}

	void Reload()
	{
		if ( WeaponTimeBase() < self.m_flNextPrimaryAttack )
			return;
			
		if ( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 || self.m_iClip >= CMLWBR_MAX_CLIP )
			return;
		
		if ( m_iZoomLevel == 0 )
		{
			if ( self.m_iClip == 0 )
				self.DefaultReload( CMLWBR_MAX_CLIP, CMLWBR_RELOAD_EMPTY, 6.2, 0 );
			else
				self.DefaultReload( CMLWBR_MAX_CLIP, CMLWBR_RELOAD, 7.7, 0 );
		}
		else
		{
			g_PlayerFuncs.ScreenFade( m_pPlayer, Vector( 0, 0, 0 ), 0.25, 0, 220, FFADE_IN );
			ZoomIn(0);
			m_iZoomLevel = 0;
			m_pPlayer.m_szAnimExtension = "sniper";

			if ( self.m_iClip == 0 )
				self.DefaultReload( CMLWBR_MAX_CLIP, CMLWBR_RELOAD_EMPTY, 6.2, 0 );
			else
				self.DefaultReload( CMLWBR_MAX_CLIP, CMLWBR_RELOAD, 7.7, 0 );
		}

		BaseClass.Reload();
		return;
	}
}

string GetCmlwbrName()
{
	return "weapon_cmlwbr";
}

void RegisterCmlwbr()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_cmlwbr", GetCmlwbrName() );
	g_ItemRegistry.RegisterWeapon( GetCmlwbrName(), "vendetta", "bolts", "", "ammo_crossbow" );
}
