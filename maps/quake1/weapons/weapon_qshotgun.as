const Vector Q1_SG_CONE( 0.04, 0.04, 0 );

const int Q1_SG_AMMO_DEFAULT	= 25;
const int Q1_SG_AMMO_MAX		= 100;
const uint Q1_SG_NPELLETS		= 6;

enum q1_ShotgunAnims
{
	SHOTGUN_IDLE = 0,
	SHOTGUN_SHOOT
};

class weapon_qshotgun : ScriptBasePlayerWeaponEntity
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set	 		{ self.m_hPlayer = EHandle( @value ); }
	}

	private int m_iShell;
//	private CScheduledFunction@ m_pRotFunc = null;

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, "models/quake1/w_shotgun.mdl" );
		self.m_iDefaultAmmo = Q1_SG_AMMO_DEFAULT;
		BaseClass.Spawn();
		self.FallInit();

		self.pev.movetype = MOVETYPE_NONE;
		// i have to use the fucking schedulers for JUST FUCKING ROTATING
		// THE FUCKING ITEMS because somewhere after FallInit() and before
		// the gun respawns a shitton of undocumented things happen and
		// thunks change a lot, so i can't figure out where to place the
		// fucking rotation code
	//	@m_pRotFunc = @g_Scheduler.SetInterval( this, "RotateThink", 0.01, g_Scheduler.REPEAT_INFINITE_TIMES );
		SetThink( ThinkFunction( RotateThink ) );
		self.pev.nextthink = g_Engine.time + 0.01;
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( "models/quake1/v_shotgun.mdl" );
		g_Game.PrecacheModel( "models/quake1/p_shotgun.mdl" );
		g_Game.PrecacheModel( "models/quake1/w_shotgun.mdl" );

		m_iShell = g_Game.PrecacheModel( "models/quake1/shotgunshell.mdl" );

		g_SoundSystem.PrecacheSound( "quake1/weapon.wav" );
		g_SoundSystem.PrecacheSound( "quake1/weapons/shotgun1.wav" );
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
		if ( !BaseClass.AddToPlayer( pPlayer ) )
			return false;

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

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 = Q1_SG_AMMO_MAX;
		info.iAmmo1Drop	= Q1_AMMO_SHELLS_GIVE;
		info.iMaxAmmo2 = -1;
		info.iAmmo2Drop	= -1;
		info.iMaxClip = WEAPON_NOCLIP;
		info.iSlot = 1;
		info.iPosition = 7;
		info.iFlags = 0;
		info.iWeight = 3;

		return true;
	}

	CBasePlayerItem@ DropItem() // Doesn't let the player drop the weapon due "HONK" model
	{
		return null;
	}

	bool Deploy()
	{
		return self.DefaultDeploy(self.GetV_Model( "models/quake1/v_shotgun.mdl" ),
									self.GetP_Model( "models/quake1/p_shotgun.mdl" ), SHOTGUN_IDLE, "shotgun" );
	}

	void CreatePelletDecals( const Vector& in vecSrc, const Vector& in vecAiming, const Vector& in vecSpread, const uint uiPelletCount )
	{
		TraceResult tr;
		float x, y;
		
		for ( uint uiPellet = 0; uiPellet < uiPelletCount; ++uiPellet )
		{
			g_Utility.GetCircularGaussianSpread(x, y);

			Vector vecDir = vecAiming 
					+ x * vecSpread.x * g_Engine.v_right 
					+ y * vecSpread.y * g_Engine.v_up;

			Vector vecEnd = vecSrc + vecDir * 2048;

			g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );

			if ( tr.flFraction < 1.0 )
			{
				if ( tr.pHit !is null )
				{
					CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );

					if ( pHit is null || pHit.IsBSPModel() )
						g_WeaponFuncs.DecalGunshot(tr, BULLET_PLAYER_BUCKSHOT);
				}
			}
		}
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

		self.SendWeaponAnim( SHOTGUN_SHOOT, 0, 0 );
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "quake1/weapons/shotgun1.wav", Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );
		m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;

		--iAmmo;

		// player "shoot" animation
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		Vector vecSrc		= m_pPlayer.GetGunPosition();
		Vector vecAiming	= m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );
		
		int iDamage = 4;
		if ( m_pPlayer.HasNamedPlayerItem( "item_qquad" ) !is null )
		{
			iDamage *= 4;
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, "quake1/quad_s.wav", Math.RandomFloat( 0.69, 0.7 ), ATTN_NORM, 0, 93 + Math.RandomLong( 0, 0xf ) );
		}
		
		m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		self.pev.effects |= EF_MUZZLEFLASH;
		m_pPlayer.FireBullets( Q1_SG_NPELLETS, vecSrc, vecAiming, Q1_SG_CONE, 2048, 
							BULLET_PLAYER_CUSTOMDAMAGE, 0, iDamage );

		Math.MakeVectors( m_pPlayer.pev.v_angle );
		
		Vector vecShellVelocity = m_pPlayer.pev.velocity 
				+ g_Engine.v_right * Math.RandomFloat( 50, 70 ) 
				+ g_Engine.v_up * Math.RandomFloat( 100, 150 ) 
				+ g_Engine.v_forward * 25;
		
		g_EntityFuncs.EjectBrass( vecSrc + m_pPlayer.pev.view_ofs + g_Engine.v_up * -42 + g_Engine.v_forward * 11 + g_Engine.v_right * 5, vecShellVelocity, m_pPlayer.pev.angles.y, m_iShell, TE_BOUNCE_SHOTSHELL );
 
		m_pPlayer.pev.punchangle.x = -3.0;
		self.m_flNextPrimaryAttack = g_Engine.time + 0.5;

		if ( iAmmo != 0 )
			self.m_flTimeWeaponIdle = g_Engine.time + 5.0;
		else
		{
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );
			self.m_flNextPrimaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 0.75;
		}

		q1_AlertMonsters( m_pPlayer, m_pPlayer.pev.origin, 1000 );
		CreatePelletDecals( vecSrc, vecAiming, Q1_SG_CONE, Q1_SG_NPELLETS );
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

void q1_RegisterWeapon_SHOTGUN()
{
	g_CustomEntityFuncs.RegisterCustomEntity("weapon_qshotgun", "weapon_qshotgun");
	g_ItemRegistry.RegisterWeapon("weapon_qshotgun", "quake1/weapons", "buckshot", "", "ammo_qshells");
}
