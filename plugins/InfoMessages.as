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
const float MIN_FEQ_TIME = 180.0;
const string g_szIMessageIniFile = "scripts/plugins/Configs/imessage.ini";


class MsgData
{
	string msg;
	uint8 r, g, b;
	float holdtime;
	bool IsEmpty() { return msg.IsEmpty(); }
	bool IsColorSet() { return ( r != 0 || g != 0 || b != 0 ); }
	void Check() { if ( r == 0 && g == 0 && b == 0 ) r = g = b = 100; if ( holdtime == 0.0 ) holdtime = HOLD_TIME; }
	void Clear() { msg.Clear(); r = g = b = 100; holdtime = HOLD_TIME; }
}

array<MsgData> g_pMsgValues;
int g_iMessagesNum;
int g_iCurrent;
float g_flFrequency = 0.0;
string g_szModuleName;
//const Cvar@ g_pCvarHostname;
HUDTextParams g_hudTxtParam;

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Duko" );
	g_Module.ScriptInfo.SetContactInfo( "group.midu.cz" );
	
	g_Hooks.RegisterHook( Hooks::Game::MapChange, @MapChange );

	g_szModuleName = "[" + g_Module.GetModuleName() + "] ";
	//@g_pCvarHostname = g_EngineFuncs.CVarGetPointer( "hostname" );
	
	SetMessage();

	if ( g_flFrequency < MIN_FEQ_TIME )
		 g_flFrequency = MIN_FEQ_TIME; // do not spam messages
		
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

HookReturnCode MapChange( const string& in szNextMap )
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
	g_hudTxtParam.holdTime = data.holdtime;
	
	g_PlayerFuncs.HudMessageAll( g_hudTxtParam, szMessage );
	
	g_PlayerFuncs.ClientPrintAll( HUD_PRINTCONSOLE, g_szModuleName + szMessage + "\n" );
	g_iCurrent++;

	//g_EngineFuncs.ServerPrint( g_szModuleName + szMessage + "\n" );
}

void SetMessage()
{
	File@ pFile = g_FileSystem.OpenFile( g_szIMessageIniFile, OpenFile::READ );

	if ( pFile !is null && pFile.IsOpen() )
	{
		string line;
		MsgData data;
		array<string>@ pValues;
		bool bHasColor = false;

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
			
			//g_EngineFuncs.ServerPrint( g_szModuleName + pValues[0] + " = " + pValues[1] + "\n" );

			if ( g_flFrequency < MIN_FEQ_TIME && pValues[0] == "frequency" )
			{
				g_flFrequency = atof( pValues[1] );
				continue;
			}

			if ( pValues[0] == "message" )
			{
				pValues[1].Replace( "^n", "\n" );
				data.msg = pValues[1];
				continue;
			}

			if ( pValues[0] == "holdtime" )
			{
				data.holdtime = atof( pValues[1] );
				continue;
			}
			else
			{
				if ( data.holdtime == 0.0 )
					data.holdtime = HOLD_TIME;
			}

			if ( pValues[0] == "color" )
			{
				data.r = atoui( pValues[1].SubString( 0, 3 ) );
				data.g = atoui( pValues[1].SubString( 3, 3 ) );
				data.b = atoui( pValues[1].SubString( 6, 3 ) );
			}

			if ( !data.IsColorSet() || data.IsEmpty() )
			{
				g_EngineFuncs.ServerPrint( g_szModuleName + "bad format in " + g_szIMessageIniFile + " file\n" );
				continue;
			}

			data.Check();
			g_pMsgValues.insertLast( data );
			data.Clear();
		}
		
		pFile.Close();
	}
}
