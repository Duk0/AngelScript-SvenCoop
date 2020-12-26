
void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Duko" );
	g_Module.ScriptInfo.SetContactInfo( "group.midu.cz" );
}

CConCommand listplugins( "listplugins", "- Plugin List", @CmdListPlugins );

void CmdListPlugins( const CCommand@ args )
{
	array<string> pPluginList = g_PluginManager.GetPluginList();
	
	for ( uint ui = 0; ui < pPluginList.length(); ui++ )
		g_EngineFuncs.ServerPrint( string( ui + 1 ) + ". " + pPluginList[ui] + "\n" );
}
