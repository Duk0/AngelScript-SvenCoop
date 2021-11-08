#include "proj_blaster"
#include "p_entity"

const int E11_DEFAULT_GIVE			= 100;
const int E11_MAX_CARRY			= 300;
const int E11_MAX_CLIP				= -1;
const int E11_WEIGHT				= 110;
const int E11_DAMAGE				= 9;
const int E11_DROP_GIVE			= 25;

const string E11_SOUND_DRAW			= "starwars/selectRifleBlaster.wav";
const string E11_SOUND_FIRE			= "starwars/shootRifleBlaster.wav";
const string E11_SOUND_EXPLODE		= "starwars/hit_wallRifleBlaster.wav";
const string E11_SOUND_DRYFIRE		= "starwars/dryfire.wav";

const string E11_MODEL_NULL			= "models/starwars/p_rifleBlasterNull.mdl";
const string E11_MODEL_VIEW			= "models/starwars/v_rifleBlaster.mdl";
const string E11_MODEL_PLAYER		= "models/starwars/p_rifleBlaster.mdl";
const string E11_MODEL_GROUND		= "models/starwars/w_rifleBlaster.mdl";
//const string E11_MODEL_CLIP			= "models/w_weaponbox.mdl";
const string E11_MODEL_CLIP			= "models/w_gaussammo.mdl";
const string E11_MODEL_PROJECTILE	= "models/starwars/BlasterShootRed.mdl";

const Vector VECTOR_CONE( 0.15, 0.15, 0.00 );		// 10 degrees by 5 degrees

enum e11_e
{
	E11_LONGIDLE,
	E11_IDLE,
	E11_GRENADE,
	E11_RELOAD,
	E11_DRAW,
	E11_FIRE,
	E11_FIRE_SOLID,
	E11_HOLSTER
};

