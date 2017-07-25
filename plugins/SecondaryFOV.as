
array<EHandle> g_hZoomed( g_Engine.maxClients + 1, EHandle( null ) );
CCVar@ g_pEnable, g_pFov;

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Drak|Duko" );
	g_Module.ScriptInfo.SetContactInfo( "group.midu.cz" );
	
	g_Hooks.RegisterHook( Hooks::Player::PlayerKilled, @PlayerKilled );
	g_Hooks.RegisterHook( Hooks::Player::PlayerPreThink, @PlayerPreThink );
	g_Hooks.RegisterHook( Hooks::Player::ClientPutInServer, @ClientPutInServer );
	g_Hooks.RegisterHook( Hooks::Weapon::WeaponSecondaryAttack, @WeaponSecondaryAttack );

	@g_pEnable = CCVar( "enable_fov", 1 );
	@g_pFov = CCVar( "secondary_fov", 45 );
}

HookReturnCode PlayerKilled( CBasePlayer@ pPlayer, CBaseEntity@ pAttacker, int iGib )
{
	if ( pPlayer is null )
		return HOOK_CONTINUE;

	int iPlayer = pPlayer.entindex();
	g_hZoomed[iPlayer] = null;

	return HOOK_CONTINUE;
}

HookReturnCode PlayerPreThink( CBasePlayer@ pPlayer, uint& out uiFlags )
{
	if ( pPlayer is null )
		return HOOK_CONTINUE;
	
	if ( !g_pEnable.GetBool() )
		return HOOK_CONTINUE;

	if ( !pPlayer.IsConnected() || !pPlayer.IsAlive() )
		return HOOK_CONTINUE;

	CBaseEntity@ pActiveItem = pPlayer.m_hActiveItem.GetEntity();
	CBasePlayerWeapon@ pWeapon = cast<CBasePlayerWeapon@>( pActiveItem );
	
	if ( pWeapon is null )
		return HOOK_CONTINUE;
	
	if ( pWeapon.m_iId == WEAPON_PYTHON )
		return HOOK_CONTINUE;

	int iPlayer = pPlayer.entindex();

	@pWeapon = cast<CBasePlayerWeapon@>( g_hZoomed[iPlayer].GetEntity() );

	if ( pWeapon is null || pWeapon.m_iId != WEAPON_PYTHON || !pWeapon.m_fInZoom )
		return HOOK_CONTINUE;

	pWeapon.SetFOV( 0 );
	pWeapon.m_fInZoom = false;

	g_hZoomed[iPlayer] = null;

	return HOOK_CONTINUE;
}

HookReturnCode WeaponSecondaryAttack( CBasePlayer@ pPlayer, CBasePlayerWeapon@ pWeapon )
{
	if ( pPlayer is null || pWeapon is null )
		return HOOK_CONTINUE;

	if ( !g_pEnable.GetBool() )
		return HOOK_CONTINUE;

	if ( !pPlayer.IsConnected() || !pPlayer.IsAlive() )
		return HOOK_CONTINUE;
	
	if ( pWeapon.m_iId != WEAPON_PYTHON )
		return HOOK_CONTINUE;

	int iPlayer = pPlayer.entindex();

	if ( pWeapon.m_fInZoom )
	{
		pWeapon.SetFOV( 0 );
		pWeapon.m_fInZoom = false;
		
		g_hZoomed[iPlayer] = null;
				
		return HOOK_CONTINUE;
	}
			
	pWeapon.SetFOV( g_pFov.GetInt() );
	pWeapon.m_fInZoom = true;

	g_hZoomed[iPlayer] = pWeapon;

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
