void CheckFLPlugin(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
{
	array<string> pluginList = g_PluginManager.GetPluginList();
	
	if(pluginList.find("AoMDCFlashlight") >= 0)
		g_EntityFuncs.FireTargets("relay_path_battery", null, null, USE_ON, 0, 0);
	else
		g_EntityFuncs.FireTargets("relay_path_nobattery", null, null, USE_ON, 0, 0);
}	