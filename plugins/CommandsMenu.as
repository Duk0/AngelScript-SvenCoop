array<CvarArrayData> g_pCvarName;
array<SpeechArrayData> g_pSpeechName;
array<CTextMenu@> g_CmdMenu( g_Engine.maxClients + 1, null );
array<CTextMenu@> g_SubMenu( g_Engine.maxClients + 1, null );
/*
array<string> g_pCDTracks = { "dummy", "dummy", "half-life01", "half-life02", "half-life03", "half-life04", "half-life05",
"half-life06", "half-life07", "half-life08", "half-life09", "half-life10", "half-life11", "half-life12", "half-life13",
"half-life14", "half-life15", "half-life16", "half-life17", "half-life18", "half-life19", "half-life20", "half-life21",
"half-life22", "half-life23", "half-life24", "half-life25", "half-life26", "half-life27" };
*/
float g_flCmdWaitTime = 0.0;

const string g_szSpeechFile = "scripts/plugins/Configs/speech.ini";
const string g_szCvarsFile = "scripts/plugins/Configs/cvars.ini";

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Duko" );
	g_Module.ScriptInfo.SetContactInfo( "group.midu.cz" );
	g_Module.ScriptInfo.SetMinimumAdminLevel( ADMIN_YES );

	g_Hooks.RegisterHook( Hooks::Game::MapChange, @MapChange );

	loadSpeechSettings();
	loadCvarSettings();
}

CClientCommand cvarmenu( "cvarmenu", "- displays cvars menu", @CmdCvarMenu );
CClientCommand speechmenu( "speechmenu", "- displays speech menu", @CmdSpeechMenu );

HookReturnCode MapChange()
{
	// set all menus to null. Apparently this fixes crashes for some people:
	// http://forums.svencoop.com/showthread.php/43310-Need-help-with-text-menu#post515087
	for ( int iPlayer = 1; iPlayer <= g_Engine.maxClients; ++iPlayer )
	{
		@g_CmdMenu[iPlayer] = null;
		@g_SubMenu[iPlayer] = null;
	}
	
	g_Scheduler.ClearTimerList();
	
	g_flCmdWaitTime = 0.0;
	
	return HOOK_CONTINUE;
}

/* Speech menu */

class SpeechArrayData
{
	string name;
	string cmd;
	AdminLevel_t alvl;
}

class SpeechMenuData
{
	int page;
	string cmd;
}

void actionSpeechMenu( CTextMenu@ menu, CBasePlayer@ pPlayer, int iSlot, const CTextMenuItem@ pItem )
{
	if ( pItem !is null && pPlayer !is null )
	{
		SpeechMenuData data;
		pItem.m_pUserData.retrieve( data );
		string szCmd = data.cmd;

		if ( szCmd.CompareN( "spk ", 4 ) == 0 )
		{
			szCmd = szCmd.SubString( 4 );
			if ( !szCmd.IsEmpty() )
			{
				NetworkMessage message( MSG_ALL, NetworkMessages::SVC_STUFFTEXT );
				message.WriteString( "speak " + szCmd );
				message.End();
			}
		}
		
		if ( szCmd.CompareN( "mp3 ", 4 ) == 0 )
		{
/*			int iNum = -1;
			szCmd = szCmd.SubString( 4 );
			if ( szCmd == "stop" )
				iNum = 1;
			else if ( szCmd.CompareN( "play media/", 11 ) == 0 )
				iNum = g_pCDTracks.find( szCmd.SubString( 11 ) );

			if ( iNum > 0 )
			{
				NetworkMessage message( MSG_ALL, NetworkMessages::CdAudio );
				message.WriteByte( uint8( iNum ) );
				message.End();
			}*/

			NetworkMessage message( MSG_ALL, NetworkMessages::SVC_STUFFTEXT );
			message.WriteString( szCmd );
			message.End();
		}

		if ( g_Engine.time - g_flCmdWaitTime > 15.0 )
		{
			ShowActivityToAdmins( pPlayer, "used speech\n" );
			g_Game.AlertMessage( at_logged, "ADMIN: %1 used speech\n", pPlayer.pev.netname );
		}
			
		g_flCmdWaitTime = g_Engine.time;
		
		menu.Open( 0, data.page, pPlayer );
	}

	if ( @menu !is null && menu.IsRegistered() )
	{
		// Also waiting for fix
		//menu.Unregister();
		@menu = null;
	}
}

