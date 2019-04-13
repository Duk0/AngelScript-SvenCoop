
// The amount of ammo given to a player by an ammo item.
const int AMMO_GLOCKCLIP_GIVE		= 17;
const int AMMO_357BOX_GIVE			= 6;
const int AMMO_MP5CLIP_GIVE		= 30;
const int AMMO_CHAINBOX_GIVE		= 200;
const int AMMO_M203BOX_GIVE		= 2;
const int AMMO_BUCKSHOTBOX_GIVE	= 12;
const int AMMO_CROSSBOWCLIP_GIVE	= 5;
const int AMMO_RPGCLIP_GIVE		= 2;
const int AMMO_URANIUMBOX_GIVE		= 20;
//const int AMMO_SNARKBOX_GIVE		= 5;
const int AMMO_556BOX_GIVE			= 100;
const int AMMO_M40A1CLIP_GIVE		= 5;
const int AMMO_UZICLIP_GIVE		= 32;

// AoM
const int AMMO_DEAGLE_GIVE			= 7;
const int AMMO_GLOCK_GIVE			= 20;
const int AMMO_MP5K_GIVE			= 30;
const int AMMO_REVOLVER_GIVE		= 6;
const int AMMO_SHOTGUN_GIVE		= 8;

// poke646
const int AMMO_NAIL_GIVE			= 25;
const int AMMO_NAILR_GIVE			= 50;
const int AMMO_PAR21_GIVE			= 30;
const int AMMO_PAR21GL_GIVE		= 2;

// quake1
const int Q1_AMMO_ENERGY_GIVE		= 10;
const int Q1_AMMO_NAILS_GIVE		= 50;
const int Q1_AMMO_ROCKETS_GIVE		= 10;
const int Q1_AMMO_SHELLS_GIVE		= 25;



CCVar@ g_pCvarAmmo, g_pCvar556, g_pCvarExpendables, g_pCvarHealth, g_pCvarArmor;

//int g_iAmmoMedkit;
int g_iAmmo9mm;
int g_iAmmo357;
int g_iAmmoShotgun;
int g_iAmmoCrossbow;
int g_iAmmo556;
int g_iAmmoARGrenade;
int g_iAmmoRPG;
int g_iAmmoUranium;
//int g_iAmmoHornetgun;
int g_iAmmoHandgrenade;
//int g_iAmmoSatchel;
//int g_iAmmoTripmine;
int g_iAmmoSnark;
int g_iAmmoSniperrifle;
//int g_iAmmoSpore;
//int g_iAmmoShock;


void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Avalanche|Duko" );
	g_Module.ScriptInfo.SetContactInfo( "group.midu.cz" );
	
	g_Hooks.RegisterHook( Hooks::PickupObject::CanCollect, @CanCollect );

	@g_pCvarAmmo = CCVar( "limit_ammo", 100 );
	@g_pCvar556 = CCVar( "limit_556", 90 );
	@g_pCvarExpendables = CCVar( "limit_expendables", 89 );
	@g_pCvarHealth = CCVar( "limit_health", 98 );
	@g_pCvarArmor = CCVar( "limit_armor", 95 );
	
	MapStart();
	
//	g_EngineFuncs.ServerPrint( "g_iAmmoMedkit: " + g_iAmmoMedkit + "\n" );
	g_EngineFuncs.ServerPrint( "g_iAmmo9mm: " + g_iAmmo9mm + "\n" );
	g_EngineFuncs.ServerPrint( "g_iAmmo357: " + g_iAmmo357 + "\n" );
	g_EngineFuncs.ServerPrint( "g_iAmmoShotgun: " + g_iAmmoShotgun + "\n" );
	g_EngineFuncs.ServerPrint( "g_iAmmoCrossbow: " + g_iAmmoCrossbow + "\n" );
	g_EngineFuncs.ServerPrint( "g_iAmmo556: " + g_iAmmo556 + "\n" );
	g_EngineFuncs.ServerPrint( "g_iAmmoARGrenade: " + g_iAmmoARGrenade + "\n" );
	g_EngineFuncs.ServerPrint( "g_iAmmoRPG: " + g_iAmmoRPG + "\n" );
	g_EngineFuncs.ServerPrint( "g_iAmmoUranium: " + g_iAmmoUranium + "\n" );
//	g_EngineFuncs.ServerPrint( "g_iAmmoHornetgun: " + g_iAmmoHornetgun + "\n" );
	g_EngineFuncs.ServerPrint( "g_iAmmoHandgrenade: " + g_iAmmoHandgrenade + "\n" );
