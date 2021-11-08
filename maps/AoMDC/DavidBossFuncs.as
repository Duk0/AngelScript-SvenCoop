// Afraid of Monsters: Director's Cut Script
// Misc Script: David Boss Functions
// Author: Zorbos

const float DAVIDBAD_MOD_ELECTRIC_RADIUS = 1500.0;
const float DAVIDBAD_MOD_ELECTRIC_DAMAGE = 15.0;

// David's Electric Shock attack. Damages players for 15 health
// if they are on the ground when this function is called.
void ElectricAttack( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
{	
	CBaseMonster@ pDavid = FindDavid();
	
	if ( pDavid !is null )
	{
		CBaseEntity@ pEntity = null;
		CBasePlayer@ pPlayer;
	
		while ( ( @pEntity = g_EntityFuncs.FindEntityInSphere( pEntity, pDavid.pev.origin, DAVIDBAD_MOD_ELECTRIC_RADIUS, "player", "classname" ) ) !is null )
		{
			@pPlayer = cast<CBasePlayer@>( pEntity );
			
			if ( pPlayer is null || !pPlayer.IsAlive() )
				continue;
			
			if ( pPlayer.pev.flags & FL_ONGROUND == 0 ) // Take damage if the player is on the ground
				continue;
				
			if ( pDavid is null || !pDavid.IsAlive() )
				break;

			pPlayer.TakeDamage( pDavid.pev, pDavid.pev, DAVIDBAD_MOD_ELECTRIC_DAMAGE, DMG_SHOCK );
		}
	}
}

// Returns a handle to the currently spawned David monster if he exists
CBaseMonster@ FindDavid()
{
	CBaseEntity@ pDavid = null;
	
	// Search for the david monster
	const array<string> baddavid = { "baddavid3", "baddavid4", "baddavid5", "baddavid6", "baddavid7" };
	
	for ( uint uiIndex = 0; uiIndex < baddavid.length(); ++uiIndex )
	{
		@pDavid = g_EntityFuncs.FindEntityByTargetname( null, baddavid[uiIndex] );

		if ( pDavid is null )
			continue;
			
		return cast<CBaseMonster@>( pDavid );
	}
	
	return null; // David monster not found
}
