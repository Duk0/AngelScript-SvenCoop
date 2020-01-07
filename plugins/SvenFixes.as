bool g_bFix511 = false; // non-functional killtarget for trigger_camera
bool g_bFix521 = false; // Multisource used by non member DelayedUse.

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Duko" );
	g_Module.ScriptInfo.SetContactInfo( "group.midu.cz" );

	switch ( g_Game.GetGameVersion() )
	{
		case 511: g_bFix511 = true; break;
		case 521: g_bFix521 = true; break;
	}
}

class CameraData
{
	string targetname;
	string killtarget;
	float delay;
}

void MapInit()
{
	if ( g_Engine.cdAudioTrack > 0 )
	{
		g_Engine.cdAudioTrack = 0; // This prevent play music while loading
		g_EngineFuncs.ServerPrint( "[SvenFixes] Canceled cdAudioTrack loading music.\n" );
	}
}

void MapActivate()
{
	if ( !g_bFix521 )
		return;

	CBaseEntity@ pEntity = null;
	string szTargetName;
	array<string> aszMultiSrc;

	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "multisource" ) ) !is null )
	{
		szTargetName = pEntity.GetTargetname();

		if ( szTargetName.IsEmpty() )
			continue;

		if ( aszMultiSrc.find( szTargetName ) >= 0 )
			continue;
		
		aszMultiSrc.insertLast( szTargetName );
	}
	
	string szTarget, szFixTarget;
	CBaseDelay@ pDelay;
	CBaseEntity@ pEnt;
	int iCount = 0;

	for ( uint u32 = 0; u32 < aszMultiSrc.length(); u32++ )
	{
	/*	@pEntity = null;

		while ( ( @pEntity = g_EntityFuncs.FindEntityByString( pEntity, "target", aszMultiSrc[u32] ) ) !is null )
		{
		}*/
		
		@pEntity = g_EntityFuncs.FindEntityByString( null, "target", aszMultiSrc[u32] );

		if ( pEntity is null )
			continue;

		if ( pEntity.GetTargetname().EndsWith( "_521fix", String::CaseSensitive ) )
			continue;

		@pDelay = cast<CBaseDelay@>( pEntity );
		if ( pDelay is null )
			continue;

		if ( pDelay.m_flDelay == 0.0 )
			continue;
			
		szTarget = pEntity.pev.target;
		szFixTarget = szTarget + "_521fix";

		pEntity.pev.target = szFixTarget;
		
		g_EngineFuncs.ServerPrint( "[SvenFixes] MultiSrc target: " + szTarget + ", fix: " + szFixTarget + ".\n" );

		@pEnt = g_EntityFuncs.Create( "trigger_relay", g_vecZero, g_vecZero, false );
		if ( pEnt is null )
			continue;

		pEnt.pev.target = szTarget;
		pEnt.pev.targetname = szFixTarget;
		pEnt.pev.spawnflags = 64;

		iCount++;
	}

	if ( iCount > 0 )
		g_EngineFuncs.ServerPrint( "[SvenFixes] Fixed " + iCount + " multisource target delayed ents.\n" );
}

void MapStart()
{
	CBaseEntity@ pEntity = null;
	CBaseDelay@ pDelay;
	edict_t@ pEdict;
	string szTargetName, szKillTarget;
	array<CameraData> pStored;
	CameraData data;
	int iCount = 0;

	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "trigger_camera" ) ) !is null )
	{
		/* Not bug, but can be feature. Hide HUD when spawnflags All Players is set. */
		if ( pEntity.pev.SpawnFlagBitSet( 8 ) )
		{
		//	pEntity.pev.spawnflags |= 256;

			@pEdict = pEntity.edict();
			g_EntityFuncs.DispatchKeyValue( pEdict, "hud_health", "1" );
			g_EntityFuncs.DispatchKeyValue( pEdict, "hud_flashlight", "1" );
			g_EntityFuncs.DispatchKeyValue( pEdict, "hud_weapons", "1" );
		}

		/* Fix for non-functional killtarget of trigger_camera */
		if ( !g_bFix511 )
			continue;

		szTargetName = pEntity.GetTargetname();
		if ( szTargetName.IsEmpty() )
			continue;

		@pDelay = cast<CBaseDelay@>( pEntity );
		if ( pDelay is null )
			continue;

		szKillTarget = pDelay.m_iszKillTarget;	
		if ( szKillTarget.IsEmpty() )
			continue;

		data.targetname = szTargetName;
		data.killtarget = szKillTarget;
		data.delay = pDelay.m_flDelay;
		pStored.insertLast( data );
	}
	
	for ( uint u32 = 0; u32 < pStored.length(); u32++ )
	{
		@pEntity = g_EntityFuncs.Create( "trigger_relay", g_vecZero, g_vecZero, false );
		if ( pEntity is null )
			continue;
			
		data = pStored[u32];

		pEntity.pev.targetname = data.targetname;
		pEntity.pev.spawnflags = 1;

		@pDelay = cast<CBaseDelay@>( pEntity );
		if ( pDelay is null )
			continue;
		
		pDelay.m_iszKillTarget = data.killtarget;

		if ( data.delay > 0 )
			pDelay.m_flDelay = data.delay;

		iCount++;
	}
	
	if ( iCount > 0 )
	{
		g_EngineFuncs.ServerPrint( "[SvenFixes] Fixed " + iCount + " trigger_camera entities.\n" );
		iCount = 0;
	}

	/* Fix for possibility healing monster_*_dead npcs */
	// Fixed in v5.21
/*	@pEntity = null;
	string szClassname;
	float flMaxHealth;
	
	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "monster_*" ) ) !is null )
	{
		if ( pEntity.IsRevivable() || pEntity.IsAlive() )
			continue;

		szClassname = pEntity.GetClassname();
		if ( !szClassname.EndsWith( "_dead", String::CaseSensitive ) )
			continue;
			
		flMaxHealth = pEntity.pev.max_health;
		
		if ( flMaxHealth > 100 )
			pEntity.pev.health = flMaxHealth;
		else if ( flMaxHealth > 10 )
			pEntity.pev.health = 10;
		else
			pEntity.pev.health = flMaxHealth;

		pEntity.pev.max_health = 1;
		
		iCount++;
	}

	if ( iCount > 0 )
		g_EngineFuncs.ServerPrint( "[SvenFixes] Fixed " + iCount + " monster_*_dead npcs.\n" );*/
}
