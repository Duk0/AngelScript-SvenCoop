const int Q1_KEY_SILVER = 1;
const int Q1_KEY_GOLD   = 2;
const int Q1_KEY_RUNE1  = 4;
const int Q1_KEY_RUNE2  = 8;
const int Q1_KEY_RUNE3  = 16;

// set in base-themed maps manually (q1_e1m1, q1_e2m1, ...)
const int Q1_KEY_SF_KEYCARD = 65536;

// item icon stuff
// all icons are contained in a sprite sheet
const string Q1_ICON_SPR = "quake1/huditems.spr";
const int Q1_ICON_W = 64; // size of individual icon
const int Q1_ICON_H = 64;

// store collected keys globally
// TODO: recall runes?
//int g_iQ1Keys = 0;

class CBaseQuakePlayerItem : ScriptBasePlayerItemEntity
{
	protected CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set			{ self.m_hPlayer = EHandle( @value ); }
	}

	protected string m_sModel = "models/error.mdl";
	protected string m_sSound;
	protected string m_sSound2 = "";
	protected string m_sName;
	protected string m_sMessage;
	protected int m_iRemainingTime = 3;
	protected float m_flCustomRespawnTime = 60.0f;
//	protected bool m_bCanTouch = true;
	protected bool m_bCanRespawn = true;
	protected bool m_bIsPlayerItem = false;
//	protected CScheduledFunction@ m_pRotFunc = null;
	protected CScheduledFunction@ m_pEndFunc = null;

	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if ( szKey == "m_flCustomRespawnTime" )
		{
			m_flCustomRespawnTime = atof( szValue );
			return true;
		}
		else
			return BaseClass.KeyValue( szKey, szValue );
	}

	void Precache()
	{
		g_Game.PrecacheModel( m_sModel );
		g_SoundSystem.PrecacheSound( "quake1/quad_s.wav" );
		g_SoundSystem.PrecacheSound( m_sSound );

		if ( !m_sSound2.IsEmpty() )
			g_SoundSystem.PrecacheSound( m_sSound2 );
	}

	void Spawn()
	{
		Precache();
		BaseClass.Spawn();
		self.FallInit();
		g_EntityFuncs.SetModel( self, m_sModel );
		self.pev.noise = m_sSound; // this actually doesn't work, so have to schedule later
		self.pev.netname = m_sName;
	//	@m_pRotFunc = @g_Scheduler.SetInterval( this, "RotateThink", 0.01, g_Scheduler.REPEAT_INFINITE_TIMES );
	//	SetThink( ThinkFunction( RotateThink ) );
		self.pev.nextthink = g_Engine.time + 0.01;
		@m_pEndFunc = null;
		@m_pPlayer = null;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
/*		if ( !m_bCanTouch )
			return false;*/

		if ( BaseClass.AddToPlayer( pPlayer ) )
		{
			// pPlayer.SwitchWeapon(pPrev);
			if ( ApplyEffects( pPlayer ) )
			{
				NetworkMessage message( MSG_ONE, NetworkMessages::ItemPickup, pPlayer.edict() );
				message.WriteString( self.pszName() );
				message.End();
				
			//	g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTNOTIFY, "You got the " + self.pev.netname + "\n" );
				g_EngineFuncs.ClientPrintf( pPlayer, print_center, "You got the " + self.pev.netname + "\n" );

			/*	if ( m_pRotFunc !is null )
				{
					g_Scheduler.RemoveTimer( m_pRotFunc );
					@m_pRotFunc = null;
				}*/
			//	SetThink( null );

				q1_ScheduleItemSound( pPlayer, m_sSound );
			//	g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, m_sSound, 1.0, ATTN_NORM );
			
				@m_pPlayer = pPlayer;
				
				m_bIsPlayerItem = true;
				
			//	self.Materialize();
			//	self.AttemptToMaterialize();
			//	self.RespawnItem();
			//	self.Respawn();
			//	RespawnItem();
			
			//	g_Scheduler.SetTimeout( this, "MaterializeItem_S", 31.0, EHandle( self ) );
			//	g_Scheduler.SetTimeout( this, "MaterializeItem", 31.0 );

			//	g_EngineFuncs.ServerPrint( "entindex: " + self.entindex() + "\n" );
				
			//	g_EngineFuncs.ServerPrint( "GetRespawnTime: " + self.GetRespawnTime() + "\n" );

				return true;
			}
		}

		return false;
	}

	bool ApplyEffects( CBasePlayer@ pPlayer ) { return false; }
	
	void MaterializeItem()
	{
		self.Materialize();
	}

	void Think()
	{
		if ( m_bIsPlayerItem )
		{
			if ( m_pPlayer !is null && ( !m_pPlayer.IsAlive() || !g_bShowQuickStats ) )
			{
				if ( m_pPlayer.HasPlayerItem( self ) )
					g_EntityFuncs.Remove( self );

				q1_BonusFlash( m_pPlayer );
				
				return;
			}
			
			self.pev.nextthink = g_Engine.time + 0.1;

			return;
		}
	
		self.pev.nextthink = g_Engine.time + 0.01;
		self.pev.angles.y += 1.0;

		if ( m_bCanRespawn && ( self.pev.effects & EF_NODRAW ) != 0 )
		{
			m_bCanRespawn = false;
			g_Scheduler.SetTimeout( this, "MaterializeItem", m_flCustomRespawnTime );
		//	g_EngineFuncs.ServerPrint( self.pszName() + " entindex: " + self.entindex() + "\n" );
		}
		
	//	g_EngineFuncs.ServerPrint( self.pszName() + " entindex: " + self.entindex() + "\n" );
	}
