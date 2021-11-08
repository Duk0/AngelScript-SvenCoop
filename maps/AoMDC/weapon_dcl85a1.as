// Afraid of Monsters: Director's Cut Script
// Weapon Script: L85A1 Bullpup
// Author: Zorbos

enum L85A1Animation
{
	L85_LONGIDLE = 0,
	L85_IDLE1,
	L85_LAUNCH,
	L85_RELOAD,
	L85_DEPLOY,
	L85_FIRE1,
	L85_FIRE2,
	L85_FIRE3,
};

const float L85_DAMAGE = 2000.0;
const float L85_MOD_FIRERATE = 0.06;

const int L85_DEFAULT_GIVE 	= -1;
const int L85_MAX_AMMO		= -1;
const int L85_MAX_AMMO2 	= -1;
const int L85_MAX_CLIP 		= -1;
const int L85_WEIGHT 		= -1;

class weapon_dcl85a1 : ScriptBasePlayerWeaponEntity
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}
	
	float m_flNextAnimTime;
	int m_iShell;
	int iShellModelIndex;
	
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, "models/AoMDC/weapons/l85a1/w_dcl85a1.mdl" );

		self.m_iDefaultAmmo = L85_DEFAULT_GIVE;

		self.m_iSecondaryAmmoType = 0;
		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( "models/AoMDC/weapons/l85a1/w_dcl85a1.mdl" );
		g_Game.PrecacheModel( "models/AoMDC/weapons/l85a1/v_dcl85a1.mdl" );
		g_Game.PrecacheModel( "models/AoMDC/weapons/l85a1/p_dcl85a1.mdl" );

		m_iShell = g_Game.PrecacheModel( "models/saw_shell.mdl" );

		//These are played by the model, needs changing there
		g_SoundSystem.PrecacheSound( "AoMDC/weapons/l85a1/l85a1_fire.wav" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= L85_MAX_AMMO;
		info.iMaxAmmo2 	= L85_MAX_AMMO2;
		info.iMaxClip 	= L85_MAX_CLIP;
		info.iSlot 		= 2;
		info.iPosition 	= 7;
		info.iFlags 	= 0;
		info.iWeight 	= L85_WEIGHT;

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

	bool Deploy()
	{
		return self.DefaultDeploy( self.GetV_Model( "models/AoMDC/weapons/l85a1/v_dcl85a1.mdl" ), self.GetP_Model( "models/AoMDC/weapons/l85a1/p_dcl85a1.mdl" ), L85_DEPLOY, "mp5" );
	}
	
	float WeaponTimeBase()
	{
		return g_Engine.time; //g_WeaponFuncs.WeaponTimeBase();
	}

	void PrimaryAttack()
	{
		//--self.m_iClip;
		
		self.SendWeaponAnim( L85_FIRE2, 0, 0 );
		
		m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;
		
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "AoMDC/weapons/l85a1/l85a1_fire.wav", 0.75, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );

		// player "shoot" animation
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		Vector vecSrc	 = m_pPlayer.GetGunPosition();
		Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_2DEGREES );

		int m_iBulletDamage = L85_DAMAGE;

		// optimized multiplayer. Widened to make it easier to hit a moving player
		m_pPlayer.FireBullets( 1, vecSrc, vecAiming, VECTOR_CONE_2DEGREES, 8192, BULLET_PLAYER_CUSTOMDAMAGE, 2, m_iBulletDamage);
			
		//m_pPlayer.pev.punchangle.x = Math.RandomLong( -2, 2 );

		self.m_flNextPrimaryAttack = self.m_flNextPrimaryAttack + L85_MOD_FIRERATE;
		if( self.m_flNextPrimaryAttack < WeaponTimeBase() )
			self.m_flNextPrimaryAttack = WeaponTimeBase() + L85_MOD_FIRERATE;

		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  10, 15 );
		
		TraceResult tr;
		
		float x, y;
		
		g_Utility.GetCircularGaussianSpread( x, y );
		
		Vector vecDir = vecAiming 
						+ x * VECTOR_CONE_2DEGREES.x * g_Engine.v_right 
						+ y * VECTOR_CONE_2DEGREES.y * g_Engine.v_up;

		Vector vecEnd	= vecSrc + vecDir * 4096;

		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );
		
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
		Vector brassOrigin = m_pPlayer.GetGunPosition() + g_Engine.v_forward * 10.0 +
							 g_Engine.v_up * -12.0 +
							 g_Engine.v_right * 10.0;
		Vector brassDir = g_Engine.v_right * Math.RandomFloat(100.0, 150.0) + 
						  g_Engine.v_up * Math.RandomFloat(10.0, 50.0) + 
						  g_Engine.v_forward * Math.RandomFloat(-45.0, 45.0);
		
		g_EntityFuncs.EjectBrass( brassOrigin, brassDir, 0.0f, iShellModelIndex, TE_BOUNCE_SHELL );
	}
}

string GetDCL85A1Name()
{
	return "weapon_dcl85a1";
}

void RegisterDCL85A1()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_dcl85a1", GetDCL85A1Name() );
	g_ItemRegistry.RegisterWeapon( GetDCL85A1Name(), "AoMDC" );
}
