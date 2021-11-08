// Afraid of Monsters Classic Script
// Main Script
// Author: Zorbos

// Weapons are NOT allowed to be given on these maps
const array<string> AOM_LIST_NOWEAPON = {"aom_training", "aom_intro", "aom_nightmare", "aom_end"};
										 
// Map List
// Array indices are used as a means of deciding which maps are farther than others.
// Used for giving out weapons and ammo to the player.
const array<string> AOM_LIST_MAPS = {"aom_hospital", "aom_hospital2", "aom_garage", "aom_backalley",
								     "aom_darkalley", "aom_city", "aom_city2", "aom_city3", "aom_sick", "aom_sick2",
									 "aom_sick3", "aom_forest", "aom_forhouse", "aom_forest2", "aom_forest3",
									 "aom_heaven1", "aom_heaven2"};

#include "weapon_clak47"
#include "weapon_clberetta"
#include "weapon_cldeagle"
#include "weapon_clknife"
#include "weapon_clshotgun"
#include "point_checkpoint"
#include "ammo_clshotgun"
#include "AttachKeySpr"

bool g_bShouldGiveWeapons, g_bCanGiveMelee, g_bCanGiveShotgun, g_bCanGiveAK47, g_bCanGiveMagnum;
int g_iAmmo9mm, g_iAmmo357, g_iAmmoShotgun;

void MapInit()
{ 
	// Register weapons
	RegisterCLAK47();
	RegisterCLBeretta();
	RegisterCLDeagle();
	RegisterCLKnife();
	RegisterCLShotgun();
	RegisterPointCheckPointEntity();
	
	// Register ammo entities
	g_CustomEntityFuncs.RegisterCustomEntity( "ammo_clshotgun", "ammo_clshotgun" );
	
	// Hooks
	g_Hooks.RegisterHook( Hooks::Player::PlayerSpawn, @PlayerSpawn );
}

void MapStart()
{
	// Parsers
	g_Scheduler.SetTimeout( "CheckSurvival", 0.1 );
}

void CheckSurvival()
{
	const string currentMap = g_Engine.mapname;

	// Is survival on?
	bool bSurvivalEnabled = g_SurvivalMode.MapSupportEnabled() && g_SurvivalMode.IsEnabled();
	
	const array<string> RemoveTargetnamesSurvivalOn = {"mm_checkpoint1", "mm_checkpoint2", "checkpoint_spr1", "checkpoint_spr2", "checkpoint_txt", "spr_checkpoint1", "spr_checkpoint2"};
	const array<string> RemoveTargetnamesSurvivalOff = {"start_block", "relay_init_map"};
	
	CBaseEntity@ pEntity = null;
	
	// Activate the built in relays
	if ( bSurvivalEnabled )
		g_EntityFuncs.FireTargets( "relay_survivalenabled", null, null, USE_ON, 0, 0 );
	else
		g_EntityFuncs.FireTargets( "relay_survivaldisabled", null, null, USE_ON, 0, 0 );
/*	
	// Now, search for survival/non-survival specific entities
	for ( int pIndex = g_Engine.maxClients; pIndex < g_Engine.maxEntities; ++pIndex )
	{
		@pEntity = g_EntityFuncs.Instance(pIndex);
		
		if ( pEntity is null )
			continue;

		if ( bSurvivalEnabled ) // Remove non-survival entities (checkpoints)
		{
			if ( RemoveTargetnamesSurvivalOn.find( pEntity.pev.targetname ) >= 0 )
				g_EntityFuncs.Remove( pEntity );
		}
		else // Remove survival checkpoints and entities
		{
			if ( RemoveTargetnamesSurvivalOff.find( pEntity.pev.targetname ) >= 0 ||
			   pEntity.GetClassname() == "point_checkpoint" || pEntity.pev.globalname == "survival_weapons" )
				g_EntityFuncs.Remove( pEntity );
		}
	}
*/
	// Now, search for survival/non-survival specific entities
	if ( bSurvivalEnabled ) // Remove non-survival entities (checkpoints)
	{
		for ( uint uiIndex = 0; uiIndex < RemoveTargetnamesSurvivalOn.length(); ++uiIndex )
		{
			@pEntity = null;

			while ( ( @pEntity = g_EntityFuncs.FindEntityByTargetname( pEntity, RemoveTargetnamesSurvivalOn[uiIndex] ) ) !is null )
				g_EntityFuncs.Remove( pEntity );
		}
	}
	else // Remove survival checkpoints and entities
	{
		for ( uint uiIndex = 0; uiIndex < RemoveTargetnamesSurvivalOff.length(); ++uiIndex )
		{
			@pEntity = null;

			while ( ( @pEntity = g_EntityFuncs.FindEntityByTargetname( pEntity, RemoveTargetnamesSurvivalOff[uiIndex] ) ) !is null )
				g_EntityFuncs.Remove( pEntity );
		}

		@pEntity = null;

		while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "point_checkpoint" ) ) !is null )
			g_EntityFuncs.Remove( pEntity );
		
		@pEntity = null;

		while ( ( @pEntity = g_EntityFuncs.FindEntityByString( pEntity, "globalname", "survival_weapons" ) ) !is null )
			g_EntityFuncs.Remove( pEntity );
	}
	
	if ( currentMap == "aom_forhouse" )
	{
		// fix inventory trigger_once wait time
		@pEntity = null;

		while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "trigger_once" ) ) !is null )
		{
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "wait", "1" );
		}
	}

	// Is this map a map that we should give weapons on?
	g_bShouldGiveWeapons = AOM_LIST_NOWEAPON.find(currentMap) < 0;

	// Only start giving the knife/beretta after the first map it naturally occurs in
	g_bCanGiveMelee = AOM_LIST_MAPS.find(currentMap) > AOM_LIST_MAPS.find( "aom_hospital" );
	
	// Only start giving the shotgun after the first map it naturally occurs in
	g_bCanGiveShotgun = AOM_LIST_MAPS.find(currentMap) > AOM_LIST_MAPS.find( "aom_hospital2" );
	
	// Only start giving the ak47 after the first map it naturally occurs in
	g_bCanGiveAK47 = AOM_LIST_MAPS.find(currentMap) > AOM_LIST_MAPS.find( "aom_city3" );
	
	// Only start giving the deagle after the first map it naturally occurs in		
	g_bCanGiveMagnum = AOM_LIST_MAPS.find(currentMap) > AOM_LIST_MAPS.find( "aom_backalley" );

	g_iAmmo9mm = g_PlayerFuncs.GetAmmoIndex( "9mm" );
	g_iAmmo357 = g_PlayerFuncs.GetAmmoIndex( "357" );
	g_iAmmoShotgun = g_PlayerFuncs.GetAmmoIndex( "buckshot" );
}

