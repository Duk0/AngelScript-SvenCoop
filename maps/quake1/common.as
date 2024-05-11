#include "ammo"
#include "items"
#include "tempents"
#include "triggers"
#include "monsters/monsters"
#include "weapons/projectile"
#include "weapons/weapon_qaxe"
#include "weapons/weapon_qshotgun"
#include "weapons/weapon_qshotgun2"
#include "weapons/weapon_qnailgun"
#include "weapons/weapon_qnailgun2"
#include "weapons/weapon_qgrenade"
#include "weapons/weapon_qrocket"
#include "weapons/weapon_qthunder"
#include "misc_fireball"
#include "stats"
//#include "lights"

/* TODO 
- mixin class weapon_qgeneric, shit's getting ridiculous
- keys/runes
*/

const float PLAYER_MAX_SAFE_FALL_SPEED = 580.0; // approx 20 feet

const Cvar@ g_pCvarGravity, g_pCvarStepSize;
int g_iAmmoBuckshot, g_iAmmoBolts, g_iAmmoRockets, g_iAmmoUranium;

void q1_InitCommon()
{
	q1_PrecachePlayerSounds();

	q1_RegisterMiscFireBall();
	q1_RegisterIntermission();
//	q1_RegisterLightTorch();

	q1_RegisterProjectiles();
	q1_RegisterAmmo();
	q1_RegisterItems();
	q1_RegisterTriggers();
	q1_RegisterWeapon_AXE();
	q1_RegisterWeapon_SHOTGUN();
	q1_RegisterWeapon_SHOTGUN2();
	q1_RegisterWeapon_NAILGUN();
	q1_RegisterWeapon_NAILGUN2();
	q1_RegisterWeapon_GRENADE();
	q1_RegisterWeapon_ROCKET();
	q1_RegisterWeapon_THUNDER();

	g_Hooks.RegisterHook( Hooks::Player::PlayerSpawn, @q1_PlayerSpawn );
	g_Hooks.RegisterHook( Hooks::Player::PlayerKilled, @q1_PlayerKilled );
	g_Hooks.RegisterHook( Hooks::Player::PlayerTakeDamage, @q1_PlayerTakeDamage );
	g_Hooks.RegisterHook( Hooks::Player::PlayerPreThink, @q1_PlayerPreThink );
	g_Hooks.RegisterHook( Hooks::Player::PlayerPostThink, @q1_PlayerPostThink );

	@g_pCvarGravity = g_EngineFuncs.CVarGetPointer( "sv_gravity" );
	@g_pCvarStepSize = g_EngineFuncs.CVarGetPointer( "sv_stepsize" );

	if ( g_Engine.cdAudioTrack > 0 )
	{
	//	g_EngineFuncs.ServerPrint( "cdAudioTrack: " + g_Engine.cdAudioTrack + "\n" );
		g_Engine.cdAudioTrack = 0; // don't play looped music from loading
	}
}

void q1_ActivateCommon()
{
	q1_ActivateScretCounter();
}

void q1_StartCommon()
{
	g_iAmmoBuckshot = g_PlayerFuncs.GetAmmoIndex( "buckshot" );
	g_iAmmoBolts = g_PlayerFuncs.GetAmmoIndex( "bolts" );
	g_iAmmoRockets = g_PlayerFuncs.GetAmmoIndex( "rockets" );
	g_iAmmoUranium = g_PlayerFuncs.GetAmmoIndex( "uranium" );
}

HookReturnCode q1_PlayerSpawn( CBasePlayer@ pPlayer )
{
	if ( pPlayer is null )
		return HOOK_CONTINUE;

	q1_SetAmmoCaps( pPlayer );
	CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
	pCustom.SetKeyvalue( "$fl_jumpFlag", 0.0 );
/*	pCustom.SetKeyvalue( "$fl_lastHealth", pPlayer.pev.health );
	pCustom.SetKeyvalue( "$fl_lastPain", 0.0 );*/
	return HOOK_CONTINUE;
}

