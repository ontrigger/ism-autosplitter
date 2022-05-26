state("In Sound Mind")
{
	bool isLoading : "unityplayer.dll", 0x19fb7c8, 0x78;
}

startup
{
	vars.Log = (Action<object>)(output => print("[ISM-ASL] " + output));
	vars.Watch = (Action<string>)(key => { if(vars.Unity[key].Changed) vars.Log(key + ": " + vars.Unity[key].Old + " -> " + vars.Unity[key].Current); });
	vars.Unity = Assembly.Load(File.ReadAllBytes(@"Components\UnityASL.bin")).CreateInstance("UnityASL.Unity");
	vars.Unity.LoadSceneManager = true;

	/*
	Building -> Desmond's Tape -> Building 
		-> Virginia's Tape -> Homa-Mart -> Building
		-> Allen's Tape    -> Point Icarus -> Building
		-> Max's Tape 	   -> Old Factory  -> Building
		-> Lucas' Tape     -> Elysium Park -> Building
		-> Rainbow Tape    -> Building
	4, 5, 6: Hub_1, Hub_Env_1, Hub_Outside_1
	28, 29, 30, 31, 32, 33: Tape_Desmond_1, Tape_Watcher_1, Tape_Shade_1, Tape_Bull_1, Tape_Flash_1, Tape_Rainbow_1
	10, 11, 12: C_Supermarket, C_Supermarket_env_1, C_Supermarket_env_2
	13, 14, 15, 16, 17: C_Lighthouse, C_Lighthouse_env1, C_Lighthouse_env2, C_Lighthouse_Walls, C_Lighthouse_splines
	18, 19, 20, 21, 22: C_Factory, C_Factory_env1, C_Factory_env2, C_Factory_Walls, C_Factory_splines
	23, 24, 25, 26, 27: C_Forest, C_Forest_env1, C_Forest_env2, C_Forest_Splines, C_Forest_Walls
	*/
	vars.Levels = new Dictionary<string, dynamic>()
	{
		{ "mainmenu", new {
			Label = "Main Menu",
			Scenes = new List<int> { 1, 9 },
			SettingEntry = false,
			SettingExit = false,
		}},
		{ "building", new {
			Label = "Building",
			Scenes = new List<int> { 4, 5, 6 },
			SettingEntry = false,
			SettingExit = false
		}},
		{ "dtape", new {
			Label = "Desmond's Tape",
			Scenes = new List<int> { 28 },
			SettingEntry = true,
			SettingExit = true
		}},
		{ "vtape", new {
			Label = "Virginia's Tape",
			Scenes = new List<int> { 29 },
			SettingEntry = true,
			SettingExit = true
		}},
		{ "hm", new {
			Label = "Homa-Mart",
			Scenes = new List<int> { 10, 11, 12 },
			SettingEntry = true,
			SettingExit = true
		}},
		{ "atape", new {
			Label = "Allen's Tape",
			Scenes = new List<int> { 30 },
			SettingEntry = "flaregun-name",
			SettingExit = true
		}},
		{ "pi", new {
			Label = "Point Icarus",
			Scenes = new List<int> { 13, 14, 15, 16, 17 },
			SettingEntry = "flaregun-name",
			SettingExit = true
		}},
		{ "mtape", new {
			Label = "Max's Tape",
			Scenes = new List<int> { 31 },
			SettingEntry = "lurepill-name",
			SettingExit = true
		}},
		{ "of", new {
			Label = "Old Factory",
			Scenes = new List<int> { 18, 19, 20, 21, 22 },
			SettingEntry = "lurepill-name",
			SettingExit = true
		}},
		{ "ltape", new {
			Label = "Lucas' Tape",
			Scenes = new List<int> { 32 },
			SettingEntry = "radio-name",
			SettingExit = true
		}},
		{ "ep", new {
			Label = "Elysium Park",
			Scenes = new List<int> { 23, 24, 25, 26, 27 },
			SettingEntry = "radio-name",
			SettingExit = true
		}},
		{ "rtape", new {
			Label = "Rainbow Tape",
			Scenes = new List<int> { 33 },
			SettingEntry = true,
			SettingExit = true
		}},
	};

	vars.EquippableItemNames = new Dictionary<string, string>() 
	{ 
		{"flashlight-name", "Flashlight"}, 
		{"mirror-name", "Mirror Shard"},
		{"pistol-name", "Pistol"}, 
		{"gasmask-name", "Gas Mask"}, 
		{"flaregun-name", "Flare Gun"}, 
		{"lurepill-name", "Lure Pill"}, 
		{"shotgun-name", "Shotgun"}, 
		{"radio-name", "Radio"}
	};

	vars.DefaultSettings = new List<string>() {
		"dtape_entry_any",		// Building 1/Desmonds Tape
		"vtape_entry_any",		// Building 2
		"hm_exit",				// Homa-Mart
		"atape_entry_item",		// Building 3
		"pi_exit",				// Point Icarus
		"mtape_entry_item",		// Building 4
		"of_exit",				// Old Factory
		"ltape_entry_item",		// Building 5
		"ep_exit",				// Elysium Park
		"rtape_entry_any",		// Building 6
		"rtape_exit"			// Agent Rainbow
	};

	// If we are loading a specific level (associated with multiple scenes - if any of the scenes are loading, then we are loading the level)
	vars.LevelLoading = (Func<string, int, bool>)((level, loadingScene) => vars.Levels[level].Scenes.Contains(loadingScene));

	settings.Add("level_entry_any", true, "Enter Level (First time, any item)");
	settings.Add("level_entry_item", true, "Enter Level With Item (First time)");
	settings.Add("level_exit", true, "Exit Level (First time)");

	var SHOW_SET_IN_LABEL = false;
	foreach(KeyValuePair<string, dynamic> entry in vars.Levels)
	{
		// split for entering the level with any item for the first time
		if((entry.Value.SettingEntry is Boolean && entry.Value.SettingEntry != false)
			|| entry.Value.SettingEntry is String)
		{
			string set = entry.Key + "_entry_any";
			string label = SHOW_SET_IN_LABEL ? entry.Value.Label + " [" + set + "]" : entry.Value.Label; 
			settings.Add(set, vars.DefaultSettings.Contains(set), label, "level_entry_any");
		}

		if(entry.Value.SettingEntry is String)
		{
			string set = entry.Key + "_entry_item";
			string label = SHOW_SET_IN_LABEL ? entry.Value.Label + " with " + vars.EquippableItemNames[entry.Value.SettingEntry] + " [" + set + "]" : entry.Value.Label + " with " + vars.EquippableItemNames[entry.Value.SettingEntry]; 
			settings.Add(set, vars.DefaultSettings.Contains(set), label, "level_entry_item");
		}

		if(entry.Value.SettingExit)
		{
			string set = entry.Key + "_exit";
			string label = SHOW_SET_IN_LABEL ? entry.Value.Label + " [" + set + "]" : entry.Value.Label; 
			settings.Add(set, vars.DefaultSettings.Contains(set), label, "level_exit");
		}
	}

	// Equippable Splits
	vars.EquippableItemGot = new Dictionary<string, bool>();

	settings.Add("equippables", false, "Equippable Pickup");
	foreach (KeyValuePair<string, string> entry in vars.EquippableItemNames)
	{
		settings.Add(entry.Key, false, entry.Value, "equippables");
		vars.EquippableItemGot.Add(entry.Key, false);
	}

	// Stat splits
	vars.Stats = new string[] { "Speed", "Health", "Stamina", "Stealth" };
	vars.StatMaxes = new Dictionary<string, int>();

	settings.Add("stat", false, "Stat Increase (pill pickup)");
	foreach(string stat in vars.Stats)
	{
		settings.Add(stat, false, stat, "stat");
		vars.StatMaxes.Add(stat, 0);
	}
}

