state("In Sound Mind")
{
	bool isLoading : "unityplayer.dll", 0x19fb7c8, 0x78;
}

startup
{
	vars.Log = (Action<object>)(output => print("[ISM-ASL] " + output));
	vars.Watch = (Action<string>)(key => { if(vars.Unity[key].Changed) vars.Log(key + ": " + vars.Unity[key].Old + " -> " + vars.Unity[key].Current); });
	vars.Unity = Assembly.Load(File.ReadAllBytes(@"Components\UnityASL.bin")).CreateInstance("UnityASL.Unity");
	
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
	vars.EquippableItemGot = new Dictionary<string, bool>();
	vars.Stats = new string[] { "Speed", "Health", "Stamina", "Stealth" };
	vars.StatMaxes = new Dictionary<string, int>();

	// Equippable Splits
	settings.Add("equippables", false, "Equippable Pickup");
	foreach (KeyValuePair<string, string> entry in vars.EquippableItemNames)
	{
		settings.Add(entry.Key, false, entry.Value, "equippables");
		vars.EquippableItemGot.Add(entry.Key, false);
	}

	// Stat splits
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

	// Testing
	vars.Watch("Location");
	vars.Watch("Speed");
	vars.Watch("Health");
	vars.Watch("Stamina");
	vars.Watch("Stealth");
	vars.Watch("currentEquippedItem");
	vars.Watch("isEquipping");
	if(current.isLoading != old.isLoading) vars.Log("isLoading: " + old.isLoading + " -> " + current.isLoading);
}

start
{
	return vars.Unity["Location"].Changed && vars.Unity["Location"].Current == 34;
}

split
{
	if (vars.Unity["isEquipping"].Changed)
	{	
		if(!vars.EquippableItemGot[vars.Unity["currentEquippedItem"].Current])
		{
			vars.EquippableItemGot[vars.Unity["currentEquippedItem"].Current] = true;
			return settings[vars.Unity["currentEquippedItem"].Current];
		}
	}

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

