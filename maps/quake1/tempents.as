void q1_TE_LavaSplash( Vector pos, NetworkMessageDest msgType = MSG_BROADCAST, edict_t@ dest = null )
{
	NetworkMessage m( msgType, NetworkMessages::SVC_TEMPENTITY, dest );
	m.WriteByte( TE_LAVASPLASH );
	m.WriteCoord( pos.x );
	m.WriteCoord( pos.y );
	m.WriteCoord( pos.z );
	m.End();
}

void q1_TE_ParticleBurst( Vector pos, uint16 radius = 4, uint8 color = 7, uint8 life = 3, 
							NetworkMessageDest msgType = MSG_BROADCAST, edict_t@ dest = null )
{
	NetworkMessage m( msgType, NetworkMessages::SVC_TEMPENTITY, dest );
	m.WriteByte( TE_PARTICLEBURST );
	m.WriteCoord( pos.x );
	m.WriteCoord( pos.y );
	m.WriteCoord( pos.z );
	m.WriteShort( radius );
	m.WriteByte( color );
	m.WriteByte( life );
	m.End();
}

void q1_TE_BloodStream( Vector pos, Vector dir, uint8 color = 55, uint8 speed = 64,
						NetworkMessageDest msgType = MSG_BROADCAST, edict_t@ dest = null )
{
	NetworkMessage m( msgType, NetworkMessages::SVC_TEMPENTITY, dest );
	m.WriteByte( TE_BLOODSTREAM );
	m.WriteCoord( pos.x );
	m.WriteCoord( pos.y );
	m.WriteCoord( pos.z );
	m.WriteCoord( dir.x );
	m.WriteCoord( dir.y );
	m.WriteCoord( dir.z );
	m.WriteByte( color );
	m.WriteByte( speed );
	m.End();
}

void q1_TE_BeamPoints( Vector start, Vector end,
						uint8 frameStart = 0, uint8 frameRate = 100, uint8 life = 3,
						uint8 width = 32, uint8 noise = 25, uint8 r = 255, uint8 g = 255, uint8 b = 255,
						uint8 brightness = 255, uint8 scroll = 100, string sprite = "sprites/laserbeam.spr",
						NetworkMessageDest msgType = MSG_BROADCAST, edict_t@ dest = null )
{
	NetworkMessage m( msgType, NetworkMessages::SVC_TEMPENTITY, dest );
	m.WriteByte( TE_BEAMPOINTS );
	m.WriteCoord( start.x );
	m.WriteCoord( start.y );
	m.WriteCoord( start.z );
	m.WriteCoord( end.x );
	m.WriteCoord( end.y );
	m.WriteCoord( end.z );
	m.WriteShort( g_EngineFuncs.ModelIndex( sprite ) );
	m.WriteByte( frameStart );
	m.WriteByte( frameRate );
	m.WriteByte( life );
	m.WriteByte( width );
	m.WriteByte( noise );
	m.WriteByte( r );
	m.WriteByte( g );
	m.WriteByte( b );
	m.WriteByte( brightness );
	m.WriteByte( scroll );
	m.End();
}
