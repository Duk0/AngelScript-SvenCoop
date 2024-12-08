const string g_szIssuesPath = "scripts/plugins/store/issues/";
array<string> g_pEntities;
int g_iIssues = 0;
HUDTextParams g_hudTxtParam;
//array<CScheduledFunction@> g_pDelayedMsgFunction( g_Engine.maxClients + 1, null );
//array<string> g_pShootModelList = { "models/woodgibs.mdl", "models/metalgibs.mdl", "models/cindergibs.mdl" };

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Duko" );
	g_Module.ScriptInfo.SetContactInfo( "group.midu.cz" );
	g_Module.ScriptInfo.SetMinimumAdminLevel( ADMIN_YES );

	g_Hooks.RegisterHook( Hooks::Player::ClientPutInServer, @ClientPutInServer );
	g_Hooks.RegisterHook( Hooks::Game::MapChange, @MapChange );

	g_hudTxtParam.r1 = 255;
	g_hudTxtParam.g1 = 30;
	g_hudTxtParam.b1 = 30;
	g_hudTxtParam.a1 = 100;
	g_hudTxtParam.r2 = 255;
	g_hudTxtParam.g2 = 255;
	g_hudTxtParam.b2 = 250;
	g_hudTxtParam.a2 = 0;

	g_hudTxtParam.x = 0.01;
	g_hudTxtParam.y = 0.01;

	g_hudTxtParam.effect = 0;

	g_hudTxtParam.fxTime = 0.;
	g_hudTxtParam.holdTime = 30;
					
	g_hudTxtParam.fadeinTime = 0;
	g_hudTxtParam.fadeoutTime = 0;

	g_hudTxtParam.channel = 7;
	
	g_EngineFuncs.ServerPrint( "[FixMe] Reloaded...\n" );
}

HookReturnCode ClientPutInServer( CBasePlayer@ pPlayer )
{
	if ( pPlayer is null )
		return HOOK_CONTINUE;
		
	if ( !IsPlayerAdmin( pPlayer ) )
		return HOOK_CONTINUE;
		
	int iPlayer = pPlayer.entindex();
	g_Scheduler.SetTimeout( "DelayedMsg", 8, iPlayer );

	return HOOK_CONTINUE;
}

HookReturnCode MapChange( const string& in szNextMap )
{
	g_Scheduler.ClearTimerList();

	return HOOK_CONTINUE;
}

void MapStart()
{
	if ( g_iIssues > 0 )
	{
		g_pEntities.resize( 0 );
		g_iIssues = 0;
	}

	g_Scheduler.SetTimeout( "FixMe", 7 );
}

void DelayedMsg( int iPlayer )
{
	CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );

	if ( pPlayer is null || !pPlayer.IsConnected() )
		return;

	if ( g_iIssues == 0 )
		return;

	g_PlayerFuncs.HudMessage( pPlayer, g_hudTxtParam, "!Found " + g_iIssues + " issues!\nFor list of issues\ntype .issues in console" );
}

void FixMe()
{
	CBaseEntity@ pEntity = null;
	CBaseEntity@ pEnt = null;
	CBaseToggle@ pToggle;
	CBaseDelay@ pDelay;
	Vector vecOrigin;
	string szTargetName, szTarget, szMaster, szModel;
	int iCount = 0;
	bool bFound = false;
	bool bHasTarget = false;

	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "trigger_teleport" ) ) !is null )
	{
		szTargetName = pEntity.GetTargetname();
		if ( szTargetName.IsEmpty() )
			continue;
			
		if ( pEntity.pev.SpawnFlagBitSet( 4096 ) )
			continue;
		
		@pToggle = cast<CBaseToggle@>( pEntity );
		if ( pToggle is null )
			continue;
		
		szMaster = pToggle.m_sMaster;
		if ( !szMaster.IsEmpty() && szTargetName != szMaster )
			continue;

		while ( !bFound && ( @pEnt = g_EntityFuncs.FindEntityByClassname( pEnt, "*" ) ) !is null )
		{
			//if ( pEnt.GetClassname() == "trigger_teleport" )
			if ( pEnt is pEntity )
				continue;

			@pDelay = cast<CBaseDelay@>( pEnt );

			if ( pDelay !is null && pDelay.m_iszKillTarget == szTargetName )
				bFound = true;
				
			if ( szTargetName != pEnt.GetTargetname() && pEnt.HasTarget( szTargetName ) )
				bHasTarget = true;
		}

		if ( !bFound )
			@pEnt = null;

		while ( !bFound && ( @pEnt = g_EntityFuncs.FindEntityByString( pEnt, "target", szTargetName ) ) !is null )
		{
			if ( pEnt.GetClassname() == "trigger_changetarget" )
				bFound = true;
		}
		
		if ( bFound )
		{
			@pEnt = null;
			bFound = false;

			if ( bHasTarget ) bHasTarget = false;

			continue;
		}

		if ( bHasTarget ) bHasTarget = false;
		else continue;
		
		vecOrigin = pEntity.Center();
		szModel = pEntity.pev.model;
		g_pEntities.insertLast( "trigger_teleport, origin: " + vecOrigin.x + " " + vecOrigin.y + " " + vecOrigin.z + ", model: " + szModel + ", targetname: " + szTargetName + " non-functional.\n" );

		iCount++;
	}

	if ( iCount > 0 )
	{
		g_pEntities.insertLast( "=> Found " + iCount + " issues with trigger_teleport!\n" );
		g_iIssues += iCount;
		iCount = 0;
	}
