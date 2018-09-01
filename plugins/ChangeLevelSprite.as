
array<string> m_pSpriteList = { "sprites/level_change.spr", "sprites/map_change.spr", "sprites/aomdc/levelchange.spr", "sprites/poke646/levelchange.spr", "sprites/vendetta/levelchange.spr" };
const string m_szDefaultSprite = m_pSpriteList[0];

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Duko" );
	g_Module.ScriptInfo.SetContactInfo( "group.midu.cz" );
	
	g_Hooks.RegisterHook( Hooks::Game::MapChange, @MapChange );
}

HookReturnCode MapChange()
{
	g_Scheduler.ClearTimerList();

	return HOOK_CONTINUE;
}

void MapInit()
{
	g_Game.PrecacheModel( m_szDefaultSprite );
}

void MapStart()
{
	g_Scheduler.SetTimeout( "CreateSprite", 4 );
}

void CreateSprite()
{
	bool bSpriteFound = false;
	CBaseEntity@ pEntity = null;

	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "env_sprite" ) ) !is null )
	{
		if ( m_pSpriteList.find( pEntity.pev.model ) < 0 )
			continue;

		bSpriteFound = true;
		break;
	}

	if ( bSpriteFound )
		return;

	array<Vector> pCenterPos;

	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "trigger_changelevel" ) ) !is null )
	{
		if ( pEntity.pev.solid == SOLID_BSP )
			continue;

		if ( !pEntity.GetTargetname().IsEmpty() )
			continue;

		if ( pEntity.pev.SpawnFlagBitSet( 2 ) )
			continue;

		pCenterPos.insertLast( pEntity.Center() );
	}

	Vector vecCenter;

	for ( uint i = 0; i < pCenterPos.length(); ++i )
	{
		vecCenter = pCenterPos[i];
		if ( vecCenter == g_vecZero )
			continue;

		CSprite@ pSprite = g_EntityFuncs.CreateSprite( m_szDefaultSprite, vecCenter, false );
		if ( pSprite is null )
			continue;

		pSprite.SetScale( 0.22 );
	
		g_EngineFuncs.ServerPrint( "[ChangeLevelSprite] created sprite at: (" + vecCenter.x + " " + vecCenter.y + " " + vecCenter.z + ")\n" );
		
		if ( MoveSprite( pSprite, vecCenter ) == 2 )
		{
			vecCenter = pSprite.GetOrigin();
			g_EngineFuncs.ServerPrint( "[ChangeLevelSprite] moved to visible position: (" + vecCenter.x + " " + vecCenter.y + " " + vecCenter.z + ")\n" );
			continue;
		}

		g_EngineFuncs.ServerPrint( "[ChangeLevelSprite] is not visible\n" );
	}
}

int MoveSprite( CSprite@ pSprite, Vector &in vecOrigin )
{
	TraceResult tr;
	g_Utility.TraceHull( vecOrigin, vecOrigin, dont_ignore_monsters, head_hull, pSprite.edict(), tr );

	if ( tr.fInOpen == 1 && tr.fAllSolid == 0 && tr.fStartSolid == 0 )
		return 1;

	int iStartDistance = 32, iDistance = iStartDistance, iMaxAttempts = 128;
	Vector vecNewOrigin;

	while ( iDistance < 1000 )
	{
		for ( int iAttempts = 0; iAttempts < iMaxAttempts; iAttempts++ )
		{
			vecNewOrigin.x = Math.RandomFloat( vecOrigin.x - iDistance, vecOrigin.x + iDistance );
			vecNewOrigin.y = Math.RandomFloat( vecOrigin.y - iDistance, vecOrigin.y + iDistance );
			vecNewOrigin.z = Math.RandomFloat( vecOrigin.z - iDistance, vecOrigin.z + iDistance );
			
			g_Utility.TraceHull( vecNewOrigin, vecNewOrigin, dont_ignore_monsters, head_hull, pSprite.edict(), tr );

			if ( tr.fInOpen == 1 && tr.fAllSolid == 0 && tr.fStartSolid == 0 )
			{
				pSprite.SetOrigin( vecNewOrigin );
				return 2;
			}
		}

		iDistance += iStartDistance;
	}
	
	return 0;
}
