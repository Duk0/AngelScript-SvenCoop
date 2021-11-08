// Afraid of Monsters: Director's Cut Script
// Misc Script: Flashlight Battery
// Author: Zorbos

const int AOMBATTERY_GIVE = 25;
const int AOMBATTERY_GIVE_SURVIVAL = 20;

class item_aombattery : ScriptBasePlayerAmmoEntity
{
	private int m_iAmountToGive;
	private bool bSurvivalEnabled = g_SurvivalMode.MapSupportEnabled() && g_SurvivalMode.IsEnabled();
	
	void Spawn()
	{ 
		Precache();

		if ( !self.SetupModel() )
			g_EntityFuncs.SetModel( self, "models/AoMDC/items/w_battery.mdl" );
		else	//Custom model
			g_EntityFuncs.SetModel( self, self.pev.model );

		BaseClass.Spawn();
		
		if ( bSurvivalEnabled )
			self.pev.spawnflags = 1280;// +USE only AND Never Respawn
		else
			self.pev.spawnflags = 256; // +USE only
		
		// Makes it slightly easier to pickup
		if ( g_bEasyPickup )
			g_EntityFuncs.SetSize( self.pev, Vector( -4, -4, -2 ), Vector( 4, 4, 2 ) );
	}
	
	void Precache()
	{
		BaseClass.Precache();

		if ( string( self.pev.model ).IsEmpty() )
			g_Game.PrecacheModel( "models/AoMDC/items/w_battery.mdl" );
		else	//Custom model
			g_Game.PrecacheModel( self.pev.model );

		g_SoundSystem.PrecacheSound( "items/gunpickup2.wav" );
	}
	
	bool AddAmmo( CBaseEntity@ pOther )
	{
		CBasePlayer@ pPlayer = cast<CBasePlayer@>( pOther );
		
		if ( pPlayer is null )
			return false;
		
		// Can't take batteries if the flashlight is already full!
		if ( pPlayer.m_iFlashBattery < 100 )
		{
			if ( bSurvivalEnabled )
				m_iAmountToGive = AOMBATTERY_GIVE_SURVIVAL;
			else
				m_iAmountToGive = AOMBATTERY_GIVE;
				
			NetworkMessage message( MSG_ONE, NetworkMessages::ItemPickup, pPlayer.edict() );
				message.WriteString( "item_battery" ); // Show the battery icon on the HUD
			message.End();
		
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "items/gunpickup2.wav", 1, ATTN_NORM );
			
			// Set a floor on the new battery level if the amount added goes over the maximum
			if ( ( pPlayer.m_iFlashBattery + m_iAmountToGive ) > 100 )
				pPlayer.m_iFlashBattery = 100;
			else
				pPlayer.m_iFlashBattery += m_iAmountToGive;
				
			g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCENTER, "Flashlight battery: " + pPlayer.m_iFlashBattery );
				
			return true;
		}
		
		return false;
	}
}

void RegisterAOMBattery()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "item_aombattery", "item_aombattery" );
}
