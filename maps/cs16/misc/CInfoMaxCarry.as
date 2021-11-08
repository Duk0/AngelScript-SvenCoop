
namespace CS16_MAXCARRY
{

string ENTITY_NAME  	= "info_max_carry";

class CInfoMaxCarry : ScriptBaseEntity
{
	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if ( szKey == "m249" )
		{
			CS16_M249::MAX_CARRY = Math.clamp( 1, 9999, atoi( szValue ) );
			return true;
		}
		else if ( szKey == "deagle" )
		{
			CS16_DEAGLE::MAX_CARRY = Math.clamp( 1, 9999, atoi( szValue ) );
			return true;
		}
		else if ( szKey == "glock18" )
		{
			CS16_GLOCK18::MAX_CARRY = Math.clamp( 1, 9999, atoi( szValue ) );
			return true;
		}
		else if ( szKey == "elites" )
		{
			CS16_ELITES::MAX_CARRY = Math.clamp( 1, 9999, atoi( szValue ) );
			return true;
		}
		else if ( szKey == "57" )
		{
			CS16_57::MAX_CARRY = Math.clamp( 1, 9999, atoi( szValue ) );
			return true;
		}
		else if ( szKey == "p228" )
		{
			CS16_P228::MAX_CARRY = Math.clamp( 1, 9999, atoi( szValue ) );
			return true;
		}
		else if ( szKey == "usp" )
		{
			CS16_USP::MAX_CARRY = Math.clamp( 1, 9999, atoi( szValue ) );
			return true;
		}
		else if ( szKey == "ak47" )
		{
			CS16_AK47::MAX_CARRY = Math.clamp( 1, 9999, atoi( szValue ) );
			return true;
		}
		else if ( szKey == "aug" )
		{
			CS16_AUG::MAX_CARRY = Math.clamp( 1, 9999, atoi( szValue ) );
			return true;
		}
		else if ( szKey == "famas" )
		{
			CS16_FAMAS::MAX_CARRY = Math.clamp( 1, 9999, atoi( szValue ) );
			return true;
		}
		else if ( szKey == "galil" )
		{
			CS16_GALIL::MAX_CARRY = Math.clamp( 1, 9999, atoi( szValue ) );
			return true;
		}
		else if ( szKey == "m4a1" )
		{
			CS16_M4A1::MAX_CARRY = Math.clamp( 1, 9999, atoi( szValue ) );
			return true;
		}
		else if ( szKey == "sg552" )
		{
			CS16_SG552::MAX_CARRY = Math.clamp( 1, 9999, atoi( szValue ) );
			return true;
		}
		else if ( szKey == "m3" )
		{
			CS16_M3::MAX_CARRY = Math.clamp( 1, 9999, atoi( szValue ) );
			return true;
		}
		else if ( szKey == "xm1014" )
		{
			CS16_XM1014::MAX_CARRY = Math.clamp( 1, 9999, atoi( szValue ) );
			return true;
		}
		else if ( szKey == "mac10" )
		{
			CS16_MAC10::MAX_CARRY = Math.clamp( 1, 9999, atoi( szValue ) );
			return true;
		}
		else if ( szKey == "mp5" )
		{
			CS16_MP5::MAX_CARRY = Math.clamp( 1, 9999, atoi( szValue ) );
			return true;
		}
		else if ( szKey == "p90" )
		{
			CS16_P90::MAX_CARRY = Math.clamp( 1, 9999, atoi( szValue ) );
			return true;
		}
		else if ( szKey == "tmp" )
		{
			CS16_TMP::MAX_CARRY = Math.clamp( 1, 9999, atoi( szValue ) );
			return true;
		}
		else if ( szKey == "ump45" )
		{
			CS16_UMP45::MAX_CARRY = Math.clamp( 1, 9999, atoi( szValue ) );
			return true;
		}
		else if ( szKey == "awp" )
		{
			CS16_AWP::MAX_CARRY = Math.clamp( 1, 9999, atoi( szValue ) );
			return true;
		}
		else if ( szKey == "g3sg1" )
		{
			CS16_G3SG1::MAX_CARRY = Math.clamp( 1, 9999, atoi( szValue ) );
			return true;
		}
		else if ( szKey == "scout" )
		{
			CS16_SCOUT::MAX_CARRY = Math.clamp( 1, 9999, atoi( szValue ) );
			return true;
		}
		else if ( szKey == "sg550" )
		{
			CS16_SG550::MAX_CARRY = Math.clamp( 1, 9999, atoi( szValue ) );
			return true;
		}
		else if ( szKey == "hegrenade" )
		{
			CS16_HEGRENADE::MAX_CARRY = Math.clamp( 1, 9999, atoi( szValue ) );
			return true;
		}
		else
			return BaseClass.KeyValue( szKey, szValue );
	}
}

void Register()
{
	if ( g_CustomEntityFuncs.IsCustomEntity( ENTITY_NAME ) )
		return;

	g_CustomEntityFuncs.RegisterCustomEntity( "CS16_MAXCARRY::CInfoMaxCarry", ENTITY_NAME );
}

}