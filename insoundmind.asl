state("In Sound Mind")
{
	// used in the first versions of the autosplitter and is now just grandfathered in as the loading variable for consistency's sake
	bool isNotLoading: "UnityPlayer.dll", 0x19FB7C8, 0x78;
	// No static reference to this class I could find unfortunately
	long inventoryUI: "UnityPlayer.dll", 0x01952CC0, 0x330, 0x48, 0x168, 0x30, 0x30, 0x18, 0x28;
}

startup
{
	vars.Log = (Action<object>)(output => print("[ISM-ASL] " + output));
	vars.Watch = (Action<string>)(key => { if(vars.Helper[key].Changed) vars.Log(key + ": " + vars.Helper[key].Old + " -> " + vars.Helper[key].Current); });

    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.GameName = "In Sound Mind";
	vars.Helper.LoadSceneManager = true;

	vars.FoundEquippables = new Dictionary<string, bool>();
	vars.FoundItems = new Dictionary<string, bool>();
	vars.EquippableLabels = new Dictionary<string, string>();
	vars.LevelEntryItems = new Dictionary<string, string>();
	vars.LevelScenes = new Dictionary<string, List<int>>();
	vars.CompletedSplits = new List<string>();
	// temporary!
	vars.Locations = new List<string>() { "Beach", "Office", "GasStation", "Town", "supermarket", "supermarket_entrance", "supermarket_main1", "supermarket_main2", "supermarket_main3", "supermarket_main4", "supermarket_electronic", "supermarket_toys", "supermarket_toilets", "supermarket_maintenance1", "supermarket_maintenance2", "supermarket_maintenance3", "supermarket_managerroom", "supermarket_cctv", "supermarket_offices", "supermarket_staff", "supermarket_lockerroom", "supermarket_powerroom", "supermarket_compressorroom", "supermarket_loadingbay", "supermarket_controlcabin", "supermarket_warehouse", "supermarket_trashroom", "supermarket_freezerroom", "supermarket_storage1", "supermarket_storage2", "supermarket_registers", "supermarket_exhibit", "supermarket_vents", "hub_building", "hub_basement", "hub_basement_trash", "hub_basement_storage", "hub_basement_workroom", "hub_basement_elevatorhallway", "hub_basement_boiler", "hub_basement_laundry", "hub_basement_service", "hub_basement_shaft", "hub_office_floor", "hub_office_desmondoffice", "hub_office_hall", "hub_floor_1", "hub_floor_1_centralhallway", "hub_floor_1_easthallway", "hub_floor_1_westhallway", "hub_floor_1_toilets", "hub_floor_1_maintenanceroom", "hub_floor_1_janitorcloset", "hub_floor_1_backroom", "hub_floor_1_gasroom", "hub_floor_1_storage", "hub_floor_1_lobby", "hub_floor_1_resepctionroom", "hub_floor_1_mailroom", "hub_tape_0", "lighthouse", "lighthouse_beach", "lighthouse_cove", "lighthouse_fishingcabin", "lighthouse_forest", "lighthouse_lookout", "lighthouse_blockedcave", "lighthouse_sunkencars", "lighthouse_checkpoint1", "lighthouse_checkpoint2", "lighthouse_smallhouse1", "lighthouse_lane", "lighthouse_lighthouse", "lighthouse_burnthouse", "lighthouse_courtyard", "lighthouse_cliffs", "lighthouse_bay", "lighthouse_ship", "lighthouse_shipinside", "lighthouse_shipbridge", "lighthouse_wharf", "lighthouse_warehouse", "lighthouse_lighthouseinside", "lighthouse_lighthousebasement", "lighthouse_lighthousetop", "lighthouse_lighthouseshed", "lighthouse_shipdeck", "lighthouse_boathouse", "lighthouse_trip", "hub_tape_1", "hub_apt_desmond", "hub_apt_virginia", "hub_tape_2", "hub_apt_allen", "factory_railroadsouth", "factory_entrance", "factory_loadzone", "factory_trainyard", "factory_trainyardeast", "factory_tunnel", "factory_hangar", "factory_powerstation", "factory_floor1", "factory_floor2", "factory_floor3", "factory_packaging", "factory_storage1", "factory_storage2", "factory_frozenroom", "factory_assembly1", "factory_assembly2", "factory_assembly3", "factory_incinerator", "factory_scary", "factory_centrifuge", "factory_processingwing1", "factory_processingwing2", "factory_blastroom", "factory_officecabin", "factory_watingarea", "factory_office1", "factory_office2", "factory_bossroom", "factory_secretaryroom", "factory_lab", "factory_toxicdump", "factory_quarry", "factory_trainhouse", "forest", "forest_normal", "forest_deep", "forest_flashcabin", "forest_bunkerdoor", "forest_watertower", "forest_watchtower", "forest_rangerstation", "forest_church", "forest_graveyard", "forest_crypt", "forest_radiotower", "forest_radiostation", "forest_bunker", "forest_radarout", "forest_radartop", "forest_cablestation", "forest_poi_1", "forest_poi_2", "forest_poi_3", "forest_poi_4", "forest_poi_5", "forest_poi_6", "forest_poi_7", "forest_poi_8", "forest_poi_9", "forest_poi_10", "forest_anchortower", "forest_watercenter", "forest_bridge_l", "forest_bridge_c", "forest_bridge_r", "forest_bridge_small", "forest_bridge_big", "forest_forest_center", "forest_forest_west", "forest_forest_east", "forest_jammer_tower", "forest_water_center_inside", "forest_water_center_sewer", "forest_lookout", "forest_visitorcenterinside", "supermarket_meat", "supermarket_dairy", "hub_tape_3", "hub_tape_4", "hub_apt_max", "hub_apt_lucas", "hub_floor_1_ventilation", "tape_rainbow_piano_room", "tape_rainbow", "hub_roof", "hub_roof_stairs" };
	
	#region Settings
	var xml = System.Xml.Linq.XDocument.Load(@"Components\ISM.Data.xml").Element("Data");

	settings.Add("levels", false, "Split on level events");
	settings.Add("equippables", false, "Split on equippable pickup");
	settings.Add("items", false, "Split on item pickup");
	
	foreach(var equippable in xml.Element("Equippables").Elements("Equippable"))
	{
		string id = equippable.Attribute("ID").Value;
		string name = equippable.Attribute("Name").Value;
		string desc = equippable.Attribute("Description").Value;

		settings.Add(id, false, name, "equippables");
		settings.SetToolTip(id, desc);

		vars.FoundEquippables[id] = false;
		vars.EquippableLabels[id] = name;
	}
	

	foreach(var level in xml.Element("Levels").Elements("Level"))
	{
		string levelId = level.Attribute("ID").Value;
		string levelName = level.Attribute("Name").Value;

		#region LevelScenes
		vars.LevelScenes[levelId] = new List<int>();
		foreach(var scene in level.Element("Scenes").Elements("Scene"))
		{
			vars.LevelScenes[levelId].Add(Int32.Parse(scene.Attribute("Index").Value));
		}
		#endregion

		#region LevelSplit
		var entryItem = level.Attribute("EntryItem") != null ? level.Attribute("EntryItem").Value : "None";
		var exitLevel = level.Attribute("ExitLevel") != null ? level.Attribute("ExitLevel").Value : "None";

		// enter / exit
		if(entryItem != "None" || exitLevel != "None")
		{
			// settings.Add(levelId, false, levelName, "levels");

			if(entryItem != "None")
			{
				settings.Add(levelId + "_enter", false, "Enter " + levelName, "levels");
				
				if(entryItem != "Any")
				{
					vars.LevelEntryItems[levelId + "_item"] = entryItem;
					settings.Add(levelId + "_item", false, "Only if you have the " + vars.EquippableLabels[entryItem] + ".", levelId + "_enter");
					settings.SetToolTip(levelId + "_item", "Tick this if you are using BTO and want to split after\ngetting the item (otherwise it will false split).");
				}
			}

			if(exitLevel != "None")
			{
				settings.Add(levelId + "_exit", false, "Exit " + levelName, "levels");
			}
		}
		#endregion

		#region ItemSplit
		// Item Splits
		var levelItems = level.Element("Items");
		if(levelItems == null) continue;

		string levelSetId = "item-" + levelId;
		settings.Add(levelSetId, false, levelName, "items");

		foreach(var item in levelItems.Elements("Item"))
		{
			string itemId = item.Attribute("ID").Value;
			string itemName = item.Attribute("Name").Value;
			string itemDesc = item.Attribute("Description").Value;

			string itemSetId = itemId + "-" + levelId;
			settings.Add(itemSetId, false, itemName, levelSetId);
			settings.SetToolTip(itemSetId, itemDesc);

			vars.FoundItems[itemSetId] = false;
		}
		#endregion
	}
	#endregion

	vars.Stats = new string[] { "Speed", "Health", "Stamina", "Stealth" };
	vars.StatMaxes = new Dictionary<string, int>();

	// settings.Add("stat", false, "Stat Increase (pill pickup)");
	foreach(string stat in vars.Stats)
	{
		// settings.Add(stat, false, stat, "stat");
		vars.StatMaxes[stat] = 0;
	}

	vars.ResetFound = (Action)(() => 
	{
		foreach(var key in new List<string>(vars.FoundItems.Keys))
		{
			vars.FoundItems[key] = false;
		}

		foreach(var key in new List<string>(vars.FoundEquippables.Keys))
		{
			vars.FoundEquippables[key] = false;
		}
	});

	vars.GetLevel = (Func<int, string>)(scene =>
	{
		foreach(string key in vars.LevelScenes.Keys)
		{
			if(vars.LevelScenes[key].Contains(scene))
				return key;
		}
		return "";
	});

	vars.Helper.AlertLoadless();
}

