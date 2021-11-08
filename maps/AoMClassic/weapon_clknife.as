// Afraid of Monsters Classic Script
// Weapon Script: Knife
// Author: Zorbos

const float KNIFE_MOD_DAMAGE = 12.0;
const float KNIFE_MOD_ATKSPEED = 0.25;

const float KNIFE_MOD_DAMAGE_SURVIVAL = 9.0; // Reduce damage by 25% on Survival

enum knife_e
{
	KNIFE_IDLE = 0,
	KNIFE_DRAW,
	KNIFE_HOLSTER,
	KNIFE_ATTACK1HIT,
	KNIFE_ATTACK1MISS,
	KNIFE_ATTACK2MISS,
	KNIFE_ATTACK2HIT,
	KNIFE_ATTACK3MISS,
	KNIFE_ATTACK3HIT
};

class weapon_clknife : ScriptBasePlayerWeaponEntity
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}
	
	private bool bSurvivalEnabled = g_SurvivalMode.MapSupportEnabled() && g_SurvivalMode.IsEnabled();
	
	int m_iSwing;
	TraceResult m_trHit;
	
	void Spawn()
	{
		self.Precache();
		g_EntityFuncs.SetModel( self, self.GetW_Model( "models/AoMClassic/weapons/knife/w_clknife.mdl") );
		self.m_iClip			= -1;
		self.m_flCustomDmg		= self.pev.dmg;

		self.FallInit();// get ready to fall down.
	}

	void Precache()
	{
		self.PrecacheCustomModels();

		g_Game.PrecacheModel( "models/AoMClassic/weapons/knife/v_clknife.mdl" );
		g_Game.PrecacheModel( "models/AoMClassic/weapons/knife/w_clknife.mdl" );
		g_Game.PrecacheModel( "models/AoMClassic/weapons/knife/p_clknife.mdl" );

		g_SoundSystem.PrecacheSound( "AoMClassic/weapons/knife/knife_hit1.wav" );
		g_SoundSystem.PrecacheSound( "AoMClassic/weapons/knife/knife_hit2.wav" );
		g_SoundSystem.PrecacheSound( "AoMClassic/weapons/knife/knife_hitbod1.wav" );
		g_SoundSystem.PrecacheSound( "AoMClassic/weapons/knife/knife_hitbod2.wav" );
		g_SoundSystem.PrecacheSound( "AoMClassic/weapons/knife/knife_hitbod3.wav" );
		g_SoundSystem.PrecacheSound( "AoMClassic/weapons/knife/knife_miss1.wav" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1		= -1;
		info.iMaxAmmo2		= -1;
		info.iMaxClip		= WEAPON_NOCLIP;
		info.iSlot			= 0;
		info.iPosition		= 5;
		info.iWeight		= 0;
		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer( pPlayer ) )
			return false;
			
		@m_pPlayer = pPlayer;

		return true;
	}
	
	bool Deploy()
	{
		return self.DefaultDeploy( self.GetV_Model( "models/AoMClassic/weapons/knife/v_clknife.mdl" ), self.GetP_Model( "models/AoMClassic/weapons/knife/p_clknife.mdl" ), KNIFE_DRAW, "crowbar" );
	}

	void Holster( int skiplocal /* = 0 */ )
	{
		self.m_fInReload = false;// cancel any reload in progress.
		m_pPlayer.m_flNextAttack = g_WeaponFuncs.WeaponTimeBase() + 0.5;

		// Fix for the SendWeaponAnim crash
		SetThink( null );
	}
	
	void PrimaryAttack()
	{
		if ( !Swing( 1 ) )
		{
			SetThink( ThinkFunction( this.SwingAgain ) );
			self.pev.nextthink = g_Engine.time + 0.1;
		}
	}
	
	void Smack()
	{
		g_WeaponFuncs.DecalGunshot( m_trHit, BULLET_PLAYER_CROWBAR );
	}

	void SwingAgain()
	{
		Swing( 0 );
	}

	bool Swing( int fFirst )
	{
		float flDamage;
		bool fDidHit = false;

		TraceResult tr;

		Math.MakeVectors( m_pPlayer.pev.v_angle );
		Vector vecSrc	= m_pPlayer.GetGunPosition();
		Vector vecEnd	= vecSrc + g_Engine.v_forward * 32;

		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );
		
		if ( tr.flFraction >= 1.0 )
		{
			g_Utility.TraceHull( vecSrc, vecEnd, dont_ignore_monsters, head_hull, m_pPlayer.edict(), tr );
			if ( tr.flFraction < 1.0 )
			{
				// Calculate the point of intersection of the line (or hull) and the object we hit
				// This is and approximation of the "best" intersection
				if ( tr.pHit !is null )
				{
					CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
					if ( pHit is null || pHit.IsBSPModel() )
						g_Utility.FindHullIntersection( vecSrc, tr, tr, VEC_DUCK_HULL_MIN, VEC_DUCK_HULL_MAX, m_pPlayer.edict() );
				}
				vecEnd = tr.vecEndPos;	// This is the point on the actual surface (the hull could have hit space)
			}

			if ( fFirst != 0 )
			{
				// miss
				switch ( ( m_iSwing++ ) % 3 )
				{
				case 0:
					self.SendWeaponAnim( KNIFE_ATTACK1MISS ); break;
				case 1:
					self.SendWeaponAnim( KNIFE_ATTACK2MISS ); break;
				case 2:
					self.SendWeaponAnim( KNIFE_ATTACK3MISS ); break;
				}
				self.m_flNextPrimaryAttack = g_Engine.time + 0.5;
				// play wiff or swish sound
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "AoMClassic/weapons/knife/knife_miss1.wav", 1, ATTN_NORM, 0, 94 + Math.RandomLong( 0,0xF ) );

				// player "shoot" animation
				m_pPlayer.SetAnimation( PLAYER_ATTACK1 ); 
			}
		}
		else
		{
			// hit
			fDidHit = true;
			
			CBaseEntity@ pEntity = null;
			
			if ( tr.pHit !is null )
				@pEntity = g_EntityFuncs.Instance( tr.pHit );

			switch ( ( ( m_iSwing++ ) % 2 ) + 1 )
			{
			case 0:
				self.SendWeaponAnim( KNIFE_ATTACK1HIT ); break;
			case 1:
				self.SendWeaponAnim( KNIFE_ATTACK2HIT ); break;
			case 2:
				self.SendWeaponAnim( KNIFE_ATTACK3HIT ); break;
			}

			// player "shoot" animation
			m_pPlayer.SetAnimation( PLAYER_ATTACK1 ); 

			// AdamR: Custom damage option
			if ( bSurvivalEnabled )
				flDamage = KNIFE_MOD_DAMAGE_SURVIVAL;
			else
				flDamage = KNIFE_MOD_DAMAGE;
				
			if ( self.m_flCustomDmg > 0 )
				flDamage = self.m_flCustomDmg;
			// AdamR: End

			g_WeaponFuncs.ClearMultiDamage();

			if ( pEntity !is null )
			{
				if ( self.m_flNextPrimaryAttack + 1 < g_Engine.time )
				{
					// first swing does full damage
					pEntity.TraceAttack( m_pPlayer.pev, flDamage, g_Engine.v_forward, tr, DMG_CLUB );  
				}
				else
				{
					// subsequent swings do 50% (Changed -Sniper) (Half)
					pEntity.TraceAttack( m_pPlayer.pev, flDamage * 0.5, g_Engine.v_forward, tr, DMG_CLUB );  
				}
			}	
			g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );

			//m_flNextPrimaryAttack = gpGlobals->time + 0.30; //0.25

			// play thwack, smack, or dong sound
			float flVol = 1.0;
			bool fHitWorld = true;

			if ( pEntity !is null )
			{
				self.m_flNextPrimaryAttack = g_Engine.time + KNIFE_MOD_ATKSPEED; //0.25

				if ( pEntity.Classify() != CLASS_NONE && pEntity.Classify() != CLASS_MACHINE && pEntity.BloodColor() != DONT_BLEED )
				{
	// aone
					if ( pEntity.IsPlayer() )		// lets pull them
					{
						pEntity.pev.velocity = pEntity.pev.velocity + ( self.pev.origin - pEntity.pev.origin ).Normalize() * 120;
					}
	// end aone
					// play thwack or smack sound
					switch ( Math.RandomLong( 0, 2 ) )
					{
					case 0:
						g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "AoMClassic/weapons/knife/knife_hitbod1.wav", 1, ATTN_NORM ); break;
					case 1:
						g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "AoMClassic/weapons/knife/knife_hitbod2.wav", 1, ATTN_NORM ); break;
					case 2:
						g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "AoMClassic/weapons/knife/knife_hitbod3.wav", 1, ATTN_NORM ); break;
					}

					m_pPlayer.m_iWeaponVolume = 128;

					if ( !pEntity.IsAlive() )
						return true;
					else
						flVol = 0.1;

					fHitWorld = false;
				}
			}

			// play texture hit sound
			// UNDONE: Calculate the correct point of intersection when we hit with the hull instead of the line

			if ( fHitWorld )
			{
				float fvolbar = g_SoundSystem.PlayHitSound( tr, vecSrc, vecSrc + ( vecEnd - vecSrc ) * 2, BULLET_PLAYER_CROWBAR );
				
				self.m_flNextPrimaryAttack = g_Engine.time + KNIFE_MOD_ATKSPEED; //0.25
				
				// override the volume here, cause we don't play texture sounds in multiplayer, 
				// and fvolbar is going to be 0 from the above call.

				fvolbar = 1;

				// also play crowbar strike
				switch ( Math.RandomLong( 0, 1 ) )
				{
				case 0:
					g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "AoMClassic/weapons/knife/knife_hit1.wav", fvolbar, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) ); 
					break;
				case 1:
					g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "AoMClassic/weapons/knife/knife_hit2.wav", fvolbar, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) ); 
					break;
				}
			}

			// delay the decal a bit
			m_trHit = tr;
			SetThink( ThinkFunction( this.Smack ) );
			self.pev.nextthink = g_Engine.time + 0.20;

			m_pPlayer.m_iWeaponVolume = int( flVol * 512 ); 
		}
		return fDidHit;
	}
}

string GetCLKnifeName()
{
	return "weapon_clknife";
}

void RegisterCLKnife()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_clknife", GetCLKnifeName() );
	g_ItemRegistry.RegisterWeapon( GetCLKnifeName(), "AoMClassic" );
}
