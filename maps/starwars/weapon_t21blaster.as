#include "proj_blaster"
#include "p_entity"

const int T21_DEFAULT_GIVE			= 50;
const int T21_MAX_CARRY			= 100;
const int T21_MAX_CLIP				= -1;
const int T21_WEIGHT				= 110;
const int T21_DAMAGE				= 24;
const int T21_DROP_GIVE			= 10;

const string T21_SOUND_DRAW			= "starwars/selectBowcaster.wav";
const string T21_SOUND_FIRE1		= "starwars/fireT21.wav";
const string T21_SOUND_DRYFIRE		= "starwars/dryfire.wav";

const string T21_MODEL_NULL			= "models/not_precached.mdl";
const string T21_MODEL_VIEW			= "models/starwars/v_t21.mdl";
const string T21_MODEL_PLAYER		= "models/starwars/p_t21.mdl";
const string T21_MODEL_GROUND		= "models/starwars/w_t21.mdl";
const string T21_MODEL_CLIP			= "models/w_weaponbox.mdl";
const string T21_MODEL_PROJECTILE	= "models/starwars/HighPowerBlasterShootRed.mdl";

const Vector VECTOR_CONE_T21( 0.10, 0.10, 0.00 );

enum t21_e
{
	T21_IDLE1,
	T21_IDLE2,
	T21_DRAW,
	T21_FIRE1,
	T21_FIRE2,
	T21_FIRE3
};

