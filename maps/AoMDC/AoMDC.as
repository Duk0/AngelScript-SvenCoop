// Afraid of Monsters: Director's Cut Script
// Main Script
// Author: Zorbos

// Weapons are NOT allowed to be given on these maps
const array<string> AOMDC_LIST_NOWEAPON = {"aomdc_1tutorial", "aomdc_2tutorial", "aomdc_3tutorial",
										   "aomdc_1nightmare", "aomdc_2nightmare", "aomdc_3nightmare",
										   "aomdc_1intro", "aomdc_2intro", "aomdc_3intro",
										   "aomdc_1end", "aomdc_2end", "aomdc_3end", "aomdc_4end", "aomdc_4mother"};
										   		
// Ending 1 Maplist
// Array indices are used as a means of deciding which maps are farther than others.
// Used for giving out weapons and ammo to the player.
const array<string> AOMDC_LIST_E1 = {"aomdc_1hospital", "aomdc_1hospital2", "aomdc_1garage", "aomdc_1backalley", "aomdc_1darkalley",
									 "aomdc_1sewer", "aomdc_1city", "aomdc_1city2", "aomdc_1cityx", "aomdc_1ridingcar",
									 "aomdc_1carforest", "aomdc_1afterforest", "aomdc_1angforest", "aomdc_1forhouse",
									 "aomdc_1forest2", "aomdc_1forest3", "aomdc_1heaven1", "aomdc_1heaven2"};

// Ending 2 Maplist										 
const array<string> AOMDC_LIST_E2 = {"aomdc_2hospital", "aomdc_2hospital2", "aomdc_2garage", "aomdc_2backalley", "aomdc_2darkalley",
									 "aomdc_2sewer", "aomdc_2city", "aomdc_2city2", "aomdc_2city3", "aomdc_2sick",
									 "aomdc_2sick2", "aomdc_2sorgarden", "aomdc_2sorgarden2", "aomdc_2arforest",
									 "aomdc_2afterforest", "aomdc_2angforest", "aomdc_2forhouse",
									 "aomdc_2forest2", "aomdc_2forest3", "aomdc_2heaven1", "aomdc_2heaven2"};

// Ending 3 Maplist	
const array<string> AOMDC_LIST_E3 = {"aomdc_3hospital", "aomdc_3hospital2", "aomdc_3garage", "aomdc_3backalley", "aomdc_3darkalley",
									 "aomdc_3sewer", "aomdc_3city", "aomdc_3city2", "aomdc_3city3", "aomdc_3city4", "aomdc_3cityz",
									 "aomdc_3sick", "aomdc_3sick2", "aomdc_3sorgarden", "aomdc_3sorgarden2",
									 "aomdc_3arforest", "aomdc_3afterforest", "aomdc_3angforest", "aomdc_3forhouse",
									 "aomdc_3forest2", "aomdc_3forest3", "aomdc_3heaven1", "aomdc_3heaven2"};

// Fix inventory trigger_once Maplist
const array<string> AOMDC_LIST_WAIT_FIX = { "aomdc_1hospital", "aomdc_1backalley", "aomdc_1forhouse",
											"aomdc_2hospital", "aomdc_2backalley", "aomdc_2city3", "aomdc_2sorgarden", "aomdc_2forhouse",
											"aomdc_3hospital", "aomdc_3backalley", "aomdc_3city3", "aomdc_3city4", "aomdc_3cityz", "aomdc_3sorgarden", "aomdc_3forhouse"}; 

const bool g_bEasyPickup = false;
const bool g_bNoLimitWeapons = true;
string g_szCurrentMap;

#include "weapon_dcberetta"
#include "weapon_dcp228"
#include "weapon_dcglock"
#include "weapon_dchammer"
#include "weapon_dcknife"
#include "weapon_dcmp5k"
#include "weapon_dcuzi"
#include "weapon_dcshotgun"
#include "weapon_dcrevolver"
#include "weapon_dcdeagle"
#include "weapon_dcaxe"
#include "weapon_dcl85a1"
#include "ammo_dcglock"
#include "ammo_dcdeagle"
#include "ammo_dcrevolver"
#include "ammo_dcmp5k"
#include "ammo_dcshotgun"
#include "item_aompills"
#include "item_aombattery"
#include "point_checkpoint"
#include "monster_hellhound"
#include "monster_ghost"
#include "AttachKeySpr"
#include "weaponmaker"
									 									 
