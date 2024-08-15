package stages;

import haxe.ds.StringMap;
import flixel.FlxBasic;
import flixel.group.FlxGroup.FlxTypedGroup;

class StageMe extends FlxTypedGroup<FlxBasic> {
    var exp:StringMap<Dynamic> = new StringMap<Dynamic>();
    public function new(stage:String) {
        super();

        exp.set("add", function(bsc:FlxBasic) {
            return PlayState.instance.add(bsc);
        });

        exp.set("remove", function(bsc:FlxBasic) {
            return PlayState.instance.remove(bsc);
        });

        exp.set("boyfriend", PlayState.instance.boyfriend);
        exp.set("gf", PlayState.instance.gf);
        exp.set("dad", PlayState.instance.dad);

        exp.set("game", PlayState.instance);
        
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