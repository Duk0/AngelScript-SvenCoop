/* Sven Co-op AngelScript
*   Info. Messages Plugin
*
* by the AMX Mod X Development Team
*  originally developed by OLO
*
*/

const float X_POS = -1.0;
const float Y_POS = 0.20;
const float HOLD_TIME = 12.0;
const string g_szIMessageIniFile = "scripts/plugins/Configs/imessage.ini";


class MsgData
{
	string msg;
	int r, g, b;
	bool IsEmpty() { return msg.IsEmpty(); }
	void Check() { if ( r == 0 && g == 0 && b == 0 ) r = g = b = 100; }
	void Clear() { msg.Clear(); r = g = b = 100; }
}

array<MsgData> g_pMsgValues;
int g_iMessagesNum;
int g_iCurrent;
float g_flFrequency;
string g_szModuleName;
//const Cvar@ g_pvHostname;
HUDTextParams g_hudTxtParam;

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Duko" );
	g_Module.ScriptInfo.SetContactInfo( "group.midu.cz" );
	
	g_Hooks.RegisterHook( Hooks::Game::MapChange, @MapChange );

	g_szModuleName = "[" + g_Module.GetModuleName() + "] ";
	//@g_pvHostname = g_EngineFuncs.CVarGetPointer( "hostname" );
	
	SetMessage();

	if ( g_flFrequency < 180.0 )
		 g_flFrequency = 180.0; // do not spam messages

/*	uint uiMsgLen = g_Messages.length();
	if ( g_Values.length() == uiMsgLen )
		g_iMessagesNum = uiMsgLen;
	else
		g_Game.AlertMessage( at_warning, "bad format in %1 file\n", g_szIMessageIniFile );*/
		
	g_iMessagesNum = g_pMsgValues.length();
	g_EngineFuncs.ServerPrint( g_szModuleName + "Loaded " + g_iMessagesNum + " messages from " + g_szIMessageIniFile + " file\n" );

	g_hudTxtParam.x = X_POS;
	g_hudTxtParam.y = Y_POS;
				
	g_hudTxtParam.effect = 0;
				
	g_hudTxtParam.r1 = 100;
	g_hudTxtParam.g1 = 100;
	g_hudTxtParam.b1 = 100;
	g_hudTxtParam.a1 = 0;

	g_hudTxtParam.r2 = 255;
	g_hudTxtParam.g2 = 255;
	g_hudTxtParam.b2 = 250;
	g_hudTxtParam.a2 = 0;
			
	g_hudTxtParam.fadeinTime = 2.0;
	g_hudTxtParam.fadeoutTime = 2.0;
	g_hudTxtParam.holdTime = HOLD_TIME;
	g_hudTxtParam.fxTime = 0.5;
	g_hudTxtParam.channel = 5;
}

HookReturnCode MapChange()
{
	g_Scheduler.ClearTimerList();

	return HOOK_CONTINUE;
}


void MapStart()
{
	g_Scheduler.SetInterval( "InfoMessage", g_flFrequency );
}

void InfoMessage()
{
	if ( g_iCurrent >= g_iMessagesNum )
		g_iCurrent = 0;
		
	// No messages, just get out of here
	if ( g_iMessagesNum == 0 )
		return;

	MsgData data = g_pMsgValues[ g_iCurrent ];
	string szMessage = data.msg;
	
	szMessage.Replace( "%hostname%", g_EngineFuncs.CVarGetString( "hostname" ) );
	
	g_hudTxtParam.r1 = data.r;
	g_hudTxtParam.g1 = data.g;
	g_hudTxtParam.b1 = data.b;
	
	g_PlayerFuncs.HudMessageAll( g_hudTxtParam, szMessage );
	
	g_PlayerFuncs.ClientPrintAll( HUD_PRINTCONSOLE, g_szModuleName + szMessage + "\n" );
	++g_iCurrent;

	//g_EngineFuncs.ServerPrint( g_szModuleName + szMessage + "\n" );
}

void SetMessage()
{
	File@ pFile = g_FileSystem.OpenFile( g_szIMessageIniFile, OpenFile::READ );

	if ( pFile !is null && pFile.IsOpen() )
	{
		string line;
		MsgData data;
		while ( !pFile.EOFReached() )
		{
			pFile.ReadLine( line );
			line.Trim();
			
/*			line.Trim( '\r' ); // linux fix
			if ( line == '\r' )
				continue;*/

			if ( line.IsEmpty() )
				continue;

			if ( line[0] == '/' && line[1] == '/' )
				continue;
			
			array<string>@ pValues = line.Split( '=' );
			if ( pValues.length() != 2 ) 
				continue;

			pValues[0].Trim();
			pValues[1].Trim();

			if ( pValues[0].Length() == 0 || pValues[1].Length() == 0 )
				continue;

			if ( pValues[0] == "message" )
			{
				pValues[1].Replace( "^n", "\n" );
				data.msg = pValues[1];
			}

			if ( pValues[0] == "color" )
			{
				data.r = atoi( pValues[1].SubString( 0, 3 ) );
				data.g = atoi( pValues[1].SubString( 3, 3 ) );
				data.b = atoi( pValues[1].SubString( 6, 3 ) );
				
				if ( !data.IsEmpty() )
				{
					data.Check();
					g_pMsgValues.insertLast( data );
					data.Clear();
				}
				else
					g_Game.AlertMessage( at_warning, "bad format in %1 file\n", g_szIMessageIniFile );
			}
			
			if ( pValues[0] == "frequency" )
				g_flFrequency = atof( pValues[1] );
		}
		
		pFile.Close();
	}
}
