array<string> g_pTextures = {
"{capsa",
"{capsb",
"{capsc",
"{capsd",
"{capse", 
"{capsf",
"{capsg",
"{capsh",
"{capsi",
"{capsj", 
"{capsk",
"{capsl",
"{capsm",
"{capsn",
"{capso",
"{capsp",
"{capsq",
"{capsr",
"{capss",
"{capst",
"{capsu",
"{capsv",
"{capsw",
"{capsx",
"{capsy",
"{capsz"
};

dictionary g_pDictDecal;

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Duko" );
	g_Module.ScriptInfo.SetContactInfo( "group.midu.cz" );
	g_Module.ScriptInfo.SetMinimumAdminLevel( ADMIN_YES );
	
	for ( uint ui = 0; ui < g_pTextures.length(); ui++ )
	{
		string szName = g_pTextures[ui];
		g_pDictDecal.set( szName.SubString( 5 ), g_EngineFuncs.DecalIndex( szName ) );
	}
}

CClientCommand infodecal( "infodecal", "- infodecal", @cmdInfoDecal );

void cmdInfoDecal( const CCommand@ args )
{
	CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();

	if ( pPlayer is null || !pPlayer.IsConnected() )
		return;

	if ( !IsPlayerAdmin( pPlayer ) )
	{
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "You have no access to this command.\n" );
		return;
	}
	
	string szArgs = args.GetArgumentsString();
	if ( szArgs.IsEmpty() )
		return;

	szArgs.ToLowercase();


	TraceResult tr;
	Vector vecStart = pPlayer.GetGunPosition();

	Math.MakeVectors( pPlayer.pev.v_angle );
	g_Utility.TraceLine( vecStart, vecStart + g_Engine.v_forward * 4096, dont_ignore_monsters, pPlayer.edict(), tr );

	if ( tr.pHit !is null )
	{
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "tr.vecEndPos = " + tr.vecEndPos.ToString() + "\n" );

	/*	CBaseEntity@ pEntity = g_EntityFuncs.Create( "infodecal", tr.vecEndPos, g_vecZero, true );
		if ( pEntity !is null )
		{
			edict_t@ pEdict = pEntity.edict();
			g_EntityFuncs.DispatchKeyValue( pEdict, "texture", "{capsd" );
			g_EntityFuncs.DispatchSpawn( pEdict );
			
			g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "created\n" );
		}*/
		
		int16 iEnt = g_EntityFuncs.EntIndex( tr.pHit );
		
		Vector vecPosition = tr.vecEndPos;
	//	Vector vecAngles = pPlayer.pev.angles;
		uint8 uiDecal;

/*		int iSwitch;
		if ( vecAngles.x > 0 && vecAngles.y < 0 )
			iSwitch = 1;*/

		string szChar;

		for ( uint ui = 0; ui < szArgs.Length(); ui++ )
		{
			szChar = szArgs.opIndex( ui );
			if ( isspace( szChar ) )
			{
				vecPosition.y -= 12;
				continue;
			}
				
			if ( !g_pDictDecal.get( szChar, uiDecal ) )
				continue;
				
		//	g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, szChar + "\n" );

			if ( iEnt == 0 )
			{
				NetworkMessage message( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
				message.WriteByte( TE_WORLDDECAL );
				message.WriteCoord( vecPosition.x );
				message.WriteCoord( vecPosition.y );
				message.WriteCoord( vecPosition.z );
				message.WriteByte( uiDecal );
				message.End();
			}
			else
			{
				NetworkMessage message( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
				message.WriteByte( TE_DECAL );
				message.WriteCoord( vecPosition.x );
				message.WriteCoord( vecPosition.y );
				message.WriteCoord( vecPosition.z );
				message.WriteByte( uiDecal );
				message.WriteShort( iEnt );
				message.End();
			}
			
		/*	switch ( iSwitch )
			{
				case 1: vecPosition.x += 12; break;
			}*/
			vecPosition.y -= 12;
		}

	//	g_EntityFuncs.CreateDecal( "{capsd", tr.vecEndPos, "prd" );

	//	g_Utility.GunshotDecalTrace( tr, g_uiDecal );
	}
}

bool IsPlayerAdmin( CBasePlayer@ pPlayer )
{
	return g_PlayerFuncs.AdminLevel( pPlayer ) >= ADMIN_YES;
}