HookReturnCode q1_PlayerKilled( CBasePlayer@ pPlayer, CBaseEntity@ pAttacker, int iGib )
{
	if ( pPlayer is null )
		return HOOK_CONTINUE;
	
	if ( iGib == GIB_NORMAL || iGib == GIB_NEVER )
	{
		// AUTHENTIC DEATH SOUNDS
		if ( pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
		{
			Vector vecOrigin = pPlayer.GetOrigin();
			g_Utility.Bubbles( vecOrigin - Vector( 64, 64, 64 ), vecOrigin + Vector( 64, 64, 64 ), 20 );
			g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_VOICE, "quake1/player/h2odeath.wav", Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM );
		}
		else
		{
			int iNum = Math.RandomLong( 1, 5 );
			string sName = "quake1/player/death" + string( iNum ) + ".wav";
			g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_VOICE, sName, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM );
		}
	}

	int iAmmoShells = pPlayer.m_rgAmmo( g_iAmmoBuckshot );
	int iAmmoNails = pPlayer.m_rgAmmo( g_iAmmoBolts );
	int iAmmoRockets = pPlayer.m_rgAmmo( g_iAmmoRockets );
	int iAmmoCells = pPlayer.m_rgAmmo( g_iAmmoUranium );

	CBasePlayerItem@ pActiveItem = cast<CBasePlayerItem@>( pPlayer.m_hActiveItem.GetEntity() );

	if ( pActiveItem is null && iAmmoShells == 0 && iAmmoNails == 0 && iAmmoRockets == 0 && iAmmoCells == 0 )
		return HOOK_CONTINUE;

	// spawn a backpack, moving player's weapon and ammo into it
	CBackPack@ pPack = q1_SpawnBackpack( pPlayer );
	if ( pPack is null )
		return HOOK_CONTINUE;

	if ( pActiveItem !is null )
	{
	//	@pPack.m_pWeapon = @pActiveItem;
		pPack.m_szWeaponName = pActiveItem.pszName();
		pPlayer.RemovePlayerItem( pActiveItem );
	}

	pPack.m_iAmmoShells = iAmmoShells;
	pPack.m_iAmmoNails = iAmmoNails;
	pPack.m_iAmmoRockets = iAmmoRockets;
	pPack.m_iAmmoCells = iAmmoCells;
	pPlayer.m_rgAmmo( g_iAmmoBuckshot, 0 );
	pPlayer.m_rgAmmo( g_iAmmoBolts, 0 );
	pPlayer.m_rgAmmo( g_iAmmoRockets, 0 );
	pPlayer.m_rgAmmo( g_iAmmoUranium, 0 );

	return HOOK_CONTINUE;
}