void DisplaySpeechMenu( CBasePlayer@ pPlayer, const int iPage = 0 )
{
	if ( pPlayer is null || !pPlayer.IsConnected() )
		return;

	int iPlayer = pPlayer.entindex();
	
	@g_CmdMenu[iPlayer] = CTextMenu( @actionSpeechMenu );

	g_CmdMenu[iPlayer].SetTitle( "Speech Menu " );

	const uint uiCount = g_pSpeechName.length();
	AdminLevel_t adminlvl = g_PlayerFuncs.AdminLevel( pPlayer );
	int iPageMenu = 0;
	SpeechArrayData speechdata;
	SpeechMenuData menudata;

	for ( uint uiIndex = 0; uiIndex < uiCount; ++uiIndex )
	{
		speechdata = g_pSpeechName[uiIndex];

		if ( speechdata.alvl > adminlvl )
			continue;

		if ( uiIndex != 0 && uiIndex % 7 == 0 )
			iPageMenu++;

		menudata.page = iPageMenu;
		menudata.cmd = speechdata.cmd;

		g_CmdMenu[iPlayer].AddItem( speechdata.name, any( menudata ) );
	}

	g_CmdMenu[iPlayer].Register();
	g_CmdMenu[iPlayer].Open( 0, iPage, pPlayer );
}

void CmdSpeechMenu( const CCommand@ args )
{
	CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();

	if ( pPlayer is null || !pPlayer.IsConnected() )
		return;

	if ( !IsPlayerAdmin( pPlayer ) )
	{
		g_EngineFuncs.ClientPrintf( pPlayer, print_console, "You have no access to this command.\n" );
		return;
	}
	
	if ( g_pSpeechName.length() == 0 )
	{
		g_EngineFuncs.ClientPrintf( pPlayer, print_console, "There are no speech sounds in menu\n" );
		return;
	}

	DisplaySpeechMenu( pPlayer );
}


/* Cvars menu */

class CvarArrayData
{
	string name;
	any pvar;
	array<string> vals;
	AdminLevel_t alvl;
}

class CvarMenuData
{
//	bool toggle;
	int page;
	array<string> vals;
	string cvar;
}

void actionCvarMenu( CTextMenu@ menu, CBasePlayer@ pPlayer, int iSlot, const CTextMenuItem@ pItem )
{
	if ( pItem !is null && pPlayer !is null )
	{
		int iPlayer = pPlayer.entindex();

		CvarMenuData data;
		pItem.m_pUserData.retrieve( data );
		
		int len = data.vals.length();
	
		@g_SubMenu[iPlayer] = CTextMenu( @actionSubMenu );
		g_SubMenu[iPlayer].SetTitle( data.cvar );

		for ( int i = 0; i < len; ++i )
			g_SubMenu[iPlayer].AddItem( data.vals[i] );
		
		g_SubMenu[iPlayer].AddItem( "Back", any( data.page ) );

		g_SubMenu[iPlayer].Register();
		g_SubMenu[iPlayer].Open( 0, 0, pPlayer );
	}

	if ( @menu !is null && menu.IsRegistered() )
	{
		// Also waiting for fix
		//menu.Unregister();
		@menu = null;
	}
}

