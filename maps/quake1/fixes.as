string g_szCurrentMap;

class FuncDoorData
{
	string targetname;
	string fireonopening;
	bool m_fIgnoreTargetname;
	int wait;
	bool Is2DoorSet() { return !targetname.IsEmpty() && !fireonopening.IsEmpty() && m_fIgnoreTargetname; }
	void Clear() { targetname.Clear(); fireonopening.Clear(); m_fIgnoreTargetname = false; wait = 0; }
}

void q1_InitFixes()
{
	g_szCurrentMap = g_Engine.mapname;

	if ( g_szCurrentMap.ICompare( "q1_start" ) == 0 )
	{
	//	g_SoundSystem.PrecacheSound( Q1_ZOMBIE_IDLEC );
		g_Game.PrecacheOther( "monster_qzombie" );
	}
}

void q1_ActivateFixes()
{
	//CBaseEntity@ pEntity = g_EntityFuncs.FindEntityByClassname( null, "worldspawn" );
	
	CBaseEntity@ pEntity = null;
	string szTargetName;

	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "ambient_generic" ) ) !is null )
	{
		if ( !pEntity.pev.SpawnFlagBitSet( 1 ) )
			continue;
			
	//	if ( int( string( pEntity.pev.message ).Find( "music", 0, String::CaseInsensitive ) ) == -1 )
		if ( string( pEntity.pev.message ).CompareN( "quake1/music/", 13 ) != 0 )
			continue;

		szTargetName = pEntity.GetTargetname();

		if ( szTargetName.IsEmpty() )
			pEntity.pev.targetname = string_t( "q1_music" );
		else
		{
			if ( szTargetName == "mus" )
				pEntity.pev.spawnflags |= 16;
		}

		pEntity.pev.iuser1 = 2;
		pEntity.pev.health = 7;
	}

	string szTarget, szMessage;
	CBaseDelay@ pDelay;
	CBaseEntity@ pEnt;
	
	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "trigger_relay" ) ) !is null )
	{
		szTargetName = pEntity.GetTargetname();
		szTarget = pEntity.pev.target;
		
		if ( szTargetName.IsEmpty() || !szTarget.IsEmpty() )
			continue;

		@pDelay = cast<CBaseDelay@>( pEntity );
		if ( pDelay is null || !string( pDelay.m_iszKillTarget ).IsEmpty() )
			continue;

		szMessage = pEntity.pev.message;
		
		if ( szMessage.IsEmpty() )
		{
			g_EntityFuncs.Remove( pEntity ); // just remove emtpy relay
			continue;
		}

		@pEnt = g_EntityFuncs.Create( "env_message", pEntity.GetOrigin(), pEntity.pev.angles, true );
		if ( pEnt is null )
			continue;
		
		pEnt.pev.targetname = szTargetName;
		pEnt.pev.message = szMessage;
		pEnt.pev.spawnflags = 2;
		
		g_EntityFuncs.DispatchSpawn( pEnt.edict() );
		
		g_EntityFuncs.Remove( pEntity );
	}

	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "trigger_once" ) ) !is null )
	{
		szTargetName = pEntity.GetTargetname();
		szTarget = pEntity.pev.target;
		
		if ( szTargetName.IsEmpty() || !szTarget.IsEmpty() )
			continue;

		if ( !string( pEntity.pev.netname ).IsEmpty() )
			continue;

		if ( pEntity.pev.spawnflags > 0 )
			continue;

		szMessage = pEntity.pev.message;
		
		if ( szMessage.IsEmpty() )
			continue;

		@pDelay = cast<CBaseDelay@>( pEntity );
		if ( pDelay is null || !string( pDelay.m_iszKillTarget ).IsEmpty() )
			continue;

		@pEnt = g_EntityFuncs.Create( "env_message", g_vecZero, g_vecZero, true );
		if ( pEnt is null )
			continue;
		
		pEnt.pev.targetname = szTargetName;
		pEnt.pev.message = szMessage;
		pEnt.pev.spawnflags = 2;
		
		g_EntityFuncs.DispatchSpawn( pEnt.edict() );
		
		g_EntityFuncs.Remove( pEntity );
	}

	float flDelay;

	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "trigger_once" ) ) !is null )
	{
		szTargetName = pEntity.GetTargetname();
		szTarget = pEntity.pev.target;
		
		if ( szTargetName.IsEmpty() || szTarget.IsEmpty() )
			continue;

		if ( !string( pEntity.pev.netname ).IsEmpty() )
			continue;

		if ( pEntity.pev.spawnflags > 0 )
			continue;

		szMessage = pEntity.pev.message;
		
		if ( !szMessage.IsEmpty() )
			continue;

		@pDelay = cast<CBaseDelay@>( pEntity );
		if ( pDelay is null || !string( pDelay.m_iszKillTarget ).IsEmpty() )
			continue;
			
		flDelay = pDelay.m_flDelay;

		if ( flDelay > 0 )
		{
			if ( pEntity.pev.spawnflags == 0 )
				pEntity.pev.spawnflags |= 2;
		}
/*
		@pEnt = g_EntityFuncs.Create( "trigger_relay", g_vecZero, g_vecZero, true );
		if ( pEnt is null )
			continue;
		
		pEnt.pev.targetname = szTargetName;
		pEnt.pev.target = szTarget;
	//	pEnt.pev.spawnflags = 65;
		pEnt.pev.spawnflags = 1;
		
		g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "triggerstate", "2" );
		
		if ( flDelay > 0 )
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "delay", string( flDelay ) );
		
		g_EntityFuncs.DispatchSpawn( pEnt.edict() );
		
		g_EntityFuncs.Remove( pEntity );*/
	}

	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "trigger_teleport" ) ) !is null )
	{
		szTargetName = pEntity.GetTargetname();
		szTarget = pEntity.pev.target;
		
		if ( szTargetName.IsEmpty() || szTarget.IsEmpty() )
			continue;

		if ( !pEntity.pev.SpawnFlagBitSet( 4099 ) )
			continue;

		@pEnt = g_EntityFuncs.Create( "trigger_qteleport", g_vecZero, g_vecZero, true );
		if ( pEnt is null )
			continue;

		pEnt.pev.model = pEntity.pev.model;
	//	if ( !szTargetName.IsEmpty() )
	//		pEnt.pev.targetname = szTargetName;
	//	else
	//		pEnt.pev.spawnflags |= 16384;
		pEnt.pev.targetname = szTargetName;
		pEnt.pev.target = szTarget;

		if ( pEntity.pev.SpawnFlagBitSet( 256 ) )
			pEnt.pev.spawnflags |= 256;

		if ( pEntity.pev.SpawnFlagBitSet( 512 ) )
			pEnt.pev.spawnflags |= 512;
		
		g_EntityFuncs.DispatchSpawn( pEnt.edict() );
		
		g_EntityFuncs.Remove( pEntity );
	}

