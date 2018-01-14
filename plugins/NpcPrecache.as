/*
Hod .as plugin do .../svencoop_addon/scripts/plugins/ a text nizsie v ... vloz do default_plugins.txt
Potom napis do hlds konzoly as_reloadplugin NpcPrecache alebo restartuj server

"plugins"
{
...
	"plugin"
	{
		"name" "NpcPrecache"
		"script" "NpcPrecache"
	}
...
}
*/

// Entity
array<string> g_pEnts = {
	"monster_alien_babyvoltigore",
	"monster_alien_grunt",
	"monster_alien_slave",
	"monster_alien_tor",
	"monster_alien_voltigore",
	"monster_babycrab",
	"monster_babygarg",
	"monster_barnacle",
	"monster_barney",
	"monster_bigmomma",
	"monster_blkop_osprey",
	"monster_blkop_apache",
	"monster_bodyguard",
	"monster_bullchicken",
	"monster_chumtoad",
	"monster_cleansuit_scientist",
	"monster_cockroach",
	"monster_gargantua",
	"monster_gman",
	"monster_headcrab",
	"monster_houndeye",
	"monster_human_assassin",
	"monster_human_grunt",
	"monster_human_grunt_ally",
	"monster_human_medic_ally",
	"monster_human_torch_ally",
	"monster_hwgrunt",
	"monster_ichthyosaur",
	"monster_kingpin",
	"monster_leech",
	"monster_male_assassin",
	"monster_miniturret",
	"monster_nihilanth",
	"monster_osprey",
	"monster_otis",
	"monster_pitdrone",
	"monster_rat",
	"monster_robogrunt",
	"monster_scientist",
	"monster_sentry",
	"monster_shockroach",
	"monster_shocktrooper",
	"monster_snark",
	"monster_sqknest",
	"monster_stukabat",
	"monster_tentacle",
	"monster_tripmine",
	"monster_turret",
	"monster_zombie",
	"monster_zombie_barney",
	"monster_zombie_soldier",
};


void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Duko" );
	g_Module.ScriptInfo.SetContactInfo( "group.midu.cz" );
}

void MapInit()
{
	for ( uint i = 0; i < g_pEnts.length(); i++ )
		g_Game.PrecacheOther( g_pEnts[i] ); // toto precachne entitu aj s modelom

	// Modely, pridaj len iba ak treba
/*	g_Game.PrecacheModel( "models/otis.mdl" );
	g_Game.PrecacheModel( "models/scientist.mdl" );
	g_Game.PrecacheModel( "models/hwgruntf.mdl" );
	g_Game.PrecacheModel( "models/hgruntf.mdl" );
*/
}
