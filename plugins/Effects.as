
class Color
{ 
	uint8 r, g, b, a;
	Color() { r = g = b = a = 0; }
	Color(uint8 r, uint8 g, uint8 b) { this.r = r; this.g = g; this.b = b; this.a = 255; }
	Color(uint8 r, uint8 g, uint8 b, uint8 a) { this.r = r; this.g = g; this.b = b; this.a = a; }
	Color (Vector v) { this.r = int(v.x); this.g = int(v.y); this.b = int(v.z); this.a = 255; }
	string ToString() { return "" + r + " " + g + " " + b + " " + a; }
}
Color RED    = Color(255,0,0);
Color GREEN  = Color(0,255,0);
Color BLUE   = Color(0,0,255);
Color YELLOW = Color(255,255,0);
Color ORANGE = Color(255,127,0);
Color PURPLE = Color(127,0,255);
Color PINK   = Color(255,0,127);
Color TEAL   = Color(0,255,255);
Color WHITE  = Color(255,255,255);
Color BLACK  = Color(0,0,0);
Color GRAY  = Color(127,127,127);

void print(string text) { g_Game.AlertMessage( at_console, text); }
void println(string text) { print(text + "\n"); }


void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "w00tguy" );
	g_Module.ScriptInfo.SetContactInfo( "w00tguy123 - forums.svencoop.com" );
	
	g_Hooks.RegisterHook( Hooks::Player::ClientSay, @ClientSay );
}

// Beam effect between two points
void te_beampoints(Vector start, Vector end, 
	string sprite="sprites/laserbeam.spr", uint8 frameStart=0, 
	uint8 frameRate=100, uint8 life=0, uint8 width=1, uint8 noise=2, 
	Color c=GREEN, uint8 scroll=32,
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
	m.WriteByte(TE_BEAMPOINTS);
	m.WriteCoord(start.x);
	m.WriteCoord(start.y);
	m.WriteCoord(start.z);
	m.WriteCoord(end.x);
	m.WriteCoord(end.y);
	m.WriteCoord(end.z);
	m.WriteShort(g_EngineFuncs.ModelIndex(sprite));
	m.WriteByte(frameStart);
	m.WriteByte(frameRate);
	m.WriteByte(life);
	m.WriteByte(width);
	m.WriteByte(noise);
	m.WriteByte(c.r);
	m.WriteByte(c.g);
	m.WriteByte(c.b);
	m.WriteByte(c.a); // actually brightness
	m.WriteByte(scroll);
	m.End();
}

// Beam effect between point and entity
void te_beamentpoint(CBaseEntity@ target, Vector end, 
	string sprite="sprites/laserbeam.spr", int frameStart=0, 
	int frameRate=100, int life=255, int width=32, int noise=1, 
	Color c=PURPLE, int scroll=32,
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
	m.WriteByte(TE_BEAMENTPOINT);
	m.WriteShort(target.entindex());
	m.WriteCoord(end.x);
	m.WriteCoord(end.y);
	m.WriteCoord(end.z);
	m.WriteShort(g_EngineFuncs.ModelIndex(sprite));
	m.WriteByte(frameStart);
	m.WriteByte(frameRate);
	m.WriteByte(life);
	m.WriteByte(width);
	m.WriteByte(noise);
	m.WriteByte(c.r);
	m.WriteByte(c.g);
	m.WriteByte(c.b);
	m.WriteByte(c.a); // actually brightness
	m.WriteByte(scroll);
	m.End();
}

// Beam effect between two entities
void te_beaments(CBaseEntity@ start, CBaseEntity@ end, 
	string sprite="sprites/laserbeam.spr", int frameStart=0, 
	int frameRate=100, int life=255, int width=32, int noise=1, 
	Color c=PURPLE, int scroll=32,
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
	m.WriteByte(TE_BEAMENTS);
	m.WriteShort(start.entindex());
	m.WriteShort(end.entindex());
	m.WriteShort(g_EngineFuncs.ModelIndex(sprite));
	m.WriteByte(frameStart);
	m.WriteByte(frameRate);
	m.WriteByte(life);
	m.WriteByte(width);
	m.WriteByte(noise);
	m.WriteByte(c.r);
	m.WriteByte(c.g);
	m.WriteByte(c.b);
	m.WriteByte(c.a); // actually brightness
	m.WriteByte(scroll);
	m.End();
}

// A simpler version of te_beampoints
void te_lightning(Vector start, Vector end, 
	string sprite="sprites/laserbeam.spr", int life=20, int width=32, 
	int noise=10, 
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
	m.WriteByte(TE_LIGHTNING);
	m.WriteCoord(start.x);
	m.WriteCoord(start.y);
	m.WriteCoord(start.z);
	m.WriteCoord(end.x);
	m.WriteCoord(end.y);
	m.WriteCoord(end.z);
	m.WriteByte(life);
	m.WriteByte(width);
	m.WriteByte(noise);
	m.WriteShort(g_EngineFuncs.ModelIndex(sprite));
	m.End();
}

// Useless effect? No way to make it last longer than 1 frame it seems.
void te_beamsprite(Vector start, Vector end,
	string beamSprite="sprites/laserbeam.spr", string endSprite="sprites/glow01.spr",
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
	m.WriteByte(TE_BEAMSPRITE);
	m.WriteCoord(start.x);
	m.WriteCoord(start.y);
	m.WriteCoord(start.z);
	m.WriteCoord(end.x);
	m.WriteCoord(end.y);
	m.WriteCoord(end.z);
	m.WriteShort(g_EngineFuncs.ModelIndex(beamSprite));
	m.WriteShort(g_EngineFuncs.ModelIndex(endSprite));
	m.End();
}

