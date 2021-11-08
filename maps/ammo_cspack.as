#include "../base"

namespace CS16_AMMOPACK
{

class ammo_cspack : ScriptBasePlayerAmmoEntity
{
	void Spawn()
	{ 
		Precache();

		if ( !self.SetupModel() )
			g_EntityFuncs.SetModel( self, "models/w_weaponbox.mdl" );
		else	//Custom model
			g_EntityFuncs.SetModel( self, self.pev.model );

		BaseClass.Spawn();
		
		g_EntityFuncs.SetSize( self.pev, Vector( -16, -16, 0 ), Vector( 16, 16, 16 ) );
	}
	
	void Precache()
	{
		BaseClass.Precache();

		if ( string( self.pev.model ).IsEmpty() )
			g_Game.PrecacheModel( "models/w_weaponbox.mdl" );
		else	//Custom model
			g_Game.PrecacheModel( self.pev.model );

		g_SoundSystem.PrecacheSound( "items/gunpickup2.wav" );
	}
	
	bool AddAmmo( CBaseEntity@ pOther ) 
	{
		int iRet = pOther.GiveAmmo( (CS16BASE::ShouldUseCustomAmmo) ? CS16_M249::MAX_CARRY : CS16BASE::DF_MAX_CARRY_556, (CS16BASE::ShouldUseCustomAmmo) ? CS16_M249::AMMO_TYPE : CS16BASE::DF_AMMO_556, (CS16BASE::ShouldUseCustomAmmo) ? CS16_M249::MAX_CARRY : CS16BASE::DF_MAX_CARRY_556 );

		iRet += pOther.GiveAmmo( (CS16BASE::ShouldUseCustomAmmo) ? CS16_DEAGLE::MAX_CARRY : CS16BASE::DF_MAX_CARRY_357, (CS16BASE::ShouldUseCustomAmmo) ? CS16_DEAGLE::AMMO_TYPE : CS16BASE::DF_AMMO_357, (CS16BASE::ShouldUseCustomAmmo) ? CS16_DEAGLE::MAX_CARRY : CS16BASE::DF_MAX_CARRY_357 );
		iRet += pOther.GiveAmmo( (CS16BASE::ShouldUseCustomAmmo) ? CS16_GLOCK18::MAX_CARRY : CS16BASE::DF_MAX_CARRY_9MM, (CS16BASE::ShouldUseCustomAmmo) ? CS16_GLOCK18::AMMO_TYPE : CS16BASE::DF_AMMO_9MM, (CS16BASE::ShouldUseCustomAmmo) ? CS16_GLOCK18::MAX_CARRY : CS16BASE::DF_MAX_CARRY_9MM );
		iRet += pOther.GiveAmmo( (CS16BASE::ShouldUseCustomAmmo) ? CS16_ELITES::MAX_CARRY : CS16BASE::DF_MAX_CARRY_9MM, (CS16BASE::ShouldUseCustomAmmo) ? CS16_ELITES::AMMO_TYPE : CS16BASE::DF_AMMO_9MM, (CS16BASE::ShouldUseCustomAmmo) ? CS16_ELITES::MAX_CARRY : CS16BASE::DF_MAX_CARRY_9MM );
		iRet += pOther.GiveAmmo( (CS16BASE::ShouldUseCustomAmmo) ? CS16_57::MAX_CARRY : CS16BASE::DF_MAX_CARRY_9MM, (CS16BASE::ShouldUseCustomAmmo) ? CS16_57::AMMO_TYPE : CS16BASE::DF_AMMO_9MM, (CS16BASE::ShouldUseCustomAmmo) ? CS16_57::MAX_CARRY : CS16BASE::DF_MAX_CARRY_9MM );
		iRet += pOther.GiveAmmo( (CS16BASE::ShouldUseCustomAmmo) ? CS16_P228::MAX_CARRY : CS16BASE::DF_MAX_CARRY_9MM, (CS16BASE::ShouldUseCustomAmmo) ? CS16_P228::AMMO_TYPE : CS16BASE::DF_AMMO_9MM, (CS16BASE::ShouldUseCustomAmmo) ? CS16_P228::MAX_CARRY : CS16BASE::DF_MAX_CARRY_9MM );
		iRet += pOther.GiveAmmo( (CS16BASE::ShouldUseCustomAmmo) ? CS16_USP::MAX_CARRY : CS16BASE::DF_MAX_CARRY_9MM, (CS16BASE::ShouldUseCustomAmmo) ? CS16_USP::AMMO_TYPE : CS16BASE::DF_AMMO_9MM, (CS16BASE::ShouldUseCustomAmmo) ? CS16_USP::MAX_CARRY : CS16BASE::DF_MAX_CARRY_9MM );

		iRet += pOther.GiveAmmo( (CS16BASE::ShouldUseCustomAmmo) ? CS16_AK47::MAX_CARRY : CS16BASE::DF_MAX_CARRY_556, (CS16BASE::ShouldUseCustomAmmo) ? CS16_AK47::AMMO_TYPE : CS16BASE::DF_AMMO_556, (CS16BASE::ShouldUseCustomAmmo) ? CS16_AK47::MAX_CARRY : CS16BASE::DF_MAX_CARRY_556 );
		iRet += pOther.GiveAmmo( (CS16BASE::ShouldUseCustomAmmo) ? CS16_AUG::MAX_CARRY : CS16BASE::DF_MAX_CARRY_556, (CS16BASE::ShouldUseCustomAmmo) ? CS16_AUG::AMMO_TYPE : CS16BASE::DF_AMMO_556, (CS16BASE::ShouldUseCustomAmmo) ? CS16_AUG::MAX_CARRY : CS16BASE::DF_MAX_CARRY_556 );
		iRet += pOther.GiveAmmo( (CS16BASE::ShouldUseCustomAmmo) ? CS16_FAMAS::MAX_CARRY : CS16BASE::DF_MAX_CARRY_556, (CS16BASE::ShouldUseCustomAmmo) ? CS16_FAMAS::AMMO_TYPE : CS16BASE::DF_AMMO_556, (CS16BASE::ShouldUseCustomAmmo) ? CS16_FAMAS::MAX_CARRY : CS16BASE::DF_MAX_CARRY_556 );
		iRet += pOther.GiveAmmo( (CS16BASE::ShouldUseCustomAmmo) ? CS16_GALIL::MAX_CARRY : CS16BASE::DF_MAX_CARRY_556, (CS16BASE::ShouldUseCustomAmmo) ? CS16_GALIL::AMMO_TYPE : CS16BASE::DF_AMMO_556, (CS16BASE::ShouldUseCustomAmmo) ? CS16_GALIL::MAX_CARRY : CS16BASE::DF_MAX_CARRY_556 );
		iRet += pOther.GiveAmmo( (CS16BASE::ShouldUseCustomAmmo) ? CS16_M4A1::MAX_CARRY : CS16BASE::DF_MAX_CARRY_556, (CS16BASE::ShouldUseCustomAmmo) ? CS16_M4A1::AMMO_TYPE : CS16BASE::DF_AMMO_556, (CS16BASE::ShouldUseCustomAmmo) ? CS16_M4A1::MAX_CARRY : CS16BASE::DF_MAX_CARRY_556 );
		iRet += pOther.GiveAmmo( (CS16BASE::ShouldUseCustomAmmo) ? CS16_SG552::MAX_CARRY : CS16BASE::DF_MAX_CARRY_556, (CS16BASE::ShouldUseCustomAmmo) ? CS16_SG552::AMMO_TYPE : CS16BASE::DF_AMMO_556, (CS16BASE::ShouldUseCustomAmmo) ? CS16_SG552::MAX_CARRY : CS16BASE::DF_MAX_CARRY_556 );

		iRet += pOther.GiveAmmo( (CS16BASE::ShouldUseCustomAmmo) ? CS16_M3::MAX_CARRY : CS16BASE::DF_MAX_CARRY_BUCK, (CS16BASE::ShouldUseCustomAmmo) ? CS16_M3::AMMO_TYPE : CS16BASE::DF_AMMO_BUCK, (CS16BASE::ShouldUseCustomAmmo) ? CS16_M3::MAX_CARRY : CS16BASE::DF_MAX_CARRY_BUCK );
		iRet += pOther.GiveAmmo( (CS16BASE::ShouldUseCustomAmmo) ? CS16_XM1014::MAX_CARRY : CS16BASE::DF_MAX_CARRY_BUCK, (CS16BASE::ShouldUseCustomAmmo) ? CS16_XM1014::AMMO_TYPE : CS16BASE::DF_AMMO_BUCK, (CS16BASE::ShouldUseCustomAmmo) ? CS16_XM1014::MAX_CARRY : CS16BASE::DF_MAX_CARRY_BUCK );

		iRet += pOther.GiveAmmo( (CS16BASE::ShouldUseCustomAmmo) ? CS16_MAC10::MAX_CARRY : CS16BASE::DF_MAX_CARRY_9MM, (CS16BASE::ShouldUseCustomAmmo) ? CS16_MAC10::AMMO_TYPE : CS16BASE::DF_AMMO_9MM, (CS16BASE::ShouldUseCustomAmmo) ? CS16_MAC10::MAX_CARRY : CS16BASE::DF_MAX_CARRY_9MM );
		iRet += pOther.GiveAmmo( (CS16BASE::ShouldUseCustomAmmo) ? CS16_MP5::MAX_CARRY : CS16BASE::DF_MAX_CARRY_9MM, (CS16BASE::ShouldUseCustomAmmo) ? CS16_MP5::AMMO_TYPE : CS16BASE::DF_AMMO_9MM, (CS16BASE::ShouldUseCustomAmmo) ? CS16_MP5::MAX_CARRY : CS16BASE::DF_MAX_CARRY_9MM );
		iRet += pOther.GiveAmmo( (CS16BASE::ShouldUseCustomAmmo) ? CS16_P90::MAX_CARRY : CS16BASE::DF_MAX_CARRY_556, (CS16BASE::ShouldUseCustomAmmo) ? CS16_P90::AMMO_TYPE : CS16BASE::DF_AMMO_556, (CS16BASE::ShouldUseCustomAmmo) ? CS16_P90::MAX_CARRY : CS16BASE::DF_MAX_CARRY_556 );
		iRet += pOther.GiveAmmo( (CS16BASE::ShouldUseCustomAmmo) ? CS16_TMP::MAX_CARRY : CS16BASE::DF_MAX_CARRY_9MM, (CS16BASE::ShouldUseCustomAmmo) ? CS16_TMP::AMMO_TYPE : CS16BASE::DF_AMMO_9MM, (CS16BASE::ShouldUseCustomAmmo) ? CS16_TMP::MAX_CARRY : CS16BASE::DF_MAX_CARRY_9MM );
		iRet += pOther.GiveAmmo( (CS16BASE::ShouldUseCustomAmmo) ? CS16_UMP45::MAX_CARRY : CS16BASE::DF_MAX_CARRY_9MM, (CS16BASE::ShouldUseCustomAmmo) ? CS16_UMP45::AMMO_TYPE : CS16BASE::DF_AMMO_9MM, (CS16BASE::ShouldUseCustomAmmo) ? CS16_UMP45::MAX_CARRY : CS16BASE::DF_MAX_CARRY_9MM );

		iRet += pOther.GiveAmmo( (CS16BASE::ShouldUseCustomAmmo) ? CS16_AWP::MAX_CARRY : CS16BASE::DF_MAX_CARRY_M40A1, (CS16BASE::ShouldUseCustomAmmo) ? CS16_AWP::AMMO_TYPE : CS16BASE::DF_AMMO_M40A1, (CS16BASE::ShouldUseCustomAmmo) ? CS16_AWP::MAX_CARRY : CS16BASE::DF_MAX_CARRY_M40A1 );
		iRet += pOther.GiveAmmo( (CS16BASE::ShouldUseCustomAmmo) ? CS16_G3SG1::MAX_CARRY : CS16BASE::DF_MAX_CARRY_357, (CS16BASE::ShouldUseCustomAmmo) ? CS16_G3SG1::AMMO_TYPE : CS16BASE::DF_AMMO_357, (CS16BASE::ShouldUseCustomAmmo) ? CS16_G3SG1::MAX_CARRY : CS16BASE::DF_MAX_CARRY_357 );
		iRet += pOther.GiveAmmo( (CS16BASE::ShouldUseCustomAmmo) ? CS16_SCOUT::MAX_CARRY : CS16BASE::DF_MAX_CARRY_M40A1, (CS16BASE::ShouldUseCustomAmmo) ? CS16_SCOUT::AMMO_TYPE : CS16BASE::DF_AMMO_M40A1, (CS16BASE::ShouldUseCustomAmmo) ? CS16_SCOUT::MAX_CARRY : CS16BASE::DF_MAX_CARRY_M40A1 );
		iRet += pOther.GiveAmmo( (CS16BASE::ShouldUseCustomAmmo) ? CS16_SG550::MAX_CARRY : CS16BASE::DF_MAX_CARRY_357, (CS16BASE::ShouldUseCustomAmmo) ? CS16_SG550::AMMO_TYPE : CS16BASE::DF_AMMO_357, (CS16BASE::ShouldUseCustomAmmo) ? CS16_SG550::MAX_CARRY : CS16BASE::DF_MAX_CARRY_357 );

		iRet += pOther.GiveAmmo( CS16_HEGRENADE::MAX_CARRY, CS16_HEGRENADE::AMMO_TYPE, CS16_HEGRENADE::MAX_CARRY );
/*
		CBasePlayer@ pPlayer = cast<CBasePlayer@>( pOther );

		if ( pPlayer !is null && pPlayer.HasNamedPlayerItem( CS16_HEGRENADE::GetName() ) is null )
			pPlayer.GiveNamedItem( CS16_HEGRENADE::GetName() );
*/		
		// -25 = ( 25 GiveAmmo ) * -1
		if ( iRet != -25 )
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "items/gunpickup2.wav", 1, ATTN_NORM );
			return true;
		}

		return false;
	}
}

string GetAmmoName()
{
	return "ammo_cspack";
}

void Register()
{
	if ( g_CustomEntityFuncs.IsCustomEntity( GetAmmoName() ) )
		return;

	g_CustomEntityFuncs.RegisterCustomEntity( "CS16_AMMOPACK::ammo_cspack", GetAmmoName() );
}

}
