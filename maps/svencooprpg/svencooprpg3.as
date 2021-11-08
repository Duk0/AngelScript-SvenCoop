const string szEntFile = "svencooprpg/svencooprpg3.ent";

void MapInit()
{
	g_SoundSystem.PrecacheSound( "garg/gar_attack1.wav" );
}

void MapActivate()
{
	CBaseEntity@ pEntity = null;
	CBaseToggle@ pToggle;
	string szTargetname;
	string szNetname;

	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "trigger_multiple" ) ) !is null )
	{
		@pToggle = cast<CBaseToggle@>( pEntity );

		if ( pToggle is null )
			continue;

		if ( pToggle.m_flWait > 0 )
			continue;

/*		if ( pEntity.pev.target == "fightertext" || pEntity.pev.target == "clerictext"  )
			pToggle.m_flWait = 1;
		if ( pEntity.pev.target == "archertext" || pEntity.pev.target == "wizardtext"  )
			pToggle.m_flWait = 1;*/
		if ( pEntity.pev.target == "enterlair" )
			pToggle.m_flWait = 2;
		else
			pToggle.m_flWait = 1;
	}

	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "game_text" ) ) !is null )
	{
		szTargetname = pEntity.GetTargetname();

		if ( szTargetname == "wizardtext" || szTargetname == "archertext" )
			pEntity.pev.spawnflags = 2;

		if ( szTargetname == "clerictext" || szTargetname == "fightertext" )
			pEntity.pev.spawnflags = 2;

		if ( szTargetname == "enterlair" )
		{
			pEntity.pev.spawnflags = 2;
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "y", "0.75" );
		}

		if ( szTargetname == "quest1 text" )
		{
			pEntity.pev.spawnflags = 1;
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "color2", "255 255 255" );
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "color", "200 200 200" );
		}
	}

	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "ambient_generic" ) ) !is null )
	{
		if ( pEntity.GetTargetname() == "vomit" )
			pEntity.pev.targetname = "vomit_sound";
	}

	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "squadmaker" ) ) !is null )
	{
		szNetname = pEntity.pev.netname;

		if ( !szNetname.IsEmpty() )
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "displayname", szNetname );

		if ( pEntity.GetTargetname() == "gargspawn" )
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "displayname", "Hydra" );
	}

	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "monster_alien_slave" ) ) !is null )
	{
		szNetname = pEntity.pev.netname;

		if ( !szNetname.IsEmpty() )
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "displayname", szNetname );
	}

	if ( !g_EntityLoader.LoadFromFile( szEntFile ) )
		g_EngineFuncs.ServerPrint( "Can't open " + szEntFile + "\n" );
}