void _te_beamcircle(Vector pos, float velocity, string sprite, uint8 startFrame, uint8 frameRate, uint8 life, 
				  uint8 width, uint8 noise, Color c, uint8 scrollSpeed, NetworkMessageDest msgType, 
				  edict_t@ dest, int beamType)
{
	NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
	m.WriteByte(beamType);
	m.WriteCoord(pos.x);
	m.WriteCoord(pos.y);
	m.WriteCoord(pos.z);
	m.WriteCoord(pos.x);
	m.WriteCoord(pos.y);
	m.WriteCoord(pos.z + velocity);
	m.WriteShort(g_EngineFuncs.ModelIndex(sprite));
	m.WriteByte(startFrame);
	m.WriteByte(frameRate);
	m.WriteByte(life);
	m.WriteByte(width);
	m.WriteByte(noise);
	m.WriteByte(c.r);
	m.WriteByte(c.g);
	m.WriteByte(c.b);
	m.WriteByte(c.a);
	m.WriteByte(scrollSpeed);
	m.End();
}


// Like torus but with a filled center
void te_beamdisk(Vector pos, float velocity, 
	string sprite="sprites/laserbeam.spr", uint8 startFrame=0, 
	uint8 frameRate=16, uint8 life=8, 
	Color c=PURPLE, uint8 scrollSpeed=10, 
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	// width has no effect.
	_te_beamcircle(pos, velocity, sprite, startFrame, frameRate, life, 1, 0, c, 
				 scrollSpeed, msgType, dest, TE_BEAMDISK);
}

// Like torus but without the weird sprite rotation
void te_beamcylinder(Vector pos, float velocity, string sprite="sprites/laserbeam.spr", uint8 startFrame=0, 
					uint8 frameRate=16, uint8 life=8, uint8 width=8, uint8 noise=0, Color c=PURPLE, 
					uint8 scrollSpeed=0, NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	_te_beamcircle(pos, velocity, sprite, startFrame, frameRate, life, width, noise, c, 
				 scrollSpeed, msgType, dest, TE_BEAMCYLINDER);
}

// Creates a flat expanding circle. There seems to be no way to change the axis
void te_beamtorus(Vector pos, float velocity, 
	string sprite="sprites/laserbeam.spr", uint8 startFrame=0, 
	uint8 frameRate=16, uint8 life=8, uint8 width=8, uint8 noise=0,
	Color c=PURPLE, uint8 scrollSpeed=0, 
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	_te_beamcircle(pos, velocity, sprite, startFrame, frameRate, life, width, noise, c, 
				 scrollSpeed, msgType, dest, TE_BEAMTORUS);
}

// Draws a beam ring between two entities
void te_beamring(CBaseEntity@ start, CBaseEntity@ end, 
	string sprite="sprites/laserbeam.spr", uint8 startFrame=0, 
	uint8 frameRate=16, uint8 life=255, uint8 width=16, uint8 noise=0, 
	Color c=PURPLE, uint8 scrollSpeed=0, 
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
	m.WriteByte(TE_BEAMRING);
	m.WriteShort(start.entindex());
	m.WriteShort(end.entindex());
	m.WriteShort(g_EngineFuncs.ModelIndex(sprite));
	m.WriteByte(startFrame);
	m.WriteByte(frameRate);
	m.WriteByte(life);
	m.WriteByte(width);
	m.WriteByte(noise);
	m.WriteByte(c.r);
	m.WriteByte(c.g);
	m.WriteByte(c.b);
	m.WriteByte(c.a);
	m.WriteByte(scrollSpeed);
	m.End();
}


// ricochet sound with weird particle effect
void te_gunshot(Vector pos, 
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	_te_pointeffect(pos, msgType, dest, TE_GUNSHOT);
}


// You've seen it a million times. Possible flags:
// 1 = Sprite will be drawn opaque
// 2 = Do not render the dynamic lights
// 4 = Do not play the explosion sound
// 8 = Do not draw the particles
void te_explosion(Vector pos, string sprite="sprites/zerogxplode.spr", 
	int scale=10, int frameRate=15, int flags=0,
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
	m.WriteByte(TE_EXPLOSION);
	m.WriteCoord(pos.x);
	m.WriteCoord(pos.y);
	m.WriteCoord(pos.z);
	m.WriteShort(g_EngineFuncs.ModelIndex(sprite));
	m.WriteByte(scale);
	m.WriteByte(frameRate);
	m.WriteByte(flags);
	m.End();
}

// Quake particle effect. Looks like confetti or dust. Would be nice if it didn't play the explosion sound.
void te_tarexplosion(Vector pos, NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	_te_pointeffect(pos, msgType, dest, TE_TAREXPLOSION);
}

// Alphablend sprite rising at 30 pps
void te_smoke(Vector pos, string sprite="sprites/steam1.spr", 
	int scale=10, int frameRate=15,
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
	m.WriteByte(TE_SMOKE);
	m.WriteCoord(pos.x);
	m.WriteCoord(pos.y);
	m.WriteCoord(pos.z);
	m.WriteShort(g_EngineFuncs.ModelIndex(sprite));
	m.WriteByte(scale);
	m.WriteByte(frameRate);
	m.End();
}

