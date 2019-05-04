
void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Duko" );
	g_Module.ScriptInfo.SetContactInfo( "group.midu.cz" );

	g_Hooks.RegisterHook( Hooks::Player::PlayerSpawn, @PlayerSpawn );
}

void MapStart()
{
	CBaseEntity@ pEntity = null;
	int iCount = 0;

	while( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "info_player_deathmatch" ) ) !is null )
	{
		if ( !pEntity.GetTargetname().IsEmpty() )
			continue;

		if ( pEntity.pev.SpawnFlagBitSet( 2 ) )
			continue;
	
		pEntity.pev.netname = "as_crouch_spawn";
	
		iCount++;
	}
	
	g_EngineFuncs.ServerPrint( "[CrouchSpawn] Used " + iCount + " info_player_deathmatch\n" );
}

HookReturnCode PlayerSpawn( CBasePlayer@ pPlayer )
{
	if ( pPlayer is null )
		return HOOK_CONTINUE;
		
	if ( pPlayer.pev.flags & FL_DUCKING != 0 )
		return HOOK_CONTINUE;

	if ( pPlayer.GetTargetname() == "as_crouch_spawn" )
	{
		pPlayer.pev.flags |= FL_DUCKING;
		pPlayer.pev.view_ofs = Vector( 0.0, 0.0, 12.0 );
		
		pPlayer.pev.targetname = string_t();
	}

	return HOOK_CONTINUE;
}