/*		
	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "trigger_multiple" ) ) !is null )
	{
		@pToggle = cast<CBaseToggle@>( pEntity );
		if ( pToggle is null )
			continue;

		float flWait = pToggle.m_flWait;
		if ( flWait != 0 )
			continue;

		szTargetName = pEntity.GetTargetname();
		szTarget = pEntity.pev.target;
		vecOrigin = pEntity.Center();
		szModel = pEntity.pev.model;
		g_pEntities.insertLast( "trigger_multiple, origin: " + vecOrigin.x + " " + vecOrigin.y + " " + vecOrigin.z + ", model: " + szModel + ( szTargetName.IsEmpty() ? "" : ", targetname: " + szTargetName ) + ( szTarget.IsEmpty() ? "" : ", target: " + szTarget ) + ", flWait: " + flWait + "\n" );

		iCount++;
	}

	if ( iCount > 0 )
	{
		g_pEntities.insertLast( "=> Found " + iCount + " issues with trigger_multiple!\n" );
		g_iIssues += iCount;
		iCount = 0;
	}
*/
	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "trigger_relay" ) ) !is null )
	{
		szTargetName = pEntity.GetTargetname();
		szTarget = pEntity.pev.target;
		
		if ( !szTarget.IsEmpty() )
			continue;

		@pDelay = cast<CBaseDelay@>( pEntity );
		if ( pDelay is null || !string( pDelay.m_iszKillTarget ).IsEmpty() )
			continue;
			
		vecOrigin = pEntity.GetOrigin();
		g_pEntities.insertLast( "trigger_relay, origin: " + vecOrigin.x + " " + vecOrigin.y + " " + vecOrigin.z + ( szTargetName.IsEmpty() ? "" : ", targetname: " + szTargetName ) + " without target.\n" );
		
		iCount++;
	}

	if ( iCount > 0 )
	{
		g_pEntities.insertLast( "=> Found " + iCount + " issues with trigger_relay!\n" );
		g_iIssues += iCount;
		iCount = 0;
	}

	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "env_shooter" ) ) !is null )
	{
		szTargetName = pEntity.GetTargetname();
		if ( szTargetName.IsEmpty() )
			continue;
		
		szModel = pEntity.pev.model;
/*		if ( g_pShootModelList.find( szModel ) == -1 )
			continue;*/
		
		if ( pEntity.pev.scale < 100 )
			continue;
		
		vecOrigin = pEntity.GetOrigin();
		g_pEntities.insertLast( "env_shooter, origin: " + vecOrigin.x + " " + vecOrigin.y + " " + vecOrigin.z + ", model: " + szModel + ", targetname: " + szTargetName + ", scale: " + pEntity.pev.scale + "\n" );

		iCount++;
	}

	if ( iCount > 0 )
	{
		g_pEntities.insertLast( "=> Found " + iCount + " issues with env_shooter!\n" );
		g_iIssues += iCount;
		iCount = 0;
	}

	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "info_player_deathmatch" ) ) !is null )
	{
		szTargetName = pEntity.GetTargetname();
		if ( !szTargetName.IsEmpty() )
			continue;
		
		if ( !pEntity.pev.SpawnFlagBitSet( 2 ) )
			continue;
		
		vecOrigin = pEntity.GetOrigin();
		g_pEntities.insertLast( "info_player_deathmatch, origin: " + vecOrigin.x + " " + vecOrigin.y + " " + vecOrigin.z + ", spawnflags: " + pEntity.pev.spawnflags + ", without targetname!\n" );

		iCount++;
	}

	if ( iCount > 0 )
	{
		g_pEntities.insertLast( "=> Found " + iCount + " issues with info_player_deathmatch!\n" );
		g_iIssues += iCount;
		iCount = 0;
	}

	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "info_player_dm2" ) ) !is null )
	{
		szTargetName = pEntity.GetTargetname();
		if ( !szTargetName.IsEmpty() )
			continue;
		
		if ( !pEntity.pev.SpawnFlagBitSet( 2 ) )
			continue;
		
		vecOrigin = pEntity.GetOrigin();
		g_pEntities.insertLast( "info_player_dm2, origin: " + vecOrigin.x + " " + vecOrigin.y + " " + vecOrigin.z + ", spawnflags: " + pEntity.pev.spawnflags + ", without targetname!\n" );

		iCount++;
	}

	if ( iCount > 0 )
	{
		g_pEntities.insertLast( "=> Found " + iCount + " issues with info_player_dm2!\n" );
		g_iIssues += iCount;
		iCount = 0;
	}
