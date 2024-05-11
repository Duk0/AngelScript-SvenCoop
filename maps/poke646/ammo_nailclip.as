// Poke646 Script
// Misc Script: Bradnailer Clip
// Author: Zorbos

const int AMMO_NAIL_GIVE = 25;
const int AMMO_NAIL_MAX_CARRY = 200;

class ammo_nailclip : ScriptBasePlayerAmmoEntity
{
	void Spawn()
	{ 
		Precache();

		if( self.SetupModel() == false )
		{
			g_EntityFuncs.SetModel( self, "models/poke646/items/w_nailclip.mdl" );
		}
		else	//Custom model
			g_EntityFuncs.SetModel( self, self.pev.model );

		BaseClass.Spawn();
	}

	void Precache()
	{
		BaseClass.Precache();

		if( string( self.pev.model ).IsEmpty() )
			g_Game.PrecacheModel("models/poke646/items/w_nailclip.mdl");
		else	//Custom model
			g_Game.PrecacheModel( self.pev.model );

		g_SoundSystem.PrecacheSound("items/9mmclip1.wav");
	}

	bool AddAmmo( CBaseEntity@ pOther ) 
	{ 
		if (pOther.GiveAmmo( AMMO_NAIL_GIVE, "9mm", AMMO_NAIL_MAX_CARRY ) != -1)
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "items/9mmclip1.wav", 1, ATTN_NORM);
			return true;
		}
		return false;
	}
}