class weapon_t21blaster : ScriptBasePlayerWeaponEntity
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}
	
	float m_flCoolDown = 0.0;
	CPEntityController@ m_pController = null;
	
	void Spawn()
	{
		self.Precache();
		g_EntityFuncs.SetModel( self, T21_MODEL_GROUND );
		self.m_iDefaultAmmo = T21_DEFAULT_GIVE;
		self.pev.sequence = 1;
		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( T21_MODEL_NULL );
		g_Game.PrecacheModel( T21_MODEL_VIEW );
		g_Game.PrecacheModel( T21_MODEL_PLAYER );
		g_Game.PrecacheModel( T21_MODEL_GROUND );
		g_Game.PrecacheModel( T21_MODEL_PROJECTILE );
		g_Game.PrecacheModel( "sprites/spray.spr" );
		g_Game.PrecacheModel( "sprites/starwars/expB1.spr" );
		g_Game.PrecacheModel( "sprites/red.spr" );
		
		g_Game.PrecacheGeneric( "sound/" + T21_SOUND_DRAW );
		g_Game.PrecacheGeneric( "sound/" + T21_SOUND_FIRE1 );
		g_Game.PrecacheGeneric( "sound/" + T21_SOUND_DRYFIRE );
		
		g_SoundSystem.PrecacheSound( T21_SOUND_DRAW );
		g_SoundSystem.PrecacheSound( T21_SOUND_FIRE1 );
		g_SoundSystem.PrecacheSound( T21_SOUND_DRYFIRE );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= T21_MAX_CARRY;
		info.iAmmo1Drop	= T21_DROP_GIVE;
		info.iMaxAmmo2 	= -1;
		info.iAmmo2Drop	= -1;
		info.iMaxClip 	= T21_MAX_CLIP;
		info.iSlot 		= 4;
		info.iPosition 	= 9;
		info.iFlags 	= ITEM_FLAG_NOAUTORELOAD;
		info.iWeight 	= T21_WEIGHT;

		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if ( BaseClass.AddToPlayer( pPlayer ) )
		{
			@m_pPlayer = pPlayer;
			NetworkMessage message( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			message.WriteLong( self.m_iId );
			message.End();
			return true;
		}
		
		return false;
	}
	
	bool Deploy()
	{
		if ( m_pController is null )
			@m_pController = SpawnWeaponControllerInPlayer( m_pPlayer, T21_MODEL_PLAYER );

		return self.DefaultDeploy( self.GetV_Model( T21_MODEL_VIEW ), self.GetP_Model( T21_MODEL_PLAYER ), T21_DRAW, "gauss" );	
	}

	void Holster( int skipLocal = 0 )
	{
		m_pPlayer.m_flNextAttack = WeaponTimeBase() + 0.7;
		
		if ( m_pController !is null )
		{
			m_pController.DeletePEntity();
			@m_pController = null;
		}
		
		SetThink( null );
	}
	
	float WeaponTimeBase()
	{
		return g_Engine.time;
	}
	
	void PrimaryAttack()
	{

		if ( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD || m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = g_Engine.time + 0.5;
			self.m_flNextSecondaryAttack = g_Engine.time + 0.5;
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, T21_SOUND_DRYFIRE, 1.0, ATTN_LOW, 0, PITCH_NORM );
			return;
		}
		
		if ( m_pController !is null )
			m_pController.SetAnimAttack();
		
		m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		
		int iAnim;
		switch ( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 2 ) )
		{
			case 0:
			{
				iAnim = T21_FIRE1;
				self.m_flTimeWeaponIdle = g_Engine.time + 0.4;
				break;
			}
			case 1:
			{
				iAnim = T21_FIRE2;
				self.m_flTimeWeaponIdle = g_Engine.time + 0.4;
				break;
			}
			case 2:
			{
				iAnim = T21_FIRE3;
				self.m_flTimeWeaponIdle = g_Engine.time + 0.4;
				break;
			}
		}
		
		self.SendWeaponAnim( iAnim );
		
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, T21_SOUND_FIRE1, 1.0, ATTN_LOW, 0, 94 + Math.RandomLong( 0, 0xF ) );
		
		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		
		float numRandom1 = Math.RandomFloat( -VECTOR_CONE.y, VECTOR_CONE.y ) * m_flCoolDown;
		float numRandom2 = Math.RandomFloat( -VECTOR_CONE.x, VECTOR_CONE.x ) * m_flCoolDown;
		
	//	ShootBlasterT21( m_pPlayer.pev, m_pPlayer.GetGunPosition() + g_Engine.v_forward * 32 + g_Engine.v_up * -4 + g_Engine.v_right * 4, g_Engine.v_forward * 4000 + g_Engine.v_up * numRandom1 * 500 + g_Engine.v_right * numRandom2 * 500 );
		ShootBlasterT21( m_pPlayer.pev, m_pPlayer.GetGunPosition() + g_Engine.v_up * -4 + g_Engine.v_right * 4, g_Engine.v_forward * 4000 + g_Engine.v_up * numRandom1 * 500 + g_Engine.v_right * numRandom2 * 500 );
		
		Vector vecTemp;
		vecTemp = m_pPlayer.pev.v_angle;

		vecTemp.x -= 1.0f;
		vecTemp.y += 0.5f - ( m_flCoolDown * 0.5f );
		m_pPlayer.pev.angles = vecTemp;
		m_pPlayer.pev.fixangle = FAM_FORCEVIEWANGLES;
		
		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );
		self.m_flNextPrimaryAttack = g_Engine.time + 0.2;
		self.m_flNextSecondaryAttack = g_Engine.time + 0.2;
		self.m_flNextTertiaryAttack = g_Engine.time + 0.2;
		self.m_flTimeWeaponIdle = g_Engine.time + 0.4;
		m_pPlayer.pev.punchangle.x -= 0.5f;
		
		if ( m_flCoolDown < 1.0 )
			m_flCoolDown += 0.1;
		
		SetThink( ThinkFunction( this.CoolDownFire ) );
		self.pev.nextthink = g_Engine.time + 0.2;

	}

	void CoolDownFire()
	{	
		if ( m_flCoolDown > 0.0 )
			m_flCoolDown -= 0.7;
		
		if ( m_flCoolDown < 0.0 )
			m_flCoolDown = 0.0;
		
		SetThink( ThinkFunction( this.CoolDownFire ) );
		self.pev.nextthink = g_Engine.time + 0.2;
	}
	
	void WeaponIdle()
	{
		if ( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		int iAnim;
		switch ( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed,  0, 1 ) )
		{
			case 0:
			{
				iAnim = T21_IDLE1;
				self.m_flTimeWeaponIdle = g_Engine.time + 3;
				break;
			}
			case 1:
			{
				iAnim = T21_IDLE2;
				self.m_flTimeWeaponIdle = g_Engine.time + 3;
				break;
			}
		}
		
		self.SendWeaponAnim( iAnim );		
	}

	void Reload()
	{
		if ( self.m_iClip != 0 )
			return;
		
		self.DefaultReload( 1, T21_DRAW, 3.6 );
	}
}

void RegisterT21Blaster()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_t21blaster", "weapon_t21blaster" );
	g_ItemRegistry.RegisterWeapon( "weapon_t21blaster", "starwars", "highpowerblaster", "", "ammo_highpowerblaster" );
}
