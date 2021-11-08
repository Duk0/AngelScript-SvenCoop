const string szEntFile = "megamonstermassacre/megamonstermassacre2.ent";

void MapActivate()
{
	CBaseEntity@ pEntity = null;

	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "monster_*" ) ) !is null )
	{
		string szNetname = pEntity.pev.netname;
		if ( !szNetname.IsEmpty() )
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "displayname", szNetname );
		
		//pEntity.pev.spawnflags |= 4;
	}

	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "game_text" ) ) !is null )
	{
		edict_t@ pEdict = pEntity.edict();
		g_EntityFuncs.DispatchKeyValue( pEdict, "y", "0.55" );
		g_EntityFuncs.DispatchKeyValue( pEdict, "color", "200 200 200" );
	}

	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "weapon_9mmAR" ) ) !is null )
	{
		g_EntityFuncs.Create( "ammo_buckshot", pEntity.GetOrigin(), pEntity.pev.angles, false );
		g_EntityFuncs.Remove( pEntity );
	}

	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "weapon_shotgun" ) ) !is null )
	{
		g_EntityFuncs.Create( "ammo_buckshot", pEntity.GetOrigin(), pEntity.pev.angles, false );
		g_EntityFuncs.Remove( pEntity );
	}
	
	@pEntity = g_EntityFuncs.FindEntityByClassname( null, "env_sprite" );
	if ( pEntity !is null )
	{
		if ( pEntity.pev.model == "sprites/enter1.spr" )
		{
			pEntity.pev.renderamt = 255;
			pEntity.pev.rendermode = 5;
			pEntity.pev.renderfx = 14;
		}
	}

	if ( !g_EntityLoader.LoadFromFile( szEntFile ) )
		g_EngineFuncs.ServerPrint( "Can't open " + szEntFile + "\n" );
}