// Equips players with a weapon if they do not already possess one in a respective slot
void EquipPlayer( CBasePlayer@ pPlayer )
{
	if ( g_bShouldGiveWeapons )
	{
		bool bPlayerHasMelee = false, bPlayerHasPistol = false, bPlayerHasShotgun = false, bPlayerHasAK47 = false, bPlayerHasMagnum = false;

		CBasePlayerItem@ pPlayerItem = null;
		string szName;
		
		for ( size_t uiIndex = 0; uiIndex < MAX_ITEM_TYPES; ++uiIndex )
		{
			@pPlayerItem = pPlayer.m_rgpPlayerItems( uiIndex );
			
			if ( pPlayerItem is null )
				continue;

			do
			{
				szName = pPlayerItem.pszName();

				if ( !bPlayerHasMelee && szName.Compare( "weapon_clknife" ) == 0 )
					bPlayerHasMelee = true;

				if ( !bPlayerHasPistol && szName.Compare( "weapon_clberetta" ) == 0 )
					bPlayerHasPistol = true;

				if ( !bPlayerHasShotgun && szName.Compare( "weapon_clshotgun" ) == 0 )
					bPlayerHasShotgun = true;

				if ( !bPlayerHasAK47 && szName.Compare( "weapon_clak47" ) == 0 )
					bPlayerHasAK47 = true;

				if ( !bPlayerHasMagnum && szName.Compare( "weapon_cldeagle" ) == 0 )
					bPlayerHasMagnum = true;
			}
			while( ( @pPlayerItem = cast<CBasePlayerItem@>( pPlayerItem.m_hNextItem.GetEntity() ) ) !is null );
		}
		
		if ( !bPlayerHasMelee && g_bCanGiveMelee ) // Does the player have a melee weapon already?
			pPlayer.GiveNamedItem("weapon_clknife");
			
		if ( !bPlayerHasPistol && g_bCanGiveMelee ) // Does the player have a pistol already?
			pPlayer.GiveNamedItem("weapon_clberetta");
			
		if ( !bPlayerHasShotgun && g_bCanGiveShotgun ) // Does the player have a shotgun already?
			pPlayer.GiveNamedItem("weapon_clshotgun");
				
		if ( !bPlayerHasAK47 && g_bCanGiveAK47 ) // Does the player have an ak47 already?
			pPlayer.GiveNamedItem("weapon_clak47");
			
		if ( !bPlayerHasMagnum && g_bCanGiveMagnum ) // Does the player have a magnum already?
			pPlayer.GiveNamedItem("weapon_cldeagle");
				
		// Get player reserve ammo amounts		
		int iReserve9mm = pPlayer.m_rgAmmo( g_iAmmo9mm );
		int iReserveBuckshot = pPlayer.m_rgAmmo( g_iAmmoShotgun );
		int iReserve357 = pPlayer.m_rgAmmo( g_iAmmo357 );
	
		// Give ammo if necessary (is ammo low enough and are we on a map that needs this ammo?)
		if ( g_bCanGiveMelee && iReserve9mm < 65 )
			pPlayer.m_rgAmmo( g_iAmmo9mm, 65); // Set the ammo amounts
		if ( g_bCanGiveShotgun && iReserveBuckshot < 12 )
			pPlayer.m_rgAmmo( g_iAmmoShotgun, 12);
		if ( g_bCanGiveMagnum && iReserve357 < 6 )
			pPlayer.m_rgAmmo( g_iAmmo357, 6);
	}
}

HookReturnCode PlayerSpawn( CBasePlayer@ pPlayer )
{
	if ( pPlayer is null )
		return HOOK_CONTINUE;

	EquipPlayer( pPlayer );
	return HOOK_CONTINUE;
}
