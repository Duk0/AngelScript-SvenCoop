#include "common"
#include "fixes"

/*
  the whole point of the script is to put each connecting player
  into a different monster relation class, so they could hurt each
  other. unless i find a better way of implementing deathmatch,
  this means that DM is limited by about 13 players.
*/
/*
array<int> dmPlayerClasses = {-1, 1, 2, 4, 5, 6, 7, 8, 9, 10, 12, 13, 14};
array<CBasePlayer@> dmPlayers = {null, null, null, null, null, null, null, null, null, null, null, null, null};
*/

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
/*
	for ( uint i = 0; i < dmPlayers.length(); ++i )
		@dmPlayers[i] = null;

	g_Hooks.RegisterHook( Hooks::Player::ClientPutInServer, @q1_DMClientPutInServer );
	g_Hooks.RegisterHook( Hooks::Player::ClientDisconnect, @q1_DMClientDisconnect );*/
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
/*
int q1_FindDMSlot()
{
	for ( uint i = 0; i < dmPlayers.length(); ++i )
		if ( dmPlayers[i] is null )
			return i;

	return -1;
}

HookReturnCode q1_DMClientPutInServer( CBasePlayer@ pPlayer )
{
	if ( pPlayer is null )
		return HOOK_CONTINUE;

	int i = q1_FindDMSlot();
	if ( i < 0 )
		return HOOK_CONTINUE;

	pPlayer.m_fOverrideClass = true;
	pPlayer.m_iClassSelection = dmPlayerClasses[i];
	@dmPlayers[i] = @pPlayer;

	return HOOK_CONTINUE;
}

HookReturnCode q1_DMClientDisconnect( CBasePlayer@ pPlayer )
{
	if ( pPlayer is null )
		return HOOK_CONTINUE;

	for ( uint i = 0; i < dmPlayers.length(); ++i )
	{
		if ( dmPlayers[i] is pPlayer )
		{
			@dmPlayers[i] = null;
			// don't break here just in case the fucker was in multiple slots
		}
	}

	return HOOK_CONTINUE;
}
*/
