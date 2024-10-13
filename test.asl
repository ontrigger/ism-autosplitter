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
	vars.Helper.LoadSceneManager = true;
	
	vars.Log = (Action<object>)(output => print("[ISM-ASL] " + output));
	vars.Watch = (Action<string>)(key => { if(vars.Helper[key].Changed) vars.Log(key + ": " + vars.Helper[key].Old + " -> " + vars.Helper[key].Current); });

	vars.English = new Dictionary<string, string>();

	// vars.Helper.AlertLoadless("In Sound Mind");
}

init
{
	vars.Helper.TryOnLoad = (Func<dynamic, bool>)(mono =>
	{
		var pms = mono.GetClass("PlayerMovementState", 2);
		var invs = mono.GetClass("Inventories");
		var inv = mono.GetClass("Inventory");
		var iit = mono.GetClass("InventoryItemType");
		var ii = mono.GetClass("InventoryItem");

		var iid = mono.GetClass("InventoryItemDictionary", 2);

		// var Entry = mono.GetClass("mscorlib", "Entry");

		// var pm = mono.GetClass("PersistencyManager", 1);

		var pi = mono.GetClass("PlayerInventory", 1);
		var id = mono.GetClass("InventoryDictionary", 3);
		// var piiid = mono.GetClass("PlayerInventory.InventoryItemData");
		var puzzItem = mono.GetClass("PuzzleItem");
		var cd = mono.GetClass("ChapterData");

		var lm = mono.GetClass("LanguageManager", 1);
		vars.Helper["language"] = lm.Make<IntPtr>("Instance", "_language");

		vars.Helper["ID"] = pi.Make<IntPtr>("Instance", "_inventories");
		vars.Helper["entries"] = pi.Make<IntPtr>("Instance", "_inventories");
		vars.Helper["MovementStates"] = pms.Make<IntPtr>("Instance", "_states");

		var pis = mono.GetClass("PlayerInteractivityState", 2);
		vars.Helper["InteractivityStates"] = pis.Make<IntPtr>("Instance", "_states");
		var pim = mono.GetClass("PlayerInteractivityMode", 2);
		vars.Helper["Incapacitated"] = pim.Make<bool>("Instance", "_states", 0x18, 0x2C);
		vars.Helper["InteractivityModes"] = pim.Make<IntPtr>("Instance", "_states");


		#region GetEntries
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
			for(var i = 0; i < length && i < maxEntries; i++)
			{
				var entryPointer = entries + ITEMS_OFFSET + (i * ITEM_SIZE);

				var key = vars.Helper.Read<IntPtr>(entryPointer + KEY_OFFSET);
				var val = vars.Helper.Read<IntPtr>(entryPointer + VAL_OFFSET);

				dynamic entry = new ExpandoObject();
				entry.key = key;
				entry.value = val;
				ret.Add(entry);
			}

			return ret;
		});
		#endregion

		/* Load in the english language pack */
		vars.LoadEnglish = (Action<IntPtr>)(dictionary =>
		{
			vars.English = new Dictionary<string, string>();

			var entries = vars.Helper.Read<IntPtr>(dictionary + 0x18);
			var baseEntry = entries + 0x20;
			var length = vars.Helper.Read<int>(entries + 0x18);
			// 0 - hashCode (4 bytes), 4 - next (4 bytes), 8 - key (8 bytes), 10 - value (8 bytes)
			var entrySize = 0x18;

			vars.Log("Loading " + length + " english items!");
			for(var i = 0; i < length; i++)
			{
				var entryPointer = baseEntry + (i * entrySize);

				var key = vars.Helper.ReadString(entryPointer + 0x8);
				var value = vars.Helper.ReadString(entryPointer + 0x10);

				if(key == null || value == null) continue;

				vars.English[key] = value.Replace("\"", "\\\"");
			}
		});

		// vars.GetEntries44 = (Func<IntPtr, List<dynamic>>)(dictionary =>
		// {
		// 	var entries = vars.Helper.Read<IntPtr>(dictionary + 0x18);
		// 	var baseEntry = entries + 0x20;
		// 	var length = vars.Helper.Read<int>(entries + 0x18);
		// 	// 0 - hashCode (4 bytes), 4 - next (4 bytes), 8 - key (8 bytes), 10 - value (8 bytes)
		// 	var entrySize = 0x10;

		// 	var ret = new List<dynamic>();

		// 	for(var i = 0; i < length; i++)
		// 	{
		// 		var entryPointer = baseEntry + (i * entrySize);

		// 		var key = vars.Helper.Read<int>(entryPointer + 0x8);
		// 		var value = vars.Helper.Read<bool>(entryPointer + 0xC);

		// 		dynamic entry = new ExpandoObject();
		// 		entry.key = key;
		// 		entry.value = value;
		// 		ret.Add(entry);

		// 		// "'object' does not contain a definition for 'value'"
		// 		// ret.Add(new
		// 		// {
		// 		// 	key = key,
		// 		// 	value = value
		// 		// });
		// 	}

		// 	return ret;
		// });

		vars.ReadInventory = (Func<IntPtr, dynamic>)(invPointer =>
		{
			dynamic invObject = new ExpandoObject();
			invObject.ItemType = vars.Helper.Read<int>(invPointer + inv["ItemType"]);
			// invObject.Items = vars.Helper.Read<IntPtr>(invPointer + inv["Items"]);
			return invObject;
		});

		// InventoryItem
		vars.ReadII = (Func<IntPtr, bool, dynamic>)((iiPointer, readInv) => 
		{
			dynamic iiObject = new ExpandoObject();
			iiObject.DisplayName = vars.Helper.ReadString(iiPointer + ii["DisplayName"]);
			iiObject.Description = vars.Helper.ReadString(iiPointer + ii["Description"]);

			var chapter = vars.Helper.Read<IntPtr>(iiPointer + puzzItem["Chapter"]);
			iiObject.Chapter = vars.Helper.ReadString(chapter + cd["SceneName"]);

			// if(readInv)
			// 	iiObject.Inventory = vars.ReadInventory(vars.Helper.Read<IntPtr>(iiPointer + ii["Inventory"]));
			

			// iiObject.MaxAmount = vars.Helper.Read<int>(iiPointer + ii["MaxAmount"]);
			// iiObject.Priority = vars.Helper.Read<int>(iiPointer + ii["Priority"]);
			/*
			Inventory (Inventory)
			Icon (Sprite)
			MaxAmount (int)
			SoundPack (SoundPack)
			Description (string)
			MaxAmountPlayerHints (string[])
			Priority (int)
			*/
			return iiObject;
		});

		// PlayerInventory.InventoryItemData
		vars.ReadPIIID = (Func<IntPtr, dynamic>)(pidPointer =>
		{
			// vars.Log(piiid["Amount"].ToString("X"));
			dynamic pidObject = new ExpandoObject();
			pidObject.Amount = vars.Helper.Read<int>(pidPointer + 0x10);
			// pidObject.InClip = vars.Helper.Read<int>(pidPointer + 0x14);
			// pidObject.Unlocked = vars.Helper.Read<bool>(pidPointer + 0x18);
			
			// pidObject.Amount = vars.Helper.Read<int>(pidPointer + piiid["Amount"]);
			// pidObject.InClip = vars.Helper.Read<int>(pidPointer + piiid["InClip"]);
			// pidObject.Unlocked = vars.Helper.Read<bool>(pidPointer + piiid["Unlocked"]);
			// pidObject.Shortcut = vars.Helper.Read<int>(pidPointer + piiid["Shortcut"]);
			return pidObject;
		});

		


		// vars.Helper["InventoryList"] = pi.MakeArray<IntPtr>("Instance", "_inventoryAssets", invs["InventoryList"]);
		// vars.Helper["InventoryList"] = pm.MakeArray<IntPtr>("Instance", "_inventories", invs["InventoryList"]);
		// vars.Helper["IIDA"] = pi.MakeArray<IntPtr>("Instance", "_inventories", id["m_values"]);

 
		// vars.InvToDyn = (Func<IntPtr, dynamic>)(inventory => 
		// {
		// 	var itemtype = vars.Helper.Read<int>(inventory + inv["ItemType"]);
		// 	var items_ = vars.Helper.ReadList<IntPtr>(inventory + inv["Items"]);
		// 	var items = new List<dynamic>();

		// 	foreach(var item_ in items_)
		// 	{
		// 		items.Add(vars.InvItemToDyn(item_));
		// 	}

		// 	return new
		// 	{
		// 		ItemType = itemtype,
		// 		Items = items
		// 	};
		// });

		// vars.GetInventoryItemList = (Func<IntPtr[], List<dynamic>>)(invItemList => 
		// {
		// 	var ret = new List<dynamic>();

		// 	foreach(var invitem in invItemList)
		// 	{
		// 		ret.Add(vars.InvItemToDyn(invitem));
		// 	}

		// 	return ret;
		// });

		// vars.GetInventoryList = (Func<IntPtr[], List<dynamic>>)((il) => 
		// {
		// 	var ret = new List<dynamic>();

		// 	foreach(var inventory in il)
		// 	{
		// 		ret.Add(vars.InvToDyn(inventory));
		// 	}

		// 	return ret;
		// });



		// var gp = mono.GetClass("GameParams", 1);

		// vars.Helper["Location"] = gp.Make<int>("Instance", "CurrentLocation");

		// var sl = mono.GetClass("SceneLoader", 1);

		// vars.Helper["Loading"] = sl.Make<bool>("Instance", "isLoading");
		// vars.Helper["sceneQueue"] = sl.Make<IntPtr>("Instance", "_sceneQueue", 0x10);

		// array at 0x10

		// var li = mono.GetClass("LoadInfo");

		// vars.GetSceneName = (Func<IntPtr, bool>)(loadinfo =>
		// {
		// 	if(loadinfo == IntPtr.Zero) return false;

		// 	var s = new DeepPointer(loadinfo, 0x18).DerefString(game, 128);
		// 	// vars.Log(loadinfo.ToString("X"));
		// 	// vars.Log(li["SceneName"]);
		// 	if(s != null) vars.Log("'" + s + "'");

		// 	return true;
		// });

		var InventoryUI = mono.GetClass("InventoryUI"); 

// 		vars.InventoryUIGuesses = new List<IntPtr>()
// 		{
// new IntPtr(0x48B14BF2D0),
// new IntPtr(0x48B14BF408),
// new IntPtr(0x14D6521BC70),
// new IntPtr(0x14D6521BD90),
// new IntPtr(0x14D6521C030),
// new IntPtr(0x14D6521C290),
// new IntPtr(0x14D6521C510),
// new IntPtr(0x14D6521C650),
// new IntPtr(0x14D6521C790),
// new IntPtr(0x14D6521C8D0),
// new IntPtr(0x14D6521CA30),
// new IntPtr(0x14EE68E75D0),
// new IntPtr(0x14EF21FBEF0),
// new IntPtr(0x14EF21FC520),
// new IntPtr(0x14EF21FCB50),
// new IntPtr(0x14EF21FD000),
// new IntPtr(0x14EF21FD630),
// new IntPtr(0x14EF21FDC60),
// new IntPtr(0x14EF21FE290),
// new IntPtr(0x14EF21FE8C0),
// new IntPtr(0x14EF21FEEF0),
// new IntPtr(0x14F4F803140),
// new IntPtr(0x14F4F8CC7B0),
// new IntPtr(0x14F4F8CD058),
// new IntPtr(0x14F4F8CD0A8),
// new IntPtr(0x14F4F8CD0F8),
// new IntPtr(0x14F4F8CD148),
// new IntPtr(0x14F4F8CD198),
// new IntPtr(0x14F4F8CD1E8),
// new IntPtr(0x14F4F8CD238),
// new IntPtr(0x14F4F8CD288),
// new IntPtr(0x14F4F8CD2D8),
// new IntPtr(0x14F4F8CD328),
// new IntPtr(0x14F4F8CD378),
// new IntPtr(0x14F4F8CD3C8),
// new IntPtr(0x14F4F8CD418),
// new IntPtr(0x14F4F8CD468),
// new IntPtr(0x14F4F8CD4B8),
// new IntPtr(0x14F4F8CD508),
// new IntPtr(0x14F4F8CD558),
// new IntPtr(0x14F4F8CD5A8),
// new IntPtr(0x14F4F8CD5F8),
// new IntPtr(0x14F4F8CD648),
// new IntPtr(0x14F4F8CD698),
// new IntPtr(0x14F4F8CD6E8),
// new IntPtr(0x14F4F8CD738),
// new IntPtr(0x14F4F8CD788),
// new IntPtr(0x14F4F8CD7D8),
// new IntPtr(0x14F4F8CD828),
// new IntPtr(0x14F4F8CD878),
// new IntPtr(0x14F4F8CD8C8),
// new IntPtr(0x14F4F8CD918),
// new IntPtr(0x14FBDFB9000),
// new IntPtr(0x14FC630C6A8),
// new IntPtr(0x14FC630C6C8),
// new IntPtr(0x14FC630C6E8),
// new IntPtr(0x14FC630C708),
// new IntPtr(0x14FC630C728),
// new IntPtr(0x14FC630C748),
// new IntPtr(0x14FC630C768),
// new IntPtr(0x14FC630C788),
// new IntPtr(0x14FC630C7A8),
// new IntPtr(0x14FC630C7C8),
// new IntPtr(0x14FC630C7E8),
// new IntPtr(0x14FC630C808),
// new IntPtr(0x14FC630C828),
// new IntPtr(0x14FC630C848),
// new IntPtr(0x14FC630C868),
// new IntPtr(0x14FC630C888),
// new IntPtr(0x14FC630C8A8),
// new IntPtr(0x14FC630C8C8),
// new IntPtr(0x14FC630C8E8),
// new IntPtr(0x14FC630C908),
// new IntPtr(0x14FC630C928),
// new IntPtr(0x14FC630C948),
// new IntPtr(0x14FC630C968),
// new IntPtr(0x14FC630C988),
// new IntPtr(0x14FC68FE8C0),
// new IntPtr(0x150034DD480)
// 		};

		vars.ReadInventoryUI = (Func<IntPtr, bool>)(invUI =>
		{
			var p = vars.Helper.Read<IntPtr>(invUI + 0x88);
			if(p == null) return false;

			try {
				var visiblePuzzleItems = vars.Helper.ReadList<IntPtr>(invUI + 0x88);

				vars.Log(invUI.ToString("X") + " has " + visiblePuzzleItems.Count);
				foreach(var a in visiblePuzzleItems)
				{
					vars.Log(a);
					var item = vars.ReadII(a, false);
					vars.Log(item.DisplayName);
				}
					
			}
			catch(Exception e) { return false; }

			return true;
		});

		return true;
	});

	vars.flag = false;
	vars.CollectedItems = new List<string>();

	vars.Helper.Load();
}