// Bullet tracer effect. Its speed is constant.
void te_tracer(Vector start, Vector end, 
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
	m.WriteByte(TE_TRACER);
	m.WriteCoord(start.x);
	m.WriteCoord(start.y);
	m.WriteCoord(start.z);
	m.WriteCoord(end.x);
	m.WriteCoord(end.y);
	m.WriteCoord(end.z);
	m.End();
}

void _te_pointeffect(Vector pos, NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null, int effect=TE_SPARKS)
{
	NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
	m.WriteByte(effect);
	m.WriteCoord(pos.x);
	m.WriteCoord(pos.y);
	m.WriteCoord(pos.z);
	m.End();
}

// Sound effects sold separately
void te_sparks(Vector pos, 
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	_te_pointeffect(pos, msgType, dest, TE_SPARKS);
}

// Another weird quake particle effect. Apparently red dots == lava
void te_lavasplash(Vector pos, NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	_te_pointeffect(pos, msgType, dest, TE_LAVASPLASH);
}

// Quake particle effect. This one is pretty cool.
void te_teleport(Vector pos, NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	_te_pointeffect(pos, msgType, dest, TE_TELEPORT);
}

// A faster version of te_tarexplosion. Also spawns a dlight. Color args do literally nothing?
void te_explosion2(Vector pos, 
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
	m.WriteByte(TE_EXPLOSION2);
	m.WriteCoord(pos.x);
	m.WriteCoord(pos.y);
	m.WriteCoord(pos.z);
	m.WriteByte(0); // "start color" - has no effect
	m.WriteByte(127); // "number of colors" - has no effect
	m.End();
}

void _te_decal(Vector pos, CBaseEntity@ plr, CBaseEntity@ brushEnt, string decal, 
			   NetworkMessageDest msgType, edict_t@ dest, int decalType)
{
	int decalIdx = g_EngineFuncs.DecalIndex(decal);
	int entIdx = brushEnt is null ? 0 : brushEnt.entindex();
	
	// validate inputs
	if (decalIdx == -1)
	{
		if (plr !is null)
			decalIdx = 0;
		else
		{
			println("Invalid decal: " + decalIdx);
			return;
		}
	}
	if (decalIdx > 511)
	{
		println("Decal index too high (" + decalIdx + ")! Max decal index is 511.");
		return;
	}
	if (decalIdx > 255)
	{
		decalIdx -= 255;
		if (decalType == TE_DECAL) decalType = TE_DECALHIGH;
		else if (decalType == TE_WORLDDECAL) decalType = TE_WORLDDECALHIGH;
		else println("Decal type " + decalType + " doesn't support indicies > 255");
	}
	
	// save a little bandwidth if possible
	if (decalType == TE_DECAL and entIdx == 0) decalType = TE_WORLDDECAL;
	if (decalType == TE_DECALHIGH and entIdx == 0) decalType = TE_WORLDDECALHIGH; 
	
	// create the message
	NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
	m.WriteByte(decalType);
	if (plr !is null) 
		m.WriteByte(plr.entindex());
	m.WriteCoord(pos.x);
	m.WriteCoord(pos.y);
	m.WriteCoord(pos.z);
	switch(decalType)
	{
		case TE_DECAL: case TE_DECALHIGH:
			m.WriteByte(decalIdx);
			m.WriteShort(entIdx);
			break;
		case TE_GUNSHOTDECAL: case TE_PLAYERDECAL:
			m.WriteShort(entIdx);
			m.WriteByte(decalIdx);
			break;
		default:
			m.WriteByte(decalIdx);
	}
	m.End();
}

// Creates a decal if the specified point is close enough to a world or brush surface
void te_decal(Vector pos, CBaseEntity@ brushEnt=null, string decal="{handi",
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	_te_decal(pos, null, brushEnt, decal, msgType, dest, TE_DECAL);
}

// Decal from the .BSP file. (...how do you put a decal there?)
void te_bspdecal(Vector pos, string decal="{a_bsp_decal", NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	_te_decal(pos, null, null, decal, msgType, dest, TE_BSPDECAL);
}

// Applies a decal if the position is close enough to a surface.
// Also creates a bullet spark/particle effect and sometimes a sound.
void te_gunshotdecal(Vector pos, CBaseEntity@ brushEnt=null, string decal="{handi",
			  NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	_te_decal(pos, null, brushEnt, decal, msgType, dest, TE_GUNSHOTDECAL);
}

// Applies the target player's spray if the position is close enough to a surface
void te_playerdecal(Vector pos, CBaseEntity@ plr, CBaseEntity@ brushEnt=null,
			  NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	_te_decal(pos, plr, brushEnt, 0, msgType, dest, TE_PLAYERDECAL);
}

// Tracers moving toward a point
void te_implosion(Vector pos, uint8 radius=255, uint8 count=32, uint8 life=5,
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
	m.WriteByte(TE_IMPLOSION);
	m.WriteCoord(pos.x);
	m.WriteCoord(pos.y);
	m.WriteCoord(pos.z);
	m.WriteByte(radius);
	m.WriteByte(count);
	m.WriteByte(life);
	m.End();
}