void actionSubMenu( CTextMenu@ menu, CBasePlayer@ pPlayer, int iSlot, const CTextMenuItem@ pItem )
{
	if ( pItem !is null && pPlayer !is null )
	{
		if ( pItem.m_szName == "Back" )
		{
			int iPage = 0;
			pItem.m_pUserData.retrieve( iPage );
			g_Scheduler.SetTimeout( "DisplayCvarMenu", 0.01, @pPlayer, iPage );
		}
		else
		{
			const string szCvarName = menu.GetTitle();
			string szCvarValue = pItem.m_szName;
			const string szCurrentVal = g_EngineFuncs.CVarGetString( szCvarName );

			if ( szCurrentVal != szCvarValue )
			{
				if ( szCvarValue.IsEmpty() )
					szCvarValue = '""';

				bool bExecute = true;
				if ( szCvarName == "mp_timelimit" )
				{
					float flValue = atof( szCvarValue );
					float flMapTime = g_Engine.time / 60;
					
					if ( flValue != 0 && flValue <= flMapTime )
					{
						bExecute = false;
						g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "Current cvar value is set to " + szCurrentVal + " minutes.\nMap already running " + int( ceil( flMapTime ) ) + " minutes. Increase value.\n" );
					}
					else		
						g_Scheduler.SetTimeout( "updateScoreboardTimeLeft", 0.01 ); // just wait a bit for update mp_timeleft cvar
				}
				
				if ( bExecute )
				{
					g_EngineFuncs.ServerCommand( szCvarName +  " " + szCvarValue + "\n" );
					g_EngineFuncs.ServerExecute();

					ShowActivityToAdmins( pPlayer, "Cvar " + szCvarName + " changed from " + szCurrentVal + " to " + szCvarValue + "\n" );
					g_Game.AlertMessage( at_logged, "ADMIN: %1 changed cvar %2 from value '%3' to '%4'\n", pPlayer.pev.netname, szCvarName, szCurrentVal, szCvarValue );
				}
			}

			menu.Open( 0, 0, pPlayer );
		}
	}

	if ( @menu !is null && menu.IsRegistered() )
	{
		@menu = null;
	}
}

void DisplayCvarMenu( CBasePlayer@ pPlayer, const int iPage = 0 )
{
	if ( pPlayer is null || !pPlayer.IsConnected() )
		return;

	int iPlayer = pPlayer.entindex();
	
	@g_CmdMenu[iPlayer] = CTextMenu( @actionCvarMenu );

	g_CmdMenu[iPlayer].SetTitle( "Cvars Menu " );

	const uint uiCount = g_pCvarName.length();
	AdminLevel_t adminlvl = g_PlayerFuncs.AdminLevel( pPlayer );
	int iPageMenu = 0;
	CvarArrayData cvardata;
	CvarMenuData menudata;
	string szCurrentVal;

	for ( uint uiIndex = 0; uiIndex < uiCount; ++uiIndex )
	{
		cvardata = g_pCvarName[uiIndex];

		if ( cvardata.alvl > adminlvl )
			continue;

		if ( cvardata.pvar is null )
			continue;

		if ( uiIndex != 0 && uiIndex % 7 == 0 )
			iPageMenu++;

		menudata.page = iPageMenu;
		menudata.cvar = cvardata.name;
		menudata.vals = cvardata.vals;
		
		szCurrentVal = g_EngineFuncs.CVarGetString( cvardata.name );

		g_CmdMenu[iPlayer].AddItem( cvardata.name + " " + szCurrentVal, any( menudata ) );
	}

	g_CmdMenu[iPlayer].Register();
	g_CmdMenu[iPlayer].Open( 0, iPage, pPlayer );
}

void CmdCvarMenu( const CCommand@ args )
{
	CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();

	if ( pPlayer is null || !pPlayer.IsConnected() )
		return;

	if ( !IsPlayerAdmin( pPlayer ) )
	{
		g_EngineFuncs.ClientPrintf( pPlayer, print_console, "You have no access to this command.\n" );
		return;
	}
	
	if ( g_pCvarName.length() == 0 )
	{
		g_EngineFuncs.ClientPrintf( pPlayer, print_console, "There are no cvars in menu\n" );
		return;
	}

	DisplayCvarMenu( pPlayer );
}

void loadSpeechSettings()
{
	File@ pFile = g_FileSystem.OpenFile( g_szSpeechFile, OpenFile::READ );

	if ( pFile !is null && pFile.IsOpen() )
	{
		string line;
		SpeechArrayData data;
		while ( !pFile.EOFReached() )
		{
			pFile.ReadLine( line );
			line.Trim();

/*			line.Trim( '\r' );			
			if ( line == '\r' )
				continue;*/

			if ( line.IsEmpty() )
				continue;

			if ( line[0] == '/' && line[1] == '/' )
				continue;

			if ( line[0] == ';' )
				continue;
			
			line.Replace( "	", "" );

			array<string>@ pValues = line.Split( ':' );
			uint uiNum = pValues.length();
			if ( uiNum < 2 )
				continue;

			for ( uint uiIndex = 0; uiIndex < uiNum; ++uiIndex )
				pValues[uiIndex].Trim();
			
			data.name = pValues[0];
			data.cmd = pValues[1];

			if ( pValues[uiNum - 1].CompareN( "ADMIN_", 6 ) == 0 )
			{
				data.alvl = g_PlayerFuncs.StringToAdminLevel( pValues[uiNum - 1] );
				pValues.removeLast();
			}
			else
			{
				data.alvl = ADMIN_YES;
			}
				
			g_pSpeechName.insertLast( data );
		}
		
		pFile.Close();
	}
	
	uint uiCount = g_pSpeechName.length();
	g_EngineFuncs.ServerPrint( "CommandsMenu loaded " + uiCount + " speech sounds\n" );
}

