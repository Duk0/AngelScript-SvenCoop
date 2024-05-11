/*
QUAKED light_torch_small_walltorch (0 .5 0) (-10 -10 -20) (10 10 20)
Short wall torch
Default light value is 200
Default style is 0
*/
class CLightTorch : ScriptBaseAnimating
{
	void Precache()
	{
		BaseClass.Precache();

		g_Game.PrecacheModel( "models/quake1/flame1.mdl" );
		g_SoundSystem.PrecacheSound( "quake1/ambience/fire1.wav" );

	//	UTIL_EmitAmbientSound( ENT(pev), pev->origin, "ambience/fire1.wav", 0.5, ATTN_STATIC, SND_SPAWNING, 100 );
		g_SoundSystem.EmitAmbientSound( self.edict(), self.pev.origin, "quake1/ambience/fire1.wav", 0.3, ATTN_STATIC, SND_FORCE_LOOP, PITCH_NORM );
	}

	void Spawn()
	{
		Precache();
/*
		// g-cont. use STUDIO_NF_FULLBRIGHT here because body of torch must be shaded
		if ( g_fXashEngine )
		{
			// NOTE: this has effect only in Xash3D
			pev.effects = EF_FULLBRIGHT;
		}
*/
		g_EntityFuncs.SetModel( self, "models/quake1/flame1.mdl" );
		
		self.pev.solid = SOLID_NOT;

		// run animation
		self.pev.framerate = Math.RandomFloat( 0.45, 0.55 ); // DMC models have too fast sequence
		self.pev.nextthink = g_Engine.time + Math.RandomFloat( 0.0f, 0.2f );
	}
}

void q1_RegisterLightTorch()
{
	g_Game.PrecacheModel( "models/quake1/flame1.mdl" );
	g_SoundSystem.PrecacheSound( "quake1/ambience/fire1.wav" );

	g_CustomEntityFuncs.RegisterCustomEntity( "CLightTorch", "light_torch_small_walltorch" );
}
