float g_flTime = 0;

void CrowbarReturnInit( float flTime = 5 )
{
	g_flTime = flTime;

	if ( g_flTime < 1 )
		g_flTime = 1;

	g_Hooks.RegisterHook( Hooks::Weapon::WeaponTertiaryAttack, @WeaponTertiaryAttack );
}

HookReturnCode WeaponTertiaryAttack( CBasePlayer@ pPlayer, CBasePlayerWeapon@ pWeapon )
{
	if ( pPlayer is null || pWeapon is null )
		return HOOK_CONTINUE;

	if ( !pPlayer.IsConnected() || !pPlayer.IsAlive() )
		return HOOK_CONTINUE;
	
	if ( pWeapon.m_iId != WEAPON_CROWBAR && pWeapon.m_iId != WEAPON_CROWBAR_ELECTRIC )
		return HOOK_CONTINUE;
	
	g_Scheduler.SetTimeout( "ReturnWeapon", g_flTime, pPlayer.entindex() );
	
	return HOOK_CONTINUE;
}

void ReturnWeapon( int iPlayer )
{
	CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );
	if ( pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive() )
		return;

	if ( pPlayer.HasNamedPlayerItem( "weapon_crowbar" ) is null )
	{
		CBaseEntity@ pEntity = null;
		//bool bFound = false;
		while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "weaponbox" ) ) !is null )
		{
			if ( pEntity.pev.owner is null )
				continue;
				
			if ( g_EntityFuncs.EntIndex( pEntity.pev.owner ) != iPlayer )
				continue;
			
			g_EntityFuncs.Remove( pEntity );
		/*	bFound = true;
			pEntity.Touch( pPlayer );
			break;*/
		}
	
	/*	if ( bFound )
			return;*/

		pPlayer.GiveNamedItem( "weapon_crowbar" );
	}
}