// Line of glow sprites with gravity, fadeout, and collisions. Lots of possibilities with this one
void te_spritetrail(Vector start, Vector end, 
	string sprite="sprites/hotglow.spr", uint8 count=2, uint8 life=0, 
	uint8 scale=1, uint8 speed=16, uint8 speedNoise=8,
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
	m.WriteByte(TE_SPRITETRAIL);
	m.WriteCoord(start.x);
	m.WriteCoord(start.y);
	m.WriteCoord(start.z);
	m.WriteCoord(end.x);
	m.WriteCoord(end.y);
	m.WriteCoord(end.z);
	m.WriteShort(g_EngineFuncs.ModelIndex(sprite));
	m.WriteByte(count);
	m.WriteByte(life);
	m.WriteByte(scale);
	m.WriteByte(speedNoise);
	m.WriteByte(speed);
	m.End();
}

// Line of alpha sprites floating upwards (shooting underwater effect)
void te_bubbletrail(Vector start, Vector end, 
	string sprite="sprites/bubble.spr", float height=128.0f,
	uint8 count=16, float speed=16.0f, 
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
	m.WriteByte(TE_BUBBLETRAIL);
	m.WriteCoord(start.x);
	m.WriteCoord(start.y);
	m.WriteCoord(start.z);
	m.WriteCoord(end.x);
	m.WriteCoord(end.y);
	m.WriteCoord(end.z);
	m.WriteCoord(height);
	m.WriteShort(g_EngineFuncs.ModelIndex(sprite));
	m.WriteByte(count);
	m.WriteCoord(speed);
	m.End();
}

// Plays additive sprite once.
void te_sprite(Vector pos, string sprite="sprites/zerogxplode.spr", 
	uint8 scale=10, uint8 alpha=200, 
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
	m.WriteByte(TE_SPRITE);
	m.WriteCoord(pos.x);
	m.WriteCoord(pos.y);
	m.WriteCoord(pos.z);
	m.WriteShort(g_EngineFuncs.ModelIndex(sprite));
	m.WriteByte(scale);
	m.WriteByte(alpha);
	m.End();
}

// Places an additive sprite that fades out
void te_glowsprite(Vector pos, string sprite="sprites/glow01.spr", 
	uint8 life=1, uint8 scale=10, uint8 alpha=255, 
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
	m.WriteByte(TE_GLOWSPRITE);
	m.WriteCoord(pos.x);
	m.WriteCoord(pos.y);
	m.WriteCoord(pos.z);
	m.WriteShort(g_EngineFuncs.ModelIndex(sprite));
	m.WriteByte(life);
	m.WriteByte(scale);
	m.WriteByte(alpha);
	m.End();
}


// Will kill itself if target stays still for too long
void te_trail(CBaseEntity@ target, string sprite="sprites/laserbeam.spr", 
	uint8 life=100, uint8 width=2, Color c=PURPLE,
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
	m.WriteByte(TE_BEAMFOLLOW);
	m.WriteShort(target.entindex());
	m.WriteShort(g_EngineFuncs.ModelIndex(sprite));
	m.WriteByte(life);
	m.WriteByte(width);
	m.WriteByte(c.r);
	m.WriteByte(c.g);
	m.WriteByte(c.b);
	m.WriteByte(c.a);
	m.End();
}

// Shoot group of tracers in some direction. These have a slight gravity effect
void te_streaksplash(Vector start, Vector dir, uint8 color=250, 
	uint16 count=256, uint16 speed=2048, uint16 speedNoise=128, 
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
	m.WriteByte(TE_STREAK_SPLASH);
	m.WriteCoord(start.x);
	m.WriteCoord(start.y);
	m.WriteCoord(start.z);
	m.WriteCoord(dir.x);
	m.WriteCoord(dir.y);
	m.WriteCoord(dir.z);
	m.WriteByte(color);
	m.WriteShort(count);
	m.WriteShort(speed);
	m.WriteShort(speedNoise);
	m.End();
}

// Dynamic light.
void te_dlight(Vector pos, uint8 radius=14, Color c=GREEN, 
	uint8 life=8, uint16 decayRate=4,
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
	m.WriteByte(TE_DLIGHT);
	m.WriteCoord(pos.x);
	m.WriteCoord(pos.y);
	m.WriteCoord(pos.z);
	m.WriteByte(radius);
	m.WriteByte(c.r);
	m.WriteByte(c.g);
	m.WriteByte(c.b);
	m.WriteByte(life);
	m.WriteByte(decayRate);
	m.End();
}

// Dynamic light that only affects point entities. Seems pretty useless.
// It does a pretty crappy job of lighting my model if that's what it's supposed to do.
void te_elight(CBaseEntity@ target, Vector pos, float radius=1024.0f, 
	Color c=PURPLE, uint8 life=16, float decayRate=2000.0f, 
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
	m.WriteByte(TE_ELIGHT);
	m.WriteShort(target.entindex());
	m.WriteCoord(pos.x);
	m.WriteCoord(pos.y);
	m.WriteCoord(pos.z);
	m.WriteCoord(radius);
	m.WriteByte(c.r);
	m.WriteByte(c.g);
	m.WriteByte(c.b);
	m.WriteByte(life);
	m.WriteCoord(decayRate);
	m.End();
}

// Draws a dotted line. Uses tons of TE slots, so just use beams inastead.
void te_line(Vector start, Vector end, uint16 life=32, Color c=PURPLE,
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
	m.WriteByte(TE_LINE);
	m.WriteCoord(start.x);
	m.WriteCoord(start.y);
	m.WriteCoord(start.z);
	m.WriteCoord(end.x);
	m.WriteCoord(end.y);
	m.WriteCoord(end.z);
	m.WriteShort(life);
	m.WriteByte(c.r);
	m.WriteByte(c.g);
	m.WriteByte(c.b);
	m.End();
}