onStart
{
	vars.CollectedItems.Clear();
}

update
{
	if (!vars.Helper.Update())
		return false;
	
	if (!vars.flag)
	{
		// foreach(var a in vars.InventoryUIGuesses) vars.ReadInventoryUI(a);
		// vars.LoadEnglish(vars.Helper["language"].Current);

		vars.ReadInventoryUI(new IntPtr(current.inventoryUI));
	}

	vars.flag = true;

	// vars.Log(vars.Helper["entries"].Current.ToString("X"));

	// vars.Log(vars.Helper["ID"].Current.ToString("X"));

	// var entries = vars.GetEntries(vars.Helper["entries"].Current, 2);

	// var langEntries = vars.GetEntriesSS(vars.Helper["language"].Current, 9999);
	// vars.Log("lang: " + langEntries.Count);
	// foreach(var langEntry in langEntries)
	// {
	// 	var key = langEntry.key;
	// 	var val = langEntry.value;
	// 	// var key = vars.Helper.ReadString(langEntry.key);
	// 	// var val = vars.Helper.ReadString(langEntry.value);
	// 	vars.Log(key + ", " + val);
	// }
	// vars.Log(entries.Count);
	// foreach(var entry in entries)
	// {
		// var iidEntries = vars.GetEntries(entries[1].value, 102);
		// vars.Log("=================================== " + iidEntries.Count);
		// int i = 0;

		// foreach(var iidEntry in iidEntries)
		// {
		// 	var itemData = vars.ReadII(iidEntry.key, false);

		// 	if(itemData.DisplayName == null)
		// 	{
		// 		vars.Log("breaking at " + i);
		// 		break;
		// 	}

		// 	var playerItemData = vars.ReadPIIID(iidEntry.value);			

		// 	// vars.Log(i + "\t--: '" + itemData.DisplayName);
		// 	i++;

		// 	if(vars.CollectedItems.Contains(itemData.DisplayName)) continue;

		// 	if(playerItemData.Amount == 0) continue;

		// 	// we have item
		// 	vars.CollectedItems.Add(itemData.DisplayName);
		// 	vars.Log("Collected the item: " + itemData.DisplayName);

		// }
	// }

	// var entriesBase = vars.Helper.Read<IntPtr>(entries[1].value + 0x18);
	// var baseEntry = entriesBase + 0x20;
	// // var length = vars.Helper.Read<int>(entries[1].value + 0x18);
	// // 0 - hashCode (4 bytes), 4 - next (4 bytes), 8 - key (8 bytes), 10 - value (8 bytes)
	// var entrySize = 0x18;

	// var s = "";

	// for(var i = 0; i < 102; i++)
	// {
	// 	var entryPointer = baseEntry + (i * entrySize);

	// 	var key = vars.Helper.Read<IntPtr>(entryPointer + 0x8);
	// 	var itemData = vars.ReadII(key, false);

	// 	if(!vars.English.ContainsKey(itemData.DisplayName)) continue;
		
	// 	// vars.Log(i + ": " + itemData.DisplayName);
	// 	// var name = vars.English.ContainsKey(itemData.DisplayName) ? vars.English[itemData.DisplayName] + "(" + itemData.DisplayName + ")" : itemData.DisplayName;
	// 	// vars.Log(": " + name + " (" + itemData.Chapter + ")");
	// 	// vars.Log("    " + itemData.Description);
		
	// 	var name = vars.English[itemData.DisplayName];
	// 	var desc = vars.English[itemData.Description];
	// 	var id = itemData.DisplayName + "-" + itemData.Chapter;
	// 	var obj = "new { ID = \"" + itemData.DisplayName + "\", Name = \"" + name + "\", Description = \"" + desc + "\", Chapter = \"" + itemData.Chapter + "\" }";
	// 	s += "{ \"" + id + "\", " + obj + " }, ";
	// 	// s += obj + ", ";

	// 	if(itemData.DisplayName == null)
	// 	{
	// 		vars.Log("breaking at " + i);
	// 		break;
	// 	}

	// 	var value = vars.Helper.Read<IntPtr>(entryPointer + 0x10);
	// 	var playerItemData = vars.ReadPIIID(value);			

	// 	if(vars.CollectedItems.Contains(itemData.DisplayName)) continue;

	// 	if(playerItemData.Amount == 0) continue;

	// 	// we have item
	// 	vars.CollectedItems.Add(itemData.DisplayName);
	// 	vars.Log("Collected the item: " + itemData.DisplayName);
	// }

	// // vars.Log("done");
	// vars.Log(s);

	// vars.Log(vars.Helper["MovementStates"].Current.ToString("X"));
	// vars.Log(vars.Helper["InteractivityStates"].Current.ToString("X")); // DisableInventory (6)
	// vars.Log(vars.Helper["InteractivityModes"].Current.ToString("X")); // DisableInventory (6)

	// var mmsEntries = vars.GetEntries44(vars.Helper["MovementStates"].Current);
	// foreach(var mmsEntry in mmsEntries)
	// {
	// 	vars.Log("mms: " + mmsEntry.key + ", " + mmsEntry.value);
	// }

	// List<dynamic> InvList = vars.GetInventoryList(vars.Helper["InventoryList"].Current);
	// // vars.Log(vars.GetInventoryList());
	// vars.Log("\n----LENGTH: " + InvList.Count);
	// foreach(var inv in InvList)
	// {
	// 	vars.Log(inv);
	// 	vars.Log(inv.GetType().GetProperty("ItemType").GetValue(inv, null));
	// 	// vars.Log(inv.ItemType + ": ");
		
	// 	foreach(var item in inv.GetType().GetProperty("Items").GetValue(inv, null))
	// 	{
	// 		vars.Log("\t" + item.GetType().GetProperty("Name").GetValue(item, null));
	// 	}
	// }
	// vars.Log(InvList);

	// var a = vars.GetInventoryItemList(vars.Helper["IIDA"].Current);
	// vars.Log("\n----LENGTH: " + a.Count);
	// foreach(var b in a)
	// {
	// 	vars.Log(b);
	// }

	// vars.Watch("MovementState");
	// vars.Watch("Loading");vars.Helper["Incapacitated"]
	// vars.Watch("Incapacitated");
	
	// foreach(var scene in vars.Helper.Scenes.Loading)
	// {
	// 	if(scene.Index <= 0) break;

	// 	vars.Log("[" + scene.Index + "] " + scene.Name);
	// }
}

exit
{
	vars.CollectedItems.Clear();
	vars.Helper.Dispose();
}

shutdown
{
	vars.CollectedItems.Clear();
	vars.Helper.Dispose();
}
