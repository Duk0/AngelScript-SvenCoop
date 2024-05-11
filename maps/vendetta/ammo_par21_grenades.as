// Poke646: Vendetta Script
// Misc Script: PAR-21 Grenades
// Author: Zorbos

const int AMMO_PAR21GL_GIVE = 2;
const int AMMO_PAR21GL_MAX_CARRY = 10;

class ammo_par21_grenades : ScriptBasePlayerAmmoEntity
{
	void Spawn()
	{ 
		Precache();

		if( self.SetupModel() == false )
		{
			g_EntityFuncs.SetModel( self, "models/vendetta/items/w_par21_grenades.mdl" );
		}
		else	//Custom model
			g_EntityFuncs.SetModel( self, self.pev.model );

		BaseClass.Spawn();
	}

	void Precache()
	{
		BaseClass.Precache();

		if( string( self.pev.model ).IsEmpty() )
			g_Game.PrecacheModel("models/vendetta/items/w_par21_grenades.mdl");
		else	//Custom model
			g_Game.PrecacheModel( self.pev.model );

		g_SoundSystem.PrecacheSound("items/9mmclip1.wav");
	}
	
	bool AddAmmo( CBaseEntity@ pOther ) 
	{ 
		if (pOther.GiveAmmo( AMMO_PAR21GL_GIVE, "ARgrenades", AMMO_PAR21GL_MAX_CARRY ) != -1)
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "items/9mmclip1.wav", 1, ATTN_NORM);
			return true;
		}
		return false;
	}
}