// Draws a red dotted line. Dies in 30 seconds
void te_showline(Vector start, Vector end, Color c=PURPLE,
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
	m.WriteByte(TE_SHOWLINE);
	m.WriteCoord(start.x);
	m.WriteCoord(start.y);
	m.WriteCoord(start.z);
	m.WriteCoord(end.x);
	m.WriteCoord(end.y);
	m.WriteCoord(end.z);
	m.End();
}

// Draws a axis-aligned box made up of dotted lines.
void te_box(Vector mins, Vector maxs, uint16 life=16, Color c=PURPLE,
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
	m.WriteByte(TE_BOX);
	m.WriteCoord(mins.x);
	m.WriteCoord(mins.y);
	m.WriteCoord(mins.z);
	m.WriteCoord(maxs.x);
	m.WriteCoord(maxs.y);
	m.WriteCoord(maxs.z);
	m.WriteShort(life);
	m.WriteByte(c.r);
	m.WriteByte(c.g);
	m.WriteByte(c.b);
	m.End();
}

// Kill all beams originating from the target entity
void te_killbeam(CBaseEntity@ target, 
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
	m.WriteByte(TE_KILLBEAM);
	m.WriteShort(target.entindex());
	m.End();
}

// Same thing as env_funnel. Set flags to 1 for reverse funnel
void te_largefunnel(Vector pos, string sprite="sprites/glow01.spr", 
	uint16 flags=0,
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
	m.WriteByte(TE_LARGEFUNNEL);
	m.WriteCoord(pos.x);
	m.WriteCoord(pos.y);
	m.WriteCoord(pos.z);
	m.WriteShort(g_EngineFuncs.ModelIndex(sprite));
	m.WriteShort(flags);
	m.End();
}

// Quake-style blood stream
void te_bloodstream(Vector pos, Vector dir, uint8 color=70, uint8 speed=64,
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
	m.WriteByte(TE_BLOODSTREAM);
	m.WriteCoord(pos.x);
	m.WriteCoord(pos.y);
	m.WriteCoord(pos.z);
	m.WriteCoord(dir.x);
	m.WriteCoord(dir.y);
	m.WriteCoord(dir.z);
	m.WriteByte(color);
	m.WriteByte(speed);
	m.End();
}

// Another Quake-style blood stream
void te_blood(Vector pos, Vector dir, uint8 color=70, uint8 speed=16,
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
	m.WriteByte(TE_BLOOD);
	m.WriteCoord(pos.x);
	m.WriteCoord(pos.y);
	m.WriteCoord(pos.z);
	m.WriteCoord(dir.x);
	m.WriteCoord(dir.y);
	m.WriteCoord(dir.z);
	m.WriteByte(color);
	m.WriteByte(speed);
	m.End();
}

// Creates alpha-transparency sprites inside of a brush entity (can't be world)
void te_fizz(CBaseEntity@ brushEnt, 
	string sprite="sprites/bubble.spr", uint8 density=100,
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
	m.WriteByte(TE_FIZZ);
	m.WriteShort(brushEnt.entindex());
	m.WriteShort(g_EngineFuncs.ModelIndex(sprite));
	m.WriteByte(density);
	m.End();
}

// Creates alpha-transparency sprites inside of a box
void te_bubbles(Vector mins, Vector maxs, float height=256.0f, 
	string sprite="sprites/bubble.spr", uint8 count=64, float speed=16.0f,
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
	m.WriteByte(TE_BUBBLES);
	m.WriteCoord(mins.x);
	m.WriteCoord(mins.y);
	m.WriteCoord(mins.z);
	m.WriteCoord(maxs.x);
	m.WriteCoord(maxs.y);
	m.WriteCoord(maxs.z);
	m.WriteCoord(height);
	m.WriteShort(g_EngineFuncs.ModelIndex(sprite));
	m.WriteByte(count);
	m.WriteCoord(speed);
	m.End();
}

// Throw model with gravity and collisions.
void te_model(Vector pos, Vector velocity, float yaw=0, 
	string model="models/agibs.mdl", uint8 bounceSound=2, uint8 life=32,
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
	m.WriteByte(TE_MODEL);
	m.WriteCoord(pos.x);
	m.WriteCoord(pos.y);
	m.WriteCoord(pos.z);
	m.WriteCoord(velocity.x);
	m.WriteCoord(velocity.y);
	m.WriteCoord(velocity.z);
	m.WriteAngle(yaw);
	m.WriteShort(g_EngineFuncs.ModelIndex(model));
	m.WriteByte(bounceSound);
	m.WriteByte(life);
	m.End();
}

// Quake-style model explosion. Dynamic light created for each gib
void te_explodemodel(Vector pos, float velocity, 
	string model="models/hgibs.mdl", uint16 count=8, uint8 life=32,
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
	m.WriteByte(TE_EXPLODEMODEL);
	m.WriteCoord(pos.x);
	m.WriteCoord(pos.y);
	m.WriteCoord(pos.z);
	m.WriteCoord(velocity);
	m.WriteShort(g_EngineFuncs.ModelIndex(model));
	m.WriteShort(count);
	m.WriteByte(life);
	m.End();
}

