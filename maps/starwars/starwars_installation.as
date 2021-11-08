#include "starwars"

bool g_bMapInstallation1 = false;
bool g_bMapInstallation2 = false;

array<ItemMapping@> g_ItemMappings = {
	ItemMapping( "weapon_gauss", "weapon_e11blaster" ),
	ItemMapping( "ammo_gaussclip", "ammo_blaster" ),
	ItemMapping( "weapon_crossbow", "weapon_bowcasterblaster" ),
	ItemMapping( "ammo_crossbow", "ammo_highpowerblaster" )
};

void MapInit()
{
	SWRegister();
	
	g_ClassicMode.SetItemMappings( @g_ItemMappings );

	g_Game.PrecacheOther( "monster_stormtrooper" );

	string szCurrentMap = g_Engine.mapname;
	
	if ( szCurrentMap.ICompare( "sc_swars_installation" ) == 0 )
		g_GlobalState.EntitySetState( "gen1", GLOBAL_ON );
	else if ( szCurrentMap.ICompare( "sc_swars_installation1" ) == 0 )
		g_bMapInstallation1 = true;
	else if ( szCurrentMap.ICompare( "sc_swars_installation2" ) == 0 )
		g_bMapInstallation2 = true;

	if ( g_bMapInstallation2 )
		return;

	string szEntFile;
	snprintf( szEntFile, "starwars/swars_installation/%1.ent", szCurrentMap );

	if ( !g_EntityLoader.LoadFromFile( szEntFile ) )
		g_EngineFuncs.ServerPrint( "Can't open " + szEntFile + "\n" );
}

