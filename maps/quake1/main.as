#include "common"
#include "fixes"

// coop shit
#include "monsters/monster_qarmy"
#include "monsters/monster_qdog"
#include "monsters/monster_qogre"
#include "monsters/monster_qfiend"
#include "monsters/monster_qscrag"
#include "monsters/monster_qknight"
#include "monsters/monster_qshambler"
#include "monsters/monster_qzombie"
#include "monsters/monster_qboss"

//#include "../monster_barney_custom"

#include "monsters/monster_qenforcer"
#include "monsters/monster_qfish"
#include "monsters/monster_qhellknight"
#include "monsters/monster_qshalrath"
#include "monsters/monster_qtarbaby"

void MapInit()
{
	q1_InitCommon();
	q1_RegisterMonsters();

	q1_InitFixes();
	
	g_SoundSystem.PrecacheSound( Q1_FIEND_LAND );
}

void q1_RegisterMonsters()
{
	q1_RegisterMonster_ARMY();
	q1_RegisterMonster_DOG();
	q1_RegisterMonster_OGRE();
	q1_RegisterMonster_FIEND();
	q1_RegisterMonster_SCRAG();
	q1_RegisterMonster_KNIGHT();
	q1_RegisterMonster_SHAMBLER();
	q1_RegisterMonster_ZOMBIE();
	q1_RegisterMonster_BOSS();
	
//	BarneyCustom::Register();
//	g_Game.PrecacheOther( "monster_barney_custom" );

	q1_RegisterMonster_ENFORCER();
	g_Game.PrecacheOther( "monster_qenforcer" );
	q1_RegisterMonster_FISH();
	g_Game.PrecacheOther( "monster_qfish" );
	q1_RegisterMonster_HELLKNIGHT();
	g_Game.PrecacheOther( "monster_qhellknight" );
	q1_RegisterMonster_SHALRATH();
	g_Game.PrecacheOther( "monster_qshalrath" );
	q1_RegisterMonster_TARBABY();
	g_Game.PrecacheOther( "monster_qtarbaby" );
}

void MapActivate()
{
	q1_ActivateCommon();
	q1_ActivateFixes();
}

void MapStart()
{
	q1_StartCommon();
	q1_StartMonster();
}
