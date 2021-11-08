// Afraid of Monsters Classic Script
// Weapon Script: Beretta
// Author: Zorbos

const float BERETTA_MOD_DAMAGE = 17.0;
const float BERETTA_MOD_FIRERATE = 0.30;

const float BERETTA_MOD_DAMAGE_SURVIVAL = 13.0; // Reduce damage by 25% on Survival

const int BERETTA_DEFAULT_AMMO 	= 17;
const int BERETTA_MAX_CARRY 	= 150;
const int BERETTA_MAX_CLIP 		= 17;
const int BERETTA_WEIGHT 		= 5;

enum BERETTAAnimation
{
	BERETTA_IDLE1 = 0,
	BERETTA_IDLE2,
	BERETTA_IDLE3,
	BERETTA_SHOOT,
	BERETTA_SHOOT_EMPTY,
	BERETTA_RELOAD,
	BERETTA_RELOAD_NOT_EMPTY,
	BERETTA_DRAW,
	BERETTA_HOLSTER,
	BERETTA_ADD_SILENCER
};

class weapon_clberetta : ScriptBasePlayerWeaponEntity
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
		g_EntityFuncs.SetModel( self, "models/AoMClassic/weapons/beretta/w_clberetta.mdl" );
		
		self.m_iDefaultAmmo = BERETTA_DEFAULT_AMMO;

		self.FallInit();// get ready to fall
	}
	
	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( "models/AoMClassic/weapons/beretta/v_clberetta.mdl" );
		g_Game.PrecacheModel( "models/AoMClassic/weapons/beretta/w_clberetta.mdl" );
		g_Game.PrecacheModel( "models/AoMClassic/weapons/beretta/p_clberetta.mdl" );

		m_iShell = g_Game.PrecacheModel( "models/shell.mdl" ); // brass casing

		g_SoundSystem.PrecacheSound( "AoMClassic/weapons/beretta/beretta_clipin.wav" ); // reloading sound
		g_SoundSystem.PrecacheSound( "AoMClassic/weapons/beretta/beretta_clipout.wav" ); // reloading sound
		g_SoundSystem.PrecacheSound( "AoMClassic/weapons/beretta/beretta_slide.wav" ); // reloading sound
		g_SoundSystem.PrecacheSound( "AoMClassic/weapons/beretta/beretta_reload.wav" ); // reloading sound

		g_SoundSystem.PrecacheSound( "AoMClassic/weapons/beretta/beretta_fire.wav" ); // firing sound
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
		info.iMaxAmmo1 	= BERETTA_MAX_CARRY;
		info.iAmmo1Drop	= BERETTA_MAX_CLIP;
		info.iMaxAmmo2 	= -1;
		info.iAmmo2Drop	= -1;
		info.iMaxClip 	= BERETTA_MAX_CLIP;
		info.iSlot 		= 1;
		info.iPosition 	= 6;
		info.iFlags 	= 0;
		info.iWeight 	= BERETTA_WEIGHT;

		return true;
	}

	bool Deploy()
	{
		return self.DefaultDeploy( self.GetV_Model( "models/AoMClassic/weapons/beretta/v_clberetta.mdl" ), self.GetP_Model( "models/AoMClassic/weapons/beretta/p_clberetta.mdl" ), BERETTA_DRAW, "onehanded" );
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
		
		if ( self.m_iClip == 0 )
		{
			self.m_flNextPrimaryAttack = g_Engine.time + BERETTA_MOD_FIRERATE;
			return;
		}
		else if ( self.m_iClip != 0 )
		{
			self.SendWeaponAnim( BERETTA_SHOOT, 0, 0 );
		}
		else
		{
			self.SendWeaponAnim( BERETTA_SHOOT_EMPTY, 0, 0 );
		}

		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "AoMClassic/weapons/beretta/beretta_fire.wav", Math.RandomFloat( 0.92, 1.0 ), ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) );

		m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;

		--self.m_iClip;

		// player "shoot" animation
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		Vector vecSrc	 = m_pPlayer.GetGunPosition();
		Vector vecAiming = m_pPlayer.GetAutoaimVector( 0 );

		if ( bSurvivalEnabled )
			m_iBulletDamage = BERETTA_MOD_DAMAGE_SURVIVAL;
		else
			m_iBulletDamage = BERETTA_MOD_DAMAGE;

		m_pPlayer.FireBullets( 1, vecSrc, vecAiming, g_vecZero, 8192, BULLET_PLAYER_CUSTOMDAMAGE, 0, m_iBulletDamage );
		self.m_flNextPrimaryAttack = g_Engine.time + BERETTA_MOD_FIRERATE;
		self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  10, 15 );

		m_pPlayer.pev.punchangle.x = -2.0;
		
		NetworkMessage mFlash( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
			mFlash.WriteByte( TE_DLIGHT );
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
		
		Vector vecDir = vecAiming;

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
		
		iShellModelIndex = g_EngineFuncs.ModelIndex( "models/shell.mdl" );
		Vector brassOrigin = m_pPlayer.GetGunPosition() + g_Engine.v_forward * 22.0 +
							 g_Engine.v_up * -5.0 +
							 g_Engine.v_right * 11.0;
		Vector brassDir = g_Engine.v_right * Math.RandomFloat(75.0, 150.0) + 
						  g_Engine.v_up * Math.RandomFloat(10.0, 40.0) + 
						  g_Engine.v_forward * Math.RandomFloat(-35.0, 35.0);
		
		g_EntityFuncs.EjectBrass( brassOrigin, brassDir, 0.0f, iShellModelIndex, TE_BOUNCE_SHELL );
	}

	void Reload()
	{
		if ( self.m_iClip == BERETTA_MAX_CLIP ) // Can't reload if we have a full magazine already!
			return;

		if ( self.m_iClip == 0 )
		{
			self.DefaultReload( BERETTA_MAX_CLIP, BERETTA_RELOAD, 2.30, 0 );
		}
		else
		{
			self.DefaultReload( 18, BERETTA_RELOAD_NOT_EMPTY, 1.80, 0 );
		}
		
		BaseClass.Reload();
		return;
	}
}

string GetCLBerettaName()
{
	return "weapon_clberetta";
}

void RegisterCLBeretta()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_clberetta", GetCLBerettaName() );
	g_ItemRegistry.RegisterWeapon( GetCLBerettaName(), "AoMClassic", "9mm", "", "ammo_9mmclip" );
}
