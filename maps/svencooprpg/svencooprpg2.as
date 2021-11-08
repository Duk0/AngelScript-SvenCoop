void MapActivate()
{
	CBaseEntity@ pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "worldspawn" );

	if ( pEntity !is null )
		g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "sounds", "1" );

	@pEntity = null;
	
	CBaseToggle@ pToggle;
	string szTarget;
	string szNetname;
	string szTargetname;

	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "trigger_multiple" ) ) !is null )
	{
		@pToggle = cast<CBaseToggle@>( pEntity );
		if ( pToggle is null )
			continue;

		if ( pToggle.m_flWait > 0 )
			continue;

		szTarget = pEntity.pev.target;
/*		if ( szTarget == "fightertext" || szTarget == "clerictext" || szTarget == "archertext" || szTarget == "wizardtext" )
			pToggle.m_flWait = 1;*/
		if ( szTarget == "montext" )
			pToggle.m_flWait = 2;
		else if ( szTarget.EndsWith( " xp text", String::CaseSensitive ) )
			pToggle.m_flWait = 1.5;
		else
			pToggle.m_flWait = 1;
	}

	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "game_text" ) ) !is null )
	{
		if ( string( pEntity.pev.message ).CompareN( "Total Experience:", 17 ) == 0 )
			pEntity.pev.spawnflags = 2;

		szTargetname = pEntity.GetTargetname();

		if ( szTargetname == "wizardtext" || szTargetname == "archertext" )
			pEntity.pev.spawnflags = 2;

		if ( szTargetname == "clerictext" || szTargetname == "fightertext" )
			pEntity.pev.spawnflags = 2;

		if ( szTargetname == "montext" || szTargetname == "healtext" )
		{
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "y", "0.75" );
			pEntity.pev.spawnflags = 2;
		}

		if ( szTargetname == "quest1 text" || szTargetname == "quest2 text" || szTargetname == "quest3 text" )
		{
			pEntity.pev.spawnflags = 1;
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "color2", "255 255 255" );
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "color", "200 200 200" );
		}
	}

	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "squadmaker" ) ) !is null )
	{
		szNetname = pEntity.pev.netname;

		if ( !szNetname.IsEmpty() )
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "displayname", szNetname );
	}

	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "monster_*" ) ) !is null )
	{
		szNetname = pEntity.pev.netname;

		if ( !szNetname.IsEmpty() )
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "displayname", szNetname );
	}
}

void FillAmmo( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
{
	if ( pActivator is null || !pActivator.IsPlayer() )
		return;

	CBasePlayer@ pPlayer = cast<CBasePlayer@>( pActivator );
	if ( pPlayer !is null && pPlayer.IsAlive() )
	{
		pPlayer.GiveAmmo( 100, "health", 100, false );
		pPlayer.GiveAmmo( 250, "9mm", 250, false );
		pPlayer.GiveAmmo( 36, "357", 36, false );
		pPlayer.GiveAmmo( 125, "buckshot", 125, false );
		pPlayer.GiveAmmo( 50, "bolts", 50, false );
		pPlayer.GiveAmmo( 100, "uranium", 100, false );
		pPlayer.GiveAmmo( 100, "hornets", 100, false );

	//	pPlayer.pev.armorvalue = pPlayer.pev.armortype;
	}
}
