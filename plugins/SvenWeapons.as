dictionary g_dWeapons;
array<array<string>> g_pWeapons = { { "weapon_crowbar" }, { "weapon_pipewrench" }, { "weapon_medkit", "health", "100" }, { "weapon_grapple" },
{ "weapon_9mmhandgun", "9mm", "250" }, { "weapon_glock", "9mm", "250" }, { "weapon_357", "357", "36" }, { "weapon_eagle", "357", "36" }, { "weapon_uzi", "9mm", "250" }, { "weapon_uziakimbo", "9mm", "250" },
{ "weapon_9mmAR", "9mm", "250" }, { "weapon_mp5", "9mm", "250" }, { "weapon_shotgun", "buckshot", "125" }, { "weapon_crossbow", "bolts", "50" }, { "weapon_m16", "556", "600", "argrenades", "10" },
{ "weapon_rpg", "rockets", "5" }, { "weapon_gauss", "uranium", "100" }, { "weapon_egon", "uranium", "100" }, { "weapon_hornetgun", "hornets", "100" },
{ "weapon_handgrenade", "hand grenade", "10" }, { "weapon_satchel", "satchel charge", "5" }, { "weapon_tripmine", "trip mine", "5" }, { "weapon_snark", "snarks", "15" },
{ "weapon_sniperrifle", "m40a1", "15" }, { "weapon_m249", "556", "600" }, { "weapon_sporelauncher", "sporeclip", "30" }, { "weapon_displacer", "uranium", "100" },
{ "weapon_minigun", "556", "600" }, { "weapon_shockrifle", "shock charges", "100" }
};

class WeaponData
{
	string classname;
	string ammoname;
	int ammovalue;
}

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Duko" );
	g_Module.ScriptInfo.SetContactInfo( "group.midu.cz" );
	g_Module.ScriptInfo.SetMinimumAdminLevel( ADMIN_YES );

	uint uiCount = g_pWeapons.length();
	array<string>@ vals;
	uint len = 0;
	WeaponData data;

	for ( uint i = 0; i < uiCount; i++ )
	{
		@vals = g_pWeapons[i];
		len = vals.length();
		
		data.classname = vals[0];
		
		if ( len > 2 )
		{
			data.ammoname = vals[1];
			data.ammovalue = atoi( vals[2] );
		}
		else
		{
			data.ammoname = "";
			data.ammovalue = 0;
		}
		
		g_dWeapons.set( vals[0].SubString( 7 ), data );
	}
}

CClientCommand sc_weapon( "sc_weapon", "<playername/#userid/@list> <weaponname/@all/@ammo/@explosives> - give player a weapon", @cmdGiveWeapon );
CClientCommand sc_item( "sc_item", "<playername/#userid> <itemname/@all> - give player a item", @cmdGiveItem );

