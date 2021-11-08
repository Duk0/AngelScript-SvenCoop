// Afraid of Monsters Classic Script
// Misc Script: item_inventory Sprite Manager
// Author: Zorbos

void AttachPlayerKeySprite( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
{	
	if ( pActivator is null || !pActivator.IsPlayer() )
		return;
	
	CBasePlayer@ pPlayer = cast<CBasePlayer@>( pActivator );

	if ( pPlayer is null )
		return;
	
	pPlayer.pev.targetname = string_t( "pKey_holder" );
	
	CBaseEntity@ pAttach = null;
	
	string pSprOffset = "0 0 44";
	string pOrigin = string( pPlayer.pev.origin.x ) + " " + 
							 pPlayer.pev.origin.y + " " + 
							 pPlayer.pev.origin.z;
	

	dictionary@ pAttachValues = {{"targetname", "pKey_spr_attach"}, {"origin", pOrigin}, {"target", "pKey_spr"}, {"offset", pSprOffset}, {"copypointer", "pKey_holder"}, {"spawnflags", "1011"}};
	@pAttach = g_EntityFuncs.CreateEntity("trigger_setorigin", @pAttachValues, true);

	if ( pAttach !is null )
	{
		dictionary@ pSprValues = {{"targetname", "pKey_spr"}, {"origin", pOrigin}, {"model", "sprites/AoMClassic/keyicon.spr"}, {"framerate", "10"}, {"rendermode", "5"}, {"renderamt", "255"}, {"scale", "0.12"}, {"spawnflags", "1"}};
		g_EntityFuncs.CreateEntity( "env_sprite", @pSprValues, true );

		g_EntityFuncs.FireTargets( "pKey_spr_attach", null, null, USE_ON, 0, 0 );
	}
	
	RemoveDroppedKeySprite();
}

void AttachDroppedKeySprite()
{
	CBaseEntity@ pEntity = null, pAttach = null, pSprite = null;
	edict_t@ pEdict;

	while ( ( @pEntity = g_EntityFuncs.FindEntityByTargetname( pEntity, "pKey" ) ) !is null )
	{
		if  ( pEntity.GetClassname() == "item_inventory" )
		{		
			@pAttach = g_EntityFuncs.Create( "trigger_setorigin", pEntity.GetOrigin(), g_vecZero, true );

			if ( pAttach !is null )
			{
				@pEdict = pAttach.edict();
				g_EntityFuncs.DispatchKeyValue( pEdict, "targetname", "pKey_droppedspr_attach" );
				g_EntityFuncs.DispatchKeyValue( pEdict, "target", "pKey_droppedspr" );
				g_EntityFuncs.DispatchKeyValue( pEdict, "offset", "0 0 14" );
				g_EntityFuncs.DispatchKeyValue( pEdict, "copypointer", "pKey" );
				g_EntityFuncs.DispatchKeyValue( pEdict, "spawnflags", "1011" );
				g_EntityFuncs.DispatchSpawn( pEdict );

				@pSprite = g_EntityFuncs.Create( "env_sprite", pEntity.GetOrigin(), g_vecZero, true );

				if ( pSprite !is null )
				{
					@pEdict = pAttach.edict();
					g_EntityFuncs.DispatchKeyValue( pEdict, "targetname", "pKey_droppedspr" );
					g_EntityFuncs.DispatchKeyValue( pEdict, "model", "sprites/AoMClassic/keyicon.spr" );
					g_EntityFuncs.DispatchKeyValue( pEdict, "framerate", "10" );
					g_EntityFuncs.DispatchKeyValue( pEdict, "rendermode", "5" );
					g_EntityFuncs.DispatchKeyValue( pEdict, "renderamt", "255" );
					g_EntityFuncs.DispatchKeyValue( pEdict, "scale", "0.13" );
					g_EntityFuncs.DispatchKeyValue( pEdict, "spawnflags", "1" );
					g_EntityFuncs.DispatchSpawn( pEdict );
				}
				
				g_EntityFuncs.FireTargets( "pKey_droppedspr_attach", null, null, USE_ON, 0, 0 );
			}
		}
	}
}

void RemoveDroppedKeySprite()
{
	CBaseEntity@ pEntity = null;

	while ( ( @pEntity = g_EntityFuncs.FindEntityByTargetname( pEntity, "pKey_droppedspr" ) ) !is null )
		g_EntityFuncs.Remove( pEntity );

	@pEntity = null;

	while ( ( @pEntity = g_EntityFuncs.FindEntityByTargetname( pEntity, "pKey_droppedspr_attach" ) ) !is null )
		g_EntityFuncs.Remove( pEntity );
}

void KeyDropped( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
{
	if ( pActivator is null || !pActivator.IsPlayer() )
		return;
		
	CBasePlayer@ pPlayer = cast<CBasePlayer@>( pActivator );
	if ( pPlayer is null )
		return;

	pPlayer.pev.targetname = string_t(); // Reset the targetname

	RemovePlayerKeySprite();
	AttachDroppedKeySprite();
}

void RemovePlayerKeySprite()
{
	CBaseEntity@ pEntity = null;

	while ( ( @pEntity = g_EntityFuncs.FindEntityByTargetname( pEntity, "pKey_spr" ) ) !is null )
		g_EntityFuncs.Remove( pEntity );
	
	@pEntity = null;

	while ( ( @pEntity = g_EntityFuncs.FindEntityByTargetname( pEntity, "pKey_spr_attach" ) ) !is null )
		g_EntityFuncs.Remove( pEntity );
}