/*
	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "monster_q*" ) ) !is null )
	{
		szTarget = pEntity.pev.target;
		
		if ( szTarget.IsEmpty() )
			continue;

		pEntity.pev.target = string_t();

		g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "TriggerCondition", "4" );
		g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "TriggerTarget", szTarget );
	}
*/
/*
	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "monster_qogre" ) ) !is null )
	{
		@pEnt = g_EntityFuncs.Create( "monster_zombie", pEntity.GetOrigin(), pEntity.pev.angles, true );
		if ( pEnt is null )
			continue;

		g_EntityFuncs.DispatchSpawn( pEnt.edict() );
		
		g_EntityFuncs.Remove( pEntity );
	}
*/

	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "item_healthkit" ) ) !is null )
	{
		if ( pEntity.pev.SpawnFlagBitSet( 1 ) )
			pEntity.pev.spawnflags &= ~1;

		if ( pEntity.pev.SpawnFlagBitSet( 2 ) )
			pEntity.pev.spawnflags &= ~2;

		if ( pEntity.pev.SpawnFlagBitSet( 256 ) )
			pEntity.pev.spawnflags &= ~256;

		if ( pEntity.pev.SpawnFlagBitSet( 512 ) )
			pEntity.pev.spawnflags &= ~512;

		if ( pEntity.pev.SpawnFlagBitSet( 1024 ) )
			pEntity.pev.spawnflags &= ~1024;
	}
