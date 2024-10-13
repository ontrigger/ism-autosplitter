state("In Sound Mind")
{
	bool isLoading : "unityplayer.dll", 0x19fb7c8, 0x78;
	long inventoryUI: "UnityPlayer.dll", 0x01952CC0, 0x330, 0x48, 0x168, 0x30, 0x30, 0x18, 0x28;
}

startup
{
	var bytes = File.ReadAllBytes(@"Components\LiveSplit.ASLHelper.bin");
	var type = Assembly.Load(bytes).GetType("ASLHelper.Unity");
	vars.Helper = Activator.CreateInstance(type, timer, this);
	
	vars.Log = (Action<object>)(output => print("[ISM-ASL] " + output));
	vars.Watch = (Action<string>)(key => { if(vars.Helper[key].Changed) vars.Log(key + ": " + vars.Helper[key].Old + " -> " + vars.Helper[key].Current); });
}

init
{
	vars.Helper.TryOnLoad = (Func<dynamic, bool>)(mono =>
	{
		var pm = mono.GetClass("PersistencyManager", 1);
		var saver = mono.GetClass("Saver");
		
		// var sidm = mono.GetClass("SaveIdManager", 1);
		// var s = mono.GetClass("Saveable");

		vars.Helper["DataDictionary"] = pm.Make<IntPtr>("Instance", "_currentSaver", saver["DataDictionary"]);
		vars.Helper["states"] = pm.Make<IntPtr>("Instance", "_currentStates");

		vars.GetEntries = (Func<IntPtr, int, List<dynamic>>)((dictionary, maxEntries) =>
		{
			// entries are 0x18 from the dict
			var ENTRIES_OFFSET = 0x18;

			// data about the entries array
			var LENGTH_OFFSET = 0x18;
			var ITEMS_OFFSET = 0x20;
			// each item oa a struct instead of a reference to another object
			var ITEM_SIZE = 0x18;

			// where the key/value are in each item
			var KEY_OFFSET = 0x8;
			var VAL_OFFSET = 0x10;

			var entries = vars.Helper.Read<IntPtr>(dictionary + ENTRIES_OFFSET);
			var length = vars.Helper.Read<int>(entries + LENGTH_OFFSET);

			var ret = new List<dynamic>();
			for(var i = 0; i < length && (maxEntries == -1 || i < maxEntries); i++)
			{
				var entryPointer = entries + ITEMS_OFFSET + (i * ITEM_SIZE);

				var key = vars.Helper.ReadString(entryPointer + KEY_OFFSET);
				var val = vars.Helper.ReadString(entryPointer + VAL_OFFSET);

				dynamic entry = new ExpandoObject();
				entry.key = key;
				entry.value = val;
				ret.Add(entry);
			}

			return ret;
		});

		// vars.ReadSaveable = (Func<IntPtr, dynamic>)(saveable =>
		// {
		// 	dynamic saveableObj = new ExpandoObject();

		// 	saveableObj._saveId = vars.Helper.ReadString(saveable + s["_saveId"]);
		// 	saveableObj._isEnabled = vars.Helper.Read<bool>(saveable + s["_isEnabled"]);

		// 	return saveableObj;
		// });

		return true;
	});

	vars.Helper.Load();

	vars.flag = true;
}

update
{
	if (!vars.Helper.Update())
		return false;

	if(!vars.flag) return false;
	vars.flag = false;

	var entries = vars.GetEntries(vars.Helper["states"].Current, -1);
	vars.Log(entries.Count);
	foreach(var entry in entries)
	{
		vars.Log(entry.key);
		vars.Log(entry.value);
	}
}

exit
{
	vars.Helper.Dispose();
}

shutdown
{
	vars.Helper.Dispose();
}