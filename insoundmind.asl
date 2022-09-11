state("In Sound Mind")
{
	bool isLoading : "unityplayer.dll", 0x19fb7c8, 0x78;
}

startup
{
	vars.Log = (Action<object>)(output => print("[ISM-ASL] " + output));
	vars.Watch = (Action<string>)(key => { if(vars.Unity[key].Changed) vars.Log(key + ": " + vars.Unity[key].Old + " -> " + vars.Unity[key].Current); });
	var bytes = File.ReadAllBytes(@"Components\LiveSplit.ASLHelper.bin");
	var type = Assembly.Load(bytes).GetType("ASLHelper.Unity");
	vars.Unity = Activator.CreateInstance(type, timer, this);
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
	// asl be like
	vars.LevelLabels = new Dictionary<string, string>() {
		{"mainmenu", "Main Menu"}, 
		{"building", "Building"}, 
		{"dtape", "Desmond's Tape"}, 
		{"vtape", "Virginia's Tape"}, 
		{"hm", "Homa-Mart"},
		{"atape", "Allen's Tape"},
		{"pi", "Point Icarus"},
		{"mtape", "Max's Tape"},
		{"of", "Old Factory"},
		{"ltape", "Lucas' Tape"},
		{"ep", "Elysium Park"},
		{"rtape", "Rainbow Tape"},
	};

	vars.LevelScenes = new Dictionary<string, List<int>>() {
		{"mainmenu", new List<int> { 1, 9 }}, 
		{"building", new List<int> { 4, 5, 6 }},
		{"dtape", new List<int> { 28 }},
		{"vtape", new List<int> { 29 }},
		{"hm", new List<int> { 10, 11, 12 }},
		{"atape", new List<int> { 30 }},
		{"pi", new List<int> { 13, 14, 15, 16, 17 }},
		{"mtape", new List<int> { 31 }},
		{"of", new List<int> { 18, 19, 20, 21, 22 }},
		{"ltape", new List<int> { 32 }},
		{"ep", new List<int> { 23, 24, 25, 26, 27 }},
		{"rtape", new List<int> { 33 }},
	};

	vars.LevelSettingEntry = new Dictionary<string, dynamic>() {
		{"mainmenu", false}, 
		{"building", false}, 
		{"dtape", true},
		{"vtape", true},
		{"hm", true},
		{"atape", "flaregun-name"},
		{"pi", "flaregun-name"},
		{"mtape", "lurepill-name"},
		{"of", "lurepill-name"},
		{"ltape", "radio-name"},
		{"ep", "radio-name"},
		{"rtape", true},
	};

	vars.LevelSettingExit = new Dictionary<string, dynamic>() {
		{"mainmenu", false}, 
		{"building", false}, 
		{"dtape", true},
		{"vtape", "hm"},
		{"hm", true},
		{"atape", "pi"},
		{"pi", true},
		{"mtape", "of"},
		{"of", true},
		{"ltape", "ep"},
		{"ep", true},
		{"rtape", true},
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
		"dtape_exit",		// Building 1/Desmonds Tape
		"vtape_entry_any",	// Building 2
		"hm_exit",			// Homa-Mart
		"atape_entry_item",	// Building 3
		"pi_exit",			// Point Icarus
		"mtape_entry_item",	// Building 4
		"of_exit",			// Old Factory
		"ltape_entry_item",	// Building 5
		"ep_exit",			// Elysium Park
		"rtape_entry_any",	// Building 6
		"rtape_exit"		// Agent Rainbow
	};

	// If we are loading a specific level (associated with multiple scenes - if any of the scenes are loading, then we are loading the level)
	vars.LevelHasScene = (Func<string, int, bool>)((level, sceneIndex) => vars.LevelScenes[level].Contains(sceneIndex));
	vars.GetLevelFromScene = (Func<int, string>)((sceneIndex) => 
	{
		foreach(string key in vars.LevelScenes.Keys) 
		{
			if(vars.LevelHasScene(key, sceneIndex))
			{
				return key;
			}	
		}
		return "";
	});

	settings.Add("level_entry_any", true, "Enter Level (First time, any item)");
	settings.Add("level_entry_item", true, "Enter Level With Item (First time)");
	settings.Add("level_exit", true, "Exit Level (First time)");
	vars.LevelSplitsDone = new Dictionary<string, bool>();

	var SHOW_SET_IN_LABEL = false;
	foreach(string key in vars.LevelLabels.Keys)
	{
		// split for entering the level with any item for the first time
		if((vars.LevelSettingEntry[key] is Boolean && vars.LevelSettingEntry[key] != false)
			|| vars.LevelSettingEntry[key] is String)
		{
			string set = key + "_entry_any";
			string label = SHOW_SET_IN_LABEL ? vars.LevelLabels[key] + " [" + set + "]" : vars.LevelLabels[key]; 
			settings.Add(set, vars.DefaultSettings.Contains(set), label, "level_entry_any");
			vars.LevelSplitsDone.Add(set, false);
		}

		if(vars.LevelSettingEntry[key] is String)
		{
			string set = key + "_entry_item";
			string label = SHOW_SET_IN_LABEL ? vars.LevelLabels[key] + " with " + vars.EquippableItemNames[vars.LevelSettingEntry[key]] + " [" + set + "]" : vars.LevelLabels[key] + " with " + vars.EquippableItemNames[vars.LevelSettingEntry[key]]; 
			settings.Add(set, vars.DefaultSettings.Contains(set), label, "level_entry_item");
			vars.LevelSplitsDone.Add(set, false);
		}

		if((vars.LevelSettingExit[key] is bool && vars.LevelSettingExit[key])
			|| (vars.LevelSettingExit[key] is string))
		{
			string set = key + "_exit";
			string label = vars.LevelLabels[key];
			if(vars.LevelSettingExit[key] is string) label += " exit to " + vars.LevelLabels[vars.LevelSettingExit[key]];
			label = SHOW_SET_IN_LABEL ? label + " [" + set + "]" : label; 

			settings.Add(set, vars.DefaultSettings.Contains(set), label, "level_exit");
			vars.LevelSplitsDone.Add(set, false);
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

	vars.LoadingFrom = -1;
}

init
{
	vars.Unity.TryOnLoad = (Func<dynamic, bool>)(mono =>
	{
		var gp = mono.GetClass("GameParams", 1);
		vars.Unity["Location"] = gp.Make<int>("Instance", "CurrentLocation");

		var ec = mono.GetClass("EquippableController", 1);
		var ii = mono.GetClass("InventoryItem");

		vars.Unity["isEquipping"] = ec.Make<bool>("Instance", "_isEquipping");
		vars.Unity["currentEquippedItem"] = ec.MakeString("Instance", "_currentEquippedItem", ii["DisplayName"]);

		var ps = mono.GetClass("PlayerStats", 1);
		
		foreach(string stat in vars.Stats) 
		{
			vars.Unity[stat] = ps.Make<int>("Instance", ps[stat]);
		}

		return true;
	});

	vars.Unity.Load();
}

update
{
	if (!vars.Unity.Update()) return false;
    
    current.activeSceneIndex = vars.Unity.Scenes.Active.Index;
	current.loadingScenes = vars.Unity.Scenes.Loading;
	current.loadingSceneIndex = current.loadingScenes.Count == 0 || current.loadingScenes[0].Index > 200 ? -1 : current.loadingScenes[0].Index;

	// Testing
	vars.Watch("Location");
	vars.Watch("Speed");
	vars.Watch("Health");
	vars.Watch("Stamina");
	vars.Watch("Stealth");
	vars.Watch("currentEquippedItem");
	vars.Watch("isEquipping");
	if(current.isLoading != old.isLoading) vars.Log("isLoading: " + old.isLoading + " -> " + current.isLoading);
	
	// Watch scene variables
	if(old.loadingScenes.Count != current.loadingScenes.Count ||  
		(current.loadingSceneIndex != -1 && old.loadingSceneIndex != current.loadingSceneIndex)
	)
	{
		vars.Log("\nNew loading scenes [" + current.loadingScenes.Count + "]");
		foreach(var scene in current.loadingScenes)
		{
			if(scene.Index <= 0) break;
			vars.Log(scene.Index + ": " + scene.Name);
		}
	}
	
	if(old.activeSceneIndex != current.activeSceneIndex)
	{
		vars.Log("Active: " + current.activeSceneIndex);
		if(current.activeSceneIndex == 7) vars.LoadingFrom = old.activeSceneIndex;
	}

}

start
{
	return vars.Unity["Location"].Changed && vars.Unity["Location"].Current == 34;
}

split
{
	
	// levels
	if(current.loadingSceneIndex != -1 // no loading scenes (happens during BTO sequences, we dont need to split during these though)
		&& old.loadingSceneIndex != current.loadingSceneIndex
		&& current.loadingSceneIndex != 2 && current.loadingSceneIndex != 3) // Loading / GameManagers
	{
		string loadingLevel = vars.GetLevelFromScene(current.loadingSceneIndex);
		string activeLevel = vars.GetLevelFromScene(vars.LoadingFrom);

		if(loadingLevel == "" || activeLevel == "") 
		{
			vars.Log("Invalid loadingLevel or activeLevel: " + current.loadingSceneIndex + ", " + vars.LoadingFrom);
		}
		else if(loadingLevel == activeLevel)
		{
			vars.Log("Loading " + vars.LevelLabels[loadingLevel] + " from itself!");
		}
		else
		{
			vars.Log("We are loading " + vars.LevelLabels[loadingLevel] + " from " + vars.LevelLabels[activeLevel]);

			string entry_any = loadingLevel + "_entry_any";
			string entry_item = loadingLevel + "_entry_item";
			string exit = activeLevel + "_exit";

			// (All for the first time)
			// Split when we are entering a specific level
			if(settings.ContainsKey(entry_any) && !vars.LevelSplitsDone[entry_any] && settings[entry_any]) 
			{
				vars.LevelSplitsDone[entry_any] = true;
				return true;
			}

			// Split when we are entering a specific level with a specific equippable
			if(settings.ContainsKey(entry_item) && !vars.LevelSplitsDone[entry_item] && settings[entry_item]
				&& vars.LevelSettingEntry[loadingLevel] is string
				&& vars.EquippableItemGot.ContainsKey(vars.LevelSettingEntry[loadingLevel])
				&& vars.EquippableItemGot[vars.LevelSettingEntry[loadingLevel]]
			)
			{
				vars.LevelSplitsDone[entry_item] = true;
				return true;
			}
			
			// Split when we are exiting a specific level
			if(settings.ContainsKey(exit) && !vars.LevelSplitsDone[exit] && settings[exit]) 
			{	
				if(vars.LevelSettingExit[activeLevel] is string && vars.LevelSettingExit[activeLevel] != loadingLevel) return false;

				vars.LevelSplitsDone[exit] = true;
				return true;
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

	// end split
	if(vars.Unity["Location"].Current == 179) // roof
	{
		// placeholder
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
	foreach (string key in new List<string>(vars.LevelSplitsDone.Keys)) vars.LevelSplitsDone[key] = false;
	foreach (string key in vars.EquippableItemNames.Keys) vars.EquippableItemGot[key] = false;
	foreach (string key in vars.Stats) vars.StatMaxes[key] = 0;
	
}

exit
{
	vars.Unity.Dispose();
}

shutdown
{
	vars.Unity.Dispose();
}

