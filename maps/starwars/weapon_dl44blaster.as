#include "proj_blaster"
#include "p_entity"

const int DL44_DEFAULT_GIVE		= 100;
const int DL44_MAX_CARRY			= 300;
const int DL44_MAX_CLIP			= -1;
const int DL44_WEIGHT				= 110;
const int DL44_DAMAGE				= 6;
const int DL44_DROP_GIVE			= 25;

const string DL44_SOUND_DRAW		= "starwars/selectRifleBlaster.wav";
const string DL44_SOUND_FIRE		= "starwars/shootRifleBlaster.wav";
const string DL44_SOUND_EXPLODE		= "starwars/hit_wallRifleBlaster.wav";
const string DL44_SOUND_DRYFIRE		= "starwars/dryfire.wav";

const string DL44_MODEL_NULL		= "models/starwars/p_dl44Null.mdl";
const string DL44_MODEL_VIEW		= "models/starwars/v_dl44.mdl";
const string DL44_MODEL_PLAYER		= "models/starwars/p_dl44.mdl";
const string DL44_MODEL_GROUND		= "models/starwars/w_dl44.mdl";
const string DL44_MODEL_CLIP		= "models/w_weaponbox.mdl";
const string DL44_MODEL_PROJECTILE	= "models/starwars/BlasterShootRed.mdl";

const Vector VECTOR_CONE_DL44( 0.15, 0.15, 0.00 );		// 10 degrees by 5 degrees

enum dl44_e
{
	DL44_IDLE1,
	DL44_FIRE,
	DL44_HOLSTER,
	DL44_DRAW,
	DL44_IDLE2,
	DL44_IDLE3
};