CScheduledFunction@ g_pInterval = null;

bool g_bShouldGiveWeapons, g_bCanGiveMelee, g_bCanGivePrimary, g_bCanGiveMagnum;
int g_iAmmo9mm, g_iAmmo357, g_iAmmoShotgun, g_iAmmo556;

void MapInit()
{ 
	// Register weapons
	RegisterDCBeretta();
	RegisterDCP228();
	RegisterDCGlock();
	RegisterDCHammer();
	RegisterDCKnife();
	RegisterDCMP5K();
	RegisterDCUzi();
	RegisterDCShotgun();
	RegisterDCRevolver();
	RegisterDCDeagle();
	RegisterDCAxe();
	RegisterDCL85A1();
	
	// Register monsters
	AOMHellhound::Register();
	AOMGhost::Register();
	
	// Register pills and batteries
	RegisterAOMBattery();
	RegisterAOMPills();
	
	// Register misc entities
	g_CustomEntityFuncs.RegisterCustomEntity( "ammo_dcglock", "ammo_dcglock" );
	g_CustomEntityFuncs.RegisterCustomEntity( "ammo_dcdeagle", "ammo_dcdeagle" );
	g_CustomEntityFuncs.RegisterCustomEntity( "ammo_dcrevolver", "ammo_dcrevolver" );
	g_CustomEntityFuncs.RegisterCustomEntity( "ammo_dcmp5k", "ammo_dcmp5k" );
	g_CustomEntityFuncs.RegisterCustomEntity( "ammo_dcshotgun", "ammo_dcshotgun" );
	g_CustomEntityFuncs.RegisterCustomEntity( "weaponmaker", "weaponmaker" );
	RegisterPointCheckPointEntity();
	
	// Hooks
	g_Hooks.RegisterHook( Hooks::Player::PlayerSpawn, @PlayerSpawn );
	g_Hooks.RegisterHook( Hooks::Game::MapChange, @MapChange );
}

void MapActivate()
{
	g_szCurrentMap = g_Engine.mapname;
	bool bHospital = false;
	
	if ( g_szCurrentMap.ICompare( "aomdc_1hospital" ) == 0
		|| g_szCurrentMap.ICompare( "aomdc_2hospital" ) == 0 || g_szCurrentMap.ICompare( "aomdc_3hospital" ) == 0 )
		bHospital = true;

	CBaseEntity@ pEntity = null;
	string szTarget;

	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "trigger_auto" ) )  !is null )
	{
		szTarget = pEntity.pev.target;

		if ( szTarget.Compare( "relay_randomize_items" ) == 0 || szTarget.Compare( "relay_randomize_ammo" ) == 0 )
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "delay", "1" );
	}

	@pEntity = null;
	string szMessage;

	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "weaponmaker" ) )  !is null )
	{
		szMessage = pEntity.pev.message;
	
		if ( !bHospital && szMessage.Compare( "weapon_dcp228" ) == 0 )
		{
			pEntity.pev.message = string_t( "weapon_dcberetta" );
			continue;
		}

		if ( szMessage.Compare( "weapon_dcshotgun" ) != 0 )
			continue;

		if ( Math.RandomLong( 0, 1 ) == 0 )
			pEntity.pev.message = string_t( "weapon_dcuzi" );
		else
			pEntity.pev.message = string_t( "weapon_dcmp5k" );
	}
}

void MapStart()
{
	// Parsers
	if ( !g_bNoLimitWeapons )
		@g_pInterval = g_Scheduler.SetInterval( "CheckDroppedWeapons", 15, -1 );

	g_Scheduler.SetTimeout( "CheckFLPlugin", 2 );
	g_Scheduler.SetTimeout( "CheckSurvival", 0.1 );

	g_EngineFuncs.CVarSetFloat( "mp_dropweapons", 1 );
}