init
{
	vars.Unity.TryOnLoad = (Func<dynamic, bool>)(helper =>
	{
		// GameParams
		var GameParamsClass = helper.GetClass("Assembly-CSharp", "GameParams");
		var GameParamsBase = helper.GetParent(GameParamsClass);
		vars.Unity.Make<int>(GameParamsBase.Static, GameParamsBase["Instance"], GameParamsClass["CurrentLocation"]).Name = "Location";
		
		// EquippableController
		var EquippableControllerClass = helper.GetClass("Assembly-CSharp", "EquippableController", 1);
		var EquippableControllerBase = helper.GetParent(EquippableControllerClass);
		var EquippableItemClass = helper.GetClass("Assembly-CSharp", "EquippableItem");
		var InventoryItemClass = helper.GetClass("Assembly-CSharp", "InventoryItem");

		vars.Unity.Make<bool>(EquippableControllerBase.Static, EquippableControllerBase["Instance"], EquippableControllerClass["_isEquipping"]).Name = "isEquipping";
		vars.Unity.MakeString(EquippableControllerBase.Static, EquippableControllerBase["Instance"], EquippableControllerClass["_currentEquippedItem"], InventoryItemClass["DisplayName"]).Name = "currentEquippedItem";
		
		// PlayerStats
		var PlayerStatsClass = helper.GetClass("Assembly-CSharp", "PlayerStats", 1);
		var PlayerStatsMS = helper.GetParent(PlayerStatsClass);
		foreach(string stat in vars.Stats) 
		{
			vars.Unity.Make<int>(PlayerStatsClass.Static, PlayerStatsMS["Instance"], PlayerStatsClass[stat]).Name = stat;
		}

		return true;
	});

	vars.Unity.Load(game);
}