/*
	void RotateThink()
	{
		self.pev.nextthink = g_Engine.time + 0.01;
		self.pev.angles.y += 1.0;
	}
*/
	void FlashSceen()
	{
		if ( m_pPlayer is null )
			return;

		if ( m_iRemainingTime == 3 && !m_sMessage.IsEmpty() )
		{
			g_EngineFuncs.ClientPrintf( m_pPlayer, print_center, m_sMessage );
			g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_AUTO, m_sSound2, 1.0, ATTN_NORM );
		}

		q1_BonusFlash( m_pPlayer );

		if ( m_iRemainingTime > 0 )
		{
			m_iRemainingTime--;
			return;
		}
		
		RemoveEffects();
		
		SetThink( null );
	}
	
	void RemoveEffects() {};

	void UpdateOnRemove()
	{
/*		if ( m_pRotFunc !is null )
		{
			g_Scheduler.RemoveTimer( m_pRotFunc );
			@m_pRotFunc = null;
		}*/
		
		SetThink( null );

		if ( m_pEndFunc !is null )
		{
			g_Scheduler.RemoveTimer( m_pEndFunc );
			@m_pEndFunc = null;
		}

		BaseClass.UpdateOnRemove();
	}

	void KillSelf()
	{
		if ( m_pPlayer is null )
			return;

		if ( m_pPlayer.HasPlayerItem( self ) )
			g_EntityFuncs.Remove( self );
/*
		if ( m_pPlayer.HasPlayerItem( self ) )
			m_pPlayer.RemovePlayerItem( self );
*/
/*		if ( m_pPlayer.AddPlayerItem( self ) != APIR_NotAdded )
			m_pPlayer.RemovePlayerItem( self );*/

/*		CBasePlayerItem@ pItem = m_pPlayer.HasNamedPlayerItem( self.pszName() );
		if ( pItem !is null && pItem is self )
		{
		//	pItem.m_hPlayer = null;
		//	m_pPlayer.RemovePlayerItem( pItem );
		//	g_EntityFuncs.Remove( pItem );
			g_EntityFuncs.Remove( self );
		}*/

/*
		CBaseEntity@ pEntity = null;
		CBaseEntity@ pOwner;

		while ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, self.pszName() ) ) !is null )
		{
			@pOwner = g_EntityFuncs.Instance( pEntity.pev.owner );

			if ( pOwner is null )
				continue;

			if ( pEntity !is m_pPlayer )
				continue;

			if ( pOwner.IsPlayer() )
				@pEntity.pev.owner = null;

			g_EntityFuncs.Remove( pEntity );
		}
*/
	//	g_EntityFuncs.Remove( self );
	}

	CBasePlayerWeapon@ GetWeaponPtr()
	{
		return null;
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iWeight = -1;
		info.iFlags = 0;
		return true;
	}
}

class CBaseQuakeItem : ScriptBaseItemEntity
{
	protected string m_sModel = "models/error.mdl";
	protected string m_sSound;
	protected int m_iArmor;
//	protected bool m_bCanTouch = true;
//	protected bool m_bCanRespawn = false;

	void Precache()
	{
		g_Game.PrecacheModel( m_sModel );
		g_SoundSystem.PrecacheSound( m_sSound );
		g_SoundSystem.PrecacheSound( "quake1/items/itembk2.wav" );
	}

	void Spawn()
	{
		Precache();

		BaseClass.Spawn();

		self.pev.noise = m_sSound; // this actually doesn't work, so have to schedule later
		g_EntityFuncs.SetModel( self, m_sModel );

		g_EntityFuncs.SetSize( self.pev, Vector( -16, -16, 0 ), Vector( 16, 16, 56 ) );

		self.pev.movetype = MOVETYPE_TOSS;
		self.pev.solid = SOLID_TRIGGER;

	//	SetThink( ThinkFunction( RotateThink ) );
		self.pev.nextthink = g_Engine.time + 0.01;
	}

