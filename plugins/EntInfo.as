void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "pizzahut|Duko" );
	g_Module.ScriptInfo.SetContactInfo( "group.midu.cz" );
	g_Module.ScriptInfo.SetMinimumAdminLevel( ADMIN_YES );
}

void InfoEntity( const CCommand@ args )
{
	CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();

	if ( pPlayer is null || !pPlayer.IsConnected() )
		return;

	string szArg = args.Arg( 1 );
	szArg.Trim();

	CBaseEntity@ pEntity = null;
	
	string szSearchMethod;
	
	if ( szArg == "@me" )
		@pEntity = pPlayer;
	else if ( szArg.IsEmpty() )
		@pEntity = g_Utility.FindEntityForward( pPlayer, 4096 );
	else
	{
		while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, szArg ) ) !is null )
		{
			szSearchMethod = "Classname";
			break;
		}

		if ( pEntity is null )
		{	
			while ( ( @pEntity = g_EntityFuncs.FindEntityByTargetname( pEntity, szArg ) ) !is null )
			{
				szSearchMethod = "Targetname";
				break;
			}
		}

		if ( pEntity is null )
		{
			while ( ( @pEntity = g_EntityFuncs.FindEntityByString( pEntity, "target", szArg ) ) !is null )
			{
				szSearchMethod = "Target";
				break;
			}
		}

		if ( pEntity is null )
		{
			while ( ( @pEntity = g_EntityFuncs.FindEntityByString( pEntity, "model", szArg ) ) !is null )
			{
				szSearchMethod = "Model";
				break;
			}
		}
	}

	if ( pEntity is null )
		return;

	Vector absmin = pEntity.pev.absmin;
	Vector absmax = pEntity.pev.absmax;
	
	if ( absmin != g_vecZero && absmax != g_vecZero )
	{
		NetworkMessage msg( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
		msg.WriteByte( TE_BOX );
		msg.WriteCoord( absmin.x );
		msg.WriteCoord( absmin.y );
		msg.WriteCoord( absmin.z );
		msg.WriteCoord( absmax.x );
		msg.WriteCoord( absmax.y );
		msg.WriteCoord( absmax.z );
		msg.WriteShort( int16( 50 ) ); // life in 0.1 s
		msg.WriteByte( uint8( 255 ) ); // R
		msg.WriteByte( uint8( 10 ) ); // G
		msg.WriteByte( uint8( 10 ) ); // B
		msg.End();
	}

	HUDTextParams hudPrms;
	hudPrms.x = -1;
	hudPrms.y = 0.7;
				
	hudPrms.effect = 0;
				
	hudPrms.r1 = 255;
	hudPrms.g1 = 0;
	hudPrms.b1 = 0;
	hudPrms.a1 = 255;
				
	hudPrms.fadeinTime = 0.1;
	hudPrms.fadeoutTime = 0.2;
	hudPrms.holdTime = 5.0;
	hudPrms.fxTime = 6.0;
	hudPrms.channel = 4;
				
	g_PlayerFuncs.HudMessage( pPlayer, hudPrms, "Entity " + pEntity.entindex() + " " + pEntity.GetClassname() + "\nSee console for more info." );
	g_EngineFuncs.ClientPrintf( pPlayer, print_console, "--------------------------\n" );
	g_EngineFuncs.ClientPrintf( pPlayer, print_console, "Entity " + pEntity.entindex() + ( szSearchMethod.IsEmpty() ? "" : ", Found by " + szSearchMethod ) + "\n" );

	entvars_t@ pVars = pEntity.pev;
	
	if ( pVars is null )
	{
		g_EngineFuncs.ClientPrintf( pPlayer, print_console, "Entity " + pEntity.GetClassname() + " doesn't have entvars\n" );
		return;
	}

	/* Int */
	dictionary dictINT = {
	{'gamestate', pVars.gamestate},
	{'oldbuttons', pVars.oldbuttons},
	{'groupinfo', pVars.groupinfo},
	{'iuser1', pVars.iuser1},
	{'iuser2', pVars.iuser2},
	{'iuser3', pVars.iuser3},
	{'iuser4', pVars.iuser4},
	{'weaponanim', pVars.weaponanim},
	{'pushmsec', pVars.pushmsec},
	{'bInDuck', pVars.bInDuck},
	{'flTimeStepSound', pVars.flTimeStepSound},
	{'flSwimTime', pVars.flSwimTime},
	{'flDuckTime', pVars.flDuckTime},
	{'iStepLeft', pVars.iStepLeft},
	{'movetype', pVars.movetype},
	{'solid', pVars.solid},
	{'skin', pVars.skin},
	{'body', pVars.body},
	{'effects', pVars.effects},
	{'light_level', pVars.light_level},
	{'sequence', pVars.sequence},
	{'gaitsequence', pVars.gaitsequence},
	{'modelindex', pVars.modelindex},
	{'playerclass', pVars.playerclass},
	{'waterlevel', pVars.waterlevel},
	{'watertype', pVars.watertype},
	{'spawnflags', pVars.spawnflags},
	{'flags', pVars.flags},
	{'colormap', pVars.colormap},
	{'team', pVars.team},
	{'fixangle', pVars.fixangle},
	{'weapons', pVars.weapons},
	{'rendermode', pVars.rendermode},
	{'renderfx', pVars.renderfx},
	{'button', pVars.button},
	{'impulse', pVars.impulse},
	{'deadflag', pVars.deadflag} };


	array<string>@ keys = dictINT.getKeys();
	uint uiCount = keys.length();

	int iValue;
	for ( uint uiIndex = 0; uiIndex < uiCount; uiIndex++ )
	{
		if ( dictINT.get( keys[ uiIndex ], iValue ) && iValue != 0 )
			g_EngineFuncs.ClientPrintf( pPlayer, print_console, "INT " + keys[ uiIndex ] + " = " + iValue + "\n" );
	}
	
	dictINT.deleteAll();
	keys.resize(0);

	/* Float */
	dictionary dictFL = {
	{'impacttime', pVars.impacttime},
	{'starttime', pVars.starttime},
	{'idealpitch', pVars.idealpitch},
	{'pitch_speed', pVars.pitch_speed},
	{'ideal_yaw', pVars.ideal_yaw},
	{'yaw_speed', pVars.yaw_speed},
	{'ltime', pVars.ltime},
	{'nextthink', pVars.nextthink},
	{'gravity', pVars.gravity},
	{'friction', pVars.friction},
	{'frame', pVars.frame},
	{'animtime', pVars.animtime},
	{'framerate', pVars.framerate},
	{'health', pVars.health},
	{'frags', pVars.frags},
	{'takedamage', pVars.takedamage},
	{'max_health', pVars.max_health},
	{'teleport_time', pVars.teleport_time},
	{'armortype', pVars.armortype},
	{'armorvalue', pVars.armorvalue},
	{'dmg_take', pVars.dmg_take},
	{'dmg_save', pVars.dmg_save},
	{'dmg', pVars.dmg},
	{'dmgtime', pVars.dmgtime},
	{'speed', pVars.speed},
	{'air_finished', pVars.air_finished},
	{'pain_finished', pVars.pain_finished},
	{'radsuit_finished', pVars.radsuit_finished},
	{'scale', pVars.scale},
	{'renderamt', pVars.renderamt},
	{'maxspeed', pVars.maxspeed},
	{'fov', pVars.fov},
	{'flFallVelocity', pVars.flFallVelocity},
	{'fuser1', pVars.fuser1},
	{'fuser2', pVars.fuser2},
	{'fuser3', pVars.fuser3},
	{'fuser4', pVars.fuser4} };

	@keys = dictFL.getKeys();
	uiCount = keys.length();

	float flValue;
	for ( uint uiIndex = 0; uiIndex < uiCount; uiIndex++ )
	{
		if ( dictFL.get( keys[ uiIndex ], flValue ) && flValue != 0.0 )
			g_EngineFuncs.ClientPrintf( pPlayer, print_console, "FL " + keys[ uiIndex ] + " = " + flValue + "\n" );
	}
	
	dictFL.deleteAll();
	keys.resize(0);

	/* Vector */
	dictionary dictVEC = {
	{'origin', pVars.origin},
	{'oldorigin', pVars.oldorigin},
	{'velocity', pVars.velocity},
	{'basevelocity', pVars.basevelocity},
//	{'clbasevelocity', pVars.clbasevelocity},
	{'movedir', pVars.movedir},
	{'angles', pVars.angles},
	{'avelocity', pVars.avelocity},
	{'punchangle', pVars.punchangle},
	{'v_angle', pVars.v_angle},
	{'startpos', pVars.startpos},
	{'endpos', pVars.endpos},
	{'absmin', pVars.absmin},
	{'absmax', pVars.absmax},
	{'mins', pVars.mins},
	{'maxs', pVars.maxs},
	{'size', pVars.size},
	{'rendercolor', pVars.rendercolor},
	{'view_ofs', pVars.view_ofs},
	{'vuser1', pVars.vuser1},
	{'vuser2', pVars.vuser2},
	{'vuser3', pVars.vuser3},
	{'vuser4', pVars.vuser4} };

	@keys = dictVEC.getKeys();
	uiCount = keys.length();

	Vector vecValue;
	for ( uint uiIndex = 0; uiIndex < uiCount; uiIndex++ )
	{
		if ( dictVEC.get( keys[ uiIndex ], vecValue ) && vecValue != g_vecZero )
			g_EngineFuncs.ClientPrintf( pPlayer, print_console, "VEC " + keys[ uiIndex ] + " = (" + vecValue.x + ", " + vecValue.y + ", " + vecValue.z + ")\n" );
	}
	
	dictVEC.deleteAll();
	keys.resize(0);

	/* Edict */
	dictionary dictENT = {
	{'chain', pVars.chain},
	{'dmg_inflictor', pVars.dmg_inflictor},
	{'enemy', pVars.enemy},
	{'aiment', pVars.aiment},
	{'owner', pVars.owner},
	{'groundentity', pVars.groundentity},
	{'pContainingEntity', pVars.pContainingEntity},
	{'euser1', pVars.euser1},
	{'euser2', pVars.euser2},
	{'euser3', pVars.euser3},
	{'euser4', pVars.euser4} };

	@keys = dictENT.getKeys();
	uiCount = keys.length();

	edict_t@ pEdict;
	int entValue;
	for ( uint uiIndex = 0; uiIndex < uiCount; uiIndex++ )
	{
		if ( !dictENT.get( keys[ uiIndex ], @pEdict ) )
			continue;
		entValue = g_EntityFuncs.EntIndex( pEdict );
		if ( entValue == 0 )
			continue;

		g_EngineFuncs.ClientPrintf( pPlayer, print_console, "ENT " + keys[ uiIndex ] + " = " + entValue + "\n" );
	}
	
	dictENT.deleteAll();
	keys.resize(0);

	/* String */
	dictionary dictSZ = {
	{'classname', string(pVars.classname)},
	{'globalname', string(pVars.globalname)},
	{'model', string(pVars.model)},
	{'target', string(pVars.target)},
	{'targetname', string(pVars.targetname)},
	{'netname', string(pVars.netname)},
	{'message', string(pVars.message)},
	{'noise', string(pVars.noise)},
	{'noise1', string(pVars.noise1)},
	{'noise2', string(pVars.noise2)},
	{'noise3', string(pVars.noise3)},
	{'viewmodel', string(pVars.viewmodel)},
	{'weaponmodel', string(pVars.weaponmodel)} };

	@keys = dictSZ.getKeys();
	uiCount = keys.length();

	string szValue;
	for ( uint uiIndex = 0; uiIndex < uiCount; uiIndex++ )
	{
		if ( dictSZ.get( keys[ uiIndex ], szValue ) && !szValue.IsEmpty() )
			g_EngineFuncs.ClientPrintf( pPlayer, print_console, "SZ " + keys[ uiIndex ] + " = " + szValue + "\n" );
	}

	dictSZ.deleteAll();
	keys.resize(0);

	/* Byte */
	dictionary dictBYTE = {
	{'controller1', pVars.get_controller(0)},
	{'controller2', pVars.get_controller(1)},
	{'controller3', pVars.get_controller(2)},
	{'controller4', pVars.get_controller(3)},
	{'blending1', pVars.get_blending(0)},
	{'blending2', pVars.get_blending(1)} };

	@keys = dictBYTE.getKeys();
	uiCount = keys.length();

	for ( uint uiIndex = 0; uiIndex < uiCount; uiIndex++ )
	{
		if ( dictBYTE.get( keys[ uiIndex ], iValue ) && iValue != 0 )
			g_EngineFuncs.ClientPrintf( pPlayer, print_console, "BYTE " + keys[ uiIndex ] + " = " + iValue + "\n" );
	}

	dictBYTE.deleteAll();
	keys.resize(0);
	
	int iClassification = pEntity.Classify();
	if ( iClassification != 0 )
		g_EngineFuncs.ClientPrintf( pPlayer, print_console, "INT Classification = " + iClassification + "\n" );
	
	g_EngineFuncs.ClientPrintf( pPlayer, print_console, "B is moving = " + ( pEntity.IsMoving() ? "Yes" : "No" ) + "\n" );
	g_EngineFuncs.ClientPrintf( pPlayer, print_console, "B is machine = " + ( pEntity.IsMachine() ? "Yes" : "No" ) + "\n" );
	g_EngineFuncs.ClientPrintf( pPlayer, print_console, "B is monster = " + ( pEntity.IsMonster() ? "Yes" : "No" ) + "\n" );

	CBaseMonster@ pMonster = cast<CBaseMonster@>( pEntity );
	if ( pMonster !is null )
	{
		int iTriggerCondition = pMonster.m_iTriggerCondition;
		if ( iTriggerCondition != 0 )
			g_EngineFuncs.ClientPrintf( pPlayer, print_console, "INT Trigger Condition = " + iTriggerCondition + "\n" );
	
		string szTriggerTarget = pMonster.m_iszTriggerTarget;
		if ( !szTriggerTarget.IsEmpty() )
			g_EngineFuncs.ClientPrintf( pPlayer, print_console, "SZ Trigger Target = " + szTriggerTarget + "\n" );
	
		string szFormattedName = pMonster.m_FormattedName;
		if ( !szFormattedName.IsEmpty() )
			g_EngineFuncs.ClientPrintf( pPlayer, print_console, "SZ Monster displayname = " + szFormattedName + "\n" );
		
		g_EngineFuncs.ClientPrintf( pPlayer, print_console, "B Monster Ally = " + ( pMonster.IsPlayerAlly() ? "Yes" : "No" )  + "\n" );
	}
	
	CBaseToggle@ pToggle = cast<CBaseToggle@>( pEntity );
	if ( pToggle !is null )
	{
		int iToggleState = pToggle.GetToggleState();
		if ( iToggleState != 0 )
			g_EngineFuncs.ClientPrintf( pPlayer, print_console, "INT Toggle State = " + iToggleState + "\n" );
		
		float flDelay = pToggle.m_flDelay;
		if ( flDelay != 0 )
			g_EngineFuncs.ClientPrintf( pPlayer, print_console, "FL Delay = " + flDelay + "\n" );

		float flWait = pToggle.m_flWait;
		if ( flWait != 0 )
			g_EngineFuncs.ClientPrintf( pPlayer, print_console, "FL Wait = " + flWait + "\n" );

		string szKillTarget = pToggle.m_iszKillTarget;
		if ( !szKillTarget.IsEmpty() )
			g_EngineFuncs.ClientPrintf( pPlayer, print_console, "SZ KillTarget = " + szKillTarget + "\n" );
	
		string szMaster = pToggle.m_sMaster;
		if ( !szMaster.IsEmpty() )
			g_EngineFuncs.ClientPrintf( pPlayer, print_console, "SZ Master = " + szMaster + "\n" );
	}
	else
	{
		CBaseDelay@ pDelay = cast<CBaseDelay@>( pEntity );
		if ( pDelay !is null )
		{
			float flDelay = pDelay.m_flDelay;
			if ( flDelay != 0 )
				g_EngineFuncs.ClientPrintf( pPlayer, print_console, "FL Delay = " + flDelay + "\n" );

			string szKillTarget = pDelay.m_iszKillTarget;
			if ( !szKillTarget.IsEmpty() )
				g_EngineFuncs.ClientPrintf( pPlayer, print_console, "SZ KillTarget = " + szKillTarget + "\n" );
		}
	}
	
	g_EngineFuncs.ClientPrintf( pPlayer, print_console, "--------------------------\n\n" );
}

CClientCommand ent_info( "ent_info", "Entity Info", @InfoEntity ); //.ent_info

/*
string VecTOString( Vector vec )
{
	if ( vec.x != 0.0 || vec.y != 0.0 || vec.z != 0.0 )
		return "(" + vec.x + ", " + vec.y + ", " + vec.z + ")";

	return "";
}
*/
