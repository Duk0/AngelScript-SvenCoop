// Poke646 Script
// po_c4m5 Anti-Troll Script
// Author: Zorbos / Anti-Troll code by w00tguy123

#include "poke646"
	
void MapStart()
{
	disableRestart();
	findTripmines();
	g_Scheduler.SetInterval( "mineThink", 0.01 );
}

// Everything below here is for fixing the tripmine level

bool g_bRespawnMode = false;

void te_explosion2(Vector pos, NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null) { NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest); m.WriteByte(TE_EXPLOSION2); m.WriteCoord(pos.x); m.WriteCoord(pos.y); m.WriteCoord(pos.z); m.WriteByte(0); m.WriteByte(127); m.End();}

array<TripmineData> g_pMines;

class TripmineData
{
	Vector pos;
	Vector angles;
	EHandle ent;
	bool respawning; // tripmine is scheduled to respawn
	
	// custom mode
	Vector dir; // look direction
	Vector endPos; // trace end position
	EHandle beam;
}

void disableRestart()
{	
	CBaseEntity@ pEntity = null;
	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "func_breakable" ) ) !is null )
	{
		if ( pEntity.pev.target == "blowup_mm" )
		{
			g_EntityFuncs.Remove( pEntity );
			break;
		}
	}
	@pEntity = g_EntityFuncs.FindEntityByTargetname( null, "blowup_mm" );
	if ( pEntity !is null )
		g_EntityFuncs.Remove( pEntity );
}

void mineRespawn( TripmineData@ data )
{
	// check to make sure mine will attach to something
	g_EngineFuncs.MakeVectors( data.angles );
	TraceResult tr;
	g_Utility.TraceLine( data.pos, data.pos - g_Engine.v_forward * 16, ignore_monsters, null, tr );
	if ( tr.flFraction >= 1.0 )
	{
		// can't spawn in air
		return;
	}
	
	CBaseEntity@ pEntity = g_EntityFuncs.Create( "monster_tripmine", data.pos, data.angles, false );
	data.ent = pEntity;
	data.respawning = false;
}

void mineThink()
{
	for ( uint i = 0; i < g_pMines.length(); i++ )
	{
		TripmineData@ data = g_pMines[i];
		if ( g_bRespawnMode )
		{
			// mine respawn mode
			if ( !data.ent && !data.respawning ) 
			{
				data.respawning = true;
				g_Scheduler.SetTimeout( "mineRespawn", 0.5, @data );
			}
		}
		else
		{
			// teleport mode
			if ( data.ent && !data.respawning )
			{
				TraceResult tr;
				g_Utility.TraceLine( data.pos, data.pos + data.dir * 4096, dont_ignore_monsters, null, tr );
				if ( ( tr.vecEndPos - data.endPos ).Length() > 0.001 )
				{
					CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
					if ( pHit !is null && pHit.IsPlayer() )
					{
						CBasePlayer@ pPlayer = cast<CBasePlayer@>( pHit );
						if ( pPlayer !is null && pPlayer.IsConnected() )
						{
							te_explosion2( pPlayer.pev.origin );
							g_PlayerFuncs.RespawnPlayer( pPlayer );
							g_PlayerFuncs.ScreenFade( pPlayer, Vector(170, 240, 220), 0.25, 0, 220, FFADE_IN );
							g_PlayerFuncs.SayText( pPlayer, "You touched a tripmine. Be more careful next time!");
							g_SoundSystem.PlaySound( pPlayer.edict(), CHAN_STATIC, "weapons/mine_activate.wav", 0.65f, 1.0f, 0, 100 );
						}
					}
					
					data.endPos = tr.vecEndPos;
					CBaseEntity@ pBeamEnt = data.beam;
					CBeam@ pBeam = cast<CBeam@>( pBeamEnt );
					pBeam.SetEndPos( data.endPos );
				}
				
				TraceResult tr2;
				g_Utility.TraceLine( data.pos, data.pos - data.dir * 16, ignore_monsters, null, tr2 );
				if ( tr2.flFraction >= 1.0 )
				{
					g_EntityFuncs.CreateExplosion( data.pos, g_vecZero, null, 150, true );
					g_EntityFuncs.Remove( data.ent );
					g_EntityFuncs.Remove( data.beam );
					data.respawning = true; // actually not but i don't want to make another flag
				}
			}
		}
	}
}

void findTripmines()
{
	CBaseEntity@ pEntity = null;
	TripmineData data;
	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "monster_tripmine" ) ) !is null )
	{
		data.pos = pEntity.pev.origin;
		data.angles = pEntity.pev.angles;
		data.respawning = false;
			
		if ( g_bRespawnMode )
			data.ent = pEntity;
		else
		{
			dictionary dKeys = {
		//	{ 'origin', pEntity.GetOrigin().ToString() },
			{ 'model', 'models/v_tripmine.mdl' } };
					
			CBaseEntity@ pMine = g_EntityFuncs.CreateEntity( "env_sprite", dKeys, true );
			if ( pMine !is null )
			{
				pMine.SetOrigin( pEntity.GetOrigin() );
				pMine.pev.angles = pEntity.pev.angles;
				pMine.pev.body = 3;
				pMine.pev.sequence = 7;
				data.ent = pMine;
					
				g_EngineFuncs.MakeVectors( pMine.pev.angles );
				data.dir = g_Engine.v_forward;
					
				TraceResult tr;
				g_Utility.TraceLine( pMine.pev.origin, pMine.pev.origin + g_Engine.v_forward * 4096, ignore_monsters, null, tr );

				CBeam@ pBeam = g_EntityFuncs.CreateBeam( "sprites/laserbeam.spr", 10 );
				if ( pBeam !is null )
				{
					pBeam.PointsInit( pMine.pev.origin, tr.vecEndPos );
					pBeam.SetColor( 0, 214, 198 );
					pBeam.SetScrollRate( 255 );
					pBeam.SetBrightness( 64 );
					data.beam = pBeam;
				}

				data.endPos = tr.vecEndPos;
				g_EntityFuncs.Remove( pEntity );
			}
		}

		g_pMines.insertLast( data );
	}
}
