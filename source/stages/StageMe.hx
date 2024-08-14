package stages;

import haxe.ds.StringMap;
import flixel.FlxBasic;
import flixel.group.FlxGroup.FlxTypedGroup;

class StageMe extends FlxTypedGroup<FlxBasic> {
    var exp:StringMap<Dynamic> = new StringMap<Dynamic>();
    var playState:PlayState;

    public function new(stage:String) {
        super();

        exp.set("add", add);
        exp.set("remove", remove);

        exp.set("boyfriend", playState.boyfriend);
        exp.set("gf", playState.gf);
        exp.set("dad", playState.dad);
        
        exp.set("BGSprite", BGSprite);
        exp.set("FunkinSprite", FunkinSprite);
        exp.set("Paths", Paths);
        exp.set("PlayState", PlayState);
        
        var module:MyScripts = MyScripts.execute(Paths.file("stages/" + stage + ".hxs"), exp);
        if (module.exists("onCreate")) {
            module.get('onCreate')();
        }
    }
}