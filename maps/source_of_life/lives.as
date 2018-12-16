const string szLivesFile = "scripts/maps/store/source_of_life/lives.ini";

void LivesActivate()
{
	int iLives = 1000;
	if ( string( g_Engine.mapname ).ICompare( "source_of_life_v22" ) != 0 )
		iLives = LoadLives();
	if ( iLives <= 0 )
		iLives = 100;

	CBaseEntity@ pEntity = g_EntityFuncs.FindEntityByTargetname( null, "wootguy_data" );
	if ( pEntity !is null )
	{
		//g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "$i_lives", "1000" );
		CustomKeyvalues@ pCustom = pEntity.GetCustomKeyvalues();
		if ( pCustom !is null )
			pCustom.SetKeyvalue( "$i_lives", iLives );
	}

	@pEntity = g_EntityFuncs.FindEntityByTargetname( null, "wootguy_life_ui" );
	if ( pEntity !is null )
		pEntity.pev.message = string_t( "Life: " + iLives );

	@pEntity = g_EntityFuncs.FindEntityByTargetname( null, "wootguy_txt_ch" );
	if ( pEntity !is null )
		pEntity.pev.message = string_t( "wootguy_txt_ci" );
}

void LivesInit()
{
	g_Hooks.RegisterHook( Hooks::Game::MapChange, @MapChange );
}

HookReturnCode MapChange()
{
	SaveLives();

	return HOOK_CONTINUE;
}

void SaveLives()
{
	int iLives = 0;
	CBaseEntity@ pEntity = g_EntityFuncs.FindEntityByTargetname( null, "wootguy_data" );
	if ( pEntity !is null )
	{
		CustomKeyvalues@ pCustom = pEntity.GetCustomKeyvalues();
		if ( pCustom !is null )
		{
			CustomKeyvalue pKeyValue = pCustom.GetKeyvalue( "$i_lives" );
			iLives = pKeyValue.GetInteger();
		}
	}

	File@ pFile = g_FileSystem.OpenFile( szLivesFile, OpenFile::WRITE );

	if ( pFile !is null && pFile.IsOpen() )
	{
		pFile.Write( string( iLives ) + "\n" );
		pFile.Close();
	}
	
	//g_EngineFuncs.ServerPrint( "pFile is " + ( pFile is null ? "null" : "NOT null" ) + "\n" );
	g_EngineFuncs.ServerPrint( "iLives: " + iLives + "\n" );
}

int LoadLives()
{
	int iLives = -1;

	File@ pFile = g_FileSystem.OpenFile( szLivesFile, OpenFile::READ );

	if ( pFile !is null && pFile.IsOpen() )
	{
		string line;
		while ( !pFile.EOFReached() )
		{
			pFile.ReadLine( line );
			line.Trim();
			
			if ( line.IsEmpty() )
				continue;

			if ( line.Length() == 0 )
				continue;
	
			iLives = atoi( line );
		}
		
		pFile.Close();
		
		return iLives;
	}
	
	return iLives;
}

