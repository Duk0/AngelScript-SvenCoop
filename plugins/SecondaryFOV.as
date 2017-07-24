
// Secondary FOV
// VERSION 1.1

array<EHandle> g_hZoomed( g_Engine.maxClients + 1, EHandle( null ) );
CCVar@ g_pEnable, g_pFov;


void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Drak|Duko" );
	g_Module.ScriptInfo.SetContactInfo( "group.midu.cz" );
	
	g_Hooks.RegisterHook( Hooks::Player::PlayerPreThink, @PlayerPreThink );
	g_Hooks.RegisterHook( Hooks::Player::ClientPutInServer, @ClientPutInServer );

	@g_pEnable = CCVar( "enable_fov", 1 );
	@g_pFov = CCVar( "secondary_fov", 45 );
}

HookReturnCode PlayerPreThink( CBasePlayer@ pPlayer, uint& out uiFlags )
{
	if ( pPlayer is null )
		return HOOK_CONTINUE;

	if ( !pPlayer.IsConnected() || !pPlayer.IsAlive() )
		return HOOK_CONTINUE;
	
	if ( !g_pEnable.GetBool() )
		return HOOK_CONTINUE;

	CBaseEntity@ pActiveItem = pPlayer.m_hActiveItem.GetEntity();
	CBasePlayerWeapon@ pPlayerWeapon = cast<CBasePlayerWeapon@>( pActiveItem );
	
	if ( pPlayerWeapon is null )
		return HOOK_CONTINUE;
		
	int iPlayer = pPlayer.entindex();
	
	if ( pPlayerWeapon.m_iId == WEAPON_PYTHON )
	{
		int button = pPlayer.pev.button;
		int oldbuttons = pPlayer.pev.oldbuttons;
		
		if ( button & IN_ATTACK2 != 0 && oldbuttons & IN_ATTACK2 == 0 ) 
		{
			if ( pPlayerWeapon.m_fInZoom )
			{
				pPlayerWeapon.SetFOV( 0 );
				pPlayerWeapon.m_fInZoom = false;

			//	g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "[SecondaryFOV] default.\n" );
				
				return HOOK_CONTINUE;
			}
			
			pPlayerWeapon.SetFOV( g_pFov.GetInt() );
			pPlayerWeapon.m_fInZoom = true;

			g_hZoomed[iPlayer] = pPlayerWeapon;
			
		//	g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "[SecondaryFOV] set.\n" );
		}
	}
	else
	{
		@pPlayerWeapon = cast<CBasePlayerWeapon@>( g_hZoomed[iPlayer].GetEntity() );

		if ( pPlayerWeapon !is null )
		{
			pPlayerWeapon.SetFOV( 0 );
			pPlayerWeapon.m_fInZoom = false;

			g_hZoomed[iPlayer] = null;
			
		//	g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "[SecondaryFOV] default.\n" );
		}
	}

	return HOOK_CONTINUE;
}

HookReturnCode ClientPutInServer( CBasePlayer@ pPlayer )
{
	if ( pPlayer is null )
		return HOOK_CONTINUE;
	
	int iPlayer = pPlayer.entindex();
	g_hZoomed[iPlayer] = null;

	return HOOK_CONTINUE;
}