init
{	
	vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
	{
		// start and end split
		var GameParams = mono.GetClass("GameParams", 1);
		vars.Helper["Location"] = GameParams.Make<int>("Instance", "CurrentLocation");

		var pim = mono.GetClass("PlayerInteractivityMode", 2);
		// 0x18 - entries of the _states Dictionary
		// 0x2C - 0x20 is the base of the entries array, each item is a struct of size 0x10 (0x0 - hashcode, 0x4 - next, 0x8 - key, 0xC - value)
		// 			first item in the entries array is Incapacitated, so 0x20 + 0 * 0x10 + 0xC gives us whether or not we are incapacitated
		vars.Helper["Incapacitated"] = pim.Make<bool>("Instance", "_states", 0x18, 0x2C);

		#region ExtraSplits
		var PuzzleItem = mono.GetClass("PuzzleItem", 1); // extends InventoryItem
		var ChapterData = mono.GetClass("ChapterData");

		var InventoryUI = mono.GetClass("InventoryUI");		
		var Interactible = mono.GetClass("Interactible", 1);

		// equippables
		var EquippableController = mono.GetClass("EquippableController", 1);

		vars.Helper["isEquipping"] = EquippableController.Make<bool>("Instance", "_isEquipping");
		vars.Helper["CurrentEquipped"] = EquippableController.MakeString("Instance", "_currentEquippedItem", PuzzleItem["DisplayName"]);

		// stats
		var PlayerStats = mono.GetClass("PlayerStats", 1);
		
		foreach(string stat in vars.Stats) 
		{
			vars.Helper[stat] = PlayerStats.Make<int>("Instance", PlayerStats[stat]);
		}
		#endregion

		#region ItemThings
		vars.ReadInventoryItem = (Func<IntPtr, dynamic>)(iiPointer =>
		{
			dynamic iiObject = new ExpandoObject();
			iiObject.DisplayName = vars.Helper.ReadString(iiPointer + PuzzleItem["DisplayName"]);

			var chapter = vars.Helper.Read<IntPtr>(iiPointer + PuzzleItem["Chapter"]);
			iiObject.Chapter = vars.Helper.ReadString(chapter + ChapterData["SceneName"]);

			return iiObject;
		});

		vars.ReadVisiblePuzzleItems = (Func<IntPtr, List<dynamic>>)(invUIPointer =>
		{
			var visiblePuzzleItems = vars.Helper.ReadList<IntPtr>(invUIPointer + InventoryUI["_visiblePuzzleItems"]);
			var ret = new List<dynamic>();

			foreach(var puzzleItemP in visiblePuzzleItems)
			{
				ret.Add(vars.ReadInventoryItem(puzzleItemP));
			}

			return ret;
		});
		#endregion

		return true;
	});

	vars.ResetFound();
	current.loadingFromLevel = "empty";
	current.loadingLevel = "empty";
	current.activeLevel = "empty";
	current.activeSceneNameRaw = "empty";
	current.loadingSceneNameRaw = "empty";
}

