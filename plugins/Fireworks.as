// Sprite Index
int g_iSprLaserdot, g_iSprFire, g_iSprWhite, g_iSprSmoke, g_iSprLightning, g_iSprBflare, g_iSprRflare, g_iSprGflare, g_iSprTflare, g_iSprOflare, g_iSprPflare, g_iSprYflare, g_iSprGarbagegibs, g_iSprFlare3, g_iSprFlare6, g_iSprShockwave;

// Has Sound Index
bool g_bHasRocket = false, g_bHasDrop = false;

array<int> g_pIntPlayerFireworks( g_Engine.maxClients + 1, 0 );
array<bool> g_pBoolAllowedFireworks( g_Engine.maxClients + 1, false );
//array<string> g_pMovableEntList = { "func_door", "func_train", "func_tracktrain", "func_trackchange", "func_plat" };

CCVar@ g_pCVarFireworksEnable, g_pCVarMaxLife, g_pCVarFlareCount, g_pCVarMaxCount, g_pCVarAdminMaxCount, g_pCVarColorType, g_pCVarMultiplier, g_pCVarXVelocity, g_pCVarYVelocity, g_pCVarPassword;

FireworksMenu g_FireworksMenu;

const float FIRE_WAIT_TIME = 5.0;

enum CheckMode
{
	MODE_USER = 0,
	MODE_ADMIN,
	MODE_UNLIMIT
}

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Twilight Suzuka|Duko" ); // ver. 2.5
	g_Module.ScriptInfo.SetContactInfo( "group.midu.cz" );
	//g_Module.ScriptInfo.SetMinimumAdminLevel( ADMIN_YES );
	
	g_Hooks.RegisterHook( Hooks::Player::ClientSay, @ClientSay );
	g_Hooks.RegisterHook( Hooks::Player::ClientPutInServer, @ClientPutInServer );
	g_Hooks.RegisterHook( Hooks::Player::ClientDisconnect, @ClientDisconnect );

	@g_pCVarFireworksEnable = CCVar( "fireworks_enable", 1, "Turns fireworks on or off" );
	@g_pCVarMaxLife = CCVar( "fireworks_maxlife", 20, "Max life (default: 20)" );
	@g_pCVarFlareCount = CCVar( "fireworks_flare_count", 30, "Flare count (default: 30)" );
	@g_pCVarMaxCount = CCVar( "fireworks_maxcount", 5, "Max count (default: 5)" );
	@g_pCVarAdminMaxCount = CCVar( "fireworks_amaxcount", 20, "Admin max count (default: 20)" );
	@g_pCVarColorType = CCVar( "fireworks_colortype", 0, "Color type (default: 0)" );
	@g_pCVarMultiplier = CCVar( "fireworks_multiplier", 2, "Multiplier (default: 2)" );

	@g_pCVarXVelocity = CCVar( "fireworks_xvelocity", 100, "X velocity (default: 100)" );
	@g_pCVarYVelocity = CCVar( "fireworks_yvelocity", 100, "Y velocity (default: 100)" );

	@g_pCVarPassword = CCVar( "fireworks_pass", "tsx", "Password" );
}


CConCommand set_lights( "set_lights", "set lights", @CmdChangeLights );

CClientCommand fireworks_menu( "fireworks_menu", "- displays fireworks menu", @CmdFireworksMenu );
CClientCommand firework( "firework", "- spawn normal rocket", @CmdSpawnFirework );
CClientCommand _firework_rc( "firework_rc", "- spawn laser guided rocket", @CmdSpawnFirework );
CClientCommand _firework_rv( "firework_rv", "- spawn remote view rocket", @CmdSpawnFirework );

CClientCommand firework_shooter( "firework_shooter", "- spawn shooter", @CmdSpawnShooter );
CClientCommand shoot_fireworks( "shoot_fireworks", "- shoot firework", @CmdShootFireworks );

CClientCommand fireworks_password( "fireworks_password", "- check password", @CmdCheckPassword );

CClientCommand _remove_fireworks( "remove_fireworks", "- remove fireworks", @CmdRemoveFireworks );
CClientCommand _remove_shooters( "remove_shooters", "- remove shooters", @CmdRemoveShooters );


void MapInit()
{
	g_Game.PrecacheModel( "models/rpgrocket.mdl" );
	g_Game.PrecacheModel( "models/w_rpgammo.mdl" );

	g_iSprGarbagegibs = g_Game.PrecacheModel( "models/garbagegibs.mdl" );
	g_iSprFlare3 = g_Game.PrecacheModel( "sprites/flare3.spr" );

	g_iSprSmoke = g_Game.PrecacheModel( "sprites/smoke.spr" );
	g_iSprFlare6 = g_Game.PrecacheModel( "sprites/flare6.spr" );
	g_iSprLightning = g_Game.PrecacheModel( "sprites/lgtning.spr" );
	g_iSprWhite = g_Game.PrecacheModel( "sprites/white.spr" );
	g_iSprFire = g_Game.PrecacheModel( "sprites/explode1.spr" );

	g_iSprRflare = g_Game.PrecacheModel( "sprites/fireworks/rflare.spr" );
	g_iSprGflare = g_Game.PrecacheModel( "sprites/fireworks/gflare.spr" );
	g_iSprBflare = g_Game.PrecacheModel( "sprites/fireworks/bflare.spr" );
	g_iSprOflare = g_Game.PrecacheModel( "sprites/fireworks/oflare.spr" );
	g_iSprPflare = g_Game.PrecacheModel( "sprites/fireworks/pflare.spr" );
	g_iSprTflare = g_Game.PrecacheModel( "sprites/fireworks/tflare.spr" );
	g_iSprYflare = g_Game.PrecacheModel( "sprites/fireworks/yflare.spr" );
	g_iSprLaserdot = g_Game.PrecacheModel( "sprites/laserdot.spr" );
	g_iSprShockwave = g_Game.PrecacheModel( "sprites/shockwave.spr" );


	g_SoundSystem.PrecacheSound( "weapons/explode3.wav" );
	g_SoundSystem.PrecacheSound( "weapons/explode4.wav" );
	g_SoundSystem.PrecacheSound( "weapons/explode5.wav" );

	g_SoundSystem.PrecacheSound( "weapons/rocketfire1.wav" );
	g_SoundSystem.PrecacheSound( "weapons/mortarhit.wav" );
	g_SoundSystem.PrecacheSound( "ambience/thunder_clap.wav" );

	File@ pFile;
	if ( true || ( @pFile = g_FileSystem.OpenFile( "sound/fireworks/rocket1.wav", OpenFile::READ ) ) !is null )
	{
		if ( pFile !is null && pFile.IsOpen() )
			pFile.Close();

		g_SoundSystem.PrecacheSound( "fireworks/rocket1.wav" );
		g_Game.PrecacheGeneric( "sound/fireworks/rocket1.wav" );
		g_bHasRocket = true;
	}
	else
	{
		g_SoundSystem.PrecacheSound( "weapons/rocket1.wav" );
		g_bHasRocket = false;
	}

	if ( true || ( @pFile = g_FileSystem.OpenFile( "sound/fireworks/weapondrop1.wav", OpenFile::READ ) ) !is null )
	{
		if ( pFile !is null && pFile.IsOpen() )
			pFile.Close();

		g_SoundSystem.PrecacheSound( "fireworks/weapondrop1.wav" );
		g_Game.PrecacheGeneric( "sound/fireworks/weapondrop1.wav" );
		g_bHasDrop = true;
	}
	else
	{
		g_SoundSystem.PrecacheSound( "items/weapondrop1.wav" );
		g_bHasDrop = false;
	}

	g_SoundSystem.PrecacheSound( "fvox/beep.wav" );
	g_SoundSystem.PrecacheSound( "fvox/bell.wav" );
	
	g_CustomEntityFuncs.RegisterCustomEntity( "fireworks_shooter", "fireworks_shooter" );
	g_CustomEntityFuncs.RegisterCustomEntity( "firework_normal", "firework_normal" );
	g_CustomEntityFuncs.RegisterCustomEntity( "firework_rc", "firework_rc" );
	g_CustomEntityFuncs.RegisterCustomEntity( "firework_rv", "firework_rv" );
	g_CustomEntityFuncs.RegisterCustomEntity( "nrm_fireworks", "nrm_fireworks" );
}

