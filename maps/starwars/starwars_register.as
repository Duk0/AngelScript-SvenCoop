#include "starwars"

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Kite" );
	g_Module.ScriptInfo.SetContactInfo( "https://discord.gg/0wtJ6aAd7XOGI6vI" );
}

void MapInit()
{
	SWRegister();
}