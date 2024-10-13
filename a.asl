state("In Sound Mind") {}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.GameName = "In Sound Mind";
	vars.Helper.LoadSceneManager = true;
}

update
{
    vars.Log("vars.Helper.Scenes.Loaded.Count: " + vars.Helper.Scenes.Loaded.Count);
}