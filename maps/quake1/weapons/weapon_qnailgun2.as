const Vector Q1_NG2_CONE( 0.0, 0.0, 0.0 );
const int Q1_NG2_AMMO_DEFAULT	= 50;
const int Q1_NG2_AMMO_MAX		= 200;

enum q1_Nailgun2Anims
{
	NAILGUN2_IDLE = 0,
	NAILGUN2_SHOOT
};

class weapon_qnailgun2 : ScriptBasePlayerWeaponEntity
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set			{ self.m_hPlayer = EHandle( @value ); }
	}

//	private CScheduledFunction@ m_pRotFunc = null;

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, "models/quake1/w_nailgun2.mdl" );
		self.m_iDefaultAmmo = Q1_NG2_AMMO_DEFAULT;
		BaseClass.Spawn();
		self.FallInit();

		self.pev.movetype = MOVETYPE_NONE;
	//	@m_pRotFunc = @g_Scheduler.SetInterval( this, "RotateThink", 0.01, g_Scheduler.REPEAT_INFINITE_TIMES );
		SetThink( ThinkFunction( RotateThink ) );
		self.pev.nextthink = g_Engine.time + 0.01;
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( "models/quake1/v_nailgun2.mdl" );
		g_Game.PrecacheModel( "models/quake1/p_nailgun2.mdl" );
		g_Game.PrecacheModel( "models/quake1/w_nailgun2.mdl" );
		g_Game.PrecacheModel( "models/quake1/spike.mdl" );

		g_SoundSystem.PrecacheSound( "quake1/weapon.wav" );
		g_SoundSystem.PrecacheSound( "quake1/weapons/nailgun2.wav" );
		g_SoundSystem.PrecacheSound( "weapons/357_cock1.wav" );
		g_SoundSystem.PrecacheSound( "quake1/weapons/tink1.wav" );
	}

	bool PlayEmptySound()
	{
		if ( self.m_bPlayEmptySound )
		{
			self.m_bPlayEmptySound = false;
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "weapons/357_cock1.wav", 0.8, ATTN_NORM, 0, PITCH_NORM );
		}

		return false;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if ( BaseClass.AddToPlayer( pPlayer ) )
		{
			NetworkMessage message( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			message.WriteLong( self.m_iId );
			message.End();
/*
			if ( m_pRotFunc !is null )
			{
				g_Scheduler.RemoveTimer( m_pRotFunc );
				@m_pRotFunc = null;
			}
*/
			SetThink( null );

			@m_pPlayer = pPlayer;

			return true;
		}

		return false;
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 = Q1_NG2_AMMO_MAX;
		info.iAmmo1Drop	= Q1_AMMO_NAILS_GIVE;
		info.iMaxAmmo2 = -1;
		info.iAmmo2Drop	= -1;
		info.iMaxClip = WEAPON_NOCLIP;
		info.iSlot = 2;
		info.iPosition = 8;
		info.iFlags = 0;
		info.iWeight = 4;

		return true;
	}

	bool Deploy()
	{
		return self.DefaultDeploy( self.GetV_Model( "models/quake1/v_nailgun2.mdl" ),
									self.GetP_Model( "models/quake1/p_nailgun2.mdl" ), NAILGUN2_IDLE, "mp5" );
	}

	void PrimaryAttack()
	{
		int iAmmo = m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType );
		if ( iAmmo <= 1 )
		{
			self.m_flNextPrimaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 0.75;
			self.PlayEmptySound();
			return;
		}

		self.SendWeaponAnim( NAILGUN2_SHOOT, 0, 0 );
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "quake1/weapons/nailgun2.wav", Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );
		m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;

		iAmmo -= 2;

		// player "shoot" animation
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		Vector vecSrc		= m_pPlayer.GetGunPosition();
		Vector vecAiming	= m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );
		
		int iDamage = 18;
		if ( m_pPlayer.HasNamedPlayerItem( "item_qquad" ) !is null )
		{
			iDamage *= 4;
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, "quake1/quad_s.wav", Math.RandomFloat( 0.69, 0.7 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );
		}

		m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		self.pev.effects |= EF_MUZZLEFLASH;
		CBaseEntity@ pBolt = q1_ShootCustomProjectile( "projectile_qspike", "models/quake1/spike.mdl", 
														vecSrc, vecAiming * 1024, m_pPlayer.pev.v_angle, m_pPlayer );
		if ( pBolt !is null )
			pBolt.pev.dmg = iDamage;

		m_pPlayer.pev.punchangle.x = -1.0;
		self.m_flNextPrimaryAttack = g_Engine.time + 0.1;

		if ( iAmmo != 0 )
			self.m_flTimeWeaponIdle = g_Engine.time + 5.0;
		else
		{
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );
			self.m_flNextPrimaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 0.75;
		}

		q1_AlertMonsters( m_pPlayer, m_pPlayer.pev.origin, 1000 );
		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, iAmmo );
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();
		BaseClass.WeaponIdle();
	}

	void RotateThink()
	{
		self.pev.nextthink = g_Engine.time + 0.01;
		self.pev.angles.y += 1;

		BaseClass.Think();
	}

	void UpdateOnRemove()
	{
/*		if ( m_pRotFunc !is null )
		{
			g_Scheduler.RemoveTimer( m_pRotFunc );
			@m_pRotFunc = null;
		}
*/
		SetThink( null );

		BaseClass.UpdateOnRemove();
	}
}

void q1_RegisterWeapon_NAILGUN2()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_qnailgun2", "weapon_qnailgun2" );
	g_ItemRegistry.RegisterWeapon( "weapon_qnailgun2", "quake1/weapons", "bolts", "", "ammo_qnails" );
}
