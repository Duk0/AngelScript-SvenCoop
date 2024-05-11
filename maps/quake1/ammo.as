const int Q1_AMMO_SHELLS_MAX	= 100;
const int Q1_AMMO_NAILS_MAX	= 200;
const int Q1_AMMO_ROCKETS_MAX	= 100;
const int Q1_AMMO_ENERGY_MAX	= 100;

const int Q1_AMMO_SHELLS_GIVE	= 25;
const int Q1_AMMO_NAILS_GIVE	= 50;
const int Q1_AMMO_ROCKETS_GIVE	= 10;
const int Q1_AMMO_ENERGY_GIVE	= 10;

class CBaseQuakeAmmo : ScriptBasePlayerAmmoEntity
{
	protected string m_sModel = "models/error.mdl";
	protected string m_sAmmo;
	protected int m_iGive = 0;
	protected int m_iMax = 0;

	void Precache()
	{
		g_Game.PrecacheModel( m_sModel );
		g_SoundSystem.PrecacheSound( "quake1/ammo.wav" );
	}

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, m_sModel );
		BaseClass.Spawn();
	}

	bool AddAmmo( CBaseEntity@ pOther )
	{
		if ( pOther is null )
			return false;

		if ( pOther.GiveAmmo( m_iGive, m_sAmmo, m_iMax ) != -1 )
		{
			g_SoundSystem.EmitSound( pOther.edict(), CHAN_ITEM, "quake1/ammo.wav", 1.0, ATTN_NORM );
			return true;
		}

		return false;
	}
}

class ammo_qshells : CBaseQuakeAmmo
{
	ammo_qshells()
	{
		m_sModel = "models/quake1/w_shotgun_ammo.mdl";
		m_sAmmo = "buckshot";
		m_iGive = Q1_AMMO_SHELLS_GIVE;
		m_iMax = Q1_AMMO_SHELLS_MAX;
	}
}

class ammo_qnails : CBaseQuakeAmmo
{
	ammo_qnails()
	{
		m_sModel = "models/quake1/w_nailgun_ammo.mdl";
		m_sAmmo = "bolts";
		m_iGive = Q1_AMMO_NAILS_GIVE;
		m_iMax = Q1_AMMO_NAILS_MAX;
	}
}

class ammo_qrockets : CBaseQuakeAmmo
{
	ammo_qrockets()
	{
		m_sModel = "models/quake1/w_rocket_ammo.mdl";
		m_sAmmo = "rockets";
		m_iGive = Q1_AMMO_ROCKETS_GIVE;
		m_iMax = Q1_AMMO_ROCKETS_MAX;
	}
}

class ammo_qenergy : CBaseQuakeAmmo
{
	ammo_qenergy()
	{
		m_sModel = "models/quake1/w_thunder_ammo.mdl";
		m_sAmmo = "uranium";
		m_iGive = Q1_AMMO_ENERGY_GIVE;
		m_iMax = Q1_AMMO_ENERGY_MAX;
	}
}

void q1_SetAmmoCaps( CBasePlayer@ pPlayer )
{
	pPlayer.SetMaxAmmo( "buckshot", Q1_AMMO_SHELLS_MAX );
	pPlayer.SetMaxAmmo( "bolts", Q1_AMMO_NAILS_MAX );
	pPlayer.SetMaxAmmo( "rockets", Q1_AMMO_ROCKETS_MAX );
	pPlayer.SetMaxAmmo( "uranium", Q1_AMMO_ENERGY_MAX );
}

void q1_RegisterAmmo()
{
	// precache item and ammo models right away
	g_Game.PrecacheModel( "models/quake1/w_shotgun_ammo.mdl" );
	g_Game.PrecacheModel( "models/quake1/w_nailgun_ammo.mdl" );
	g_Game.PrecacheModel( "models/quake1/w_rocket_ammo.mdl" );
	g_Game.PrecacheModel( "models/quake1/w_thunder_ammo.mdl" );
	g_SoundSystem.PrecacheSound( "quake1/ammo.wav" ); // for backpacks

	g_CustomEntityFuncs.RegisterCustomEntity( "ammo_qshells", "ammo_qshells" );
	g_CustomEntityFuncs.RegisterCustomEntity( "ammo_qnails", "ammo_qnails" );
	g_CustomEntityFuncs.RegisterCustomEntity( "ammo_qrockets", "ammo_qrockets" );
	g_CustomEntityFuncs.RegisterCustomEntity( "ammo_qenergy", "ammo_qenergy" );
}
