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
	CBaseDelay@ pDelay = null;
	CBaseToggle@ pToggle = null;
	CBaseMonster@ pMonster = null;
	array<AmbientData> pStored;
	AmbientData data, dict;
	int iVolume, iTargets;
	dictionary dMusicData;
	
/*	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "ambient_music" ) ) !is null )
	{
		g_EngineFuncs.ServerPrint( "[AmbientMusic] targetname: " + pEntity.GetTargetname() + "\n" );
		
		g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "volume", "7" );
	}*/

	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "ambient_generic" ) ) !is null )
	{
		data.targetname = pEntity.GetTargetname();
		data.message = pEntity.pev.message;

		if ( data.targetname.IsEmpty() || data.message.IsEmpty() )
			continue;

		if ( !pEntity.pev.SpawnFlagBitSet( 1 ) )
			continue;
		
		//need something to get audio file lenght in seconds (optional miliseconds), simple detect if sound is music or effect	
		if ( !IsMusic( data.targetname ) && !IsMusic( data.message ) )
			continue;

		iVolume = int( pEntity.pev.health );

		// some music is too loudly
		if ( iVolume >= 10 )
			iVolume = 7;
		else if ( iVolume < 10 && iVolume > 5 )
			iVolume = 5;

		data.volume = iVolume;
		data.spawnflags = 0;
		iTargets = 0;

		@pEnt = null;
		// check for loop flag, would be better check audio file // todo trigger_random*
		while ( ( @pEnt = g_EntityFuncs.FindEntityByClassname( pEnt, "*" ) ) !is null )
		{
			@pDelay = cast<CBaseDelay@>( pEnt );
			@pToggle = cast<CBaseToggle@>( pEnt );
			@pMonster = cast<CBaseMonster@>( pEnt );

			if ( pDelay !is null && pDelay.m_iszKillTarget == data.targetname )
				iTargets++;
			else if ( pToggle !is null && pToggle.m_iszKillTarget == data.targetname )
				iTargets++;
				
			if ( pMonster !is null && pMonster.m_iszTriggerTarget == data.targetname )
				iTargets++;

			if ( pEnt !is pEntity && data.targetname != pEnt.GetTargetname() && pEnt.HasTarget( data.targetname ) )
				iTargets++;
				
			if ( pEnt !is pEntity && data.targetname == pEnt.pev.target )
				iTargets++;
		}

		if ( pEntity.pev.SpawnFlagBitSet( 16 ) )
			data.spawnflags |= 1;

		if ( iTargets > 1 && !pEntity.pev.SpawnFlagBitSet( 32 ) || pEntity.pev.iuser1 == 2 )
			data.spawnflags |= 2;

		if ( pEntity.pev.SpawnFlagBitSet( 64 ) )
			data.spawnflags |= 4;
		
		// ambient_generic with spawnflags 33 set, normaly starts silent
		if ( data.spawnflags == 0 && iTargets >= 0 && pEntity.pev.SpawnFlagBitSet( 32 ) )
			data.spawnflags |= 1;

		g_EntityFuncs.Remove( pEntity );

		if ( dMusicData.get( data.targetname, dict ) && dict.message == data.message && dict.spawnflags == data.spawnflags )
			continue;
			
		dMusicData.set( data.targetname, data );

		pStored.insertLast( data );
	}

	if ( !dMusicData.isEmpty() )
		dMusicData.deleteAll();

	for ( uint i = 0; i < pStored.length(); i++ )
	{
		data = pStored[i];

		@pEntity = g_EntityFuncs.Create( "ambient_music", g_vecZero, g_vecZero, true );
		if ( pEntity is null )
			continue;

		pEntity.pev.targetname = data.targetname;
		pEntity.pev.message = data.message;
		pEntity.pev.spawnflags = data.spawnflags;
			
		g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "volume", data.volume );
		g_EntityFuncs.DispatchSpawn( pEntity.edict() );
	}
	
	if ( pStored.length() > 0 )
		g_EngineFuncs.ServerPrint( "[AmbientMusic] Replaced " + pStored.length() + " ambient_generic entities.\n" );
}

bool IsMusic( const string &in szName )
{
	if ( int( szName.Find( "breathing", 0, String::CaseInsensitive ) ) != -1 )
		return false;

	if ( int( szName.Find( "music", 0, String::CaseInsensitive ) ) != -1 )
		return true;
	if ( int( szName.Find( "song", 0, String::CaseInsensitive ) ) != -1 )
		return true;
	if ( int( szName.Find( "bgm", 0, String::CaseInsensitive ) ) != -1 )
		return true;
	if ( int( szName.Find( "musa", 0, String::CaseInsensitive ) ) != -1 )
		return true;
	if ( int( szName.Find( "hmg_", 0, String::CaseInsensitive ) ) != -1 )
		return true;
	if ( int( szName.Find( "theme", 0, String::CaseInsensitive ) ) != -1 )
		return true;
	if ( int( szName.Find( "intro", 0, String::CaseInsensitive ) ) != -1 )
		return true;
	if ( int( szName.Find( "/mp3", 0, String::CaseInsensitive ) ) != -1 )
		return true;

	return false;
}
