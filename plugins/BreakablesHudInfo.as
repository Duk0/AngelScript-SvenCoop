
bool m_bForAll;
HUDTextParams m_hudTxtParam;
CCVar@ m_pVarBreakableHud;

enum SF_FUNC_BREAKABLE
{
	SF_BREAKABLE_ONLYTRIGGER = 1,
	SF_BREAKABLE_TOUCH = 2,
	SF_BREAKABLE_PRESSURE = 4,
	SF_BREAKABLE_REPAIRABLE = 8,
	SF_BREAKABLE_SHOWHUDINFO = 32,
	SF_BREAKABLE_IMMUNETOCLIENTS = 64,
	SF_BREAKABLE_INSTANTBREAK = 256,
	SF_BREAKABLE_EXPLOSIVESONLY = 512
}

enum SF_FUNC_PUSHABLE
{
	SF_PUSHABLE_REPAIRABLE = 8,
	SF_PUSHABLE_MONSTERSIGNORE = 16,
	SF_PUSHABLE_SHOWHUDINFO = 32,
	SF_PUSHABLE_BREAKABLE = 128,
	SF_PUSHABLE_1HITBREAK = 256,
	SF_PUSHABLE_EXPLOSIVESONLY = 512,
	SF_PUSHABLE_LIFTABLE = 1024
}

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Duko" );
	g_Module.ScriptInfo.SetContactInfo( "group.midu.cz" );
	
	g_Hooks.RegisterHook( Hooks::Game::MapChange, @MapChange );

	m_hudTxtParam.r1 = 170;
	m_hudTxtParam.g1 = 20;
	m_hudTxtParam.b1 = 20;
	m_hudTxtParam.a1 = 0;
	m_hudTxtParam.r2 = 255;
	m_hudTxtParam.g2 = 255;
	m_hudTxtParam.b2 = 250;
	m_hudTxtParam.a2 = 0;

	m_hudTxtParam.x = 0.04;
	m_hudTxtParam.y = 0.60;

	m_hudTxtParam.effect = 0;

	m_hudTxtParam.fxTime = 0;
	m_hudTxtParam.holdTime = 1.0;
					
	m_hudTxtParam.fadeinTime = 0;
	m_hudTxtParam.fadeoutTime = 0;

	m_hudTxtParam.channel = 3;
	
	@m_pVarBreakableHud = CCVar( "breakablehud", "0", "Enable/Disable Breakable Hud for All", ConCommandFlag::AdminOnly, @BreakableHudCallBack );
	m_bForAll = m_pVarBreakableHud.GetBool();

	if ( !m_bForAll )
		g_Scheduler.SetInterval( "HUDInfoThink", 0.3 );
}

HookReturnCode MapChange()
{
	g_Scheduler.ClearTimerList();
	
	return HOOK_CONTINUE;
}

void BreakableHudCallBack( CCVar@ cvar, const string& in szOldValue, float flOldValue )
{
	cvar.SetInt( Math.clamp( 0, 1, cvar.GetInt() ) );

	if ( int( flOldValue ) != cvar.GetInt() )
	{
		m_bForAll = cvar.GetBool();
		if ( m_bForAll )
		{
			g_Scheduler.ClearTimerList();
			FindBreakables();
		}
		else
			g_Scheduler.SetInterval( "HUDInfoThink", 0.3 );

		g_EngineFuncs.ServerPrint( "Breakable Hud for All is " + ( m_bForAll ? "Enabled" : "Disabled" ) + "\n" );
	}
}

void MapActivate()
{
	if ( m_bForAll )
		FindBreakables();
}

