// Afraid of Monsters: Director's Cut Script
// Monster Script: Ghost
// Author: Zorbos

namespace AOMGhost
{
// Monster events
const int GHOST_AE_ATTACK = 1;

// Behavior modifiers
const float GHOST_MOD_HEALTH = 150.0;
const float GHOST_MOD_MOVESPEED = 325.0;
const int GHOST_MOD_DMG_INIT = 2; // Initial damage
const int GHOST_MOD_DMG_TICK = 3; // Damage per DoT tick

const float GHOST_MOD_HEALTH_SURVIVAL = 225.0;
const float GHOST_MOD_MOVESPEED_SURVIVAL = 400.0;
const int GHOST_MOD_DMG_INIT_SURVIVAL = 5; // Initial damage
const int GHOST_MOD_DMG_TICK_SURVIVAL = 4; // Damage per DoT tick

class CMonsterGhost : ScriptBaseMonsterEntity
{
	private float m_flNextAttack = 0;
	private float m_flDmgInit, m_flDmgTick;
	private bool bSurvivalEnabled = g_SurvivalMode.MapSupportEnabled() && g_SurvivalMode.IsEnabled();
	CScheduledFunction@ interval;
	
	void Precache()
	{
		BaseClass.Precache();

		g_Game.PrecacheModel("models/AoMDC/monsters/ghost/ghost.mdl");

		g_SoundSystem.PrecacheSound("AoMDC/monsters/ghost/ear_ringing.wav");
		g_SoundSystem.PrecacheSound("AoMDC/monsters/ghost/slv_alert2.wav");
		g_SoundSystem.PrecacheSound("AoMDC/monsters/ghost/slv_die.wav");
	}
	
	void Spawn()
	{
		Precache();

		if( !self.SetupModel() )
			g_EntityFuncs.SetModel( self, "models/AoMDC/monsters/ghost/ghost.mdl" );
			
		g_EntityFuncs.SetSize( self.pev, VEC_HUMAN_HULL_MIN, VEC_HUMAN_HULL_MAX );
	
		if(bSurvivalEnabled)
			self.pev.health = GHOST_MOD_HEALTH_SURVIVAL;
		else
			self.pev.health = GHOST_MOD_HEALTH;
	
		pev.solid					= SOLID_SLIDEBOX;
		pev.movetype				= MOVETYPE_STEP;
		self.m_bloodColor			= BLOOD_COLOR_RED;
		self.pev.health				= GHOST_MOD_HEALTH;
		self.pev.view_ofs			= Vector( 0, 0, 80 );
		self.m_flFieldOfView		= 0.8;
		self.m_MonsterState			= MONSTERSTATE_NONE;
		self.m_afCapability			= bits_CAP_DOORS_GROUP;
		
		self.m_FormattedName		= "Ghost";

		self.MonsterInit();
	}
	
	int	Classify()
	{
		return self.GetClassification( CLASS_ALIEN_MONSTER );
	}
	
	void SetYawSpeed()
	{
		if(bSurvivalEnabled)
			self.pev.yaw_speed = GHOST_MOD_MOVESPEED_SURVIVAL;
		else
			self.pev.yaw_speed = GHOST_MOD_MOVESPEED;
	}
	
	void DeathSound()
	{
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "AoMDC/monsters/ghost/slv_die.wav", 1, ATTN_NORM, 0, PITCH_NORM );
	}
	
	void Killed(entvars_t@ pevAttacker, int iGib)
	{
		BaseClass.Killed(pevAttacker, iGib);
	}
	
	void AlertSound()
	{	
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "AoMDC/monsters/ghost/slv_alert2.wav", 1, ATTN_NORM, 0, PITCH_NORM );
	
	}
	
	int TakeDamage( entvars_t@ pevInflictor, entvars_t@ pevAttacker, float flDamage, int bitsDamageType)
	{	
		if( FNullEnt(pevAttacker) )
			return 0;

		CBaseEntity@ pAttacker = g_EntityFuncs.Instance( pevAttacker );

		if(pAttacker is null || self.CheckAttacker( pAttacker ))
			return 0;

		return BaseClass.TakeDamage(pevInflictor, pevAttacker, flDamage, bitsDamageType);
	}
	
	CBaseEntity@ initAttack()
	{
		TraceResult tr;

		Math.MakeVectors(pev.angles);
		Vector vecStart = pev.origin;
		vecStart.z += pev.size.z * 0.5;
		Vector vecEnd = vecStart + (g_Engine.v_forward * 64);

		g_Utility.TraceHull(vecStart, vecEnd, dont_ignore_monsters, head_hull, self.edict(), tr);
		
		if ( !FNullEnt( tr.pHit ) && g_EntityFuncs.IsValidEntity( tr.pHit ) )
		{
			return g_EntityFuncs.Instance(tr.pHit);
		}

		return null;
	}	
	
	bool CheckMeleeAttack1( float flDot, float flDist )
	{
		CBaseMonster@ pEnemy;

		if(self.m_hEnemy.IsValid())
		{
			@pEnemy = self.m_hEnemy.GetEntity().MyMonsterPointer();

			if (pEnemy is null)
				return false;
		}

		if(flDist <= 64 && flDot >= 0.7)
			return true;
			
		return false;
	}
	
	bool CheckRangeAttack1(float flDot, float flDist)
	{	
		return false;
	}
	
	bool CheckRangeAttack2(float flDot, float flDist)
	{	
		return false;
	}
	
	void RingEars(CBasePlayer@ pPlayer)
	{	
		g_SoundSystem.PlaySound(pPlayer.edict(), CHAN_STATIC, "AoMDC/monsters/ghost/ear_ringing.wav", 0.65f, 1.0f, 0, 100, pPlayer.entindex());
		g_PlayerFuncs.ScreenFade(pPlayer, Vector(150, 0, 0), 2, 12, 255, FFADE_MODULATE | FFADE_IN);
	}
	
	void RingEarsTick(CBasePlayer@ pPlayer)
	{
		if(bSurvivalEnabled)
			m_flDmgTick = GHOST_MOD_DMG_TICK_SURVIVAL;
		else
			m_flDmgTick = GHOST_MOD_DMG_TICK;
			
		pPlayer.TakeDamage(pev, pev, m_flDmgTick, DMG_CLUB);
	}
	
	void HandleAnimEvent(MonsterEvent@ pEvent)
	{
		if(g_Engine.time < m_flNextAttack)
			return;
			
		if(pEvent.event == GHOST_AE_ATTACK)
		{
			CBaseEntity@ pHurt = initAttack();
			CBasePlayer@ pPlayer = cast<CBasePlayer@>(pHurt);
			
			if (pPlayer !is null)
			{
				if(bSurvivalEnabled)
					m_flDmgInit = GHOST_MOD_DMG_INIT_SURVIVAL;
				else
					m_flDmgInit = GHOST_MOD_DMG_INIT;
					
				Math.MakeVectors(pev.angles);
				pPlayer.pev.punchangle.x = 20;
				pPlayer.TakeDamage(pev, pev, m_flDmgInit, DMG_CLUB);
				@interval = g_Scheduler.SetInterval(@this, "RingEarsTick", 2, 6, @pPlayer);
				
				m_flNextAttack = g_Engine.time + 13;
				RingEars(pPlayer);	
			}
		}
		else
			BaseClass.HandleAnimEvent(pEvent);
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "AOMGhost::CMonsterGhost", "monster_ghost" );
}
} // end namespace