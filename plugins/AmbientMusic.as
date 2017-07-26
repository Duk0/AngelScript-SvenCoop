
void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Duko" );
	g_Module.ScriptInfo.SetContactInfo( "group.midu.cz" );
	
	g_EngineFuncs.ServerPrint( "[AmbientMusic] Reloaded...\n" );
}

class AmbientData
{
	string targetname;
	string message;
	string volume;
	int spawnflags;
}

void MapStart()
{
	CBaseEntity@ pEntity = null, pEnt = null;
	array<AmbientData> pStored;
	AmbientData data;
	int iVolume, iTargets;

	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "ambient_generic" ) ) !is null )
	{
		data.targetname = pEntity.GetTargetname();
		data.message = pEntity.pev.message;

		if ( data.targetname.IsEmpty() || data.message.IsEmpty() )
			continue;

		if ( !pEntity.pev.SpawnFlagBitSet( 1 ) )
			continue;
		
		//need something to get audio file lenght in seconds (optional miliseconds), simple detect if sound is music or effect
		//if ( data.message.EndsWith( ".wav", String::CaseInsensitive ) )
		/*if ( data.message.EndsWith( ".wav", String::CaseInsensitive ) && int( data.targetname.Find( "music", 0, String::CaseInsensitive ) ) == -1 )
			continue;*/
			
		if ( int( data.targetname.Find( "music", 0, String::CaseInsensitive ) ) == -1 && int( data.targetname.Find( "song", 0, String::CaseInsensitive ) ) == -1 && int( data.targetname.Find( "bgm", 0, String::CaseInsensitive ) ) == -1 )
			continue;

		iVolume = int( pEntity.pev.health );

		if ( iVolume > 10 )
			iVolume = 10;

		if ( iVolume == 10 )
			iVolume -= 8;

		data.volume = iVolume;
		data.spawnflags = 0;
		iTargets = 0;

		while ( ( @pEnt = g_EntityFuncs.FindEntityByClassname( pEnt, "*" ) ) !is null )
		{
			CBaseDelay@ pDelay = cast<CBaseDelay@>( pEnt );

			if ( pDelay !is null && pDelay.m_iszKillTarget == data.targetname )
				iTargets++;

			if ( pEnt !is pEntity && data.targetname != pEnt.GetTargetname() && pEnt.HasTarget( data.targetname ) )
				iTargets++;
		}

		if ( pEntity.pev.SpawnFlagBitSet( 16 ) )
			data.spawnflags |= 1;

		if ( iTargets > 1 && !pEntity.pev.SpawnFlagBitSet( 32 ) )
			data.spawnflags |= 2;

		if ( pEntity.pev.SpawnFlagBitSet( 64 ) )
			data.spawnflags |= 4;

		pStored.insertLast( data );

		g_EntityFuncs.Remove( pEntity );
	}

	for ( uint i = 0; i < pStored.length(); i++ )
	{
		data = pStored[i];

		@pEnt = g_EntityFuncs.Create( "ambient_music", g_vecZero, g_vecZero, true );
		if ( pEnt is null )
			continue;

		pEnt.pev.targetname = data.targetname;
		pEnt.pev.message = data.message;
		pEnt.pev.spawnflags = data.spawnflags;
			
		g_EntityFuncs.DispatchKeyValue( pEnt.edict(), "volume", data.volume );
		g_EntityFuncs.DispatchSpawn( pEnt.edict() );
	}
	
	if ( pStored.length() > 0 )
		g_EngineFuncs.ServerPrint( "[AmbientMusic] Replaced " + pStored.length() + " ambient_generic entities.\n" );
}
