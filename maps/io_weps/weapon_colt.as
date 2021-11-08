enum DeagleAnimation
{
	DEAGLE_IDLE = 0,
	DEAGLE_SHOOT1,
	DEAGLE_SHOOT2,
	DEAGLE_EMPTY,
	DEAGLE_RELOAD,
	DEAGLE_DRAW
};

const int DEAGLE_DEFAULT_GIVE	= 16;
const int DEAGLE_MAX_CARRY		= 40;
const int DEAGLE_MAX_CLIP		= 8;
const int DEAGLE_WEIGHT			= 7;

class weapon_colt : ScriptBasePlayerWeaponEntity
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
		g_EntityFuncs.SetModel( self, "models/rngstuff/kuilu/weapons/w_colt.mdl" );
		
		self.m_iDefaultAmmo = DEAGLE_DEFAULT_GIVE;
		
		self.FallInit();
	}
	
	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( "models/rngstuff/kuilu/weapons/v_colt.mdl" );
		g_Game.PrecacheModel( "models/rngstuff/kuilu/weapons/w_colt.mdl" );
		g_Game.PrecacheModel( "models/rngstuff/kuilu/weapons/p_colt.mdl" );
		
		m_iShell = g_Game.PrecacheModel( "models/shell.mdl" );
		
		g_Game.PrecacheGeneric( "sound/" + "weapons/dryfire1.wav" );
		g_Game.PrecacheGeneric( "sound/" + "rng/kuilu/weapons/colt_fire.ogg" );
		g_Game.PrecacheGeneric( "sound/" + "rng/kuilu/weapons/colt_clipin.ogg" );
		g_Game.PrecacheGeneric( "sound/" + "rng/kuilu/weapons/colt_clipout.ogg" );
		g_Game.PrecacheGeneric( "sound/" + "rng/kuilu/weapons/colt_slideback.ogg" );
		g_Game.PrecacheGeneric( "sound/" + "rng/kuilu/weapons/colt_slideforward.ogg" );
		g_Game.PrecacheGeneric( "sound/" + "rng/kuilu/weapons/colt_draw.ogg" );
		
		g_SoundSystem.PrecacheSound( "weapons/dryfire_pistol.wav" );
		g_SoundSystem.PrecacheSound( "rng/kuilu/weapons/colt_fire.ogg" );
		g_SoundSystem.PrecacheSound( "rng/kuilu/weapons/colt_clipin.ogg" );
		g_SoundSystem.PrecacheSound( "rng/kuilu/weapons/colt_clipout.ogg" );
		g_SoundSystem.PrecacheSound( "rng/kuilu/weapons/colt_draw.ogg" );
		g_SoundSystem.PrecacheSound( "rng/kuilu/weapons/colt_slideback.ogg" );
		g_SoundSystem.PrecacheSound( "rng/kuilu/weapons/colt_slideforward.ogg" );
		
		g_Game.PrecacheGeneric( "sprites/" + "kuilu/640hud7.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "kuilu/640hud10.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "kuilu/640hud11.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "kuilu/crosshairs.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "kuilu/weapon_colt.txt" );
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= DEAGLE_MAX_CARRY;
		info.iAmmo1Drop	= DEAGLE_MAX_CLIP;
		info.iMaxAmmo2 	= -1;
		info.iAmmo2Drop	= -1;
		info.iMaxClip 	= DEAGLE_MAX_CLIP;
		info.iSlot 		= 1;
		info.iPosition 	= 10;
		info.iFlags 	= 0;
		info.iWeight 	= DEAGLE_WEIGHT;

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
			bResult = self.DefaultDeploy( self.GetV_Model( "models/rngstuff/kuilu/weapons/v_colt.mdl" ), self.GetP_Model( "models/rngstuff/kuilu/weapons/p_colt.mdl" ), DEAGLE_DRAW, "onehanded" );
		
			float deployTime = 1;
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
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.08f;
			return;
		}
		
		if ( self.m_iClip <= 0 )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.08f;
			return;
		}
		
		self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.200;
		
		m_pPlayer.m_iWeaponVolume = BIG_EXPLOSION_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;

		--self.m_iClip;
		
		m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		
		if ( self.m_iClip <= 0 )
		{
			self.SendWeaponAnim( DEAGLE_EMPTY, 0, 0 );
		}
		else
		{
			switch ( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 1 ) )
			{
				case 0: self.SendWeaponAnim( DEAGLE_SHOOT1, 0, 0 ); break;
				case 1: self.SendWeaponAnim( DEAGLE_SHOOT2, 0, 0 ); break;
			}
		}
		
		switch ( Math.RandomLong (0, 1) )
		{
			case 0: g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "rng/kuilu/weapons/colt_fire.ogg", 0.9, ATTN_NORM, 0, PITCH_NORM ); break;
			case 1: g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "rng/kuilu/weapons/colt_fire.ogg", 0.9, ATTN_NORM, 0, PITCH_NORM ); break;
		}
	
		Vector vecSrc	 = m_pPlayer.GetGunPosition();
		Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );
		
		int m_iBulletDamage = 80;
		
		m_pPlayer.FireBullets( 1, vecSrc, vecAiming, VECTOR_CONE_1DEGREES, 8192, BULLET_PLAYER_CUSTOMDAMAGE, 2, m_iBulletDamage );

		if ( self.m_iClip == 0 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );
			
		m_pPlayer.pev.punchangle.x = Math.RandomLong( -2, 2 );

		//self.m_flNextPrimaryAttack = self.m_flNextPrimaryAttack + 0.15f;
		if ( self.m_flNextPrimaryAttack < WeaponTimeBase() )
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.12f;

		self.m_flTimeWeaponIdle = WeaponTimeBase() + Math.RandomFloat( 10, 15 );
		
		TraceResult tr;
		
		float x, y;
		
		g_Utility.GetCircularGaussianSpread( x, y );
		
		Vector vecDir = vecAiming 
						+ x * VECTOR_CONE_1DEGREES.x * g_Engine.v_right 
						+ y * VECTOR_CONE_1DEGREES.y * g_Engine.v_up;

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
       
		//The last 3 parameters are unique for each weapon (this should be using an attachment in the model to get the correct position, but most models don't have that).
		GetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, 15, 10, -6 );
       
		//Lefthanded weapon, so invert the Y axis velocity to match.
		vecShellVelocity.y *= 1;
       
		g_EntityFuncs.EjectBrass( vecShellOrigin, vecShellVelocity, m_pPlayer.pev.angles[ 1 ], m_iShell, TE_BOUNCE_SHELL );
	}
	
	void Reload()
	{
		if( self.m_iClip < DEAGLE_MAX_CLIP )
			BaseClass.Reload();
		self.DefaultReload( DEAGLE_MAX_CLIP, DEAGLE_RELOAD, 2.2, 0 );
	}
	
	void WeaponIdle()
	{
		self.ResetEmptySound();

		m_pPlayer.GetAutoaimVector( AUTOAIM_10DEGREES );
		
		if ( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;
		
		self.SendWeaponAnim( DEAGLE_IDLE );
		self.m_flTimeWeaponIdle = WeaponTimeBase() + Math.RandomFloat( 10, 15 );
	}
}

