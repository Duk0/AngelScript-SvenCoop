#include "weapons"
#include "misc/ammo_cspack"
//#include "misc/CInfoMaxCarry"

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "D.N.I.O. 071/R4to0/KernCore" );
	g_Module.ScriptInfo.SetContactInfo( "https://discord.gg/0wtJ6aAd7XOGI6vI" );

	//Change each weapon's iPosition here so they don't conflict with Map's weapons
	//Melees
	CS16_KNIFE::POSITION 		= 10;
	//Pistols
	CS16_GLOCK18::POSITION 		= 10;
	CS16_USP::POSITION 			= 11;
	CS16_P228::POSITION 		= 12;
	CS16_57::POSITION 			= 13;
	CS16_ELITES::POSITION 		= 14;
	CS16_DEAGLE::POSITION 		= 15;
	//Shotguns
	CS16_M3::POSITION 			= 10;
	CS16_XM1014::POSITION 		= 11;
	//Submachine Guns
	CS16_MAC10::POSITION 		= 10;
	CS16_TMP::POSITION 			= 11;
	CS16_MP5::POSITION 			= 12;
	CS16_UMP45::POSITION 		= 13;
	CS16_P90::POSITION 			= 14;
	//Assault Rifles
	CS16_FAMAS::POSITION 		= 10;
	CS16_GALIL::POSITION 		= 11;
	CS16_AK47::POSITION 		= 12;
	CS16_M4A1::POSITION 		= 13;
	CS16_AUG::POSITION 			= 14;
	CS16_SG552::POSITION 		= 15;
	//Sniper Rifles
	CS16_SCOUT::POSITION 		= 10;
	CS16_AWP::POSITION 			= 11;
	CS16_SG550::POSITION 		= 12;
	CS16_G3SG1::POSITION 		= 13;
	//Light Machine Guns
	CS16_M249::POSITION 		= 10;
	//Misc
	CS16_HEGRENADE::POSITION 	= 10;
	CS16_C4::POSITION 			= 11;
}

void MapInit()
{
	CS16_HEGRENADE::MAX_CARRY = 2;

	//Helper method to register all weapons
	RegisterAll();

	CS16_AMMOPACK::Register();
//	CS16_MAXCARRY::Register();
}