// func_breakable effect without sounds. Flags:
// 1 : Glass sounds and models 50% opacity
// 2 : Metal sounds.
// 4 : Flesh sounds.
// 8 : Wood sounds
// 16 : Quake particle trail on some gibs (combinable)
// 32: 50% opacity (combinable)
// 64 : Rock sounds.
void te_breakmodel(Vector pos, Vector size, Vector velocity, 
	uint8 speedNoise=16, string model="models/hgibs.mdl", 
	uint8 count=8, uint8 life=0, uint8 flags=20,
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
	m.WriteByte(TE_BREAKMODEL);
	m.WriteCoord(pos.x);
	m.WriteCoord(pos.y);
	m.WriteCoord(pos.z);
	m.WriteCoord(size.x);
	m.WriteCoord(size.y);
	m.WriteCoord(size.z);
	m.WriteCoord(velocity.x);
	m.WriteCoord(velocity.y);
	m.WriteCoord(velocity.z);
	m.WriteByte(speedNoise);
	m.WriteShort(g_EngineFuncs.ModelIndex(model));
	m.WriteByte(count);
	m.WriteByte(life);
	m.WriteByte(flags);
	m.End();
}

// Spray fading alpha sprites in some direction (bullsquid spit effect)
void te_spritespray(Vector pos, Vector velocity, 
	string sprite="sprites/bubble.spr", uint8 count=8, 
	uint8 speed=16, uint8 noise=255,
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
	m.WriteByte(TE_SPRITE_SPRAY);
	m.WriteCoord(pos.x);
	m.WriteCoord(pos.y);
	m.WriteCoord(pos.z);
	m.WriteCoord(velocity.x);
	m.WriteCoord(velocity.y);
	m.WriteCoord(velocity.z);
	m.WriteShort(g_EngineFuncs.ModelIndex(sprite));
	m.WriteByte(count);
	m.WriteByte(speed);
	m.WriteByte(noise);
	m.End();
}

// Like spritespray but with a custom rendermode and no fading
// Rendermodes:
// 0 : Normal
// 1 : Color
// 2 : Texture
// 3 : Glow
// 4 : Solid
// 5 : Additive
void te_spray(Vector pos, Vector dir, string sprite="models/hgibs.mdl", 
	uint8 count=8, uint8 speed=127, uint8 noise=255, uint8 rendermode=9,
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
	m.WriteByte(TE_SPRAY);
	m.WriteCoord(pos.x);
	m.WriteCoord(pos.y);
	m.WriteCoord(pos.z);
	m.WriteCoord(dir.x);
	m.WriteCoord(dir.y);
	m.WriteCoord(dir.z);
	m.WriteShort(g_EngineFuncs.ModelIndex(sprite));
	m.WriteByte(count);
	m.WriteByte(speed);
	m.WriteByte(noise);
	m.WriteByte(rendermode);
	m.End();
}

// Armor ricochet effect
void te_ricochet(Vector pos, uint8 scale=10, 
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
	m.WriteByte(TE_ARMOR_RICOCHET);
	m.WriteCoord(pos.x);
	m.WriteCoord(pos.y);
	m.WriteCoord(pos.z);
	m.WriteByte(scale);
	m.End();
}

// Bullet hitting monster effect
void te_bloodsprite(Vector pos, string sprite1="sprites/bloodspray.spr",
	string sprite2="sprites/blood.spr", uint8 color=70, uint8 scale=3,
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
	m.WriteByte(TE_BLOODSPRITE);
	m.WriteCoord(pos.x);
	m.WriteCoord(pos.y);
	m.WriteCoord(pos.z);
	m.WriteShort(g_EngineFuncs.ModelIndex(sprite1));
	m.WriteShort(g_EngineFuncs.ModelIndex(sprite2));
	m.WriteByte(color);
	m.WriteByte(scale);
	m.End();
}

// Projectile with no gravity, explosion, or sound.
void te_projectile(Vector pos, Vector velocity, CBaseEntity@ owner=null, 
	string model="models/grenade.mdl", uint8 life=255, 
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	int ownerId = (owner is null) ? 0 : owner.entindex();
	NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
	m.WriteByte(TE_PROJECTILE);
	m.WriteCoord(pos.x);
	m.WriteCoord(pos.y);
	m.WriteCoord(pos.z);
	m.WriteCoord(velocity.x);
	m.WriteCoord(velocity.y);
	m.WriteCoord(velocity.z);
	m.WriteShort(g_EngineFuncs.ModelIndex(model));
	m.WriteByte(life);
	m.WriteByte(ownerId);
	m.End();
}


// Surround player with sprites with 1 falling off (looks like getting attacked by bubbles)
void te_playersprites(CBasePlayer@ target, 
	string sprite="sprites/bubble.spr", uint8 count=16,
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
	m.WriteByte(TE_PLAYERSPRITES);
	m.WriteShort(target.entindex());
	m.WriteShort(g_EngineFuncs.ModelIndex(sprite));
	m.WriteByte(count);
	m.WriteByte(0); // "size variation" - has no effect
	m.End();
}

// Quake-style particle explosion
void te_particlebust(Vector pos, uint16 radius=128, 
	uint8 color=250, uint8 life=5,
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
	m.WriteByte(TE_PARTICLEBURST);
	m.WriteCoord(pos.x);
	m.WriteCoord(pos.y);
	m.WriteCoord(pos.z);
	m.WriteShort(radius);
	m.WriteByte(color);
	m.WriteByte(life);
	m.End();
}