void cmdGiveWeapon( const CCommand@ args )
{
	CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();

	if ( pPlayer is null || !pPlayer.IsConnected() )
		return;

	string szArg = args.Arg( 1 );
	szArg.Trim();

	if ( szArg.ICompare( "@list" ) == 0 )
	{
		uint uiCount = g_pWeapons.length();

		g_EngineFuncs.ClientPrintf( pPlayer, print_console, "[SvenWeapon] Weapon list:\n" );

		string szBuffer;
		for ( uint uiIndex = 0; uiIndex < uiCount; uiIndex++ )
			szBuffer += g_pWeapons[uiIndex][0].SubString( 7 ) + "\n";
		
		g_EngineFuncs.ClientPrintf( pPlayer, print_console, szBuffer );

		return;
	}

	if ( args.ArgC() < 3 )
	{
		g_EngineFuncs.ClientPrintf( pPlayer, print_console, "Usage: ." + sc_weapon.GetName() + " " + sc_weapon.GetHelpInfo() + "\n" );
		return;
	}

	CBasePlayer@ pTarget = GetTargetPlayer( pPlayer, szArg );

	if ( pTarget is null )
		return;

	string szWeapon = args.Arg( 2 );
	szWeapon.Trim();
	szWeapon.ToLowercase();

	WeaponData data;
	if ( g_dWeapons.get( szWeapon, data ) )
	{
		if ( pTarget.HasNamedPlayerItem( data.classname ) is null )
		{
			if ( data.classname == "weapon_minigun" || data.classname == "weapon_shockrifle" )
				GiveWeapon( pTarget, data.classname );
			else
				pTarget.GiveNamedItem( data.classname, 0, data.ammovalue );
		}
		
		if ( !data.ammoname.IsEmpty() )
			pTarget.GiveAmmo( data.ammovalue, data.ammoname, data.ammovalue, false );

		if ( data.classname == "weapon_m16" )
			pTarget.GiveAmmo( 10, "argrenades", 10, false );
	}
	else if ( szWeapon.ICompare( "@all" ) == 0 )
	{
		pTarget.GiveNamedItem( "weapon_crowbar" );
		pTarget.GiveNamedItem( "weapon_pipewrench" );
		pTarget.GiveNamedItem( "weapon_medkit" );
		pTarget.GiveNamedItem( "weapon_grapple" );
		pTarget.GiveNamedItem( "weapon_hornetgun" );
		pTarget.GiveNamedItem( "weapon_357", ITEM_FLAG_SELECTONEMPTY, 36 );
		pTarget.GiveNamedItem( "weapon_eagle", ITEM_FLAG_SELECTONEMPTY, 36 );
		pTarget.GiveNamedItem( "weapon_crossbow", ITEM_FLAG_SELECTONEMPTY, 50 );
		pTarget.GiveNamedItem( "weapon_glock", ITEM_FLAG_SELECTONEMPTY, 250 );
		pTarget.GiveNamedItem( "weapon_gauss", ITEM_FLAG_SELECTONEMPTY, 100 );
		pTarget.GiveNamedItem( "weapon_mp5", ITEM_FLAG_SELECTONEMPTY, 250 );
		pTarget.GiveNamedItem( "weapon_egon", ITEM_FLAG_SELECTONEMPTY, 100 ); 			   
		pTarget.GiveNamedItem( "weapon_rpg", ITEM_FLAG_SELECTONEMPTY, 5 );
		pTarget.GiveNamedItem( "weapon_shotgun", ITEM_FLAG_SELECTONEMPTY, 125 );
		pTarget.GiveNamedItem( "weapon_m16", ITEM_FLAG_SELECTONEMPTY, 600 );
		pTarget.GiveNamedItem( "weapon_m249", ITEM_FLAG_SELECTONEMPTY, 600 );
		pTarget.GiveNamedItem( "weapon_sporelauncher", ITEM_FLAG_SELECTONEMPTY, 30 );
		pTarget.GiveNamedItem( "weapon_sniperrifle", ITEM_FLAG_SELECTONEMPTY, 15 );
		pTarget.GiveNamedItem( "weapon_uziakimbo", ITEM_FLAG_SELECTONEMPTY, 250 );
		pTarget.GiveNamedItem( "weapon_handgrenade", 0, 10 );
		pTarget.GiveNamedItem( "weapon_tripmine", 0, 5 );
		pTarget.GiveNamedItem( "weapon_satchel", 0, 5 );
		pTarget.GiveNamedItem( "weapon_snark", 0, 15 );
		pTarget.GiveNamedItem( "weapon_displacer", ITEM_FLAG_SELECTONEMPTY, 100 );
		//pTarget.GiveNamedItem( "weapon_minigun" );
		//pTarget.GiveNamedItem( "weapon_shockrifle" );

		pTarget.GiveAmmo( 100, "health", 100, false );
		pTarget.GiveAmmo( 250, "9mm", 250, false );
		pTarget.GiveAmmo( 36, "357", 36, false );
		pTarget.GiveAmmo( 125, "buckshot", 125, false );
		pTarget.GiveAmmo( 50, "bolts", 50, false );
		pTarget.GiveAmmo( 600, "556", 600, false );
		pTarget.GiveAmmo( 10, "argrenades", 10, false );
		pTarget.GiveAmmo( 5, "rockets", 5, false );
		pTarget.GiveAmmo( 100, "uranium", 100, false );
		pTarget.GiveAmmo( 100, "hornets", 100, false );
		pTarget.GiveAmmo( 10, "hand grenade", 10, false );
		pTarget.GiveAmmo( 5, "trip mine", 5, false );
		pTarget.GiveAmmo( 15, "snarks", 15, false );
		pTarget.GiveAmmo( 5, "satchel charge", 5, false );
		pTarget.GiveAmmo( 15, "m40a1", 15, false );
		pTarget.GiveAmmo( 30, "sporeclip", 30, false );
		pTarget.GiveAmmo( 100, "shock charges", 100, false );
	}
	else if ( szWeapon.ICompare( "@ammo" ) == 0 )
	{
		pTarget.GiveAmmo( 100, "health", 100, false );
		pTarget.GiveAmmo( 250, "9mm", 250, false );
		pTarget.GiveAmmo( 36, "357", 36, false );
		pTarget.GiveAmmo( 125, "buckshot", 125, false );
		pTarget.GiveAmmo( 50, "bolts", 50, false );
		pTarget.GiveAmmo( 600, "556", 600, false );
		pTarget.GiveAmmo( 10, "argrenades", 10, false );
		pTarget.GiveAmmo( 5, "rockets", 5, false );
		pTarget.GiveAmmo( 100, "uranium", 100, false );
		pTarget.GiveAmmo( 100, "hornets", 100, false );
		pTarget.GiveAmmo( 10, "hand grenade", 10, false );
		pTarget.GiveAmmo( 5, "trip mine", 5, false );
		pTarget.GiveAmmo( 15, "snarks", 15, false );
		pTarget.GiveAmmo( 5, "satchel charge", 5, false );
		pTarget.GiveAmmo( 15, "m40a1", 15, false );
		pTarget.GiveAmmo( 30, "sporeclip", 30, false );
		pTarget.GiveAmmo( 100, "shock charges", 100, false );
	}
	else if ( szWeapon.ICompare( "@explosives" ) == 0 )
	{
		pTarget.GiveNamedItem( "weapon_handgrenade", 0, 10 );
		pTarget.GiveNamedItem( "weapon_tripmine", 0, 5 );
		pTarget.GiveNamedItem( "weapon_snark", 0, 15 );
		pTarget.GiveNamedItem( "weapon_satchel", 0, 5 );

		pTarget.GiveAmmo( 10, "hand grenade", 10, false );
		pTarget.GiveAmmo( 5, "trip mine", 5, false );
		pTarget.GiveAmmo( 15, "snarks", 15, false );
		pTarget.GiveAmmo( 5, "satchel charge", 5, false );
	}
	else
	{
		g_EngineFuncs.ClientPrintf( pPlayer, print_console, "[SvenWeapon] Invalid weapon name!\n" );
		return;
	}

	string szName = pPlayer.pev.netname;
	string szAuthid = g_EngineFuncs.GetPlayerAuthId( pPlayer.edict() );
	int iUserId = g_EngineFuncs.GetPlayerUserId( pPlayer.edict() );

	string szNameTarget = pTarget.pev.netname;
	string szAuthidTarget = g_EngineFuncs.GetPlayerAuthId( pTarget.edict() );
	int iUserIdTarget = g_EngineFuncs.GetPlayerUserId( pTarget.edict() );

	g_Game.AlertMessage( at_logged, "SvenWeapon: \"%1<%2><%3><>\" give weapon \"%4\" to \"%5<%6><%7><>\"\n", szName, iUserId, szAuthid, szWeapon, szNameTarget, iUserIdTarget, szAuthidTarget );
}