HookReturnCode q1_PlayerTakeDamage( DamageInfo@ pDamageInfo )
{
	if ( pDamageInfo.pVictim is null )
		return HOOK_CONTINUE;

	if ( !pDamageInfo.pVictim.IsPlayer() || !pDamageInfo.pVictim.IsAlive() )
		return HOOK_CONTINUE;

//	g_EngineFuncs.ServerPrint( "bitsDamageType: " + pDamageInfo.bitsDamageType + "\n" );

	if ( pDamageInfo.pVictim.pev.FlagBitSet( FL_GODMODE ) )
	{
		pDamageInfo.bitsDamageType = DMG_GENERIC;
		pDamageInfo.flDamage = 0;
		return HOOK_HANDLED;
	}

	if ( ( pDamageInfo.bitsDamageType & DMG_NERVEGAS ) != 0 || ( pDamageInfo.pAttacker !is null && pDamageInfo.pAttacker.IsPlayer() && pDamageInfo.pAttacker !is pDamageInfo.pVictim && pDamageInfo.pAttacker.Classify() == pDamageInfo.pVictim.Classify() ) )
	{
		pDamageInfo.flDamage = 0;
		return HOOK_HANDLED;
	}

	if ( ( pDamageInfo.bitsDamageType & DMG_DROWN ) != 0 && pDamageInfo.pVictim.pev.FlagBitSet( FL_IMMUNE_WATER ) )
	{
		pDamageInfo.bitsDamageType = DMG_GENERIC;
		pDamageInfo.flDamage = 0;
		return HOOK_HANDLED;
	}

	if ( ( pDamageInfo.bitsDamageType & DMG_BURN ) != 0 && pDamageInfo.pVictim.pev.FlagBitSet( FL_IMMUNE_LAVA ) )
	{
		pDamageInfo.bitsDamageType = DMG_GENERIC;
		pDamageInfo.flDamage = 0;
		return HOOK_HANDLED;
	}

	if ( ( pDamageInfo.bitsDamageType & DMG_ACID ) != 0 && pDamageInfo.pVictim.pev.FlagBitSet( FL_IMMUNE_SLIME ) )
	{
		pDamageInfo.bitsDamageType = DMG_GENERIC;
		pDamageInfo.flDamage = 0;
	//	@pDamageInfo.pVictim = null;
		return HOOK_HANDLED;
	}

/*	if ( ( pDamageInfo.bitsDamageType & DMG_FALL ) != 0 )
	{
		g_SoundSystem.StopSound( pDamageInfo.pVictim.edict(), CHAN_VOICE, "player/pl_fallpain3.wav", false );
		return HOOK_CONTINUE;
	}*/

	if ( pDamageInfo.pVictim.pev.pain_finished > g_Engine.time )
		return HOOK_CONTINUE;

	pDamageInfo.pVictim.pev.pain_finished = g_Engine.time + 0.7;
	
	string sName;

	if ( ( pDamageInfo.bitsDamageType & DMG_BURN ) != 0 || ( pDamageInfo.bitsDamageType & DMG_ACID ) != 0 )
	{
		// we're in lava or acid or some shit, scream properly
		sName = "quake1/player/burn" + string( Math.RandomLong( 1, 2 ) ) + ".wav";
	}
	else if ( ( pDamageInfo.bitsDamageType & DMG_FALL ) != 0 )
	{
		// fell
		g_SoundSystem.StopSound( pDamageInfo.pVictim.edict(), CHAN_VOICE, "player/pl_fallpain3.wav", false );
		sName = "quake1/player/fall.wav";
	}
	else if ( ( pDamageInfo.bitsDamageType & DMG_DROWN ) != 0 )
	{
		// drowning
		Vector vecOrigin = pDamageInfo.pVictim.GetOrigin();
		g_Utility.Bubbles( vecOrigin - Vector( 32, 32, 32 ), vecOrigin + Vector( 32, 32, 32 ), 1 );

		if ( Math.RandomFloat( 0, 1 ) > 0.5 )
			sName = "quake1/player/drown1.wav";
		else
			sName = "quake1/player/drown2.wav";
	}
	else
	{
		// scream with intensity proportional to damage value
		int iNum = 1 + int( pDamageInfo.flDamage / 20 ) + Math.RandomLong( 0, 2 );
		if ( iNum > 6 ) iNum = 6;
		if ( iNum < 1 ) iNum = 1;
		sName = "quake1/player/pain" + string( iNum ) + ".wav";
	}

	g_SoundSystem.EmitSoundDyn( pDamageInfo.pVictim.edict(), CHAN_VOICE, sName, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM );
//	g_EngineFuncs.ServerPrint( "sName: " + sName + "\n" );
	
	return HOOK_CONTINUE;
}

HookReturnCode q1_PlayerPreThink( CBasePlayer@ pPlayer, uint& out uiFlags )
{
	if ( pPlayer is null )
		return HOOK_CONTINUE;
		
	q1_PlayPlayerJumpSounds( pPlayer );
	q1_PlayPlayerWaterSounds( pPlayer );
	
	return HOOK_CONTINUE;
}