//	g_EngineFuncs.ServerPrint( "g_iAmmoSatchel: " + g_iAmmoSatchel + "\n" );
//	g_EngineFuncs.ServerPrint( "g_iAmmoTripmine: " + g_iAmmoTripmine + "\n" );
	g_EngineFuncs.ServerPrint( "g_iAmmoSnark: " + g_iAmmoSnark + "\n" );
	g_EngineFuncs.ServerPrint( "g_iAmmoSniperrifle: " + g_iAmmoSniperrifle + "\n" );
//	g_EngineFuncs.ServerPrint( "g_iAmmoSpore: " + g_iAmmoSpore + "\n" );
//	g_EngineFuncs.ServerPrint( "g_iAmmoShock: " + g_iAmmoShock + "\n" );
}

void MapStart()
{
//	g_iAmmoMedkit = g_PlayerFuncs.GetAmmoIndex( "health" );
	g_iAmmo9mm = g_PlayerFuncs.GetAmmoIndex( "9mm" ); // ammo_9mmAR, ammo_9mmbox, ammo_9mmclip, ammo_glockclip, ammo_mp5clip
	g_iAmmo357 = g_PlayerFuncs.GetAmmoIndex( "357" ); // ammo_357
	g_iAmmoShotgun = g_PlayerFuncs.GetAmmoIndex( "buckshot" ); // ammo_buckshot
	g_iAmmoCrossbow = g_PlayerFuncs.GetAmmoIndex( "bolts" ); // ammo_crossbow
	g_iAmmo556 = g_PlayerFuncs.GetAmmoIndex( "556" ); // ammo_556
	g_iAmmoARGrenade = g_PlayerFuncs.GetAmmoIndex( "argrenades" ); // ammo_ARgrenades, ammo_mp5grenades
	g_iAmmoRPG = g_PlayerFuncs.GetAmmoIndex( "rockets" ); // ammo_rpgclip
	g_iAmmoUranium = g_PlayerFuncs.GetAmmoIndex( "uranium" ); // ammo_egonclip, ammo_gaussclip
//	g_iAmmoHornetgun = g_PlayerFuncs.GetAmmoIndex( "hornets" );
	g_iAmmoHandgrenade = g_PlayerFuncs.GetAmmoIndex( "hand grenade" );
//	g_iAmmoSatchel = g_PlayerFuncs.GetAmmoIndex( "satchel charge" );
//	g_iAmmoTripmine = g_PlayerFuncs.GetAmmoIndex( "trip mine" );
	g_iAmmoSnark = g_PlayerFuncs.GetAmmoIndex( "snarks" );
	g_iAmmoSniperrifle = g_PlayerFuncs.GetAmmoIndex( "m40a1" ); // ammo_762
//	g_iAmmoSpore = g_PlayerFuncs.GetAmmoIndex( "sporeclip" ); // ammo_spore, ammo_sporeclip
//	g_iAmmoShock = g_PlayerFuncs.GetAmmoIndex( "shock charges" );
}

