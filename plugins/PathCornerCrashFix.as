//Fix server crash for trigger_camera if move to path_corner with set the same name of target and targetname

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Duko" );
	g_Module.ScriptInfo.SetContactInfo( "group.midu.cz" );
}

void MapStart()
{
	CBaseEntity@ pEntity = null;
	string szTargetName;
	int iCount = 0;

	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "path_corner" ) ) !is null )
	{
		szTargetName = pEntity.GetTargetname();

		if ( szTargetName.IsEmpty() )
			continue;

		if ( szTargetName.Compare( pEntity.pev.target ) != 0 )
			continue;

		pEntity.pev.target = string_t();

		iCount++;
	}
	
	if ( iCount > 0 )
		g_EngineFuncs.ServerPrint( "[PathCornerCrashFix] Fixed " + iCount + " path_corner entities.\n" );
}