void cmdGiveItem( const CCommand@ args )
{
	CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();

	if ( pPlayer is null || !pPlayer.IsConnected() )
		return;

	if ( args.ArgC() < 3 )
	{
		g_EngineFuncs.ClientPrintf( pPlayer, print_console, "Usage: ." + sc_item.GetName() + " " + sc_item.GetHelpInfo() + "\n" );
		return;
	}

	const string szPlayer = args.Arg( 1 );

	CBasePlayer@ pTarget = GetTargetPlayer( pPlayer, szPlayer );

	if ( pTarget is null )
		return;

	const string szItem = args.Arg( 2 );

	if ( szItem.ICompare( "battery" ) == 0 )
	{
		if ( pTarget.pev.armorvalue != pTarget.pev.armortype )
			pTarget.GiveNamedItem( "item_battery", ITEM_FLAG_LIMITINWORLD, 25 );
	}
	else if ( szItem.ICompare( "healthkit" ) == 0 )
	{
		if ( pTarget.pev.health != pTarget.pev.max_health )
			pTarget.GiveNamedItem( "item_healthkit", ITEM_FLAG_LIMITINWORLD, 25 );
	}
	else if ( szItem.ICompare( "longjump" ) == 0 )
	{
		//if ( pTarget.HasNamedPlayerItem( "item_longjump" ) is null )
		if ( !pTarget.m_fLongJump )
			pTarget.GiveNamedItem( "item_longjump", ITEM_FLAG_LIMITINWORLD );
	}
/*
	else if ( szItem.ICompare( "antidote" ) == 0 )
	{
		pTarget.GiveNamedItem( "item_antidote", ITEM_FLAG_LIMITINWORLD );
	}
*/
	else if ( szItem.ICompare( "@all" ) == 0 )
	{
		if ( pTarget.pev.armorvalue != pTarget.pev.armortype )
			pTarget.GiveNamedItem( "item_battery", ITEM_FLAG_LIMITINWORLD, 25 );
		
		if ( pTarget.pev.health != pTarget.pev.max_health )
			pTarget.GiveNamedItem( "item_healthkit", ITEM_FLAG_LIMITINWORLD, 25 );

		//if ( pTarget.HasNamedPlayerItem( "item_longjump" ) is null )
		if ( !pTarget.m_fLongJump )
			pTarget.GiveNamedItem( "item_longjump", ITEM_FLAG_LIMITINWORLD );

		//pTarget.GiveNamedItem( "item_antidote", ITEM_FLAG_LIMITINWORLD );
	}
	else
	{
		g_EngineFuncs.ClientPrintf( pPlayer, print_console, "[SvenWeapon] Invalid item name!\n" );
		return;
	}

	string szName = pPlayer.pev.netname;
	string szAuthid = g_EngineFuncs.GetPlayerAuthId( pPlayer.edict() );
	int iUserId = g_EngineFuncs.GetPlayerUserId( pPlayer.edict() );

	string szNameTarget = pTarget.pev.netname;
	string szAuthidTarget = g_EngineFuncs.GetPlayerAuthId( pTarget.edict() );
	int iUserIdTarget = g_EngineFuncs.GetPlayerUserId( pTarget.edict() );

	g_Game.AlertMessage( at_logged, "SvenWeapon: \"%1<%2><%3><>\" give item \"%4\" to \"%5<%6><%7><>\"\n", szName, iUserId, szAuthid, szItem, szNameTarget, iUserIdTarget, szAuthidTarget );
}

