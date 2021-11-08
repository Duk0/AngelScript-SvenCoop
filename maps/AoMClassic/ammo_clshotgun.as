// Afraid of Monsters Classic Script
// Misc Script: Shotgun Ammo
// Author: Zorbos

const int AMMO_SHOTGUN_GIVE = 8;
const int AMMO_SHOTGUN_MAX_CARRY = 32;

class ammo_clshotgun : ScriptBasePlayerAmmoEntity
{
	private bool bSurvivalEnabled = g_SurvivalMode.MapSupportEnabled() && g_SurvivalMode.IsEnabled();
	
	void Spawn()
	{ 
		Precache();

		if ( !self.SetupModel() )
			g_EntityFuncs.SetModel( self, "models/w_shotbox.mdl" );
		else	//Custom model
			g_EntityFuncs.SetModel( self, self.pev.model );
			
		if ( bSurvivalEnabled )
			self.pev.spawnflags = 1024; // Never Respawn
			
		BaseClass.Spawn();
	}
	
	void Precache()
	{
		BaseClass.Precache();

		if ( string( self.pev.model ).IsEmpty() )
			g_Game.PrecacheModel( "models/w_shotbox.mdl" );
		else	//Custom model
			g_Game.PrecacheModel( self.pev.model );

		g_SoundSystem.PrecacheSound( "items/9mmclip1.wav" );
	}
	
	bool AddAmmo( CBaseEntity@ pOther ) 
	{ 
		if ( pOther.GiveAmmo( AMMO_SHOTGUN_GIVE, "buckshot", AMMO_SHOTGUN_MAX_CARRY ) != -1 )
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "items/9mmclip1.wav", 1, ATTN_NORM );
			return true;
		}

		return false;
	}
}