// Check if survival is enabled and execute certain entities
void CheckSurvival()
{
	// Is survival on?
	bool bSurvivalEnabled = g_SurvivalMode.MapSupportEnabled() && g_SurvivalMode.IsEnabled();

	const array<string> RemoveTargetnamesSurvivalOn = {"mm_checkpoint1", "mm_checkpoint2", "checkpoint_spr1", "checkpoint_spr2", "checkpoint_txt", "spr_checkpoint1", "spr_checkpoint2"};
	const array<string> RemoveTargetnamesSurvivalOff = {"start_block", "relay_init_map", "survival_weapons"};
	
	// Activate the built in relays
	if ( bSurvivalEnabled )
		g_EntityFuncs.FireTargets( "relay_survivalenabled", null, null, USE_ON, 0, 0 );
	else
		g_EntityFuncs.FireTargets( "relay_survivaldisabled", null, null, USE_ON, 0, 0 );

	CBaseEntity@ pEntity = null;
/*	
	// Now, search for survival/non-survival specific entities
	for ( int pIndex = g_Engine.maxClients; pIndex < g_Engine.maxEntities; ++pIndex )
	{
		@pEntity = g_EntityFuncs.Instance( pIndex );
		
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
		
	if ( AOMDC_LIST_WAIT_FIX.find( g_szCurrentMap ) >= 0 )
	{
		// Fix inventory trigger_once wait time
		@pEntity = null;

		while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "trigger_once" ) ) !is null )
		{
		//	if ( pEntity.pev.target == "multin1_3" || pEntity.pev.target == "multin2_4" )
			
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "wait", "1" );
		}
	}

	// Is this map a map that we should give weapons on?
	g_bShouldGiveWeapons = AOMDC_LIST_NOWEAPON.find( g_szCurrentMap ) < 0;

	// Only start giving the knife after the first map it naturally occurs in
	g_bCanGiveMelee = AOMDC_LIST_E1.find( g_szCurrentMap ) > AOMDC_LIST_E1.find( "aomdc_1hospital" )
		   || AOMDC_LIST_E2.find( g_szCurrentMap ) > AOMDC_LIST_E2.find( "aomdc_2hospital" )
		   || AOMDC_LIST_E3.find( g_szCurrentMap ) > AOMDC_LIST_E3.find( "aomdc_3hospital" );
	
	// Only start giving the shotgun after the first map it naturally occurs in
	g_bCanGivePrimary = AOMDC_LIST_E1.find( g_szCurrentMap ) > AOMDC_LIST_E1.find( "aomdc_1hospital2" )
		   || AOMDC_LIST_E2.find( g_szCurrentMap ) > AOMDC_LIST_E2.find( "aomdc_2hospital2" )
		   || AOMDC_LIST_E3.find( g_szCurrentMap ) > AOMDC_LIST_E3.find( "aomdc_3hospital2" );
	
	// Only start giving the deagle after the first map it naturally occurs in		
	g_bCanGiveMagnum = AOMDC_LIST_E1.find( g_szCurrentMap ) > AOMDC_LIST_E1.find( "aomdc_1backalley" )
		   || AOMDC_LIST_E2.find( g_szCurrentMap ) > AOMDC_LIST_E2.find( "aomdc_2backalley" )
		   || AOMDC_LIST_E3.find( g_szCurrentMap ) > AOMDC_LIST_E3.find( "aomdc_3backalley" );

	g_iAmmo9mm = g_PlayerFuncs.GetAmmoIndex( "9mm" );
	g_iAmmo357 = g_PlayerFuncs.GetAmmoIndex( "357" );
	g_iAmmoShotgun = g_PlayerFuncs.GetAmmoIndex( "buckshot" );
	g_iAmmo556 = g_PlayerFuncs.GetAmmoIndex( "556" );
}

// Checks if the Flashlight plugin is installed. If yes, spawns batteries. Otherwise does nothing.
void CheckFLPlugin()
{
	array<string> pluginList = g_PluginManager.GetPluginList();
		
	if ( pluginList.find( "AoMDCFlashlight" ) >= 0 )
	{
		g_EngineFuncs.ServerPrint( "\nAoMDCFlashlight plugin FOUND. Spawning batteries..\n" );
		g_Scheduler.SetTimeout( "RandomizeBatteries", 2 ); // Spawn the batteries
	}
	else
	{
		g_EngineFuncs.ServerPrint( "\nINFO: Could not find AoMDCFlashlight plugin. Batteries not spawned.\n" );
		g_EngineFuncs.ServerPrint( "Make sure you add the plugin to default_plugins.txt\n" );
	}
}


// Anti-spam countermeasure (in case the ones built into the weapons themselves fail)
// Scans the map for dropped weapons and removes some if there are too many
void CheckDroppedWeapons()
{
	int numDropped = 0;
	CBaseEntity@ pEntity = null;

	// Find dropped weapons by targetname
	while ( ( @pEntity = g_EntityFuncs.FindEntityByTargetname( pEntity, "weapon_dropped" ) ) !is null )
	{
		numDropped++;
	}

	if ( numDropped <= 20 )
		return;
	
	// Sets an upper bound on dropped weapons to prevent spam.
	// If there are more than 20 weapons dropped, then someone is most likely spamming
	@pEntity = null;
	
	while ( numDropped > 20 && ( @pEntity = g_EntityFuncs.FindEntityByTargetname( pEntity, "weapon_dropped" ) ) !is null )
	{
		g_EntityFuncs.Remove( pEntity );
		numDropped--;
	}
}

// Randomizes battery spawns by deleting a random amount in random locations
// constrained between a high and low percentage.
void RandomizeBatteries()
{
	int numSpawners = FindSpawners();
	float low, high;
	
	if ( numSpawners >= 30 ) // Remove most of the spawners
	{
		low = 0.30;
		high = 0.40;
	}
	else if ( numSpawners >= 10 && numSpawners < 30 ) // Remove a little more of the spawners
	{
		low = 0.30;
		high = 0.50;
	}
	else if ( numSpawners >= 5 && numSpawners < 10 ) // Remove only a few spawners
	{
		low = 0.60;
		high = 0.75;
	}
	else // Not enough spawners to randomize. Don't do anything.
		return;
	
	float spawnersToRemove = numSpawners - Math.Ceil( numSpawners * Math.RandomFloat( low, high ) );
	
	// Loop and remove random battery spawners until a given percent remain
	for ( float i = 0; i < spawnersToRemove; i += 1 )
	{
		CBaseEntity@ thisSpawner = g_EntityFuncs.RandomTargetname( "batteryspawner" );

		if ( thisSpawner is null )
			continue;

		g_EntityFuncs.Remove( thisSpawner );
	}
	
	// Now, activate the remaining spawners
	g_EntityFuncs.FireTargets( "batteryspawner", null, null, USE_ON, 0, 0 );
	
	g_EngineFuncs.ServerPrint( "\nSpawners successfully randomized..\n" );
}

// Returns the number of battery spawners present in the map
int FindSpawners()
{
	int numSpawners = 0;
	
	// Count batteries	
	CBaseEntity@ pEntity = null;

	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "monstermaker" ) ) !is null )
	{
		if ( pEntity.GetTargetname() == "batteryspawner" )
			numSpawners++;
	}
	
	g_EngineFuncs.ServerPrint( "\nFindSpawners() finds " + numSpawners + " spawners.\n" );
	
	return numSpawners;
}

// Equips players with both weapons and ammunition if certain conditions are met
void EquipPlayer( CBasePlayer@ pPlayer )
{
	if ( g_bShouldGiveWeapons )
	{
		bool bPlayerHasMelee = false, bPlayerHasPistol = false, bPlayerHasPrimary = false, bPlayerHasMagnum = false;
	
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

				if ( !bPlayerHasMelee && ( szName.Compare( "weapon_dcknife" ) == 0
					|| szName.Compare( "weapon_dchammer" ) == 0 || szName.Compare( "weapon_dcaxe" ) == 0 ) )
					bPlayerHasMelee = true;

				if ( !bPlayerHasPistol && ( szName.Compare( "weapon_dcberetta" ) == 0
					|| szName.Compare( "weapon_dcp228" ) == 0 || szName.Compare( "weapon_dcglock" ) == 0 ) )
					bPlayerHasPistol = true;

				if ( !bPlayerHasPrimary && ( szName.Compare( "weapon_dcshotgun" ) == 0
					|| szName.Compare( "weapon_dcmp5k" ) == 0 || szName.Compare( "weapon_dcuzi" ) == 0 ) )
					bPlayerHasPrimary = true;

				if ( !bPlayerHasMagnum && ( szName.Compare( "weapon_dcrevolver" ) == 0
					|| szName.Compare( "weapon_dcdeagle" ) == 0 ) )
					bPlayerHasMagnum = true;
			}
			while( ( @pPlayerItem = cast<CBasePlayerItem@>( pPlayerItem.m_hNextItem.GetEntity() ) ) !is null );
		}
		
	//	g_EngineFuncs.ServerPrint( "bPlayerHasMelee " + ( bPlayerHasMelee ? "Yes" : "No" ) + ", g_bCanGiveMelee " + ( g_bCanGiveMelee ? "Yes" : "No" ) + "\n" );

		if ( !bPlayerHasMelee && g_bCanGiveMelee ) // Does the player have a melee weapon already?
			pPlayer.GiveNamedItem( "weapon_dcknife" );
			
		if ( !bPlayerHasPistol && g_bCanGiveMelee ) // Does the player have a pistol already?
		{
			pPlayer.GiveNamedItem( "weapon_dcp228" );
			
		/*	if ( g_bNoLimitWeapons )
				pPlayer.GiveNamedItem( "weapon_dcberetta" );*/
		}
			
		if ( !bPlayerHasPrimary && g_bCanGivePrimary ) // Does the player have a primary weapon already?
			pPlayer.GiveNamedItem( "weapon_dcshotgun" );
			
		if ( !bPlayerHasMagnum && g_bCanGiveMagnum ) // Does the player have a magnum already?
			pPlayer.GiveNamedItem( "weapon_dcdeagle" );
		
		// Get player reserve ammo amounts		
		int m_iReserve9mm = pPlayer.m_rgAmmo( g_iAmmo9mm );
		int m_iReserveBuckshot = pPlayer.m_rgAmmo( g_iAmmoShotgun );
		int m_iReserve556 = pPlayer.m_rgAmmo( g_iAmmo556 );
		int m_iReserve357 = pPlayer.m_rgAmmo( g_iAmmo357 );
	
		// Give ammo if necessary (is ammo low enough and are we on a map that needs this ammo?)
		if ( g_bCanGiveMelee && m_iReserve9mm < 85 )
			pPlayer.m_rgAmmo( g_iAmmo9mm, 85 ); // Set the ammo amounts
		if ( g_bCanGivePrimary && m_iReserveBuckshot < 16 )
			pPlayer.m_rgAmmo( g_iAmmoShotgun, 16 );
		if ( g_bCanGivePrimary && m_iReserve556 < 30 )
			pPlayer.m_rgAmmo( g_iAmmo556, 30 );
		if ( g_bCanGiveMagnum && m_iReserve357 < 7 )
			pPlayer.m_rgAmmo( g_iAmmo357, 7 );
	}
}

HookReturnCode PlayerSpawn( CBasePlayer@ pPlayer )
{
	if ( pPlayer is null )
		return HOOK_CONTINUE;

	EquipPlayer( pPlayer );
	return HOOK_CONTINUE;
}

HookReturnCode MapChange()
{
	if ( g_bNoLimitWeapons )
		return HOOK_CONTINUE;

	if ( TaskExist( g_pInterval ) )
		g_Scheduler.RemoveTimer( g_pInterval );

	return HOOK_CONTINUE;
}

bool TaskExist( CScheduledFunction@ pFunction )
{
	if ( pFunction is null )
		return false;

	return !pFunction.HasBeenRemoved();
}
