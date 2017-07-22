const Cvar@ m_pCvarRespawnDelay, m_pCvarBarnacleParalyze;
float m_flRespawnDelayValue;
int m_iNumStored = -1;

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Duko" );
	g_Module.ScriptInfo.SetContactInfo( "group.midu.cz" );
	
	g_Hooks.RegisterHook( Hooks::Game::MapChange, @MapChange );
	
	@m_pCvarRespawnDelay = g_EngineFuncs.CVarGetPointer( "mp_respawndelay" );
	@m_pCvarBarnacleParalyze = g_EngineFuncs.CVarGetPointer( "mp_barnacle_paralyze" );
}

void MapStart()
{
	m_flRespawnDelayValue = m_pCvarRespawnDelay.value;
	m_iNumStored = -1;
	
	if ( m_flRespawnDelayValue >= 1 )
		g_Scheduler.SetInterval( "DynamicRespawnDelay", 10 );
}

HookReturnCode MapChange()
{
	g_Scheduler.ClearTimerList();

	return HOOK_CONTINUE;
}

void DynamicRespawnDelay()
{
	if ( IsInteger( m_pCvarRespawnDelay.value ) && m_flRespawnDelayValue != m_pCvarRespawnDelay.value )
		return;

	int iNum = g_PlayerFuncs.GetNumPlayers();

	if ( iNum == m_iNumStored || iNum == 0 )
		return;

	m_iNumStored = iNum;
	float flValue = -1;

	switch ( iNum )
	{
		case 1: flValue = 0; break;
		case 2: flValue = m_flRespawnDelayValue / 5; break;
		case 3: flValue = m_flRespawnDelayValue / 4; break;
		case 4: flValue = m_flRespawnDelayValue / 3; break;
		case 5: flValue = m_flRespawnDelayValue / 3; break;
		case 6: flValue = m_flRespawnDelayValue / 2; break;
		case 7: flValue = m_flRespawnDelayValue; break;
	}
	
	flValue += 0.001;

	if ( flValue == -1 || flValue == m_pCvarRespawnDelay.value )
		return;

	//g_EngineFuncs.CVarSetString( "mp_respawndelay", string( flValue ) );
	g_EngineFuncs.CVarSetFloat( "mp_respawndelay", flValue );
	g_EngineFuncs.ServerPrint( "mp_respawndelay changed to " + flValue + "\n" );

	if ( iNum == 1 && m_pCvarBarnacleParalyze.value == 1.0 )
		g_EngineFuncs.CVarSetString( "mp_barnacle_paralyze", "0" );
	else if ( iNum > 1 && m_pCvarBarnacleParalyze.value == 0.0 )
		g_EngineFuncs.CVarSetString( "mp_barnacle_paralyze", "1" );
}

bool IsInteger( float fA )
{
	return floor( fA ) == fA;
}
