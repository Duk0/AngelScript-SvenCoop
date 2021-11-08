#include "weapon_knife"
#include "weapon_fiveseven"
#include "weapon_p228sil"
#include "weapon_colt"
#include "weapon_dualglock"
#include "weapon_sawedoff_io"
#include "BulletEjection"

int g_iSecretTotal = 0;
int g_iSecretFound = 0;

void MapInit()
{
	RegisterWeapon_KNIFE();
	RegisterFIVESEVEN();
	RegisterCOLT();
	RegisterELITES();
	RegisterUSP();
	RegisterSAWEDOFF();

	const string szEntFile = "io_weps/io.ent";

	if ( !g_EntityLoader.LoadFromFile( szEntFile ) )
		g_EngineFuncs.ServerPrint( "Can't open " + szEntFile + "\n" );	
}

void MapActivate()
{
	CBaseEntity@ pEntity = null;

	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "multi_manager" ) ) !is null )
	{
		if ( pEntity.GetTargetname().CompareN( "secret_", 7 ) != 0 )
			continue;
		
		if ( !pEntity.HasTarget( "secretcounter" ) )
			continue;

		if ( !pEntity.HasTarget( "secret_text" ) )
			g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "secret_text_delay", "0.1" );
		
		g_iSecretTotal++;
	}
	
	g_EngineFuncs.ServerPrint( "IO g_iSecretTotal: " + g_iSecretTotal + "\n" );

	while ( ( @pEntity = g_EntityFuncs.FindEntityByTargetname( pEntity, "secret_text" ) ) !is null )
	{
		if ( pEntity.GetClassname() != "game_text" )
			continue;
		
		pEntity.pev.targetname = string_t( "secret_text_delay" );
		pEntity.pev.spawnflags |= 1;

		g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "y", "0.65" );
		g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "channel", "1" );
	}

	// end button
	@pEntity = g_EntityFuncs.FindEntityByTargetname( null, "surg_button" );
	if ( pEntity !is null )
	{
		pEntity.pev.target = string_t( "start_exit_vote" );
		
		CBaseButton@ pButton = cast<CBaseButton@>( pEntity );
		
		if ( pButton !is null )
		{
			pButton.m_flWait = 16;
			pButton.m_fStayPushed = false;
		}
	}

	// breakable
	@pEntity = g_EntityFuncs.FindEntityByTargetname( null, "secret_avpware_door" );
	if ( pEntity !is null )
		pEntity.pev.spawnflags |= 1;
	
	// fix for secret_counter
	@pEntity = g_EntityFuncs.FindEntityByTargetname( null, "secret_starthallcrate_cc" );
	if ( pEntity !is null )
		pEntity.pev.targetname = string_t( "secret_startwarecrate_cc" );
}

void SecretCounter( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
{
	g_iSecretFound++;

	CBaseEntity@ pEntity = g_EntityFuncs.FindEntityByTargetname( null, "secret_text_delay" );
	if ( pEntity !is null )
		pEntity.pev.message = string_t( string( g_iSecretFound ) + "/" + g_iSecretTotal + " a secret areas found!\n" );

	@pEntity = g_EntityFuncs.FindEntityByTargetname( null, "start_exit_vote" );
	if ( pEntity !is null )
		pEntity.pev.message = string_t( "You missed some secret areas. Found " + g_iSecretFound + " of " + g_iSecretTotal + "\nWould you like exit this map?" );

	if ( g_iSecretTotal != g_iSecretFound )
		return;

	@pEntity = g_EntityFuncs.FindEntityByTargetname( null, "surg_button" );
	if ( pEntity !is null )
		pEntity.pev.target = string_t( "end_m" );
}
