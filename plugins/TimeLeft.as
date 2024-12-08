/* Sven Co-op AngelScript
*   TimeLeft Plugin
*
* by the AMX Mod X Development Team
*  originally developed by OLO
*/

// time display flags
const int TD_BOTTOM_WHITE_TEXT = 1;		// a - display white text on bottom
const int TD_USE_VOICE = 2;				// b - use voice
const int TD_NO_REMAINING_VOICE = 4;		// c - don't add "remaining" (only in voice)
const int TD_NO_HOURS_MINS_SECS_VOICE = 8;	// d - don't add "hours/minutes/seconds" (only in voice)
const int TD_SHOW_SPEAK_VALUES_BELOW = 16;	// e - show/speak if current time is less than this set in parameter

array<array<int>> g_pTimeSet;
int g_iLastTime, g_iCountDown, g_iSwitch;
CCVar@ g_pVarTimeVoice;
const Cvar@ g_pCvarTimeLimit, g_pCvarTimeLeft;
CScheduledFunction@ g_pTimeRemainFunction = null;
const string g_szTimeLeftFile = "scripts/plugins/Configs/timeleft.ini";

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Duko" );
	g_Module.ScriptInfo.SetContactInfo( "group.midu.cz" );

	g_Hooks.RegisterHook( Hooks::Player::ClientSay, @ClientSay );
	g_Hooks.RegisterHook( Hooks::Game::MapChange, @MapChange );
	@g_pVarTimeVoice = CCVar( "timeleft_voice", "1", "TimeLeft Voice", ConCommandFlag::AdminOnly );

//	@g_pCvarTimeLeft = CCVar("amx_timeleft", "00:00", FCVAR_SERVER|FCVAR_EXTDLL|FCVAR_UNLOGGED|FCVAR_SPONLY)
	@g_pCvarTimeLimit = g_EngineFuncs.CVarGetPointer( "mp_timelimit" );
	@g_pCvarTimeLeft = g_EngineFuncs.CVarGetPointer( "mp_timeleft" );
	
	setDisplaying();
}

void MapStart()
{				
	@g_pTimeRemainFunction = g_Scheduler.SetInterval( "timeRemain", 0.8 );
}

HookReturnCode ClientSay( SayParameters@ pParams )
{
	CBasePlayer@ pPlayer = pParams.GetPlayer();
	const CCommand@ pArguments = pParams.GetArguments();
	
	if ( pArguments.ArgC() >= 1 )
	{
		if ( pArguments.Arg( 0 ) == "thetime" )
		{
			if ( pPlayer is null || !pPlayer.IsConnected() )
				return HOOK_HANDLED;

			sayTheTime( pPlayer );
		}
		else if ( pArguments.Arg( 0 ) == "timeleft" )
		{
			if ( pPlayer is null || !pPlayer.IsConnected() )
				return HOOK_HANDLED;

			sayTimeLeft( pPlayer );
		}
	}
	
	return HOOK_CONTINUE;
}

HookReturnCode MapChange( const string& in szNextMap )
{
	g_Scheduler.ClearTimerList();

	return HOOK_CONTINUE;
}

void sayTheTime( CBasePlayer@ pPlayer )
{
	DateTime time;

	if ( g_pVarTimeVoice.GetBool() )
	{
		string whours, wmins, wpm;
		
		int mins = time.GetMinutes();
		int hrs = time.GetHour();
		
		if ( mins > 0 )
			wmins = UTIL_IntToString( mins );
		
		if ( hrs < 12 )
			wpm = "am";
		else
		{
			if ( hrs > 12 ) hrs -= 12;
			wpm = "pm";
		}

		if ( hrs > 0 ) 
			 whours = UTIL_IntToString( hrs );
		else
			whours = "twelve";
			
		//client_cmd(id, "spk ^"fvox/time_is_now %s_period %s%s^"", whours, wmins, wpm) // this is better

		NetworkMessage message( MSG_ONE, NetworkMessages::SVC_STUFFTEXT, pPlayer.edict() );
		message.WriteString( "spk \"fvox/time_is_now " + whours + " _period " + wmins + " " + wpm + "\"" );
		message.End();
	}
	
	string szCurrentTime;
	time.Format( szCurrentTime, "The time:  %d.%m.%Y - %H:%M:%S" );
	g_PlayerFuncs.SayTextAll( pPlayer, szCurrentTime + "\n" );
}

