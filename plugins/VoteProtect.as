
void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Duko" );
	g_Module.ScriptInfo.SetContactInfo( "group.midu.cz" );
	
	g_Hooks.RegisterHook( Hooks::Player::PlayerTakeDamage, @PlayerTakeDamage );
}

HookReturnCode PlayerTakeDamage( DamageInfo@ pDamageInfo )
{
	if ( pDamageInfo.bitsDamageType == DMG_GENERIC && pDamageInfo.flDamage == 5000 && pDamageInfo.pAttacker.entindex() == 0 && pDamageInfo.pAttacker is pDamageInfo.pInflictor )
	{
		CBasePlayer@ pPlayer = cast<CBasePlayer@>( pDamageInfo.pVictim );
		if ( pPlayer !is null && IsPlayerAdmin( pPlayer ) && g_Utility.VoteActive() )
		{
			g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, "The Votesystem decided it was better not to kill Admin: " + pPlayer.pev.netname + ". Vote kill canceled.\n" );
		
			pDamageInfo.bitsDamageType = DMG_MEDKITHEAL;
			pDamageInfo.flDamage = 0;
			return HOOK_HANDLED;
		}
	}

	return HOOK_CONTINUE;
}

bool IsPlayerAdmin( CBasePlayer@ pPlayer )
{
	return g_PlayerFuncs.AdminLevel( pPlayer ) >= ADMIN_YES;
}