	bool MyTouch( CBasePlayer@ pPlayer )
	{
	/*	if ( !m_bCanTouch )
			return false;*/

		if ( ApplyArmor( pPlayer ) )
		{
			NetworkMessage message( MSG_ONE, NetworkMessages::ItemPickup, pPlayer.edict() );
			//	message.WriteString( self.GetClassname() );
				message.WriteString( "item_battery" );
			message.End();

			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, m_sSound, 1.0, ATTN_NORM );
			
			g_Scheduler.SetTimeout( this, "MaterializeItem", 10.0 );

		//	self.Respawn();
		//	self.Materialize();
			return true;
		//	RespawnArmor();
		}

		return false;
	}

	bool ApplyArmor( CBasePlayer@ pPlayer )
	{
		if ( pPlayer.pev.armorvalue >= pPlayer.pev.armortype )
			return false;

		if ( pPlayer.pev.armorvalue + m_iArmor > pPlayer.pev.armortype )
			pPlayer.pev.armorvalue = pPlayer.pev.armortype;
		else
			pPlayer.pev.armorvalue += m_iArmor;

		return true;
	}
/*	
	void Touch( CBaseEntity@ pOther )
	{
		BaseClass.Touch( pOther );
	
		if ( m_bCanRespawn )
			return;
		
		self.Respawn();
		
	//	m_bCanTouch = false;
		m_bCanRespawn = true;

		self.pev.nextthink = g_Engine.time + 2.0;

		g_EngineFuncs.ServerPrint( "Touch " + self.GetClassname() + " entindex: " + self.entindex() + "\n" );
	}
	
	void Use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue = 0.0f )
	{
		BaseClass.Use( pActivator, pCaller, useType, flValue );
	
		if ( m_bCanRespawn )
			return;
		
		self.Respawn();
		
	//	m_bCanTouch = false;
		m_bCanRespawn = true;

		self.pev.nextthink = g_Engine.time + 2.0;

		g_EngineFuncs.ServerPrint( "Use " + self.GetClassname() + " entindex: " + self.entindex() + "\n" );
	}

	CBaseEntity@ Respawn()
	{
		g_EngineFuncs.ServerPrint( "Respawn " + self.GetClassname() + " entindex: " + self.entindex() + "\n" );
		return null;
	}
*/
	void MaterializeItem()
	{
		self.Materialize();
		self.pev.nextthink = g_Engine.time + 0.01;
	//	m_bCanRespawn = true;
	//	g_EngineFuncs.ServerPrint( "MaterializeItem " + self.GetClassname() + " entindex: " + self.entindex() + "\n" );
	}

	void Think()
	{
		self.pev.nextthink = g_Engine.time + 0.01;
		self.pev.angles.y += 1.0;

	/*	if ( m_bCanRespawn && ( self.pev.effects & EF_NODRAW ) != 0 )
		{
		//	m_bCanTouch = true;
			m_bCanRespawn = false;
		//	g_Scheduler.SetTimeout( this, "MaterializeItem", 10.0 );
			self.Materialize();
			g_EngineFuncs.ServerPrint( self.GetClassname() + " entindex: " + self.entindex() + "\n" );
		}*/
		
	//	g_EngineFuncs.ServerPrint( self.GetClassname() + " entindex: " + self.entindex() + "\n" );
	}
	
//	void RespawnArmor() {};

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iWeight = -1;
		info.iFlags = 0;
		return true;
	}
}

class CBaseQuakeKey : ScriptBaseEntity
{
	protected string m_sModel = "models/error.mdl";
	protected string m_sSound;
//	protected int m_iKey;
	protected string m_sPickupMsg;
//	protected bool m_bRespawns = true;
//	protected bool m_bRotates = true;
	protected bool m_bKeyCard;

	void Precache()
	{
		g_Game.PrecacheModel( m_sModel );
		g_SoundSystem.PrecacheSound( m_sSound );
	}

	void Spawn()
	{
		m_bKeyCard = ( self.pev.spawnflags & Q1_KEY_SF_KEYCARD ) != 0;

		Precache();
		BaseClass.Spawn();

		g_EntityFuncs.SetModel( self, m_sModel );
		g_EntityFuncs.SetSize( self.pev, Vector(-16, -16, 0), Vector(16, 16, 16) );

		self.pev.movetype = MOVETYPE_TOSS;
		self.pev.solid = SOLID_TRIGGER;

	//	self.FallInit();
	//	self.pev.netname = m_sName;

		self.pev.nextthink = g_Engine.time + 0.01;
	}

	void Think()
	{
		self.pev.angles.y += 1.0;
		self.pev.nextthink = g_Engine.time + 0.01;
	}

