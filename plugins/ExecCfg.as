
void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Duko" );
	g_Module.ScriptInfo.SetContactInfo( "group.midu.cz" );
}

void MapStart()
{
	string szPathCfg = g_EngineFuncs.CVarGetString( "servercfgfile" );
	szPathCfg.Replace( "server.cfg", "mapchange.cfg" );

	g_EngineFuncs.ServerCommand( "exec " + szPathCfg + "\n" );
	g_EngineFuncs.ServerExecute();
}