HookReturnCode CanCollect( CBaseEntity@ pPickup, CBaseEntity@ pOther, bool& out bResult )
{
	if ( pPickup is null || pOther is null )
		return HOOK_CONTINUE;

	CBasePlayer@ pPlayer = cast<CBasePlayer@>( pOther );

	if ( pPlayer is null || !pPlayer.IsAlive() )
		return HOOK_CONTINUE;

	string szClassname = pPickup.GetClassname();

	if ( szClassname.CompareN( "ammo_", 5 ) == 0 )
	{
		float flAmmoLimit = g_pCvarAmmo.GetFloat();
		if ( flAmmoLimit <= 0.0 ) return HOOK_CONTINUE;

		int iAmmoId = -1, iAmmoGive = 0;
		switch ( szClassname[5].opImplConv() )
		{
			case 51: iAmmoId = g_iAmmo357; iAmmoGive = AMMO_357BOX_GIVE; break; // ammo_357
			case 53:
			{
				flAmmoLimit = g_pCvar556.GetFloat();
				if ( flAmmoLimit <= 0.0 ) return HOOK_CONTINUE;

				iAmmoId = g_iAmmo556; iAmmoGive = AMMO_556BOX_GIVE; break; // ammo_556
			}
			case 55: iAmmoId = g_iAmmoSniperrifle; iAmmoGive = AMMO_M40A1CLIP_GIVE; break; // ammo_762
			case 57:
			{
				iAmmoId = g_iAmmo9mm; 

				switch ( szClassname[8].opImplConv() )
				{
					case 65: iAmmoGive = AMMO_MP5CLIP_GIVE; break; // ammo_9mmAR
					case 98: iAmmoGive = AMMO_CHAINBOX_GIVE; break; // ammo_9mmbox
					case 99: iAmmoGive = AMMO_GLOCKCLIP_GIVE; break; // ammo_9mmclip
				}

				break;
			}
			case 97:
			{
				if ( szClassname[7] != 'g' ) return HOOK_CONTINUE;

				iAmmoId = g_iAmmoARGrenade; iAmmoGive = AMMO_M203BOX_GIVE; break; // ammo_ARgrenades
			}
			case 98:
			{
				if ( szClassname[6] != 'u' ) return HOOK_CONTINUE;

				iAmmoId = g_iAmmoShotgun; iAmmoGive = AMMO_BUCKSHOTBOX_GIVE; break; // ammo_buckshot
			}
			case 99:
			{
				switch ( szClassname[6].opImplConv() )
				{
					case 108: iAmmoId = g_iAmmoShotgun; iAmmoGive = AMMO_SHOTGUN_GIVE; break; // ammo_clshotgun
					case 114: iAmmoId = g_iAmmoCrossbow; iAmmoGive = AMMO_CROSSBOWCLIP_GIVE; break; // ammo_crossbow
				}
				
				break;
			}
			case 100:
			{
				if ( szClassname[6] != 'c' ) return HOOK_CONTINUE;

				switch ( szClassname[7].opImplConv() )
				{
					case 100: iAmmoId = g_iAmmo357; iAmmoGive = AMMO_DEAGLE_GIVE; break; // ammo_dcdeagle
					case 103: iAmmoId = g_iAmmo9mm; iAmmoGive = AMMO_GLOCK_GIVE; break; // ammo_dcglock
					case 109: iAmmoId = g_iAmmo556; iAmmoGive = AMMO_MP5K_GIVE; break; // ammo_dcmp5k
					case 114: iAmmoId = g_iAmmoSniperrifle; iAmmoGive = AMMO_REVOLVER_GIVE; break; // ammo_dcrevolver
					case 115: iAmmoId = g_iAmmoShotgun; iAmmoGive = AMMO_SHOTGUN_GIVE; break; // ammo_dcshotgun
				}
				
				break;
			}
			case 101: iAmmoId = g_iAmmoUranium; iAmmoGive = AMMO_URANIUMBOX_GIVE; break; // ammo_egonclip
			case 103:
			{
				switch ( szClassname[6].opImplConv() )
				{
					case 97: iAmmoId = g_iAmmoUranium; iAmmoGive = AMMO_URANIUMBOX_GIVE; break; // ammo_gaussclip
					case 108:
					{
						if ( szClassname[7] != 'o' ) return HOOK_CONTINUE;

						iAmmoId = g_iAmmo9mm; iAmmoGive = AMMO_GLOCKCLIP_GIVE; break; // ammo_glockclip
					}
				}
				
				break;
			}
			case 109:
			{
				switch ( szClassname[8].opImplConv() )
				{
					case 99: iAmmoId = g_iAmmo9mm; iAmmoGive = AMMO_MP5CLIP_GIVE; break; // ammo_mp5clip
					case 103: iAmmoId = g_iAmmoARGrenade; iAmmoGive = AMMO_M203BOX_GIVE; break; // ammo_mp5grenades
				}

				break;
			}
			case 110:
			{
				switch ( szClassname[9].opImplConv() )
				{
					case 99: iAmmoId = g_iAmmo9mm; iAmmoGive = AMMO_NAIL_GIVE; break; // ammo_nailclip
					case 114: iAmmoId = g_iAmmoARGrenade; iAmmoGive = AMMO_NAILR_GIVE; break; // ammo_nailround
				}

				break;
			}
			case 112:
			{
				switch ( szClassname[11].opImplConv() )
				{
					case 99: iAmmoId = g_iAmmo9mm; iAmmoGive = AMMO_PAR21_GIVE; break; // ammo_par21_clip
					case 114: iAmmoId = g_iAmmo9mm; iAmmoGive = AMMO_PAR21GL_GIVE; break; // ammo_par21_grenades
				}

				break;
			}
			case 113:
			{
				switch ( szClassname[6].opImplConv() )
				{
					case 101: iAmmoId = g_iAmmoUranium; iAmmoGive = Q1_AMMO_ENERGY_GIVE; break; // ammo_qenergy
					case 110: iAmmoId = g_iAmmoCrossbow; iAmmoGive = Q1_AMMO_NAILS_GIVE; break; // ammo_qnails
					case 114: iAmmoId = g_iAmmoRPG; iAmmoGive = Q1_AMMO_ROCKETS_GIVE; break; // ammo_qrockets
					case 115: iAmmoId = g_iAmmoShotgun; iAmmoGive = Q1_AMMO_SHELLS_GIVE; break; // ammo_qshells
				}
				
				break;
			}
			case 114: iAmmoId = g_iAmmoRPG; iAmmoGive = AMMO_RPGCLIP_GIVE; break; // ammo_rpgclip
			case 117: iAmmoId = g_iAmmo9mm; iAmmoGive = AMMO_UZICLIP_GIVE; break; // ammo_uziclip
			default: return HOOK_CONTINUE;
		}

		if ( iAmmoId == -1 ) return HOOK_CONTINUE;

	//	if ( float( pPlayer.AmmoInventory( iAmmoId ) ) > ( flAmmoLimit / 100 ) * float( pPlayer.GetMaxAmmo( iAmmoId ) ) )
		if ( flAmmoLimit > 99 ? pPlayer.AmmoInventory( iAmmoId ) + iAmmoGive > pPlayer.GetMaxAmmo( iAmmoId ) : float( pPlayer.AmmoInventory( iAmmoId ) ) > ( flAmmoLimit / 100 ) * float( pPlayer.GetMaxAmmo( iAmmoId ) ) )
		{
			bResult = false;
			return HOOK_HANDLED;
		}

		return HOOK_CONTINUE;
	}
	else if ( szClassname.CompareN( "weapon_", 7 ) == 0 )
	{
		CBasePlayerWeapon@ pWeapon = cast<CBasePlayerWeapon@>( pPickup );

		if ( pWeapon is null )
			return HOOK_CONTINUE;

		float flExpendLimit = g_pCvarExpendables.GetFloat();
		if ( flExpendLimit <= 0.0 ) return HOOK_CONTINUE;

		int iAmmoId = -1;
/*		switch ( szClassname[7].opImplConv() )
		{
			case 104:
			{
				if ( szClassname[8] == 'a' )
				{
					iAmmoId = g_iAmmoHandgrenade; break; // weapon_handgrenade
				}
				
				break;
			}
			case 115:
			{
				switch ( szClassname[8].opImplConv() )
				{
				//	case 97: iAmmoId = g_iAmmoSatchel; break; // weapon_satchel
					case 110:
					{
						if ( szClassname[9] == 'a' )
						{
							iAmmoId = g_iAmmoSnark; break; // weapon_snark
						}
						
						break;
					}
				}
				
				break;
			}
		//	case 116: iAmmoId = g_iAmmoTripmine; break; // weapon_tripmine
		}*/
		switch ( pWeapon.m_iId )
		{
			case WEAPON_HANDGRENADE:
				iAmmoId = g_iAmmoHandgrenade; break; // weapon_handgrenadee
			case WEAPON_SNARK:
				iAmmoId = g_iAmmoSnark; break; // weapon_snark
			default: return HOOK_CONTINUE;
		}

		if ( iAmmoId == -1 ) return HOOK_CONTINUE;

		if ( float( pPlayer.AmmoInventory( iAmmoId ) ) > ( flExpendLimit / 100 ) * float( pPlayer.GetMaxAmmo( iAmmoId ) ) )
		{
			bResult = false;
			return HOOK_HANDLED;
		}

		return HOOK_CONTINUE;
	}
	else if ( szClassname.CompareN( "item_", 5 ) == 0 )
	{
		switch ( szClassname[5].opImplConv() )
		{
			case 97:
			{
				if ( szClassname[8] == 'b' )
				{
					// item_aombattery
					float flArmorLimit = g_pCvarArmor.GetFloat();
					if ( flArmorLimit <= 0.0 ) return HOOK_CONTINUE;

					if ( pPlayer.pev.armorvalue > ( flArmorLimit / 100 ) * pPlayer.pev.armortype )
					{
						bResult = false;
						return HOOK_HANDLED;
					}
				}
				else if ( szClassname[8] == 'p' )
				{
					// item_aompills
					float flHealthLimit = g_pCvarHealth.GetFloat();
					if ( flHealthLimit <= 0.0 ) return HOOK_CONTINUE;

					if ( pPlayer.pev.health > ( flHealthLimit / 100 ) * pPlayer.pev.max_health )
					{
						bResult = false;
						return HOOK_HANDLED;
					}
				}

				return HOOK_CONTINUE;	
			}
			case 98: // item_battery
			{
				float flArmorLimit = g_pCvarArmor.GetFloat();
				if ( flArmorLimit <= 0.0 ) return HOOK_CONTINUE;

				if ( pPlayer.pev.armorvalue > ( flArmorLimit / 100 ) * pPlayer.pev.armortype )
				{
					bResult = false;
					return HOOK_HANDLED;
				}

				return HOOK_CONTINUE;
			}
			case 104: // item_healthkit
			{
				if ( szClassname[11] != 'k' ) return HOOK_CONTINUE;
			
				float flHealthLimit = g_pCvarHealth.GetFloat();
				if ( flHealthLimit <= 0.0 ) return HOOK_CONTINUE;

				if ( pPlayer.pev.health > ( flHealthLimit / 100 ) * pPlayer.pev.max_health )
				{
					bResult = false;
					return HOOK_HANDLED;
				}
	
				return HOOK_CONTINUE;
			}
			default: return HOOK_CONTINUE;
		}
	}

	return HOOK_CONTINUE;
}