	void Touch( CBaseEntity@ pOther )
	{
		if ( pOther is null ) return;
		if ( !pOther.IsPlayer() ) return;
		if ( pOther.pev.health <= 0 ) return;

		CBasePlayer@ pPlayer = cast<CBasePlayer@>( pOther );

		if ( pPlayer is null ) return;

		if ( PickedUp( pPlayer ) )
		{
			SetTouch( null );
			self.SUB_UseTargets( pOther, USE_TOGGLE, 0 );

			g_SoundSystem.EmitSound( pPlayer.edict(), CHAN_ITEM, m_sSound, 1.0, ATTN_NORM );
		//	if ( m_bRespawns )
		//		Respawn();
		//	else
			Die();
		}
	}

/*
	// despite the name, this is called when the item gets picked
	// to set up the respawn timer and shit
	CBaseEntity@ Respawn()
	{
		self.pev.effects |= EF_NODRAW;
		SetThink( ThinkFunction( this.Materialize ) );
		self.pev.nextthink = g_Engine.time + m_fRespawnTime;
		return self;
	}

	// but this is called when the item is ready to respawn
	void Materialize()
	{
		if ( ( self.pev.effects & EF_NODRAW ) != 0 )
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "quake1/items/itembk2.wav", 1.0, ATTN_NORM );
			self.pev.effects &= ~EF_NODRAW;
			self.pev.effects |= EF_MUZZLEFLASH;
		}

		SetThink( m_bRotates ? ThinkFunction( this.ItemThink ) : null );
		SetTouch( TouchFunction( this.ItemTouch ) );
		self.pev.nextthink = g_Engine.time + 0.01;
	}
*/

	void Die()
	{
		g_EntityFuncs.Remove( self );
	}

	bool PickedUp( CBasePlayer@ pPlayer )
	{
	//	m_bRespawns = false;
	//	g_iQ1Keys |= m_iKey;
		g_PlayerFuncs.ShowMessageAll( m_sPickupMsg );
		return true;
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iWeight = -1;
		info.iFlags = 0;
		return true;
	}
}

// turns out using BasePlayerItem is not the way to make actual items
// but it's too late now
class item_qquad : CBaseQuakePlayerItem
{
	item_qquad()
	{
		m_sModel = "models/quake1/w_quad.mdl";
		m_sSound = "quake1/quad.wav";
		m_sSound2 = "quake1/items/damage2.wav";
		m_sName = "Quad Damage";
		m_sMessage = "Quad Damage is wearing off\n";
	}

	bool ApplyEffects( CBasePlayer@ pPlayer )
	{
		pPlayer.pev.renderfx = kRenderFxGlowShell;
		pPlayer.pev.rendercolor.z = 255;
		pPlayer.pev.renderamt = 1;
		pPlayer.pev.effects |= EF_BRIGHTLIGHT;
		
		@m_pEndFunc = g_Scheduler.SetTimeout( this, "StartRemove", 27.0 );
		
		g_PlayerFuncs.ScreenFade( pPlayer, Vector( 0, 0, 255 ), 0.01, 0.01, 30, FFADE_OUT|FFADE_STAYOUT );

		return true;
	}

	void RemoveEffects()
	{
		if ( m_pPlayer is null )
			return;

		m_pPlayer.pev.rendercolor.z = 0;

		if ( m_pPlayer.HasNamedPlayerItem( "item_qsuit" ) is null && m_pPlayer.HasNamedPlayerItem( "item_qinvul" ) is null )
		{
			m_pPlayer.pev.renderfx = kRenderFxNone;
			m_pPlayer.pev.renderamt = 0;
		}
		
		m_pPlayer.pev.effects &= ~EF_BRIGHTLIGHT;

		KillSelf();
	}

	void StartRemove()
	{
		SetThink( ThinkFunction( TimerThink ) );
		self.pev.nextthink = g_Engine.time + 1.0;
	}

	void TimerThink()
	{
		self.pev.nextthink = g_Engine.time + 1.0;
		
		FlashSceen();
	}
}

class item_qinvul : CBaseQuakePlayerItem
{
	protected float m_iSavedArmor;

	item_qinvul()
	{
		m_sModel = "models/quake1/w_invul.mdl";
		m_sSound = "quake1/invul.wav";
		m_sSound2 = "quake1/items/protect2.wav";
		m_sName = "Pentagram of Protection";
		m_sMessage = "Protection is almost burned out\n";
	}

	bool ApplyEffects( CBasePlayer@ pPlayer )
	{
		pPlayer.pev.renderfx = kRenderFxGlowShell;
		pPlayer.pev.rendercolor.x = 255;
		pPlayer.pev.renderamt = 1;
		pPlayer.pev.flags |= FL_GODMODE;
		pPlayer.pev.effects |= EF_BRIGHTLIGHT;

		@m_pEndFunc = g_Scheduler.SetTimeout( this, "StartRemove", 27.0 );
		
		g_PlayerFuncs.ScreenFade( pPlayer, Vector( 255, 255, 0 ), 0.01, 0.01, 30, FFADE_OUT|FFADE_STAYOUT );
	
		m_iSavedArmor = pPlayer.pev.armorvalue;
		pPlayer.pev.armorvalue = pPlayer.pev.armortype = 666;

		return true;
	}