void loadCvarSettings()
{
	File@ pFile = g_FileSystem.OpenFile( g_szCvarsFile, OpenFile::READ );

	if ( pFile !is null && pFile.IsOpen() )
	{
		string line;
		CvarArrayData data;
		while ( !pFile.EOFReached() )
		{
			pFile.ReadLine( line );
			line.Trim();

/*			line.Trim( '\r' );
			if ( line == '\r' )
				continue;*/

			if ( line.IsEmpty() )
				continue;

			if ( line[0] == '/' && line[1] == '/' )
				continue;

			if ( line[0] == ';' )
				continue;
			
			line.Replace( "	", "" );

			array<string>@ pValues = line.Split( ':' );
			uint uiNum = pValues.length();
			if ( uiNum < 3 )
				continue;

			for ( uint uiIndex = 0; uiIndex < uiNum; ++uiIndex )
				pValues[uiIndex].Trim();

			string szCvarName = pValues[0];
			const Cvar@ pCvar = g_EngineFuncs.CVarGetPointer( szCvarName );
			if ( pCvar is null )
				continue;

			if ( pValues[uiNum - 1].CompareN( "ADMIN_", 6 ) == 0 )
			{
				data.alvl = g_PlayerFuncs.StringToAdminLevel( pValues[uiNum - 1] );
				pValues.removeLast();
			}
			else
			{
				data.alvl = ADMIN_YES;
			}
			
			pValues.removeAt( 0 );

			data.name = szCvarName;
			data.pvar = any( @pCvar );
			data.vals = pValues;

			g_pCvarName.insertLast( data );
		}
		
		pFile.Close();
	}
	
	uint uiCount = g_pCvarName.length();
	g_EngineFuncs.ServerPrint( "CommandsMenu loaded " + uiCount + " cvars\n" );

/*	for( uint uiIndex = 0; uiIndex < uiCount; ++uiIndex )
	{
		const array<string>@ vals = g_cvarCmd[uiIndex];
		const uint valsLen = vals.length();
		string szText;
		for ( uint ui = 0; ui < valsLen - 1; ++ui )
			szText += vals[ui] + " ";

		szText += vals[valsLen - 1];
		//szText += g_PlayerFuncs.StringToAdminLevel( vals[valsLen - 1] );
		
		//if ( uiIndex != 0 && uiIndex % 7 == 0 )
		//	szText += " uiIndex = " + uiIndex;
		
		//g_EngineFuncs.ServerPrint( "szCvarName = " + szCvarName + ", szText = " + szText + ", adminLevel = " + adminLevel + "\n" );
		g_EngineFuncs.ServerPrint( "CvarName = " + szText + "\n" );
	}*/
}

void updateScoreboardTimeLeft()
{
	// udpate time left in scoreboard
	NetworkMessage message( MSG_ALL, NetworkMessages::TimeEnd );
	message.WriteLong( int( g_EngineFuncs.CVarGetFloat( "mp_timeleft" ) ) );
	message.End();
}

void ShowActivityToAdmins( CBasePlayer@ pPlayer, const string& in szMessage )
{
	for ( int iIndex = 1; iIndex <= g_Engine.maxClients; ++iIndex )
	{
		CBasePlayer@ pTarget = g_PlayerFuncs.FindPlayerByIndex( iIndex );
		
		if ( pTarget is null || !pTarget.IsConnected() )
			continue;
		
		if ( !IsPlayerAdmin( pTarget ) )
			continue;
		
		g_PlayerFuncs.ClientPrint( pTarget, HUD_PRINTTALK, "ADMIN " + pPlayer.pev.netname + ": " + szMessage );
	}
}

bool IsPlayerAdmin( CBasePlayer@ pPlayer )
{
	return g_PlayerFuncs.AdminLevel( pPlayer ) >= ADMIN_YES;
}

//as_reloadplugin CommandsMenu
