enum ElitesAnimation
{
	ELITES_IDLE = 0,
	ELITES_IDLE_LEFTEMPTY,
	ELITES_SHOOTLEFT1,
	ELITES_SHOOTLEFT2,
	ELITES_SHOOTLEFT3,
	ELITES_SHOOTLEFT4,
	ELITES_SHOOTLEFT5,
	ELITES_SHOOTLEFTLAST,
	ELITES_SHOOTRIGHT1,
	ELITES_SHOOTRIGHT2,
	ELITES_SHOOTRIGHT3,
	ELITES_SHOOTRIGHT4,
	ELITES_SHOOTRIGHT5,
	ELITES_SHOOTRIGHTLAST,
	ELITES_RELOAD,
	ELITES_DRAW
};

const int ELITES_DEFAULT_GIVE	= 30;
const int ELITES_MAX_CARRY		= 120;
const int ELITES_MAX_CLIP		= 30;
const int ELITES_WEIGHT			= 5;

class weapon_dualglock : ScriptBasePlayerWeaponEntity
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}

	float m_flNextAnimTime;
	int m_iShell;
	
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, "models/rngstuff/kuilu/weapons/w_glock.mdl" );
		
		self.m_iDefaultAmmo = ELITES_DEFAULT_GIVE;
		
		self.FallInit();
	}
	
	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( "models/rngstuff/kuilu/weapons/v_glock.mdl" );
		g_Game.PrecacheModel( "models/rngstuff/kuilu/weapons/w_glock.mdl" );
		g_Game.PrecacheModel( "models/rngstuff/kuilu/weapons/p_glock.mdl" );
		
		m_iShell = g_Game.PrecacheModel( "models/shell.mdl" );
		
		g_Game.PrecacheGeneric( "sound/" + "weapons/dryfire1.wav" );
		g_Game.PrecacheGeneric( "sound/" + "rng/kuilu/weapons/glock_fire.ogg" );
		g_Game.PrecacheGeneric( "sound/" + "rng/kuilu/weapons/glock_draw.ogg" );
		g_Game.PrecacheGeneric( "sound/" + "rng/kuilu/weapons/glock_clipout.ogg" );
		g_Game.PrecacheGeneric( "sound/" + "rng/kuilu/weapons/glock_clipin_left.ogg" );
		g_Game.PrecacheGeneric( "sound/" + "rng/kuilu/weapons/glock_reloadstart.ogg" );
		g_Game.PrecacheGeneric( "sound/" + "rng/kuilu/weapons/glock_clipin_right.ogg" );
		g_Game.PrecacheGeneric( "sound/" + "rng/kuilu/weapons/glock_slide.ogg" );
		
		g_SoundSystem.PrecacheSound( "weapons/dryfire1.wav" );
		g_SoundSystem.PrecacheSound( "rng/kuilu/weapons/glock_fire.ogg" );
		g_SoundSystem.PrecacheSound( "rng/kuilu/weapons/glock_slide.ogg" );
		g_SoundSystem.PrecacheSound( "rng/kuilu/weapons/glock_draw.ogg" );
		g_SoundSystem.PrecacheSound( "rng/kuilu/weapons/glock_clipin_left.ogg" );
		g_SoundSystem.PrecacheSound( "rng/kuilu/weapons/glock_clipout.ogg" );
		g_SoundSystem.PrecacheSound( "rng/kuilu/weapons/glock_reloadstart.ogg" );
		g_SoundSystem.PrecacheSound( "rng/kuilu/weapons/glock_slide.ogg" );
		g_SoundSystem.PrecacheSound( "rng/kuilu/weapons/glock_clipin_right.ogg" );
		
		g_Game.PrecacheGeneric( "sprites/" + "kuilu/640hud7.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "kuilu/640hud14.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "kuilu/640hud15.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "kuilu/crosshairs.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "kuilu/weapon_dualglock.txt" );
		
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= ELITES_MAX_CARRY;
		info.iAmmo1Drop	= ELITES_MAX_CLIP;
		info.iMaxAmmo2 	= -1;
		info.iAmmo2Drop	= -1;
		info.iMaxClip 	= ELITES_MAX_CLIP;
		info.iSlot 		= 4;
		info.iPosition 	= 5;
		info.iFlags 	= 0;
		info.iWeight 	= ELITES_WEIGHT;

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
			
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "weapons/dryfire1.wav", 0.9, ATTN_NORM, 0, PITCH_NORM );
		}
		
		return false;
	}
	
	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy ( self.GetV_Model( "models/rngstuff/kuilu/weapons/v_glock.mdl" ), self.GetP_Model( "models/rngstuff/kuilu/weapons/p_glock.mdl" ), ELITES_DRAW, "uzis" );
			
			float deployTime = 1.1f;
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + deployTime;
			return bResult;
		}
	}
	
	float WeaponTimeBase()
	{
		return g_Engine.time;
	}
	
	void PrimaryAttack()
	{
		if ( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.14f;
			return;
		}
		
		if ( self.m_iClip <= 0 )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.14f;
			return;
		}
		
		self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.14f;
		
		m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;

		--self.m_iClip;
		
		m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		
		int iAnimation;

		if ( self.m_iClip == 1 )
		{
			iAnimation = ELITES_SHOOTLEFTLAST;
		}
		else if ( self.m_iClip == 0 )
		{
			iAnimation = ELITES_SHOOTRIGHTLAST;
		}
		else
		{
			iAnimation = ( ( self.m_iClip % 2 ) == 0 ) ? ELITES_SHOOTRIGHT1 : ELITES_SHOOTLEFT1;

			iAnimation += g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 4 );
		}
		
		self.SendWeaponAnim( iAnimation, 0, 0 );
		
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "rng/kuilu/weapons/glock_fire.ogg", 0.9, ATTN_NORM, 0, PITCH_NORM );
		
		Vector vecSrc	 = m_pPlayer.GetGunPosition();
		Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );
		
		int m_iBulletDamage = 36;
		
		m_pPlayer.FireBullets( 1, vecSrc, vecAiming, VECTOR_CONE_6DEGREES, 8192, BULLET_PLAYER_CUSTOMDAMAGE, 2, m_iBulletDamage );

		if ( self.m_iClip == 0 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );
			
		m_pPlayer.pev.punchangle.x = Math.RandomLong( -2, 2 );

		//self.m_flNextPrimaryAttack = self.m_flNextPrimaryAttack + 0.15f;
		if ( self.m_flNextPrimaryAttack < WeaponTimeBase() )
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.14f;

		self.m_flTimeWeaponIdle = WeaponTimeBase() + Math.RandomFloat( 10, 15 );
		
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
					g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_MP5 );
			}
		}
		
		Vector vecShellVelocity, vecShellOrigin;
		
		if ( iAnimation == ELITES_SHOOTRIGHT1 )
			GetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, 21, -9, -7 );
		else if ( iAnimation == ELITES_SHOOTRIGHT2 )
			GetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, 21, -9, -7 );
		else if ( iAnimation == ELITES_SHOOTRIGHT3 )
			GetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, 21, -9, -7 );
		else if ( iAnimation == ELITES_SHOOTRIGHT4 )
			GetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, 21, -9, -7 );
		else if ( iAnimation == ELITES_SHOOTRIGHT5 )
			GetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, 21, -9, -7 );
		else if ( iAnimation == ELITES_SHOOTRIGHTLAST )
			GetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, 21, -9, -7 );
		else if ( iAnimation == ELITES_SHOOTLEFT1 )
			GetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, 21, 9, -7 );
		else if ( iAnimation == ELITES_SHOOTLEFT2 )
			GetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, 21, 9, -7 );
		else if ( iAnimation == ELITES_SHOOTLEFT3 )
			GetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, 21, 9, -7 );
		else if ( iAnimation == ELITES_SHOOTLEFT4 )
			GetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, 21, 9, -7 );
		else if ( iAnimation == ELITES_SHOOTLEFT5 )
			GetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, 21, 9, -7 );
		else if ( iAnimation == ELITES_SHOOTLEFTLAST )
			GetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, 21, 9, -7 );

		//Lefthanded weapon, so invert the Y axis velocity to match.
		vecShellVelocity.y *= 1;
       
		g_EntityFuncs.EjectBrass( vecShellOrigin, vecShellVelocity, m_pPlayer.pev.angles[ 1 ], m_iShell, TE_BOUNCE_SHELL );
	}
	
	void Reload()
	{
		if ( self.m_iClip < ELITES_MAX_CLIP )
			BaseClass.Reload();
		
		self.DefaultReload( ELITES_MAX_CLIP, ELITES_RELOAD, 4.6, 0 );
		m_pPlayer.m_szAnimExtension = "uzis";
	}
	
	void WeaponIdle()
	{
		self.ResetEmptySound();

		m_pPlayer.GetAutoaimVector( AUTOAIM_10DEGREES );
		
		if ( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;
		
		self.SendWeaponAnim( ELITES_IDLE );
		if ( self.m_iClip == 1 )
		{
			self.SendWeaponAnim( ELITES_IDLE_LEFTEMPTY );
		}
		self.m_flTimeWeaponIdle = WeaponTimeBase() + Math.RandomFloat( 10, 15 );
		m_pPlayer.m_szAnimExtension = "uzis";
	}
}	

string GetELITESName()
{
	return "weapon_dualglock";
}

void RegisterELITES()
{
	g_CustomEntityFuncs.RegisterCustomEntity( GetELITESName(), GetELITESName() );
	g_ItemRegistry.RegisterWeapon( GetELITESName(), "kuilu", "9mm", "", "ammo_uziclip" );
}
