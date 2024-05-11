const int Q1_LG_AMMO_DEFAULT	= 10;
const int Q1_LG_AMMO_MAX		= 100;

enum q1_ThunderAnims
{
	THUNDER_IDLE = 0,
	THUNDER_SHOOT
};

class weapon_qthunder : ScriptBasePlayerWeaponEntity
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set			{ self.m_hPlayer = EHandle( @value ); }
	}

//	private CScheduledFunction@ m_pRotFunc = null;
	private CBeam@ m_pBeam;
	private float m_flNextSound;
	private float m_flNextDamage;
	private bool m_bShooting;

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, "models/quake1/w_thunder.mdl" );
		self.m_iDefaultAmmo = Q1_LG_AMMO_DEFAULT;
		BaseClass.Spawn();
		self.FallInit();

		self.pev.movetype = MOVETYPE_NONE;
	//	@m_pRotFunc = @g_Scheduler.SetInterval( this, "RotateThink", 0.01, g_Scheduler.REPEAT_INFINITE_TIMES );
		SetThink( ThinkFunction( RotateThink ) );
		self.pev.nextthink = g_Engine.time + 0.01;

		m_flNextSound = 0.0;
		m_flNextDamage = 0.0;
		m_bShooting = false;
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( "models/quake1/v_thunder.mdl" );
		g_Game.PrecacheModel( "models/quake1/p_thunder.mdl" );
		g_Game.PrecacheModel( "models/quake1/w_thunder.mdl" );
		g_Game.PrecacheModel( "sprites/laserbeam.spr" );

		g_SoundSystem.PrecacheSound( "quake1/weapon.wav" );
		g_SoundSystem.PrecacheSound( "quake1/weapons/thunder1.wav" );
		g_SoundSystem.PrecacheSound( "quake1/weapons/thunder2.wav" );
		g_SoundSystem.PrecacheSound( "weapons/357_cock1.wav" );
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

			m_bShooting = false;
			@m_pBeam = null;
			@m_pPlayer = pPlayer;

			return true;
		}

		return false;
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 = Q1_LG_AMMO_MAX;
		info.iAmmo1Drop	= Q1_AMMO_ENERGY_GIVE;
		info.iMaxAmmo2 = -1;
		info.iAmmo2Drop	= -1;
		info.iMaxClip = WEAPON_NOCLIP;
		info.iSlot = 4;
		info.iPosition = 8;
		info.iFlags = 0;
		info.iWeight = 4;

		return true;
	}

	bool Deploy()
	{
		m_bShooting = false;
		return self.DefaultDeploy( self.GetV_Model( "models/quake1/v_thunder.mdl" ),
									self.GetP_Model( "models/quake1/p_thunder.mdl" ), THUNDER_IDLE, "shotgun" );
	}

	void PrimaryAttack()
	{
		int iAmmo = m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType );
		if ( iAmmo <= 0 )
		{
			self.m_flNextPrimaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 0.75;
			self.PlayEmptySound();
			return;
		}

		bool bQuad = ( m_pPlayer.HasNamedPlayerItem( "item_qquad" ) !is null );
		bool bDidShoot = !m_bShooting;
		if ( !m_bShooting )
		{
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "quake1/weapons/thunder1.wav", Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );
			m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
			m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;
			m_flNextSound = g_Engine.time + 0.64;
			m_bShooting = true;
		}
		else if ( m_flNextSound <= g_Engine.time )
		{
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "quake1/weapons/thunder2.wav", Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xa) );
			m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
			m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;
			m_flNextSound = g_Engine.time + 0.55;
			bDidShoot = true;
		}

		if ( bDidShoot )
		{
			self.SendWeaponAnim( THUNDER_SHOOT, 0, 0 );
			m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
			if (bQuad)
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, "quake1/quad_s.wav", Math.RandomFloat( 0.69, 0.7 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );
		}

		Vector vecSrc		= m_pPlayer.pev.origin + m_pPlayer.pev.view_ofs + g_Engine.v_forward * 16 - g_Engine.v_up * 16;
		Vector vecAiming	= m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );

		int iDamage = 0;
		if ( m_flNextDamage <= g_Engine.time )
		{
			iDamage = 30;
			--iAmmo;
			if ( bQuad ) iDamage *= 4;
			m_flNextDamage = g_Engine.time + 0.1;
		}

		if ( m_pPlayer.pev.waterlevel >= WATERLEVEL_HEAD )
		{
			Discharge(iAmmo);
			iAmmo = 0;
		}
		else
		{
			UpdateLightning( vecSrc, vecAiming, iDamage );
		}

		m_pPlayer.pev.punchangle.x = -0.5;
		self.m_flNextPrimaryAttack = g_Engine.time + 0.01;

		if ( iAmmo != 0 )
			self.m_flTimeWeaponIdle = g_Engine.time + 5.0;
		else
		{
			m_bShooting = false;
			self.SendWeaponAnim( THUNDER_IDLE, 0, 0 );
			RemoveLightning();
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );
			self.m_flNextPrimaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 0.75;
		}

		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, iAmmo );
	}

	void SecondaryAttack()
	{
		if ( m_bShooting )
		{
			m_bShooting = false;
			self.SendWeaponAnim( THUNDER_IDLE, 0, 0 );
			RemoveLightning();
		}
	}

	void WeaponIdle()
	{
		if ( m_bShooting )
		{
			m_bShooting = false;
			self.SendWeaponAnim(THUNDER_IDLE, 0, 0);
			RemoveLightning();
		}

		self.ResetEmptySound();
		BaseClass.WeaponIdle();
	}

	void Holster()
	{
		m_bShooting = false;
		RemoveLightning();
		BaseClass.Holster();
	}

	void SpawnLightning()
	{
		RemoveLightning();
		@m_pBeam = @g_EntityFuncs.CreateBeam( "sprites/laserbeam.spr", 40 );
		if ( m_pBeam is null )
			return;

		m_pBeam.PointEntInit( self.pev.origin, m_pPlayer );
		m_pBeam.SetBrightness( 300 );
		m_pBeam.SetEndAttachment( 1 );
		m_pBeam.pev.spawnflags |= SF_BEAM_TEMPORARY | SF_BEAM_SPARKSTART;
		// m_pBeam.pev.flags |= FL_SKIPLOCALHOST;
		@m_pBeam.pev.owner = @m_pPlayer.edict();
		m_pBeam.SetScrollRate( 110 );
		m_pBeam.SetNoise( 25 );
	}

	void UpdateLightning( const Vector& in vecSrc, const Vector& in vecAiming, int iDamage )
	{
		TraceResult tr;
		g_Utility.TraceLine( vecSrc, vecSrc + vecAiming * 800, dont_ignore_monsters, m_pPlayer.edict(), tr );

		if ( tr.fAllSolid != 0 )
			return;

		if ( m_pBeam is null )
			SpawnLightning();

		m_pBeam.SetStartPos( tr.vecEndPos );

		if ( iDamage > 0 )
		{
			if ( tr.pHit !is null )
			{
				m_pBeam.DoSparks( tr.vecEndPos, self.pev.origin );

				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );

				if ( pHit !is null )
				{
					g_WeaponFuncs.ClearMultiDamage();
					pHit.TraceAttack( m_pPlayer.pev, iDamage, vecAiming, tr, DMG_SHOCK );
					g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );
				}

				if ( pHit is null || pHit.IsBSPModel() )
					g_WeaponFuncs.DecalGunshot( tr, DECAL_SCORCH_MARK );
			}

			q1_AlertMonsters( m_pPlayer, m_pPlayer.pev.origin, 1000 );
		}
	}

	void RemoveLightning()
	{
		if ( m_pBeam is null )
			return;

		g_EntityFuncs.Remove( m_pBeam );
		@m_pBeam = null;
	}

	void Discharge( int iAmmo )
	{
		g_WeaponFuncs.RadiusDamage( self.pev.origin, m_pPlayer.pev, m_pPlayer.pev, iAmmo, 40.0 + iAmmo, 0, DMG_SHOCK );
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

		RemoveLightning();
		BaseClass.UpdateOnRemove();
	}

	CBasePlayerItem@ DropItem()
	{
		RemoveLightning();
		return BaseClass.DropItem();
	}
}

void q1_RegisterWeapon_THUNDER()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_qthunder", "weapon_qthunder" );
	g_ItemRegistry.RegisterWeapon( "weapon_qthunder", "quake1/weapons", "uranium", "", "ammo_qenergy" );
}
