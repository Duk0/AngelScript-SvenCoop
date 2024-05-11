// Poke646 Script
// Main Script
// Author: Zorbos

#include "ammo_nailclip"
#include "ammo_nailround"
#include "weapon_bradnailer"
#include "weapon_cmlwbr"
#include "weapon_heaterpipe"
#include "weapon_nailgun"
#include "weapon_sawedoff"
#include "point_checkpoint"

void MapInit()
{
	// Survival checkpoint
	POKECHECKPOINT::RegisterPointCheckPointEntity();

	// Register weapons
	RegisterBradnailer();
	RegisterNailgun();
	RegisterSawedOff();
	RegisterHeaterpipe();
	RegisterCmlwbr();

	// Register ammo entities
	g_CustomEntityFuncs.RegisterCustomEntity( "ammo_nailclip", "ammo_nailclip" );
	g_CustomEntityFuncs.RegisterCustomEntity( "ammo_nailround", "ammo_nailround" );

	g_Hooks.RegisterHook( Hooks::Player::PlayerSpawn, @poke646_PlayerSpawn );
}

HookReturnCode poke646_PlayerSpawn( CBasePlayer@ pPlayer )
{
	if ( pPlayer is null )
		return HOOK_CONTINUE;

	SetPlayerAmmo( pPlayer );
	return HOOK_CONTINUE;
}

void SetPlayerAmmo( CBasePlayer@ pPlayer )
{
	pPlayer.SetMaxAmmo("buckshot", 48);
	pPlayer.SetMaxAmmo("bolts", 15);
	pPlayer.SetMaxAmmo("9mm", 200);
	
	pPlayer.RemoveAllExcessAmmo();
}

void MapActivate()
{
	g_EngineFuncs.CVarSetFloat( "mp_allowmonsterinfo", 1 );

	CBaseEntity@ pEntity = null;
	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "func_button" ) ) !is null )
	{
		string szTarget = pEntity.pev.target;
		if ( szTarget == "iuic_mm" || szTarget == "01iuic_mm" )
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "wait", "-1" );
	}
	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "func_door" ) ) !is null )
	{
		string szTargetname = pEntity.GetTargetname();
		if ( szTargetname == "fence" || szTargetname == "closed" || szTargetname == "door_closed" )
		{
			if ( pEntity.pev.spawnflags & 512 == 0 )
				pEntity.pev.spawnflags |= 512;
			//g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "onlytrigger" , "1" );
		}
	}
	
/*	@pEntity = g_EntityFuncs.FindEntityByTargetname( null, "music" );
	if ( pEntity !is null )
	{
		//pEntity.pev.spawnflags = 17;
		g_EntityFuncs.Remove( pEntity );

		dictionary pDictionary = { { 'targetname', 'music' }, { 'message', 'poke646/ambience/title.wav' }, { 'pitchstart', '100' }, { 'pitch', '100' }, { 'health', '10' }, { 'spawnflags', '17' } };
		g_EntityFuncs.CreateEntity( "ambient_generic", pDictionary, true );
	}*/
}