/*
	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "trigger_random_time" ) ) !is null )
	{
		if ( pEntity.pev.SpawnFlagBitSet( 2 ) )
			continue;

		szTargetName = pEntity.GetTargetname();	
		vecOrigin = pEntity.GetOrigin();

		g_pEntities.insertLast( "trigger_random_time, origin: " + vecOrigin.x + " " + vecOrigin.y + " " + vecOrigin.z + ( szTargetName.IsEmpty() ? "" : ", targetname: " + szTargetName ) + " without Trigger Once flag.\n" );
		
		iCount++;
	}

	if ( iCount > 0 )
	{
		g_pEntities.insertLast( "=> Found " + iCount + " issues with trigger_random_time!\n" );
		g_iIssues += iCount;
		iCount = 0;
	}
*/
	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "trigger_changelevel" ) ) !is null )
	{		
		iCount++;
	}

	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "game_end" ) ) !is null )
	{
		szTargetName = pEntity.GetTargetname();
		if ( szTargetName.IsEmpty() )
			continue;
			
		iCount++;
	}

	if ( iCount == 0 )
	{
		g_pEntities.insertLast( "=> Map without trigger_changelevel or game_end entity!\n" );
		g_iIssues += 1;
	}	
	
	for ( uint ui = 0; ui < g_pEntities.length(); ui++ )
		g_EngineFuncs.ServerPrint( g_pEntities[ui] );
	
	if ( g_iIssues > 0 )
		LogIssues();
}

CClientCommand issues( "issues", "Issues", @cmdIssues );

void cmdIssues( const CCommand@ args )
{
	CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();

	if ( pPlayer is null || !pPlayer.IsConnected() )
		return;

	if ( !IsPlayerAdmin( pPlayer ) )
	{
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "You have no access to this command.\n" );
		return;
	}
	
	if ( g_iIssues == 0 )
	{
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "No issues.\n" );
		return;
	}

	for ( uint ui = 0; ui < g_pEntities.length(); ui++ )
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, g_pEntities[ui] );
}

bool IsPlayerAdmin( CBasePlayer@ pPlayer )
{
	return g_PlayerFuncs.AdminLevel( pPlayer ) >= ADMIN_YES;
}

void LogIssues()
{
	string szFilename = g_szIssuesPath + g_Engine.mapname + ".log";

	File@ pFile = g_FileSystem.OpenFile( szFilename, OpenFile::READ );
	if ( pFile !is null )
		return;

	@pFile = g_FileSystem.OpenFile( szFilename, OpenFile::APPEND );

	if ( pFile !is null && pFile.IsOpen() )
	{
		DateTime time;
		string szLogTime;
		time.Format( szLogTime, "L %d/%m/%Y - %H:%M:%S\n" );
		pFile.Write( "------------------------------------\n" );
		pFile.Write( szLogTime );
		pFile.Write( "------------------------------------\n" );

		for ( uint ui = 0; ui < g_pEntities.length(); ui++ )
			pFile.Write( g_pEntities[ui] );

		pFile.Close();
	}
}