	void RemoveEffects()
	{
		if ( m_pPlayer is null )
			return;

		m_pPlayer.pev.rendercolor.x = 0;

		if ( m_pPlayer.HasNamedPlayerItem( "item_qquad" ) is null && m_pPlayer.HasNamedPlayerItem( "item_qsuit" ) is null )
		{
			m_pPlayer.pev.renderfx = kRenderFxNone;
			m_pPlayer.pev.renderamt = 0;
		}

		m_pPlayer.pev.flags &= ~FL_GODMODE;
		m_pPlayer.pev.effects &= ~EF_BRIGHTLIGHT;
		
		m_pPlayer.pev.armorvalue = m_iSavedArmor;
		m_pPlayer.pev.armortype = 100;

		KillSelf();
	}

	void StartRemove()
	{
		SetThink( ThinkFunction( TimerThink ) );
		self.pev.nextthink = g_Engine.time + 1.0;
	}

	void TimerThink()
	{
		self.pev.nextthink = g_Engine.time + 1.0;
		
		FlashSceen();
	}
}

class item_qsuit : CBaseQuakePlayerItem
{
	item_qsuit()
	{
		m_sModel = "models/quake1/w_suit.mdl";
		m_sSound = "quake1/suit.wav";
		m_sSound2 = "quake1/items/suit2.wav";
		m_sName = "Biosuit";
		m_sMessage = "Air supply in Biosuit expiring\n";
	}

	bool ApplyEffects( CBasePlayer@ pPlayer )
	{
		pPlayer.pev.renderfx = kRenderFxGlowShell;
		pPlayer.pev.rendercolor.y = 255;
		pPlayer.pev.renderamt = 1;
		pPlayer.pev.flags |= FL_IMMUNE_WATER|FL_IMMUNE_LAVA|FL_IMMUNE_SLIME;
		pPlayer.pev.radsuit_finished = g_Engine.time + 30.0;

		@m_pEndFunc = g_Scheduler.SetTimeout( this, "StartRemove", 27.0 );

		g_PlayerFuncs.ScreenFade( pPlayer, Vector( 0, 255, 0 ), 0.01, 0.01, 50, FFADE_OUT|FFADE_STAYOUT );

		return true;
	}

	void RemoveEffects()
	{
		if ( m_pPlayer is null )
			return;

		m_pPlayer.pev.rendercolor.y = 0;

		if ( m_pPlayer.HasNamedPlayerItem( "item_qquad" ) is null && m_pPlayer.HasNamedPlayerItem( "item_qinvul" ) is null )
		{
			m_pPlayer.pev.renderfx = kRenderFxNone;
			m_pPlayer.pev.renderamt = 0;
		}

		m_pPlayer.pev.flags &= ~( FL_IMMUNE_WATER|FL_IMMUNE_LAVA|FL_IMMUNE_SLIME );

		KillSelf();
	}

	void StartRemove()
	{
	/*	if ( m_pPlayer !is null )
			g_PlayerFuncs.ScreenFade( m_pPlayer, g_vecZero, 0.01, 0.01, 50, FFADE_IN );*/

		SetThink( ThinkFunction( TimerThink ) );
		self.pev.nextthink = g_Engine.time + 1.0;
	}

	void TimerThink()
	{
		self.pev.nextthink = g_Engine.time + 1.0;
		
		FlashSceen();
	}
}

class item_qinvis : CBaseQuakePlayerItem
{
	item_qinvis()
	{
		m_sModel = "models/quake1/w_invis.mdl";
		m_sSound = "quake1/invis.wav";
		m_sSound2 = "quake1/items/inv2.wav";
		m_sName = "Ring of Shadows";
		m_sMessage = "Ring of Shadows magic is fading\n";
	}

	bool ApplyEffects( CBasePlayer@ pPlayer )
	{
	//	pPlayer.pev.rendermode = kRenderTransColor;
		pPlayer.pev.rendermode = kRenderTransAlpha;
		pPlayer.pev.renderamt = 1;
		pPlayer.pev.flags |= FL_NOTARGET;

		@m_pEndFunc = g_Scheduler.SetTimeout( this, "StartRemove", 27.0 );
		
		g_PlayerFuncs.ScreenFade( pPlayer, Vector( 100, 100, 100 ), 0.01, 0.01, 50, FFADE_OUT|FFADE_STAYOUT );

		return true;
	}

	void RemoveEffects()
	{
		if ( m_pPlayer is null )
			return;

		m_pPlayer.pev.rendermode = kRenderNormal;
		m_pPlayer.pev.flags &= ~FL_NOTARGET;

		KillSelf();
	}

	void StartRemove()
	{
		SetThink( ThinkFunction( TimerThink ) );
		self.pev.nextthink = g_Engine.time + 1.0;
	}

	void TimerThink()
	{
		self.pev.nextthink = g_Engine.time + 1.0;
		
		FlashSceen();
	}
}

