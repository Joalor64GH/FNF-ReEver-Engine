package;

import flixel.FlxG;
import flixel.FlxSprite;

class FunkinSprite extends FlxSprite
{
    public function new(X:Float = 0, Y:Float = 0, ?SimpleGraphic:flixel.system.FlxAssets.FlxGraphicAsset) {
        super(X, Y, SimpleGraphic);

        antialiasing = FlxG.save.data.antialiasing;
        cacheWhenGetThem();
    }

    function cacheWhenGetThem() {
        if (FlxG.save.data.cacheEveryPNG) {
            // if should be cache onto memory!
            graphic.persist = true;
            graphic.destroyOnNoUse = false;
        }
    }
}