/*
	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "func_button" ) ) !is null )
	{
		if ( pEntity.pev.SpawnFlagBitSet( 256 ) )
			continue;

		pEntity.pev.spawnflags |= 256;
		
		@pEnt = g_EntityFuncs.Create( "func_button", g_vecZero, g_vecZero, true );
		if ( pEnt is null )
			continue;
			
		pEnt.pev.model = pEntity.pev.model;
		pEnt.pev.target = pEntity.pev.target;
		pEnt.pev.targetname = pEntity.pev.targetname;
		pEnt.pev.noise = pEntity.pev.noise;
		pEnt.pev.speed = pEntity.pev.speed;
		pEnt.pev.spawnflags = pEntity.pev.spawnflags;
		pEnt.pev.movedir = pEntity.pev.movedir;
		
		CBaseButton@ pButton = cast<CBaseButton@>( pEntity );
			
		if ( pButton !is null )
		{
			g_EntityFuncs.DispatchKeyValue( pEnt.edict(), "delay", string( pButton.m_flDelay ) );
			g_EntityFuncs.DispatchKeyValue( pEnt.edict(), "wait", string( pButton.m_flWait ) );
			g_EntityFuncs.DispatchKeyValue( pEnt.edict(), "lip", string( pButton.m_flLip ) );
		}
		
		g_EntityFuncs.DispatchSpawn( pEnt.edict() );
		
		
		g_EntityFuncs.Remove( pEntity );
	}
*/
	bool bFixDoors = false;
	FuncDoorData data;
	dictionary dDoors;
	
	bool bLoadEnts = false;

	if ( g_szCurrentMap.ICompare( "q1_start" ) == 0 )
	{
/*		bFixDoors = true;
	
		data.targetname = "door1b";
		data.fireonopening = "door1a";
		data.m_fIgnoreTargetname = true;
		data.wait = 0;
		dDoors.set( "*3", data );

		data.targetname = "door1a";
		data.fireonopening = "door1b";
		data.m_fIgnoreTargetname = true;
		data.wait = 0;
		dDoors.set( "*29", data );

		data.targetname = "door2b";
		data.fireonopening = "door2a";
		data.m_fIgnoreTargetname = true;
		data.wait = 0;
		dDoors.set( "*2", data );

		data.targetname = "door2a";
		data.fireonopening = "door2b";
		data.m_fIgnoreTargetname = true;
		data.wait = 0;
		dDoors.set( "*28", data );*/
		
		@pEntity = null;

		while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "monster_qzombie" ) ) !is null )
		{
			g_EntityFuncs.Remove( pEntity );
		}

		@pEntity = g_EntityFuncs.FindEntityByString( null, "target", "te2d" );
		if ( pEntity !is null )
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "wait", "5" );

		@pEntity = g_EntityFuncs.FindEntityByString( null, "target", "te3d" );
		if ( pEntity !is null )
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "wait", "5" );

		bLoadEnts = true;
	}
	else if ( g_szCurrentMap.ICompare( "q1_e1m1" ) == 0 )
	{
/*		bFixDoors = true;
	
		data.targetname = "door1b";
		data.fireonopening = "door1a";
		data.m_fIgnoreTargetname = true;
		data.wait = 0;
		dDoors.set( "*1", data );

		data.targetname = "door1a";
		data.fireonopening = "door1b";
		data.m_fIgnoreTargetname = true;
		data.wait = 0;
		dDoors.set( "*2", data );

		data.targetname = "door2b";
		data.fireonopening = "door2a";
		data.m_fIgnoreTargetname = true;
		data.wait = 0;
		dDoors.set( "*5", data );

		data.targetname = "door2a";
		data.fireonopening = "door2b";
		data.m_fIgnoreTargetname = true;
		data.wait = 0;
		dDoors.set( "*6", data );*/
/*
		data.Clear();
		data.wait = 3;
		dDoors.set( "*14", data );
*/	
/*		@pEntity = g_EntityFuncs.FindEntityByTargetname( null, "t4" );
		if ( pEntity !is null )
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "wait", "3" );
		
		@pEntity = g_EntityFuncs.FindEntityByClassname( null, "func_recharge" );
		if ( pEntity !is null )
		{
		//	g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "CustomStartSound", "items/suitchargeok1.wav" );
			g_EntityFuncs.Remove( pEntity );
		}
*/		
		bLoadEnts = true;
	}
	else if ( g_szCurrentMap.ICompare( "q1_e1m2" ) == 0 )
	{
/*		@pEntity = g_EntityFuncs.FindEntityByString( null, "target", "td2" );
		if ( pEntity !is null )
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "pass_destroy_item_name", "item_silverkey" );
*/
/*		@pEntity = g_EntityFuncs.FindEntityByClassname( null, "item_inventory" );
		if ( pEntity !is null )
		{
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "carried_hidden", "0" );
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "holder_keep_on_death", "0" );
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "holder_timelimit", "300" );
		}*/

		bLoadEnts = true;
	}
	else if ( g_szCurrentMap.ICompare( "q1_e1m3" ) == 0 )
	{
/*		bFixDoors = true;

		data.targetname = "door1b";
		data.fireonopening = "door1a";
		data.m_fIgnoreTargetname = true;
		data.wait = 0;
		dDoors.set( "*1", data );

		data.targetname = "door1a";
		data.fireonopening = "door1b";
		data.m_fIgnoreTargetname = true;
		data.wait = 0;
		dDoors.set( "*2", data );

		data.targetname = "door2b";
		data.fireonopening = "door2a";
		data.m_fIgnoreTargetname = true;
		data.wait = 0;
		dDoors.set( "*11", data );

		data.targetname = "door2a";
		data.fireonopening = "door2b";
		data.m_fIgnoreTargetname = true;
		data.wait = 0;
		dDoors.set( "*12", data );

		data.targetname = "door3b";
		data.fireonopening = "door3a";
		data.m_fIgnoreTargetname = true;
		data.wait = 0;
		dDoors.set( "*33", data );

		data.targetname = "door3a";
		data.fireonopening = "door3b";
		data.m_fIgnoreTargetname = true;
		data.wait = 0;
		dDoors.set( "*34", data );
*/
/*		@pEntity = g_EntityFuncs.FindEntityByString( null, "target", "t5" );
		if ( pEntity !is null )
		{
			pEntity.pev.targetname = string_t( "button5" );
		//	g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "wait", "30" );

			CBaseButton@ pButton = cast<CBaseButton@>( pEntity );
			
			if ( pButton !is null )
			{
				pButton.m_flWait = 30;
				pButton.m_fStayPushed = false;
			}
		}*/
		
		@pEntity = g_EntityFuncs.FindEntityByTargetname( null, "t10" );
		if ( pEntity !is null )
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "wait", "-1" );
/*
		@pEntity = g_EntityFuncs.FindEntityByString( null, "model", "*49" );
		if ( pEntity !is null )
			pEntity.pev.targetname = string_t( "t5_door" );

		@pEntity = g_EntityFuncs.FindEntityByString( null, "target", "td1" );
		if ( pEntity !is null )
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "pass_destroy_item_name", "item_goldkey" );

		@pEntity = g_EntityFuncs.FindEntityByClassname( null, "item_inventory" );
		if ( pEntity !is null )
		{
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "collect_limit", "0" ); // !!!
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "carried_hidden", "0" );
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "holder_keep_on_death", "0" );
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "holder_timelimit", "300" );
		}
*/
/*
		@pEntity = g_EntityFuncs.FindEntityByString( null, "target", "t1b" );
		if ( pEntity !is null )
			

		@pEntity = g_EntityFuncs.FindEntityByString( null, "target", "t1a" );
		if ( pEntity !is null )
*/
/*
		@pEntity = g_EntityFuncs.FindEntityByString( null, "target", "t10" );
		if ( pEntity !is null )
			g_EntityFuncs.Remove( pEntity );
*/
/*
		@pEntity = g_EntityFuncs.FindEntityByTargetname( null, "t666" );
		if ( pEntity !is null )
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "target_on_fail", "" );

		@pEntity = g_EntityFuncs.FindEntityByString( null, "target", "t666" );
		if ( pEntity !is null )
			g_EntityFuncs.Remove( pEntity );
*/
		bLoadEnts = true;
	}
	else if ( g_szCurrentMap.ICompare( "q1_e1m4" ) == 0 )
	{
/*		@pEntity = g_EntityFuncs.FindEntityByString( null, "target", "t116" );
		if ( pEntity !is null )
		{
		//	pEntity.SetOrigin( Vector( 1790, 224, 920 ) );
			pEntity.pev.target = string_t();
		}

		@pEntity = g_EntityFuncs.FindEntityByString( null, "model", "*33" );
		if ( pEntity !is null )
			pEntity.pev.targetname = string_t();

		@pEntity = null;
		while ( ( @pEntity = g_EntityFuncs.FindEntityByString( pEntity, "target", "t7" ) ) !is null )
		{
			if ( pEntity.GetClassname() != "trigger_relay" )
				continue;

			g_EntityFuncs.Remove( pEntity );
		}

		@pEntity = g_EntityFuncs.FindEntityByString( null, "target", "td1" );
		if ( pEntity !is null )
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "pass_destroy_item_name", "item_silverkey" );

		@pEntity = g_EntityFuncs.FindEntityByClassname( null, "item_inventory" );
		if ( pEntity !is null )
		{
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "carried_hidden", "0" );
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "holder_keep_on_death", "0" );
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "holder_timelimit", "300" );
		}
*/

		@pEntity = null;
		while ( ( @pEntity = g_EntityFuncs.FindEntityByString( pEntity, "target", "t120" ) ) !is null )
		{
			if ( pEntity.GetClassname() != "trigger_once" )
				continue;

			g_EntityFuncs.Remove( pEntity );
		}

		bLoadEnts = true;
	}
	else if ( g_szCurrentMap.ICompare( "q1_e1m5" ) == 0 )
	{
		@pEntity = null;

		while ( ( @pEntity = g_EntityFuncs.FindEntityByString( pEntity, "target", "t45" ) ) !is null )
		{
			if ( pEntity.pev.SpawnFlagBitSet( 1 ) )
				pEntity.pev.spawnflags &= ~1;

			if ( pEntity.pev.model == "*28" )
				g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "target", "t45_fix" );
		}

