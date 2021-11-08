// Afraid of Monsters: Director's Cut Script
// Misc Script: Weaponmaker
// Author: Zorbos

class weaponmaker : ScriptBaseEntity
{
	string m_iszWeaponToSpawn = ""; // The weapon to spawn
	
	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if ( szKey == "m_iszWeaponToSpawn" )
		{
			m_iszWeaponToSpawn = szValue;
			return true;
		}
		else
			return BaseClass.KeyValue( szKey, szValue );
	}

	void Spawn()
	{
		self.pev.movetype = MOVETYPE_NONE;
		self.pev.solid = SOLID_NOT;

		self.pev.message = string_t( m_iszWeaponToSpawn );
	}
	
	void OnCreate()
	{
		self.pev.nextthink = g_Engine.time;
	}
	
	void Use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue = 0.0f )
	{
		CBaseEntity@ pEntity = g_EntityFuncs.Create( self.pev.message, self.GetOrigin(), self.pev.angles, true );
		
		if ( pEntity is null )
			return;
		
		edict_t@ pEdict = pEntity.edict();
		g_EntityFuncs.DispatchKeyValue( pEdict, "targetname", "weapon_spawn" );
		g_EntityFuncs.DispatchSpawn( pEdict );
	}
}
