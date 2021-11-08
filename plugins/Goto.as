const float WAIT_TIME = 5.0;
array<float> g_flWaitTime( g_Engine.maxClients + 1, 0.0 );

CCVar@ g_pVarGotoEnabled;
bool g_bGotoEnabled;
dictionary g_dNoGoto;
//array<string> g_pMovableEntList = { "func_door", "func_train", "func_tracktrain", "func_trackchange", "func_plat", "func_platrot", "func_rotating" };
GotoMenu g_GotoMenu;

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Duko" );
	g_Module.ScriptInfo.SetContactInfo( "group.midu.cz" );

	g_Hooks.RegisterHook( Hooks::Player::ClientSay, @ClientSay );
	g_Hooks.RegisterHook( Hooks::Player::ClientDisconnect, @ClientDisconnect );
	g_Hooks.RegisterHook( Hooks::Game::MapChange, @MapChange );

	@g_pVarGotoEnabled = CCVar( "goto_enabled", "1", "Enable/Disable Goto", ConCommandFlag::AdminOnly, @GotoCallBack );
	g_bGotoEnabled = g_pVarGotoEnabled.GetBool();
	
	g_EngineFuncs.ServerPrint( "[Goto] Reloaded...\n" );
}

void MapStart()
{
	if ( !g_dNoGoto.isEmpty() )
		g_dNoGoto.deleteAll();

	/*for ( int iPlayer = 1; iPlayer <= g_Engine.maxClients; iPlayer++ )
		g_flWaitTime[iPlayer] = g_Engine.time;*/
	g_flWaitTime = array<float>( g_Engine.maxClients + 1, g_Engine.time );
}

void GotoCallBack( CCVar@ cvar, const string& in szOldValue, float flOldValue )
{
	cvar.SetInt( Math.clamp( 0, 1, cvar.GetInt() ) );

	if ( int( flOldValue ) != cvar.GetInt() )
	{
		g_bGotoEnabled = cvar.GetBool();
		g_EngineFuncs.ServerPrint( "Goto is " + ( g_bGotoEnabled ? "Enabled" : "Disabled" ) + "\n" );
	}
}

HookReturnCode ClientSay( SayParameters@ pParams )
{
	const CCommand@ pArguments = pParams.GetArguments();

	if ( pArguments.ArgC() >= 1 )
	{
		CBasePlayer@ pPlayer = pParams.GetPlayer();

		string szArg = pArguments.Arg( 0 );
		szArg.Trim();
		if ( szArg.ICompare( "!goto" ) == 0 )
		{
			if ( pPlayer is null || !pPlayer.IsConnected() )
				return HOOK_CONTINUE;

			int iPlayer = pPlayer.entindex();

			if ( g_Engine.time - g_flWaitTime[iPlayer] < WAIT_TIME )
			{
				pParams.ShouldHide = true;
				return HOOK_HANDLED;
			}
			
			g_flWaitTime[iPlayer] = g_Engine.time;

			string szPartName = pArguments.Arg( 1 );
			szPartName.Trim();

			if ( szPartName.ICompare( "menu" ) == 0 )
			{
				pParams.ShouldHide = true;
				g_GotoMenu.Show( pPlayer );
				
				return HOOK_HANDLED;
			}

			if ( DoGoto( pPlayer, szPartName ) )
			{
				pParams.ShouldHide = true;
				return HOOK_HANDLED;
			}

			return HOOK_CONTINUE;
		}
		else if ( szArg.ICompare( "!nogoto" ) == 0 )
		{
			if ( pPlayer is null || !pPlayer.IsConnected() )
				return HOOK_CONTINUE;

			string szSteamId = g_EngineFuncs.GetPlayerAuthId( pPlayer.edict() );
			
			if ( g_dNoGoto.exists( szSteamId ) )
			{
				g_dNoGoto.delete( szSteamId );
				g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "[AS] Players can teleport to you now.\n" );
			}
			else
			{
				g_dNoGoto.set( szSteamId, true );
				g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "[AS] Nobody can teleport to you now.\n" );
			}

			return HOOK_CONTINUE;
		}
	}
	return HOOK_CONTINUE;
}

HookReturnCode ClientDisconnect( CBasePlayer@ pPlayer )
{
	if ( pPlayer is null )
		return HOOK_CONTINUE;

	string szSteamId = g_EngineFuncs.GetPlayerAuthId( pPlayer.edict() );
	if ( g_dNoGoto.exists( szSteamId ) )
		g_dNoGoto.delete( szSteamId );

	return HOOK_CONTINUE;
}

HookReturnCode MapChange()
{
	g_Scheduler.ClearTimerList();

	return HOOK_CONTINUE;
}