class item_qarmor1 : CBaseQuakeItem
{
	item_qarmor1()
	{
		m_sModel = "models/quake1/w_armor_g.mdl";
		m_sSound = "quake1/armor.wav";
		m_iArmor = 25;
	//	m_bCanTouch = true;
	}
/*
	void RespawnArmor()
	{
		m_bCanTouch = false;
		
		self.pev.effects |= EF_NODRAW;

		SetThink( ThinkFunction( MaterializeArmor ) );
		
		self.pev.nextthink = g_Engine.time + 10.0f;
	}

	void MaterializeArmor()
	{
		if ( ( self.pev.effects & EF_NODRAW ) != 0 )
		{
			g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_ITEM, "quake1/items/itembk2.wav", 1.0, ATTN_NORM, 0, 150 );
			self.pev.effects &= ~EF_NODRAW;
		}

		m_bCanTouch = true;

		SetThink( null );
	//	SetThink( ThinkFunction( RotateThink ) );
		self.pev.nextthink = g_Engine.time + 0.01;
	}*/
}

class item_qarmor2 : CBaseQuakeItem
{
	item_qarmor2()
	{
		m_sModel = "models/quake1/w_armor_y.mdl";
		m_sSound = "quake1/armor.wav";
		m_iArmor = 50;
	//	m_bCanTouch = true;
	}
/*
	void RespawnArmor()
	{
		m_bCanTouch = false;
		
		self.pev.effects |= EF_NODRAW;

		SetThink( ThinkFunction( MaterializeArmor ) );
		
		self.pev.nextthink = g_Engine.time + 10.0f;
	}

	void MaterializeArmor()
	{
		if ( ( self.pev.effects & EF_NODRAW ) != 0 )
		{
			g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_ITEM, "quake1/items/itembk2.wav", 1.0, ATTN_NORM, 0, 150 );
			self.pev.effects &= ~EF_NODRAW;
		}

		m_bCanTouch = true;

		SetThink( null );
		self.pev.nextthink = g_Engine.time + 0.01;
	}*/
}

class item_qarmor3 : CBaseQuakeItem
{
	item_qarmor3()
	{
		m_sModel = "models/quake1/w_armor_r.mdl";
		m_sSound = "quake1/armor.wav";
		m_iArmor = 100;
	//	m_bCanTouch = true;
	}
/*
	void RespawnArmor()
	{
		m_bCanTouch = false;
		
		self.pev.effects |= EF_NODRAW;

		SetThink( ThinkFunction( MaterializeArmor ) );
		
		self.pev.nextthink = g_Engine.time + 10.0f;
	}

	void MaterializeArmor()
	{
		if ( ( self.pev.effects & EF_NODRAW ) != 0 )
		{
			g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_ITEM, "quake1/items/itembk2.wav", 1.0, ATTN_NORM, 0, 150 );
			self.pev.effects &= ~EF_NODRAW;
		}

		m_bCanTouch = true;

		SetThink( null );
		self.pev.nextthink = g_Engine.time + 0.01;
	}*/
}

class item_qkey1 : CBaseQuakeKey
{
	item_qkey1()
	{
	//	m_iKey = Q1_KEY_SILVER;
	//	m_bCanRespawn = false;
	//	m_sName = "Silver Key";
		m_sPickupMsg = "You got the Silver Key.";

		if ( m_bKeyCard )
		{
			m_sModel = "models/quake1/w_keycard_silver.mdl";
			m_sSound = "quake1/bkey.wav";
		} else {
			m_sModel = "models/quake1/w_keyrune_silver.mdl";
			m_sSound = "quake1/mkey.wav";
		}
	}
}

class item_qkey2 : CBaseQuakeKey
{
	item_qkey2()
	{
	//	m_iKey = Q1_KEY_GOLD;
	//	m_bCanRespawn = false;
	//	m_sName = "Gold Key";
		m_sPickupMsg = "You got the Gold Key.";

		if ( m_bKeyCard )
		{
			m_sModel = "models/quake1/w_keycard_gold.mdl";
			m_sSound = "quake1/bkey.wav";
		} else {
			m_sModel = "models/quake1/w_keyrune_gold.mdl";
			m_sSound = "quake1/mkey.wav";
		}
	}
}

class item_qrune1 : CBaseQuakeKey
{
	item_qrune1()
	{
	//	m_iKey = Q1_KEY_RUNE1;
	//	m_bCanRespawn = false;
	//	m_sName = "Rune of Black Magic";
		m_sPickupMsg = "You got the Rune of Black Magic.";
		m_sModel = "models/quake1/w_rune1.mdl";
		m_sSound = "quake1/rune.wav";
	}
}

class item_qrune2 : CBaseQuakeKey
{
	item_qrune2()
	{
	//	m_iKey = Q1_KEY_RUNE2;
	//	m_bCanRespawn = false;
	//	m_sName = "Rune of shit";
		m_sPickupMsg = "You got the Rune of shit.";
		m_sModel = "models/quake1/w_rune2.mdl";
		m_sSound = "quake1/rune.wav";
	}
}

