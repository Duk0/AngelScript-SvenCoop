// Afraid of Monsters Classic Script
// Weapon Script: Desert Eagle
// Author: Zorbos

const float DEAGLE_MOD_DAMAGE = 90.0;
const float DEAGLE_MOD_FIRERATE = 0.70;

const float DEAGLE_MOD_DAMAGE_SURVIVAL = 67.0; // Reduce damage by 25% on Survival

const int DEAGLE_DEFAULT_AMMO 	= 6;
const int DEAGLE_MAX_CARRY 	= 18;
const int DEAGLE_MAX_CLIP 		= 6;
const int DEAGLE_WEIGHT 		= 5;

enum DeagleAnimation
{
	DEAGLE_IDLE1 = 0,
	DEAGLE_IDLE2,
	DEAGLE_IDLE3,
	DEAGLE_SHOOT,
	DEAGLE_SHOOT_EMPTY,
	DEAGLE_RELOAD,
	DEAGLE_RELOAD_NOT_EMPTY,
	DEAGLE_DRAW,
	DEAGLE_HOLSTER,
	DEAGLE_ADD_SILENCER
};

class weapon_cldeagle : ScriptBasePlayerWeaponEntity
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}
	
	private bool bSurvivalEnabled = g_SurvivalMode.MapSupportEnabled() && g_SurvivalMode.IsEnabled();
	
	int m_iShell;
	int iShellModelIndex;

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, "models/AoMClassic/weapons/deagle/w_cldeagle.mdl" );
		
		self.m_iDefaultAmmo = DEAGLE_DEFAULT_AMMO;

		self.FallInit();// get ready to fall
	}
	
	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( "models/AoMClassic/weapons/deagle/v_cldeagle.mdl" );
		g_Game.PrecacheModel( "models/AoMClassic/weapons/deagle/w_cldeagle.mdl" );
		g_Game.PrecacheModel( "models/AoMClassic/weapons/deagle/p_cldeagle.mdl" );

		m_iShell = g_Game.PrecacheModel( "models/saw_shell.mdl" ); // brass casing

		g_SoundSystem.PrecacheSound( "AoMClassic/weapons/deagle/deagle_reload.wav" ); // reloading sound
		g_SoundSystem.PrecacheSound( "AoMClassic/weapons/deagle/deagle_slide.wav" ); // reloading sound
		g_SoundSystem.PrecacheSound( "AoMClassic/weapons/deagle/deagle_draw.wav" ); // draw sound
		g_SoundSystem.PrecacheSound( "AoMClassic/weapons/deagle/deagle_fire.wav" ); // firing sound
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
		info.iMaxAmmo1 	= DEAGLE_MAX_CARRY;
		info.iAmmo1Drop	= DEAGLE_MAX_CLIP;
		info.iMaxAmmo2 	= -1;
		info.iAmmo2Drop	= -1;
		info.iMaxClip 	= DEAGLE_MAX_CLIP;
		info.iSlot 		= 3;
		info.iPosition 	= 7;
		info.iFlags 	= 0;
		info.iWeight 	= DEAGLE_WEIGHT;

		return true;
	}

	bool Deploy()
	{
		return self.DefaultDeploy( self.GetV_Model( "models/AoMClassic/weapons/deagle/v_cldeagle.mdl" ), self.GetP_Model( "models/AoMClassic/weapons/deagle/p_cldeagle.mdl" ), DEAGLE_ADD_SILENCER, "onehanded" );
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
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.15;
			return;
		}
	
		if (self.m_iClip == 0)
		{
			self.m_flNextPrimaryAttack = g_Engine.time + DEAGLE_MOD_FIRERATE;
			return;
		}
		else if (self.m_iClip != 0)
		{
			self.SendWeaponAnim( DEAGLE_RELOAD, 0, 0 );
		}
		else
		{
			self.SendWeaponAnim( DEAGLE_RELOAD_NOT_EMPTY, 0, 0 );
		}

		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "AoMClassic/weapons/deagle/deagle_fire.wav", Math.RandomFloat( 0.92, 1.0 ), ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) );

		m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;

		--self.m_iClip;

		// player "shoot" animation
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		Vector vecSrc	 = m_pPlayer.GetGunPosition();
		Vector vecAiming = m_pPlayer.GetAutoaimVector( 0 );

		if ( bSurvivalEnabled )
			m_iBulletDamage = DEAGLE_MOD_DAMAGE_SURVIVAL;
		else
			m_iBulletDamage = DEAGLE_MOD_DAMAGE;

		m_pPlayer.FireBullets( 1, vecSrc, vecAiming, g_vecZero, 8192, BULLET_PLAYER_CUSTOMDAMAGE, 0, m_iBulletDamage );
		self.m_flNextPrimaryAttack = g_Engine.time + DEAGLE_MOD_FIRERATE;
		self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  10, 15 );

		m_pPlayer.pev.punchangle.x = -12.0;
		
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
		
		TraceResult tr;
		float x, y;
		
		g_Utility.GetCircularGaussianSpread( x, y );
		
		Vector vecDir = vecAiming;

		Vector vecEnd	= vecSrc + vecDir * 4096;

		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );
		
		if ( tr.flFraction < 1.0 )
		{
			if ( tr.pHit !is null )
			{
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
				
				if ( pHit is null || pHit.IsBSPModel() )
					g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_357 );
			}
		}
		
		iShellModelIndex = g_EngineFuncs.ModelIndex( "models/saw_shell.mdl" );
		Vector brassOrigin = m_pPlayer.GetGunPosition() + g_Engine.v_forward * 25.0 +
							 g_Engine.v_up * -9.0 +
							 g_Engine.v_right * 10.0;
		Vector brassDir = g_Engine.v_right * Math.RandomFloat(75.0, 100.0) + 
						  g_Engine.v_up * Math.RandomFloat(5.0, 50.0) + 
						  g_Engine.v_forward * Math.RandomFloat(-15.0, 15.0);
		
		g_EntityFuncs.EjectBrass( brassOrigin, brassDir, 0.0f, iShellModelIndex, TE_BOUNCE_SHELL );
	}

	void Reload()
	{
		if ( self.m_iClip == DEAGLE_MAX_CLIP ) // Can't reload if we have a full magazine already!
			return;

		if ( self.m_iClip == 0 )
		{
			self.DefaultReload( DEAGLE_MAX_CLIP, DEAGLE_DRAW, 1.65, 0 );
		}
		else
		{
			self.DefaultReload( 7, DEAGLE_DRAW, 1.65, 0 );
		}
		
		BaseClass.Reload();
		return;
	}
}

string GetCLDeagleName()
{
	return "weapon_cldeagle";
}

void RegisterCLDeagle()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_cldeagle", GetCLDeagleName() );
	g_ItemRegistry.RegisterWeapon( GetCLDeagleName(), "AoMClassic", "357", "", "ammo_357" );
}
