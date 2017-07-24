
const string g_szConfigPath = "scripts/plugins/store/CrashMap.ini";
const string g_szLogPath = "scripts/plugins/store/CMR.log";
bool g_bMapLoaded = false;
int g_iRestarts = 0;
string g_szLastMap;
string g_szCurrentMap;

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

void MapStart()
{
	g_szCurrentMap = g_Engine.mapname;

	if ( !g_bMapLoaded )
	{
		g_Scheduler.SetTimeout( "LoadLastMap", 1 );
		g_bMapLoaded = true;
	}
	else
	{
		if ( g_iRestarts > 0 && !g_szLastMap.IsEmpty() && g_szLastMap != g_szCurrentMap )
			g_iRestarts = 0;
	
		g_Scheduler.SetTimeout( "SaveCurrentMap", 3 );
	}
}

void LoadLastMap()
{
	File@ pFile = g_FileSystem.OpenFile( g_szConfigPath, OpenFile::READ );

	if ( pFile !is null && pFile.IsOpen() )
	{
		string line, szMap;
		while ( !pFile.EOFReached() )
		{
			pFile.ReadLine( line );
			line.Trim();

/*			line.Trim( '\r' );
			if ( line == '\r' )
				continue;*/
			
			if ( line.IsEmpty() )
				continue;

			array<string>@ pValues = line.Split( ':' );

			uint uiNum = pValues.length();
			if ( uiNum != 2 )
				continue;

			pValues[0].Trim();
			pValues[1].Trim();

			if ( pValues[0].Length() == 0 || pValues[1].Length() == 0 )
				continue;
				
			g_szLastMap = szMap = pValues[0];
			g_iRestarts = atoi( pValues[1] );
		}
		
		pFile.Close();

		if ( szMap.IsEmpty() || !g_EngineFuncs.IsMapValid( szMap ) )
			return;

		if ( g_iRestarts >= 3 )
		{
			CrashMapLog( "[CMR] Error! " + szMap + " is causing the server to crash. Please fix!" );
			return;
		}

		if ( szMap != g_szCurrentMap )
		{
			g_iRestarts++;
			//g_EngineFuncs.CVarSetString( "mp_nextmap_cycle", szMap ); // don't work idk why
			//g_EngineFuncs.ChangeLevel( line );
			g_EngineFuncs.ServerCommand( "mp_nextmap_cycle " + szMap + "\n" );
			g_EngineFuncs.ServerExecute();
			
			CrashMapLog( "[CMR] Map: " + szMap + " crashed " + g_iRestarts + " times." );
		}
	}
}

void SaveCurrentMap()
{
	File@ pFile = g_FileSystem.OpenFile( g_szConfigPath, OpenFile::WRITE );

	if ( pFile !is null && pFile.IsOpen() )
	{
		pFile.Write( string( g_Engine.mapname ) + " : " + g_iRestarts + "\n" );
		pFile.Close();
	}
}

void CrashMapLog( const string& in szMessage )
{
	File@ pFile = g_FileSystem.OpenFile( g_szLogPath, OpenFile::APPEND );

	if ( pFile !is null && pFile.IsOpen() )
	{
		DateTime time;
		string szLogTime;
		time.Format( szLogTime, "L %d/%m/%Y - %H:%M:%S: " );
	
		pFile.Write( szLogTime + szMessage + "\n" );
		pFile.Close();
	}
}