/*
		@pEntity = g_EntityFuncs.FindEntityByString( null, "model", "*48" );
		if ( pEntity !is null )
		{
			if ( pEntity.pev.SpawnFlagBitSet( 256 ) )
				pEntity.pev.spawnflags &= ~256;
		}
*/
/*		@pEntity = g_EntityFuncs.FindEntityByString( null, "target", "td1" );
		if ( pEntity !is null )
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "pass_destroy_item_name", "item_goldkey" );

		@pEntity = g_EntityFuncs.FindEntityByString( null, "target", "td2" );
		if ( pEntity !is null )
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "pass_destroy_item_name", "item_silverkey" );

		@pEntity = null;

		while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "item_inventory" ) ) !is null )
		{
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "carried_hidden", "0" );
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "holder_keep_on_death", "0" );
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "holder_timelimit", "300" );
		}
*/	
		bLoadEnts = true;
	}
	else if ( g_szCurrentMap.ICompare( "q1_e1m6" ) == 0 )
	{
		@pEntity = g_EntityFuncs.FindEntityByString( null, "model", "*47" );
		if ( pEntity !is null )
			pEntity.pev.targetname = string_t( "t52" );
/*
		@pEntity = g_EntityFuncs.FindEntityByString( null, "target", "td2" );
		if ( pEntity !is null )
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "pass_destroy_item_name", "item_goldkey" );

		@pEntity = g_EntityFuncs.FindEntityByString( null, "target", "td1" );
		if ( pEntity !is null )
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "pass_destroy_item_name", "item_silverkey" );

		@pEntity = null;

		while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "item_inventory" ) ) !is null )
		{
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "carried_hidden", "0" );
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "holder_keep_on_death", "0" );
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "holder_timelimit", "300" );
		}
*/
		bLoadEnts = true;
	}
	else if ( g_szCurrentMap.ICompare( "q1_e1m7" ) == 0 )
	{
/*		@pEntity = g_EntityFuncs.FindEntityByTargetname( null, "mcm" );
		if ( pEntity !is null )
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "q1_show_stats", "40" );*/

		@pEntity = g_EntityFuncs.FindEntityByTargetname( null, "tmsg" );
		if ( pEntity !is null )
		{
			pEntity.pev.targetname = string_t( "tmsg_delay" );
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "fadeout", "3" );
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "color", "100 250 250" );
		}
