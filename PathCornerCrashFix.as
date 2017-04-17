
void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Duko" );
	g_Module.ScriptInfo.SetContactInfo( "group.midu.cz" );
}

void MapStart()
{
	CBaseEntity@ pEntity = null;
	string szTargetName, szTarget;
	int iCount = 0;

	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "path_corner" ) ) !is null )
	{
		szTargetName = pEntity.GetTargetname();

		if ( szTargetName.IsEmpty() )
			continue;

		szTarget = pEntity.pev.target;

		if ( szTargetName != szTarget )
			continue;
		
//		g_EngineFuncs.ServerPrint( "path_corner, targetname: " + szTargetName + ", target: " + szTarget + "\n" );
		pEntity.pev.target = "";

		iCount++;
	}
	
	if ( iCount > 0 )
		g_EngineFuncs.ServerPrint( "Fixed " + iCount + " path_corner entities.\n" );
}