bool DoGoto( CBasePlayer@ pPlayer, string& in szPartName, bool bHiden = false )
{
	if ( !g_bGotoEnabled )
	{
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "[AS] Goto Disabled!\n" );
		return true;
	}

	if ( szPartName.IsEmpty() )
	{
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "[AS] Usage: !goto <part of name>\n" );
		return true;
	}

	if ( !pPlayer.IsAlive() )
		return true;

	if ( pPlayer.m_afPhysicsFlags & PFLAG_ONBARNACLE != 0 )
	{
		//g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "[AS] Cannot teleport while paralyzed!\n" );
		return true;
	}
	
	CBasePlayer@ pDestPlayer = null;
	string szPlayerName;
	int iCount = 0;
	array<CBasePlayer@> pRandom;
	
	CBasePlayer@ pTarget;

	for ( int iTarget = 1; iTarget <= g_Engine.maxClients; iTarget++ )
	{
		@pTarget = g_PlayerFuncs.FindPlayerByIndex( iTarget );

		if ( pTarget is null || !pTarget.IsConnected() )
			continue;

		if ( pTarget is pPlayer )
			continue;
			
		if ( szPartName == "@random" )
		{
			if ( pTarget.IsAlive() )
				pRandom.insertLast( pTarget );

			continue;
		}

		szPlayerName = pTarget.pev.netname;

		if ( int( szPlayerName.Find( szPartName, 0, String::CaseInsensitive ) ) != -1 )
		{
			@pDestPlayer = pTarget;
			iCount++;
		}
	}
	
	int iLen = pRandom.length();
	if ( iLen > 0 )
	{
		int iRandom = Math.RandomLong( 0, iLen - 1 );
		@pDestPlayer = pRandom[iRandom];
		iCount = 1;
	}

	if ( iCount == 0 || pDestPlayer is null )
	{
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "[AS] Could not find '" + szPartName + "' player\n" );
		return true;
	}

	if ( iCount > 1 )
	{
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "[AS] More than one player matches the pattern\n" );
		return true;
	}
	
/*	if ( !FNullEnt( pDestPlayer.pev ) )
		return true;*/

	szPlayerName = pDestPlayer.pev.netname;
	string szSteamId = g_EngineFuncs.GetPlayerAuthId( pDestPlayer.edict() );
			
	if ( g_dNoGoto.exists( szSteamId ) && !IsPlayerServerOwner( pPlayer ) )
	{
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "[AS] The Player " + szPlayerName + " disabled goto\n" );
		g_PlayerFuncs.ClientPrint( pDestPlayer, HUD_PRINTTALK, "[AS] The Player " + pPlayer.pev.netname + " trying goto you\n" );
		return true;
	}

	if ( pDestPlayer.pev.movetype == MOVETYPE_NOCLIP )
		return false;

	if ( pDestPlayer.Classify() != pPlayer.Classify() )
	{
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "[AS] The Player " + szPlayerName + " is not in same team!\n" );
		return true;
	}

	if ( !pDestPlayer.IsAlive() )
	{
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "[AS] The Player " + szPlayerName + " is dead\n" );
		return true;
	}

	if ( pDestPlayer.m_flFallVelocity > 230 )
	{
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "[AS] The Player " + szPlayerName + " falling down\n" );
		return false;
	}

	if ( g_EntityFuncs.IsValidEntity( pDestPlayer.pev.groundentity ) )
	{
		CBaseEntity@ pEntity = g_EntityFuncs.Instance( pDestPlayer.pev.groundentity );
		if ( pEntity !is null )
		{
		//	if ( g_pMovableEntList.find( pEntity.GetClassname() ) >= 0 && pEntity.IsMoving() && pEntity.pev.speed != 0 )
			if ( pEntity.IsMoving() && pEntity.pev.speed != 0 )
			{
				g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "[AS] The Player " + szPlayerName + " is on an moving object\n" );
				return false;
			}
		}
	}

	g_PlayerFuncs.ClientPrint( pDestPlayer, HUD_PRINTTALK, "[AS] To disable/enable goto type !nogoto\n" );

	//Duck
	if ( pDestPlayer.pev.flags & FL_DUCKING != 0 )
	{
		pPlayer.pev.flags |= FL_DUCKING;
		pPlayer.pev.view_ofs = Vector( 0.0, 0.0, 12.0 );
	//	pPlayer.pev.view_ofs.z = pDestPlayer.pev.view_ofs.z;
	}
	//Teleport
	pPlayer.SetOrigin( pDestPlayer.GetOrigin() );
	pPlayer.pev.angles.x = pDestPlayer.pev.v_angle.x;
	pPlayer.pev.angles.y = pDestPlayer.pev.angles.y;
	pPlayer.pev.angles.z = 0; //Do a barrel roll, not
	pPlayer.pev.fixangle = FAM_FORCEVIEWANGLES; // Applies the player angles
	
	if ( bHiden )
		g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, "[AS] " + pPlayer.pev.netname + " teleported to " + szPlayerName + "\n" );
	else
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "[AS] Teleported to " + szPlayerName + "\n" );
	
	return false;
}

final class GotoMenu
{
	private CTextMenu@ m_pMenu = null;
	