void sayTimeLeft( CBasePlayer@ pPlayer )
{
	if ( g_pCvarTimeLimit.value > 0.0 )
	{
		int iTimeLeft = int( g_pCvarTimeLeft.value );
		
		if ( g_pVarTimeVoice.GetBool() )
		{
			NetworkMessage message( MSG_ONE, NetworkMessages::SVC_STUFFTEXT, pPlayer.edict() );
			message.WriteString( "spk \"vox/" + setTimeVoice( 0, iTimeLeft ) + "\"" );
			message.End();
		}

		g_PlayerFuncs.SayTextAll( pPlayer, "Time Left:  " + AttachZeroPad( iTimeLeft / 60 ) + ":" + AttachZeroPad( iTimeLeft % 60 ) + "\n" );
	}
	else
		g_PlayerFuncs.SayTextAll( pPlayer, "No Time Limit\n" );
}

string AttachZeroPad( int iHrMinSec )
{
	string szTemp = string( iHrMinSec );
	
	if ( szTemp.Length() == 1 )
		return "0" + szTemp;
	
	return szTemp;
}

string setTimeText( int tmlf )
{
	int iSecs = tmlf % 60;
	int iMins = tmlf / 60;
	
	if ( iSecs == 0 )
		return string( iMins ) + ( ( iMins > 1 ) ? " minutes" : " minute" );
	else if ( iMins == 0 )
		return string( iSecs ) + ( ( iSecs > 1 ) ? " seconds" : " second" );

	return string( iMins ) + ( ( iMins > 1 ) ? " minutes " : " minute " ) + string( iSecs ) + ( ( iSecs > 1 ) ? " seconds" : " second" );
}

string setTimeVoice( int flags, int tmlf )
{
	string szTemp;
	int secs = tmlf % 60;
	int mins = tmlf / 60;

	if ( mins > 59 )
	{
		int hours = mins / 60;

		szTemp += UTIL_IntToString( hours );
		
		if ( ( flags & TD_NO_HOURS_MINS_SECS_VOICE ) == 0 )
			szTemp += " hours ";
		
		mins = mins % 60;
	}
	
	if ( mins > 0 )
	{
		szTemp += UTIL_IntToString( mins );
		
		if ( ( flags & TD_NO_HOURS_MINS_SECS_VOICE ) == 0 )
			szTemp += " minutes ";
	}

	if ( secs > 0 )
	{
		szTemp += UTIL_IntToString( secs );
		
		if ( ( flags & TD_NO_HOURS_MINS_SECS_VOICE ) == 0 ) 
			szTemp += " seconds ";	// there is no "second" in default hl // ??
	}
	
	if ( ( flags &  TD_NO_REMAINING_VOICE ) == 0 )
		szTemp += " remaining";
	
	return szTemp;
}

int findDispFormat( int iTime )
{
	// it is important to check i<length() BEFORE g_pTimeSet[i][0] to prevent out of bound error
	const uint uiLen = g_pTimeSet.length();
	for ( uint i = 0; i < uiLen && g_pTimeSet[i][0] > 0; i++ )
	{
		if ( ( g_pTimeSet[i][1] & TD_SHOW_SPEAK_VALUES_BELOW ) != 0 )
		{
			if ( g_pTimeSet[i][0] > iTime )
			{
				if ( g_iSwitch <= 0 )
				{
					g_iCountDown = g_iSwitch = iTime;
					
					if ( g_pTimeRemainFunction !is null && !g_pTimeRemainFunction.HasBeenRemoved() )
						g_Scheduler.RemoveTimer( g_pTimeRemainFunction );
					
					@g_pTimeRemainFunction = g_Scheduler.SetInterval( "timeRemain", 1.0 );
				}
				
				return i;
			}
		}
		else if ( g_pTimeSet[i][0] == iTime )
		{
			return i;
		}
	}
	
	return -1;
}

void setDisplaying()
{
	File@ pFile = g_FileSystem.OpenFile( g_szTimeLeftFile, OpenFile::READ );

	if ( pFile !is null && pFile.IsOpen() )
	{
		string line;
		array<string>@ pValues;
		array<int> vals( 2 );

		while ( !pFile.EOFReached() )
		{
			pFile.ReadLine( line );
			line.Trim();

			if ( line.IsEmpty() )
				continue;

			if ( line[0] == '/' && line[1] == '/' )
				continue;
			
			@pValues = line.Split( ' ' );

			if ( pValues.length() != 2 ) 
				continue;

			pValues[0].Trim();
			pValues[1].Trim();

			if ( pValues[0].Length() == 0 || pValues[1].Length() == 0 )
				continue;

			vals[0] = atoi( pValues[1] );
			vals[1] = UTIL_ReadFlags( pValues[0] );
			g_pTimeSet.insertLast( vals );
		}
		
		pFile.Close();
	}
}

