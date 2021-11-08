// Afraid of Monsters: Director's Cut Script
// Monster Script: Hellhound
// Author: Zorbos

namespace AOMHellhound
{
// Monster events
enum HELLHOUND_AE
{
	HELLHOUND_AE_WARN = 1,
	HELLHOUND_AE_STARTATTACK,
	HELLHOUND_AE_THUMP,
	HELLHOUND_AE_ANGERSOUND1,
	HELLHOUND_AE_ANGERSOUND2,
	HELLHOUND_AE_HOPBACK,
	HELLHOUND_AE_CLOSEEYE,
};

// Behavior modifiers
const float HELLHOUND_MOD_ATKRADIUS = 512.0;
const float HELLHOUND_MOD_DMG_BLAST = 10.0;
const float HELLHOUND_MOD_HEALTH = 100.0;
const float HELLHOUND_MOD_MOVESPEED = 320.0;

const float HELLHOUND_MOD_DMG_BLAST_SURVIVAL = 20.0;
const float HELLHOUND_MOD_HEALTH_SURVIVAL = 135.0;
const float HELLHOUND_MOD_MOVESPEED_SURVIVAL = 350.0;


class CMonsterHellhound : ScriptBaseMonsterEntity
{
	private int m_iSpriteTexture;
	private float m_flBlastDamage;
	private bool bSurvivalEnabled = g_SurvivalMode.MapSupportEnabled() && g_SurvivalMode.IsEnabled();
	
	void Precache()
	{
		BaseClass.Precache();

		g_Game.PrecacheModel("models/AoMDC/monsters/hellhound/hellhound.mdl");

		g_SoundSystem.PrecacheSound("AoMDC/monsters/hellhound/he_alert1.wav");
		g_SoundSystem.PrecacheSound("AoMDC/monsters/hellhound/he_alert2.wav");
		g_SoundSystem.PrecacheSound("AoMDC/monsters/hellhound/he_pain1.wav");
		g_SoundSystem.PrecacheSound("AoMDC/monsters/hellhound/he_pain2.wav");
		g_SoundSystem.PrecacheSound("AoMDC/monsters/hellhound/he_blast1.wav");
		g_SoundSystem.PrecacheSound("AoMDC/monsters/hellhound/he_blast2.wav");
		g_SoundSystem.PrecacheSound("AoMDC/monsters/hellhound/he_blast3.wav");
		g_SoundSystem.PrecacheSound("AoMDC/monsters/hellhound/he_die1.wav");
		g_SoundSystem.PrecacheSound("AoMDC/monsters/hellhound/he_die2.wav");
		g_SoundSystem.PrecacheSound("AoMDC/monsters/hellhound/he_die3.wav");
		g_SoundSystem.PrecacheSound("blackdog/dog_run.wav");
		
		m_iSpriteTexture = g_Game.PrecacheModel("sprites/shockwave.spr");
	}
	
	void Spawn()
	{
		Precache();

		if( !self.SetupModel() )
			g_EntityFuncs.SetModel( self, "models/AoMDC/monsters/hellhound/hellhound.mdl" );
			
		g_EntityFuncs.SetSize(self.pev, Vector(-16, -16, 0), Vector(16, 16, 36));
	
		if(bSurvivalEnabled)
			self.pev.health = HELLHOUND_MOD_HEALTH_SURVIVAL;
		else
			self.pev.health = HELLHOUND_MOD_HEALTH;
	
		pev.solid					= SOLID_SLIDEBOX;
		pev.movetype				= MOVETYPE_STEP;
		self.m_bloodColor			= BLOOD_COLOR_RED;
		self.m_flFieldOfView		= 0.5;
		self.m_MonsterState			= MONSTERSTATE_NONE;
		self.m_afCapability			= bits_CAP_DOORS_GROUP;
		
		self.m_FormattedName		= "Hellhound";

		self.MonsterInit();
	}
	
	int	Classify()
	{
		return self.GetClassification( CLASS_ALIEN_MONSTER );
	}
	
	void SetYawSpeed()
	{
		if(bSurvivalEnabled)
			self.pev.yaw_speed = HELLHOUND_MOD_MOVESPEED_SURVIVAL;
		else
			self.pev.yaw_speed = HELLHOUND_MOD_MOVESPEED;
	}
	
	void Killed(entvars_t@ pevAttacker, int iGib)
	{
		BaseClass.Killed(pevAttacker, iGib);
	}
	