void FindBreakables()
{
	CBaseEntity@ pEntity = null;
	int iSpawnFlags = 0;

	while( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "func_breakable" ) ) !is null )
	{
		if ( pEntity.pev.health <= 1 )
			continue;

		iSpawnFlags = pEntity.pev.spawnflags;
		if ( ( iSpawnFlags & SF_BREAKABLE_ONLYTRIGGER ) != 0 )
			continue;
		if ( ( iSpawnFlags & SF_BREAKABLE_TOUCH ) != 0 )
			continue;
		if ( ( iSpawnFlags & SF_BREAKABLE_PRESSURE ) != 0 )
			continue;
		if ( ( iSpawnFlags & SF_BREAKABLE_IMMUNETOCLIENTS ) != 0 )
			continue;
		if ( ( iSpawnFlags & SF_BREAKABLE_INSTANTBREAK ) != 0 && pEntity.pev.health > 200 )
			continue;
		if ( ( iSpawnFlags & SF_BREAKABLE_EXPLOSIVESONLY ) != 0 )
			continue;

		if ( ( iSpawnFlags & SF_BREAKABLE_SHOWHUDINFO ) == 0 )
			pEntity.pev.spawnflags |= SF_BREAKABLE_SHOWHUDINFO;
	}

	while( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "func_pushable" ) ) !is null )
	{
		if ( pEntity.pev.health <= 1 )
			continue;

		iSpawnFlags = pEntity.pev.spawnflags;
		if ( ( iSpawnFlags & SF_PUSHABLE_BREAKABLE ) == 0 )
			continue;
		if ( ( iSpawnFlags & SF_PUSHABLE_1HITBREAK ) != 0 )
			continue;
		if ( ( iSpawnFlags & SF_PUSHABLE_EXPLOSIVESONLY ) != 0 )
		continue;

		if ( ( iSpawnFlags & SF_PUSHABLE_SHOWHUDINFO ) == 0 )
			pEntity.pev.spawnflags |= SF_PUSHABLE_SHOWHUDINFO;
	}
}

void MapStart()
{
	if ( !m_bForAll )
		g_Scheduler.SetInterval( "HUDInfoThink", 0.3 );
}

void HUDInfoThink()
{
	for ( int iPlayer = 1; iPlayer <= g_Engine.maxClients; ++iPlayer )
	{
		CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );

		if ( pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive() )
			continue;
			
		if ( !IsPlayerAdmin( pPlayer ) )
			continue;

		CBaseEntity@ pEntity = g_Utility.FindEntityForward( pPlayer, 4096 );
		if ( pEntity is null )
			continue;

		DisplayHUDInfo( pPlayer, pEntity );
	}
}

void DisplayHUDInfo( CBasePlayer@ pPlayer, CBaseEntity@ pEntity )
{
	string szClassname = pEntity.GetClassname();
	if ( szClassname == "func_breakable" )
	{
		int iSpawnFlags = pEntity.pev.spawnflags;
		if ( ( iSpawnFlags & SF_BREAKABLE_SHOWHUDINFO ) != 0 )
			return;
		if ( ( iSpawnFlags & SF_BREAKABLE_ONLYTRIGGER ) != 0 )
			return;
		if ( ( iSpawnFlags & SF_BREAKABLE_TOUCH ) != 0 )
			return;
		if ( ( iSpawnFlags & SF_BREAKABLE_PRESSURE ) != 0 )
			return;
		if ( ( iSpawnFlags & SF_BREAKABLE_IMMUNETOCLIENTS ) != 0 )
			return;
		if ( ( iSpawnFlags & SF_BREAKABLE_INSTANTBREAK ) != 0 && pEntity.pev.health > 200 )
			return;
		if ( ( iSpawnFlags & SF_BREAKABLE_EXPLOSIVESONLY ) != 0 )
			return;
	}
	else if ( szClassname == "func_pushable" )
	{
		int iSpawnFlags = pEntity.pev.spawnflags;
		if ( ( iSpawnFlags & SF_PUSHABLE_SHOWHUDINFO ) != 0 )
			return;
		if ( ( iSpawnFlags & SF_PUSHABLE_BREAKABLE ) == 0 )
			return;
		if ( ( iSpawnFlags & SF_PUSHABLE_1HITBREAK ) != 0 )
			return;
		if ( ( iSpawnFlags & SF_PUSHABLE_EXPLOSIVESONLY ) != 0 )
			return;
	}
	else
		return;

	int iStrength = int( pEntity.pev.health );
	if ( iStrength <= 1 )
		return;
	
	g_PlayerFuncs.HudMessage( pPlayer, m_hudTxtParam, "Breakable\nStrength:  " + iStrength );
}

bool IsPlayerAdmin( CBasePlayer@ pPlayer )
{
	return g_PlayerFuncs.AdminLevel( pPlayer ) >= ADMIN_YES;
}