class weapon_dl44blaster : ScriptBasePlayerWeaponEntity
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}
	
	float m_flCoolDown = 0.0;
	int m_iCurrentMode = 0;
	CPEntityController@ m_pController = null;
	
	void Spawn()
	{
		self.Precache();
		g_EntityFuncs.SetModel( self, DL44_MODEL_GROUND );
		self.m_iDefaultAmmo = DL44_DEFAULT_GIVE;
		self.pev.sequence = 1;
		m_iCurrentMode = 0;
		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( DL44_MODEL_NULL );
		g_Game.PrecacheModel( DL44_MODEL_VIEW );
		g_Game.PrecacheModel( DL44_MODEL_PLAYER );
		g_Game.PrecacheModel( DL44_MODEL_GROUND );
		g_Game.PrecacheModel( DL44_MODEL_PROJECTILE );
		g_Game.PrecacheModel( "sprites/spray.spr" );
		g_Game.PrecacheModel( "sprites/starwars/expB1.spr" );
		g_Game.PrecacheModel( "sprites/red.spr" );
		
		g_Game.PrecacheGeneric( "sound/" + DL44_SOUND_DRAW );
		g_Game.PrecacheGeneric( "sound/" + DL44_SOUND_FIRE );
		g_Game.PrecacheGeneric( "sound/" + DL44_SOUND_EXPLODE );
		g_Game.PrecacheGeneric( "sound/" + DL44_SOUND_DRYFIRE );
		g_SoundSystem.PrecacheSound( DL44_SOUND_DRAW );
		g_SoundSystem.PrecacheSound( DL44_SOUND_FIRE );
		g_SoundSystem.PrecacheSound( DL44_SOUND_EXPLODE );
		g_SoundSystem.PrecacheSound( DL44_SOUND_DRYFIRE );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= DL44_MAX_CARRY;
		info.iAmmo1Drop	= DL44_DROP_GIVE;
		info.iMaxAmmo2 	= -1;
		info.iAmmo2Drop	= -1;
		info.iMaxClip 	= DL44_MAX_CLIP;
		info.iSlot 		= 1;
		info.iPosition 	= 6;
		info.iFlags 	= ITEM_FLAG_NOAUTORELOAD;
		info.iWeight 	= DL44_WEIGHT;

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
			@m_pController = SpawnWeaponControllerInPlayer( m_pPlayer, DL44_MODEL_PLAYER );

		return self.DefaultDeploy( self.GetV_Model( DL44_MODEL_VIEW ), self.GetP_Model( DL44_MODEL_PLAYER ), DL44_DRAW, "onehanded" );
	}

	void Holster( int skipLocal = 0 )
	{
		m_pPlayer.m_flNextAttack = WeaponTimeBase() + 0.7;
		self.SendWeaponAnim( DL44_HOLSTER );
		ToggleZoom( 0 );
		m_iCurrentMode = 0;
		m_pPlayer.pev.maxspeed = 0;

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
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, DL44_SOUND_DRYFIRE, 1.0, ATTN_LOW, 0, PITCH_NORM );
			return;
		}
		
		if ( m_pController !is null )
			m_pController.SetAnimAttack();
		
		m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		self.SendWeaponAnim( DL44_FIRE );
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, DL44_SOUND_FIRE, 1.0, ATTN_LOW, 0, 94 + Math.RandomLong( 0, 0xF ) );
		
		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		
		float numRandom1 = Math.RandomFloat( -VECTOR_CONE_DL44.y,VECTOR_CONE_DL44.y ) * m_flCoolDown;
		float numRandom2 = Math.RandomFloat( -VECTOR_CONE_DL44.x,VECTOR_CONE_DL44.x ) * m_flCoolDown;
		
	//	ShootBlasterPistol( m_pPlayer.pev, m_pPlayer.GetGunPosition() + g_Engine.v_forward * 32 + g_Engine.v_up * -4 + g_Engine.v_right * 4, g_Engine.v_forward * 4000 + g_Engine.v_up * numRandom1 * 500 + g_Engine.v_right * numRandom2 * 500 );
		ShootBlasterPistol( m_pPlayer.pev, m_pPlayer.GetGunPosition() + g_Engine.v_up * -4 + g_Engine.v_right * 4, g_Engine.v_forward * 4000 + g_Engine.v_up * numRandom1 * 500 + g_Engine.v_right * numRandom2 * 500 );
		
		Vector vecTemp = m_pPlayer.pev.v_angle;

		vecTemp.x -= 0.5f;
		vecTemp.y += -0.3f + ( m_flCoolDown * 0.5f );
		m_pPlayer.pev.angles = vecTemp;
		m_pPlayer.pev.fixangle = FAM_FORCEVIEWANGLES;
		
		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );
		self.m_flNextPrimaryAttack = g_Engine.time + 0.4;
		self.m_flNextSecondaryAttack = g_Engine.time + 0.3;
		self.m_flTimeWeaponIdle = g_Engine.time + 1.0;
		m_pPlayer.pev.punchangle.x -= 0.2f;
		
		if ( m_flCoolDown < 1.4 )
			m_flCoolDown += 0.2;
		
		SetThink( ThinkFunction( this.CoolDownFire ) );
		self.pev.nextthink = g_Engine.time + 0.3;
	}
	
	void CoolDownFire()
	{	
		if ( m_flCoolDown > 0.0 )
			m_flCoolDown -= 0.7;
		
		if ( m_flCoolDown < 0.0 )
			m_flCoolDown = 0.0;
		
		SetThink( ThinkFunction( this.CoolDownFire ) );
		self.pev.nextthink = g_Engine.time + 0.3;
	}

	void SecondaryAttack()
	{
		self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.3f;
		switch ( m_iCurrentMode )
		{
			case 0:
			{
				m_iCurrentMode = 1;
				m_pPlayer.pev.maxspeed = 150;
				ToggleZoom( 30 );
				break;
			}
			
			case 1:
			{
				m_iCurrentMode = 0;
				m_pPlayer.pev.maxspeed = 0;
				ToggleZoom( 0 );
				break;
			}
		}	
	}
	
	//POST FRAME
	void ItemPostFrame()
	{
		if ( ( m_pPlayer.pev.button & IN_ATTACK ) == 0 )
		{
			// Player released the button, reset now
			self.m_flNextPrimaryAttack = g_Engine.time + 0.05;
		}

		BaseClass.ItemPostFrame();
	}
	
	void ToggleZoom( int zoomedFOV )
	{
		if ( self.m_fInZoom )
		{
			SetFOV( 0 ); // 0 means reset to default fov
		}
		else if ( !self.m_fInZoom )
		{
			SetFOV( zoomedFOV );
		}
	}
	
	void SetFOV( int fov )
	{
		m_pPlayer.pev.fov = m_pPlayer.m_iFOV = fov;
	}

	void WeaponIdle()
	{
		if ( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		self.SendWeaponAnim( DL44_IDLE1 );
		self.m_flTimeWeaponIdle = g_Engine.time + 2.4;
	}

	void Reload()
	{
		if ( self.m_iClip != 0 )
			return;
		
		self.DefaultReload( 1, DL44_HOLSTER, 3.6 );
	}
}

void RegisterDL44Blaster()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_dl44blaster", "weapon_dl44blaster" );
	g_ItemRegistry.RegisterWeapon( "weapon_dl44blaster", "starwars", "blaster", "", "ammo_blaster" );
}