class item_qrune3 : CBaseQuakeKey
{
	item_qrune3()
	{
	//	m_iKey = Q1_KEY_RUNE3;
	//	m_bCanRespawn = false;
	//	m_sName = "Rune of fuck";
		m_sPickupMsg = "You got the Rune of fuck.";
		m_sModel = "models/quake1/w_rune3.mdl";
		m_sSound = "quake1/rune.wav";
	}
}

// backpack
// gotta make this a separate class for now

class CBackPack : ScriptBaseEntity
{
//	CBasePlayerItem@ m_pWeapon = null;
	string m_szWeaponName;
	int m_iAmmoShells;
	int m_iAmmoNails;
	int m_iAmmoRockets;
	int m_iAmmoCells;

	private float m_fDeathTime;

	void Spawn()
	{
		Precache();
		BaseClass.Spawn();

		self.pev.movetype = MOVETYPE_TOSS;
		self.pev.solid = SOLID_TRIGGER;
		g_EntityFuncs.SetModel( self, "models/quake1/w_backpack.mdl" );
		g_EntityFuncs.SetSize( self.pev, Vector( -16, -16, 0 ), Vector( 16, 16, 56 ) );

		m_fDeathTime = g_Engine.time + 120.0;
		self.pev.nextthink = g_Engine.time + 0.01;
	}

	void Precache()
	{
		g_Game.PrecacheModel( "models/quake1/w_backpack.mdl" );
		g_SoundSystem.PrecacheSound( "quake1/ammo.wav" );
		g_SoundSystem.PrecacheSound( "quake1/weapon.wav" );
	}

	void Think()
	{
		self.pev.angles.y += 1.0;

		if ( m_fDeathTime < g_Engine.time )
			Die();
		else
			self.pev.nextthink = g_Engine.time + 0.01;
	}

	void Die()
	{
/*		if ( m_pWeapon !is null )
			g_EntityFuncs.Remove( m_pWeapon );*/
		if ( !m_szWeaponName.IsEmpty() )
			m_szWeaponName.Clear();

		g_EntityFuncs.Remove( self );
	}

	void Touch( CBaseEntity@ pOther )
	{
		if ( pOther is null )
			return;

		if ( !pOther.IsPlayer() )
			return;

		if ( pOther.pev.health <= 0 )
			return;

		CBasePlayer@ pPlayer = cast<CBasePlayer@>( pOther );

		if ( pPlayer is null )
			return;
			
		CBaseEntity@ pOwner = g_EntityFuncs.Instance( self.pev.owner );

		if ( pOwner !is null && pOwner !is pPlayer )
			return;

		int iRemove = 0;

		if ( m_iAmmoShells > 0 && pPlayer.GiveAmmo( m_iAmmoShells, "buckshot", Q1_AMMO_SHELLS_MAX, false ) >= 0 )
			iRemove = 1;
		if ( m_iAmmoNails > 0 && pPlayer.GiveAmmo( m_iAmmoNails, "bolts", Q1_AMMO_NAILS_MAX, false ) >= 0 )
			iRemove = 1;
		if ( m_iAmmoRockets > 0 && pPlayer.GiveAmmo( m_iAmmoRockets, "rockets", Q1_AMMO_ROCKETS_MAX, false ) >= 0 )
			iRemove = 1;
		if ( m_iAmmoCells > 0 && pPlayer.GiveAmmo( m_iAmmoCells, "uranium", Q1_AMMO_ENERGY_MAX, false ) >= 0 )
			iRemove = 1;

	//	if ( m_pWeapon !is null && pPlayer.HasNamedPlayerItem( m_pWeapon.GetClassname() ) is null )
		if ( !m_szWeaponName.IsEmpty() && pPlayer.HasNamedPlayerItem( m_szWeaponName ) is null )
		{
			pPlayer.GiveNamedItem( m_szWeaponName );
			iRemove = 2;
		}

		if ( iRemove > 0 )
		{
			g_SoundSystem.EmitSound( pPlayer.edict(), CHAN_ITEM, iRemove == 1 ? "quake1/ammo.wav" : "quake1/weapon.wav", 1.0, ATTN_NORM );
			Die();
		}
	}
}

CBackPack@ q1_SpawnBackpack( CBaseEntity@ pOwner )
{
	Vector vecOrigin = pOwner.pev.origin;
	Vector vecVelocity = Vector( Math.RandomFloat( -100, 100 ), Math.RandomFloat( -100, 100 ), 200 );
	
	CBaseEntity@ pPackEnt = q1_ShootCustomProjectile( "item_qbackpack", "models/quake1/w_backpack.mdl",
														vecOrigin, vecVelocity,
														g_vecZero, pOwner.IsPlayer() ? pOwner : null );
	return cast<CBackPack@>( CastToScriptClass( pPackEnt ) );
}