class Color
{
	uint8 r, g, b;
	Color() { r = g = b = 0; }
	Color( uint8 r, uint8 g, uint8 b ) { this.r = r; this.g = g; this.b = b; }
	Color( Vector vec ) { this.r = int( vec.x ); this.g = int( vec.y ); this.b = int( vec.z ); }
	Vector ToVector() { return Vector( r, g, b ); }
}

bool check_fireworks( CBasePlayer@ pPlayer, int iMode )
{
	int iAmount, iPlayer = pPlayer.entindex();
	if ( !g_pCVarFireworksEnable.GetBool() )
	{
		if ( !g_pBoolAllowedFireworks[ iPlayer ] )
			return false;

//		return true;
	}

	switch ( iMode )
	{
		case MODE_USER:
		{
			if ( IsPlayerAdmin( pPlayer ) ) iAmount = g_pCVarAdminMaxCount.GetInt();
			else iAmount = g_pCVarMaxCount.GetInt();
		
			if ( g_pIntPlayerFireworks[ iPlayer ] >= iAmount )
				return false;
				
			break;
		}

		case MODE_ADMIN:
		{
			if ( !IsPlayerAdmin( pPlayer ) )
				return false;

			iAmount = g_pCVarAdminMaxCount.GetInt();

			if ( g_pIntPlayerFireworks[ iPlayer ] >= iAmount )
				return false;

			break;
		}
		
		case MODE_UNLIMIT:
		{
			if ( !IsPlayerAdmin( pPlayer ) )
				return false;

			break;
		}
	}
	
	return true;
}

void CmdCheckPassword( const CCommand@ args )
{
	CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();
	
	if ( pPlayer is null || !pPlayer.IsConnected() )
		return;

	string szArg = args.Arg( 1 );
	szArg.Trim();

	string szPass = g_pCVarPassword.GetString();
	szPass.Trim();
	
	int iPlayer = pPlayer.entindex();

	if ( szArg.Compare( szPass ) == 0 )
	{
		g_pBoolAllowedFireworks[ iPlayer ] = true;
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "[FIRE] Password Accepted\n" );
	}
	else
	{
		g_pBoolAllowedFireworks[ iPlayer ] = false;
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "[FIRE] Password Denied\n" );
	}
}


void CmdSpawnShooter( const CCommand@ args )
{
	CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();
	
	if ( pPlayer is null || !pPlayer.IsConnected() )
		return;

	if ( !check_fireworks( pPlayer, MODE_UNLIMIT ) )
	{
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "[FIRE] You are not allowed to throw shooters.\n" );
		return;
	}

	if ( CheckShooters( pPlayer ) )
	{
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "[FIRE] You cannot spawn more.\n" );
		return;
	}

	string szArg = args.Arg( 1 );
	szArg.Trim();
	int shots = atoi( szArg );
	if ( shots < 1 ) shots = 5;
	shots = Math.clamp( 1, 100, shots );

	szArg = args.Arg( 2 );
	szArg.Trim();
	float time = atof( szArg );
	if ( time < 0.1 ) time = 5.0;
	time = Math.clamp( 0.1, 20.0, time );

	szArg = args.Arg( 3 );
	szArg.Trim();
	uint8 r = atoui( szArg );

	szArg = args.Arg( 4 );
	szArg.Trim();
	uint8 g = atoui( szArg );

	szArg = args.Arg( 5 );
	szArg.Trim();
	uint8 b = atoui( szArg );

	szArg = args.Arg( 6 );
	szArg.Trim();
	int type = UTIL_ReadFlags( szArg );
	if ( type <= 0 ) szArg = "abcdefsz";
	
	shooter_spawn( pPlayer, time, shots, Color( r, g, b ), szArg );
}

void CmdShootFireworks( const CCommand@ args )
{
	CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();
	
	if ( pPlayer is null || !pPlayer.IsConnected() )
		return;

	if ( !check_fireworks( pPlayer, MODE_ADMIN ) )
		return;
	
	shoot_firework( pPlayer );
}