HookReturnCode q1_PlayerPostThink( CBasePlayer@ pPlayer )
{
	if ( pPlayer is null )
		return HOOK_CONTINUE;

	q1_PlayPlayerLandSounds( pPlayer );
//	q1_PlayPlayerPainSounds( pPlayer );
//	q1_PlayPlayerJumpSounds( pPlayer );
	return HOOK_CONTINUE;
}
/*
void q1_PlayPlayerPainSounds( CBasePlayer@ pPlayer )
{
	// get all damage we've accumulated and play AUTHENTIC PAIN SOUNDS
	// there's no robust way to actually get damage that the player
	// received during the previous frame, so we store his previous health
	// in a custom keyvalue and also a pain timeout to not scream too often
	CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
	float flLastHealth = pCustom.GetKeyvalue( "$fl_lastHealth" ).GetFloat();
	float flLastPain = pCustom.GetKeyvalue( "$fl_lastPain" ).GetFloat();

	if ( flLastHealth <= pPlayer.pev.health )
		return;

	pCustom.SetKeyvalue( "$fl_lastHealth", pPlayer.pev.health );

	if ( flLastPain > g_Engine.time )
		return;

	if ( pPlayer.pev.health <= 0 )
		return;

	float flDmg = pPlayer.m_lastPlayerDamageAmount;

	if ( flDmg < 5.0 || ( flLastHealth - pPlayer.pev.health < 5.0 ) )
		return;

	int iDmgType = pPlayer.m_bitsDamageType;
	string sName;

	if ( ( iDmgType & DMG_BURN ) != 0 || ( iDmgType & DMG_ACID ) != 0 )
	{
		// we're in lava or acid or some shit, scream properly
		sName = "quake1/player/burn" + string( Math.RandomLong( 1, 2 ) ) + ".wav";
	}
	else if ( ( iDmgType & DMG_FALL ) != 0 )
	{
		// fell
		sName = "quake1/player/fall.wav";
	}
	else
	{
		// scream with intensity proportional to damage value
		int iNum = 1 + int( flDmg / 20 ) + Math.RandomLong( 0, 2 );
		if ( iNum > 6 ) iNum = 6;
		if ( iNum < 1 ) iNum = 1;
		sName = "quake1/player/pain" + string( iNum ) + ".wav";
	}

	pCustom.SetKeyvalue( "$fl_lastPain", g_Engine.time + 1.0 );
	g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_VOICE, sName, Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM );
}
*/
void q1_PlayPlayerJumpSounds( CBasePlayer@ pPlayer )
{
	if ( !pPlayer.IsAlive() )
		return; // don't HUP if dead
/*
	if ( ( pPlayer.m_afButtonPressed & IN_JUMP ) != 0 && ( pPlayer.pev.waterlevel < WATERLEVEL_WAIST ) )
	{
		TraceResult tr;
		// gotta trace it because we already jumped at this point
		// this is a hack, but there's no PlayerJump hook or anything, so it'll do
		g_Utility.TraceHull( pPlayer.pev.origin, pPlayer.pev.origin + Vector( 0, 0, -5 ), dont_ignore_monsters, human_hull, pPlayer.edict(), tr );
		if ( tr.flFraction < 1.0 )
			g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_VOICE, "quake1/player/jump.wav", Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM );
	}
*/
	// without trace, check buttons in prethink
	if ( ( pPlayer.pev.button & IN_JUMP ) != 0 && ( pPlayer.pev.oldbuttons & IN_JUMP ) == 0 && pPlayer.pev.FlagBitSet( FL_ONGROUND ) && ( pPlayer.pev.waterlevel < WATERLEVEL_WAIST ) )
		g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_VOICE, "quake1/player/jump.wav", Math.RandomFloat( 0.95, 1.0 ), ATTN_NORM );

/*	if ( ( pPlayer.pev.button & IN_ATTACK2 ) != 0 && ( pPlayer.pev.oldbuttons & IN_ATTACK2 ) == 0 )
	{
		CBaseEntity@ pCamera = FindIntermission();
		if ( pCamera is null )
			return;

		g_EngineFuncs.SetView( pPlayer.edict(), pCamera.edict() );

		Vector vecPos = pCamera.GetOrigin();
			
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCENTER, "Intermission pos: " + vecPos.x + " " + vecPos.y + " " + vecPos.z + "\n" );*/

/*		CBaseEntity@ pCamera = g_EntityFuncs.RandomTargetname( "q1_camera" );
		if ( pCamera is null )
			return;

		pCamera.Use( pPlayer, pPlayer, USE_ON );
	//	g_EngineFuncs.SetView( pPlayer.edict(), pCamera.edict() );

		MakeStatsMsg();

		if ( !g_szIntermissionMsg.IsEmpty() )
			Message( null, g_szIntermissionMsg, -1, -1, 30 );
	}*/
	
	if ( g_bShowQuickStats && ( pPlayer.pev.button & IN_RELOAD ) != 0 && ( pPlayer.pev.oldbuttons & IN_RELOAD ) == 0 )
		g_EngineFuncs.ClientPrintf( pPlayer, print_center, "Secrets: " + g_iFoundSecrets + "/" + g_iTotalSecrets + "\n\nKills: " + g_iKilledMonsters + "/" + g_iTotalMonsters + "\n" );
}

