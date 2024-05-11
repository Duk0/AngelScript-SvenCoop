// Poke646: Vendetta Script
// Weapon Script: Lead Pipe
// Author: Zorbos

enum pipe_e
{
	PIPE_IDLE = 0,
	PIPE_DRAW,
	PIPE_HOLSTER,
	PIPE_ATTACK1HIT,
	PIPE_ATTACK1MISS,
	PIPE_ATTACK2MISS,
	PIPE_ATTACK2HIT,
	PIPE_ATTACK3MISS,
	PIPE_ATTACK3HIT,
	PIPE_IDLE2,
	PIPE_IDLE3
};

const float PIPE_MOD_DAMAGE = 25.0;
const float PIPE_MOD_FATIGUE_TICK = 0.50; // Time between fatigue checks

class weapon_leadpipe : ScriptBasePlayerWeaponEntity
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}
	int m_iSwing;
	int m_iSwingCount = 0;
	TraceResult m_trHit;
	bool m_bIsBreathing = false;
	float m_flDmgMulti = 1.0;
	float m_flDelayMulti = 1.0;
	
	void Spawn()
	{
		self.Precache();
		g_EntityFuncs.SetModel( self, self.GetW_Model( "models/vendetta/weapons/leadpipe/w_leadpipe.mdl") );
		self.m_iClip			= -1;
		self.m_flCustomDmg		= self.pev.dmg;

		self.FallInit();// get ready to fall down.
	}

	void Precache()
	{
		self.PrecacheCustomModels();

		g_Game.PrecacheModel( "models/vendetta/weapons/leadpipe/v_leadpipe.mdl" );
		g_Game.PrecacheModel( "models/vendetta/weapons/leadpipe/w_leadpipe.mdl" );
		g_Game.PrecacheModel( "models/vendetta/weapons/leadpipe/p_leadpipe.mdl" );

		g_SoundSystem.PrecacheSound( "vendetta/weapons/leadpipe/leadpipe_hit1.wav" );
		g_SoundSystem.PrecacheSound( "vendetta/weapons/leadpipe/leadpipe_hit2.wav" );
		g_SoundSystem.PrecacheSound( "vendetta/weapons/leadpipe/leadpipe_miss.wav" );
		g_SoundSystem.PrecacheSound( "weapons/cbar_hitbod1.wav" );
		g_SoundSystem.PrecacheSound( "weapons/cbar_hitbod2.wav" );
		g_SoundSystem.PrecacheSound( "weapons/cbar_hitbod3.wav" );
		
		g_SoundSystem.PrecacheSound( "vendetta/weapons/leadpipe/leadpipe_breathe.wav" ); // Fatigue sound
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1		= -1;
		info.iMaxAmmo2		= -1;
		info.iMaxClip		= WEAPON_NOCLIP;
		info.iSlot			= 0;
		info.iPosition		= 6;
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
		return self.DefaultDeploy( self.GetV_Model( "models/vendetta/weapons/leadpipe/v_leadpipe.mdl" ), self.GetP_Model( "models/vendetta/weapons/leadpipe/p_leadpipe.mdl" ), PIPE_DRAW, "crowbar" );
	}

	void Holster( int skiplocal /* = 0 */ )
	{
		self.m_fInReload = false;// cancel any reload in progress.
		m_flDmgMulti = 1.0;
		m_flDelayMulti = 0.55;
		m_iSwingCount = 0;
		
		if (m_bIsBreathing)
		{
			g_SoundSystem.StopSound(m_pPlayer.edict(), CHAN_STATIC, "vendetta/weapons/leadpipe/leadpipe_breathe.wav", false);
			m_bIsBreathing = false;
		}
		
		m_pPlayer.m_flNextAttack = g_WeaponFuncs.WeaponTimeBase() + 0.5;

		// Fix for the SendWeaponAnim crash -R4to0 (8 May 2019)
		SetThink( null );
	}
	
	void PrimaryAttack()
	{
		if( Swing( 1 ) == false )
		{
			SetThink( ThinkFunction( this.SwingAgain ) );
		}

		self.m_flTimeWeaponIdle = WeaponTimeBase() + PIPE_MOD_FATIGUE_TICK;
	}
	
	float WeaponTimeBase()
	{
		return g_Engine.time; //g_WeaponFuncs.WeaponTimeBase();
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
		if( m_pPlayer is null )
			return false;

		bool fDidHit = false;
		TraceResult tr;

		if( m_iSwingCount == 0 ) // No fatigue, full dmg/speed
		{
			m_flDmgMulti = 1.0;
			m_flDelayMulti = 0.45;
		}
		else if( m_iSwingCount == 1 )
		{
			m_flDmgMulti = 0.90;
			m_flDelayMulti = 0.48;
		}
		else if( m_iSwingCount == 2 )
		{
			m_flDmgMulti = 0.80;
			m_flDelayMulti = 0.51;
		}
		else if( m_iSwingCount == 3 )
		{
			m_flDmgMulti = 0.70;
			m_flDelayMulti = 0.54;
		}
		else if( m_iSwingCount == 4 )
		{
			m_flDmgMulti = 0.60;
			m_flDelayMulti = 0.57;
		}
		else if( m_iSwingCount == 5 )
		{
			m_flDmgMulti = 0.50;
			m_flDelayMulti = 0.65;
		}
		else if( m_iSwingCount == 6 )
		{
			m_flDmgMulti = 0.50;
			m_flDelayMulti = 0.70;
		}
		else if( m_iSwingCount == 7 )
		{
			m_flDmgMulti = 0.50;
			m_flDelayMulti = 0.80;
			
			if(!m_bIsBreathing) // Check if player is breathing yet
			{
				m_bIsBreathing = true;
				g_SoundSystem.PlaySound(m_pPlayer.edict(), CHAN_STATIC, "vendetta/weapons/leadpipe/leadpipe_breathe.wav", 0.65f, 1.0f, 0, 100, m_pPlayer.entindex());
			}
		}
		else if( m_iSwingCount == 8 )
		{
			m_flDmgMulti = 0.50;
			m_flDelayMulti = 0.90;
		}
		else if( m_iSwingCount == 9 )
		{
			m_flDmgMulti = 0.50;
			m_flDelayMulti = 1.0;
		}
		else // Maximum exertion
		{
			m_flDmgMulti = 0.50;
			m_flDelayMulti = 1.10;
		}

		m_iSwingCount += 1; // Increment the fatigue counter
		if(m_iSwingCount > 10)
			m_iSwingCount = 10; // We can't go above max fatigue

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
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
				if ( pHit is null || pHit.IsBSPModel() )
					g_Utility.FindHullIntersection( vecSrc, tr, tr, VEC_DUCK_HULL_MIN, VEC_DUCK_HULL_MAX, m_pPlayer.edict() );
				vecEnd = tr.vecEndPos;	// This is the point on the actual surface (the hull could have hit space)
			}
		}

		if ( tr.flFraction >= 1.0 )
		{
			if( fFirst != 0 )
			{
				// miss
				switch( ( m_iSwing++ ) % 3 )
				{
				case 0:
					self.SendWeaponAnim( PIPE_ATTACK1MISS ); break;
				case 1:
					self.SendWeaponAnim( PIPE_ATTACK2MISS ); break;
				case 2:
					self.SendWeaponAnim( PIPE_ATTACK3MISS ); break;
				}
				self.m_flNextPrimaryAttack = g_Engine.time + m_flDelayMulti;
				// play wiff or swish sound
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "vendetta/weapons/leadpipe/leadpipe_miss.wav", 1, ATTN_NORM, 0, 94 + Math.RandomLong( 0,0xF ) );

				// player "shoot" animation
				m_pPlayer.SetAnimation( PLAYER_ATTACK1 ); 
			}
		}
		else
		{
			// hit
			fDidHit = true;
			
			CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );

			switch( ( ( m_iSwing++ ) % 2 ) + 1 )
			{
			case 0:
				self.SendWeaponAnim( PIPE_ATTACK1HIT ); break;
			case 1:
				self.SendWeaponAnim( PIPE_ATTACK2HIT ); break;
			case 2:
				self.SendWeaponAnim( PIPE_ATTACK3HIT ); break;
			}

			// player "shoot" animation
			m_pPlayer.SetAnimation( PLAYER_ATTACK1 ); 

			// AdamR: Custom damage option
			float flDamage = PIPE_MOD_DAMAGE;
			if ( self.m_flCustomDmg > 0 )
				flDamage = self.m_flCustomDmg;
			// AdamR: End

			g_WeaponFuncs.ClearMultiDamage();
			if ( self.m_flNextPrimaryAttack + 1 < g_Engine.time )
			{
				// first swing does full damage
				pEntity.TraceAttack( m_pPlayer.pev, flDamage * m_flDmgMulti, g_Engine.v_forward, tr, DMG_CLUB );  
			}
			else
			{
				// subsequent swings do 50% (Changed -Sniper) (Half)
				pEntity.TraceAttack( m_pPlayer.pev, flDamage * m_flDmgMulti, g_Engine.v_forward, tr, DMG_CLUB );  
			}
			
			g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );

			//m_flNextPrimaryAttack = gpGlobals->time + 0.30; //0.25

			// play thwack, smack, or dong sound
			float flVol = 1.0;
			bool fHitWorld = true;

			if( pEntity !is null )
			{
				self.m_flNextPrimaryAttack = g_Engine.time + m_flDelayMulti; //0.25

				if( pEntity.Classify() != CLASS_NONE && pEntity.Classify() != CLASS_MACHINE && pEntity.BloodColor() != DONT_BLEED )
				{
	// aone
					if( pEntity.IsPlayer() )		// lets pull them
					{
						pEntity.pev.velocity = pEntity.pev.velocity + ( self.pev.origin - pEntity.pev.origin ).Normalize() * 120;
					}
	// end aone
					// play thwack or smack sound
					switch( Math.RandomLong( 0, 2 ) )
					{
					case 0:
						g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "weapons/cbar_hitbod1.wav", 1, ATTN_NORM ); break;
					case 1:
						g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "weapons/cbar_hitbod2.wav", 1, ATTN_NORM ); break;
					case 2:
						g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "weapons/cbar_hitbod3.wav", 1, ATTN_NORM ); break;
					}
					m_pPlayer.m_iWeaponVolume = 128; 
					if( !pEntity.IsAlive() )
						return true;
					else
						flVol = 0.1;

					fHitWorld = false;
				}
			}

			// play texture hit sound
			// UNDONE: Calculate the correct point of intersection when we hit with the hull instead of the line

			if( fHitWorld == true )
			{
				float fvolbar = g_SoundSystem.PlayHitSound( tr, vecSrc, vecSrc + ( vecEnd - vecSrc ) * 2, BULLET_PLAYER_CROWBAR );
				
				self.m_flNextPrimaryAttack = g_Engine.time + m_flDelayMulti;; //0.25
				
				// override the volume here, cause we don't play texture sounds in multiplayer, 
				// and fvolbar is going to be 0 from the above call.

				fvolbar = 1;

				// also play crowbar strike
				switch( Math.RandomLong( 0, 1 ) )
				{
				case 0:
					g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "vendetta/weapons/leadpipe/leadpipe_hit1.wav", fvolbar, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) ); 
					break;
				case 1:
					g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "vendetta/weapons/leadpipe/leadpipe_hit2.wav", fvolbar, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) ); 
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

	void WeaponIdle()
	{
		if ( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;

		if (m_iSwingCount != 0)
		{
			--m_iSwingCount;
		}
		
		if ( m_bIsBreathing && m_iSwingCount == 5 )
		{
			g_SoundSystem.StopSound(m_pPlayer.edict(), CHAN_STATIC, "vendetta/weapons/leadpipe/leadpipe_breathe.wav", false);
			m_bIsBreathing = false;
		}

		self.m_flTimeWeaponIdle = WeaponTimeBase() + PIPE_MOD_FATIGUE_TICK;
	}
}

string GetLeadpipeName()
{
	return "weapon_leadpipe";
}

void RegisterLeadpipe()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_leadpipe", GetLeadpipeName() );
	g_ItemRegistry.RegisterWeapon( GetLeadpipeName(), "vendetta" );
}