void timeRemain()
{
	//int gmtm = GetTimeLeft( g_pCvarTimeLimit.value );
	int gmtm = int( g_pCvarTimeLeft.value );
	int tmlf = g_iSwitch > 0 ? --g_iCountDown : gmtm;

	/*string stimel; // register engine cvar is not possible now - maybe in future
	format(stimel, 11, "%02d:%02d", gmtm / 60, gmtm % 60);
	set_pcvar_string(g_pCvarTimeLeft, stimel);*/
	
	if ( g_iSwitch > 0 && gmtm > g_iSwitch )
	{
		g_iSwitch = 0;

		if ( g_pTimeRemainFunction !is null && !g_pTimeRemainFunction.HasBeenRemoved() )
			g_Scheduler.RemoveTimer( g_pTimeRemainFunction );
					
		@g_pTimeRemainFunction = g_Scheduler.SetInterval( "timeRemain", 0.8 );
		
		return;
	}

	if ( tmlf > 0 && g_iLastTime != tmlf )
	{
		g_iLastTime = tmlf;
		int tm_set = findDispFormat( tmlf );
		
		if ( tm_set != -1 )
		{
			int flags = g_pTimeSet[tm_set][1];
			
			if ( ( flags & TD_BOTTOM_WHITE_TEXT ) != 0 )
			{
				HUDTextParams hudSet;
				hudSet.x = -1.0;
				hudSet.y = 0.85;
								
				hudSet.effect = 0;
								
				hudSet.r1 = 255;
				hudSet.g1 = 255;
				hudSet.b1 = 255;
				hudSet.a1 = 0;

				hudSet.r2 = 255;
				hudSet.g2 = 255;
				hudSet.b2 = 250;
				hudSet.a2 = 0;

				hudSet.fadeoutTime = 0.5;

				if ( ( flags & TD_SHOW_SPEAK_VALUES_BELOW ) != 0 )
				{
					hudSet.fadeinTime = 0.1;
					hudSet.holdTime = 1.1;
				}
				else
				{
					hudSet.fadeinTime = 0.0;
					hudSet.holdTime = 4.0;
				}

				hudSet.fxTime = 0.0;
				hudSet.channel = -1;

				g_PlayerFuncs.HudMessageAll( hudSet, setTimeText( tmlf ) );
			}

			if ( ( flags & TD_USE_VOICE ) != 0 )
			{
				NetworkMessage message( MSG_ALL, NetworkMessages::SVC_STUFFTEXT );
				message.WriteString( "spk \"vox/(v70) " + setTimeVoice( flags, tmlf ) + "\"" );
				message.End();
			}
		}
	}
}

string UTIL_IntToString( int iValue )
{
	const array<string> pWords = 
		{"zero ","one ","two ","three ","four ",
		"five ", "six ","seven ","eight ","nine ","ten ",
		"eleven ","twelve ","thirteen ","fourteen ","fifteen ",
		"sixteen ","seventeen ","eighteen ","nineteen ",
		"twenty ","thirty ","fourty ", "fifty ","sixty ",
		"seventy ","eighty ","ninety ",
		"hundred ","thousand "};
	
	string szOutput = "";
	if ( iValue < 0 ) iValue = -iValue;
	int tho = iValue / 1000;
	
	if ( tho > 20 )
		return szOutput;
	
	if ( tho > 0 )
	{
		szOutput += pWords[ tho ] + pWords[ 29 ];
		iValue = iValue % 1000;
	}

	int hun = iValue / 100;
	
	if ( hun > 0 )
	{
		szOutput += pWords[ hun ] + pWords[ 28 ];
		iValue = iValue % 100;
	}

	int ten = iValue / 10;
	int unit = iValue % 10;
	
	if ( ten > 0 )
		szOutput += pWords[ ( ten > 1 ) ? ( ten + 18 ) : ( unit + 10 ) ];
	
	if ( ten != 1 && ( unit > 0 || ( iValue <= 0 && hun <= 0 && tho <= 0 ) ) )
		szOutput += pWords[ unit ];
	
	szOutput.Trim();
	
	return szOutput;
}

int UTIL_ReadFlags( const string& in s ) 
{
	char c;
	int flags = 0;
	
	for ( uint i = 0; i < s.Length(); i++ )
	{
		c = s[i];
		if ( !isalpha( c ) )
			continue;
		
		flags |= ( 1 << c.opImplConv() - 97 );
	}
	
	return flags;
}
/*
int GetTimeLeft( float flCvarTimeLimit )
{
	if ( flCvarTimeLimit > 0 )
	{
		int iReturn = int( ( flCvarTimeLimit * 60.0 ) - g_Engine.time );
		return ( iReturn < 0 ) ? 0 : iReturn;
	}

	return 0;
}
*/