void shooter_spawn( CBasePlayer@ pPlayer, float tasktime, int shots, Color col, string effects )
{
	if ( !pPlayer.IsAlive() )
		return;

	Vector Origin = pPlayer.GetOrigin();

	CBaseEntity@ pEntity = g_EntityFuncs.Create( "fireworks_shooter", Origin, g_vecZero, true, pPlayer.edict() );
	if ( pEntity is null ) return;

	pEntity.pev.target = effects;
	pEntity.pev.iuser1 = shots;
	pEntity.pev.vuser1 = col.ToVector();
	pEntity.pev.fuser1 = tasktime;
	pEntity.pev.nextthink = g_Engine.time + tasktime;
	pEntity.pev.iuser2 = 1;

	g_EntityFuncs.DispatchSpawn( pEntity.edict() );

	if ( g_bHasDrop ) g_SoundSystem.EmitSoundDyn( pEntity.edict(), CHAN_WEAPON, "fireworks/weapondrop1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
	else g_SoundSystem.EmitSoundDyn( pEntity.edict(), CHAN_WEAPON, "items/weapondrop1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
}

void detonate_shooter( CBaseEntity@ pEntity )
{
	@pEntity.pev.owner = null;
	explode( pEntity );
	g_EntityFuncs.Remove( pEntity );
}

void CmdSpawnFirework( const CCommand@ args )
{
	CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();
	
	if ( pPlayer is null || !pPlayer.IsConnected() )
		return;

	if ( !check_fireworks( pPlayer, MODE_USER ) )
	{
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "[FIRE] You are not allowed to throw more fireworks.\n" );
		return;
	}

	string szArg = args.Arg( 0 );
	szArg.Trim();

	string type2;

	if ( szArg.ICompare( ".firework" ) == 0 ) type2 = "firework_normal";
	else type2 = szArg;

	szArg = args.Arg( 1 );
	szArg.Trim();
	uint8 r = atoui( szArg );

	szArg = args.Arg( 2 );
	szArg.Trim();
	uint8 g = atoui( szArg );

	szArg = args.Arg( 3 );
	szArg.Trim();
	uint8 b = atoui( szArg );

	szArg = args.Arg( 4 );
	szArg.Trim();
	int type = UTIL_ReadFlags( szArg );
	if ( type <= 0 ) szArg = "abcdefsz";

	fireworks_spawn( pPlayer, type2, szArg, Color( r, g, b ) );
}

void fireworks_spawn( CBaseEntity@ pEntity, string type, string effects, Color col, bool bSpawnSound = true )
{
	if ( pEntity.IsPlayer() && !pEntity.IsAlive() && !pEntity.IsRevivable() )
		return;

	Vector Origin = pEntity.GetOrigin();
	Vector Angles;

	Angles.x = 90.0;
	Angles.y = Math.RandomFloat( 0.0, 360.0 );
	Angles.z = 0.0;

	CBaseEntity@ pEnt = g_EntityFuncs.Create( "nrm_fireworks", Origin, Angles, true, pEntity.edict() );
	if ( pEnt is null ) return;

	pEnt.pev.target = effects;
	pEnt.pev.targetname = type;
	
	pEnt.pev.iuser2 = pEntity.pev.iuser2;

	g_EntityFuncs.DispatchSpawn( pEnt.edict() );

	if ( col.r != 0 || col.g != 0 || col.b != 0 )
	{
		if ( pEntity.IsPlayer() )
			g_SoundSystem.EmitSoundDyn( pEntity.edict(), CHAN_STREAM, "fvox/beep.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM, pEntity.entindex() );
	}
	else if ( g_pCVarColorType.GetBool() )
	{
		switch ( Math.RandomLong( 0, 6 ) )
		{
			case 0: col.r = 255; break;
			case 1: col.g = 255; break;
			case 2: col.b = 255; break;
			case 3: 
			{
				col.g = 255;
				col.b = 255;
				break;
			}
			case 4:
			{
				col.r = 255;
				col.b = 255;
				break;
			}
			case 5: 
			{
				col.r = 255;
				col.g = 255;
				break;
			}
			case 6: 
			{
				col.r = 255;
				col.g = 128;
				break;
			}
		}
	} 
	else 
	{
		col.r = Math.RandomLong( 0, 255 );
		col.g = Math.RandomLong( 0, 255 );
		col.b = Math.RandomLong( 0, 255 );
	}

	pEnt.pev.renderfx = kRenderFxGlowShell;
	pEnt.pev.rendercolor = col.ToVector();
	pEnt.pev.rendermode = kRenderNormal;
	pEnt.pev.renderamt = 10;

	pEnt.pev.vuser1 = col.ToVector();

	if ( bSpawnSound )
	{
		if ( g_bHasDrop ) g_SoundSystem.EmitSoundDyn( pEnt.edict(), CHAN_WEAPON, "fireworks/weapondrop1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
		else g_SoundSystem.EmitSoundDyn( pEnt.edict(), CHAN_WEAPON, "items/weapondrop1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
	}

	pEnt.pev.nextthink = g_Engine.time + 5.0;

	if ( pEntity.IsPlayer() )
		g_pIntPlayerFireworks[ pEntity.entindex() ]++;
}

void shoot_firework( CBaseEntity@ pEntity )
{
	detonate_fireworks( pEntity, "firework_rc" );
	detonate_fireworks( pEntity, "firework_rv" );

	if ( pEntity.IsPlayer() )
		detonate_fireworks( pEntity, "firework_normal" );

	fireworks_shoot( pEntity, "nrm_fireworks" );
}

void fireworks_shoot( CBaseEntity@ pEntity, string szClassname )
{
	CBaseEntity@ pEnt = null;
	CBaseEntity@ pEnt2 = null;
	edict_t@ pEdict = pEntity.edict();
	int iPlayer = -1;
	
	if ( pEntity !is null )
	{
		CBaseEntity@ pOwner = g_EntityFuncs.Instance( pEntity.pev.owner );
		if ( pOwner !is null && pOwner.IsPlayer() )
		{
			@pEdict = pOwner.edict();
			iPlayer = pOwner.entindex();
		}
		
		if ( iPlayer == -1 && pEntity.IsPlayer() ) iPlayer = pEntity.entindex();
	}

	while ( ( @pEnt = g_EntityFuncs.FindEntityByClassname( pEnt, szClassname ) ) !is null )
	{
		if ( pEnt.pev.owner !is pEntity.edict() )
			continue;
		
		if ( ( @pEnt2 = g_EntityFuncs.Create( pEnt.pev.targetname, pEnt.GetOrigin(), pEnt.pev.angles, true, pEdict ) ) !is null )
		{
			g_EntityFuncs.SetSize( pEnt2.pev, pEnt.pev.mins, pEnt.pev.maxs );
	
			pEnt2.pev.target = pEnt.pev.target;
			pEnt2.pev.vuser1 = pEnt.pev.vuser1;
			pEnt2.pev.nextthink = pEnt.pev.nextthink;
			pEnt2.pev.iuser2 = pEnt.pev.iuser2;

			g_EntityFuncs.DispatchSpawn( pEnt2.edict() );
		}
		
		if ( iPlayer > 0 && pEnt.pev.iuser2 == 0 ) g_pIntPlayerFireworks[ iPlayer ]--;

		g_EntityFuncs.Remove( pEnt );
	}
}

void detonate_fireworks( CBaseEntity@ pEntity, string szClassname )
{
	CBaseEntity@ pEnt = null;
	while ( ( @pEnt = g_EntityFuncs.FindEntityByClassname( pEnt, szClassname ) ) !is null )
	{
		if ( pEnt.pev.owner !is pEntity.edict() )
			continue;
		
		if ( pEnt.pev.iuser2 == 1 )
			continue;

		explode( pEnt );

		if ( pEntity.IsPlayer() ) g_EngineFuncs.SetView( pEntity.edict(), pEntity.edict() );

		g_EntityFuncs.Remove( pEnt );
	}
}

class fireworks_shooter : ScriptBaseEntity
{
	void Spawn()
	{
		g_EntityFuncs.SetModel( self, "models/w_rpgammo.mdl" );

		self.pev.movetype = MOVETYPE_TOSS;
		self.pev.solid = SOLID_TRIGGER;
	}

	void Think()
	{
		int shots = self.pev.iuser1;
		Color col = Color( self.pev.vuser1 );
		string effects = self.pev.target;

		Vector origin = self.GetOrigin();
		origin.z += 10;
		touch_effect( origin, Color( 255, 255, 255 ) );

		fireworks_spawn( self, "firework_normal", effects, col, false );
	//	shoot_firework( self );
		fireworks_shoot( self, "nrm_fireworks" );

		shots--;
		if ( shots < 1 ) detonate_shooter( self );
		else self.pev.iuser1 = shots;

		self.pev.nextthink = g_Engine.time + self.pev.fuser1;
	}
}

class firework_normal : ScriptBaseEntity
{
	void Spawn()
	{
		g_EntityFuncs.SetModel( self, "models/rpgrocket.mdl" );
	
		self.pev.effects = 64;

		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, "weapons/rocketfire1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM );

		if ( g_bHasRocket ) g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "fireworks/rocket1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
		else g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "weapons/rocket1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM );

		self.pev.iuser1 = g_pCVarMaxLife.GetInt();
		Color col = Color( self.pev.vuser1 );
		self.pev.solid = SOLID_SLIDEBOX;
		self.pev.movetype = MOVETYPE_FLY;

		self.pev.vuser2 = self.GetOrigin();

		NetworkMessage message( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
		message.WriteByte( TE_BEAMFOLLOW );
		message.WriteShort( self.entindex() );
		message.WriteShort( g_iSprSmoke );
		message.WriteByte( 45 );
		message.WriteByte( 4 );
		message.WriteByte( col.r );
		message.WriteByte( col.g );
		message.WriteByte( col.b );
		message.WriteByte( 255 );
		message.End();

 		Vector vVelocity;
		vVelocity.z = Math.RandomFloat( 400.0, 1000.0 );
		self.pev.velocity = vVelocity;

		self.pev.nextthink = g_Engine.time + 0.1;
	}

	void Think()
	{
		Vector velo = self.pev.velocity;

		float x = g_pCVarXVelocity.GetFloat();
		float y = g_pCVarYVelocity.GetFloat();
		velo.x += Math.RandomFloat( ( -1.0 * x ), x );
		velo.y += Math.RandomFloat( ( -1.0 * y ), y );
		velo.z += Math.RandomFloat( 10.0, 200.0 );
		self.pev.velocity = velo;
		self.pev.nextthink = g_Engine.time + 0.1;
	}

	void Touch( CBaseEntity@ pOther )
	{
		if ( pOther is null )
			return;

		if ( self.pev.owner is pOther.pev.owner )
			return;

		Vector origin = self.GetOrigin();
		Color col = Color( self.pev.vuser1 );

		explode( self );
		g_EntityFuncs.Remove( self );
		
		touch_effect( origin, col );
	}
}

class firework_rc : ScriptBaseEntity
{
	void Spawn()
	{
		g_EntityFuncs.SetModel( self, "models/rpgrocket.mdl" );

		self.pev.effects = 64;

		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, "weapons/rocketfire1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM );

		if ( g_bHasRocket ) g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "fireworks/rocket1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
		else g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "weapons/rocket1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM );

		self.pev.iuser1 = g_pCVarMaxLife.GetInt();
		Color col = Color( self.pev.vuser1 );
		self.pev.solid = SOLID_SLIDEBOX;
		self.pev.movetype = MOVETYPE_FLY;
		
		self.pev.vuser2 = self.GetOrigin();

		NetworkMessage message( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
		message.WriteByte( TE_BEAMFOLLOW );
		message.WriteShort( self.entindex() );
		message.WriteShort( g_iSprSmoke );
		message.WriteByte( 45 );
		message.WriteByte( 4 );
		message.WriteByte( col.r );
		message.WriteByte( col.g );
		message.WriteByte( col.b );
		message.WriteByte( 255 );
		message.End();

 		Vector vVelocity;
		vVelocity.z = Math.RandomFloat( 400.0, 1000.0 );
		self.pev.velocity = vVelocity;

		self.pev.nextthink = g_Engine.time + 0.1;
	}

	void Think()
	{
		if ( self is null )
			return;

		CBasePlayer@ pPlayer = cast<CBasePlayer@>( g_EntityFuncs.Instance( self.pev.owner ) );

		if ( pPlayer is null )
			return;

		Vector vOrigin = self.GetOrigin();

		Vector aimvec, uorigin;

		TraceResult tr;
		Vector vecStart = pPlayer.GetGunPosition();

		Math.MakeVectors( pPlayer.pev.v_angle );
		g_Utility.TraceLine( vecStart, vecStart + g_Engine.v_forward * 4096, dont_ignore_monsters, pPlayer.edict(), tr );

		if ( tr.pHit !is null )
			aimvec = tr.vecEndPos;

		make_dot( aimvec );

		uorigin.x = FloatRound( vOrigin.x );
		uorigin.y = FloatRound( vOrigin.y );
		uorigin.z = FloatRound( vOrigin.z );

		Vector velocityvec;
		velocityvec.x = aimvec.x - uorigin.x;
		velocityvec.y = aimvec.y - uorigin.y;
		velocityvec.z = aimvec.z - uorigin.z;

		float length = sqrt( velocityvec.x * velocityvec.x + velocityvec.y * velocityvec.y + velocityvec.z * velocityvec.z );
		velocityvec.x = velocityvec.x * 1000 / length;
		velocityvec.y = velocityvec.y * 1000 / length;
		velocityvec.z = velocityvec.z * 1000 / length;

		Vector fl_iNewVelocity, iNewVelocity;
		iNewVelocity.x = velocityvec.x;
		iNewVelocity.y = velocityvec.y;
		iNewVelocity.z = velocityvec.z;

		fl_iNewVelocity.x = iNewVelocity.x + 0.0;
		fl_iNewVelocity.y = iNewVelocity.y + 0.0;
		fl_iNewVelocity.z = iNewVelocity.z + 0.0;

		self.pev.velocity = fl_iNewVelocity;
		self.pev.nextthink = g_Engine.time + 0.1;
	}

	void Touch( CBaseEntity@ pOther )
	{
		if ( pOther is null )
			return;

		if ( self.pev.owner is pOther.pev.owner )
			return;

		Vector origin = self.GetOrigin();
		Color col = Color( self.pev.vuser1 );

		if ( self is null )
			return;

		CBaseEntity@ pOwner = g_EntityFuncs.Instance( self.pev.owner );

		if ( pOwner !is null )
			g_EngineFuncs.SetView( pOwner.edict(), pOwner.edict() );

		explode( self );
		g_EntityFuncs.Remove( self );
		
		touch_effect( origin, col );
	}
}

class firework_rv : ScriptBaseEntity
{
	void Spawn()
	{
		g_EntityFuncs.SetModel( self, "models/rpgrocket.mdl" );

		self.pev.effects = 64;

		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, "weapons/rocketfire1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM );

		if ( g_bHasRocket ) g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "fireworks/rocket1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
		else g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "weapons/rocket1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM );

		self.pev.iuser1 = g_pCVarMaxLife.GetInt();
		Color col = Color( self.pev.vuser1 );
		self.pev.solid = SOLID_SLIDEBOX;
		self.pev.movetype = MOVETYPE_FLY;
		
		self.pev.vuser2 = self.GetOrigin();

		NetworkMessage message( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
		message.WriteByte( TE_BEAMFOLLOW );
		message.WriteShort( self.entindex() );
		message.WriteShort( g_iSprSmoke );
		message.WriteByte( 45 );
		message.WriteByte( 4 );
		message.WriteByte( col.r );
		message.WriteByte( col.g );
		message.WriteByte( col.b );
		message.WriteByte( 255 );
		message.End();

 		Vector vVelocity;
		vVelocity.z = Math.RandomFloat( 400.0, 1000.0 );
		self.pev.velocity = vVelocity;

		self.pev.nextthink = g_Engine.time + 0.1;
	}

	void Think()
	{
		if ( self is null )
			return;

		CBaseEntity@ pOwner = g_EntityFuncs.Instance( self.pev.owner );

		if ( pOwner is null )
			return;

		g_EngineFuncs.SetView( pOwner.edict(), self.edict() );

		Vector fl_iNewVelocity;

		int iVelocity = 750;
		Math.MakeVectors( pOwner.pev.v_angle );
		Vector vVector = g_Engine.v_forward * iVelocity;

		fl_iNewVelocity = vVector;

		self.pev.velocity = fl_iNewVelocity;

		Vector vAngles = pOwner.pev.v_angle;
		self.pev.angles = vAngles;

		self.pev.nextthink = g_Engine.time + 0.01;
	}

	void Touch( CBaseEntity@ pOther )
	{
		if ( pOther is null )
			return;
			
		if ( self.pev.owner is pOther.pev.owner )
			return;

		Vector origin = self.GetOrigin();
		Color col = Color( self.pev.vuser1 );

		if ( self is null )
			return;

		CBaseEntity@ pOwner = g_EntityFuncs.Instance( self.pev.owner );

		if ( pOwner !is null )
			g_EngineFuncs.SetView( pOwner.edict(), pOwner.edict() );

		explode( self );
		g_EntityFuncs.Remove( self );
		
		touch_effect( origin, col );
	}
}

class nrm_fireworks : ScriptBaseEntity
{
	void Spawn()
	{
		g_EntityFuncs.SetModel( self, "models/rpgrocket.mdl" );

		self.pev.solid = SOLID_TRIGGER;
		self.pev.movetype = MOVETYPE_TOSS;
	}

	void Think()
	{
		self.pev.velocity = Vector( 0.0, 0.0, 450.0 );
		self.pev.nextthink = g_Engine.time + 5.0;
	}

	void Touch( CBaseEntity@ pOther )
	{
		if ( pOther is null )
			return;
			
		if ( !pOther.IsBSPModel() )
			return;
		
	//	if ( g_pMovableEntList.find( pOther.GetClassname() ) >= 0 && pOther.IsMoving() && pOther.pev.speed != 0 )
		if ( pOther.IsMoving() && pOther.pev.speed != 0 )
			return;

		Vector origin = self.GetOrigin();
		origin.z += 1;
		Color col = Color( self.pev.vuser1 );

		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_ITEM, "fvox/bell.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
		
		touch_effect( origin, col );
	}
}

void touch_effect( Vector Origin, Color col )
{
	// blast circles
	Vector origin;
	origin.x = FloatRound( Origin.x );
	origin.y = FloatRound( Origin.y );
	origin.z = FloatRound( Origin.z );

	NetworkMessage message( MSG_PAS, NetworkMessages::SVC_TEMPENTITY, origin );
	message.WriteByte( TE_BEAMCYLINDER );
	message.WriteCoord( origin.x );
	message.WriteCoord( origin.y );
	message.WriteCoord( origin.z + 16 );
	message.WriteCoord( origin.x );
	message.WriteCoord( origin.y );
	message.WriteCoord( origin.z + 16 + 348 ); // reach damage radius over .3 seconds
	message.WriteShort( g_iSprShockwave );

	message.WriteByte( 0 ); // startframe
	message.WriteByte( 0 ); // framerate
	message.WriteByte( 3 ); // life
	message.WriteByte( 30 );  // width
	message.WriteByte( 0 );   // noise

	message.WriteByte( col.r );
	message.WriteByte( col.g );
	message.WriteByte( col.b );

	message.WriteByte( 255 ); //brightness
	message.WriteByte( 0 );		// speed
	message.End();

	NetworkMessage message2( MSG_PAS, NetworkMessages::SVC_TEMPENTITY, origin );
	message2.WriteByte( TE_BEAMCYLINDER );
	message2.WriteCoord( origin.x );
	message2.WriteCoord( origin.y );
	message2.WriteCoord( origin.z + 16 );
	message2.WriteCoord( origin.x );
	message2.WriteCoord( origin.y );
	message2.WriteCoord( origin.z + 16 + ( 384 / 2 ) ); // reach damage radius over .3 seconds
	message2.WriteShort( g_iSprShockwave );

	message2.WriteByte( 0 ); // startframe
	message2.WriteByte( 0 ); // framerate
	message2.WriteByte( 3 ); // life
	message2.WriteByte( 30 );  // width
	message2.WriteByte( 0 );   // noise

	message2.WriteByte( 255 - col.r );
	message2.WriteByte( 255 - col.g );
	message2.WriteByte( 255 - col.b );
		
	message2.WriteByte( 255 );	//brightness
	message2.WriteByte( 0 );	// speed
	message2.End();
}

int SpriteColorNum( Color col )
{
	if ( ( col.r > 128 ) && ( col.g < 127 ) && ( col.b < 127 ) ) return 0;
	else if ( ( col.r < 127 ) && ( col.g > 128 ) && ( col.b < 127 ) ) return 1;
	else if ( ( col.r < 127 ) && ( col.g < 127 ) && ( col.b > 128 ) ) return 2;
	else if ( ( col.r < 127 ) && ( col.g > 128 ) && ( col.b > 128 ) ) return 3;
	else if ( ( col.r > 128 ) && ( col.g < 127 ) && ( col.b < 200 ) && ( col.b > 100 ) ) return 4;
	else if ( ( col.r > 128 ) && ( col.g > 128 ) && ( col.b < 127 ) ) return 5;
	else if ( ( col.r > 128 ) && ( col.g > 100 ) && ( col.g < 200 ) && ( col.b < 127 ) ) return 6;

	return -1;
}

// Explode Function
void explode( CBaseEntity@ pEntity )
{
	if ( pEntity is null ) return;
	Vector vecOrigin = pEntity.GetOrigin();

	Vector vecOrigin2;
	int multi = g_pCVarMultiplier.GetInt();
	vecOrigin2.x = FloatRound( vecOrigin.x );
	vecOrigin2.y = FloatRound( vecOrigin.y );
	vecOrigin2.z = FloatRound( vecOrigin.z );

	string szType = pEntity.pev.target;
	int type = UTIL_ReadFlags( szType );

	Color col = Color( pEntity.pev.vuser1 );
	
	//g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, "vecOrigin2.z - self.pev.vuser2.z = " + ( vecOrigin2.z - pEntity.pev.vuser2.z ) + "\n" );
	
	if ( vecOrigin.z - pEntity.pev.vuser2.z < 500 )
		type &= ~( 1<<0 | 1<<18 ); //remove garbage if are too close

	if ( type & ( 1<<0 ) != 0 )
	{
		//a -- Voogru Effect
		NetworkMessage message( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
		message.WriteByte( TE_BEAMDISK ); 				// TE_BEAMDISK
		message.WriteCoord( vecOrigin2.x );			// coord coord coord (center position)
		message.WriteCoord( vecOrigin2.y );
		message.WriteCoord( vecOrigin2.z );
		message.WriteCoord( 0 );			// coord coord coord (axis and radius)
		message.WriteCoord( 0 );
		message.WriteCoord( 100 );
		switch ( Math.RandomLong( 0, 1) )
		{
			case 0: message.WriteShort( g_iSprFlare6 );	break;		// short (sprite index)
			case 1: message.WriteShort( g_iSprLightning ); break;	// short (sprite index)
		}
		message.WriteByte( 0 );				// byte (starting frame)
		message.WriteByte( 0 );				// byte (frame rate in 0.1's)
		message.WriteByte( 50 );				// byte (life in 0.1's)
		message.WriteByte( 0 );				// byte (line width in 0.1's)
		message.WriteByte( 150 );				// byte (noise amplitude in 0.01's)
		message.WriteByte( col.r );				// byte,byte,byte (color)
		message.WriteByte( col.g );
		message.WriteByte( col.b );
		message.WriteByte( 255 );				// byte (brightness)
		message.WriteByte( 0 );				// byte (scroll speed in 0.1's)
		message.End();
	}

	if ( type & ( 1<<1 ) != 0 )
	{
		//b -- Flares
		uint8 count = g_pCVarFlareCount.GetInt();
		
		int iSpr;
		switch ( SpriteColorNum( col ) )
		{
			case 0: iSpr = g_iSprRflare; break;
			case 1: iSpr = g_iSprGflare; break;
			case 2: iSpr = g_iSprBflare; break;
			case 3: iSpr = g_iSprTflare; break;
			case 4: iSpr = g_iSprPflare; break;
			case 5: iSpr = g_iSprYflare; break;
			case 6: iSpr = g_iSprOflare; break;
			default: iSpr = g_iSprBflare; break;
		}

		if ( g_pCVarColorType.GetBool() )
		{
			NetworkMessage message( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
			message.WriteByte( TE_SPRITETRAIL ); 		// TE_SPRITETRAIL
			message.WriteCoord( vecOrigin2.x );			// coord, coord, coord (start)
			message.WriteCoord( vecOrigin2.y );
			message.WriteCoord( vecOrigin2.z - 20 );
			message.WriteCoord( vecOrigin2.x );			// coord, coord, coord (end)
			message.WriteCoord( vecOrigin2.y );
			message.WriteCoord( vecOrigin2.z + 20 );
			message.WriteShort( iSpr );
			message.WriteByte( count );				// byte (count)
			message.WriteByte( 10 );				// byte (life in 0.1's)
			message.WriteByte( 10 );				// byte (scale in 0.1's)
			message.WriteByte( Math.RandomLong( 40, 100 ) );		// byte (velocity along vector in 10's)
			message.WriteByte( 40 );				// byte (randomness of velocity in 10's)
			message.End();
		}
		else
		{
			NetworkMessage message( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
			message.WriteByte( TE_SPRITETRAIL );		// TE_SPRITETRAIL
			message.WriteCoord( vecOrigin2.x );			// coord, coord, coord (start)
			message.WriteCoord( vecOrigin2.y );
			message.WriteCoord( vecOrigin2.z - 20 );
			message.WriteCoord( vecOrigin2.x );			// coord, coord, coord (end)
			message.WriteCoord( vecOrigin2.y );
			message.WriteCoord( vecOrigin2.z + 20 );
			message.WriteShort( iSpr );
			message.WriteByte( count );				// byte (count)
			message.WriteByte( 2 );				// byte (life in 0.1's)
			message.WriteByte( 5 );				// byte (scale in 0.1's)
			message.WriteByte( Math.RandomLong( 40, 100 ) );		// byte (velocity along vector in 10's)
			message.WriteByte( 40 );				// byte (randomness of velocity in 10's)
			message.End();
		}
	}

	if ( type & ( 1<<2 ) != 0 )
	{
		//c -- Falling flares
		int velo = Math.RandomLong( 30, 70 );
		int spr;
		int choosespr = Math.RandomLong( 0, 3 );

		switch ( choosespr )
		{
			case 0: spr = g_iSprFlare3; break;
			case 1: spr = g_iSprBflare; break;
			case 2: spr = g_iSprFlare6; break;
			case 3: spr = g_iSprRflare; break;
		}

		//TE_SPRITETRAIL
		NetworkMessage message( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
		message.WriteByte ( TE_SPRITETRAIL );	// line of moving glow sprites with gravity, fadeout, and collisions
		message.WriteCoord( vecOrigin2.x );			// coord, coord, coord (start)
		message.WriteCoord( vecOrigin2.y );
		message.WriteCoord( vecOrigin2.z );
		message.WriteCoord( vecOrigin2.x );			// coord, coord, coord (start)
		message.WriteCoord( vecOrigin2.y );
		message.WriteCoord( vecOrigin2.z - 80 );
		message.WriteShort( spr ); // (sprite index)
		message.WriteByte( 50 * multi ); // (count)
		message.WriteByte( Math.RandomLong( 1, 3 ) ); // (life in 0.1's) 
		message.WriteByte( 10 ); // byte (scale in 0.1's) 
		message.WriteByte( velo ); // (velocity along vector in 10's)
		message.WriteByte( 40 ); // (randomness of velocity in 10's)
		message.End();
	}

	if ( type & ( 1<<3 ) != 0 )
	{
		//d - lightening
		//TE_BEAMPOINTS
		NetworkMessage message( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY ); 
		message.WriteByte( TE_BEAMPOINTS );
		message.WriteCoord( vecOrigin2.x );			// coord, coord, coord (start)
		message.WriteCoord( vecOrigin2.y );
		message.WriteCoord( vecOrigin2.z - 50 );
		message.WriteCoord( vecOrigin2.x );			// coord, coord, coord (End)
		message.WriteCoord( vecOrigin2.y );
		message.WriteCoord( vecOrigin2.z - 2000 );
		message.WriteShort( g_iSprLightning ); 
		message.WriteByte( 1 ); // framestart 
		message.WriteByte( 5 ); // framerate 
		message.WriteByte( 3 ); // life 
		message.WriteByte( 150 * multi ); // width 
		message.WriteByte( 30 ); // noise 
		message.WriteByte( 200 ); // r, g, b 
		message.WriteByte( 200 ); // r, g, b 
		message.WriteByte( 200 ); // r, g, b 
		message.WriteByte( 200 ); // brightness 
		message.WriteByte( 100 ); // speed 
		message.End();

		//Sparks 
/*		NetworkMessage message2( MSG_PVS, NetworkMessages::SVC_TEMPENTITY );
		message2.WriteByte( TE_SPARKS );
		message2.WriteCoord( vecOrigin2.x );			// coord, coord, coord (start)
		message2.WriteCoord( vecOrigin2.y );
		message2.WriteCoord( vecOrigin2.z - 1000 );
		message2.End();*/
		
		g_Utility.Sparks( Vector( vecOrigin2.x, vecOrigin2.y, vecOrigin2.z - 1000 ) );	
	}

	if ( type & ( 1<<4 ) != 0 )
	{
		//e -- Lights
		NetworkMessage message( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
		message.WriteByte( TE_DLIGHT );
		message.WriteCoord( vecOrigin2.x );			// coord, coord, coord (start)
		message.WriteCoord( vecOrigin2.y );
		message.WriteCoord( vecOrigin2.z );
		message.WriteByte( 60 );			// byte (radius in 10's) 
		message.WriteByte( col.r );			// byte byte byte (color)
		message.WriteByte( col.g );
		message.WriteByte( col.b );
		message.WriteByte( 100 );			// byte (life in 10's)
		message.WriteByte( 15 );			// byte (decay rate in 10's)
		message.End();
	}

	if ( type & ( 1<<5 ) != 0 )
	{
		//f -- Effect upward
		NetworkMessage message( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
		message.WriteByte( TE_LARGEFUNNEL );
		message.WriteCoord( vecOrigin2.x );
		message.WriteCoord( vecOrigin2.y );
		message.WriteCoord( vecOrigin2.z - 64 );
		message.WriteShort( g_iSprFlare6 );
		message.WriteShort( 1 );
		message.End();
	}

	if ( type & ( 1<<6 ) != 0 )
	{
		//g -- Throw ents
		int velo = Math.RandomLong( 300, 700 );

		//define TE_EXPLODEMODEL
		NetworkMessage message( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
		message.WriteByte( TE_EXPLODEMODEL ); // spherical shower of models, picks from set
		message.WriteCoord( vecOrigin2.x );			// coord, coord, coord (start)
		message.WriteCoord( vecOrigin2.y );
		message.WriteCoord( vecOrigin2.z - 50 );
		message.WriteCoord( velo ); //(velocity)
		message.WriteShort( g_iSprGarbagegibs ); //(model index)
		message.WriteShort( 25 * multi ); // (count)
		message.WriteByte( 15 ); // (life in 0.1's)		
		message.End();
	}

	if ( type & ( 1<<7 ) != 0 )
	{
		//h
		//TE_TAREXPLOSION
		NetworkMessage message( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
		message.WriteByte( TE_TAREXPLOSION ); // Quake1 "tarbaby" explosion with sound
		message.WriteCoord( vecOrigin2.x );			// coord, coord, coord (start)
		message.WriteCoord( vecOrigin2.y );
		message.WriteCoord( vecOrigin2.z - 40 );
		message.End();
	}

	if ( type & ( 1<<8 ) != 0 )
	{
		//i
		int color = Math.RandomLong( 0, 255 );
		int width = Math.RandomLong( 400, 1000 );
		//TE_PARTICLEBURST
		NetworkMessage message( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
		message.WriteByte( TE_PARTICLEBURST ); // very similar to lavasplash.
		message.WriteCoord( vecOrigin2.x );			// coord, coord, coord (start)
		message.WriteCoord( vecOrigin2.y );
		message.WriteCoord( vecOrigin2.z );
		message.WriteShort( width );
		message.WriteByte( color ); // (particle color)
		message.WriteByte( 40 ); // (duration * 10) (will be randomized a bit)
		message.End();
	}

	if ( type & ( 1<<9 ) != 0 )
	{
		//j...for random...blood
		NetworkMessage message( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
		message.WriteByte( TE_LAVASPLASH );
		message.WriteCoord( vecOrigin2.x );			// coord, coord, coord (start)
		message.WriteCoord( vecOrigin2.y );
		message.WriteCoord( vecOrigin2.z );
		message.End();
	}

	if ( type & ( 1<<10 ) != 0 )
	{
		//k
		NetworkMessage message( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
		message.WriteByte( TE_IMPLOSION );
		message.WriteCoord( vecOrigin2.x );
		message.WriteCoord( vecOrigin2.y );
		message.WriteCoord( vecOrigin2.z - 100 );
		message.WriteByte( 255 ); // radius
		message.WriteByte( 80 );
		message.WriteByte( 20 );
		message.End();
	}

	if ( type & ( 1<<11 ) != 0 )
	{
		int iSpr;
		switch ( SpriteColorNum( col ) )
		{
			case 0: iSpr = g_iSprRflare; break;
			case 1: iSpr = g_iSprGflare; break;
			case 2: iSpr = g_iSprBflare; break;
			case 3: iSpr = g_iSprTflare; break;
			case 4: iSpr = g_iSprPflare; break;
			case 5: iSpr = g_iSprYflare; break;
			case 6: iSpr = g_iSprOflare; break;
			default: iSpr = g_iSprBflare; break;
		}

		//l Sprite field
		NetworkMessage message( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
		message.WriteByte( TE_FIREFIELD );
		message.WriteCoord( vecOrigin2.x );			// coord, coord, coord (start)
		message.WriteCoord( vecOrigin2.y );
		message.WriteCoord( vecOrigin2.z );
		message.WriteShort( 256 );
		message.WriteShort( iSpr );
		message.WriteByte( 10 );
		message.WriteByte( 1 );
		message.WriteByte( 20 );
		message.End();
	}

	if ( type & ( 1<<18 ) != 0 )
	{
		//s
		NetworkMessage message( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
		message.WriteByte( TE_BEAMDISK ); 				// TE_BEAMDISK
		message.WriteCoord( vecOrigin2.x );			// coord coord coord (center position)
		message.WriteCoord( vecOrigin2.y );
		message.WriteCoord( vecOrigin2.z );
		message.WriteCoord( vecOrigin2.x );			// coord coord coord (axis and radius)
		message.WriteCoord( vecOrigin2.y );
		message.WriteCoord( vecOrigin2.z + Math.RandomLong( 250, 750 ) );
		switch ( Math.RandomLong( 0, 1 ) )
		{
			case 0: message.WriteShort( g_iSprFlare6 ); break;		// short (sprite index)
			case 1: message.WriteShort( g_iSprLightning ); break;	// short (sprite index)
		}
		message.WriteByte( 0 );				// byte (starting frame)
		message.WriteByte( 0 );				// byte (frame rate in 0.1's)
		message.WriteByte( 25 );				// byte (life in 0.1's)
		message.WriteByte( 150 );				// byte (line width in 0.1's)
		message.WriteByte( 0 );				// byte (noise amplitude in 0.01's)
		message.WriteByte( col.r );				// byte,byte,byte (color)
		message.WriteByte( col.g );
		message.WriteByte( col.b );
		message.WriteByte( 255 );				// byte (brightness)
		message.WriteByte( 0 );				// byte (scroll speed in 0.1's)
		message.End();
	}

	if ( type & ( 1<<19 ) != 0 )
	{
		//t
		NetworkMessage message( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
		message.WriteByte( TE_SPRITE );
		message.WriteCoord( vecOrigin2.x );
		message.WriteCoord( vecOrigin2.y );
		message.WriteCoord( vecOrigin2.z );
		message.WriteShort( g_iSprSmoke );
		message.WriteByte( 10 );
		message.WriteByte( 150 );
		message.End();
	}

	if ( type & ( 1<<20 ) != 0 )
	{
		//u
		NetworkMessage message( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
		message.WriteByte( TE_BEAMCYLINDER );
		message.WriteCoord( vecOrigin2.x );			// coord, coord, coord (start)
		message.WriteCoord( vecOrigin2.y );
		message.WriteCoord( vecOrigin2.z - 70 );
		message.WriteCoord( vecOrigin2.x );			// coord, coord, coord (start)
		message.WriteCoord( vecOrigin2.y );
		message.WriteCoord( vecOrigin2.z + 136 );
		message.WriteShort( g_iSprWhite );
		message.WriteByte( 0 ); // startframe 
		message.WriteByte( 0 ); // framerate 
		message.WriteByte( 2 ); // life 2 
		message.WriteByte( 20 ); // width 16 
		message.WriteByte( 0 ); // noise 
		message.WriteByte( 188 ); // r 
		message.WriteByte( 220 ); // g 
		message.WriteByte( 255 ); // b 
		message.WriteByte( 255 ); //brightness 
		message.WriteByte( 0 ); // speed 
		message.End();

		//Explosion2 
		NetworkMessage message2( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
		message2.WriteByte( TE_EXPLOSION2 ); 
		message2.WriteCoord( vecOrigin2.x );			// coord, coord, coord (start)
		message2.WriteCoord( vecOrigin2.y );
		message2.WriteCoord( vecOrigin2.z );
		message2.WriteByte( 188 ); // byte (scale in 0.1's) 188 
		message2.WriteByte( 10 ); // byte (framerate) 
		message2.End();

		//TE_Explosion 
		NetworkMessage message3( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
		message3.WriteByte( TE_EXPLOSION );
		message3.WriteCoord( vecOrigin2.x );			// coord, coord, coord (start)
		message3.WriteCoord( vecOrigin2.y );
		message3.WriteCoord( vecOrigin2.z );
		message3.WriteShort( g_iSprFire ); 
		message3.WriteByte( 60 ); // byte (scale in 0.1's) 188 
		message3.WriteByte( 10 ); // byte (framerate) 
		message3.WriteByte( 0 ); // byte flags 
		message3.End();

		//Smoke 
		NetworkMessage message4( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
		message4.WriteByte( TE_SMOKE ); // 5 
		message4.WriteCoord( vecOrigin2.x );			// coord, coord, coord (start)
		message4.WriteCoord( vecOrigin2.y );
		message4.WriteCoord( vecOrigin2.z );
		message4.WriteShort( g_iSprSmoke );
		message4.WriteByte( 10 ); // 2 
		message4.WriteByte( 10 ); // 10 
		message4.End();
	}

	if ( type & ( 1<<21 ) != 0 ) g_SoundSystem.EmitSoundDyn( pEntity.edict(), CHAN_ITEM, "ambience/thunder_clap.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM ); //v
	if ( type & ( 1<<22 ) != 0 ) g_SoundSystem.EmitSoundDyn( pEntity.edict(), CHAN_VOICE, "weapons/explode3.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM ); // w
	if ( type & ( 1<<23 ) != 0 ) g_SoundSystem.EmitSoundDyn( pEntity.edict(), CHAN_VOICE, "weapons/explode4.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM ); //x
	if ( type & ( 1<<24 ) != 0 ) g_SoundSystem.EmitSoundDyn( pEntity.edict(), CHAN_VOICE, "weapons/explode5.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM ); //y
	if ( type & ( 1<<25 ) != 0 ) g_SoundSystem.EmitSoundDyn( pEntity.edict(), CHAN_VOICE, "weapons/mortarhit.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM ); //z

/*	if ( type & ( 1<<21 ) != 0 ) g_EngineFuncs.ServerPrint( "1<<21\n" );
	if ( type & ( 1<<22 ) != 0 ) g_EngineFuncs.ServerPrint( "1<<22\n" );
	if ( type & ( 1<<23 ) != 0 ) g_EngineFuncs.ServerPrint( "1<<23\n" );
	if ( type & ( 1<<24 ) != 0 ) g_EngineFuncs.ServerPrint( "1<<24\n" );
	if ( type & ( 1<<25 ) != 0 ) g_EngineFuncs.ServerPrint( "1<<25\n" );*/

	if ( pEntity is null )
		return;

	CBaseEntity@ pOwner = g_EntityFuncs.Instance( pEntity.pev.owner );

	if ( pOwner !is null && pOwner.IsPlayer() )
	{
		//g_EngineFuncs.ServerPrint( "pEntity.pev.iuser2 = " + pEntity.pev.iuser2 + "\n" );
	//	if ( pEntity.pev.iuser2 == 0 ) g_pIntPlayerFireworks[ pOwner.entindex() ]--;
		float flRadius = 200;
		if ( ( vecOrigin - pOwner.GetOrigin() ).Length() > flRadius + 20 )
			g_WeaponFuncs.RadiusDamage( vecOrigin2, pOwner.pev, pOwner.pev, 25.0, flRadius, CLASS_NONE, DMG_BLAST );
	}
}

void CmdRemoveFireworks( const CCommand@ args )
{
	CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();
	
	if ( pPlayer is null || !pPlayer.IsConnected() )
		return;

	string szArg = args.Arg( 1 );
	szArg.Trim();
		
	if ( szArg.IsEmpty() )
	{
		remove_fireworks( pPlayer );
		return;
	}
	
	if ( !IsPlayerAdmin( pPlayer ) || szArg != "all" )
		return;
	
	remove_entity_name( "nrm_fireworks" );
	remove_entity_name( "firework_normal" );
	remove_entity_name( "firework_rv" );
	remove_entity_name( "firework_rc" );

/*	for ( int i = 1; i <= g_Engine.maxClients; i++ )
		g_pIntPlayerFireworks[i] = 0;*/
	g_pIntPlayerFireworks = array<int>( g_Engine.maxClients + 1, 0 );	
}

void CmdRemoveShooters( const CCommand@ args )
{
	CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();
	
	if ( pPlayer is null || !pPlayer.IsConnected() )
		return;

	string szArg = args.Arg( 1 );
	szArg.Trim();
		
	if ( szArg.IsEmpty() )
	{
		remove_shooters( pPlayer );
		return;
	}
	
	if ( !IsPlayerAdmin( pPlayer ) || szArg != "all" )
		return;

	remove_shooters( pPlayer );
}

void remove_fireworks( CBasePlayer@ pPlayer )
{
	int iPlayer = pPlayer.entindex();

	if ( g_pIntPlayerFireworks[iPlayer] == 0 )
		return;

	g_pIntPlayerFireworks[iPlayer] = 0;

	remove_by_class( pPlayer, "nrm_fireworks" );
	remove_by_class( pPlayer, "firework_normal" );
	remove_by_class( pPlayer, "firework_rv" );
	remove_by_class( pPlayer, "firework_rc" );
}

void remove_shooters( CBasePlayer@ pPlayer )
{
	remove_by_class( pPlayer, "fireworks_shooter" );
}

void remove_by_class( CBasePlayer@ pPlayer, string szClassname )
{
	CBaseEntity@ pEntity = null;
	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, szClassname ) ) !is null )
	{
		if ( pEntity.pev.owner !is pPlayer.edict() )
			continue;

		g_EntityFuncs.Remove( pEntity );
	}
}

void remove_entity_name( string szClassname )
{
	CBaseEntity@ pEntity = null;
	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, szClassname ) ) !is null )
		g_EntityFuncs.Remove( pEntity );
}

void make_dot( Vector vec )
{
	NetworkMessage message( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );  
	message.WriteByte( TE_SPRITE );
	message.WriteCoord( vec.x );
	message.WriteCoord( vec.y );
	message.WriteCoord( vec.z );
	message.WriteShort( g_iSprLaserdot );
	message.WriteByte( 10 );
	message.WriteByte( 255 );
	message.End();
}

void CmdFireworksMenu( const CCommand@ args )
{
	CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();
	
	if ( pPlayer is null || !pPlayer.IsConnected() )
		return;

	g_FireworksMenu.Show( pPlayer );
}

bool FindShooters( CBasePlayer@ pPlayer )
{
	CBaseEntity@ pEntity = null;
	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "fireworks_shooter" ) ) !is null )
	{
		if ( pEntity.pev.owner is pPlayer.edict() )
			return true;
	}
	
	return false;
}

bool CheckShooters( CBasePlayer@ pPlayer )
{
	CBaseEntity@ pEntity = null;
	while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "fireworks_shooter" ) ) !is null )
	{
		if ( pEntity.pev.fuser1 < 5.0 && pEntity.pev.iuser1 > 10 )
			return true;
	}
	
	return false;
}

final class FireworksMenu
{
	private CTextMenu@ m_pMenu = null;
	private int m_iAmount = 0;
	private float m_flWaitTime = 0.0;
	
	void Show( CBasePlayer@ pPlayer = null )
	{
		if ( m_pMenu is null )
			CreateMenu();
			
		if ( pPlayer !is null )
		{
/*			if ( !check_fireworks( pPlayer, MODE_USER ) )
			{
				shoot_firework( pPlayer );
				g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "[FIRE] You are not allowed to use the menu.\n" );
				//g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "[FIRE] You cannot spawn more.\n" );
				return;
			}*/

			if ( IsPlayerAdmin( pPlayer ) ) m_iAmount = g_pCVarAdminMaxCount.GetInt();
			else m_iAmount = g_pCVarMaxCount.GetInt();

			m_pMenu.SetTitle( "Fireworks Menu: (" + g_pIntPlayerFireworks[ pPlayer.entindex() ] + " of " + m_iAmount + ")\n" );

			m_pMenu.Open( 0, 0, pPlayer );

			if ( FIRE_WAIT_TIME - ( g_Engine.time - m_flWaitTime ) > FIRE_WAIT_TIME )
				m_flWaitTime = g_Engine.time;
		}
	}
	
	private void CreateMenu()
	{
		@m_pMenu = CTextMenu( TextMenuPlayerSlotCallback( this.Callback ) );

//		m_pMenu.SetTitle( "Fireworks Menu:\n" );
		
		m_pMenu.AddItem( "Spawn Normal Rocket" );
		m_pMenu.AddItem( "Spawn Laser Guided Rocket" );
		m_pMenu.AddItem( "Spawn Remote View Rocket" );
		m_pMenu.AddItem( "Fire Rockets" );
		m_pMenu.AddItem( "Spawn Shooter" );
		m_pMenu.AddItem( "Remove All Your Rockets" );
		m_pMenu.AddItem( "Remove All Your Shooters" );
		//m_pMenu.AddItem( "Reset view" );
		
		m_pMenu.Register();
	}
	
	private void Callback( CTextMenu@ menu, CBasePlayer@ pPlayer, int iSlot, const CTextMenuItem@ pItem )
	{
		if ( pItem !is null && pPlayer !is null )
		{
			switch ( iSlot )
			{
				case 1:
				{
					if ( check_fireworks( pPlayer, MODE_USER ) )
						fireworks_spawn( pPlayer, "firework_normal", "abcdefsz", Color() );
					else
						g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "[FIRE] You cannot spawn more.\n" );

					break;
				}
				case 2:
				{
					if ( check_fireworks( pPlayer, MODE_USER ) )
						fireworks_spawn( pPlayer, "firework_rc", "abcdefsz", Color() );
					else
						g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "[FIRE] You cannot spawn more.\n" );

					break;	
				}
				case 3:
				{
					if ( check_fireworks( pPlayer, MODE_USER ) )
						fireworks_spawn( pPlayer, "firework_rv", "abcdefsz", Color() );
					else
						g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "[FIRE] You cannot spawn more.\n" );

					break;	
				}		
				case 4:
				{
					if ( g_Engine.time - m_flWaitTime < FIRE_WAIT_TIME )
					{
						g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "[FIRE] You must wait " + formatFloat( FIRE_WAIT_TIME - ( g_Engine.time - m_flWaitTime ), "", 0, 1 ) + " seconds before fire again.\n" );
						break;
					}
			
					m_flWaitTime = g_Engine.time;

					shoot_firework( pPlayer );
					break;
				}
				case 5:
				{
					if ( check_fireworks( pPlayer, MODE_UNLIMIT ) )
						shooter_spawn( pPlayer, 5.0, 5, Color(), "abcdz" );
					else
					{
						//g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "[FIRE] You cannot spawn shooters.\n" );
						
						if ( FindShooters( pPlayer ) )
							g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "[FIRE] You cannot spawn more.\n" );
						else
						{
							float time = Math.RandomFloat( 2.0, 7.0 );
							int shots = Math.RandomLong( 4, 10 );
							shooter_spawn( pPlayer, time, shots, Color(), "abcdz" );
						}
					}

					break;
				}
				case 6: remove_fireworks( pPlayer ); break;
				case 7: remove_shooters( pPlayer ); break;
				
				//case 8: g_EngineFuncs.SetView( pPlayer.edict(), pPlayer.edict() ); break;
			}
			
			if ( iSlot <= 8 )
			{
				if ( IsPlayerAdmin( pPlayer ) ) m_iAmount = g_pCVarAdminMaxCount.GetInt();
				else m_iAmount = g_pCVarMaxCount.GetInt();

				m_pMenu.SetTitle( "Fireworks Menu: (" + g_pIntPlayerFireworks[ pPlayer.entindex() ] + " of " + m_iAmount + ")\n" );
				m_pMenu.Open( 0, 0, pPlayer );
			}
		}
	}
}

HookReturnCode ClientPutInServer( CBasePlayer@ pPlayer )
{
	if ( pPlayer is null || ( pPlayer.pev.flags & FL_FAKECLIENT ) != 0 )
		return HOOK_CONTINUE;
		
	int iPlayer = pPlayer.entindex();

	g_pIntPlayerFireworks[iPlayer] = 0;
	g_pBoolAllowedFireworks[iPlayer] = false;
	
//	set_task( 17.0, "display_info", id )
	
	return HOOK_CONTINUE;
}

HookReturnCode ClientDisconnect( CBasePlayer@ pPlayer )
{
	if ( pPlayer is null )
		return HOOK_CONTINUE;
		
	remove_fireworks( pPlayer );

	return HOOK_CONTINUE;
}

/*
void display_info(id)
{
	client_print( id, print_chat, "Simply say 'fireworks' to open the fireworks menu" )
}
*/
HookReturnCode ClientSay( SayParameters@ pParams )
{
	const CCommand@ pArguments = pParams.GetArguments();

	if ( pArguments.ArgC() >= 1 )
	{
		string szArg = pArguments.Arg( 0 );
		szArg.Trim();

		CBasePlayer@ pPlayer = pParams.GetPlayer();

		if ( pPlayer is null || !pPlayer.IsConnected() )
			return HOOK_CONTINUE;
	
		if ( szArg.ICompare( "fireworks" ) == 0 )
		{		
			g_FireworksMenu.Show( pPlayer );

		//	if ( check_fireworks( pPlayer, MODE_USER ) )
		//	{
			pParams.ShouldHide = true;
				
			return HOOK_HANDLED;
		//	}
		}	
		else if ( szArg.ICompare( "resetview" ) == 0 )
		{
			g_EngineFuncs.SetView( pPlayer.edict(), pPlayer.edict() );

			pParams.ShouldHide = true;
				
			return HOOK_HANDLED;
		}
	}

	return HOOK_CONTINUE;
}

void CmdChangeLights( const CCommand@ args )
{ 
	string szVal = args.Arg( 1 );
	szVal.Trim();

	g_EngineFuncs.LightStyle( 0, szVal );

	// These make it so that players/weaponmodels look like whatever the lighting is
	// at. otherwise it would color players under the skybox to these values.
	g_EngineFuncs.ServerCommand( "sv_skycolor_r 0\n" );
	g_EngineFuncs.ServerCommand( "sv_skycolor_g 0\n" );
	g_EngineFuncs.ServerCommand( "sv_skycolor_b 0\n" );
	g_EngineFuncs.ServerExecute();

	g_EngineFuncs.ServerPrint( "[AS] Light Change Successful.\n" );
}

bool IsPlayerAdmin( CBasePlayer@ pPlayer )
{
	return g_PlayerFuncs.AdminLevel( pPlayer ) >= ADMIN_YES;
}

int FloatRound( float fA )
{
	return int( floor( fA + 0.5 ) );
}

int UTIL_ReadFlags( const string& in s ) 
{
	char c;
	int flags = 0;
	
	for ( uint i = 0; i < s.Length(); i++ )
	{
		c = s[i];
		if ( !isalpha( c ) )
			continue;
		
		flags |= ( 1 << c.opImplConv() - 97 );
	}
	
	return flags;
}