	void Show( CBasePlayer@ pPlayer = null )
	{
		if ( m_pMenu !is null && m_pMenu.IsRegistered() )
		{
			m_pMenu.Unregister();
			@m_pMenu = null;
		}

		if ( m_pMenu is null || !m_pMenu.IsRegistered() )
			CreateMenu( pPlayer );
			
		if ( pPlayer !is null )
			m_pMenu.Open( 0, 0, pPlayer );
	}

	private void RefeshMenu( CBasePlayer@ pPlayer = null )
	{
		if ( m_pMenu is null )
			return;

		if ( !m_pMenu.IsRegistered() )
			return;

		m_pMenu.Unregister();
		@m_pMenu = null;
		
		Show( pPlayer );
	}
	
	private void CreateMenu( CBasePlayer@ pPlayer = null )
	{
		@m_pMenu = CTextMenu( TextMenuPlayerSlotCallback( this.Callback ) );

		m_pMenu.SetTitle( "Goto Menu:\n" );
		
		array<string> pStoredNames;
		
		CBasePlayer@ pTarget;

		for ( int i = 1; i <= g_Engine.maxClients; i++ )
		{
			@pTarget = g_PlayerFuncs.FindPlayerByIndex( i );

			if ( pTarget is null || !pTarget.IsConnected() || !pTarget.IsAlive() )
				continue;
			
			if ( pPlayer is pTarget )
				continue;
				
/*			if ( g_dNoGoto.exists( g_EngineFuncs.GetPlayerAuthId( pTarget.edict() ) ) )
				continue;*/
				
			pStoredNames.insertLast( pTarget.pev.netname );
		}
		
		if ( IsPlayerAdmin( pPlayer ) )
		{
			if ( pStoredNames.length() > 1 )
				m_pMenu.AddItem( "[Random Player]", any( 1 ) );

			if ( !g_dNoGoto.isEmpty() )
				m_pMenu.AddItem( "[Remove Nogoto]", any( 2 ) );
		}
		
		for ( uint i = 0; i < pStoredNames.length(); i++ )
			m_pMenu.AddItem( pStoredNames[i] );
		
		if ( m_pMenu.GetItemCount() == 0 )
		{
			m_pMenu.AddItem( "No alive players", any( 3 ) );
			m_pMenu.AddItem( "[Refresh]", any( 3 ) );
		}

		m_pMenu.Register();
	}
	
	private void Callback( CTextMenu@ menu, CBasePlayer@ pPlayer, int iSlot, const CTextMenuItem@ pItem )
	{
		if ( pItem is null || pPlayer is null )
			return;
		
		int iUserData = 0;
		if ( pItem.m_pUserData !is null )
			pItem.m_pUserData.retrieve( iUserData );

		if ( iUserData == 2 && !g_dNoGoto.isEmpty() )
			g_dNoGoto.deleteAll();
		
		if ( iUserData <= 1 )
			DoGoto( pPlayer, iUserData == 1 ? "@random" : pItem.m_szName, true );

		g_Scheduler.SetTimeout( @this, "RefeshMenu", 0.01, @pPlayer );
	}
}

void CmdRemoveNoGoto( const CCommand@ args )
{
	CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();

	if ( pPlayer is null || !pPlayer.IsConnected() )
		return;

	if ( !IsPlayerAdmin( pPlayer ) )
	{
		g_EngineFuncs.ClientPrintf( pPlayer, print_console, "[AS] You have no access to that command\n" );
		return;
	}

	if ( g_dNoGoto.isEmpty() )
	{
		g_EngineFuncs.ClientPrintf( pPlayer, print_console, "[AS] Nogoto nothing stored.\n" );
		return;
	}

	g_dNoGoto.deleteAll();
	g_EngineFuncs.ClientPrintf( pPlayer, print_console, "[AS] Nogoto deleted all.\n" );
}

CClientCommand nogoto( "removenogoto", "remove nogoto", @CmdRemoveNoGoto );

void CmdToggleGoto( const CCommand@ args )
{
	CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();

	if ( pPlayer is null || !pPlayer.IsConnected() )
		return;

	if ( !IsPlayerAdmin( pPlayer ) )
	{
		g_EngineFuncs.ClientPrintf( pPlayer, print_console, "[AS] You have no access to that command\n" );
		return;
	}

	if ( !g_bGotoEnabled )
	{
		g_pVarGotoEnabled.SetInt( 1 );
		g_EngineFuncs.ClientPrintf( pPlayer, print_console, "[AS] Goto Enabled.\n" );
	}
	else
	{
		g_pVarGotoEnabled.SetInt( 0 );
		g_EngineFuncs.ClientPrintf( pPlayer, print_console, "[AS] Goto Disabled.\n" );
	}
}

CClientCommand togglegoto( "togglegoto", "togglegoto", @CmdToggleGoto );

bool IsPlayerAdmin( CBasePlayer@ pPlayer )
{
	return g_PlayerFuncs.AdminLevel( pPlayer ) >= ADMIN_YES;
}

bool IsPlayerServerOwner( CBasePlayer@ pPlayer )
{
	return g_PlayerFuncs.AdminLevel( pPlayer ) == ADMIN_OWNER;
}