/*
		@pEntity = g_EntityFuncs.FindEntityByClassname( null, "item_inventory" );
		if ( pEntity !is null )
		{
			@pEnt = g_EntityFuncs.Create( "item_security", pEntity.GetOrigin(), pEntity.pev.angles, true );
			if ( pEnt !is null )
			{
				pEnt.pev.target = pEntity.pev.target;
				pEnt.pev.model = pEntity.pev.model;

				g_EntityFuncs.DispatchSpawn( pEnt.edict() );

				g_EntityFuncs.Remove( pEntity );
			}	
		}
*/	
		bLoadEnts = true;
	}
	else if ( g_szCurrentMap.ICompare( "q1_e1m8" ) == 0 )
	{
/*		@pEntity = g_EntityFuncs.FindEntityByString( null, "target", "td1" );
		if ( pEntity !is null )
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "pass_destroy_item_name", "item_silverkey" );

		@pEntity = g_EntityFuncs.FindEntityByClassname( null, "item_inventory" );
		if ( pEntity !is null )
		{
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "carried_hidden", "0" );
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "holder_keep_on_death", "0" );
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "holder_timelimit", "300" );
		}
*/

		@pEntity = null;

		while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "func_plat" ) ) !is null )
		{
			szTargetName = pEntity.GetTargetname();

			if ( szTargetName.IsEmpty() && !pEntity.pev.SpawnFlagBitSet( 1 ) )
				continue;
				
		//	pEntity.pev.spawnflags &= ~1;

		//	g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "targetname", "" );
		//	g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "fireonopened", "" );
		//	g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "fireonclosed", "" );
			
		//	g_EntityFuncs.Remove( pEntity );
		
			pEntity.Use( pEntity, pEntity, USE_TOGGLE, 1 );
		}
