#include "common"
#include "fixes"

/*
  this used to have an array of "slots", each with predefined relation class,
  about 13 in total, which would limit the amount of DM players
  but now you can just hack through any classification in PlayerTakeDamage
*/

void MapInit()
{
	q1_InitCommon();
	q1_InitFixes();
	g_bDeathmatch = true;
}

void MapActivate()
{
//	q1_ActivateCommon();
	q1_ActivateFixes();
}

void MapStart()
{
	q1_StartCommon();
}
