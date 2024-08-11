package;

import flixel.FlxG;
import flixel.FlxSprite;

class FunkinSprite extends FlxSprite
{
    public function new(X:Float = 0, Y:Float = 0, ?SimpleGraphic:flixel.system.FlxAssets.FlxGraphicAsset) {
        super(X, Y, SimpleGraphic);
        cacheWhenGetThem();
    }

    function cacheWhenGetThem() {
        if (SaveData.settings.get("cacheEveryPNG") == true) {
            // if should be cache onto memory!
            graphic.persist = true;
            graphic.destroyOnNoUse = false;
        }
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        antialiasing = SaveData.settings.get("antialiasing");
    }
}