CBasePlayer@ GetTargetPlayer( CBasePlayer@ pPlayer, const string& in szNameOrUserId )
{
	CBasePlayer@ pTarget = g_PlayerFuncs.FindPlayerByName( szNameOrUserId, false );
	int iCount = 0;

	if ( pTarget is null )
	{
		CBasePlayer@ pTempPlayer = null;
		string szPlayerName;
		for ( int iIndex = 1; iIndex <= g_Engine.maxClients; iIndex++ )
		{
			@pTempPlayer = g_PlayerFuncs.FindPlayerByIndex( iIndex );
			
			if ( pTempPlayer is null || !pTempPlayer.IsConnected() )
				continue;

			szPlayerName = pTempPlayer.pev.netname;
			
			if ( int( szPlayerName.Find( szNameOrUserId, 0, String::CaseInsensitive ) ) != -1 )
			{
				@pTarget = pTempPlayer;
				iCount++;
			}
			
			if ( iCount > 1 )
				break;
		}
	}
		
	if ( pTarget is null && szNameOrUserId[0] == "#" )
	{
		string szUserId;
		for ( int iIndex = 1; iIndex <= g_Engine.maxClients; iIndex++ )
		{
			@pTarget = g_PlayerFuncs.FindPlayerByIndex( iIndex );
			
			if ( pTarget is null || !pTarget.IsConnected() )
				continue;

			szUserId = "#" + g_EngineFuncs.GetPlayerUserId( pTarget.edict() );
			
			if ( szUserId == szNameOrUserId )
				break;
					
			@pTarget = null;
		}
	}

	if ( pTarget is null )
	{
		g_EngineFuncs.ClientPrintf( pPlayer, print_console, "Client with that name or userid not found\n" );
		return null;
	}

	if ( iCount > 1 )
	{
		g_EngineFuncs.ClientPrintf( pPlayer, print_console, "There is more than one client matching your argument\n" );
		return null;
	}

	if ( pTarget !is pPlayer && IsPlayerAdmin( pTarget ) )
	{
		g_EngineFuncs.ClientPrintf( pPlayer, print_console, "Client " + pTarget.pev.netname + " has immunity\n" );
		return null;
	}

	if ( !pTarget.IsAlive() )
	{
		g_EngineFuncs.ClientPrintf( pPlayer, print_console, "That action can't be performed on dead client " + pTarget.pev.netname + "\n" );
		return null;
	}
	
	return pTarget;
}

bool IsPlayerAdmin( CBasePlayer@ pPlayer )
{
	return g_PlayerFuncs.AdminLevel( pPlayer ) >= ADMIN_YES;
}

void GiveWeapon( CBasePlayer@ pPlayer, const string& in szItemName )
{
	CBaseEntity@ pEntity = g_EntityFuncs.Create( szItemName, pPlayer.GetOrigin(), g_vecZero, true, pPlayer.edict() );
	if ( pEntity !is null )
  	{
		g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "spawnflags", "1024" );
		g_EntityFuncs.DispatchSpawn( pEntity.edict() );
		
		//pEntity.Use( pPlayer, pPlayer, USE_ON );
	}
}

//as_reloadplugin SvenWeapons