// Flags:
// 1: All sprites will drift upwards
// 2: 50% of the sprites will drift upwards
// 4: Sprites loop at 15fps instead of being controlled by "life"
// 8: Show sprites at 50% opacity
// 16: Spawn sprites on flat plane instead of in cube
void te_firefield(Vector pos, uint16 radius=128, 
	string sprite="sprites/zerogxplode.spr", uint8 count=128, 
	uint8 flags=30, uint8 life=5,
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null) 
{
	NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
	m.WriteByte(TE_FIREFIELD);
	m.WriteCoord(pos.x);
	m.WriteCoord(pos.y);
	m.WriteCoord(pos.z);
	m.WriteShort(radius);
	m.WriteShort(g_EngineFuncs.ModelIndex(sprite));
	m.WriteByte(count);
	m.WriteByte(flags);
	m.WriteByte(life);
	m.End();
}

// Show sprite at vertical offset from player position ("Take Cover!" alert)
void te_playerattachment(CBasePlayer@ target, float vOffset=51.0f, 
	string sprite="sprites/bubble.spr", uint16 life=16, 
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
	m.WriteByte(TE_PLAYERATTACHMENT);
	m.WriteByte(target.entindex());
	m.WriteCoord(vOffset);
	m.WriteShort(g_EngineFuncs.ModelIndex(sprite));
	m.WriteShort(life);
	m.End();
}

// Removes player attachements created with te_playerattachment()
void te_killplayerattachments(CBasePlayer@ plr, 
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
	m.WriteByte(TE_KILLPLAYERATTACHMENTS);
	m.WriteByte(plr.entindex());
	m.End();
}

// Creates a shotgun effect on the target surface. Shows no tracers, and the effect ignores monsters.
void te_multigunshot(Vector pos, Vector dir, float spreadX=512.0f, 
	float spreadY=512.0f, uint8 count=3, string decal="{shot4",
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	int decalIdx = g_EngineFuncs.DecalIndex(decal);	
	// validate inputs
	if (decalIdx == -1)
	{
		println("Invalid decal: " + decal);
		return;
	}
	NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
	m.WriteByte(TE_MULTIGUNSHOT);
	m.WriteCoord(pos.x);
	m.WriteCoord(pos.y);
	m.WriteCoord(pos.z);
	m.WriteCoord(dir.x);
	m.WriteCoord(dir.y);
	m.WriteCoord(dir.z);
	m.WriteCoord(spreadX);
	m.WriteCoord(spreadY);
	m.WriteByte(count);
	m.WriteByte(decalIdx);
	m.End();
}

// cUsToM tracers!
void te_usertracer(Vector pos, Vector dir, float speed=6000.0f, 
	uint8 life=32, uint color=4, uint8 length=12,
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	Vector velocity = dir*speed;
	NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
	m.WriteByte(TE_USERTRACER);
	m.WriteCoord(pos.x);
	m.WriteCoord(pos.y);
	m.WriteCoord(pos.z);
	m.WriteCoord(velocity.x);
	m.WriteCoord(velocity.y);
	m.WriteCoord(velocity.z);
	m.WriteByte(life);
	m.WriteByte(color);
	m.WriteByte(length);
	m.End();
}

// Max 512 characters
// channel range = 0-3 ???
// Effects:
// 0 : fade in/out
// 1 : flickery credits
// 2 : write out characeter by character
void te_textmessage(string text, uint8 channel=1, uint16 x=4000, uint16 y=4000, uint8 effect=2,
	Color textColor=WHITE, Color effectColor=PURPLE, uint16 fadeInTime=16, 
	uint16 fadeOutTime=16, uint16 holdTime=300, uint16 scanTime=20,
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
	m.WriteByte(TE_TEXTMESSAGE);
	m.WriteByte(channel);
	m.WriteShort(x);
	m.WriteShort(y);
	m.WriteByte(effect);
	m.WriteByte(textColor.r);
	m.WriteByte(textColor.g);
	m.WriteByte(textColor.b);
	m.WriteByte(textColor.a);
	m.WriteByte(effectColor.r);
	m.WriteByte(effectColor.g);
	m.WriteByte(effectColor.b);
	m.WriteByte(effectColor.a);
	m.WriteShort(fadeInTime);
	m.WriteShort(fadeOutTime);
	m.WriteShort(holdTime);
	if (effect == 2 and scanTime > 0) 
		m.WriteShort(scanTime);
	m.WriteString(text);
	m.End();
}

// It's random. I swear.
CBaseEntity@ getRandomEnt()
{
	edict_t@ pEdict = g_EngineFuncs.PEntityOfEntIndex( 0 );
	return g_EntityFuncs.Instance( pEdict );
}

class DecalTarget
{
	Vector pos;
	CBaseEntity@ ent; // for when the target is a brush entity, not the world (0 = world)
}

// find the surface this player is aiming at
DecalTarget getDecalTarget(CBasePlayer@ plr)
{			
	TraceResult tr;
	Vector vecSrc	 = plr.pev.origin + plr.pev.view_ofs;
	Vector vecAiming = plr.GetAutoaimVector(0);
	Vector vecEnd	= vecSrc + vecAiming * 4096;

	//g_Utility.TraceLine( vecSrc, vecEnd, ignore_monsters, plr.edict(), tr );
	g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, plr.edict(), tr );
	
	DecalTarget@ decalTarget = DecalTarget();
	decalTarget.pos = tr.vecEndPos;
	
	if( tr.flFraction < 1.0 and tr.pHit !is null)
		@decalTarget.ent = g_EntityFuncs.Instance( tr.pHit );
	
	return decalTarget;
}

