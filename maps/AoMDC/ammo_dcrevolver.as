// Afraid of Monsters: Director's Cut Script
// Misc Script: Revolver Ammo
// Author: Zorbos

const int AMMO_REVOLVER_GIVE = 6;
const int AMMO_REVOLVER_MAX_CARRY = 18;

class ammo_dcrevolver : ScriptBasePlayerAmmoEntity
{
	private bool bSurvivalEnabled = g_SurvivalMode.MapSupportEnabled() && g_SurvivalMode.IsEnabled();

	void Spawn()
	{ 
		Precache();

		if ( !self.SetupModel() )
			g_EntityFuncs.SetModel( self, "models/AoMDC/items/w_revolverrounds.mdl" );
		else	//Custom model
			g_EntityFuncs.SetModel( self, self.pev.model );

		BaseClass.Spawn();
		
		if ( bSurvivalEnabled )
			self.pev.spawnflags = 1280;	// +USE only AND Never Respawn
		else
			self.pev.spawnflags = 256;	// +USE only
		
		// Makes it slightly easier to pickup
		if ( g_bEasyPickup )
			g_EntityFuncs.SetSize( self.pev, Vector( -4, -4, -2 ), Vector( 4, 4, 2 ) );
	}
	
	void Precache()
	{
		BaseClass.Precache();

		if ( string( self.pev.model ).IsEmpty() )
			g_Game.PrecacheModel( "models/AoMDC/items/w_revolverrounds.mdl" );
		else	//Custom model
			g_Game.PrecacheModel( self.pev.model );

		g_SoundSystem.PrecacheSound( "items/9mmclip1.wav" );
	}
	
	bool AddAmmo( CBaseEntity@ pOther ) 
	{ 
		if ( pOther.GiveAmmo( AMMO_REVOLVER_GIVE, "m40a1", AMMO_REVOLVER_MAX_CARRY ) != -1 )
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "items/9mmclip1.wav", 1, ATTN_NORM );
			return true;
		}

		return false;
	}
}
