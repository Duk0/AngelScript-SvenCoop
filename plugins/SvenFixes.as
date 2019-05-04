bool g_bFix = false;

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Duko" );
	g_Module.ScriptInfo.SetContactInfo( "group.midu.cz" );
	
	if ( g_Game.GetGameVersion() == 511 )
		g_bFix = true;
}

class CameraData
{
	string targetname;
	string killtarget;
	float delay;
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
		/* Not bug, but can be feature. Hide HUD for all players set. */
		if ( pEntity.pev.SpawnFlagBitSet( 8 ) )
		{
		//	pEntity.pev.spawnflags |= 256;

			@pEdict = pEntity.edict();
			g_EntityFuncs.DispatchKeyValue( pEdict, "hud_health", "1" );
			g_EntityFuncs.DispatchKeyValue( pEdict, "hud_flashlight", "1" );
			g_EntityFuncs.DispatchKeyValue( pEdict, "hud_weapons", "1" );
		}

		/* Fix for non-functional killtarget of trigger_camera */
		if ( !g_bFix )
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
	
	for ( uint i = 0; i < pStored.length(); i++ )
	{
		@pEntity = g_EntityFuncs.Create( "trigger_relay", g_vecZero, g_vecZero, false );
		if ( pEntity is null )
			continue;
			
		data = pStored[i];

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
	@pEntity = null;
	string szClassname;
	float flMaxHealth;
	
	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "monster_*" ) ) !is null )
	{
		if ( pEntity.IsRevivable() || pEntity.IsAlive() )
			continue;

		szClassname = pEntity.GetClassname();
		if ( !szClassname.EndsWith( "_dead", String::CaseSensitive ) )
			continue;
		
		/*if ( pEntity.pev.health == pEntity.pev.max_health )
			continue;*/
			
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
		g_EngineFuncs.ServerPrint( "[SvenFixes] Fixed " + iCount + " monster_*_dead npcs.\n" );
}