void q1_PlayPlayerWaterSounds( CBasePlayer@ pPlayer )
{
	if ( !pPlayer.IsAlive() )
		return;

	if ( pPlayer.pev.movetype == MOVETYPE_NOCLIP )
	{
		pPlayer.pev.air_finished = g_Engine.time + 12;
		return;
	}
	
	int iWatertype = pPlayer.pev.watertype;

	if ( iWatertype != CONTENTS_WATER && iWatertype != CONTENTS_SLIME)
		return;

	if ( pPlayer.pev.waterlevel != WATERLEVEL_HEAD )
	{
		// play 'up for air' sound
		string sName;
		if ( pPlayer.pev.air_finished < g_Engine.time )
			sName = "quake1/player/gasp2.wav";
		else if ( pPlayer.pev.air_finished < g_Engine.time + 9 )
			sName = "quake1/player/gasp1.wav";

		pPlayer.pev.air_finished = g_Engine.time + 12;
		
		if ( !sName.IsEmpty() )
			g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_VOICE, sName, 1.0, ATTN_NORM );
	}
}

void q1_PlayPlayerLandSounds( CBasePlayer@ pPlayer )
{
	CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
	float flJumpFlag = pCustom.GetKeyvalue( "$fl_jumpFlag" ).GetFloat();

	// check to see if player landed and play landing sound	
	if ( ( flJumpFlag < -300 ) && pPlayer.pev.FlagBitSet( FL_ONGROUND ) && ( pPlayer.pev.health > 0 ) )
	{
		string sName;
		if ( pPlayer.pev.watertype == CONTENTS_WATER )
			sName = "quake1/player/h2ojump.wav";
		else if ( flJumpFlag >= -PLAYER_MAX_SAFE_FALL_SPEED )
			sName = "quake1/player/land.wav";
		
		if ( !sName.IsEmpty() )
			g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_VOICE, sName, 1.0, ATTN_NORM );

		pCustom.SetKeyvalue( "$fl_jumpFlag", 0.0 );

	//	g_EngineFuncs.ServerPrint( "flJumpFlag: " + flJumpFlag + "\n" );
	}

	if ( !pPlayer.pev.FlagBitSet( FL_ONGROUND ) )
		pCustom.SetKeyvalue( "$fl_jumpFlag", pPlayer.pev.velocity.z );
}

void q1_PrecachePlayerSounds()
{
	g_SoundSystem.PrecacheSound( "quake1/player/pain1.wav" );
	g_SoundSystem.PrecacheSound( "quake1/player/pain2.wav" );
	g_SoundSystem.PrecacheSound( "quake1/player/pain3.wav" );
	g_SoundSystem.PrecacheSound( "quake1/player/pain4.wav" );
	g_SoundSystem.PrecacheSound( "quake1/player/pain5.wav" );
	g_SoundSystem.PrecacheSound( "quake1/player/pain6.wav" );
	g_SoundSystem.PrecacheSound( "quake1/player/burn1.wav" );
	g_SoundSystem.PrecacheSound( "quake1/player/burn2.wav" );
	g_SoundSystem.PrecacheSound( "quake1/player/death1.wav" );
	g_SoundSystem.PrecacheSound( "quake1/player/death2.wav" );
	g_SoundSystem.PrecacheSound( "quake1/player/death3.wav" );
	g_SoundSystem.PrecacheSound( "quake1/player/death4.wav" );
	g_SoundSystem.PrecacheSound( "quake1/player/death5.wav" );
	g_SoundSystem.PrecacheSound( "quake1/player/gasp1.wav" );
	g_SoundSystem.PrecacheSound( "quake1/player/gasp2.wav" );
	g_SoundSystem.PrecacheSound( "quake1/player/drown1.wav" );
	g_SoundSystem.PrecacheSound( "quake1/player/drown2.wav" );
	g_SoundSystem.PrecacheSound( "quake1/player/h2odeath.wav" );
	g_SoundSystem.PrecacheSound( "quake1/player/h2ojump.wav" );
	g_SoundSystem.PrecacheSound( "quake1/player/jump.wav" );
	g_SoundSystem.PrecacheSound( "quake1/player/land.wav" );
	g_SoundSystem.PrecacheSound( "quake1/player/fall.wav" );
	g_SoundSystem.PrecacheSound( "quake1/gib.wav" );
}

bool TaskExist( CScheduledFunction@ pFunction )
{
	if ( pFunction is null )
		return false;

	return !pFunction.HasBeenRemoved();
}
