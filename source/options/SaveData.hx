package options;

import flixel.util.FlxSave;

class SaveData {
    public static var settings:Map<String, Dynamic> = [
        // name, value
        "ghost tap" => true,
        "downscroll" => false,
		"antialiasing" => true,
		"cache every png" => false,
		"camera zoom" => true,
		"framerate" => 60
	];

    public static function saveSettings() {
		var settingsSave:FlxSave = new FlxSave();
		settingsSave.bind('reEver', 'huy1234th');
		settingsSave.data.settings = settings;
		settingsSave.close();

		trace("settings saved!");
	}

    public static function loadSettings() {
		var settingsSave:FlxSave = new FlxSave();
		settingsSave.bind('reEver', 'huy1234th');

		if (settingsSave != null) {
			if (settingsSave.data.settings != null) {
				var savedMap:Map<String, Dynamic> = settingsSave.data.settings;
				for (name => value in savedMap) {
					settings.set(name, value);
				}
			}
		}

		Framerate.change(get("framerate"));
		settingsSave.destroy();
	}

	public static function get(string:String)
		return SaveData.settings.get(string);
	
	public static function set(string:String, newValue:Dynamic)
		return SaveData.settings.set(string, newValue);
}