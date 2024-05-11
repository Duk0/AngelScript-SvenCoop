// Poke646: Vendetta Script
// Misc Script: PAR-21 Clip
// Author: Zorbos

const int AMMO_PAR21_GIVE = 30;
const int AMMO_PAR21_MAX_CARRY = 150;

class ammo_par21_clip : ScriptBasePlayerAmmoEntity
{
	void Spawn()
	{ 
		Precache();

		if( self.SetupModel() == false )
		{
			g_EntityFuncs.SetModel( self, "models/vendetta/items/w_par21_clip.mdl" );
		}
		else	//Custom model
			g_EntityFuncs.SetModel( self, self.pev.model );

		BaseClass.Spawn();
	}

	void Precache()
	{
		BaseClass.Precache();

		if( string( self.pev.model ).IsEmpty() )
			g_Game.PrecacheModel("models/vendetta/items/w_par21_clip.mdl");
		else	//Custom model
			g_Game.PrecacheModel( self.pev.model );

		g_SoundSystem.PrecacheSound("items/9mmclip1.wav");
	}

	bool AddAmmo( CBaseEntity@ pOther ) 
	{ 
		if (pOther.GiveAmmo( AMMO_PAR21_GIVE, "9mm", AMMO_PAR21_MAX_CARRY ) != -1)
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "items/9mmclip1.wav", 1, ATTN_NORM);
			return true;
		}
		return false;
	}
}