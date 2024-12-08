const float SCROLL_SPEED = 0.3;
const int REPEAT_COUNT = 48; // def. 48 for -0.0063, ( 0.65 - 0.35 ) / 0.00625 = 48 - def., ( 0.65 - 0.35 ) / 0.004 = 75 - widescreen (small text)
const float XPOS_STEP = 0.00625; // def. should be 0.00625 why this was 0.0063?
const string g_szScrollMsgIniFile = "scripts/plugins/Configs/scrollmsg.ini";

int g_iStartPos = 0;
int g_iEndPos;
float g_flXPos;
int g_iLength;
int g_iFrequency;
string g_szScrollMsg;
string g_szModuleName;
HUDTextParams g_hudTxtParam;

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Duko" );
	g_Module.ScriptInfo.SetContactInfo( "group.midu.cz" );
	g_Module.ScriptInfo.SetMinimumAdminLevel( ADMIN_YES );

	g_Hooks.RegisterHook( Hooks::Game::MapChange, @MapChange );

	g_szModuleName = "[" + g_Module.GetModuleName() + "] ";
	
	setScrollMsg();

	g_hudTxtParam.x = 0.65;
	g_hudTxtParam.y = 0.90;
				
	g_hudTxtParam.effect = 0;
				
	g_hudTxtParam.r1 = 200;
	g_hudTxtParam.g1 = 100;
	g_hudTxtParam.b1 = 0;
	g_hudTxtParam.a1 = 0;

	g_hudTxtParam.r2 = 255;
	g_hudTxtParam.g2 = 255;
	g_hudTxtParam.b2 = 250;
	g_hudTxtParam.a2 = 0;
			
	g_hudTxtParam.fadeinTime = 0.05;
	g_hudTxtParam.fadeoutTime = 0.05;
	g_hudTxtParam.holdTime = SCROLL_SPEED;
	g_hudTxtParam.fxTime = SCROLL_SPEED;
	g_hudTxtParam.channel = 6;
}

HookReturnCode MapChange( const string& in szNextMap )
{	
	g_Scheduler.ClearTimerList();

	return HOOK_CONTINUE;
}

void MapStart()
{
	g_iLength = g_szScrollMsg.Length();
	
	if ( g_iFrequency > 0 && g_iLength > 2 )
	{
		int iMinimal = int( ( REPEAT_COUNT + g_iLength ) * ( SCROLL_SPEED + 0.1 ) );
		
		if ( g_iFrequency < iMinimal )
		{
			g_EngineFuncs.ServerPrint( g_szModuleName + "Minimal frequency for this message is " + iMinimal + " seconds\n" );
			g_iFrequency = iMinimal;
		}

		int iSeconds = g_iFrequency % 60;
		g_Scheduler.SetInterval( "MsgInit", float( g_iFrequency ) );
		g_EngineFuncs.ServerPrint( g_szModuleName + "Scrolling message displaying frequency: " + g_iFrequency / 60 + ":" + ( iSeconds < 10 ? "0" : "" ) + iSeconds + " minutes\n" );
	}
	else
		g_EngineFuncs.ServerPrint( g_szModuleName + "Scrolling message disabled\n" );
}

void ShowMsg()
{
	int a = g_iStartPos, i = 0;

	while ( a < g_iEndPos )
	{
		a++;
		i++;
	}

	string szDisplayMsg = g_szScrollMsg.SubString( a - i, i );

	if ( g_iEndPos < g_iLength )
		g_iEndPos++;

	if ( g_flXPos > 0.35 ) // def. 0.35
		g_flXPos -= XPOS_STEP;
	else
	{
		g_iStartPos++;
		g_flXPos = 0.35; // def. 0.35
	}

	g_hudTxtParam.x = g_flXPos;
				
	g_PlayerFuncs.HudMessageAll( g_hudTxtParam, szDisplayMsg );
}

void MsgInit()
{
	g_iEndPos = 1;
	g_iStartPos = 0;
	g_flXPos = 0.65; // def. 0.65

	//g_szScrollMsg.Replace( "%hostname%", g_EngineFuncs.CVarGetString( "hostname" ) );
	
	g_iLength = g_szScrollMsg.Length();
	
	g_Scheduler.SetInterval( "ShowMsg", SCROLL_SPEED, REPEAT_COUNT + g_iLength );
	g_PlayerFuncs.ClientPrintAll( HUD_PRINTCONSOLE, g_szModuleName + g_szScrollMsg + "\n" );
}

void setScrollMsg()
{
	File@ pFile = g_FileSystem.OpenFile( g_szScrollMsgIniFile, OpenFile::READ );

	if ( pFile !is null && pFile.IsOpen() )
	{
		string line;
		array<string>@ pValues;

		while ( !pFile.EOFReached() )
		{
			pFile.ReadLine( line );
			line.Trim();

			if ( line.IsEmpty() )
				continue;

			if ( line[0] == '/' && line[1] == '/' )
				continue;
			
			@pValues = line.Split( '=' );

			if ( pValues.length() != 2 ) 
				continue;

			pValues[0].Trim();
			pValues[1].Trim();

			if ( pValues[0].Length() == 0 || pValues[1].Length() == 0 )
				continue;

			if ( pValues[0] == "message" )
				g_szScrollMsg = pValues[1];
			
			if ( pValues[0] == "frequency" )
				g_iFrequency = atoi( pValues[1] );
		}
		
		pFile.Close();
	}
}

/*
void CmdScrollMsg( const CCommand@ args )
{
	CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();

	if ( pPlayer is null || !pPlayer.IsConnected() )
		return;

	if ( !IsPlayerAdmin( pPlayer ) )
	{
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "You have no access to this command.\n" );
		return;
	}

	g_Scheduler.SetTimeout( "MsgInit", 3.0 );
}

bool IsPlayerAdmin( CBasePlayer@ pPlayer )
{
	return g_PlayerFuncs.AdminLevel( pPlayer ) >= ADMIN_YES;
}

CClientCommand scrollmsg( "scrollmsg", "Scroll Message", @CmdScrollMsg );
*/
