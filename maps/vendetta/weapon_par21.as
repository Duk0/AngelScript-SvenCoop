// Poke646: Vendetta Script
// Weapon Script: PAR-21 Assault Rifle
// Author: Zorbos

const float PAR_MOD_DAMAGE = 15.0;
const float PAR_MOD_FIRERATE = 0.10;

enum PARAnimation
{
	PAR_LONGIDLE = 0,
	PAR_IDLE1,
	PAR_LAUNCH,
	PAR_RELOAD,
	PAR_DEPLOY,
	PAR_FIRE1,
	PAR_FIRE2,
	PAR_FIRE3,
};

const int PAR_DEFAULT_GIVE 	= 30;
const int PAR_MAX_AMMO		= 150;
const int PAR_MAX_AMMO2 	= 10;
const int PAR_MAX_CLIP 		= 30;
const int PAR_WEIGHT 		= 5;

class weapon_par21 : ScriptBasePlayerWeaponEntity
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}

	float m_flNextAnimTime;
	int m_iShell;
	int	m_iSecondaryAmmo;
	int iShellModelIndex;
	
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, "models/vendetta/weapons/par21/w_par21.mdl" );

		self.m_iDefaultAmmo = PAR_DEFAULT_GIVE;

		self.m_iSecondaryAmmoType = 0;
		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( "models/vendetta/weapons/par21/v_par21.mdl" );
		g_Game.PrecacheModel( "models/vendetta/weapons/par21/w_par21.mdl" );
		g_Game.PrecacheModel( "models/vendetta/weapons/par21/p_par21.mdl" );

		m_iShell = g_Game.PrecacheModel( "models/shell.mdl" );

		g_Game.PrecacheModel( "models/vendetta/items/grenade.mdl" );
		g_Game.PrecacheModel( "models/vendetta/items/w_par21_clip.mdl" );
		g_SoundSystem.PrecacheSound( "items/9mmclip1.wav" );           

		//These are played by the model, needs changing there
		g_SoundSystem.PrecacheSound( "vendetta/weapons/par21/par21_fire.wav" );

		g_SoundSystem.PrecacheSound( "vendetta/weapons/par21/par21_gl1.wav" );
		g_SoundSystem.PrecacheSound( "vendetta/weapons/par21/par21_gl2.wav" );
		g_SoundSystem.PrecacheSound( "vendetta/weapons/par21/par21_reload.wav" );

		g_SoundSystem.PrecacheSound( "weapons/dryfire1.wav" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= PAR_MAX_AMMO;
		info.iAmmo1Drop	= PAR_MAX_CLIP;
		info.iMaxAmmo2 	= PAR_MAX_AMMO2;
		info.iAmmo2Drop	= -1;
		info.iMaxClip 	= PAR_MAX_CLIP;
		info.iSlot 		= 1;
		info.iPosition 	= 4;
		info.iFlags 	= 0;
		info.iWeight 	= PAR_WEIGHT;

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
	
	bool PlayEmptySound()
	{
		if ( self.m_bPlayEmptySound )
		{
			self.m_bPlayEmptySound = false;
			
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "weapons/dryfire1.wav", 0.8, ATTN_NORM, 0, PITCH_NORM );
		}
		
		return false;
	}

	bool Deploy()
	{
		return self.DefaultDeploy( self.GetV_Model( "models/vendetta/weapons/par21/v_par21.mdl" ), self.GetP_Model( "models/vendetta/weapons/par21/p_par21.mdl" ), PAR_DEPLOY, "mp5" );
	}
	
	float WeaponTimeBase()
	{
		return g_Engine.time; //g_WeaponFuncs.WeaponTimeBase();
	}

	void PrimaryAttack()
	{
		// don't fire underwater
		if ( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
		{
			self.PlayEmptySound( );
			self.m_flNextPrimaryAttack = WeaponTimeBase() + PAR_MOD_FIRERATE;
			return;
		}

		if ( self.m_iClip <= 0 )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = WeaponTimeBase() + PAR_MOD_FIRERATE;
			return;
		}

		m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;

		--self.m_iClip;
		
		switch ( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 2 ) )
		{
		case 0: self.SendWeaponAnim( PAR_FIRE1, 0, 0 ); break;
		case 1: self.SendWeaponAnim( PAR_FIRE2, 0, 0 ); break;
		case 2: self.SendWeaponAnim( PAR_FIRE3, 0, 0 ); break;
		}
		
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "vendetta/weapons/par21/par21_fire.wav", 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );

		// player "shoot" animation
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		Vector vecSrc	 = m_pPlayer.GetGunPosition();
		Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );
		
		int m_iBulletDamage = PAR_MOD_DAMAGE;
		
		// optimized multiplayer. Widened to make it easier to hit a moving player
		m_pPlayer.FireBullets( 1, vecSrc, vecAiming, VECTOR_CONE_6DEGREES, 8192, BULLET_PLAYER_CUSTOMDAMAGE, 2, m_iBulletDamage );
			
		m_pPlayer.pev.punchangle.x = Math.RandomLong( -2, 2 );

		self.m_flNextPrimaryAttack = self.m_flNextPrimaryAttack + PAR_MOD_FIRERATE;
		if( self.m_flNextPrimaryAttack < WeaponTimeBase() )
			self.m_flNextPrimaryAttack = WeaponTimeBase() + PAR_MOD_FIRERATE;

		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  10, 15 );
		
		TraceResult tr;
		
		float x, y;
		
		g_Utility.GetCircularGaussianSpread( x, y );
		
		Vector vecDir = vecAiming 
						+ x * VECTOR_CONE_6DEGREES.x * g_Engine.v_right 
						+ y * VECTOR_CONE_6DEGREES.y * g_Engine.v_up;

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
		
		iShellModelIndex = g_EngineFuncs.ModelIndex("models/shell.mdl");
		
		g_EntityFuncs.EjectBrass( m_pPlayer.GetGunPosition(), g_Engine.v_right * 100.0 , 0.0f, iShellModelIndex, TE_BOUNCE_SHELL );

		m_pPlayer.pev.effects = EF_MUZZLEFLASH;
	}

	void SecondaryAttack()
	{
		// don't fire underwater
		if ( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.15;
			return;
		}
		
		if ( m_pPlayer.m_rgAmmo(self.m_iSecondaryAmmoType) <= 0 )
		{
			self.PlayEmptySound();
			return;
		}

		m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;

		m_pPlayer.m_iExtraSoundTypes = bits_SOUND_DANGER;
		m_pPlayer.m_flStopExtraSoundTime = WeaponTimeBase() + 0.2;

		m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType ) - 1 );

		m_pPlayer.pev.punchangle.x = -10.0;

		self.SendWeaponAnim( PAR_LAUNCH );

		// player "shoot" animation
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		if ( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 1 ) != 0 )
		{
			// play this sound through BODY channel so we can hear it if player didn't stop firing
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "vendetta/weapons/par21/par21_gl1.wav", 0.8, ATTN_NORM, 0, PITCH_NORM );
		}
		else
		{
			// play this sound through BODY channel so we can hear it if player didn't stop firing
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "vendetta/weapons/par21/par21_gl2.wav", 0.8, ATTN_NORM, 0, PITCH_NORM );
		}
	
		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );

		// we don't add in player velocity anymore.
		if ( ( m_pPlayer.pev.button & IN_DUCK ) != 0 )
		{
			g_EntityFuncs.ShootContact( m_pPlayer.pev, 
								m_pPlayer.pev.origin + g_Engine.v_forward * 12 + g_Engine.v_right * 6, 
								g_Engine.v_forward * 675 ); //800
		}
		else
		{
			g_EntityFuncs.ShootContact( m_pPlayer.pev, 
								m_pPlayer.pev.origin + m_pPlayer.pev.view_ofs * 0.5 + g_Engine.v_forward * 12 + g_Engine.v_right * 6, 
								g_Engine.v_forward * 675 ); //800
		}
		self.m_flNextPrimaryAttack = WeaponTimeBase() + 1;
		self.m_flNextSecondaryAttack = WeaponTimeBase() + 1;
		self.m_flTimeWeaponIdle = WeaponTimeBase() + 5;// idle pretty soon after shooting.
	}

	void Reload()
	{
		if ( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 || self.m_iClip == PAR_MAX_CLIP )
			return;
			
		self.DefaultReload( PAR_MAX_CLIP, PAR_RELOAD, 1.5, 0 );

		//Set 3rd person reloading animation -Sniper
		BaseClass.Reload();
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();

		m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

		if ( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;

		int iAnim;
		switch ( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 1 ) )
		{
		case 0:	
			iAnim = PAR_LONGIDLE;	
			break;
		
		case 1:
			iAnim = PAR_IDLE1;
			break;
			
		default:
			iAnim = PAR_IDLE1;
			break;
		}

		self.SendWeaponAnim( iAnim );

		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 10, 15 );// how long till we do this again.
	}
}

string GetPAR21Name()
{
	return "weapon_par21";
}

void RegisterPAR21()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_par21", GetPAR21Name() );
	g_ItemRegistry.RegisterWeapon( GetPAR21Name(), "vendetta", "9mm", "ARgrenades", "ammo_par21_clip" );
}