onStart
{
	vars.ResetFound();
	vars.CompletedSplits.Clear();

	foreach(string stat in vars.Stats)
		vars.StatMaxes[stat] = 0;

    vars.Log("loadingLevel: " + current.loadingLevel);
	vars.Log("activeLevel: " + current.activeLevel);
	vars.Log("loadingFromLevel: " + current.loadingFromLevel);
	vars.Log("loadingSceneIndex: " + current.loadingSceneIndex);
	vars.Log("activeSceneNameRaw: " + current.activeSceneNameRaw);
    vars.Log("loadingSceneNameRaw: " + current.loadingSceneNameRaw);
    vars.Log("loadedCount: " + current.loadedCount);
}
// [11772] Member 'AslHelp..get' cannot be accessed with an instance reference; qualify it with a type name instead

update
{
	current.isLoading = !current.isNotLoading;

	current.activeSceneIndex = vars.Helper.Scenes.Active.Index;
    // vars.Log("vars.Helper.Scenes.Loaded.Count: " + vars.Helper.Scenes.Loaded.Count);
	current.loadingSceneIndex = vars.Helper.Scenes.Loaded.Count == 0 || vars.Helper.Scenes.Loaded[0].Index > 200 ? -1 : vars.Helper.Scenes.Loaded[0].Index;

    current.activeSceneNameRaw = vars.Helper.Scenes.Active.Name ?? current.activeSceneNameRaw;
    current.loadingSceneNameRaw = vars.Helper.Scenes.Loaded.Count == 0 ? current.loadingSceneNameRaw : vars.Helper.Scenes.Loaded[0].Name;
    current.loadedCount = vars.Helper.Scenes.Loaded.Count;

    if (old.loadedCount != current.loadedCount) {
        vars.Log("--- " + current.loadedCount);
        foreach (var Scene in vars.Helper.Scenes.Loaded) {
            vars.Log(Scene.Name);
        }
    }

	if(current.loadingLevel == "empty" || current.loadingSceneIndex != old.loadingSceneIndex)
    {
		current.loadingLevel = vars.GetLevel(current.loadingSceneIndex);
    }
    
	if(current.activeLevel == "empty" || current.activeSceneIndex != old.activeSceneIndex)
		current.activeLevel = vars.GetLevel(current.activeSceneIndex);

	if(old.activeSceneIndex != current.activeSceneIndex && current.activeSceneIndex == 7)
		current.loadingFromLevel = vars.GetLevel(old.activeSceneIndex);

	// debugging below
	if(vars.Helper["Location"].Changed)
	{
		var oldloc = vars.Helper["Location"].Old;
		var currloc = vars.Helper["Location"].Current;
		vars.Log("Location: " + vars.Locations[oldloc] + " [" + oldloc + "] -> " + vars.Locations[currloc] + " [" + currloc + "]");
	}

	foreach(string stat in vars.Stats)
	{
		if(vars.Helper[stat].Changed && vars.Helper[stat].Current > vars.StatMaxes[stat])
		{
			vars.StatMaxes[stat] = vars.Helper[stat].Current;
			var loc = vars.Helper["Location"].Current;
			vars.Log("Stat increase! " + stat + " increased to " + vars.StatMaxes[stat] + "! Location: " + vars.Locations[loc] + " [" + loc + "]");
			return true;
		}
	}
	// if(current.isLoading != old.isLoading) vars.Log("Loading: " + old.isLoading + " -> " + current.isLoading);
	// if(vars.Helper["CurrentEquipped"].Changed) vars.Log(vars.Helper["CurrentEquipped"].Current);

	if(old.loadingLevel != current.loadingLevel) vars.Log("loadingLevel: " + old.loadingLevel + " -> " + current.loadingLevel);
	if(old.activeLevel != current.activeLevel) vars.Log("activeLevel: " + old.activeLevel + " -> " + current.activeLevel);
	if(old.loadingFromLevel != current.loadingFromLevel) vars.Log("loadingFromLevel: " + old.loadingFromLevel + " -> " + current.loadingFromLevel);
	if(old.loadingSceneIndex != current.loadingSceneIndex) vars.Log("loadingSceneIndex: " + old.loadingSceneIndex + " -> " + current.loadingSceneIndex);
	if(old.activeSceneNameRaw != current.activeSceneNameRaw) vars.Log("activeSceneNameRaw: " + old.activeSceneNameRaw + " -> " + current.activeSceneNameRaw);
	if(old.loadingSceneNameRaw != current.loadingSceneNameRaw) vars.Log("loadingSceneNameRaw: " + old.loadingSceneNameRaw + " -> " + current.loadingSceneNameRaw);
}

