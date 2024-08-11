package options;

import Controls.Control;
import flash.text.TextField;
import flixel.FlxG;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;

class OptionsMenu extends MusicBeatState
{
	var selector:FlxText;
	var curSelected:Int = 0;

	var inSetting:Bool = false;

	var controlsStrings:Array<String> = [];

	var ogStrings:Array<String> = [
		"Gameplay",
		"Quality",
		"Misc"
	];

	var gameplayStrings:Array<String> = [
		"ghost tap",
		"downscroll"
	];

	var qualityStrings:Array<String> = [
		"antialiasing"
	];
	
	private var checkbox:Array<CheckboxThingie> = [];
	private var grpControls:FlxTypedGroup<Alphabet>;

	override function create()
	{
		controlsStrings = ogStrings; // default array string
		var menuBG:FunkinSprite = new FunkinSprite();
		menuBG.loadGraphic(Paths.image('menuBG'));
		menuBG.color = 0xFFea71fd;
		menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
		menuBG.updateHitbox();
		menuBG.screenCenter();
		add(menuBG);

		grpControls = new FlxTypedGroup<Alphabet>();
		add(grpControls);

		for (i in 0...controlsStrings.length)
		{
			var controlLabel:Alphabet = new Alphabet(0, (70 * i) + 30, controlsStrings[i], true, false);
			controlLabel.isMenuItem = true;
			controlLabel.targetY = i;
			grpControls.add(controlLabel);
			// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
			var aCheckbox:CheckboxThingie = new CheckboxThingie(controlLabel.x, controlLabel.y, SaveData.settings.get(controlsStrings[i]));
			aCheckbox.sprTracker = controlLabel;
			if (inSetting) {
				checkbox.push(aCheckbox);
				add(aCheckbox);
			} else if (!inSetting) { // JUST REMOVE THE BUTTON DAMMIT
				checkbox.remove(aCheckbox);
				remove(aCheckbox);
				for (checkBoxItem in checkbox) {
					remove(checkBoxItem);
				}
				checkbox = [];
			}
		}
		super.create();
	}

	function regenOptions():Void {
		while (grpControls.members.length > 0)
		{
			grpControls.remove(grpControls.members[0], true);
		}
		
		for (i in 0...controlsStrings.length)
		{
			var controlLabel:Alphabet = new Alphabet(0, (70 * i) + 30, controlsStrings[i], true, false);
			controlLabel.isMenuItem = true;
			controlLabel.targetY = i;
			grpControls.add(controlLabel);
			// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
			var aCheckbox:CheckboxThingie = new CheckboxThingie(controlLabel.x, controlLabel.y, SaveData.settings.get(controlsStrings[i]));
			aCheckbox.sprTracker = controlLabel;
			if (inSetting) {
				checkbox.push(aCheckbox);
				add(aCheckbox);
			} else if (!inSetting) { // JUST REMOVE THE BUTTON DAMMIT
				checkbox.remove(aCheckbox);
				remove(aCheckbox);
				for (checkBoxItem in checkbox) {
					remove(checkBoxItem);
				}
				checkbox = [];
			}
		}

		curSelected = 0;
		changeSelection();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (controls.ACCEPT)
		{
			switch (controlsStrings[curSelected]) {
				case "Gameplay": 
					inSetting = true;
					controlsStrings = gameplayStrings;
					regenOptions();
				case "Quality": 
					inSetting = true;
					controlsStrings = qualityStrings;
					regenOptions();
				case "Misc":
					inSetting = true;
			}
			if (inSetting) {
				// this one can only using for change bool, int and string are working on
				SaveData.settings.set(controlsStrings[curSelected], !SaveData.settings.get(controlsStrings[curSelected]));
				changeCheckbox(controlsStrings[curSelected]);
			}
		}

		if (controls.BACK)
		{
			SaveData.saveSettings();
			if (inSetting) {
				inSetting = false;
				controlsStrings = ogStrings;
				regenOptions();
			} else {
				MusicBeatState.switchState(new MainMenuState());
			}
		}
		if (controls.UP_P)
			changeSelection(-1);
		if (controls.DOWN_P)
			changeSelection(1);
	}

	function changeCheckbox(nameSave:String)
	{
		checkbox[curSelected].set_daValue(SaveData.settings.get(nameSave));
		trace(checkbox[curSelected].set_daValue(SaveData.settings.get(nameSave)));
	}

	function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = grpControls.length - 1;
		if (curSelected >= grpControls.length)
			curSelected = 0;

		// selector.y = (70 * curSelected) + 30;

		var bullShit:Int = 0;

		for (item in grpControls.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			// item.setGraphicSize(Std.int(item.width * 0.8));

			if (item.targetY == 0)
			{
				item.alpha = 1;
				// item.setGraphicSize(Std.int(item.width));
			}
		}
	}
}
