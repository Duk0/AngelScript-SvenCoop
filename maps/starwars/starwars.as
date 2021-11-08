const float ATTN_LOW = 0.5;
const float ATTN_LOW_HIGH = 0.25f;

#include "weapon_e11blaster"
#include "weapon_dl44blaster"
#include "weapon_bowcasterblaster"
#include "weapon_heavyrepeater"
#include "weapon_t21blaster"

//Monsters
#include "monsters/monster_stormtrooper"

void SWRegister()
{
	RegisterE11Blaster();
	RegisterBlaster();
	RegisterBlasterAmmoBox();
	RegisterDL44Blaster();
	RegisterBowcasterBlaster();
	RegisterHighPowerBlasterAmmoBox();
	RegisterHPBlaster();
	RegisterHREPEATER();
	RegisterFlechetteAmmoBox();
	RegisterCShoot();
	RegisterT21Blaster();
	RegisterBlasterNpc();
	RegisterPEntity();
	
	//Monsters
	StormTrooper::Register();
}