	void DeathSound()
	{
		switch(Math.RandomLong(0,2))
		{
			case 0:
				g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "AoMDC/monsters/hellhound/he_die1.wav", 1, ATTN_NORM, 0, PITCH_NORM );
				break;
			case 1:
				g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "AoMDC/monsters/hellhound/he_die2.wav", 1, ATTN_NORM, 0, PITCH_NORM );
				break;
			case 2:
				g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "AoMDC/monsters/hellhound/he_die3.wav", 1, ATTN_NORM, 0, PITCH_NORM );
				break;
		}		
	}
	
	void PainSound()
	{	
		switch(Math.RandomLong(0,2))
		{
			case 0:
				g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "AoMDC/monsters/hellhound/he_pain1.wav", 1, ATTN_NORM, 0, PITCH_NORM );
				break;
			case 1:
				g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "AoMDC/monsters/hellhound/he_pain2.wav", 1, ATTN_NORM, 0, PITCH_NORM );
				break;
		}		
	}
	
	void AlertSound()
	{	
		switch(Math.RandomLong(0,1))
		{
			case 0:
				g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "AoMDC/monsters/hellhound/he_alert1.wav", 1, ATTN_NORM, 0, PITCH_NORM );
				break;
			case 1:
				g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "AoMDC/monsters/hellhound/he_alert2.wav", 1, ATTN_NORM, 0, PITCH_NORM );
				break;
		}		
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
	
	bool CheckRangeAttack1(float flDot, float flDist)
	{	
		if(flDist <= (HELLHOUND_MOD_ATKRADIUS * 0.5) && flDot >= 0.3)
			return true;
	
		return false;
	}

	void SonicAttack()
	{
		float flDist;
		
		switch(Math.RandomLong(0, 2))
		{
			case 0:
				g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, "AoMDC/monsters/hellhound/he_blast1.wav", 1, ATTN_NORM, 0, PITCH_NORM );
				break;
			case 1:
				g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, "AoMDC/monsters/hellhound/he_blast2.wav", 1, ATTN_NORM, 0, PITCH_NORM );
				break;
			case 2:
				g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, "AoMDC/monsters/hellhound/he_blast3.wav", 1, ATTN_NORM, 0, PITCH_NORM );
				break;				
		}
		
		NetworkMessage message( MSG_PAS, NetworkMessages::SVC_TEMPENTITY, self.pev.origin );
			message.WriteByte(TE_BEAMCYLINDER);
			message.WriteCoord(self.pev.origin.x);
			message.WriteCoord(self.pev.origin.y);
			message.WriteCoord(self.pev.origin.z + 16);
			message.WriteCoord(self.pev.origin.x);
			message.WriteCoord(self.pev.origin.y);
			message.WriteCoord(self.pev.origin.z + 16 + HELLHOUND_MOD_ATKRADIUS / 0.2);
			
			// Shockwave Sprite
			message.WriteShort(m_iSpriteTexture);
			message.WriteByte(0); // Start frame
			message.WriteByte(0); // Framerate
			message.WriteByte(2); // Life
			message.WriteByte(64); // Width
			message.WriteByte(0); // Noise
			
			// Shockwave Color
			message.WriteByte(255); // R
			message.WriteByte(0); // G
			message.WriteByte(0); // B
			
			message.WriteByte(255); // Brightness
			message.WriteByte(0); // Speed
		message.End();
		
		CBaseEntity@ pEntity = null;
		
		if(bSurvivalEnabled)
			m_flBlastDamage = HELLHOUND_MOD_DMG_BLAST_SURVIVAL;
		else
			m_flBlastDamage = HELLHOUND_MOD_DMG_BLAST;
		
		// Find PLAYERS ONLY in the radius and hurt them
		while((@pEntity = g_EntityFuncs.FindEntityInSphere(pEntity, self.pev.origin, HELLHOUND_MOD_ATKRADIUS, "player", "classname")) !is null)
		{
			CBasePlayer@ pPlayer = cast<CBasePlayer@>(pEntity);
			pPlayer.TakeDamage(self.pev, self.pev, m_flBlastDamage, DMG_SONIC | DMG_ALWAYSGIB);
		}
	}
	
	void HandleAnimEvent(MonsterEvent@ pEvent)
	{		
		switch(pEvent.event)
		{
			case HELLHOUND_AE_WARN:
				break;
			case HELLHOUND_AE_STARTATTACK:
				break;
			case HELLHOUND_AE_HOPBACK:
				break;
			case HELLHOUND_AE_THUMP:
				SonicAttack(); // Emit the shockwaves
				break;
			case HELLHOUND_AE_ANGERSOUND1:
				g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "AoMDC/monsters/hellhound/he_pain1.wav", 1, ATTN_NORM, 0, PITCH_NORM );
				break;
			case HELLHOUND_AE_ANGERSOUND2:
				g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "AoMDC/monsters/hellhound/he_pain2.wav", 1, ATTN_NORM, 0, PITCH_NORM );
				break;
			case HELLHOUND_AE_CLOSEEYE:
				break;
			default:
				BaseClass.HandleAnimEvent(pEvent);
		}
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity("AOMHellhound::CMonsterHellhound", "monster_hellhound");
}
} // end namespace