update
{
	if (!vars.Unity.Loaded) return false;

	vars.Unity.Update();
    
    current.activeScene = vars.Unity.Scenes.Active.Index;
	current.loadingScenes = vars.Unity.Scenes.Loading;
	
	current.loadingScene = vars.Unity.Scenes.Loading.Count == 0 ? -1 : vars.Unity.Scenes.Loading[0].Index;
	
	if(old.loadingScenes.Count != current.loadingScenes.Count || 
		(current.loadingScene != -1 && old.loadingScene != current.loadingScene))
	{
		vars.Log("New loading scenes [" + current.loadingScenes.Count + "]");
		foreach(var scene in current.loadingScenes)
		{
			vars.Log(scene.Index + ": " + scene.Name);
		}
	}
	

	// Testing
	vars.Watch("Location");
	vars.Watch("Speed");
	vars.Watch("Health");
	vars.Watch("Stamina");
	vars.Watch("Stealth");
	vars.Watch("currentEquippedItem");
	vars.Watch("isEquipping");
	if(current.isLoading != old.isLoading) vars.Log("isLoading: " + old.isLoading + " -> " + current.isLoading);
	if(current.activeScene != old.activeScene)  vars.Log("activeScene: " + old.activeScene + " -> " + current.activeScene);

	if(current.loadingScene > 0 && current.loadingScene < current.loadingScenes.Count
		&& current.loadingScene != old.loadingScene)
	{
		vars.Log("loadingScene: " + old.loadingScene + " -> " + current.loadingScene);
		vars.Log("New loading scenes [" + current.loadingScenes.Count + "]");
		foreach(var scene in current.loadingScenes)
		{
			vars.Log(scene.Index + ": " + scene.Name);
		}
	}

}

start
{
	return vars.Unity["Location"].Changed && vars.Unity["Location"].Current == 34;
}

split
{
	
	// levels
	if(old.loadingScene != current.loadingScene
	&& current.loadingScene != 2 && current.loadingScene != 3) // Loading / GameManagers
	{
		vars.Log("Loading something...");
		foreach(KeyValuePair<string, dynamic> entry in vars.Levels)
		{
			if(vars.LevelLoading(entry.Key, current.loadingScene))
			{
				vars.Log("We are loading " + entry.Value.Label + "! " + current.loadingScene + ", " + current.activeScene);

				// (All for the first time)
				// Split when we are entering a specific level
				// Split when we are entering a specific level with a specific equippable
				// Split when we are exiting a specific level

				break;
			}
		}
	}

	// equippables
	if (vars.Unity["isEquipping"].Changed)
	{	
		if(!vars.EquippableItemGot[vars.Unity["currentEquippedItem"].Current])
		{
			vars.EquippableItemGot[vars.Unity["currentEquippedItem"].Current] = true;
			return settings[vars.Unity["currentEquippedItem"].Current];
		}
	}

	// stats
	foreach(string stat in vars.Stats)
	{
		if(vars.Unity[stat].Changed && vars.Unity[stat].Current > vars.StatMaxes[stat] && settings[stat])
		{
			vars.StatMaxes[stat] = vars.Unity[stat].Current;
			return true;
		}
	}

	return false;
}

isLoading
{
	return !current.isLoading;
}

onStart
{
	// update maxes to current when run starts
	foreach (string key in vars.Stats) vars.StatMaxes[key] = vars.Unity[key].Current;
}

onReset
{
	// reset trackers
	foreach (string key in vars.EquippableItemNames.Keys) vars.EquippableItemGot[key] = false;
	foreach (string key in vars.Stats) vars.StatMaxes[key] = 0;
}

exit
{
	vars.Unity.Reset();
}

shutdown
{
	vars.Unity.Reset();
}