// fucking schedulers again
// gotta do this AFTER pickup to override the default pickup sound
void q1_ScheduleItemSound( CBasePlayer @pPlayer, string sSound )
{
	g_SoundSystem.StopSound( pPlayer.edict(), CHAN_ITEM, "items/gunpickup2.wav", true );
	g_Scheduler.SetTimeout( "q1_ScheduledItemSound", 0.001, EHandle( pPlayer ), sSound );
}

void q1_ScheduledItemSound( EHandle hPlayer, string sSound )
{
	if ( !hPlayer.IsValid() )
		return;

	CBaseEntity@ pEntity = hPlayer.GetEntity();

	if ( pEntity is null )
		return;

//	g_SoundSystem.StopSound( pEntity.edict(), CHAN_ITEM, "items/gunpickup2.wav", true );
	g_SoundSystem.EmitSound( pEntity.edict(), CHAN_ITEM, sSound, 1.0, ATTN_NORM );
}

void q1_BonusFlash( CBasePlayer @pPlayer )
{
	g_PlayerFuncs.ScreenFade( pPlayer, Vector( 215, 186, 69 ), 0.01, 0.5, 50, FFADE_OUT );
}

void q1_RegisterItems()
{
	// precache item and ammo models right away
	g_Game.PrecacheModel( "models/quake1/w_quad.mdl" );
	g_Game.PrecacheModel( "models/quake1/w_invul.mdl" );
	g_Game.PrecacheModel( "models/quake1/w_invis.mdl" );
	g_Game.PrecacheModel( "models/quake1/w_suit.mdl" );
	g_Game.PrecacheModel( "models/quake1/w_armor_g.mdl" );
	g_Game.PrecacheModel( "models/quake1/w_armor_y.mdl" );
	g_Game.PrecacheModel( "models/quake1/w_armor_r.mdl" );
	g_Game.PrecacheModel( "models/quake1/w_backpack.mdl" );
	g_Game.PrecacheModel( "models/quake1/w_keyrune_silver.mdl" );
	g_Game.PrecacheModel( "models/quake1/w_keyrune_gold.mdl" );
	g_Game.PrecacheModel( "models/quake1/w_rune1.mdl" );
	g_Game.PrecacheModel( "models/quake1/w_rune2.mdl" );
//	g_Game.PrecacheModel( "models/quake1/w_rune3.mdl" );

	g_CustomEntityFuncs.RegisterCustomEntity( "item_qquad", "item_qquad" );
	g_ItemRegistry.RegisterItem( "item_qquad", "quake1/items" );
	g_CustomEntityFuncs.RegisterCustomEntity( "item_qinvul", "item_qinvul" );
	g_ItemRegistry.RegisterItem( "item_qinvul", "quake1/items" );
	g_CustomEntityFuncs.RegisterCustomEntity( "item_qsuit", "item_qsuit" );
	g_ItemRegistry.RegisterItem( "item_qsuit", "quake1/items" );
	g_CustomEntityFuncs.RegisterCustomEntity( "item_qinvis", "item_qinvis" );
	g_ItemRegistry.RegisterItem( "item_qinvis", "quake1/items" );
	g_CustomEntityFuncs.RegisterCustomEntity( "item_qarmor1", "item_qarmor1" );
//	g_ItemRegistry.RegisterItem( "item_qarmor1", "quake1/items" );
	g_CustomEntityFuncs.RegisterCustomEntity( "item_qarmor2", "item_qarmor2" );
//	g_ItemRegistry.RegisterItem( "item_qarmor2", "quake1/items");
	g_CustomEntityFuncs.RegisterCustomEntity( "item_qarmor3", "item_qarmor3" );
//	g_ItemRegistry.RegisterItem( "item_qarmor3", "quake1/items");
	g_CustomEntityFuncs.RegisterCustomEntity( "CBackPack", "item_qbackpack" );
//	g_ItemRegistry.RegisterItem( "item_qbackpack", "quake1/items" );
	g_CustomEntityFuncs.RegisterCustomEntity( "item_qkey1", "item_qkey1" );
//	g_ItemRegistry.RegisterItem( "item_qkey1", "quake1/items" );
	g_CustomEntityFuncs.RegisterCustomEntity( "item_qkey2", "item_qkey2" );
//	g_ItemRegistry.RegisterItem( "item_qkey2", "quake1/items" );
	g_CustomEntityFuncs.RegisterCustomEntity( "item_qrune1", "item_qrune1" );
//	g_ItemRegistry.RegisterItem( "item_qrune1", "quake1/items" );
	g_CustomEntityFuncs.RegisterCustomEntity( "item_qrune2", "item_qrune2" );
//	g_ItemRegistry.RegisterItem( "item_qrune2", "quake1/items" );
//	g_CustomEntityFuncs.RegisterCustomEntity( "item_qrune3", "item_qrune3" );
//	g_ItemRegistry.RegisterItem( "item_qrune3", "quake1/items" );
}
