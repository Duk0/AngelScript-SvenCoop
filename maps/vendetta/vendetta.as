// Poke646: Vendetta Script
// Main Script
// Author: Zorbos

#include "ammo_par21_clip"
#include "ammo_par21_grenades"
#include "weapon_cmlwbr"
#include "weapon_leadpipe"
#include "weapon_par21"
#include "weapon_sawedoff"
#include "../poke646/point_checkpoint"

void MapInit()
{
	// Survival checkpoint
	POKECHECKPOINT::RegisterPointCheckPointEntity();

	// Register weapons
	RegisterPAR21();
	RegisterSawedOff();
	RegisterLeadpipe();
	RegisterCmlwbr();
	
	// Register ammo entities
	g_CustomEntityFuncs.RegisterCustomEntity( "ammo_par21_clip", "ammo_par21_clip" );
	g_CustomEntityFuncs.RegisterCustomEntity( "ammo_par21_grenades", "ammo_par21_grenades" );


	g_Hooks.RegisterHook(Hooks::Player::PlayerSpawn, @vendetta_PlayerSpawn);
}

HookReturnCode vendetta_PlayerSpawn( CBasePlayer@ pPlayer )
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
	pPlayer.SetMaxAmmo("9mm", 150);
	
	pPlayer.RemoveAllExcessAmmo();
}

void MapActivate()
{
	g_EngineFuncs.CVarSetFloat( "mp_allowmonsterinfo", 1 );

	CBaseEntity@ pEntity = null;
	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "func_button" ) ) !is null )
	{
		string szTarget = pEntity.pev.target;
		if ( szTarget == "laptop_mm" || szTarget == "laptop2_mm" )
		{
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "wait", "-1" );
		/*	string szTargetName = szTarget + "_relay";
			pEntity.pev.target = szTargetName;
			dictionary pDictionary = { { 'targetname', szTargetName }, { 'target', szTarget }, { 'spawnflags', '1' }, { 'triggerstate', '1' } };
			g_EntityFuncs.CreateEntity( "trigger_relay", pDictionary, true );*/
		}
	}
/*	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "item_generic" ) ) !is null )
	{
		if ( pEntity.pev.model == "models/vendetta/props/chair.mdl" )
		{
			Vector vecAngles = pEntity.pev.angles;
			vecAngles.y += 180;
			pEntity.pev.angles = vecAngles;
		}
	}*/
}
