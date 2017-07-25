
array<bool> g_bIsZooming( g_Engine.maxClients + 1, false );
CCVar@ g_pEnable, g_pFov;

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Drak|Duko" );
	g_Module.ScriptInfo.SetContactInfo( "group.midu.cz" );
	
	g_Hooks.RegisterHook( Hooks::Player::PlayerPreThink, @PlayerPreThink );
	g_Hooks.RegisterHook( Hooks::Player::ClientPutInServer, @ClientPutInServer );
	g_Hooks.RegisterHook( Hooks::Weapon::WeaponSecondaryAttack, @WeaponSecondaryAttack );

	@g_pEnable = CCVar( "enable_fov", 1 );
	@g_pFov = CCVar( "secondary_fov", 45 );
}

HookReturnCode PlayerPreThink( CBasePlayer@ pPlayer, uint& out uiFlags )
{
	if ( pPlayer is null )
		return HOOK_CONTINUE;
	
	if ( !g_pEnable.GetBool() )
		return HOOK_CONTINUE;

	if ( !pPlayer.IsConnected() || !pPlayer.IsAlive() )
		return HOOK_CONTINUE;

	int iPlayer = pPlayer.entindex();

	if ( !g_bIsZooming[iPlayer] )
		return HOOK_CONTINUE;

	CBaseEntity@ pActiveItem = pPlayer.m_hActiveItem.GetEntity();
	CBasePlayerWeapon@ pWeapon = cast<CBasePlayerWeapon@>( pActiveItem );
	
	if ( pWeapon is null )
		return HOOK_CONTINUE;
	
	if ( pWeapon.m_iId == WEAPON_PYTHON )
		return HOOK_CONTINUE;

	g_bIsZooming[iPlayer] = false;

	if ( pPlayer.m_iFOV == 0 )
		return HOOK_CONTINUE;

	pPlayer.m_iFOV = 0;

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

	if ( g_bIsZooming[iPlayer] )
	{
		pWeapon.SetFOV( 0 );
		g_bIsZooming[iPlayer] = false;
				
		return HOOK_CONTINUE;
	}
			
	pWeapon.SetFOV( g_pFov.GetInt() );
	g_bIsZooming[iPlayer] = true;

	return HOOK_CONTINUE;
}

HookReturnCode ClientPutInServer( CBasePlayer@ pPlayer )
{
	if ( pPlayer is null )
		return HOOK_CONTINUE;
	
	int iPlayer = pPlayer.entindex();
	g_bIsZooming[iPlayer] = false;

	return HOOK_CONTINUE;
}