void MapActivate()
{
	CBaseEntity@ pEntity = null;
	CBaseEntity@ pEnt;
	string szClassName;
	string szMappedName;
	float flZOffset;

	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "squadmaker" ) ) !is null )
	{
		flZOffset = GetEntityZOffset( pEntity );

		if ( pEntity.pev.origin.z - flZOffset > 20.0f )
		{
		//	g_EngineFuncs.ServerPrint( "flZOffset: " + flZOffset + ", diff: " + ( pEntity.pev.origin.z - flZOffset ) + "\n" );

			pEntity.pev.origin.z = flZOffset + 20.0f;
		}
		
		if ( pEntity.pev.health == 0.0f )
			pEntity.pev.max_health = pEntity.pev.health = 200.0f;
	
		pEntity.pev.weapons = 0;

		g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "new_model", "models/starwars/stormtrooper.mdl" );
		g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "monstertype", "monster_stormtrooper" );
	}

	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "func_tank" ) ) !is null )
	{
		if ( pEntity.pev.globalname == "gen1" )
		{
			pEntity.pev.globalname = string_t();
		
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "rendercolor", "255 255 255" );
		}

		g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "relation_none", "-1" );
		g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "relation_human_militar", "-1" );
		g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "relation_alien_monster", "-1" );

	//	g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "spriteflash", "sprites/starwars/blasterboltred.spr" );
	}

	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "weapon_*" ) ) !is null )
	{
		szClassName = pEntity.GetClassname();
		szMappedName = g_ClassicMode.FindItemMapping( szClassName );

		if ( szMappedName.IsEmpty() )
			continue;
		
	/*	if ( szClassName == "weapon_gauss" )
			pEntity.pev.angles.y -= 180;*/

		@pEnt = g_EntityFuncs.Create( szMappedName, pEntity.GetOrigin(), pEntity.pev.angles, true );
		if ( pEnt is null )
			continue;
		
		pEnt.pev.spawnflags = pEntity.pev.spawnflags;

		g_EntityFuncs.Remove( pEntity );
		g_EntityFuncs.DispatchSpawn( pEnt.edict() );

		g_EngineFuncs.ServerPrint( szClassName + " replaced with: " + szMappedName + "\n" );
	}

	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "ammo_*" ) ) !is null )
	{
		szClassName = pEntity.GetClassname();
		szMappedName = g_ClassicMode.FindItemMapping( szClassName );

		if ( szMappedName.IsEmpty() )
			continue;

		@pEnt = g_EntityFuncs.Create( szMappedName, pEntity.GetOrigin(), pEntity.pev.angles, true );
		if ( pEnt is null )
			continue;
		
		pEnt.pev.spawnflags = pEntity.pev.spawnflags;

		g_EntityFuncs.Remove( pEntity );
		g_EntityFuncs.DispatchSpawn( pEnt.edict() );

		g_EngineFuncs.ServerPrint( szClassName + " replaced with: " + szMappedName + "\n" );
	}

	if ( !g_bMapInstallation2 )
	{
		@pEntity = g_EntityFuncs.FindEntityByClassname( null, "game_end" );
		if ( pEntity !is null )
		{
			string szTargetName = pEntity.GetTargetname();

			g_EntityFuncs.Remove( pEntity );

			if ( !szTargetName.IsEmpty() )
			{
				@pEntity = g_EntityFuncs.FindEntityByString( null, "target", szTargetName );
				
				if ( pEntity !is null )
					g_EntityFuncs.Remove( pEntity );
			}
		}
	}

	// sc_swars_installation1 or sc_swars_installation2
	if ( !g_bMapInstallation1 && !g_bMapInstallation2 )
		return;
	
	@pEntity = null;
	CBaseMonster@ pMonster;
	int iTriggerCondition;
	string szTriggerTarget;
	
	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "monster_shocktrooper" ) ) !is null )
	{
		@pEnt = g_EntityFuncs.Create( "monster_stormtrooper", pEntity.GetOrigin(), pEntity.pev.angles, true );
		if ( pEnt is null )
			continue;

		@pMonster = cast<CBaseMonster@>( pEntity );
		if ( pMonster is null )
			continue;
		
		iTriggerCondition = pMonster.m_iTriggerCondition;
		szTriggerTarget = pMonster.m_iszTriggerTarget;
		
		@pMonster = cast<CBaseMonster@>( pEnt );
		if ( pMonster is null )
			continue;
		
		if ( iTriggerCondition != 0 )
			pMonster.m_iTriggerCondition = iTriggerCondition;

		if ( !szTriggerTarget.IsEmpty() )
			pMonster.m_iszTriggerTarget = szTriggerTarget;
		
		pEnt.pev.spawnflags = pEntity.pev.spawnflags;

		if ( pEntity.pev.health < 200.0f )
			pEnt.pev.max_health = pEnt.pev.health = 200.0f;
		else
		{
			pEnt.pev.max_health = pEntity.pev.max_health;
			pEnt.pev.health = pEntity.pev.health;
		}

		g_EntityFuncs.Remove( pEntity );
		g_EntityFuncs.DispatchSpawn( pEnt.edict() );

		g_EngineFuncs.ServerPrint( "monster_shocktrooper replaced with: monster_stormtrooper\n" );
	}

	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "trigger_hurt" ) ) !is null )
	{	
		if ( pEntity.pev.dmg > 1000 )
			continue;

		pEntity.pev.dmg *= 100;
	}

	// sc_swars_installation1
	if ( !g_bMapInstallation1 )
		return;
	
	while ( ( @pEntity = g_EntityFuncs.FindEntityByTargetname( pEntity, "D_ventilator*" ) ) !is null )
	{
		if ( pEntity.GetTargetname() == "D_ventilators" )
			continue;

		if ( pEntity.pev.dmg > 1000 )
			continue;
	
		pEntity.pev.dmg *= 100;
	}
	
	@pEntity = g_EntityFuncs.FindEntityByClassname( null, "trigger_random_time" );
	if ( pEntity !is null )
	{
	//	g_EntityFuncs.Remove( pEntity );
		pEntity.pev.spawnflags |= 2;
	}
		
	@pEntity = g_EntityFuncs.FindEntityByTargetname( null, "D_lift" );
	if ( pEntity !is null )
	{
	//	pEntity.pev.target = string_t();
		pEntity.pev.dmg *= 100;

		g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "wait", "-1" );
	/*	g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "fireonopened", "D_lift_random" );
		g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "fireonclosed", "D_lift_random" );*/
	}
}

float GetEntityZOffset( CBaseEntity@ pEntity )
{
	TraceResult tr;

	g_Utility.TraceLine( pEntity.GetOrigin(), pEntity.GetOrigin() - Vector( 0, 0, 2048 ), ignore_monsters, pEntity.edict(), tr );
	return tr.vecEndPos.z;
}