start
{
	// the trash room you spawn in is 34, and this gets updated once you gain control
	return vars.Helper["Location"].Changed && vars.Helper["Location"].Current == 34;
}

split
{
	// End Split - 179 is the roof
	if(vars.Helper["Incapacitated"].Changed && vars.Helper["Incapacitated"].Current && vars.Helper["Location"].Current == 179)
	{
		vars.Log("End detected! GG!");
		return true;
	}

	// Level Events (Enter / Exit)
	if(settings["levels"] && current.loadingLevel != old.loadingLevel
	   && current.loadingFromLevel != current.loadingLevel
	   && current.loadingLevel != "" && current.loadingFromLevel != "")
	{
		string enter = current.loadingLevel + "_enter";
		string enterItem = current.loadingLevel + "_item";
		string exit = current.loadingFromLevel + "_exit";

		if(settings.ContainsKey(enter) && settings[enter] && !vars.CompletedSplits.Contains(enter)
		&& (!settings.ContainsKey(enterItem) || !settings[enterItem] || (settings[enterItem] && vars.FoundEquippables[vars.LevelEntryItems[enterItem]])))
		{
			vars.CompletedSplits.Add(enter);
			vars.Log("Entering " + current.loadingLevel + "!");
			return true;
		}

		if(settings.ContainsKey(exit) && settings[exit] && !vars.CompletedSplits.Contains(exit))
		{
			vars.CompletedSplits.Add(exit);
			vars.Log("Exiting " + current.loadingFromLevel + "!");
			return true;
		}
	}

	// Equippables (Flashlight, etc)
	if(vars.Helper["isEquipping"].Current
	&& !vars.FoundEquippables[vars.Helper["CurrentEquipped"].Current])
	{
		vars.FoundEquippables[vars.Helper["CurrentEquipped"].Current] = true;
		vars.Log("Equipped " + vars.Helper["CurrentEquipped"].Current + "!");
		return settings[vars.Helper["CurrentEquipped"].Current];
	}

	// Puzzle Items (In the inventory)
	if(current.isLoading || current.inventoryUI == 0) return false;

	var visiblePuzzleItems = vars.ReadVisiblePuzzleItems(new IntPtr(current.inventoryUI));
	foreach(var puzzleItem in visiblePuzzleItems)
	{
		var id = puzzleItem.DisplayName + "-" + puzzleItem.Chapter;
		if(id == "item-hub-record-rosemary-name-") id += "C_Forest";

		if(!settings[id] || vars.FoundItems[id])
			continue;
		
		vars.FoundItems[id] = true;
		vars.Log("Collected item: " + id);
		return true;
	}
}

isLoading
{
	return current.isLoading;
}
