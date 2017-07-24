
// WARNING:  More than 150 maps in vote list may render your server un-joinable for the reliable channel overflowing (yours has >150).

const int MAPSLIST_MAX = 300;

string g_szMapVotecfgFile = "scripts/plugins/symlinks/mapvote.cfg";

array<string> g_pMapList;
int g_iTotal = 0;

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Duko" );
	g_Module.ScriptInfo.SetContactInfo( "group.midu.cz" );
}

void LoadMaps()
{
	array<string> pMapList = g_MapCycle.GetMapCycle();

	File@ pFile = g_FileSystem.OpenFile( g_szMapVotecfgFile, OpenFile::READ );

	if ( pFile !is null && pFile.IsOpen() )
	{
		string szLine, szBuff;
		while ( !pFile.EOFReached() )
		{
			pFile.ReadLine( szLine );
			szLine.Trim();

/*			szLine.Trim( '\r' );
			if ( szLine == '\r' )
				continue;*/
			
			if ( szLine.IsEmpty() )
				continue;

			if ( szLine[0] == '/' && szLine[1] == '/' )
				continue;

			if ( szLine[0] == ';' || szLine[0] == '#' )
				continue;

			if ( szLine.CompareN( "addvotemap ", 11 ) != 0 )
				continue;

			szBuff = szLine.SubString( 11 );
			if ( szBuff.IsEmpty() )
				continue;

			if ( !g_EngineFuncs.IsMapValid( szBuff ) )
				continue;
			
			int iFound = pMapList.find( szBuff );
			if ( iFound >= 0 )
				pMapList.removeAt( iFound );
				
			g_iTotal++;
		}
		pFile.Close();
		g_pMapList = pMapList;
	}
	else
	{
		g_EngineFuncs.ServerPrint( "Can't open " + g_szMapVotecfgFile + "\n" );
	}
}

void MapStart()
{
	if ( g_iTotal == 0 )
		LoadMaps();

	array<string> pMapList = g_pMapList;
	
	int iFound = pMapList.find( g_Engine.mapname );
	if ( iFound >= 0 )
		pMapList.removeAt( iFound );
	
	int iMapCount = pMapList.length();

	if ( iMapCount > 0 )
	{
		int iFree = MAPSLIST_MAX - g_iTotal;
		int iAdded = 0, iRandom;
		string szMap;

		while ( iAdded != iFree && iMapCount > 0 )
		{
			iRandom = Math.RandomLong( 0, iMapCount - 1 );
			szMap = pMapList[iRandom];
			pMapList.removeAt( iRandom );

			iMapCount--;
			iAdded++;

			g_EngineFuncs.ServerCommand( "addvotemap " + szMap + "\n" );
			g_EngineFuncs.ServerExecute();
		}

	//	g_EngineFuncs.ServerPrint( "[DynamicMapvote] iTotal: " + g_iTotal + ", iFree: " + iFree + ", iMapCount: " + iMapCount + ", iAdded: " + iAdded + ", Total found: " + ( iMapCount + iAdded ) + "\n" );
		g_EngineFuncs.ServerPrint( "[DynamicMapvote] Total in mapvote.cfg: " + g_iTotal + ", New added: " + iAdded + ", Total possible maps: " + ( iMapCount + iAdded ) + "\n" );
	}
/*	else
	{
		g_Log.PrintF( "[DynamicMapvote] WARNING: Couldn't find a valid map or the file doesn't exist\n" );
	}*/
}
