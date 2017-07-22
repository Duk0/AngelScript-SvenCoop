
array<string> m_pSpriteList = { "sprites/level_change.spr", "sprites/map_change.spr", "sprites/aomdc/levelchange.spr", "sprites/poke646/levelchange.spr", "sprites/vendetta/levelchange.spr" };
const string szDefaultSprite = m_pSpriteList[0];

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
	g_Game.PrecacheModel( szDefaultSprite );
}

void MapStart()
{
	g_Scheduler.SetTimeout( "AddSprite", 4 );
}

void AddSprite()
{
	bool bSpriteFound = false;
	CBaseEntity@ pEntity = null;

	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "env_sprite" ) ) !is null )
	{
		if ( m_pSpriteList.find( pEntity.pev.model ) >= 0 )
		{
			bSpriteFound = true;
			break;
		}
	}

	if ( !bSpriteFound )
	{
		array<Vector> pCenterPos;

		while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "trigger_changelevel" ) ) !is null )
		{
			if ( pEntity.pev.solid == SOLID_BSP )
				continue;

			if ( !pEntity.GetTargetname().IsEmpty() )
				continue;

			if ( pEntity.pev.SpawnFlagBitSet( 2 ) )
				continue;

			Vector vecOrigin = pEntity.Center();
			pCenterPos.insertLast( vecOrigin );
		}

		for ( uint i = 0; i < pCenterPos.length(); ++i )
		{
			Vector vecCenter = pCenterPos[i];
			if ( vecCenter == g_vecZero )
				continue;

			CSprite@ pSprite = g_EntityFuncs.CreateSprite( szDefaultSprite, vecCenter, false );
			if ( pSprite !is null )
			{
				//pSprite.SetBrightness( 255 );
				pSprite.SetScale( 0.22 );
				//pSprite.TurnOn();
				g_EngineFuncs.ServerPrint( "* created changelevel sprite\n" );
			}
		}
	}
}