class weapon_e11blaster : ScriptBasePlayerWeaponEntity
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
		g_EntityFuncs.SetModel( self, E11_MODEL_GROUND );
		self.m_iDefaultAmmo = E11_DEFAULT_GIVE;
		self.pev.sequence = 1;
		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( E11_MODEL_NULL );
		g_Game.PrecacheModel( E11_MODEL_VIEW );
		g_Game.PrecacheModel( E11_MODEL_PLAYER );
		g_Game.PrecacheModel( E11_MODEL_GROUND );
		g_Game.PrecacheModel( E11_MODEL_PROJECTILE );
		g_Game.PrecacheModel( "sprites/spray.spr" );
		g_Game.PrecacheModel( "sprites/starwars/expB1.spr" );
		g_Game.PrecacheModel( "sprites/red.spr" );
		g_Game.PrecacheModel( "sprites/white.spr" );
		g_Game.PrecacheModel( "sprites/starwars/blasterboltred.spr" );
		g_Game.PrecacheModel( "sprites/starwars/blasterimpact.spr" );
		
		
		g_Game.PrecacheGeneric( "sound/" + E11_SOUND_DRAW );
		g_Game.PrecacheGeneric( "sound/" + E11_SOUND_FIRE );
		g_Game.PrecacheGeneric( "sound/" + E11_SOUND_EXPLODE );
		g_Game.PrecacheGeneric( "sound/" + E11_SOUND_DRYFIRE );
		g_SoundSystem.PrecacheSound( E11_SOUND_DRAW );
		g_SoundSystem.PrecacheSound( E11_SOUND_FIRE );
		g_SoundSystem.PrecacheSound( E11_SOUND_EXPLODE );
		g_SoundSystem.PrecacheSound( E11_SOUND_DRYFIRE );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= E11_MAX_CARRY;
		info.iAmmo1Drop	= E11_DROP_GIVE;
		info.iMaxAmmo2 	= -1;
		info.iAmmo2Drop	= -1;
		info.iMaxClip 	= E11_MAX_CLIP;
		info.iSlot 		= 2;
		info.iPosition 	= 9;
		info.iFlags 	= ITEM_FLAG_NOAUTORELOAD;
		info.iWeight 	= E11_WEIGHT;

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
			@m_pController = SpawnWeaponControllerInPlayer( m_pPlayer, E11_MODEL_PLAYER );

		return self.DefaultDeploy( self.GetV_Model( E11_MODEL_VIEW ), self.GetP_Model( E11_MODEL_PLAYER ), E11_DRAW, "mp5" );
	}

	void Holster( int skipLocal = 0 )
	{
		m_pPlayer.m_flNextAttack = WeaponTimeBase() + 0.7;
		self.SendWeaponAnim( E11_RELOAD );
		
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
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, E11_SOUND_DRYFIRE, 1.0, ATTN_LOW, 0, PITCH_NORM );
			return;
		}
		
		if ( m_pController !is null )
			m_pController.SetAnimAttack();
		
		m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		self.SendWeaponAnim( E11_FIRE );
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, E11_SOUND_FIRE, 1.0, ATTN_LOW, 0, 94 + Math.RandomLong( 0, 0xF ) );
		
		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		
	//	ShootBlaster( m_pPlayer.pev, m_pPlayer.GetGunPosition() + g_Engine.v_forward * 32 + g_Engine.v_up * -4 + g_Engine.v_right * 3, g_Engine.v_forward * 4000 );
		ShootBlaster( m_pPlayer.pev, m_pPlayer.GetGunPosition() + g_Engine.v_up * -4 + g_Engine.v_right * 3, g_Engine.v_forward * 4000 );
		
		Vector vecTemp = m_pPlayer.pev.v_angle;

		vecTemp.x -= 0.65f;

		switch ( Math.RandomLong( 0, 9 ) )
		{
			case 0: 
			case 2: 
			case 4: 
			case 6: 
			case 8: vecTemp.y += 0.2f; break;
			case 1:
			case 3:
			case 5:
			case 7:
			case 9: vecTemp.y -= 0.2f; break;
		}

		m_pPlayer.pev.angles = vecTemp;
		m_pPlayer.pev.fixangle = FAM_FORCEVIEWANGLES;
		
		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );
		self.m_flNextPrimaryAttack = g_Engine.time + 0.4;
		self.m_flNextSecondaryAttack = g_Engine.time + 0.12;
		self.m_flTimeWeaponIdle = g_Engine.time + 1.0;
		m_pPlayer.pev.punchangle.x -= 0.25;
	}

	void SecondaryAttack()
	{
		if ( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD || m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 1 )
		{
			self.PlayEmptySound();
			self.m_flNextSecondaryAttack = g_Engine.time + 0.5;
			self.m_flNextSecondaryAttack = g_Engine.time + 0.5;
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, E11_SOUND_DRYFIRE, 1.0, ATTN_LOW, 0, PITCH_NORM );
			return;
		}
		
		if ( m_pController !is null )
			m_pController.SetAnimAttack();
		
		m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		self.SendWeaponAnim( E11_FIRE );
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, E11_SOUND_FIRE, 1.0, ATTN_LOW, 0, 94 + Math.RandomLong( 0, 0xF ) );
		
		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		
		float numRandom1 = Math.RandomFloat( -VECTOR_CONE.y, VECTOR_CONE.y ) * m_flCoolDown;
		float numRandom2 = Math.RandomFloat( -VECTOR_CONE.x, VECTOR_CONE.x ) * m_flCoolDown;
		
	//	ShootBlasterAlt( m_pPlayer.pev, m_pPlayer.GetGunPosition() + g_Engine.v_forward * 32 + g_Engine.v_up * -4 + g_Engine.v_right * 3, g_Engine.v_forward * 4000 + g_Engine.v_up * numRandom1 * 500 + g_Engine.v_right * numRandom2 * 500 );
		ShootBlasterAlt( m_pPlayer.pev, m_pPlayer.GetGunPosition() + g_Engine.v_up * -4 + g_Engine.v_right * 3, g_Engine.v_forward * 4000 + g_Engine.v_up * numRandom1 * 500 + g_Engine.v_right * numRandom2 * 500 );
		
		Vector vecTemp = m_pPlayer.pev.v_angle;

		vecTemp.x -= 0.65f;

		switch ( Math.RandomLong( 0, 9 ) )
		{
			case 0: 
			case 2: 
			case 4: 
			case 6: 
			case 8: vecTemp.y += 0.2f; break;
			case 1:
			case 3:
			case 5:
			case 7:
			case 9: vecTemp.y -= 0.2f; break;
		}

		m_pPlayer.pev.angles = vecTemp;
		m_pPlayer.pev.fixangle = FAM_FORCEVIEWANGLES;

		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - 2 );
		self.m_flNextPrimaryAttack = g_Engine.time + 0.4;
		self.m_flNextSecondaryAttack = g_Engine.time + 0.12;
		self.m_flTimeWeaponIdle = g_Engine.time + 1.0;
		m_pPlayer.pev.punchangle.x -= 0.25;
		
		if ( m_flCoolDown < 1.4 )
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

		self.SendWeaponAnim( E11_LONGIDLE );
		self.m_flTimeWeaponIdle = g_Engine.time + 10.0;
	}

	void Reload()
	{
		if ( self.m_iClip != 0 )
			return;
		
		self.DefaultReload( 1, E11_RELOAD, 3.6 );
	}
}

class BlasterAmmoBox : ScriptBasePlayerAmmoEntity
{	
	void Spawn()
	{ 
		Precache();
		g_EntityFuncs.SetModel( self, E11_MODEL_CLIP );
		self.pev.body = 15;
		BaseClass.Spawn();
	}
	
	void Precache()
	{
		g_Game.PrecacheModel( E11_MODEL_CLIP );
		g_SoundSystem.PrecacheSound( "items/9mmclip1.wav" );
	}
	
	bool AddAmmo( CBaseEntity@ pOther )
	{ 
		int iGive = E11_DEFAULT_GIVE;
		
		if ( self.pev.owner !is null )
			iGive = E11_DROP_GIVE;

		if ( pOther.GiveAmmo( iGive, "blaster", E11_MAX_CARRY ) != -1 )
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "items/9mmclip1.wav", 1, ATTN_NORM );
			return true;
		}

		return false;
	}
}

void RegisterE11Blaster()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_e11blaster", "weapon_e11blaster" );
	g_ItemRegistry.RegisterWeapon( "weapon_e11blaster", "starwars", "blaster", "", "ammo_blaster" );
}

void RegisterBlasterAmmoBox()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "BlasterAmmoBox", "ammo_blaster" );
}