/*
		@pEntity = g_EntityFuncs.FindEntityByString( null, "target", "knuckle" );
		if ( pEntity !is null )
			g_EntityFuncs.Remove( pEntity );

		@pEntity = g_EntityFuncs.FindEntityByString( null, "target", "sanic" );
		if ( pEntity !is null )
			g_EntityFuncs.Remove( pEntity );
*/
		@pEntity = null;

		while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "trigger_multiple" ) ) !is null )
		{
			if ( pEntity.pev.target == "td1" )
				continue;

			if ( pEntity.pev.SpawnFlagBitSet( 16 ) )
				pEntity.pev.spawnflags |= 32;
		}

		bLoadEnts = true;
	}
	else if ( g_szCurrentMap.ICompare( "q1_dm2" ) == 0 )
	{
		@pEntity = null;
	
		while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "trigger_changelevel" ) ) !is null )
		{
			g_EntityFuncs.Remove( pEntity );
		}
	}
	else if ( g_szCurrentMap.ICompare( "q1_dm4" ) == 0 )
	{
		@pEntity = null;

		while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "trigger_changelevel" ) ) !is null )
		{
			g_EntityFuncs.Remove( pEntity );
		}
	}
	else if ( g_szCurrentMap.ICompare( "q1_dm6" ) == 0 )
	{
		@pEntity = null;

		while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "trigger_changelevel" ) ) !is null )
		{
			g_EntityFuncs.Remove( pEntity );
		}
	}

	if ( bLoadEnts )
	{
		string szEntFile;
		snprintf( szEntFile, "quake1/ents/%1.ent", g_szCurrentMap );

		if ( !g_EntityLoader.LoadFromFile( szEntFile ) )
			g_EngineFuncs.ServerPrint( "Can't open " + szEntFile + "\n" );
	}

	if ( !bFixDoors )
		return;
	
	@pEntity = null;
	string szModel;
	
	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "func_door" ) ) !is null )
	{
		if ( !pEntity.GetTargetname().IsEmpty() )
			continue;

		szModel = pEntity.pev.model;

		if ( !dDoors.get( szModel, data ) )
			continue;
			
		if ( !data.Is2DoorSet() )
			continue;

		pEntity.pev.targetname = string_t( data.targetname );
		g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "fireonopening", data.fireonopening );

		if ( data.m_fIgnoreTargetname )
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "m_fIgnoreTargetname", "1" );

		if ( data.wait != 0 )
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "wait", string( data.wait ) );
	}

	if ( !dDoors.isEmpty() )
		dDoors.deleteAll();
}