/*class DeagleAmmoBox : ScriptBasePlayerAmmoEntity
{
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, "models/cs16ammo/50ae/w_50ae.mdl" );
		BaseClass.Spawn();
	}
	
	void Precache()
	{
		g_Game.PrecacheModel( "models/cs16ammo/50ae/w_50ae.mdl" );
		g_Game.PrecacheModel( "models/cs16ammo/50ae/w_50aet.mdl" );
		g_SoundSystem.PrecacheSound( "items/9mmclip1.wav" );
	}

	bool AddAmmo( CBaseEntity@ pither )
	{
		int iGive;
		
		iGive = DEAGLE_DEFAULT_GIVE;
		
		if( pither.GiveAmmo( iGive, "357", DEAGLE_MAX_CARRY ) != -1 )
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "items/9mmclip1.wav", 1, ATTN_NORM );
			return true;
		}
		return false;
	}
}*/

string GetCOLTName()
{
	return "weapon_colt";
}

void RegisterCOLT()
{
	g_CustomEntityFuncs.RegisterCustomEntity( GetCOLTName(), GetCOLTName() );
	g_ItemRegistry.RegisterWeapon( GetCOLTName(), "kuilu", "357", "", "ammo_357" );
}

string GetDeagleAmmoBoxName()
{
	return "357";
}

/*void RegisterDeagleAmmoBox()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "DeagleAmmoBox", GetDeagleAmmoBoxName() );
}
*/