Vector getAimPoint(CBasePlayer@ plr, float dist)
{
	Vector vecSrc	 = plr.pev.origin + plr.pev.view_ofs;
	Vector vecAiming = plr.GetAutoaimVector(0);
	return vecSrc + vecAiming * dist;
}

Vector eyePos(CBaseEntity@ plr)
{
	return plr.pev.origin + plr.pev.view_ofs;
}

bool doEffect(CBasePlayer@ plr, const CCommand@ args)
{
	if (args[0] == '.te_test')
	{
		DecalTarget@ decalTarget = getDecalTarget(plr);
		//te_killbeam(plr);
		//te_trail(plr);
		//te_beampoints(getAimPoint(plr, 256), getAimPoint(plr, 256) + Vector(128, 0, 0));
		//te_beamentpoint(plr, getAimPoint(plr, 128));
		//te_beaments(plr, decalTarget.ent);
		//te_gunshot(getAimPoint(plr, 128));
		te_explosion(getAimPoint(plr, 128));
		//te_tarexplosion(getAimPoint(plr, 128));
		//te_explosion2(getAimPoint(plr, 128));
		//te_smoke(getAimPoint(plr, 128));
		//te_tracer(plr.pev.origin, getAimPoint(plr, 1024));
		//te_lightning(plr.pev.origin, getAimPoint(plr, 256));
		//te_beamsprite(plr.pev.origin, getAimPoint(plr, 64));
		//te_beamtorus(getAimPoint(plr, 256), 128);
		//te_beamdisk(getAimPoint(plr, 256), 128);
		//te_beamcylinder(getAimPoint(plr, 256), 128);
		//te_beamring(plr, decalTarget.ent);
		//te_sparks(getAimPoint(plr, 128));
		//te_lavasplash(getAimPoint(plr, 512));
		//te_teleport(getAimPoint(plr, 256));
		//te_decal(decalTarget.pos, decalTarget.ent);
		//te_bspdecal(decalTarget.pos, "C3A1_W3B");
		//te_gunshotdecal(decalTarget.pos, decalTarget.ent);
		//te_playerdecal(decalTarget.pos, plr, decalTarget.ent);
		//te_implosion(getAimPoint(plr, 512));
		//te_spritetrail(plr.pev.origin, plr.pev.origin + plr.GetAutoaimVector(0)*8);
		//te_bubbletrail(plr.pev.origin, decalTarget.pos);
		//te_sprite(getAimPoint(plr, 128));
		//te_glowsprite(getAimPoint(plr, 128));
		//te_streaksplash(plr.pev.origin, plr.GetAutoaimVector(0));
		//te_dlight(plr.pev.origin);
		//te_elight(plr, plr.GetAutoaimVector(0));
		//te_showline(getAimPoint(plr, 128), getAimPoint(plr, 128) + Vector(0, 80, 32));
		//te_line(getAimPoint(plr, 128), getAimPoint(plr, 128) + Vector(0, 80, 32), 64, Color(0, 0, 255));
		//te_box(getAimPoint(plr, 128), getAimPoint(plr, 128) - Vector(64, 32, 64));
		//te_largefunnel(getAimPoint(plr, 1024));
		//te_bloodstream(getAimPoint(plr, 128), Vector(0,1,1));
		//te_blood(getAimPoint(plr, 128), Vector(0,0,1));
		//if (decalTarget.ent !is null) te_fizz(decalTarget.ent);
		//te_model(plr.pev.origin - Vector(8,0,4), plr.GetAutoaimVector(0)*-256);
		//te_explodemodel(getAimPoint(plr, 512), 256);
		//te_breakmodel(eyePos(plr), Vector(0, 0, 0), plr.GetAutoaimVector(0)*512);
		//te_spritespray(eyePos(plr), plr.GetAutoaimVector(0)*8);
		//te_spray(eyePos(plr), plr.GetAutoaimVector(0)*4);
		//te_ricochet(getAimPoint(plr, 128));
		//te_bubbles(getAimPoint(plr, 256) - Vector(32, 32, 16), getAimPoint(plr, 256) + Vector(32, 32, 16), 16);
		//te_bloodsprite(getAimPoint(plr, 64));
		//te_projectile(eyePos(plr), plr.GetAutoaimVector(0)*256);
		//te_playersprites(plr);
		//te_particlebust(getAimPoint(plr, 512));
		//te_firefield(getAimPoint(plr, 256));
		//te_killplayerattachments(plr);
		//te_playerattachment(plr);
		//te_multigunshot(plr.pev.origin + plr.pev.view_ofs, plr.GetAutoaimVector(0)*256);
		//te_textmessage("LOL TEST WOW");
		//te_usertracer(eyePos(plr)-Vector(0,0,8), plr.GetAutoaimVector(0));
		
		return true;
	}
	return false;
}

HookReturnCode ClientSay( SayParameters@ pParams )
{
	CBasePlayer@ plr = pParams.GetPlayer();
	const CCommand@ args = pParams.GetArguments();
	if (plr is null)
		return HOOK_CONTINUE;
	
	if ( args.ArgC() > 0 )
	{
		if (doEffect(plr, args)) 
		{
			pParams.ShouldHide = true;
			return HOOK_HANDLED;
		}
	}
	return HOOK_CONTINUE;
}

void cheatCmd( const CCommand@ args )
{
	CBasePlayer@ plr = g_ConCommandSystem.GetCurrentPlayer();
	doEffect(plr, args);
}
